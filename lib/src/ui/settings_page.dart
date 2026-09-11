/// 设置页：JSON 备份导出/导入（ADR-0005 / ADR-0008）、关于。
///
/// 导出：Android 10+ 通过 MediaStore 写入公共「下载/BabyDaily」，
/// 小米/新安卓的文件管理器可见；旧系统或通道不可用时回退应用文档目录。
/// 导入：调用系统文件选择器（ACTION_OPEN_DOCUMENT）选任意位置的备份 json。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:babydaily/src/domain/xp_economy.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/feedback.dart';
import 'package:babydaily/src/ui/theme.dart';

/// 原生备份存储通道（见 MainActivity.kt）。
const MethodChannel _storageChannel = MethodChannel(
  'com.yjym.baby.babydaily/storage',
);

const String _backupFolder = '下载/BabyDaily';

/// 当前版本（与 pubspec.yaml 的 version 保持一致）。
const String _appVersion = '1.0.3';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<String> _documentsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  String _backupFileName() {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'babydaily_backup_$stamp.json';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const ClayAvatar(
                    icon: Icons.upload_outlined,
                    color: kHealthColor,
                    size: 40,
                    iconSize: 20,
                  ),
                  title: const Text('导出备份（JSON）'),
                  subtitle: const Text('保存到手机「下载/BabyDaily」，换机或清理时可找回'),
                  onTap: () => _export(context),
                ),
                const Divider(height: 1, indent: 68),
                ListTile(
                  leading: const ClayAvatar(
                    icon: Icons.download_outlined,
                    color: kDisciplineColor,
                    size: 40,
                    iconSize: 20,
                  ),
                  title: const Text('导入备份'),
                  subtitle: const Text('用系统文件选择器挑一份备份 json 恢复（覆盖当前数据）'),
                  onTap: () => _import(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const ClayAvatar(
                icon: Icons.info_outline,
                color: kCharmColor,
                size: 40,
                iconSize: 20,
              ),
              title: Text('宝宝日常 v$_appVersion'),
              subtitle: const Text(
                '轻松治愈的个人成长 RPG\n主角 · 任务 · 习惯 · 笔记 · 场景',
              ),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 导出 ----

  Future<void> _export(BuildContext context) async {
    final controller = AppScope.read(context);
    try {
      final json = await controller.service.exportJson();
      final name = _backupFileName();
      String? path;
      try {
        path = await _storageChannel.invokeMethod<String>('saveBackup', {
          'json': json,
          'name': name,
        });
      } catch (_) {
        path = null; // 通道不可用（旧系统/测试环境）→ 应用文档目录兜底
      }
      if (!context.mounted) return;
      if (path == null || path.isEmpty) {
        await _exportLegacy(context, json, name);
        return;
      }
      await _showBackupSuccess(context, path);
    } catch (e) {
      if (context.mounted) {
        showCelebration(context, '导出失败：$e');
      }
    }
  }

  /// 兜底：写入应用文档目录（旧系统/通道异常时）。
  Future<void> _exportLegacy(
    BuildContext context,
    String json,
    String name,
  ) async {
    final dir = await _documentsDir();
    final file = File(p.join(dir, name));
    await file.writeAsString(json);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('✅ 备份成功（应用内部目录）'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前系统不支持写入公共下载目录，已保存到应用内部目录：'),
            const SizedBox(height: 8),
            SelectableText(
              file.path,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupSuccess(BuildContext context, String path) async {
    // 原生返回的是 Download/... 形式，界面上用中文目录更直观
    final display = path.replaceFirst('Download/', '下载/');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('✅ 备份成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('备份文件已保存到：'),
            const SizedBox(height: 8),
            SelectableText(
              display,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '在小米文件管理 → 下载 → BabyDaily 中可以找到；'
              '也可拷贝到电脑或其他设备保存。',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  // ---- 导入 ----

  /// 用系统文件选择器挑一份备份，确认后覆盖当前数据。
  Future<void> _import(BuildContext context) async {
    Map<Object?, Object?>? picked;
    try {
      picked = await _storageChannel
          .invokeMethod<Map<Object?, Object?>>('pickBackup');
    } on MissingPluginException {
      if (!context.mounted) return;
      await _importLegacyFile(context); // 通道不可用（测试/极旧系统）→ 内部目录兜底
      return;
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'NO_PICKER') {
        await _importLegacyFile(context);
      } else {
        showCelebration(context, '读取失败：${e.message ?? '无法读取该文件'}');
      }
      return;
    } catch (e) {
      if (!context.mounted) return;
      showCelebration(context, '导入失败：$e');
      return;
    }
    if (picked == null || !context.mounted) return; // 用户取消

    final name = picked['name'] as String? ?? '备份文件';
    final json = picked['json'] as String? ?? '';
    await _restoreFromJson(context, json, name);
  }

  /// 校验备份内容 → 展示摘要并二次确认 → 覆盖导入。
  Future<void> _restoreFromJson(
    BuildContext context,
    String json,
    String fileName,
  ) async {
    final controller = AppScope.read(context);
    Map<String, dynamic> data;
    try {
      data = _parseBackup(json);
    } on FormatException catch (e) {
      if (context.mounted) {
        showCelebration(context, '无法导入：${e.message}');
      }
      return;
    }
    if (!context.mounted) return;

    final confirmed = await _confirmOverwrite(context, fileName, data);
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.service.importJson(json, now: DateTime.now());
      await controller.refresh();
      if (context.mounted) {
        showCelebration(context, '导入成功，欢迎回来 🐣');
      }
    } catch (e) {
      if (context.mounted) {
        showCelebration(context, '导入失败：$e');
      }
    }
  }

  /// 解析并校验备份：只认本应用的版本 1 快照。
  Map<String, dynamic> _parseBackup(String json) {
    if (json.trim().isEmpty) {
      throw const FormatException('文件是空的');
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const FormatException('文件不是 JSON，可能选错了文件');
    }
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      throw const FormatException('这不是宝宝日常导出的备份文件');
    }
    return decoded;
  }

  /// 备份摘要：让用户在覆盖前确认选对了文件。
  String _describeBackup(Map<String, dynamic> data) {
    final lines = <String>[];
    final exportedAt = data['exported_at'];
    if (exportedAt is String) {
      final t = DateTime.tryParse(exportedAt)?.toLocal();
      if (t != null) {
        String two(int v) => v.toString().padLeft(2, '0');
        lines.add(
          '导出时间：${t.year}-${two(t.month)}-${two(t.day)} '
          '${two(t.hour)}:${two(t.minute)}',
        );
      }
    }
    final character = data['character'];
    if (character is Map) {
      final name = character['name'];
      final xp = character['xp'];
      lines.add(
        '主角：${name is String ? name : '（未命名）'}'
        '${xp is int ? ' · Lv.${levelForXp(xp)}' : ''}',
      );
    } else {
      lines.add('主角：备份里没有主角');
    }
    final tasks = data['tasks'];
    if (tasks is List) lines.add('任务：${tasks.length} 个');
    final notes = data['notes'];
    if (notes is List) lines.add('笔记：${notes.length} 篇');
    return lines.join('\n');
  }

  /// 通道不可用时的兜底：应用文档目录里的 babydaily_restore.json。
  Future<void> _importLegacyFile(BuildContext context) async {
    String? path;
    try {
      final dir = await _documentsDir();
      final file = File(p.join(dir, 'babydaily_restore.json'));
      path = await file.exists() ? file.path : null;
    } catch (_) {
      path = null;
    }
    if (!context.mounted) return;
    if (path == null) {
      await _showImportGuide(context);
      return;
    }
    final json = await File(path).readAsString();
    if (!context.mounted) return;
    await _restoreFromJson(context, json, 'babydaily_restore.json');
  }

  Future<void> _showImportGuide(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('无法打开文件选择器'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('当前系统的文件选择器不可用。可以这样恢复备份：'),
              const SizedBox(height: 8),
              Text(
                '· 把备份 json 改名为 babydaily_restore.json，'
                '放进应用文档目录后重新点「导入备份」；\n'
                '· 或先在本机「导出备份」，再从「$_backupFolder」里取用。',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('明白了'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmOverwrite(
    BuildContext context,
    String fileName,
    Map<String, dynamic> data,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入备份'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _describeBackup(data),
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            const Text('导入会覆盖当前所有数据，确定继续吗？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
}
