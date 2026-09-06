/// 习惯连续里程碑：跨越 10/20/30 天时各发放一次（每习惯终身一次）。
library;

import 'package:babydaily/src/domain/xp_economy.dart';

/// 一次新跨越的里程碑及其奖励。
class MilestoneReached {
  const MilestoneReached({required this.days, required this.xp});

  final int days;
  final int xp;

  @override
  bool operator ==(Object other) =>
      other is MilestoneReached && other.days == days && other.xp == xp;

  @override
  int get hashCode => Object.hash(days, xp);

  @override
  String toString() => 'MilestoneReached(days: $days, xp: $xp)';
}

/// 计算 [previousStreak] → [newStreak] 之间新跨越的里程碑。
///
/// 规则：`newStreak >= days 且 previousStreak < days` 且未在 [alreadyGranted]
/// 中出现过，才发放；从小到大排列。
List<MilestoneReached> newlyReachedMilestones({
  required int previousStreak,
  required int newStreak,
  required Set<int> alreadyGranted,
  Map<int, int> rewards = milestoneRewards,
}) {
  final thresholds = rewards.keys.toList()..sort();
  return [
    for (final days in thresholds)
      if (newStreak >= days &&
          previousStreak < days &&
          !alreadyGranted.contains(days))
        MilestoneReached(days: days, xp: rewards[days]!),
  ];
}
