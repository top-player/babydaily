package com.yjym.baby.babydaily

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 备份存储通道（ADR-0005 / ADR-0008）：
 * - 导出：Android 10+ 走 MediaStore 写入公共下载目录（Download/BabyDaily），
 *   写入期间标记 IS_PENDING，写完才对外可见；Android 9 及以下回退公共
 *   Download 目录（需 WRITE_EXTERNAL_STORAGE，maxSdkVersion 28）。
 * - 导入：交给系统文件选择器（ACTION_OPEN_DOCUMENT），用户可选任意位置的
 *   json（含从电脑/旧手机拷来的），不再依赖应用自己去列目录——列目录只能
 *   看到本应用自己写入的文件，换机后必然"识别不到"。
 *
 * 数据库本体仍在应用私有目录（ADR-0001），只有备份文件放公共目录。
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.yjym.baby.babydaily/storage"
    private val backupDir = "Download/BabyDaily"
    private val pickRequestCode = 0x5A11

    /** 正在等待结果的系统文件选择器回调（同一时刻只允许一个）。 */
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveBackup" -> {
                        val json = call.argument<String>("json")
                        val name = call.argument<String>("name")
                        if (json == null || name == null) {
                            result.error("BAD_ARG", "缺少 json 或 name", null)
                            return@setMethodCallHandler
                        }
                        runCatching { saveBackup(json, name) }
                            .onSuccess { result.success(it) }
                            .onFailure { e ->
                                result.error("SAVE_FAILED", e.message ?: "写入下载目录失败", null)
                            }
                    }
                    "pickBackup" -> pickBackup(result)
                    else -> result.notImplemented()
                }
            }
    }

    // ---- 导入：系统文件选择器 ----

    private fun pickBackup(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("BUSY", "已经有一个文件选择器在运行", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            // 不限 MIME：各家文件管理器对 .json 的判定不一致（application/json、
            // text/plain、application/octet-stream 都有），限类型反而会让备份"消失"。
            type = "*/*"
        }
        pendingPick = result
        try {
            startActivityForResult(intent, pickRequestCode)
        } catch (e: Exception) {
            pendingPick = null
            result.error("NO_PICKER", e.message ?: "无法打开系统文件选择器", null)
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequestCode) return
        val result = pendingPick ?: return
        pendingPick = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(null) // 用户取消：不是错误
            return
        }
        val uri = data?.data
        if (uri == null) {
            result.error("NO_URI", "没有拿到所选文件的地址", null)
            return
        }
        // 读文件放到后台线程，结果回到主线程回复 Dart（通道要求主线程）。
        Thread {
            val outcome = runCatching { readPickedBackup(uri) }
            runOnUiThread {
                outcome
                    .onSuccess { result.success(it) }
                    .onFailure { e ->
                        result.error("READ_FAILED", e.message ?: "读取所选文件失败", null)
                    }
            }
        }.start()
    }

    private fun readPickedBackup(uri: Uri): Map<String, Any?> {
        val resolver = applicationContext.contentResolver
        val name = queryDisplayName(uri)
            ?: uri.lastPathSegment?.substringAfterLast('/')
            ?: "backup.json"
        val text = resolver.openInputStream(uri)?.use { input ->
            input.bufferedReader(Charsets.UTF_8).readText()
        } ?: throw IllegalStateException("无法打开所选文件")
        if (text.isBlank()) throw IllegalStateException("所选文件是空的")
        return mapOf("name" to name, "json" to text)
    }

    private fun queryDisplayName(uri: Uri): String? = runCatching {
        applicationContext.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
    }.getOrNull()

    // ---- 导出：公共下载目录 ----

    private fun saveBackup(json: String, name: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val collection =
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
                put(MediaStore.MediaColumns.RELATIVE_PATH, "$backupDir/")
                // 写完才发布：中途失败不会留下一个"看得见但读不出"的半截文件
                // （旧实现没有这一步，文件管理器偶尔扫不到刚写下的备份）。
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("系统拒绝写入下载目录")
            try {
                resolver.openOutputStream(uri)?.use { out ->
                    out.write(json.toByteArray(Charsets.UTF_8))
                    out.flush()
                } ?: throw IllegalStateException("无法打开输出流")
                resolver.update(
                    uri,
                    ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                    null,
                    null,
                )
            } catch (e: Exception) {
                runCatching { resolver.delete(uri, null, null) } // 失败不留残缺文件
                throw e
            }
            if (!canReadBack(uri)) {
                runCatching { resolver.delete(uri, null, null) }
                throw IllegalStateException("备份写入后无法读回，请重试")
            }
            val actualName = queryDisplayName(uri) ?: name
            "$backupDir/$actualName"
        } else {
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                "BabyDaily",
            )
            if (!dir.exists() && !dir.mkdirs()) throw IllegalStateException("无法创建备份目录")
            File(dir, name).writeText(json, Charsets.UTF_8)
            "$backupDir/$name"
        }
    }

    /** 回读校验：确认换机/文件管理器都能拿到这份备份。 */
    private fun canReadBack(uri: Uri): Boolean = runCatching {
        applicationContext.contentResolver.openInputStream(uri)?.use { it.read() }
        true
    }.getOrDefault(false)
}
