/// 习惯详情：月历打卡视图 + 年度热力图 + 统计。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/feedback.dart';
import 'package:babydaily/src/ui/theme.dart';

const Color _kHabitFlame = Color(0xFFE8710A);
const Color _kHabitWeekly = kHealthColor;

class HabitDetailPage extends StatefulWidget {
  const HabitDetailPage({super.key, required this.habit});

  final Habit habit;

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  HabitStatus? _status;
  Set<String> _dates = {};
  GameService? _service;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 注意：不能在 initState 中查找 AppScope（InheritedWidget），
    // 框架会抛 "dependOnInheritedWidgetOfExactType was called before
    // initState() completed" 异常导致白屏。
    if (!_loadStarted) {
      _loadStarted = true;
      _service = AppScope.of(context).service;
      _load();
    }
  }

  Future<void> _load() async {
    final service = _service;
    if (service == null) return;
    final status = await service.habitStatus(
      widget.habit.id,
      now: DateTime.now(),
    );
    if (mounted) {
      setState(() {
        _status = status;
        _dates = status.checkinDates.toSet();
      });
    }
  }

  Future<void> _checkIn() async {
    final controller = AppScope.of(context);
    final outcome = await controller.service.checkInHabit(
      widget.habit.id,
      now: DateTime.now(),
    );
    if (outcome == null) return;
    if (mounted) {
      HapticFeedback.lightImpact();
      showGrowthFeedback(context, outcome);
      showMilestoneFeedback(context, outcome.milestones);
      if ({7, 30, 100}.contains(outcome.streak)) {
        showCelebration(context, '连续坚持 ${outcome.streak} 天，了不起！');
      }
    }
    await controller.refresh();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final isDaily = widget.habit.frequencyType == HabitFrequency.daily;
    final unit = isDaily ? '天' : '周';
    final scheme = Theme.of(context).colorScheme;
    final accent = isDaily ? _kHabitFlame : _kHabitWeekly;
    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;
    return Scaffold(
      appBar: AppBar(title: Text(widget.habit.name)),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                HeroCard(
                  colors: [scheme.primaryContainer, scheme.secondaryContainer],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surface.withValues(alpha: 0.55),
                          ),
                          child: Icon(
                            isDaily
                                ? Icons.local_fire_department
                                : Icons.event_repeat,
                            color: accent,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '连续 ${status.streak} $unit',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '累计打卡 ${status.cumulative} 次'
                                '${isDaily ? '' : ' · 每周 ${widget.habit.timesPerWeek} 次达标'}',
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.habit.isArchived)
                          status.checkedToday
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.surface.withValues(
                                      alpha: 0.7,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: kHealthColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '今日已打卡',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: kHealthColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : FilledButton(
                                  onPressed: _checkIn,
                                  child: const Text('打卡'),
                                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(
                                () => _month = DateTime(
                                  _month.year,
                                  _month.month - 1,
                                ),
                              ),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: Text(
                                '${_month.year} 年 ${_month.month} 月',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(
                                () => _month = DateTime(
                                  _month.year,
                                  _month.month + 1,
                                ),
                              ),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            TagPill(
                              icon: Icons.check_circle_outline,
                              text:
                                  '本月打卡 ${_countInMonth(status.checkinDates, _month)} 次',
                              color: accent,
                            ),
                            const Spacer(),
                            if (!isCurrentMonth)
                              TextButton(
                                onPressed: () => setState(() {
                                  _month = DateTime(now.year, now.month);
                                }),
                                child: const Text('回到本月'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _MonthCalendar(
                          month: _month,
                          checkinDates: _dates,
                          accent: accent,
                          onDayTap: _jumpToDay,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${now.year} 年热力图',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _YearHeatmap(
                          year: now.year,
                          checkinDates: _dates,
                          accent: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  int _countInMonth(List<String> checkinDates, DateTime month) {
    final prefix = '${month.year}-${month.month.toString().padLeft(2, '0')}-';
    return checkinDates.where((d) => d.startsWith(prefix)).length;
  }

  void _jumpToDay(DateTime day) {
    setState(() {
      _month = DateTime(day.year, day.month);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text('已定位到 ${day.year}/${day.month}'),
        ),
      );
  }
}

/// 月历：周一起始，打卡日高亮。
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.checkinDates,
    required this.accent,
    required this.onDayTap,
  });

  final DateTime month;
  final Set<String> checkinDates;
  final Color accent;
  final ValueChanged<DateTime> onDayTap;

  String _key(DateTime d) => dateString(d);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = firstDay.weekday - 1; // 周一为 0
    final today = DateTime.now();

    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final checked = checkinDates.contains(_key(date));
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      cells.add(
        InkWell(
          onTap: () => onDayTap(date),
          customBorder: const CircleBorder(),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked
                  ? accent
                  : scheme.surfaceContainerLow.withValues(alpha: 0.6),
              border: isToday
                  ? Border.all(color: accent, width: 1.8)
                  : Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                color: checked
                    ? Colors.white
                    : isToday
                    ? accent
                    : null,
              ),
            ),
          ),
        ),
      );
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    return Column(
      children: [
        Row(
          children: [
            for (final label in const ['一', '二', '三', '四', '五', '六', '日'])
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }
}

/// 年度热力图：一行一个自然周（周一起始），打卡日着色。
class _YearHeatmap extends StatelessWidget {
  const _YearHeatmap({
    required this.year,
    required this.checkinDates,
    required this.accent,
  });

  final int year;
  final Set<String> checkinDates;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(year, 1, 1);
    final start = first.subtract(Duration(days: first.weekday - 1));
    final end = DateTime(year, 12, 31);
    final totalDays = end.difference(start).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    final rows = <Widget>[];
    for (var week = 0; week < weeks; week++) {
      final row = <Widget>[];
      for (var day = 0; day < 7; day++) {
        final date = start.add(Duration(days: week * 7 + day));
        final inYear = date.year == year;
        final checked = checkinDates.contains(dateString(date));
        row.add(
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: !inYear
                  ? Colors.transparent
                  : checked
                  ? accent
                  : scheme.surfaceContainerLow,
            ),
          ),
        );
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: row));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: rows),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendCell(scheme.surfaceContainerLow),
              const SizedBox(width: 4),
              Text('未打卡', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 12),
              _legendCell(accent),
              const SizedBox(width: 4),
              Text('已打卡', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendCell(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color,
      ),
    );
  }
}
