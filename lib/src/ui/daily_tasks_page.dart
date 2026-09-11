/// 每日任务页：顶部今天（可完成 / 可判失败），下方按日期上下滑动查看历史。
///
/// 历史来自 [DailyTaskLogs]：完成与失败都会落一条当天记录，
/// 0 点结算把未完成的任务记为失败（ADR-0004 / ADR-0007），任务本身保留。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/streak.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/feedback.dart';
import 'package:babydaily/src/ui/task_editor.dart';
import 'package:babydaily/src/ui/theme.dart';

const Color _kDailyColor = kDisciplineColor;

/// 历史每次多铺的天数（滚到底再往前铺）。
const int _dayPageSize = 14;

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  final ScrollController _scroll = ScrollController();

  List<Task> _tasks = [];
  Map<String, List<DailyTaskLog>> _logsByDate = {};
  /// 时间线上已铺开的天数（含今天）。
  int _days = _dayPageSize;
  /// 能回溯的最长天数（第一条记录或最早创建的任务决定）。
  int _maxDays = _dayPageSize;
  bool _loadStarted = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _load();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final service = AppScope.read(context).service;
    final tasksF = service.dailyTasks();
    final logsF = service.dailyLogs();
    final tasks = await tasksF;
    final logs = await logsF;

    final byDate = <String, List<DailyTaskLog>>{};
    for (final log in logs) {
      byDate.putIfAbsent(log.date, () => []).add(log);
    }

    final today = dateOnly(DateTime.now());
    var earliest = today;
    for (final key in byDate.keys) {
      final day = DateTime.parse(key);
      if (day.isBefore(earliest)) earliest = day;
    }
    for (final t in tasks) {
      final created = dateOnly(t.createdAt);
      if (created.isBefore(earliest)) earliest = created;
    }
    final span = today.difference(earliest).inDays + 1;
    final maxDays = math.max(span, _dayPageSize);

    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _logsByDate = byDate;
      _maxDays = maxDays;
      _days = math.min(math.max(_days, _dayPageSize), maxDays);
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients || _days >= _maxDays) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      setState(() => _days = math.min(_days + _dayPageSize, _maxDays));
    }
  }

  // ---- 操作 ----

  Future<void> _complete(Task task) async {
    final controller = AppScope.read(context);
    final outcome = await controller.service.completeTask(
      task.id,
      now: DateTime.now(),
    );
    if (!mounted) return;
    if (outcome == null) {
      await _load();
      return;
    }
    showGrowthFeedback(context, outcome);
    await controller.refresh();
    await _load();
    if (!mounted) return;
    final today = dateString(DateTime.now());
    if (_tasks.isNotEmpty && _tasks.every((t) => t.completedOn == today)) {
      showCelebration(context, '每日任务全清，今天也很棒！');
    }
  }

  Future<void> _fail(Task task) async {
    final confirmed = await confirmFailTask(context, task);
    if (!confirmed || !mounted) return;
    final controller = AppScope.read(context);
    final outcome = await controller.service.failTask(
      task.id,
      now: DateTime.now(),
    );
    if (!mounted) return;
    await controller.refresh();
    await _load();
    if (!mounted) return;
    if (outcome == null) return;
    final lost = _penaltyText(outcome.penalty.health, outcome.penalty.discipline,
        outcome.penalty.charm);
    showNotice(
      context,
      lost.isEmpty ? '「${outcome.taskName}」已记为失败' : '「${outcome.taskName}」失败，扣除 $lost',
      warning: lost.isNotEmpty,
    );
  }

  // ---- 今天 ----

  Widget _todaySection(String todayKey, DateTime today) {
    final todayLogs = _logsByDate[todayKey] ?? const <DailyTaskLog>[];
    final failedToday = <int?>{
      for (final log in todayLogs)
        if (log.status == DailyTaskStatus.failed) log.taskId,
    };
    final aliveIds = {for (final t in _tasks) t.id};
    // 今天被删掉的每日任务：仍在历史里留一条只读记录
    final orphanLogs = [
      for (final log in todayLogs)
        if (!aliveIds.contains(log.taskId)) log,
    ];
    final doneCount =
        _tasks.where((t) => t.completedOn == todayKey).length +
            orphanLogs
                .where((l) => l.status == DailyTaskStatus.completed)
                .length;
    final failCount = failedToday.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '今天 · ${_dayLabel(today)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_tasks.isNotEmpty || orphanLogs.isNotEmpty) ...[
              TagPill(
                icon: Icons.check_circle,
                text: '$doneCount 完成',
                color: kHealthColor,
              ),
              const SizedBox(width: 6),
              TagPill(
                icon: Icons.cancel,
                text: '$failCount 失败',
                color: kFailColor,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (_tasks.isEmpty && orphanLogs.isEmpty)
          _emptyCard()
        else ...[
          for (final t in _tasks) _todayCard(t, todayKey, failedToday),
          for (final log in orphanLogs) _logCard(log, readonly: true),
        ],
      ],
    );
  }

  Widget _emptyCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            ClayAvatar(
              icon: Icons.today,
              color: _kDailyColor,
              size: 64,
              iconSize: 30,
            ),
            const SizedBox(height: 12),
            Text('还没有每日任务', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '点右下角加一个，0 点未完成会扣属性并记为失败',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayCard(Task t, String todayKey, Set<int?> failedToday) {
    final done = t.completedOn == todayKey;
    final failed = failedToday.contains(t.id);
    final penaltyText = _penaltyText(
      t.rewardHealth,
      t.rewardDiscipline,
      t.rewardCharm,
    );
    return _card(
      accent: failed ? kFailColor : _kDailyColor,
      opacity: done || failed ? 0.85 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(
            name: t.name,
            description: t.description,
            trailing: _menu(t),
          ),
          const SizedBox(height: 8),
          _rewardChips(t),
          const SizedBox(height: 10),
          if (done)
            _statusBanner(
              icon: Icons.check_circle,
              color: kHealthColor,
              text: '今日已完成，明天继续',
            )
          else if (failed)
            _statusBanner(
              icon: Icons.cancel,
              color: kFailColor,
              text: penaltyText.isEmpty
                  ? '今日已记为失败'
                  : '今日已记为失败，扣除 $penaltyText',
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => _complete(t),
                    child: const Text('完成'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: kFailColor,
                      side: BorderSide(
                        color: kFailColor.withValues(alpha: 0.5),
                      ),
                    ),
                    onPressed: () => _fail(t),
                    child: const Text('标记失败'),
                  ),
                ),
              ],
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
    );
  }

  // ---- 历史 ----

  Widget _historySection(DateTime today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '历史',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '按日期上下滑动',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        for (var i = 1; i < _days; i++)
          _daySection(today.subtract(Duration(days: i)), i),
        if (_days < _maxDays)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                '继续往下滑，加载更早的记录…',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }

  Widget _daySection(DateTime day, int daysAgo) {
    final logs = _logsByDate[dateString(day)] ?? const <DailyTaskLog>[];
    final done = logs.where((l) => l.status == DailyTaskStatus.completed).length;
    final failed = logs.where((l) => l.status == DailyTaskStatus.failed).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_relativeDayLabel(daysAgo)} · ${_dayLabel(day)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (done > 0)
                TagPill(
                  icon: Icons.check_circle,
                  text: '$done 完成',
                  color: kHealthColor,
                ),
              if (done > 0 && failed > 0) const SizedBox(width: 6),
              if (failed > 0)
                TagPill(
                  icon: Icons.cancel,
                  text: '$failed 失败',
                  color: kFailColor,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                '这天没有记录',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final log in logs) _logCard(log),
        ],
      ),
    );
  }

  /// 历史里的一条每日任务记录（只读快照）。
  Widget _logCard(DailyTaskLog log, {bool readonly = false}) {
    final completed = log.status == DailyTaskStatus.completed;
    final lost = _penaltyText(
      log.penaltyHealth,
      log.penaltyDiscipline,
      log.penaltyCharm,
    );
    final color = completed ? kHealthColor : kFailColor;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.cancel,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.taskName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration:
                          completed ? null : TextDecoration.lineThrough,
                      color: completed
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!completed) ...[
                    const SizedBox(height: 2),
                    Text(
                      lost.isEmpty ? '未完成（任务保留）' : '未完成 · 扣除 $lost',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kFailColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (readonly)
              Text(
                completed ? '已完成' : '失败',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- 通用小件 ----

  Widget _card({
    required Color accent,
    required Widget child,
    double opacity = 1,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Opacity(
          opacity: opacity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClayAvatar(icon: Icons.today, color: accent, size: 40, iconSize: 20),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleRow({
    required String name,
    required String description,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _statusBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardChips(Task t) {
    final chips = <Widget>[
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
        TagPill(
          text: '无属性奖励',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    ];
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _menu(Task t) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          await showTaskDialog(
            context,
            task: t,
            allowedTypes: const [TaskType.daily],
          );
          await _load();
        } else if (value == 'fail') {
          await _fail(t);
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
        PopupMenuItem(value: 'fail', child: Text('标记失败')),
        PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除每日任务'),
        content: Text('确定删除「$name」吗？历史记录会保留。'),
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

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('每日任务')),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _todaySection(dateString(today), today),
          _historySection(today),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'daily-fab',
        onPressed: () async {
          await showTaskDialog(
            context,
            allowedTypes: const [TaskType.daily],
          );
          await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('添加每日任务'),
      ),
    );
  }
}

/// 属性扣除文案（只列非 0 项）。
String _penaltyText(int health, int discipline, int charm) => [
  if (health > 0) '健康 -$health',
  if (discipline > 0) '自律 -$discipline',
  if (charm > 0) '魅力 -$charm',
].join('、');

/// '2026年6月5日 周五'。
String _dayLabel(DateTime day) =>
    '${day.year}年${day.month}月${day.day}日 周${_weekday(day.weekday)}';

/// 今天/昨天/前天/N 天前。
String _relativeDayLabel(int daysAgo) => switch (daysAgo) {
  1 => '昨天',
  2 => '前天',
  _ => '$daysAgo 天前',
};

String _weekday(int weekday) => switch (weekday) {
  DateTime.monday => '一',
  DateTime.tuesday => '二',
  DateTime.wednesday => '三',
  DateTime.thursday => '四',
  DateTime.friday => '五',
  DateTime.saturday => '六',
  _ => '日',
};
