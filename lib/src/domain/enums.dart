/// 领域枚举：任务类型、习惯频率、性别、场景。
library;

/// 任务类型：主线（长期目标，可拆子项）/ 支线（一次性）/ 每日任务（0 点重置）。
enum TaskType { mainline, side, daily }

/// 每日任务的单日结果：完成 / 失败。
///
/// 「未完成」不是记录状态而是派生状态：当天还没到 0 点结算、
/// 也没有手动标记失败时，任务就是未完成。
enum DailyTaskStatus { completed, failed }

/// 习惯频率：每日 / 每周 N 次。
enum HabitFrequency { daily, weekly }

/// 主角性别（只影响头像与文案）。
enum Gender { male, female, secret }

/// 场景：家里 / 公司 / 游玩（纯氛围层，手动切换）。
enum Scene { home, company, play }
