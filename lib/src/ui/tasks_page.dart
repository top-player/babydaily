/// 任务页：主线（可展开子项）/ 支线 / 每日任务 三区 + 已完成归档。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/xp_economy.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/feedback.dart';
import 'package:babydaily/src/ui/theme.dart';

const Color _kMainColor = Color(0xFFC7771F);
const Color _kSideColor = kHealthColor; // 支线=绿
const Color _kDailyColor = kDisciplineColor; // 每日=蓝
const Color _kArchiveColor = Color(0xFF8E7CC3);

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
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 一次性加载：不用 AppScope.of（会注册重建依赖），
    // 业务通知不再触发整树重建/重复查库。
    if (!_loadStarted) {
      _loadStarted = true;
      _load();
    }
  }

  Future<void> _load() async {
    final service = AppScope.read(context).service;
    // 各路查询并行发起，减少串行等待。
    final mainlinesF = service.tasksByType(TaskType.mainline, completed: false);
    final sidesF = service.tasksByType(TaskType.side, completed: false);
    final dailyF = service.dailyTasks();
    final archiveMainF = service.tasksByType(
      TaskType.mainline,
      completed: true,
    );
    final archiveSideF = service.tasksByType(TaskType.side, completed: true);
    final mainlines = await mainlinesF;
    final sides = await sidesF;
    final daily = await dailyF;
    final archive = [...await archiveMainF, ...await archiveSideF];
    final subtasksByTask = <int, List<Subtask>>{};
    await Future.wait([
      for (final t in mainlines)
        service.subtasksOf(t.id).then((s) => subtasksByTask[t.id] = s),
    ]);
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
    final controller = AppScope.read(context);
    if (outcome != null && mounted) {
      showGrowthFeedback(context, outcome);
    }
    await controller.refresh();
    await _load();
  }

  Future<void> _completeTask(Task task) async {
    final controller = AppScope.read(context);
    final outcome = await controller.service.completeTask(
      task.id,
      now: DateTime.now(),
    );
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
    final outcome = await AppScope.read(
      context,
    ).service.completeSubtask(subtask.id, now: DateTime.now());
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
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  ClayAvatar(
                    icon: Icons.flag_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 76,
                    iconSize: 36,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '还没有任务，点右下角加一个吧',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          if (_mainlines.isNotEmpty) ...[
            _sectionHeader(
              context,
              icon: Icons.flag,
              color: _kMainColor,
              title: '主线',
              subtitle: '重要的事，慢慢来',
              count: _mainlines.length,
            ),
            for (final t in _mainlines) _mainlineCard(t),
          ],
          if (_sides.isNotEmpty) ...[
            _sectionHeader(
              context,
              icon: Icons.eco,
              color: _kSideColor,
              title: '支线',
              subtitle: '顺手的小事',
              count: _sides.length,
            ),
            for (final t in _sides) _sideCard(t),
          ],
          if (_daily.isNotEmpty) ...[
            _sectionHeader(
              context,
              icon: Icons.today,
              color: _kDailyColor,
              title: '每日任务',
              subtitle: '每天 0 点重置',
              count: _daily.length,
            ),
            for (final t in _daily) _dailyCard(t),
          ],
          if (_archive.isNotEmpty) ...[
            _sectionHeader(
              context,
              icon: Icons.emoji_events,
              color: _kArchiveColor,
              title: '已完成',
              subtitle: '来时的路',
              count: _archive.length,
            ),
            for (final t in _archive) _archiveCard(t),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasks-fab',
        onPressed: () async {
          await _showTaskDialog(context);
          await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('添加任务'),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required int count,
  }) {
    return SectionHeader(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      trailing: TagPill(text: '$count', color: color),
    );
  }

  Widget _rewardChips(Task t, {bool showXp = true}) {
    final scheme = Theme.of(context).colorScheme;
    final chips = <Widget>[
      if (showXp && t.type == TaskType.mainline)
        TagPill(text: '经验 +$mainlineXp', color: _kMainColor, icon: Icons.bolt),
      if (showXp && t.type == TaskType.side)
        TagPill(text: '经验 +$sideQuestXp', color: _kSideColor, icon: Icons.bolt),
      if (t.rewardHealth > 0)
        TagPill(
          text: '健康 +${t.rewardHealth}',
          color: kHealthColor,
          icon: Icons.favorite,
        ),
      if (t.rewardDiscipline > 0)
        TagPill(
          text: '自律 +${t.rewardDiscipline}',
          color: _kDailyColor,
          icon: Icons.bolt,
        ),
      if (t.rewardCharm > 0)
        TagPill(
          text: '魅力 +${t.rewardCharm}',
          color: kCharmColor,
          icon: Icons.auto_awesome,
        ),
      if (t.type == TaskType.daily &&
          t.rewardHealth == 0 &&
          t.rewardDiscipline == 0 &&
          t.rewardCharm == 0)
        TagPill(text: '无属性奖励', color: scheme.onSurfaceVariant),
    ];
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _cardShell(BuildContext context, Color accent, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClayAvatar(
              icon: switch (accent) {
                _kMainColor => Icons.flag,
                _kSideColor => Icons.eco,
                _kDailyColor => Icons.today,
                _ => Icons.emoji_events,
              },
              color: accent,
              size: 40,
              iconSize: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
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
            await AppScope.read(context).service.deleteTask(t.id);
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
      context,
      _kMainColor,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (t.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          t.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              _menuButton(t, subtasks: subtasks),
            ],
          ),
          const SizedBox(height: 8),
          _rewardChips(t),
          if (subtasks.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final s in subtasks)
              Row(
                children: [
                  Checkbox(
                    value: s.isDone,
                    onChanged: s.isDone ? null : (_) => _completeSubtask(t, s),
                  ),
                  Expanded(
                    child: Text(
                      s.name,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: s.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: s.isDone ? Theme.of(context).hintColor : null,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    tooltip: '删除子项',
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      await AppScope.read(context).service.deleteSubtask(s.id);
                      await _load();
                    },
                  ),
                ],
              ),
            _addSubtaskRow(t),
          ],
          const SizedBox(height: 8),
          undone > 0
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '完成剩余 $undone 个子项后自动完成',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => _completeTask(t),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('完成主线'),
                ),
        ],
      ),
    );
  }

  Widget _addSubtaskRow(Task t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
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
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(controller.text.trim()),
                  child: const Text('添加'),
                ),
              ],
            ),
          );
          // 注意：不在此处 dispose controller——对话框关闭动画未结束时
          // TextField 仍引用它，提前 dispose 会触发框架断言崩溃。
          if (name == null || name.isEmpty || !mounted) return;
          await AppScope.read(
            context,
          ).service.createSubtask(taskId: t.id, name: name);
          await _load();
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text('添加子项'),
      ),
    );
  }

  Widget _sideCard(Task t) {
    return _cardShell(
      context,
      _kSideColor,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (t.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          t.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              _menuButton(t),
            ],
          ),
          const SizedBox(height: 8),
          _rewardChips(t),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
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
      context,
      _kDailyColor,
      Opacity(
        opacity: done ? 0.8 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (t.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            t.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                _menuButton(t),
              ],
            ),
            const SizedBox(height: 8),
            _rewardChips(t),
            const SizedBox(height: 10),
            if (done)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: kHealthColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: kHealthColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '今日已完成，明天继续',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kHealthColor,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => _completeTask(t),
                  child: const Text('完成'),
                ),
              ),
              if (penaltyText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '未完成将在 0 点扣除：$penaltyText',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
      context,
      _kArchiveColor,
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
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

  Future<void> _showTaskDialog(
    BuildContext context, {
    Task? task,
    List<Subtask>? subtasks,
  }) async {
    final controller = AppScope.read(context);
    final nameController = TextEditingController(text: task?.name ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    final healthController = TextEditingController(
      text: task != null && task.rewardHealth > 0
          ? '${task.rewardHealth}'
          : '0',
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
                    ButtonSegment(value: TaskType.mainline, label: Text('主线')),
                    ButtonSegment(value: TaskType.side, label: Text('支线')),
                    ButtonSegment(value: TaskType.daily, label: Text('每日任务')),
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
                  decoration: const InputDecoration(labelText: '描述（可选）'),
                ),
                const SizedBox(height: 12),
                Text('奖励（属性）', style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: [
                    Expanded(child: _rewardField('健康', healthController)),
                    const SizedBox(width: 8),
                    Expanded(child: _rewardField('自律', disciplineController)),
                    const SizedBox(width: 8),
                    Expanded(child: _rewardField('魅力', charmController)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(switch (type) {
                  TaskType.mainline => '固定经验 +50（最后一个子项完成时发放）',
                  TaskType.side => '固定经验 +20',
                  TaskType.daily => '0 点未完成会扣除上面的属性',
                }, style: Theme.of(context).textTheme.bodySmall),
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

  Widget _rewardField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}
