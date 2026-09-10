# 宝宝日常

轻松治愈的个人成长 RPG（Android / Flutter）：主角通过完成任务、坚持习惯、随手写笔记获得成长，用等级、属性与连续记录鼓励长期坚持。

## 玩法

- **主角**：姓名/年龄/性别自设；经验值驱动等级（满级 50，称号随等级解锁）；健康值/自律值/魅力值 0–100，不衰减。
- **任务**：主线（长期目标，可拆子项，全部完成自动发完成奖励）、支线（一次性）、每日任务（0 点重置，未完成会扣除配置属性）；奖励只配置三属性，经验值由系统固定发放。
- **习惯**：每日 / 每周 N 次；打卡默认 +1 自律、+5 经验；连续 10/20/30 天有一次性里程碑奖励；断签归零、累计次数永久保留；月历 + 年度热力图展示。
- **笔记**：一天多篇、按天翻页、全文搜索；写满 20 字当天 +10 经验，连续写有加成（封顶 15）。
- **场景**：家里 / 公司 / 游玩三套氛围（主题色、问候与提示文案），手动切换。

## 工程

- 领域规则（经验经济、等级曲线、连续计算、每日结算、笔记经验）以单元测试锁定，见 `test/domain/`。
- 工程规范（改完必须提交、分 ABI 构建 release 并 adb 装机）：`AGENTS.md`。
- 设计上下文：`CONTEXT.md`（术语表）；关键决策：`docs/adr/`（本地 SQLite+JSON 备份 / 习惯与任务分离 / 经验经济 / 每日结算惩罚）。
- 对话记录导出：`node tools/export_sessions.mjs` —— 把本项目在 DSH 里的全部会话（`~/.dsh/sessions/` 下的 zstd JSONL 日志）导出成 `exports/conversations/`：`index.html` 总览 + 每会话一份 HTML（气泡视图、工具调用可折叠、支持搜索过滤）+ 同名 Markdown + `sessions.json` 结构化数据。该目录不入库。

## 开发

```sh
flutter pub get
dart run build_runner build   # drift 代码生成
flutter test                  # 全部测试
flutter build apk --release --split-per-abi --split-debug-info=build/symbols --obfuscate
# 分 ABI 构建（8–9MB）：小米等 arm64 机型装 app-arm64-v8a-release.apk
# 符号表在 build/symbols/，配合混淆可还原崩溃栈
```

### 应用图标

源图 `icon2.png`（圆角方块插画：小人爬楼梯奔向星星，奶油底 `#FCF0DF`）。资源由脚本生成，不要手改 `mipmap-*` 下的 PNG：

```sh
python build/icons/gen_icons.py      # 五档传统图标 48–192px + 五档自适应前景（108/108 dp 满铺）
python build/icons/verify_icon2.py   # 合成遮罩预览，核对底色与前景无接缝
```

- API < 26 用 `ic_launcher.png`（原图圆角方块直接缩放）。
- API ≥ 26 用自适应图标：前景按 108/108 dp 满铺遮罩视口，底色层 `#FCF0DF` 与前景方块填色通道差 ≤1，任何遮罩形状下都不会露出色环或接缝。
