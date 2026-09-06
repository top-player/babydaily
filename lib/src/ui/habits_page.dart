/// 习惯页：今日打卡列表、连续/累计、归档区；点卡片进入日历详情。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/feedback.dart';
import 'package:babydaily/src/ui/habit_detail_page.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  List<Habit> _habits = [];
  List<Habit> _archived = [];
  Map<int, HabitStatus> _statusByHabit = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final service = AppScope.of(context).service;
    final all = await service.habits(includeArchived: true);
    final statuses = <int, HabitStatus>{};
    for (final h in all) {
      statuses[h.id] =
          await service.habitStatus(h.id, now: DateTime.now());
    }
    if (mounted) {
      setState(() {
        _habits = all.where((h) => !h.isArchived).toList();
        _archived = all.where((h) => h.isArchived).toList();
        _statusByHabit = statuses;
      });
    }
  }

  Future<void> _checkIn(Habit habit) async {
    final controller = AppScope.of(context);
    final outcome =
        await controller.service.checkInHabit(habit.id, now: DateTime.now());
    if (outcome == null) return;
    if (mounted) {
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
    final doneCount =
        _habits.where((h) => (_statusByHabit[h.id]?.checkedToday ?? false)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('习惯')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_habits.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '今日打卡 $doneCount / ${_habits.length} 🔥',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_habits.isEmpty && _archived.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text('🔥', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text('还没有习惯，点右下角养一个吧',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          for (final h in _habits) _habitCard(h),
          if (_archived.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text('🗄️ 已归档',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            for (final h in _archived) _habitCard(h, archived: true),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'habits-fab',
        onPressed: () async {
          await _showHabitDialog(context);
          await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('添加习惯'),
      ),
    );
  }

  Widget _habitCard(Habit h, {bool archived = false}) {
    final status = _statusByHabit[h.id] ??
        const HabitStatus(
            streak: 0, cumulative: 0, checkedToday: false, checkinDates: []);
    final unit = h.frequencyType == HabitFrequency.daily ? '天' : '周';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => HabitDetailPage(habit: h),
          ));
          await _load();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Opacity(
            opacity: archived ? 0.55 : 1,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (h.description.isNotEmpty)
                        Text(h.description,
                            style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        '🔥 连续 ${status.streak} $unit · 累计 ${status.cumulative} 次'
                        '${h.frequencyType == HabitFrequency.weekly ? '（每周 ${h.timesPerWeek} 次）' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (h.rewardDiscipline > 0 ||
                          h.rewardHealth > 0 ||
                          h.rewardCharm > 0)
                        Text(
                          [
                            if (h.rewardHealth > 0) '健康+${h.rewardHealth}',
                            if (h.rewardDiscipline > 0)
                              '自律+${h.rewardDiscipline}',
                            if (h.rewardCharm > 0) '魅力+${h.rewardCharm}',
                          ].join(' '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (!archived)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: status.checkedToday
                        ? const Chip(
                            avatar: Icon(Icons.check, size: 16),
                            label: Text('已打卡'),
                          )
                        : FilledButton(
                            onPressed: () => _checkIn(h),
                            child: const Text('打卡'),
                          ),
                  ),
                _habitMenu(h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _habitMenu(Habit h) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        final service = AppScope.of(context).service;
        if (value == 'edit') {
          await _showHabitDialog(context, habit: h);
          await _load();
        } else if (value == 'archive') {
          await service.setHabitArchived(h.id, !h.isArchived);
          await _load();
        } else if (value == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('删除习惯'),
              content: Text('确定删除「${h.name}」吗？打卡记录与连续天数会一并删除，不可恢复。'),
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
          if (confirmed == true && mounted) {
            await service.deleteHabit(h.id);
            await _load();
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('编辑')),
        PopupMenuItem(
          value: 'archive',
          child: Text(h.isArchived ? '取消归档' : '归档'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    );
  }

  Future<void> _showHabitDialog(BuildContext context, {Habit? habit}) async {
    final controller = AppScope.of(context);
    final nameController = TextEditingController(text: habit?.name ?? '');
    final descController =
        TextEditingController(text: habit?.description ?? '');
    final healthController =
        TextEditingController(text: habit != null && habit.rewardHealth > 0
            ? '${habit.rewardHealth}'
            : '0');
    final disciplineController = TextEditingController(
        text: habit != null && habit.rewardDiscipline > 0
            ? '${habit.rewardDiscipline}'
            : '1');
    final charmController = TextEditingController(
        text: habit != null && habit.rewardCharm > 0
            ? '${habit.rewardCharm}'
            : '0');
    var frequency = habit?.frequencyType ?? HabitFrequency.daily;
    var timesPerWeek = habit?.timesPerWeek ?? 3;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(habit == null ? '添加习惯' : '编辑习惯'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 8),
                SegmentedButton<HabitFrequency>(
                  segments: const [
                    ButtonSegment(
                        value: HabitFrequency.daily, label: Text('每日')),
                    ButtonSegment(
                        value: HabitFrequency.weekly, label: Text('每周 N 次')),
                  ],
                  selected: {frequency},
                  onSelectionChanged: (s) =>
                      setDialogState(() => frequency = s.first),
                ),
                if (frequency == HabitFrequency.weekly) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('每周次数',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => setDialogState(
                            () => timesPerWeek = (timesPerWeek - 1).clamp(1, 7)),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$timesPerWeek 次',
                          style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                        onPressed: () => setDialogState(
                            () => timesPerWeek = (timesPerWeek + 1).clamp(1, 7)),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text('打卡奖励（属性，经验固定 +5）',
                    style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: [
                    Expanded(
                        child: _field('健康', healthController)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('自律', disciplineController)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('魅力', charmController)),
                  ],
                ),
                if (habit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '修改频率或每周次数会重新计算连续天数（累计保留）。',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).hintColor),
                    ),
                  ),
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

    if (saved == true) {
      final name = nameController.text.trim();
      if (name.isEmpty) return;
      final reward = AttributeDelta(
        health: (int.tryParse(healthController.text) ?? 0).clamp(0, 100),
        discipline:
            (int.tryParse(disciplineController.text) ?? 0).clamp(0, 100),
        charm: (int.tryParse(charmController.text) ?? 0).clamp(0, 100),
      );
      if (habit == null) {
        await controller.service.createHabit(
          name: name,
          description: descController.text.trim(),
          frequencyType: frequency,
          timesPerWeek: frequency == HabitFrequency.weekly
              ? timesPerWeek
              : 1,
          reward: reward,
        );
      } else {
        await controller.service.updateHabit(
          id: habit.id,
          name: name,
          description: descController.text.trim(),
          frequencyType: frequency,
          timesPerWeek: frequency == HabitFrequency.weekly
              ? timesPerWeek
              : 1,
          reward: reward,
          now: DateTime.now(),
        );
      }
    }
    // 注意：不在对话框关闭动画期间 dispose controller（见 notes_page 同款注释）。
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}
