/// 主角属性：健康值、自律值、魅力值（0–100，不随时间衰减）。
library;

/// 属性当前值（0–100）。
class Attributes {
  const Attributes({
    required this.health,
    required this.discipline,
    required this.charm,
  });

  /// 新角色的初始属性（中位数，留出双向空间）。
  static const Attributes starting = Attributes(
    health: 50,
    discipline: 50,
    charm: 50,
  );

  final int health;
  final int discipline;
  final int charm;

  /// 发放奖励：各项封顶 100。
  Attributes applyGain(AttributeDelta gain) => Attributes(
        health: (health + gain.health).clamp(0, 100),
        discipline: (discipline + gain.discipline).clamp(0, 100),
        charm: (charm + gain.charm).clamp(0, 100),
      );

  /// 每日结算扣除：各项下限 0。
  Attributes applyPenalty(AttributeDelta penalty) => Attributes(
        health: (health - penalty.health).clamp(0, 100),
        discipline: (discipline - penalty.discipline).clamp(0, 100),
        charm: (charm - penalty.charm).clamp(0, 100),
      );

  @override
  bool operator ==(Object other) =>
      other is Attributes &&
      other.health == health &&
      other.discipline == discipline &&
      other.charm == charm;

  @override
  int get hashCode => Object.hash(health, discipline, charm);

  @override
  String toString() =>
      'Attributes(health: $health, discipline: $discipline, charm: $charm)';
}

/// 属性增减量（正值表示发放/扣除的数值，可为 0）。
class AttributeDelta {
  const AttributeDelta({
    required this.health,
    required this.discipline,
    required this.charm,
  });

  static const AttributeDelta zero =
      AttributeDelta(health: 0, discipline: 0, charm: 0);

  final int health;
  final int discipline;
  final int charm;

  bool get isZero => health == 0 && discipline == 0 && charm == 0;

  AttributeDelta operator +(AttributeDelta other) => AttributeDelta(
        health: health + other.health,
        discipline: discipline + other.discipline,
        charm: charm + other.charm,
      );

  @override
  bool operator ==(Object other) =>
      other is AttributeDelta &&
      other.health == health &&
      other.discipline == discipline &&
      other.charm == charm;

  @override
  int get hashCode => Object.hash(health, discipline, charm);

  @override
  String toString() =>
      'AttributeDelta(health: $health, discipline: $discipline, charm: $charm)';
}
