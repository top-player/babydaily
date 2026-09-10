#!/usr/bin/env node
/**
 * 把 DSH 会话日志（`~/.dsh/sessions/` 下按项目分目录的 `session.vN.jsonl.zstd`）导出成便于阅读的形式。
 *
 * 产物（默认写到 <项目>/exports/conversations/）：
 *   - index.html            会话总览（标题 / 时间 / 消息数 / 入口链接）
 *   - session-*.html        每个会话一页：用户与助手气泡、工具调用可折叠、支持搜索与过滤
 *   - md/*.md               每个会话一份 Markdown，便于 grep、diff、丢进其它工具
 *   - sessions.json         归一化后的结构化数据（用户/助手/工具调用/用量），便于二次加工
 *
 * 用法：
 *   node tools/export_sessions.mjs
 *   node tools/export_sessions.mjs --project C:\\path\\to\\项目 --out .\\exports\\conversations
 *   node tools/export_sessions.mjs --tool-chars 8000 --reasoning full
 *
 * 参数：
 *   --project <path>    要导出的项目路径，默认当前工作目录
 *   --dsh-home <path>   DSH 数据目录，默认 $DSH_HOME 或 ~/.dsh
 *   --out <path>        输出目录，默认 <项目>/exports/conversations
 *   --tool-chars <n>    单条工具输出保留字符数，0 表示不截断（默认 3000）
 *   --reasoning <mode>  思考块保留量：off | short | full（默认 short）
 *   --md / --no-md      是否输出 Markdown（默认输出）
 *   --quiet             只打印结果摘要
 */

import { constants, zstdDecompressSync } from 'node:zlib'
import { readFile, writeFile, mkdir, readdir, lstat, rm } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { homedir } from 'node:os'
import path from 'node:path'

// ---------------------------------------------------------------- CLI

function parseArgs(argv) {
  const opts = {
    project: process.cwd(),
    dshHome: process.env.DSH_HOME || path.join(homedir(), '.dsh'),
    out: null,
    toolChars: 3000,
    reasoning: 'short',
    md: true,
    quiet: false,
  }
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i]
    const next = () => {
      const value = argv[i + 1]
      if (value === undefined) throw new Error(`${arg} 需要一个取值`)
      i += 1
      return value
    }
    switch (arg) {
      case '--project': opts.project = next(); break
      case '--dsh-home': opts.dshHome = next(); break
      case '--out': opts.out = next(); break
      case '--tool-chars': opts.toolChars = Number(next()); break
      case '--reasoning': opts.reasoning = next(); break
      case '--md': opts.md = true; break
      case '--no-md': opts.md = false; break
      case '--quiet': opts.quiet = true; break
      case '-h':
      case '--help': console.log(helpText()); process.exit(0); break
      default: throw new Error(`未知参数：${arg}`)
    }
  }
  if (!['off', 'short', 'full'].includes(opts.reasoning)) throw new Error('--reasoning 只能是 off / short / full')
  if (!Number.isFinite(opts.toolChars) || opts.toolChars < 0) throw new Error('--tool-chars 需要非负数字')
  opts.project = path.resolve(opts.project)
  opts.out = path.resolve(opts.out ?? path.join(opts.project, 'exports', 'conversations'))
  return opts
}

function helpText() {
  return '用法：node tools/export_sessions.mjs [--project <path>] [--out <dir>] [--tool-chars <n>] [--reasoning off|short|full] [--no-md]'
}

// ---------------------------------------------------------------- 会话日志定位

const LOG_NAME = /^session(?:\.v(\d+))?\.jsonl(\.zstd)?$/

const ZSTD_MAGIC = 0xFD2FB528
const ZSTD_FLUSH = constants.ZSTD_e_flush

/** 解析 `session[.vN].jsonl[.zstd]`，拿到格式版本与压缩方式。 */
function parseLogName(name) {
  const match = LOG_NAME.exec(name)
  if (!match) return null
  return { version: match[1] ? Number(match[1]) : 1, zstd: Boolean(match[2]) }
}

/** 一个会话目录里可能有多个格式版本，只取最高的那个（旧版本是迁移前留下的副本）。 */
function pickLatestLog(names) {
  let best = null
  for (const name of names) {
    const info = parseLogName(name)
    if (!info) continue
    if (!best || info.version > best.version || (info.version === best.version && info.zstd && !best.zstd)) {
      best = { name, ...info }
    }
  }
  return best
}

