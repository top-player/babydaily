/// 界面主题：三场景（家里/公司/游玩）各自的氛围配色与文案（纯氛围层）。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/domain/enums.dart';

/// 一个场景的氛围定义。
class SceneAtmosphere {
  const SceneAtmosphere({
    required this.scene,
    required this.label,
    required this.emoji,
    required this.seed,
    required this.greeting,
    required this.tip,
  });

  final Scene scene;
  final String label;
  final String emoji;
  final Color seed;
  final String greeting;
  final String tip;
}

/// 场景 → 氛围（家里=暖橙奶油，公司=冷静蓝，游玩=明亮绿）。
const Map<Scene, SceneAtmosphere> sceneAtmospheres = {
  Scene.home: SceneAtmosphere(
    scene: Scene.home,
    label: '家里',
    emoji: '🏠',
    seed: Color(0xFFE89B64),
    greeting: '回到小窝，先歇口气 ☕',
    tip: '家是充电站：整理、早睡、喝水都算数。',
  ),
  Scene.company: SceneAtmosphere(
    scene: Scene.company,
    label: '公司',
    emoji: '💼',
    seed: Color(0xFF5B8DB8),
    greeting: '开工啦，今天也稳稳推进 💼',
    tip: '专注 25 分钟，胜过漫游两小时。',
  ),
  Scene.play: SceneAtmosphere(
    scene: Scene.play,
    label: '游玩',
    emoji: '🎮',
    seed: Color(0xFF6BBF8A),
    greeting: '尽情探索，玩得开心最重要 🎈',
    tip: '休息也是成长的一部分。',
  ),
};

SceneAtmosphere atmosphereOf(Scene scene) => sceneAtmospheres[scene]!;

/// 由场景驱动的治愈系主题：柔和配色 + 大圆角。
ThemeData buildTheme(Scene scene) {
  final atmosphere = atmosphereOf(scene);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: atmosphere.seed),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
