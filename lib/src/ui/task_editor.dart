/// 任务编辑对话框与失败确认：任务页（主线/支线）与每日任务页共用。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';

/// 类型选择器里可用的类型（每日任务页只允许建每日任务）。
const List<TaskType> kTaskTypes = [
  TaskType.mainline,
  TaskType.side,
  TaskType.daily,
];

/// 新建/编辑任务的对话框。
///
/// 保存后由调用方重新加载列表；取消或名称为空则不改动任何数据。
Future<void> showTaskDialog(
  BuildContext context, {
  Task? task,
  List<Subtask>? subtasks,
  List<TaskType> allowedTypes = kTaskTypes,
}) async {
  final controller = AppScope.read(context);
  final nameController = TextEditingController(text: task?.name ?? '');
  final descController = TextEditingController(text: task?.description ?? '');
  final healthController = TextEditingController(
    text: task != null && task.rewardHealth > 0 ? '${task.rewardHealth}' : '0',
  );
  final disciplineController = TextEditingController(
    text: task != null && task.rewardDiscipline > 0
        ? '${task.rewardDiscipline}'
        : (task == null ? '1' : '0'),
  );
  final charmController = TextEditingController(
    text: task != null && task.rewardCharm > 0 ? '${task.rewardCharm}' : '0',
  );
  final subtasksController = TextEditingController(
    text: (subtasks ?? const <Subtask>[]).map((s) => s.name).join('\n'),
  );

  var type = task?.type ?? allowedTypes.first;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(task == null ? '添加任务' : '编辑任务'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (allowedTypes.length > 1)
                SegmentedButton<TaskType>(
                  segments: [
                    for (final t in allowedTypes)
                      ButtonSegment(value: t, label: Text(taskTypeLabel(t))),
                  ],
                  selected: {type},
                  onSelectionChanged: task == null
                      ? (s) => setDialogState(() => type = s.first)
                      : null, // 编辑不改类型
                ),
              if (allowedTypes.length > 1) const SizedBox(height: 12),
              TextField(
                controller: nameController,
                maxLength: 30,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              TextField(
                controller: descController,
                maxLength: 100,
                decoration: const InputDecoration(labelText: '描述（可选）'),
              ),
              const SizedBox(height: 12),
              Text('奖励（属性）', style: Theme.of(context).textTheme.titleSmall),
              Row(
                children: [
                  Expanded(child: _rewardField(context, '健康', healthController)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _rewardField(context, '自律', disciplineController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _rewardField(context, '魅力', charmController)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                taskTypeHint(type),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (type == TaskType.mainline && task == null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: subtasksController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: '子项（可选，每行一个）',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );

  if (result != true) return;

  final name = nameController.text.trim();
  if (name.isEmpty) return;
  final reward = AttributeDelta(
    health: (int.tryParse(healthController.text) ?? 0).clamp(0, 100),
    discipline: (int.tryParse(disciplineController.text) ?? 0).clamp(0, 100),
    charm: (int.tryParse(charmController.text) ?? 0).clamp(0, 100),
  );

  if (task == null) {
    final id = await controller.service.createTask(
      name: name,
      description: descController.text.trim(),
      type: type,
      reward: reward,
    );
    final lines = subtasksController.text
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
      description: descController.text.trim(),
      reward: reward,
    );
  }
}

/// 任务类型的界面名称。
String taskTypeLabel(TaskType type) => switch (type) {
      TaskType.mainline => '主线',
      TaskType.side => '支线',
      TaskType.daily => '每日任务',
    };

/// 类型在表单里的规则说明。
String taskTypeHint(TaskType type) => switch (type) {
      TaskType.mainline => '固定经验 +50（最后一个子项完成时发放）',
      TaskType.side => '固定经验 +20',
      TaskType.daily => '0 点未完成会扣除上面的属性，并记为失败（任务保留）',
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

Widget _rewardField(
  BuildContext context,
  String label,
  TextEditingController controller,
) {
  // 浮动标签（M3 描边式）会压在边框线上、与上方标题重叠，
  // 所以改用"框外小标题 + 无标签输入框"的布局。
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
