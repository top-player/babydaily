/// 连续坚持计算：每日习惯按天、每周 N 次习惯按连续达标周、笔记按天。
///
/// 全部为纯函数，输入输出都使用"日期部分"（DateTime 的时分秒忽略）。
library;

/// 只保留日期部分（本地时区）。
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// 所在自然周的周一（周一至周日为一周）。
DateTime mondayOf(DateTime day) {
  final d = dateOnly(day);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// 当前连续天数：从今天往回数连续存在打卡的日期。
///
/// 今天尚未打卡时不算断签——从昨天继续数（习惯/笔记都可当天补）。
int currentDailyStreak(Set<DateTime> dates, DateTime today) {
  final t = dateOnly(today);
  var cursor = dates.contains(t) ? t : t.subtract(const Duration(days: 1));
  var streak = 0;
  while (dates.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// 笔记的连续天数（语义同每日习惯：当天已写或今天还没写都可继续数）。
int noteStreakDays(Set<DateTime> days, DateTime today) =>
    currentDailyStreak(days, today);

/// 当前连续达标周数：每周 N 次习惯在自然周（周一至周日）内打卡 ≥ N 次即达标。
///
/// 本周进行中且未达标时视为"待定"，不打断连续；本周已结束（周日）仍未达标则断。
int currentWeeklyStreak(Set<DateTime> dates, int timesPerWeek, DateTime today) {
  final t = dateOnly(today);
  var weekStart = mondayOf(t);
  var isCurrentWeek = true;
  var streak = 0;
  // 防御：最多回看 5200 周
  for (var i = 0; i < 5200; i++) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final count = dates.where((d) {
      final day = dateOnly(d);
      return !day.isBefore(weekStart) && !day.isAfter(weekEnd) && !day.isAfter(t);
    }).length;

    if (count >= timesPerWeek) {
      streak++;
    } else if (isCurrentWeek && t.weekday != DateTime.sunday) {
      // 本周进行中未达标：待定，继续往前数
    } else {
      break;
    }
    isCurrentWeek = false;
    weekStart = weekStart.subtract(const Duration(days: 7));
  }
  return streak;
}
