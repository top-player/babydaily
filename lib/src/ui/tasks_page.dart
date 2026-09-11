/// 任务页：主线（可展开子项）/ 支线 两区 + 已完成 / 已失败归档。
///
/// 每日任务搬到独立的每日任务页（今天 + 按日期滑动的历史），
/// 页首卡片是入口并显示今天的完成进度。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/xp_economy.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/daily_tasks_page.dart';
import 'package:babydaily/src/ui/feedback.dart';
import 'package:babydaily/src/ui/task_editor.dart';
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
  List<Task> _archive = [];
  List<Task> _failed = [];
  Map<int, List<Subtask>> _subtasksByTask = {};
  int _dailyTotal = 0;
  int _dailyDone = 0;
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
    final mainlinesF = service.tasksByType(TaskType.mainline);
    final sidesF = service.tasksByType(TaskType.side);
    final archiveMainF = service.tasksByType(
      TaskType.mainline,
      completed: true,
    );
    final archiveSideF = service.tasksByType(TaskType.side, completed: true);
    final failedMainF = service.tasksByType(TaskType.mainline, failed: true);
    final failedSideF = service.tasksByType(TaskType.side, failed: true);
    final dailyF = service.dailyTasks();
    final mainlines = await mainlinesF;
    final sides = await sidesF;
    final archive = [...await archiveMainF, ...await archiveSideF];
    final failed = [...await failedMainF, ...await failedSideF];
    final daily = await dailyF;
    final today = dateString(DateTime.now());
    final subtasksByTask = <int, List<Subtask>>{};
    await Future.wait([
      for (final t in mainlines)
        service.subtasksOf(t.id).then((s) => subtasksByTask[t.id] = s),
    ]);
    if (mounted) {
      setState(() {
        _mainlines = mainlines;
        _sides = sides;
        _archive = archive;
        _failed = failed;
        _subtasksByTask = subtasksByTask;
        _dailyTotal = daily.length;
        _dailyDone = daily.where((t) => t.completedOn == today).length;
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

  /// 手动判失败：主线/支线不发奖、不扣属性，失败后进「已失败」归档且不删除。
  Future<void> _failTask(Task task) async {
    final confirmed = await confirmFailTask(context, task);
    if (!confirmed || !mounted) return;
    final failOutcome = await AppScope.read(
      context,
    ).service.failTask(task.id, now: DateTime.now());
    if (!mounted) return;
    await _afterMutation(null);
    if (!mounted || failOutcome == null) return;
    showNotice(context, '「${failOutcome.taskName}」已标记失败，任务保留在已失败里');
  }

  Future<void> _openDailyPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DailyTasksPage()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final empty = _mainlines.isEmpty &&
        _sides.isEmpty &&
        _archive.isEmpty &&
        _failed.isEmpty &&
        _dailyTotal == 0;
    return Scaffold(
      appBar: AppBar(title: const Text('任务')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _dailyEntryCard(),
          if (empty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
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
          if (_failed.isNotEmpty) ...[
            _sectionHeader(
              context,
              icon: Icons.cancel,
              color: kFailColor,
              title: '已失败',
              subtitle: '没做成的事也留在路上',
              count: _failed.length,
            ),
            for (final t in _failed) _failedCard(t),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasks-fab',
        onPressed: () async {
          await showTaskDialog(
            context,
            allowedTypes: const [TaskType.mainline, TaskType.side],
          );
          await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('添加任务'),
      ),
    );
  }

  /// 每日任务入口卡：显示今天的进度，点进去看今天的操作与历史。
  Widget _dailyEntryCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _openDailyPage,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              const ClayAvatar(
                icon: Icons.today,
                color: _kDailyColor,
                size: 40,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '每日任务',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dailyTotal == 0
                          ? '还没有每日任务，点进去加一个'
                          : '今天 $_dailyDone/$_dailyTotal 已完成 · 0 点未完成会扣属性',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '历史',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
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
      if (t.rewardHealth == 0 && t.rewardDiscipline == 0 && t.rewardCharm == 0)
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
                kFailColor => Icons.cancel,
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

  Widget _menuButton(
    Task t, {
    List<Subtask>? subtasks,
    bool allowFail = true,
  }) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          await showTaskDialog(
            context,
            task: t,
            subtasks: subtasks,
            allowedTypes: const [TaskType.mainline, TaskType.side],
          );
          await _load();
        } else if (value == 'fail') {
          await _failTask(t);
        } else if (value == 'delete') {
          final confirmed = await _confirmDelete(context, t.name);
          if (confirmed && mounted) {
            await AppScope.read(context).service.deleteTask(t.id);
            await _load();
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('编辑')),
        if (allowFail) const PopupMenuItem(value: 'fail', child: Text('标记失败')),
        const PopupMenuItem(value: 'delete', child: Text('删除')),
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
              Expanded(child: _taskTitle(t)),
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

  Widget _taskTitle(Task t) {
    return Column(
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
              Expanded(child: _taskTitle(t)),
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
          _menuButton(t, allowFail: false),
        ],
      ),
    );
  }

  Widget _failedCard(Task t) {
    final when = t.failedAt;
    return _cardShell(
      context,
      kFailColor,
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
                    decoration: TextDecoration.lineThrough,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.type == TaskType.mainline ? '主线' : '支线'} · '
                  '${when != null ? '${when.year}/${when.month}/${when.day} 失败' : '失败'}'
                  ' · 任务保留',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _menuButton(t, allowFail: false),
        ],
      ),
    );
  }
}
