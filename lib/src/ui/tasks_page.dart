/// 任务页：主线（可展开子项）/ 支线 / 每日任务 三区 + 已完成归档。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/xp_economy.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/feedback.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> _mainlines = [];
  List<Task> _sides = [];
  List<Task> _daily = [];
  List<Task> _archive = [];
  Map<int, List<Subtask>> _subtasksByTask = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final service = AppScope.of(context).service;
    final mainlines =
        await service.tasksByType(TaskType.mainline, completed: false);
    final sides = await service.tasksByType(TaskType.side, completed: false);
    final daily = await service.dailyTasks();
    final archive = [
      ...await service.tasksByType(TaskType.mainline, completed: true),
      ...await service.tasksByType(TaskType.side, completed: true),
    ];
    final subtasksByTask = <int, List<Subtask>>{};
    for (final t in mainlines) {
      subtasksByTask[t.id] = await service.subtasksOf(t.id);
    }
    if (mounted) {
      setState(() {
        _mainlines = mainlines;
        _sides = sides;
        _daily = daily;
        _archive = archive;
        _subtasksByTask = subtasksByTask;
      });
    }
  }

  Future<void> _afterMutation(GrowthOutcome? outcome) async {
    final controller = AppScope.of(context);
    if (outcome != null && mounted) {
      showGrowthFeedback(context, outcome);
    }
    await controller.refresh();
    await _load();
  }

  Future<void> _completeTask(Task task) async {
    final controller = AppScope.of(context);
    final outcome = await controller.service
        .completeTask(task.id, now: DateTime.now());
    if (outcome == null) {
      if (mounted) setState(() {});
      return;
    }
    await _afterMutation(outcome);
    if (!mounted) return;
    if (task.type == TaskType.daily) {
      final today = dateString(DateTime.now());
      final allDone = _daily.every((t) => t.completedOn == today);
      if (allDone) showCelebration(context, '每日任务全清，今天也很棒！');
    }
  }

  Future<void> _completeSubtask(Task mainline, Subtask subtask) async {
    final outcome = await AppScope.of(context)
        .service
        .completeSubtask(subtask.id, now: DateTime.now());
    await _afterMutation(outcome);
    if (!mounted) return;
    if (outcome != null && outcome.xpGained == mainlineXp) {
      showCelebration(context, '主线完成！「${mainline.name}」达成 🏆');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_mainlines.isEmpty && _sides.isEmpty && _daily.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text('📝',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text('还没有任务，点右下角加一个吧',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          if (_mainlines.isNotEmpty) ...[
            _sectionHeader(context, '⭐ 主线', '重要的事，慢慢来'),
            for (final t in _mainlines) _mainlineCard(t),
          ],
          if (_sides.isNotEmpty) ...[
            _sectionHeader(context, '🌱 支线', '顺手的小事'),
            for (final t in _sides) _sideCard(t),
          ],
          if (_daily.isNotEmpty) ...[
            _sectionHeader(context, '📅 每日任务', '每天 0 点重置'),
            for (final t in _daily) _dailyCard(t),
          ],
          if (_archive.isNotEmpty) ...[
            _sectionHeader(context, '🏁 已完成', '来时的路'),
            for (final t in _archive) _archiveCard(t),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _showTaskDialog(context);
          await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('添加任务'),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _rewardChips(Task t, {bool showXp = true}) {
    final chips = <Widget>[
      if (showXp && t.type == TaskType.mainline) _chip('经验 +$mainlineXp'),
      if (showXp && t.type == TaskType.side) _chip('经验 +$sideQuestXp'),
      if (t.rewardHealth > 0) _chip('健康 +${t.rewardHealth}'),
      if (t.rewardDiscipline > 0) _chip('自律 +${t.rewardDiscipline}'),
      if (t.rewardCharm > 0) _chip('魅力 +${t.rewardCharm}'),
      if (t.type == TaskType.daily &&
          t.rewardHealth == 0 &&
          t.rewardDiscipline == 0 &&
          t.rewardCharm == 0)
        _chip('无属性奖励'),
    ];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _chip(String text) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _cardShell(Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: child,
      ),
    );
  }

  Widget _menuButton(Task t, {List<Subtask>? subtasks}) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          await _showTaskDialog(context, task: t, subtasks: subtasks);
          await _load();
        } else if (value == 'delete') {
          final confirmed = await _confirmDelete(context, t.name);
          if (confirmed && mounted) {
            await AppScope.of(context).service.deleteTask(t.id);
            await _load();
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('编辑')),
        PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定删除「$name」吗？已完成的历史会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _mainlineCard(Task t) {
    final subtasks = _subtasksByTask[t.id] ?? const <Subtask>[];
    final undone = subtasks.where((s) => !s.isDone).length;
    return _cardShell(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (t.description.isNotEmpty)
                      Text(t.description,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              _menuButton(t, subtasks: subtasks),
            ],
          ),
          const SizedBox(height: 6),
          _rewardChips(t),
          if (subtasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final s in subtasks)
              Row(
                children: [
                  Checkbox(
                    value: s.isDone,
                    onChanged: s.isDone
                        ? null
                        : (_) => _completeSubtask(t, s),
                  ),
                  Expanded(
                    child: Text(
                      s.name,
                      style: TextStyle(
                        decoration:
                            s.isDone ? TextDecoration.lineThrough : null,
                        color: s.isDone ? Theme.of(context).hintColor : null,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      await AppScope.of(context)
                          .service
                          .deleteSubtask(s.id);
                      await _load();
                    },
                  ),
                ],
              ),
            _addSubtaskRow(t),
          ],
          const SizedBox(height: 8),
          undone > 0
              ? Text('完成剩余 $undone 个子项后自动完成',
                  style: Theme.of(context).textTheme.bodySmall)
              : FilledButton.icon(
                  onPressed: () => _completeTask(t),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('完成主线'),
                ),
        ],
      ),
    );
  }

  Widget _addSubtaskRow(Task t) {
    return TextButton.icon(
      onPressed: () async {
        final controller = TextEditingController();
        final name = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('添加子项'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 30,
              decoration: const InputDecoration(hintText: '子项名称'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext)
                    .pop(controller.text.trim()),
                child: const Text('添加'),
              ),
            ],
          ),
        );
        controller.dispose();
        if (name == null || name.isEmpty || !mounted) return;
        await AppScope.of(context)
            .service
            .createSubtask(taskId: t.id, name: name);
        await _load();
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('添加子项'),
    );
  }

  Widget _sideCard(Task t) {
    return _cardShell(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (t.description.isNotEmpty)
                      Text(t.description,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              _menuButton(t),
            ],
          ),
          const SizedBox(height: 6),
          _rewardChips(t),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => _completeTask(t),
              child: const Text('完成'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyCard(Task t) {
    final today = dateString(DateTime.now());
    final done = t.completedOn == today;
    final penaltyText = [
      if (t.rewardHealth > 0) '健康 -${t.rewardHealth}',
      if (t.rewardDiscipline > 0) '自律 -${t.rewardDiscipline}',
      if (t.rewardCharm > 0) '魅力 -${t.rewardCharm}',
    ].join('、');
    return _cardShell(
      Opacity(
        opacity: done ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (t.description.isNotEmpty)
                        Text(t.description,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                _menuButton(t),
              ],
            ),
            const SizedBox(height: 6),
            _rewardChips(t),
            const SizedBox(height: 8),
            if (done)
              const Center(
                  child: Text('✓ 今日已完成，明天继续', textAlign: TextAlign.center))
            else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _completeTask(t),
                  child: const Text('完成'),
                ),
              ),
              if (penaltyText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('未完成将在 0 点扣除：$penaltyText',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).hintColor)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _archiveCard(Task t) {
    final when = t.completedAt;
    return _cardShell(
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${t.type == TaskType.mainline ? '主线' : '支线'} · '
                  '${when != null ? '${when.year}/${when.month}/${when.day} 完成' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _menuButton(t),
        ],
      ),
    );
  }

  // ---- 创建 / 编辑对话框 ----

  Future<void> _showTaskDialog(BuildContext context,
      {Task? task, List<Subtask>? subtasks}) async {
    final controller = AppScope.of(context);
    final nameController = TextEditingController(text: task?.name ?? '');
    final descController =
        TextEditingController(text: task?.description ?? '');
    final healthController = TextEditingController(
        text: task != null && task.rewardHealth > 0
            ? '${task.rewardHealth}'
            : '0');
    final disciplineController = TextEditingController(
        text: task != null && task.rewardDiscipline > 0
            ? '${task.rewardDiscipline}'
            : (task == null ? '1' : '0'));
    final charmController = TextEditingController(
        text: task != null && task.rewardCharm > 0
            ? '${task.rewardCharm}'
            : '0');
    final subtasksController = TextEditingController(
        text: (subtasks ?? const <Subtask>[])
            .map((s) => s.name)
            .join('\n'));

    var type = task?.type ?? TaskType.mainline;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? '添加任务' : '编辑任务'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<TaskType>(
                  segments: const [
                    ButtonSegment(
                        value: TaskType.mainline, label: Text('主线')),
                    ButtonSegment(value: TaskType.side, label: Text('支线')),
                    ButtonSegment(
                        value: TaskType.daily, label: Text('每日任务')),
                  ],
                  selected: {type},
                  onSelectionChanged: task == null
                      ? (s) => setDialogState(() => type = s.first)
                      : null, // 编辑不改类型
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  maxLength: 30,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                TextField(
                  controller: descController,
                  maxLength: 100,
                  decoration:
                      const InputDecoration(labelText: '描述（可选）'),
                ),
                const SizedBox(height: 12),
                Text('奖励（属性）', style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: [
                    Expanded(
                        child: _rewardField('健康', healthController)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _rewardField('自律', disciplineController)),
                    const SizedBox(width: 8),
                    Expanded(child: _rewardField('魅力', charmController)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  switch (type) {
                    TaskType.mainline => '固定经验 +50（最后一个子项完成时发放）',
                    TaskType.side => '固定经验 +20',
                    TaskType.daily => '0 点未完成会扣除上面的属性',
                  },
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
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

    if (result != true) {
      for (final c in [
        nameController,
        descController,
        healthController,
        disciplineController,
        charmController,
        subtasksController,
      ]) {
        c.dispose();
      }
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final reward = AttributeDelta(
      health: (int.tryParse(healthController.text) ?? 0).clamp(0, 100),
      discipline:
          (int.tryParse(disciplineController.text) ?? 0).clamp(0, 100),
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
    for (final c in [
      nameController,
      descController,
      healthController,
      disciplineController,
      charmController,
      subtasksController,
    ]) {
      c.dispose();
    }
  }

  Widget _rewardField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}
