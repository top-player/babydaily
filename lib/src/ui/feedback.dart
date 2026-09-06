/// 成长反馈层：发放后的属性/经验浮层与升级全屏动效。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/milestone.dart';
import 'package:babydaily/src/domain/xp_economy.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/theme.dart';

/// 展示一次成长反馈：+N 属性/经验浮层；升级时全屏动效 + 称号。
void showGrowthFeedback(BuildContext context, GrowthOutcome outcome) {
  if (outcome.xpGained <= 0 && outcome.attrGain.isZero) return;

  _showGainOverlay(context, outcome);

  if (outcome.leveledUp) {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (context.mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => _LevelUpDialog(outcome: outcome),
        );
      }
    });
  }
}

/// 展示习惯连续里程碑横幅。
void showMilestoneFeedback(
  BuildContext context,
  List<MilestoneReached> milestones,
) {
  if (milestones.isEmpty) return;
  final text = milestones.map((m) => '连续 ${m.days} 天里程碑 +${m.xp} 经验').join('、');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        content: Text('🏅 $text，太棒了！', textAlign: TextAlign.center),
        duration: const Duration(seconds: 3),
      ),
    );
}

/// 每日任务全清 / 连续打卡 7·30·100 天的庆祝横幅。
void showCelebration(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        content: Text('🎉 $message', textAlign: TextAlign.center),
        duration: const Duration(seconds: 3),
      ),
    );
}

void _showGainOverlay(BuildContext context, GrowthOutcome outcome) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (context) => _GainPanel(outcome: outcome));
  overlay.insert(entry);
  Timer(const Duration(milliseconds: 1600), () {
    if (entry.mounted) entry.remove();
  });
}

class _GainPanel extends StatefulWidget {
  const _GainPanel({required this.outcome});

  final GrowthOutcome outcome;

  @override
  State<_GainPanel> createState() => _GainPanelState();
}

class _GainPanelState extends State<_GainPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.outcome;
    final scheme = Theme.of(context).colorScheme;
    final parts = <(IconData, Color, String)>[
      if (o.xpGained > 0)
        (Icons.bolt, const Color(0xFFD97706), '经验 +${o.xpGained}'),
      if (o.attrGain.health > 0)
        (Icons.favorite, kHealthColor, '健康 +${o.attrGain.health}'),
      if (o.attrGain.discipline > 0)
        (Icons.bolt, kDisciplineColor, '自律 +${o.attrGain.discipline}'),
      if (o.attrGain.charm > 0)
        (Icons.auto_awesome, kCharmColor, '魅力 +${o.attrGain.charm}'),
    ];
    return Positioned(
      top: MediaQuery.of(context).padding.top + 84,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
              ),
              child: Material(
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: scheme.outlineVariant, width: 1.2),
                ),
                elevation: 4,
                shadowColor: const Color(0x338A6A3B),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (icon, color, text) in parts)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 17, color: color),
                            const SizedBox(width: 4),
                            Text(
                              text,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      const Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color: kCharmColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelUpDialog extends StatelessWidget {
  const _LevelUpDialog({required this.outcome});

  final GrowthOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primaryContainer, scheme.secondaryContainer],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface.withValues(alpha: 0.65),
                border: Border.all(
                  color: scheme.surface.withValues(alpha: 0.9),
                  width: 2,
                ),
              ),
              child: Icon(Icons.stars, size: 48, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              '升级！Lv.${outcome.levelAfter}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            TagPill(
              icon: Icons.workspace_premium,
              text: outcome.newTitle ?? titleForLevel(outcome.levelAfter),
              color: scheme.primary,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('继续成长'),
            ),
          ],
        ),
      ),
    );
  }
}
