import 'package:flutter_test/flutter_test.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/settlement.dart';

void main() {
  group('Attributes.applyGain（发放奖励，上限 100）', () {
    test('正常增加', () {
      expect(
        const Attributes(health: 50, discipline: 50, charm: 50)
            .applyGain(const AttributeDelta(health: 10, discipline: 5, charm: 0)),
        const Attributes(health: 60, discipline: 55, charm: 50),
      );
    });

    test('封顶 100', () {
      expect(
        const Attributes(health: 99, discipline: 100, charm: 50)
            .applyGain(const AttributeDelta(health: 2, discipline: 5, charm: 0)),
        const Attributes(health: 100, discipline: 100, charm: 50),
      );
    });
  });

  group('Attributes.applyPenalty（每日结算扣除，下限 0）', () {
    test('正常扣除', () {
      expect(
        const Attributes(health: 5, discipline: 5, charm: 5)
            .applyPenalty(const AttributeDelta(health: 2, discipline: 0, charm: 0)),
        const Attributes(health: 3, discipline: 5, charm: 5),
      );
    });

    test('下限 0，不为负', () {
      expect(
        const Attributes(health: 1, discipline: 0, charm: 5)
            .applyPenalty(const AttributeDelta(health: 2, discipline: 3, charm: 9)),
        const Attributes(health: 0, discipline: 0, charm: 0),
      );
    });
  });

  group('settleDailyTasks（0 点结算：未完成每日任务扣配置属性）', () {
    test('多任务惩罚累加', () {
      const current = Attributes(health: 10, discipline: 10, charm: 10);
      const penalties = [
        AttributeDelta(health: 3, discipline: 2, charm: 0),
        AttributeDelta(health: 2, discipline: 0, charm: 4),
      ];
      final outcome = settleDailyTasks(current: current, penalties: penalties);
      expect(outcome.after,
          const Attributes(health: 5, discipline: 8, charm: 6));
      expect(outcome.totalPenalty,
          const AttributeDelta(health: 5, discipline: 2, charm: 4));
    });

    test('没有未完成任务：不扣分、总惩罚为 0', () {
      const current = Attributes(health: 7, discipline: 8, charm: 9);
      final outcome = settleDailyTasks(current: current, penalties: const []);
      expect(outcome.after, current);
      expect(outcome.totalPenalty, AttributeDelta.zero);
    });

    test('零奖励任务：不产生惩罚', () {
      const current = Attributes(health: 7, discipline: 8, charm: 9);
      final outcome = settleDailyTasks(
          current: current, penalties: const [AttributeDelta.zero]);
      expect(outcome.after, current);
      expect(outcome.totalPenalty, AttributeDelta.zero);
    });

    test('属性已为 0：停在 0，无负数债务', () {
      const current = Attributes(health: 0, discipline: 0, charm: 0);
      final outcome = settleDailyTasks(current: current, penalties: const [
        AttributeDelta(health: 3, discipline: 3, charm: 3),
      ]);
      expect(outcome.after, current);
      expect(outcome.totalPenalty, const AttributeDelta(health: 0, discipline: 0, charm: 0));
    });
  });
}
