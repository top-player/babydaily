import 'package:flutter_test/flutter_test.dart';
import 'package:babydaily/src/domain/milestone.dart';

void main() {
  group('newlyReachedMilestones（打卡后新跨越的连续里程碑）', () {
    const rewards = {10: 20, 20: 30, 30: 50};

    test('第 10 天打卡：发放 10 天奖励', () {
      final reached = newlyReachedMilestones(
        previousStreak: 9,
        newStreak: 10,
        alreadyGranted: const {},
        rewards: rewards,
      );
      expect(reached, [const MilestoneReached(days: 10, xp: 20)]);
    });

    test('第 20/30 天分别发放对应奖励', () {
      expect(
        newlyReachedMilestones(
          previousStreak: 19,
          newStreak: 20,
          alreadyGranted: const {},
          rewards: rewards,
        ),
        [const MilestoneReached(days: 20, xp: 30)],
      );
      expect(
        newlyReachedMilestones(
          previousStreak: 29,
          newStreak: 30,
          alreadyGranted: const {},
          rewards: rewards,
        ),
        [const MilestoneReached(days: 30, xp: 50)],
      );
    });

    test('12 天：没有任何新里程碑', () {
      expect(
        newlyReachedMilestones(
          previousStreak: 11,
          newStreak: 12,
          alreadyGranted: const {},
          rewards: rewards,
        ),
        isEmpty,
      );
    });

    test('已领过的里程碑不再重复发放（终身一次）', () {
      expect(
        newlyReachedMilestones(
          previousStreak: 9,
          newStreak: 10,
          alreadyGranted: const {10},
          rewards: rewards,
        ),
        isEmpty,
      );
    });

    test('断签后重建到 10 天也不再发放', () {
      expect(
        newlyReachedMilestones(
          previousStreak: 9,
          newStreak: 10,
          alreadyGranted: const {10, 20, 30},
          rewards: rewards,
        ),
        isEmpty,
      );
    });

    test('一次跨越多个档（数据恢复等跳变场景）逐个发放', () {
      final reached = newlyReachedMilestones(
        previousStreak: 5,
        newStreak: 20,
        alreadyGranted: const {},
        rewards: rewards,
      );
      expect(reached, const [
        MilestoneReached(days: 10, xp: 20),
        MilestoneReached(days: 20, xp: 30),
      ]);
    });

    test('连续没变化：不发放', () {
      expect(
        newlyReachedMilestones(
          previousStreak: 10,
          newStreak: 10,
          alreadyGranted: const {},
          rewards: rewards,
        ),
        isEmpty,
      );
    });
  });
}
