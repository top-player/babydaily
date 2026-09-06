/// 设置页：JSON 备份导出/导入（ADR-0005：公共下载目录）、关于。
///
/// 备份位置：Android 10+ 通过 MediaStore 写入公共「下载/BabyDaily」，
/// 小米/新安卓的文件管理器可见；旧系统或通道不可用时回退应用文档目录。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/feedback.dart';
import 'package:babydaily/src/ui/theme.dart';

/// 原生备份存储通道（见 MainActivity.kt）。
const MethodChannel _storageChannel = MethodChannel(
  'com.yjym.baby.babydaily/storage',
);

const String _backupFolder = '下载/BabyDaily';
const String _legacyPickValue = '__legacy__';

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
                  subtitle: const Text('从「下载/BabyDaily」里选择备份文件恢复'),
                  onTap: () => _import(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: ClayAvatar(
                icon: Icons.info_outline,
                color: kCharmColor,
                size: 40,
                iconSize: 20,
              ),
              title: Text('宝宝日常 v1.0.0'),
              subtitle: Text('轻松治愈的个人成长 RPG\n主角 · 任务 · 习惯 · 笔记 · 场景'),
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
              path,
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

  Future<void> _import(BuildContext context) async {
    final controller = AppScope.read(context);

    Iterable<Map<dynamic, dynamic>> files = const [];
    var channelOk = true;
    try {
      final list =
          await _storageChannel.invokeListMethod<dynamic>('listBackups') ??
          const [];
      files = list.cast<Map<dynamic, dynamic>>();
    } catch (_) {
      channelOk = false;
    }
    final legacyPath = await _legacyRestoreJson();
    if (!context.mounted) return;
    if (!files.any((m) => (m['readable'] ?? false) == true) &&
        legacyPath == null) {
      await _showImportGuide(context, channelOk);
      return;
    }

    final picked = await _showPickDialog(context, files, legacyPath);
    if (picked == null || !context.mounted) return;

    String json;
    String label;
    if (picked == _legacyPickValue && legacyPath != null) {
      json = await File(legacyPath).readAsString();
      label = 'babydaily_restore.json';
    } else {
      try {
        json =
            await _storageChannel.invokeMethod<String>('readBackup', {
              'name': picked,
            }) ??
            '';
        label = picked;
      } on PlatformException catch (e) {
        if (context.mounted) {
          showCelebration(context, '读取失败：${e.message ?? '无法读取该文件'}');
        }
        return;
      }
    }
    if (json.isEmpty || !context.mounted) {
      if (context.mounted) showCelebration(context, '读取备份失败，文件可能为空');
      return;
    }

    final confirmed = await _confirmOverwrite(context, label);
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

  /// 应用文档目录里的旧式恢复文件（高级用法，跨系统兜底）。
  Future<String?> _legacyRestoreJson() async {
    try {
      final dir = await _documentsDir();
      final file = File(p.join(dir, 'babydaily_restore.json'));
      return await file.exists() ? file.path : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _showPickDialog(
    BuildContext context,
    Iterable<Map<dynamic, dynamic>> files,
    String? legacyPath,
  ) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入备份'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final m in files)
                _backupTile(
                  dialogContext,
                  name: (m['name'] ?? '') as String,
                  timestamp: (m['timestamp'] ?? 0) as int,
                  readable: (m['readable'] ?? false) == true,
                ),
              if (legacyPath != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const ClayAvatar(
                    icon: Icons.folder_outlined,
                    color: Color(0xFF8E7CC3),
                    size: 40,
                    iconSize: 20,
                  ),
                  title: const Text('babydaily_restore.json（应用内部目录）'),
                  subtitle: const Text('高级：通过电脑把备份放到应用文档目录'),
                  onTap: () =>
                      Navigator.of(dialogContext).pop(_legacyPickValue),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _backupTile(
    BuildContext context, {
    required String name,
    required int timestamp,
    required bool readable,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClayAvatar(
        icon: Icons.description_outlined,
        color: readable
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        size: 40,
        iconSize: 20,
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '备份时间：${_formatStamp(timestamp)}'
        '${readable ? '' : ' · 非本应用导出，无法读取'}',
      ),
      onTap: readable
          ? () => Navigator.of(context).pop(name)
          : () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('该备份不是本应用导出的文件，无法读取')),
                );
            },
    );
  }

  String _formatStamp(int seconds) {
    final t = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _showImportGuide(BuildContext context, bool channelOk) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('未找到可导入的备份'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('备份文件放在手机的「$_backupFolder」文件夹：'),
              const SizedBox(height: 8),
              Text(
                '· 用本应用先「导出备份」，文件会自动出现在那里；\n'
                '· 从旧手机拷来的备份 json 也可以放进这个文件夹'
                '（不过只有本应用导出的文件才能读取）。',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              if (!channelOk) ...[
                const SizedBox(height: 8),
                Text(
                  '当前系统不支持公共目录；可将导出文件按旧方法改名为 '
                  'babydaily_restore.json 放入应用文档目录后重试。',
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
              ],
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

  Future<bool?> _confirmOverwrite(BuildContext context, String fileName) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入备份'),
        content: Text('将用「$fileName」覆盖当前所有数据，确定继续吗？'),
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
