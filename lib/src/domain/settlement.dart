/// 每日结算（ADR-0004）：0 点重置每日任务，未完成者扣除其配置的属性。
library;

import 'package:babydaily/src/domain/attributes.dart';

/// 一次结算的结果：结算后的属性，以及实际扣除的总量（用于反馈展示）。
class SettlementOutcome {
  const SettlementOutcome({required this.after, required this.totalPenalty});

  final Attributes after;
  final AttributeDelta totalPenalty;
}

/// 对所有未完成每日任务的配置奖励求和，作为惩罚扣除；下限 0，不扣经验。
///
/// [SettlementOutcome.totalPenalty] 是实际生效的扣除量（受下限 0 截断），
/// 用于反馈展示，避免在属性已为 0 时虚报"-N"。
SettlementOutcome settleDailyTasks({
  required Attributes current,
  required List<AttributeDelta> penalties,
}) {
  final total = penalties.fold<AttributeDelta>(
      AttributeDelta.zero, (sum, p) => sum + p);
  final after = current.applyPenalty(total);
  return SettlementOutcome(
    after: after,
    totalPenalty: AttributeDelta(
      health: current.health - after.health,
      discipline: current.discipline - after.discipline,
      charm: current.charm - after.charm,
    ),
  );
}
