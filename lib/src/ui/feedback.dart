/// 成长反馈层：发放后的属性/经验浮层与升级全屏动效。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/milestone.dart';
import 'package:babydaily/src/domain/xp_economy.dart';

/// 展示一次成长反馈：+N 属性/经验浮层；升级时全屏动效 + 称号。
void showGrowthFeedback(BuildContext context, GrowthOutcome outcome) {
  if (outcome.xpGained <= 0 && outcome.attrGain.isZero) return;

  _showGainOverlay(context, outcome);

  if (outcome.leveledUp) {
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
void showMilestoneFeedback(BuildContext context, List<MilestoneReached> milestones) {
  if (milestones.isEmpty) return;
  final text = milestones.map((m) => '连续 ${m.days} 天里程碑 +${m.xp} 经验').join('、');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
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
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        content: Text('🎉 $message', textAlign: TextAlign.center),
        duration: const Duration(seconds: 3),
      ),
    );
}

void _showGainOverlay(BuildContext context, GrowthOutcome outcome) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _GainPanel(outcome: outcome),
  );
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
    duration: const Duration(milliseconds: 400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.outcome;
    final parts = <String>[
      if (o.xpGained > 0) '经验 +${o.xpGained}',
      if (o.attrGain.health > 0) '健康 +${o.attrGain.health}',
      if (o.attrGain.discipline > 0) '自律 +${o.attrGain.discipline}',
      if (o.attrGain.charm > 0) '魅力 +${o.attrGain.charm}',
    ];
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.4),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _controller, curve: Curves.easeOutBack)),
              child: Material(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(24),
                elevation: 6,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    '${parts.join(' · ')} ✨',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
      backgroundColor: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌟', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              '升级！Lv.${outcome.levelAfter}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              outcome.newTitle ?? titleForLevel(outcome.levelAfter),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
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
