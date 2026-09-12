/// 任务编辑页与失败确认：任务页（主线/支线）与每日任务页共用。
///
/// 「添加/编辑」都走整页表单（原来是与 `showDialog` 的对话框）：只有整页才能
/// 做容器变换——从 FAB、卡片 ⋮ 的位置与尺寸长大成页面；顺带摆脱对话框里
/// 键盘把表单挤成两行可滚的窘境。语义不变：保存成功 `pop(true)`，调用方刷新列表。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/xp_economy.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/editor_page.dart';
import 'package:babydaily/src/ui/motion.dart';

/// 类型选择器里可用的类型（每日任务页只允许建每日任务）。
const List<TaskType> kTaskTypes = [
  TaskType.mainline,
  TaskType.side,
  TaskType.daily,
];

/// 新建/编辑任务的整页表单。
///
/// 保存后 `pop(true)` 由调用方重新加载列表；取消、或名称为空时不落库。
class TaskEditorPage extends StatefulWidget {
  const TaskEditorPage({
    super.key,
    this.task,
    this.subtasks,
    this.allowedTypes = kTaskTypes,
  });

  /// 为空表示新建。
  final Task? task;

  /// 编辑主线时带上已有子项，保存时不做子项增删（与原来的对话框一致）。
  final List<Subtask>? subtasks;

  /// 允许选择的类型（每日任务页只给每日任务）。
  final List<TaskType> allowedTypes;

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  late final TextEditingController _name = TextEditingController(
    text: widget.task?.name ?? '',
  );
  late final TextEditingController _desc = TextEditingController(
    text: widget.task?.description ?? '',
  );
  late final TextEditingController _health = TextEditingController(
    text: _initial(widget.task?.rewardHealth, 0),
  );
  late final TextEditingController _discipline = TextEditingController(
    text: _initial(widget.task?.rewardDiscipline, widget.task == null ? 1 : 0),
  );
  late final TextEditingController _charm = TextEditingController(
    text: _initial(widget.task?.rewardCharm, 0),
  );
  late final TextEditingController _subtasks = TextEditingController(
    text: (widget.subtasks ?? const <Subtask>[]).map((s) => s.name).join('\n'),
  );
  late TaskType _type = widget.task?.type ?? widget.allowedTypes.first;

  /// 旧的对话框取值规则：已有值大于 0 就用它，否则用默认值。
  static String _initial(int? value, int fallback) =>
      value != null && value > 0 ? '$value' : '$fallback';

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _health.dispose();
    _discipline.dispose();
    _charm.dispose();
    _subtasks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final navigator = Navigator.of(context);
    if (name.isEmpty) {
      navigator.pop();
      return;
    }
    final controller = AppScope.read(context);
    final reward = AttributeDelta(
      health: parseAttribute(_health.text),
      discipline: parseAttribute(_discipline.text),
      charm: parseAttribute(_charm.text),
    );
    final task = widget.task;
    if (task == null) {
      final id = await controller.service.createTask(
        name: name,
        description: _desc.text.trim(),
        type: _type,
        reward: reward,
      );
      final lines = _subtasks.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty);
      for (final line in lines) {
        await controller.service.createSubtask(taskId: id, name: line);
      }
    } else {
      await controller.service.updateTask(
        id: task.id,
        name: name,
        description: _desc.text.trim(),
        reward: reward,
      );
    }
    if (mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.task != null;
    return EditorPage(
      title: editing ? '编辑任务' : '添加任务',
      subtitle: taskTypeHint(_type),
      onSave: _save,
      children: [
        if (widget.allowedTypes.length > 1) ...[
          SegmentedButton<TaskType>(
            segments: [
              for (final t in widget.allowedTypes)
                ButtonSegment(value: t, label: Text(taskTypeLabel(t))),
            ],
            selected: {_type},
            // 编辑不改类型（换了类型会让已完成/失败归档的语义错位）。
            onSelectionChanged: editing
                ? null
                : (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _name,
          maxLength: 30,
          autofocus: !editing,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        TextField(
          controller: _desc,
          maxLength: 100,
          decoration: const InputDecoration(labelText: '描述（可选）'),
        ),
        const SizedBox(height: 8),
        Text('奖励（属性）', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: RewardField(label: '健康', controller: _health)),
            const SizedBox(width: 8),
            Expanded(
              child: RewardField(label: '自律', controller: _discipline),
            ),
            const SizedBox(width: 8),
            Expanded(child: RewardField(label: '魅力', controller: _charm)),
          ],
        ),
        if (_type == TaskType.mainline && !editing) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _subtasks,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: '子项（可选，每行一个）',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ],
    );
  }
}

/// 「FAB / ⋮ → 任务编辑页」的容器变换。
///
/// 每次调用只建一次 [Opener]（它带 GlobalKey，不能在 `itemBuilder` 里现建）。
Opener taskEditorTransform({
  required BuildContext context,
  required Widget Function(BuildContext context, VoidCallback open) trigger,
  required VoidCallback onSaved,
  Task? task,
  List<Subtask>? subtasks,
  List<TaskType> allowedTypes = kTaskTypes,
}) {
  return openEditorTransform(
    context: context,
    trigger: trigger,
    page: (context) => TaskEditorPage(
      task: task,
      subtasks: subtasks,
      allowedTypes: allowedTypes,
    ),
    // 约定：整页表单 `pop(true)` 表示已保存；取消/名称为空是 pop(null)。
    onClosed: (saved) {
      if (saved == true) onSaved();
    },
  );
}

/// 任务类型的界面名称。
String taskTypeLabel(TaskType type) => switch (type) {
      TaskType.mainline => '主线',
      TaskType.side => '支线',
      TaskType.daily => '每日任务',
    };

/// 类型在表单里的规则说明。
String taskTypeHint(TaskType type) => switch (type) {
      TaskType.mainline => '固定经验 +$mainlineXp（最后一个子项完成时发放）',
      TaskType.side => '固定经验 +$sideQuestXp',
      TaskType.daily => '固定经验 +$dailyTaskXp；0 点未完成会扣除上面的属性，'
          '并记为失败（任务保留）',
    };

/// 失败二次确认：说清代价（每日任务立即扣属性；主线/支线进「已失败」归档）。
Future<bool> confirmFailTask(BuildContext context, Task task) async {
  final penalty = [
    if (task.rewardHealth > 0) '健康 -${task.rewardHealth}',
    if (task.rewardDiscipline > 0) '自律 -${task.rewardDiscipline}',
    if (task.rewardCharm > 0) '魅力 -${task.rewardCharm}',
  ].join('、');
  final content = switch (task.type) {
    TaskType.daily => penalty.isEmpty
        ? '把「${task.name}」今天的每日任务记为失败吗？任务会保留，明天照常。'
        : '把「${task.name}」记为失败吗？会立即扣除：$penalty。任务会保留，明天照常。',
    _ => '把「${task.name}」记为失败吗？'
        '任务会进入「已失败」归档并保留（不发奖励，也不扣属性），之后只能删除。',
  };
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('标记失败'),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('标记失败'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
