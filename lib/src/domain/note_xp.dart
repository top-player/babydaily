/// 笔记经验：当天存在 ≥20 字笔记时，+10 基础经验 + 连续加成（ADR-0003）。
library;

import 'package:babydaily/src/domain/xp_economy.dart';

/// [noteStreak] 为截至今天（含今天）的连续写笔记天数；当天没有合格笔记时传 0。
///
/// 公式：10 + min(N-1, 5)，封顶 15；断档后 N 重新从 1 计。
int noteXpForStreak(int noteStreak) {
  if (noteStreak < 1) {
    return 0;
  }
  final bonus = (noteStreak - 1).clamp(0, noteStreakBonusCap);
  return noteBaseXp + bonus;
}
