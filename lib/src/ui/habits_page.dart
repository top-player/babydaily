/// 习惯页：今日打卡列表、连续/累计、归档区；点卡片进入日历详情。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/feedback.dart';
import 'package:babydaily/src/ui/habit_detail_page.dart';
import 'package:babydaily/src/ui/motion.dart';
import 'package:babydaily/src/ui/theme.dart';

const Color _kHabitFlame = Color(0xFFE8710A);
const Color _kHabitWeekly = kHealthColor;

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  List<Habit> _habits = [];
  List<Habit> _archived = [];
  Map<int, HabitStatus> _statusByHabit = {};
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 一次性加载：避免业务通知触发的重复查库与整树重建。
    if (!_loadStarted) {
      _loadStarted = true;
      _load();
    }
  }

  Future<void> _load() async {
    final service = AppScope.read(context).service;
    final all = await service.habits(includeArchived: true);
    // 各习惯状态并行查询（原为串行 N+1）。
    final statusList = await Future.wait([
      for (final h in all) service.habitStatus(h.id, now: DateTime.now()),
    ]);
    final statuses = <int, HabitStatus>{
      for (var i = 0; i < all.length; i++) all[i].id: statusList[i],
    };
    if (mounted) {
      setState(() {
        _habits = all.where((h) => !h.isArchived).toList();
        _archived = all.where((h) => h.isArchived).toList();
        _statusByHabit = statuses;
      });
    }
  }

  Future<void> _checkIn(Habit habit) async {
    final controller = AppScope.read(context);
    final outcome = await controller.service.checkInHabit(
      habit.id,
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
    final doneCount = _habits
        .where((h) => (_statusByHabit[h.id]?.checkedToday ?? false))
        .length;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('习惯')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_habits.isNotEmpty) ...[
            HeroCard(
              colors: [scheme.primaryContainer, scheme.secondaryContainer],
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surface.withValues(alpha: 0.55),
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: _kHabitFlame,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '今日打卡 $doneCount / ${_habits.length}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                        Text(
                          '🔥',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _habits.isEmpty ? 0 : doneCount / _habits.length,
                        minHeight: 10,
                        backgroundColor: scheme.surface.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(_kHabitFlame),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_habits.isEmpty && _archived.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  ClayAvatar(
                    icon: Icons.local_fire_department,
                    color: _kHabitFlame,
                    size: 76,
                    iconSize: 36,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '还没有习惯，点右下角养一个吧',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          for (final h in _habits) _habitCard(h),
          if (_archived.isNotEmpty) ...[
            SectionHeader(
              icon: Icons.inventory_2_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              title: '已归档',
              subtitle: '暂时休息的习惯',
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
    return _HabitCard(
      key: ValueKey<int>(h.id),
      habit: h,
      status:
          _statusByHabit[h.id] ??
          const HabitStatus(
            streak: 0,
            cumulative: 0,
            checkedToday: false,
            checkinDates: [],
          ),
      archived: archived,
      onReload: _load,
      onCheckIn: () => _checkIn(h),
      menu: _habitMenu(h),
    );
  }

  Widget _habitMenu(Habit h) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        final service = AppScope.read(context).service;
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
    final controller = AppScope.read(context);
    final nameController = TextEditingController(text: habit?.name ?? '');
    final descController = TextEditingController(
      text: habit?.description ?? '',
    );
    final healthController = TextEditingController(
      text: habit != null && habit.rewardHealth > 0
          ? '${habit.rewardHealth}'
          : '0',
    );
    final disciplineController = TextEditingController(
      text: habit != null && habit.rewardDiscipline > 0
          ? '${habit.rewardDiscipline}'
          : '1',
    );
    final charmController = TextEditingController(
      text: habit != null && habit.rewardCharm > 0
          ? '${habit.rewardCharm}'
          : '0',
    );
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
                      value: HabitFrequency.daily,
                      label: Text('每日'),
                    ),
                    ButtonSegment(
                      value: HabitFrequency.weekly,
                      label: Text('每周 N 次'),
                    ),
                  ],
                  selected: {frequency},
                  onSelectionChanged: (s) =>
                      setDialogState(() => frequency = s.first),
                ),
                if (frequency == HabitFrequency.weekly) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '每周次数',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => setDialogState(
                          () => timesPerWeek = (timesPerWeek - 1).clamp(1, 7),
                        ),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$timesPerWeek 次',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => setDialogState(
                          () => timesPerWeek = (timesPerWeek + 1).clamp(1, 7),
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '打卡奖励（属性，经验固定 +5）',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Row(
                  children: [
                    Expanded(child: _field('健康', healthController)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('自律', disciplineController)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('魅力', charmController)),
                  ],
                ),
                if (habit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '修改频率或每周次数会重新计算连续天数（累计保留）。',
                      style: Theme.of(context).textTheme.bodySmall,
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
        discipline: (int.tryParse(disciplineController.text) ?? 0).clamp(
          0,
          100,
        ),
        charm: (int.tryParse(charmController.text) ?? 0).clamp(0, 100),
      );
      if (habit == null) {
        await controller.service.createHabit(
          name: name,
          description: descController.text.trim(),
          frequencyType: frequency,
          timesPerWeek: frequency == HabitFrequency.weekly ? timesPerWeek : 1,
          reward: reward,
        );
      } else {
        await controller.service.updateHabit(
          id: habit.id,
          name: name,
          description: descController.text.trim(),
          frequencyType: frequency,
          timesPerWeek: frequency == HabitFrequency.weekly ? timesPerWeek : 1,
          reward: reward,
          now: DateTime.now(),
        );
      }
    }
    // 注意：不在对话框关闭动画期间 dispose controller（见 notes_page 同款注释）。
  }

  Widget _field(String label, TextEditingController controller) {
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
}