/** 路径比较用的归一化：统一分隔符、去掉尾部分隔符、Windows 盘符大小写不敏感。 */
function normalizePath(value) {
  if (typeof value !== 'string' || value.length === 0) return ''
  let out = value.replace(/[\\/]+/g, '/').replace(/\/+$/, '')
  if (/^[a-zA-Z]:\//.test(out)) out = out[0].toLowerCase() + out.slice(1)
  return out
}

/**
 * 扫描拼接式 zstd 容器里的每个完整帧（Node 的一次性/流式 API 都只解第一帧）。
 * 返回完整帧范围，以及尾部未写完帧的起点。
 */
function scanZstdFrames(buffer) {
  const frames = []
  let offset = 0
  while (offset < buffer.length) {
    const start = offset
    if (buffer.length - offset < 4) return { frames, tornStart: start }
    if (buffer.readUInt32LE(offset) !== ZSTD_MAGIC) {
      throw new Error(`第 ${offset} 字节不是合法的 zstd 帧头`)
    }
    offset += 4
    if (offset === buffer.length) return { frames, tornStart: start }
    const descriptor = buffer.readUInt8(offset)
    offset += 1
    if ((descriptor & 0x18) !== 0) throw new Error(`第 ${offset - 1} 字节的帧头保留位非零`)
    const contentSizeFlag = descriptor >>> 6
    const singleSegment = (descriptor & 0x20) !== 0
    const checksum = (descriptor & 0x04) !== 0
    const dictionaryFlag = descriptor & 0x03
    const dictionaryBytes = dictionaryFlag === 3 ? 4 : dictionaryFlag
    const contentSizeBytes = contentSizeFlag === 0 ? (singleSegment ? 1 : 0) : 1 << contentSizeFlag
    const remainingHeader = (singleSegment ? 0 : 1) + dictionaryBytes + contentSizeBytes
    if (buffer.length - offset < remainingHeader) return { frames, tornStart: start }
    offset += remainingHeader
    for (;;) {
      if (buffer.length - offset < 3) return { frames, tornStart: start }
      const blockHeader = buffer.readUIntLE(offset, 3)
      offset += 3
      const lastBlock = (blockHeader & 1) !== 0
      const blockType = (blockHeader >>> 1) & 0x03
      const blockSize = blockHeader >>> 3
      if (blockType === 0x03) throw new Error(`第 ${offset - 3} 字节的块类型非法`)
      const payloadBytes = blockType === 0x01 ? 1 : blockSize
      if (buffer.length - offset < payloadBytes) return { frames, tornStart: start }
      offset += payloadBytes
      if (lastBlock) break
    }
    if (checksum) {
      if (buffer.length - offset < 4) return { frames, tornStart: start }
      offset += 4
    }
    frames.push({ start, end: offset })
  }
  return { frames }
}

/** 解压 `.jsonl.zstd`：会话日志按「每批一帧」追加，需要逐帧解码后拼接。 */
function decodeLogText(raw) {
  let scan
  try {
    scan = scanZstdFrames(raw)
  } catch {
    // 结构异常时退回单帧解码，至少拿到开头。
    return { text: zstdDecompressSync(raw).toString('utf8'), partial: false, frames: 1 }
  }
  const parts = []
  let decoded = 0
  for (const { start, end } of scan.frames) {
    parts.push(zstdDecompressSync(raw.subarray(start, end)))
    decoded += 1
  }
  if (scan.tornStart !== undefined) {
    // 会话正在写入：尽力解出尾部半帧里已经完整的内容。
    try {
      parts.push(zstdDecompressSync(raw.subarray(scan.tornStart), { finishFlush: ZSTD_FLUSH }))
    } catch { /* 半帧无法解码就放弃这一段 */ }
  }
  let text = Buffer.concat(parts).toString('utf8')
  if (scan.tornStart !== undefined) {
    const cut = text.lastIndexOf('\n')
    text = cut >= 0 ? text.slice(0, cut + 1) : ''
  }
  return { text, partial: scan.tornStart !== undefined, frames: decoded }
}

function parseJsonl(text) {
  const entries = []
  let broken = 0
  for (const line of text.split('\n')) {
    const trimmed = line.trim()
    if (trimmed.length === 0) continue
    try {
      entries.push(JSON.parse(trimmed))
    } catch {
      broken += 1
    }
  }
  return { entries, broken }
}

/** 找出这个项目（cwd 匹配）下的全部会话，按时间正序返回。 */
async function loadProjectSessions(opts) {
  const root = path.join(opts.dshHome, 'sessions')
  const target = normalizePath(opts.project)
  const sessions = []
  const skipped = []
  if (!existsSync(root)) throw new Error(`找不到会话目录：${root}`)

  for (const bucket of await readdir(root, { withFileTypes: true })) {
    if (!bucket.isDirectory()) continue
    const bucketPath = path.join(root, bucket.name)
    for (const dir of await readdir(bucketPath, { withFileTypes: true })) {
      if (!dir.isDirectory()) continue
      const sessionPath = path.join(bucketPath, dir.name)
      const files = await readdir(sessionPath)
      const latest = pickLatestLog(files)
      if (!latest) continue
      const file = path.join(sessionPath, latest.name)
      let decoded
      try {
        decoded = decodeLogText(await readFile(file))
      } catch (error) {
        skipped.push({ file, reason: `解压失败：${error.message}` })
        continue
      }
      const { entries, broken } = parseJsonl(decoded.text)
      const header = entries.find(entry => entry?.type === 'session')
      if (!header) { skipped.push({ file, reason: '缺少 session 头部' }); continue }
      if (normalizePath(header.cwd) !== target) continue
      sessions.push({
        header,
        entries,
        sourceFile: file,
        formatVersion: latest.version,
        brokenLines: broken,
        partial: decoded.partial,
      })
    }
  }
  sessions.sort((a, b) => (a.header.createdAt ?? 0) - (b.header.createdAt ?? 0))
  return { sessions, skipped }
}

// ---------------------------------------------------------------- 归一化

const BLOCK_LIMIT_MARK = '\n…（已截断）'

function clip(text, limit) {
  if (typeof text !== 'string') return ''
  if (!limit || text.length <= limit) return text
  return text.slice(0, limit) + BLOCK_LIMIT_MARK
}

/** 工具调用的参数是 JSON 字符串，尽量格式化后展示。 */
function formatArgs(args) {
  if (typeof args !== 'string') return args === undefined ? '' : JSON.stringify(args, null, 2)
  try {
    return JSON.stringify(JSON.parse(args), null, 2)
  } catch {
    return args
  }
}

/** 工具结果条目里可能嵌套多层 content，拍平出纯文本。 */
function toolResultText(data) {
  const blocks = data?.message?.content
  const out = []
  let isError = false
  const walk = items => {
    if (!Array.isArray(items)) return
    for (const item of items) {
      if (!item || typeof item !== 'object') continue
      if (item.type === 'text' && typeof item.text === 'string') out.push(item.text)
      else if (item.type === 'tool-result') {
        if (item.isError) isError = true
        walk(item.content)
      } else if (Array.isArray(item.content)) walk(item.content)
    }
  }
  walk(blocks)
  return { text: out.join('\n\n'), isError }
}

function firstText(blocks) {
  for (const block of blocks ?? []) {
    if (block?.type === 'text' && typeof block.text === 'string') return block.text
  }
  return ''
}

/** 把原始日志折叠成「可阅读事件」序列；用户消息按 id 去重（spliced 与 user/message 会各记一次）。 */
function normalizeSession(raw, opts) {
  const header = raw.header
  let title = null
  let titleModel = null
  let goal = null
  const events = []
  const userById = new Map()
  const toolCallById = new Map()
  const counters = { user: 0, assistant: 0, tool: 0, plugin: 0, command: 0, compaction: 0, turns: 0 }
  let currentTurn = null
  let lastTime = header.createdAt ?? null

  const pushUser = data => {
    if (!data || data.role !== 'user') return
    const id = data.id ?? null
    const blocks = Array.isArray(data.content) ? data.content : []
    const sourceKind = data.source?.kind ?? 'unknown'
    const existing = id ? userById.get(id) : null
    // 同一条消息可能在 inbox/spliced 与 user/message 里各出现一次：保留信息更全的那份。
    if (existing) {
      if (existing.sourceKind !== 'user' && sourceKind === 'user') {
        existing.blocks = blocks
        existing.sourceKind = sourceKind
        existing.plugin = false
      }
      return
    }
    const event = {
      kind: 'user',
      id,
      seq: data.seq ?? null,
      time: data.time ?? lastTime,
      turn: currentTurn || 1,
      sourceKind,
      blocks,
      // 只有 source.kind === 'user' 才是用户真正打的字；其余是 harness 注入的上下文。
      plugin: sourceKind !== 'user',
      form: data.source?.form ?? null,
    }
    if (id) userById.set(id, event)
    counters.user += 1
    if (event.plugin) counters.plugin += 1
    events.push(event)
  }

  for (const entry of raw.entries) {
    if (!entry || typeof entry !== 'object') continue
    if (typeof entry.time === 'number') lastTime = entry.time
    const data = entry.data ?? {}
    switch (entry.type) {
      case 'session':
        break
      case 'session/title':
        if (data.title) { title = data.title; titleModel = data.source?.model ?? null }
        break
      case 'turn/start':
        // 不单独出事件：轮次直接标在消息上，避免出现「消息在轮次标题之前」的错位。
        currentTurn = data.turn ?? currentTurn
        counters.turns += 1
        break
      case 'turn/end':
        break
      case 'agent/inbox/spliced':
        for (const item of data.inserted ?? []) {
          if (item?.role === 'user') pushUser({ ...item, time: entry.time })
        }
        break
      case 'user/message':
        pushUser({ ...data, time: entry.time })
        break
      case 'assistant/message': {
        const message = data.message ?? {}
        const textParts = []
        const reasoning = []
        const toolCalls = []
        for (const block of Array.isArray(message.content) ? message.content : []) {
          if (!block || typeof block !== 'object') continue
          if (block.type === 'text' && typeof block.text === 'string') textParts.push(block.text)
          else if (block.type === 'reasoning' && typeof block.text === 'string') reasoning.push(block.text)
          else if (block.type === 'tool-call') {
            const call = {
              id: block.id,
              name: block.name ?? 'tool',
              args: formatArgs(block.arguments),
              result: null,
              isError: false,
            }
            toolCalls.push(call)
            if (call.id) toolCallById.set(call.id, call)
          }
        }
        counters.assistant += 1
        counters.tool += toolCalls.length
        events.push({
          kind: 'assistant',
          id: message.id ?? null,
          time: entry.time,
          turn: data.turn ?? currentTurn ?? 1,
          step: data.step ?? null,
          model: message.source?.model ?? null,
          provider: message.source?.provider ?? null,
          usage: data.usage ?? null,
          text: textParts.join('\n\n'),
          reasoning,
          toolCalls,
        })
        break
      }
      case 'tool/result': {
        const { text, isError } = toolResultText(data)
        const callId = data.message?.source?.callId
          ?? firstCallId(data.message?.content)
        const call = callId ? toolCallById.get(callId) : null
        if (call) {
          call.result = text
          call.isError = isError
        } else {
          counters.tool += 1
          const orphan = { kind: 'tool-result', time: entry.time, callId: callId ?? null, text, isError }
          events.push(orphan)
        }
        break
      }
      case 'command/run':
        counters.command += 1
        events.push({ kind: 'command', time: entry.time, name: data.name ?? 'command', args: data.args ?? '', commandId: data.commandId ?? null })
        break
      case 'command/done':
        break
      case 'compaction/start':
        events.push({ kind: 'compaction', time: entry.time, phase: 'start' })
        break
      case 'compaction/summary':
        counters.compaction += 1
        events.push({
          kind: 'compaction',
          time: entry.time,
          phase: 'summary',
          text: firstText(data.summary),
        })
        break
      case 'goal/change':
        goal = data.goal ?? goal
        events.push({ kind: 'goal', time: entry.time, data })
        break
      case 'session/end-seed':
        events.push({ kind: 'note', time: entry.time, text: '（空会话：只完成了初始化）' })
        break
      default:
        break
    }
  }

  if (!title) {
    const firstUser = events.find(event => event.kind === 'user' && !event.plugin)
    const text = firstUser ? firstText(firstUser.blocks).replace(/\s+/g, ' ').trim() : ''
    title = text ? text.slice(0, 24) : '（空会话）'
  }

  const lastTime2 = events.reduce((acc, event) => Math.max(acc, event.time ?? 0), header.createdAt ?? 0)
  return {
    id: header.id ?? path.basename(path.dirname(raw.sourceFile)),
    cwd: header.cwd,
    createdAt: header.createdAt ?? null,
    updatedAt: lastTime2 || null,
    agentPreset: header.agentPreset ?? null,
    delegationDepth: header.delegationDepth ?? 0,
    title,
    titleModel,
    goal,
    model: events.find(event => event.kind === 'assistant' && event.model)?.model ?? null,
    counters,
    events,
    sourceFile: raw.sourceFile,
    formatVersion: raw.formatVersion,
    brokenLines: raw.brokenLines,
    partial: raw.partial,
    toolChars: opts.toolChars,
    reasoningMode: opts.reasoning,
  }
}

function firstCallId(content) {
  for (const item of Array.isArray(content) ? content : []) {
    if (item?.type === 'tool-result' && item.toolCallId) return item.toolCallId
  }
  return null
}

// ---------------------------------------------------------------- 格式化

const TIME_FMT = new Intl.DateTimeFormat('zh-CN', {
  timeZone: 'Asia/Shanghai',
  year: 'numeric', month: '2-digit', day: '2-digit',
  hour: '2-digit', minute: '2-digit', hour12: false,
})

function stamp(ms, withSeconds = false) {
  if (typeof ms !== 'number' || ms <= 0) return '—'
  const text = TIME_FMT.format(new Date(ms))
  if (!withSeconds) return text
  const seconds = new Date(ms).getSeconds().toString().padStart(2, '0')
  return `${text}:${seconds}`
}

const REASONING_LIMIT = 1200

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

function durationText(ms) {
  if (typeof ms !== 'number' || ms < 0) return ''
  const seconds = Math.round(ms / 1000)
  if (seconds < 60) return `${seconds} 秒`
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes} 分 ${seconds % 60} 秒`
  const hours = Math.floor(minutes / 60)
  return `${hours} 小时 ${minutes % 60} 分`
}

function bytesText(count) {
  if (count < 1024) return `${count} B`
  if (count < 1024 * 1024) return `${(count / 1024).toFixed(1)} KB`
  return `${(count / 1024 / 1024).toFixed(1)} MB`
}

// ---------------------------------------------------------------- HTML

const STYLE = `
:root{--bg:#f6f4ef;--panel:#fffdf9;--ink:#2f2a24;--muted:#8a8177;--line:#e6dfd4;
--user:#2f6f5e;--user-bg:#e8f4ef;--assistant-bg:#fffdf9;--tool-bg:#f2efe8;--accent:#b4762c;}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.75 -apple-system,"Segoe UI","Microsoft YaHei",system-ui,sans-serif}
a{color:var(--accent)}
.wrap{max-width:960px;margin:0 auto;padding:24px 20px 80px}
header.page{position:sticky;top:0;z-index:5;background:rgba(246,244,239,.94);backdrop-filter:blur(6px);
border-bottom:1px solid var(--line);padding:14px 20px;margin:0 -20px 20px}
h1{font-size:20px;margin:0 0 6px}
.meta{color:var(--muted);font-size:12.5px;line-height:1.9;word-break:break-all}
.badges{display:flex;flex-wrap:wrap;gap:6px;margin-top:8px}
.badge{background:var(--tool-bg);border:1px solid var(--line);border-radius:999px;padding:1px 9px;font-size:12px;color:var(--muted)}
.badge.warn{color:#a4451f;border-color:#e6c3b3;background:#fbeee8}
.toolbar{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin:14px 0 6px}
.toolbar input[type=search]{flex:1 1 220px;min-width:180px;padding:7px 11px;border:1px solid var(--line);
border-radius:9px;background:var(--panel);color:inherit;font:inherit}
.toolbar label{font-size:13px;color:var(--muted);display:flex;align-items:center;gap:5px;user-select:none}
.hidden{display:none !important}
.turn{border-top:1px dashed var(--line);margin-top:26px;padding-top:8px;color:var(--muted);font-size:12px;letter-spacing:.04em}
.msg{margin:12px 0;border-radius:14px;padding:12px 15px;border:1px solid var(--line);background:var(--assistant-bg)}
.msg .who{font-size:12.5px;color:var(--muted);margin-bottom:6px;display:flex;gap:8px;flex-wrap:wrap;align-items:baseline}
.msg .who b{color:var(--accent);font-weight:600}
.msg.user{background:var(--user-bg);border-color:#cfe3da;border-left:4px solid var(--user)}
.msg.user .who b{color:var(--user)}
.msg.plugin{background:#f4f1ea;border-style:dashed;opacity:.85}
.msg.assistant{border-left:4px solid var(--accent)}
.body{white-space:pre-wrap;word-break:break-word}
.body code{background:var(--tool-bg);padding:1px 5px;border-radius:5px;font-size:13px}
details.tool,details.reasoning,details.ctx{margin:8px 0;border:1px solid var(--line);border-radius:10px;background:var(--tool-bg)}
details summary{cursor:pointer;padding:6px 11px;font-size:13px;color:var(--muted);display:flex;gap:8px;align-items:baseline;flex-wrap:wrap}
details summary .name{color:var(--ink);font-weight:600;font-family:ui-monospace,Consolas,monospace}
details[open] summary{border-bottom:1px solid var(--line)}
pre{margin:0;padding:10px 12px;overflow:auto;max-height:420px;font:12.5px/1.65 ui-monospace,Consolas,"Courier New",monospace;white-space:pre-wrap;word-break:break-word}
pre.err{color:#a4451f}
.notes{color:var(--muted);font-size:13px;text-align:center;margin:22px 0}
.summary-card{background:var(--panel);border:1px solid var(--line);border-left:4px solid #7a6bd6;border-radius:12px;padding:12px 15px;margin:14px 0}
.summary-card .body{font-size:14px}
.item{display:block;padding:14px 16px;margin:10px 0;border:1px solid var(--line);border-radius:14px;background:var(--panel);text-decoration:none;color:inherit}
.item:hover{border-color:var(--accent);box-shadow:0 2px 10px rgba(0,0,0,.05)}
.item h2{margin:0 0 4px;font-size:16px;color:var(--ink)}
.empty{color:var(--muted);padding:10px 0}
`.trim()

const SCRIPT = `
const query = document.getElementById('q')
const showTools = document.getElementById('showTools')
const showReasoning = document.getElementById('showReasoning')
const showPlugin = document.getElementById('showPlugin')
const count = document.getElementById('count')
function apply(){
  const q = (query.value || '').trim().toLowerCase()
  const messages = Array.from(document.querySelectorAll('.msg, .summary-card, .notes'))
  let shown = 0
  for (const el of messages){
    let ok = true
    if (!showTools.checked && el.dataset.kind === 'tool-only') ok = false
    if (!showReasoning.checked && el.dataset.kind === 'reasoning-only') ok = false
    if (!showPlugin.checked && el.classList.contains('plugin')) ok = false
    if (ok && q) ok = (el.dataset.search || el.textContent).toLowerCase().includes(q)
    el.classList.toggle('hidden', !ok)
    if (ok) shown++
  }
  count.textContent = q ? shown + ' / ' + messages.length + ' 条匹配' : '共 ' + messages.length + ' 条'
}
query.addEventListener('input', apply)
for (const el of [showTools, showReasoning, showPlugin]) el.addEventListener('change', apply)
apply()
`.trim()

function htmlShell({ title, headerHtml, bodyHtml, toolbar = true }) {
  const toolbarHtml = toolbar ? `
<div class="toolbar">
  <input id="q" type="search" placeholder="搜索本页内容（用户消息 / 助手回复 / 工具输出）">
  <label><input id="showTools" type="checkbox" checked> 工具调用</label>
  <label><input id="showReasoning" type="checkbox"> 思考过程</label>
  <label><input id="showPlugin" type="checkbox"> 系统注入</label>
  <span class="meta" id="count"></span>
</div>` : ''
  return `<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escapeHtml(title)}</title>
<style>${STYLE}</style>
</head>
<body>
<div class="wrap">
<header class="page">
${headerHtml}
${toolbarHtml}
</header>
${bodyHtml}
</div>
${toolbar ? `<script>${SCRIPT}</script>` : ''}
</body>
</html>
`
}

function renderToolHtml(call, toolChars) {
  const resultText = call.result ?? ''
  const clipped = clip(resultText, toolChars)
  const truncated = clipped !== resultText
  return `<details class="tool">
<summary><span class="name">${escapeHtml(call.name)}</span><span>参数${call.args ? '' : '（无）'}</span>${call.isError ? '<span class="badge warn">失败</span>' : ''}${resultText ? `<span>· 输出 ${escapeHtml(bytesText(resultText.length))}${truncated ? '（已截断）' : ''}</span>` : '<span>· 无输出</span>'}</summary>
<pre>${escapeHtml(call.args || '')}</pre>
${resultText ? `<pre class="${call.isError ? 'err' : ''}">${escapeHtml(clipped)}</pre>` : ''}
</details>`
}

/** 注入类消息的来源中文名。 */
const SOURCE_LABELS = {
  plugin: '系统注入',
  'agent-instructions': '工作区指令',
  'skill-catalog': '技能目录',
  unknown: '系统注入',
}

function sourceLabel(sourceKind) {
  return SOURCE_LABELS[sourceKind] ?? `系统注入（${sourceKind}）`
}

function renderSessionBody(session, opts) {
  const out = []
  const toolChars = opts.toolChars
  let renderedTurn = null
  for (const event of session.events) {
    if ((event.kind === 'user' || event.kind === 'assistant') && event.turn !== renderedTurn) {
      renderedTurn = event.turn
      out.push(`<div class="turn">第 ${event.turn ?? '?'} 轮</div>`)
    }
    switch (event.kind) {
      case 'user': {
        const text = event.blocks.map(block => block?.type === 'text' ? block.text : '').filter(Boolean).join('\n\n')
        const images = event.blocks.filter(block => block?.type === 'image').length
        const kind = event.plugin ? 'plugin' : 'user'
        out.push(`<div class="msg ${kind}" data-kind="user" data-search="${escapeHtml((text || '').slice(0, 4000))}">
<div class="who"><b>${event.plugin ? escapeHtml(sourceLabel(event.sourceKind)) : '用户'}</b><span>${escapeHtml(stamp(event.time, true))}</span>${event.form ? `<span>· ${escapeHtml(event.form)}</span>` : ''}${images ? `<span>· ${images} 张图片</span>` : ''}</div>
<div class="body">${escapeHtml(text || '（无文本内容）')}</div>
</div>`)
        break
      }
      case 'assistant': {
        const toolsHtml = event.toolCalls.map(call => renderToolHtml(call, toolChars)).join('\n')
        const reasoningHtml = renderReasoningHtml(event.reasoning, opts)
        const usage = event.usage
        const meta = [
          stamp(event.time, true),
          event.model ? escapeHtml(event.model) : '',
          usage?.totalTokens ? `${usage.totalTokens} tokens` : '',
        ].filter(Boolean).join(' · ')
        const kindAttr = event.text ? 'assistant' : (event.toolCalls.length ? 'tool-only' : 'reasoning-only')
        out.push(`<div class="msg assistant" data-kind="${kindAttr}" data-search="${escapeHtml((event.text || '').slice(0, 4000))}">
<div class="who"><b>助手</b><span>${meta}</span>${event.step ? `<span>· 步骤 ${event.step}</span>` : ''}</div>
${event.text ? `<div class="body">${escapeHtml(event.text)}</div>` : ''}
${reasoningHtml}
${toolsHtml}
</div>`)
        break
      }
      case 'tool-result':
        out.push(`<div class="msg assistant" data-kind="tool-only">
<div class="who"><b>工具输出</b><span>${escapeHtml(stamp(event.time, true))}</span>${event.callId ? `<span>· ${escapeHtml(event.callId)}</span>` : ''}</div>
<pre class="${event.isError ? 'err' : ''}">${escapeHtml(clip(event.text, toolChars))}</pre>
</div>`)
        break
      case 'command':
        out.push(`<div class="msg plugin" data-kind="note"><div class="who"><b>命令</b><span>${escapeHtml(stamp(event.time, true))}</span></div><div class="body">/${escapeHtml(event.name)}${escapeHtml(event.args)}</div></div>`)
        break
      case 'compaction':
        if (event.phase === 'summary') {
          out.push(`<div class="summary-card" data-kind="note"><div class="who"><b>上下文压缩摘要</b><span>${escapeHtml(stamp(event.time, true))}</span></div><div class="body">${escapeHtml(event.text || '（无摘要文本）')}</div></div>`)
        }
        break
      case 'goal':
        out.push(`<div class="notes" data-kind="note">目标更新 · ${escapeHtml(stamp(event.time, true))}</div>`)
        break
      case 'note':
        out.push(`<div class="notes" data-kind="note">${escapeHtml(event.text)}</div>`)
        break
      default:
        break
    }
  }
  return out.join('\n')
}

function renderReasoningHtml(parts, opts) {
  if (opts.reasoning === 'off') return ''
  if (!parts || parts.length === 0) return ''
  const joined = parts.filter(part => part && part.trim()).join('\n\n')
  if (!joined) return ''
  const shown = opts.reasoning === 'full' ? joined : clip(joined, REASONING_LIMIT)
  return `<details class="reasoning"><summary>思考过程 · ${joined.length} 字</summary><pre>${escapeHtml(shown)}</pre></details>`
}

function renderSessionPage(session, opts) {
  const counters = session.counters
  const userTotal = session.events.filter(event => event.kind === 'user' && !event.plugin).length
  const badges = [
    `<span class="badge">会话 ${escapeHtml(session.id)}</span>`,
    `<span class="badge">${escapeHtml(stamp(session.createdAt))} 起</span>`,
    session.updatedAt ? `<span class="badge">最后活动 ${escapeHtml(stamp(session.updatedAt))}</span>` : '',
    `<span class="badge">${counters.turns} 轮</span>`,
    `<span class="badge">用户 ${userTotal}</span>`,
    `<span class="badge">助手 ${counters.assistant}</span>`,
    `<span class="badge">工具 ${counters.tool}</span>`,
    session.model ? `<span class="badge">${escapeHtml(session.model)}</span>` : '',
    session.delegationDepth > 0 ? `<span class="badge">子代理（深度 ${session.delegationDepth}）</span>` : '',
    session.partial ? '<span class="badge warn">日志尾部未写完，已导出可解部分</span>' : '',
    session.brokenLines > 0 ? `<span class="badge warn">${session.brokenLines} 行无法解析</span>` : '',
  ].filter(Boolean).join('\n')
  const headerHtml = `<h1>${escapeHtml(session.title)}</h1>
<div class="meta">项目：${escapeHtml(session.cwd)}<br>来源：${escapeHtml(path.basename(path.dirname(session.sourceFile)))}/${escapeHtml(path.basename(session.sourceFile))}（格式 v${session.formatVersion}）</div>
<div class="badges">${badges}</div>
<div class="meta"><a href="index.html">← 返回会话列表</a></div>`
  const body = renderSessionBody(session, opts)
  return htmlShell({
    title: `${session.title} · 会话记录`,
    headerHtml,
    bodyHtml: body,
  })
}

function renderIndexPage(sessions, opts) {
  const totalUser = sessions.reduce((sum, session) => sum + session.events.filter(event => event.kind === 'user' && !event.plugin).length, 0)
  const totalAssistant = sessions.reduce((sum, session) => sum + session.counters.assistant, 0)
  const totalTool = sessions.reduce((sum, session) => sum + session.counters.tool, 0)
  const pages = sessions.map(session => {
    const userTotal = session.events.filter(event => event.kind === 'user' && !event.plugin).length
    const first = session.events.find(event => event.kind === 'user' && !event.plugin)
    const preview = first ? first.blocks.map(b => b?.type === 'text' ? b.text : '').join(' ').replace(/\s+/g, ' ').slice(0, 150) : ''
    const span = session.updatedAt && session.createdAt
      ? `持续 ${durationText(session.updatedAt - session.createdAt)}`
      : ''
    const stat = userTotal === 0 && session.counters.assistant === 0
      ? '未产生对话（只完成了会话初始化）'
      : `${session.counters.turns} 轮 · 用户 ${userTotal} / 助手 ${session.counters.assistant} / 工具 ${session.counters.tool}`
    return `<a class="item" href="${escapeHtml(session.fileName)}">
<h2>${escapeHtml(session.title)}</h2>
<div class="meta">${escapeHtml(stamp(session.createdAt))}${span && userTotal > 0 ? ` · ${escapeHtml(span)}` : ''} · ${escapeHtml(stat)}</div>
<div class="meta">${escapeHtml(preview)}${preview.length >= 150 ? '…' : ''}</div>
</a>`
  }).join('\n')
  const headerHtml = `<h1>babydaily 会话记录</h1>
<div class="meta">项目：${escapeHtml(opts.project)}<br>导出时间：${escapeHtml(stamp(Date.now(), true))} · 共 ${sessions.length} 个会话 · 用户消息 ${totalUser} / 助手回复 ${totalAssistant} / 工具调用 ${totalTool}</div>`
  return htmlShell({
    title: 'babydaily 会话记录',
    headerHtml,
    bodyHtml: pages || '<div class="empty">没有找到该项目的会话记录。</div>',
    toolbar: false,
  })
}

// ---------------------------------------------------------------- Markdown

function mdSanitize(value) {
  return String(value ?? '').replace(/[<>:"/\\|?*\u0000-\u001f]/g, '_').replace(/\s+/g, ' ').trim().slice(0, 60)
}

function renderSessionMarkdown(session, opts) {
  const lines = []
  lines.push(`# ${session.title}`)
  lines.push('')
  lines.push(`- 会话 ID：\`${session.id}\``)
  lines.push(`- 起止：${stamp(session.createdAt)} → ${stamp(session.updatedAt)}`)
  lines.push(`- 模型：${session.model ?? '—'}`)
  lines.push(`- 轮数：${session.counters.turns} · 用户 ${session.events.filter(e => e.kind === 'user' && !e.plugin).length} · 助手 ${session.counters.assistant} · 工具 ${session.counters.tool}`)
  lines.push('')
  let renderedTurn = null
  for (const event of session.events) {
    const isMessage = event.kind === 'user' || event.kind === 'assistant'
    if (isMessage && event.turn !== renderedTurn) {
      renderedTurn = event.turn
      lines.push('---', '', `## 第 ${event.turn ?? '?'} 轮`, '')
    }
    switch (event.kind) {
      case 'user': {
        const text = event.blocks.map(b => b?.type === 'text' ? b.text : '').filter(Boolean).join('\n\n')
        lines.push(event.plugin
          ? `> **${sourceLabel(event.sourceKind)}** · ${stamp(event.time)}`
          : `### 👤 用户 · ${stamp(event.time)}`, '')
        lines.push(...quote(text || '（无文本内容）'))
        lines.push(`<!-- kind:${event.sourceKind} -->`)
        lines.push('')
        break
      }
      case 'assistant': {
        if (event.text.trim()) {
          lines.push(`### 🤖 助手 · ${stamp(event.time)}${event.model ? ` · ${event.model}` : ''}`, '')
          lines.push(event.text.trim(), '')
        }
        if (opts.reasoning !== 'off') {
          const joined = event.reasoning.filter(part => part && part.trim()).join('\n\n')
          if (joined) {
            const shown = opts.reasoning === 'full' ? joined : clip(joined, REASONING_LIMIT)
            lines.push('<details><summary>思考过程</summary>', '', shown, '', '</details>', '')
          }
        }
        for (const call of event.toolCalls) {
          const resultText = call.result ?? ''
          const clipped = clip(resultText, opts.toolChars)
          lines.push(`<details><summary>🔧 ${call.name}${call.isError ? '（失败）' : ''}</summary>`, '')
          if (call.args) lines.push('参数：', '', '```json', call.args, '```', '')
          if (resultText) lines.push('输出：', '', '```', clipped, '```', '')
          lines.push('</details>', '')
        }
        break
      }
      case 'command':
        lines.push(`> 命令：\`/${event.name}${event.args}\` · ${stamp(event.time)}`, '')
        break
      case 'compaction':
        if (event.phase === 'summary') {
          lines.push('### 📦 上下文压缩摘要', '', event.text || '（无摘要文本）', '')
        }
        break
      case 'note':
        lines.push(`> ${event.text}`, '')
        break
      default:
        break
    }
  }
  return lines.join('\n')
}

function quote(text) {
  return String(text).split('\n').map(line => (line.length ? `> ${line}` : '>'))
}

// ---------------------------------------------------------------- 主流程

async function main() {
  const opts = parseArgs(process.argv.slice(2))
  const log = (...args) => { if (!opts.quiet) console.log(...args) }
  log(`扫描：${path.join(opts.dshHome, 'sessions')}`)
  log(`项目：${opts.project}`)

  const { sessions: rawSessions, skipped } = await loadProjectSessions(opts)
  for (const item of skipped) log(`跳过 ${item.file}：${item.reason}`)
  if (rawSessions.length === 0) {
    console.error('没有找到该项目的会话记录。可用 --project 指定其它项目路径。')
    process.exitCode = 1
    return
  }

  const sessions = rawSessions.map(raw => normalizeSession(raw, opts))
  sessions.sort((a, b) => (a.createdAt ?? 0) - (b.createdAt ?? 0))

  await mkdir(opts.out, { recursive: true })
  const mdDir = path.join(opts.out, 'md')

  // 清掉上一次导出的页面，避免会话改名后留下旧文件。
  for (const name of await readdir(opts.out)) {
    if (/^session-.*\.html$/.test(name)) await rm(path.join(opts.out, name), { force: true })
  }
  if (existsSync(mdDir)) {
    for (const name of await readdir(mdDir)) {
      if (/^session-.*\.md$/.test(name)) await rm(path.join(mdDir, name), { force: true })
    }
  }

  const files = []
  sessions.forEach((session, index) => {
    const ordinal = String(index + 1).padStart(2, '0')
    const shortId = session.id.replace(/^session-/, '').slice(0, 8)
    session.fileName = `session-${ordinal}-${mdSanitize(session.title)}-${shortId}.html`
  })

  const indexHtml = renderIndexPage(sessions, opts)
  await writeFile(path.join(opts.out, 'index.html'), indexHtml, 'utf8')
  files.push('index.html')

  for (const session of sessions) {
    await writeFile(path.join(opts.out, session.fileName), renderSessionPage(session, opts), 'utf8')
    files.push(session.fileName)
    if (opts.md) {
      await mkdir(mdDir, { recursive: true })
      const mdName = session.fileName.replace(/\.html$/, '.md')
      await writeFile(path.join(mdDir, mdName), renderSessionMarkdown(session, opts), 'utf8')
      files.push(path.join('md', mdName))
    }
  }

  const dump = sessions.map(session => ({
    id: session.id,
    title: session.title,
    cwd: session.cwd,
    createdAt: session.createdAt,
    updatedAt: session.updatedAt,
    model: session.model,
    delegationDepth: session.delegationDepth,
    counters: session.counters,
    sourceFile: session.sourceFile,
    html: session.fileName,
    events: session.events.map(event => {
      if (event.kind === 'assistant') {
        return {
          ...event,
          reasoning: opts.reasoning === 'full' ? event.reasoning : event.reasoning.map(part => clip(part, REASONING_LIMIT)),
          toolCalls: event.toolCalls.map(call => ({ ...call, result: clip(call.result ?? '', opts.toolChars) })),
        }
      }
      if (event.kind === 'tool-result') return { ...event, text: clip(event.text, opts.toolChars) }
      return event
    }),
  }))
  await writeFile(path.join(opts.out, 'sessions.json'), JSON.stringify({
    project: opts.project,
    exportedAt: new Date().toISOString(),
    dshHome: opts.dshHome,
    sessionCount: sessions.length,
    sessions: dump,
  }, null, 2), 'utf8')
  files.push('sessions.json')

  let bytes = 0
  for (const file of files) {
    try {
      const stat = await lstat(path.join(opts.out, file))
      bytes += stat.size
    } catch { /* 忽略 */ }
  }

  console.log('')
  console.log(`导出完成：${opts.out}`)
  console.log(`会话 ${sessions.length} 个：`)
  for (const [index, session] of sessions.entries()) {
    const userTotal = session.events.filter(event => event.kind === 'user' && !event.plugin).length
    console.log(`  ${String(index + 1).padStart(2, '0')}. ${session.title}（${stamp(session.createdAt)} · ${session.counters.turns} 轮 · 用户 ${userTotal} / 助手 ${session.counters.assistant} / 工具 ${session.counters.tool}）`)
  }
  console.log(`文件 ${files.length} 个，约 ${bytesText(bytes)}；入口：${path.join(opts.out, 'index.html')}`)
}

main().catch(error => {
  console.error(`导出失败：${error.stack ?? error.message}`)
  process.exitCode = 1
})
