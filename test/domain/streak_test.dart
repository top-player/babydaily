import 'package:flutter_test/flutter_test.dart';
import 'package:babydaily/src/domain/streak.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  group('currentDailyStreak（每日习惯的当前连续天数）', () {
    test('今天已打卡：连续 3 天', () {
      final dates = {d(2026, 6, 1), d(2026, 6, 2), d(2026, 6, 3)};
      expect(currentDailyStreak(dates, d(2026, 6, 3)), 3);
    });

    test('今天还没打卡：连续仍活着，算到昨天', () {
      final dates = {d(2026, 6, 1), d(2026, 6, 2), d(2026, 6, 3)};
      expect(currentDailyStreak(dates, d(2026, 6, 4)), 3);
    });

    test('昨天没打卡：断签归零', () {
      final dates = {d(2026, 6, 1), d(2026, 6, 2), d(2026, 6, 3)};
      expect(currentDailyStreak(dates, d(2026, 6, 5)), 0);
    });

    test('空集合与仅今天', () {
      expect(currentDailyStreak(<DateTime>{}, d(2026, 6, 5)), 0);
      expect(currentDailyStreak({d(2026, 6, 5)}, d(2026, 6, 5)), 1);
    });

    test('未来日期的打卡不算入（数据防御）', () {
      final dates = {d(2026, 6, 5), d(2026, 6, 8)}; // 6/8 是未来
      expect(currentDailyStreak(dates, d(2026, 6, 5)), 1);
    });
  });

  group('currentWeeklyStreak（每周 N 次习惯的连续达标周数）', () {
    // 2026-06-01 是周一；week0 = 6/1–6/7，weekM1 = 5/25–5/31，weekM2 = 5/18–5/24，weekM3 = 5/11–5/17
    final week0 = {d(2026, 6, 1), d(2026, 6, 2)};
    final weekM1 = {d(2026, 5, 25), d(2026, 5, 26), d(2026, 5, 27), d(2026, 5, 28)};
    final weekM2 = {d(2026, 5, 18), d(2026, 5, 20), d(2026, 5, 22)};

    test('本周进行中且未达标：不打断，从上周往前数', () {
      final dates = {...week0, ...weekM1, ...weekM2};
      // 周三：本周 2 次 < 3，进行中 → 连续 = 上周+上上周 = 2
      expect(currentWeeklyStreak(dates, 3, d(2026, 6, 3)), 2);
    });

    test('本周进行中已达标：计入连续', () {
      final dates = {
        d(2026, 6, 1),
        d(2026, 6, 2),
        d(2026, 6, 3),
        ...weekM1,
        ...weekM2,
      };
      expect(currentWeeklyStreak(dates, 3, d(2026, 6, 3)), 3);
    });

    test('周日（本周已结束）未达标：连续归零', () {
      final dates = {...week0, ...weekM1, ...weekM2}; // week0 只有 2 次
      expect(currentWeeklyStreak(dates, 3, d(2026, 6, 7)), 0);
    });

    test('周日达标：连续 3 周', () {
      final dates = {
        d(2026, 6, 1),
        d(2026, 6, 2),
        d(2026, 6, 7),
        ...weekM1,
        ...weekM2,
      };
      expect(currentWeeklyStreak(dates, 3, d(2026, 6, 7)), 3);
    });

    test('新的一周刚开始：上周达标，连续为 1（本周待定不打断）', () {
      // 今天 6/8 是周一，上一自然周 = 6/1–6/7
      final lastWeek = {d(2026, 6, 1), d(2026, 6, 3), d(2026, 6, 5)};
      expect(currentWeeklyStreak(lastWeek, 3, d(2026, 6, 8)), 1);
    });

    test('空记录与 N=1', () {
      expect(currentWeeklyStreak(<DateTime>{}, 3, d(2026, 6, 3)), 0);
      expect(currentWeeklyStreak({d(2026, 6, 1)}, 1, d(2026, 6, 3)), 1);
    });

    test('未来日期的打卡不算入本周', () {
      final dates = {d(2026, 6, 1), d(2026, 6, 5)}; // 6/5 在未来（今天是 6/3）
      expect(currentWeeklyStreak(dates, 2, d(2026, 6, 3)), 0);
    });
  });
}

