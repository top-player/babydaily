/// 界面主题：三场景（家里/公司/游玩）各自的氛围配色与文案（纯氛围层）。
///
/// 视觉语言：黏土拟物（Claymorphism）——奶油底色、白/暖卡片、大圆角、
/// 柔和双阴影、厚边框感。参考 design-system/default/MASTER.md。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/motion.dart';

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
    seed: Color(0xFFD97706),
    greeting: '回到小窝，先歇口气 ☕',
    tip: '家是充电站：整理、早睡、喝水都算数。',
  ),
  Scene.company: SceneAtmosphere(
    scene: Scene.company,
    label: '公司',
    emoji: '💼',
    seed: Color(0xFF3E6F9E),
    greeting: '开工啦，今天也稳稳推进 💼',
    tip: '专注 25 分钟，胜过漫游两小时。',
  ),
  Scene.play: SceneAtmosphere(
    scene: Scene.play,
    label: '游玩',
    emoji: '🎮',
    seed: Color(0xFF0E9F6E),
    greeting: '尽情探索，玩得开心最重要 🎈',
    tip: '休息也是成长的一部分。',
  ),
};

SceneAtmosphere atmosphereOf(Scene scene) => sceneAtmospheres[scene]!;

/// 属性语义色（跨场景固定，便于一眼区分）。
const Color kHealthColor = Color(0xFF2E9E5B);
const Color kDisciplineColor = Color(0xFF4A7FBE);
const Color kCharmColor = Color(0xFFC25E9E);

/// 失败与惩罚的强调色（比纯红柔和，和黏土暖色调同族）。
const Color kFailColor = Color(0xFFC0503F);

/// 由场景驱动的黏土风主题：奶油底 + 大圆角 + 柔和阴影。
///
/// 页面转场统一走 [buildClayPageTransitionsTheme]（容器变换观感的放大淡入）；
/// 有源元素的卡片点击另由 `openContainerTransform` 承担，见 motion.dart。
ThemeData buildTheme(Scene scene, {Brightness brightness = Brightness.light}) {
  final atmosphere = atmosphereOf(scene);
  final isDark = brightness == Brightness.dark;

  final seed = atmosphere.seed;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
      .copyWith(
        surface: isDark ? const Color(0xFF2C251D) : Colors.white,
        onSurface: isDark ? const Color(0xFFF6EDE2) : const Color(0xFF2A2117),
        onSurfaceVariant: isDark
            ? const Color(0xFFC4B6A6)
            : const Color(0xFF6E5F50),
        outlineVariant: isDark
            ? const Color(0xFF443A2E)
            : const Color(0xFFF1E4D0),
      );

  final background = isDark ? const Color(0xFF221C15) : const Color(0xFFFFF8EC);
  final card = scheme.surface;
  final border = isDark ? const Color(0xFF443A2E) : const Color(0xFFF1E4D0);
  final muted = scheme.onSurfaceVariant;
  final fieldFill = isDark ? const Color(0xFF352D24) : const Color(0xFFFBF3E5);
  final track = isDark ? const Color(0xFF3B332A) : const Color(0xFFF3E8D6);
  final shadowColor = isDark
      ? const Color(0xAA000000)
      : const Color(0x1F8A6A3B); // 暖褐柔影

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    // 全局页面转场：所有平台统一为容器变换观感的放大淡入
    // （卡片这类有源元素的转场由 OpenContainer 承担，见 motion.dart）。
    pageTransitionsTheme: buildClayPageTransitionsTheme(),
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: scheme.onSurface,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: scheme.onSurface,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.45,
        color: scheme.onSurface,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
        color: scheme.onSurface,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.4,
        color: muted,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 2,
      shadowColor: shadowColor,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: border, width: 1.2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: const StadiumBorder()),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: muted.withValues(alpha: 0.7)),
      labelStyle: TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: border, width: 1.2),
      backgroundColor: fieldFill,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: scheme.onInverseSurface,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurface,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      headerBackgroundColor: scheme.primaryContainer,
      headerForegroundColor: scheme.onPrimaryContainer,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      elevation: 3,
      shadowColor: shadowColor,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              )
            : TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected) ? scheme.primary : muted,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 3,
      focusElevation: 3,
      hoverElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      extendedIconLabelSpacing: 8,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: track,
      linearMinHeight: 10,
      circularTrackColor: track,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: muted.withValues(alpha: 0.6), width: 1.6),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(scheme.onPrimary),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide.none
              : BorderSide(color: border, width: 1.2),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
