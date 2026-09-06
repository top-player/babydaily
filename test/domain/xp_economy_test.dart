import 'package:flutter_test/flutter_test.dart';
import 'package:babydaily/src/domain/xp_economy.dart';

void main() {
  group('nextExpForLevel（升到下一级所需经验，分段公式）', () {
    test('Lv 1–9 段：40 + (Lv-1)×3', () {
      expect(nextExpForLevel(1), 40);
      expect(nextExpForLevel(5), 52); // 40 + 4×3
      expect(nextExpForLevel(9), 64); // 40 + 8×3
    });

    test('Lv 10–29 段：70 + (Lv-10)×4', () {
      expect(nextExpForLevel(10), 70);
      expect(nextExpForLevel(20), 110); // 70 + 10×4
      expect(nextExpForLevel(29), 146); // 70 + 19×4
    });

    test('Lv 30–49 段：110 + (Lv-30)×6', () {
      expect(nextExpForLevel(30), 110);
      expect(nextExpForLevel(40), 170); // 110 + 10×6
      expect(nextExpForLevel(49), 224); // 110 + 19×6
    });

    test('Lv 50 及以上段：200 + (Lv-50)×10（备用，封顶后不使用）', () {
      expect(nextExpForLevel(50), 200);
      expect(nextExpForLevel(51), 210);
    });
  });

  group('totalXpForLevel（到达某级所需累计经验）', () {
    test('手工累加的分段边界', () {
      expect(totalXpForLevel(1), 0);
      expect(totalXpForLevel(2), 40);
      expect(totalXpForLevel(3), 83); // 40 + 43
      // 40+43+46+49+52+55+58+61 = 404
      expect(totalXpForLevel(9), 404);
      // 404 + 64 = 468
      expect(totalXpForLevel(10), 468);
      // Lv10-29 段共 20 项：20×70 + 4×(0..19)=1400+760=2160
      expect(totalXpForLevel(30), 468 + 2160); // 2628
      // Lv30-49 段共 20 项：20×110 + 6×(0..19)=2200+1140=3340
      expect(totalXpForLevel(50), 2628 + 3340); // 5968
    });
  });

  group('levelForXp（累计经验 → 等级，满级 50 封顶）', () {
    test('边界两侧', () {
      expect(levelForXp(0), 1);
      expect(levelForXp(39), 1);
      expect(levelForXp(40), 2);
      expect(levelForXp(467), 9);
      expect(levelForXp(468), 10);
      expect(levelForXp(2627), 29);
      expect(levelForXp(2628), 30);
      expect(levelForXp(5967), 49);
      expect(levelForXp(5968), 50);
    });

    test('满级后继续累计不突破 50', () {
      expect(levelForXp(100000), 50);
      expect(levelForXp(5968 + 99999), 50);
    });
  });

  group('titleForLevel（等级 → 称号，取不超过当前等级的最高档）', () {
    test('手工对照表', () {
      expect(titleForLevel(1), '初出茅庐');
      expect(titleForLevel(4), '初出茅庐');
      expect(titleForLevel(5), '小有所成');
      expect(titleForLevel(9), '小有所成');
      expect(titleForLevel(10), '持之以恒');
      expect(titleForLevel(14), '持之以恒');
      expect(titleForLevel(15), '自律新星');
      expect(titleForLevel(19), '自律新星');
      expect(titleForLevel(20), '自律达人');
      expect(titleForLevel(29), '自律达人');
      expect(titleForLevel(30), '自律大师');
      expect(titleForLevel(39), '自律大师');
      expect(titleForLevel(40), '生活冠军');
      expect(titleForLevel(49), '生活冠军');
      expect(titleForLevel(50), '人生赢家');
    });
  });

  group('经验经济常量（锁定 ADR-0003 的固定数值）', () {
    test('固定来源', () {
      expect(mainlineXp, 50);
      expect(sideQuestXp, 20);
      expect(subtaskXp, 0);
      expect(dailyTaskXp, 0);
      expect(habitCheckinXp, 5);
      expect(noteBaseXp, 10);
      expect(noteStreakBonusCap, 5);
    });

    test('每日习惯连续里程碑（每习惯终身一次）', () {
      expect(milestoneRewards, {10: 20, 20: 30, 30: 50});
    });

    test('等级上限与初始等级', () {
      expect(maxLevel, 50);
      expect(startingLevel, 1);
    });
  });

  group('xpIntoLevel / xpNeededForNext（进度条展示用）', () {
    test('Lv1 有 25 经验：进度 25/40', () {
      expect(xpIntoLevel(25), 25);
      expect(xpNeededForNext(25), 40);
    });

    test('满级 50 时所需经验为 0（进度条满）', () {
      expect(xpIntoLevel(6000), 6000 - 5968);
      expect(xpNeededForNext(6000), 0);
    });
  });
}
