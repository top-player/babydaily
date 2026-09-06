package com.yjym.baby.babydaily

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 备份存储通道（ADR-0005）：
 * Android 10+ 走 MediaStore 写入公共下载目录（Download/BabyDaily），
 * 让小米/新安卓的文件管理器都能看到；Android 9 及以下回退公共
 * Download 目录（需 WRITE_EXTERNAL_STORAGE，maxSdkVersion 28）。
 *
 * 数据库本体仍在应用私有目录（ADR-0001），只有备份文件放公共目录。
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.yjym.baby.babydaily/storage"
    private val backupDir = "Download/BabyDaily"

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
                    "listBackups" -> {
                        runCatching { listBackups() }
                            .onSuccess { result.success(it) }
                            .onFailure { e ->
                                result.error("LIST_FAILED", e.message ?: "读取备份列表失败", null)
                            }
                    }
                    "readBackup" -> {
                        val name = call.argument<String>("name")
                        if (name == null) {
                            result.error("BAD_ARG", "缺少 name", null)
                            return@setMethodCallHandler
                        }
                        runCatching { readBackup(name) }
                            .onSuccess { result.success(it) }
                            .onFailure { e ->
                                result.error("READ_FAILED", e.message ?: "读取备份失败", null)
                            }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveBackup(json: String, name: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
                put(MediaStore.MediaColumns.RELATIVE_PATH, "$backupDir/")
            }
            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("系统拒绝写入下载目录")
            resolver.openOutputStream(uri)?.use { it.write(json.toByteArray(Charsets.UTF_8)) }
                ?: throw IllegalStateException("无法打开输出流")
            "$backupDir/$name"
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

    private data class BackupInfo(val name: String, val timestamp: Long, val readable: Boolean)

    private fun listBackups(): List<Map<String, Any?>> {
        val result = mutableListOf<BackupInfo>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            val projection = arrayOf(
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.DATE_ADDED,
                MediaStore.MediaColumns._ID,
            )
            val selection = "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
            val order = "${MediaStore.MediaColumns.DATE_ADDED} DESC"
            resolver.query(
                collection,
                projection,
                selection,
                arrayOf("$backupDir/%"),
                order,
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val name = cursor.getString(0) ?: continue
                    if (!name.endsWith(".json")) continue
                    val stamp = cursor.getLong(1)
                    val id = cursor.getLong(2)
                    val uri = collection.buildUpon().appendPath("$id").build()
                    val readable = try {
                        resolver.openInputStream(uri)?.use { }
                        true
                    } catch (_: Exception) {
                        false
                    }
                    result.add(BackupInfo(name, stamp, readable))
                }
            }
        } else {
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                "BabyDaily",
            )
            dir.listFiles()?.sortedByDescending { it.lastModified() }?.forEach { f ->
                result.add(BackupInfo(f.name, f.lastModified() / 1000, true))
            }
        }
        return result.map {
            mapOf("name" to it.name, "timestamp" to it.timestamp, "readable" to it.readable)
        }
    }

    private fun readBackup(name: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            val projection = arrayOf(MediaStore.MediaColumns._ID)
            val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ? " +
                "AND ${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
            val id = resolver.query(
                collection,
                projection,
                selection,
                arrayOf(name, "$backupDir/%"),
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getLong(0)
                } else {
                    throw IllegalStateException("找不到文件 $name")
                }
            } ?: throw IllegalStateException("找不到文件 $name")
            val uri = collection.buildUpon().appendPath("$id").build()
            resolver.openInputStream(uri)?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }
                ?: throw IllegalStateException("无法读取 $name")
        } else {
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                "BabyDaily",
            )
            File(dir, name).readText(Charsets.UTF_8)
        }
    }
}
