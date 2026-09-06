/// 设置页：JSON 备份导出/导入（ADR-0001）、关于。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/feedback.dart';
import 'package:babydaily/src/ui/theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<String> _documentsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
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
                  subtitle: const Text('把全部数据保存为 JSON 文件，换机时可恢复'),
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
                  subtitle: const Text(
                    '将备份文件改名为 babydaily_restore.json 放到应用文档目录后导入',
                  ),
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

  Future<void> _export(BuildContext context) async {
    final controller = AppScope.of(context);
    try {
      final json = await controller.service.exportJson();
      final dir = await _documentsDir();
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      final file = File(p.join(dir, 'babydaily_backup_$stamp.json'));
      await file.writeAsString(json);
      if (!context.mounted) return;
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
    } catch (e) {
      if (context.mounted) {
        showCelebration(context, '导出失败：$e');
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final controller = AppScope.of(context);
    final dir = await _documentsDir();
    final file = File(p.join(dir, 'babydaily_restore.json'));
    if (!await file.exists()) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('未找到备份文件'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '请把导出的 JSON 备份改名为 '
                  'babydaily_restore.json，放到应用文档目录：',
                ),
                const SizedBox(height: 8),
                SelectableText(
                  dir,
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
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入备份'),
        content: const Text('当前数据将被备份内容覆盖，确定继续吗？'),
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
    if (confirmed != true || !context.mounted) return;
    try {
      final json = await file.readAsString();
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
}
