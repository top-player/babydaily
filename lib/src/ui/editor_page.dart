/// 全屏编辑器页的共享骨架：任务 / 习惯 / 笔记三个「添加·编辑」表单。
///
/// 为什么从对话框改成整页（ADR-0010）：
/// - 对话框是浮层，没有可以锚定的位置与尺寸，「从按钮长出来」的容器变换
///   无从谈起；整页才有源元素（FAB / 卡片 / ⋮）可言；
/// - 表单在对话框里被键盘挤到只剩两三行可滚，整页贴着键盘滚动舒服得多。
///
/// 交互语义与原来的 `showDialog<bool>` 一致：保存成功 `pop(true)`，
/// 取消/返回 `pop(null)`，调用方据此决定要不要刷新列表。
library;

import 'package:flutter/material.dart';

/// 全屏表单页骨架：左上角关闭、右上角保存、正文可滚动。
class EditorPage extends StatelessWidget {
  const EditorPage({
    super.key,
    required this.title,
    required this.onSave,
    required this.children,
    this.subtitle,
    this.saveLabel = '保存',
  });

  /// 页面标题（「添加任务」/「编辑习惯」…）。
  final String title;

  /// 顶部的说明文案（可选）。
  final String? subtitle;

  /// 表单内容。
  final List<Widget> children;

  /// 点保存：调用方自己校验并落库，成功就 `Navigator.pop(true)`。
  final VoidCallback onSave;

  /// 保存键文案。
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 用 X 而不是返回箭头：这里是「放弃编辑」而不是「回到上一页」。
        leading: IconButton(
          tooltip: '取消',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(onPressed: onSave, child: Text(saveLabel)),
          ),
        ],
      ),
      // 键盘弹起时正文缩短、标题与保存键始终可见（Scaffold 默认行为）。
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (subtitle != null) ...[
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// 属性数值输入：框外小标题 + 无标签输入框。
///
/// 不用浮动标签：M3 描边式标签会压在边框线上、和上方小标题重叠。
class RewardField extends StatelessWidget {
  const RewardField({
    super.key,
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: 4),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(),
          ),
        ),
      ],
    );
  }
}

/// 属性输入框里的文本 → 属性增量（空/非法按 0，上限 100）。
int parseAttribute(String text) => (int.tryParse(text.trim()) ?? 0).clamp(0, 100);

/// 「每周次数」那一行：− 次数 +（每周型习惯共用）。
class WeeklyTimesRow extends StatelessWidget {
  const WeeklyTimesRow({
    super.key,
    required this.times,
    required this.onChanged,
  });

  final int times;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('每周次数', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => onChanged((times - 1).clamp(1, 7)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$times 次', style: Theme.of(context).textTheme.titleLarge),
        IconButton(
          onPressed: () => onChanged((times + 1).clamp(1, 7)),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
