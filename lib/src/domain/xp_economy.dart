/// 经验值经济与等级曲线（ADR-0003）。
///
/// 纯函数、无副作用；期望值以手工算例锁定在 test/domain/xp_economy_test.dart。
library;

/// 满级等级。
const int maxLevel = 50;

/// 初始等级。
const int startingLevel = 1;

/// 固定经验来源（ADR-0003；笔记自 ADR-0006 起不再发放经验）。
const int mainlineXp = 50;
const int sideQuestXp = 20;
const int subtaskXp = 0;
const int dailyTaskXp = 1;
const int habitCheckinXp = 5;

/// 每日登录经验：每天第一次打开应用 +1（不打开不涨）。
const int dailyLoginXp = 1;

/// 每日习惯连续里程碑：连续天数 → 一次性经验奖励。
const Map<int, int> milestoneRewards = {10: 20, 20: 30, 30: 50};

/// 升到下一级所需经验（分段公式，ADR-0003）。
int nextExpForLevel(int level) {
  if (level >= 50) {
    return 200 + (level - 50) * 10; // 备用公式，封顶后不使用
  }
  if (level >= 30) {
    return 110 + (level - 30) * 6;
  }
  if (level >= 10) {
    return 70 + (level - 10) * 4;
  }
  return 40 + (level - 1) * 3;
}

/// 到达 [level] 级所需的累计经验（Lv1 为 0）。
int totalXpForLevel(int level) {
  var total = 0;
  for (var lv = 1; lv < level; lv++) {
    total += nextExpForLevel(lv);
  }
  return total;
}

/// 累计经验对应的等级，满级 [maxLevel] 封顶。
int levelForXp(int xp) {
  var level = startingLevel;
  while (level < maxLevel && xp >= totalXpForLevel(level + 1)) {
    level++;
  }
  return level;
}

/// 等级 → 称号（纯装饰，取不超过当前等级的最高档）。
String titleForLevel(int level) {
  const titles = <int, String>{
    50: '人生赢家',
    40: '生活冠军',
    30: '自律大师',
    20: '自律达人',
    15: '自律新星',
    10: '持之以恒',
    5: '小有所成',
    1: '初出茅庐',
  };
  final thresholds = titles.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final threshold in thresholds) {
    if (level >= threshold) {
      return titles[threshold]!;
    }
  }
  return titles[1]!;
}

/// 当前等级内已积累的经验（用于进度条"已填充"部分）。
int xpIntoLevel(int xp) {
  final level = levelForXp(xp);
  return xp - totalXpForLevel(level);
}

/// 升到下一级还差的经验；满级时为 0。
int xpNeededForNext(int xp) {
  final level = levelForXp(xp);
  if (level >= maxLevel) {
    return 0;
  }
  return nextExpForLevel(level);
}