/// 一张习惯卡片：点卡片走容器变换（从卡片位置放大）进详情页。
///
/// 做成 StatefulWidget 是为了让 [Opener] 随这张卡的 Element 只建一次——
/// 若在列表构建里现建，`GlobalKey` 每次重建都会换新，容器状态跟着重来。
class _HabitCard extends StatefulWidget {
  const _HabitCard({
    super.key,
    required this.habit,
    required this.status,
    required this.archived,
    required this.onReload,
    required this.onCheckIn,
    required this.menu,
  });

  final Habit habit;
  final HabitStatus status;
  final bool archived;

  /// 详情页返回后刷新列表。
  final Future<void> Function() onReload;

  /// 打卡（卡片内的按钮，点它不触发容器变换）。
  final VoidCallback onCheckIn;

  /// 卡片右侧的 ⋮ 菜单。
  final Widget menu;

  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> {
  late final Opener _opener = openContainerTransform(
    context: context,
    openBuilder: (context, close) => HabitDetailPage(habit: widget.habit),
    closedBuilder: _closedCard,
    onClosed: (_) => widget.onReload(),
  );

  @override
  Widget build(BuildContext context) => _opener;

  Widget _closedCard(BuildContext context, VoidCallback open) {
    final h = widget.habit;
    final status = widget.status;
    final archived = widget.archived;
    final unit = h.frequencyType == HabitFrequency.daily ? '天' : '周';
    final accent = h.frequencyType == HabitFrequency.daily
        ? _kHabitFlame
        : _kHabitWeekly;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: open,
        // 水波纹画在卡片自己的 Material 上：外层容器的 Material 是透明的，
        // 波纹画在那层会被卡片内容盖住。
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Opacity(
              opacity: archived ? 0.55 : 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClayAvatar(
                    icon: h.frequencyType == HabitFrequency.daily
                        ? Icons.local_fire_department
                        : Icons.event_repeat,
                    color: accent,
                    size: 44,
                    iconSize: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (h.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              h.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            TagPill(
                              icon: Icons.local_fire_department,
                              text: '连续 ${status.streak} $unit',
                              color: _kHabitFlame,
                            ),
                            TagPill(
                              icon: Icons.check_circle_outline,
                              text: '累计 ${status.cumulative} 次',
                              color: _kHabitWeekly,
                            ),
                            if (h.frequencyType == HabitFrequency.weekly &&
                                h.timesPerWeek > 0)
                              TagPill(
                                text: '每周 ${h.timesPerWeek} 次',
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            if (h.rewardDiscipline > 0 ||
                                h.rewardHealth > 0 ||
                                h.rewardCharm > 0)
                              TagPill(
                                text: [
                                  if (h.rewardHealth > 0)
                                    '健康+${h.rewardHealth}',
                                  if (h.rewardDiscipline > 0)
                                    '自律+${h.rewardDiscipline}',
                                  if (h.rewardCharm > 0)
                                    '魅力+${h.rewardCharm}',
                                ].join(' '),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!archived)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: status.checkedToday
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: kHealthColor.withValues(alpha: 0.13),
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
                                    '已打卡',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: kHealthColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: widget.onCheckIn,
                              child: const Text('打卡'),
                            ),
                    ),
                  widget.menu,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
