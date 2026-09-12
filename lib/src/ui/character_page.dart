/// 主角页：角色面板（等级/称号/属性条）、场景切换、资料编辑。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/xp_economy.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/motion.dart';
import 'package:babydaily/src/ui/settings_page.dart';
import 'package:babydaily/src/ui/theme.dart';

String _genderEmoji(Gender g) => switch (g) {
  Gender.male => '👦',
  Gender.female => '👧',
  Gender.secret => '🐣',
};

String _genderLabel(Gender g) => switch (g) {
  Gender.male => '男',
  Gender.female => '女',
  Gender.secret => '保密',
};

/// 属性段位文案（0-39/40-59/60-79/80-100，轻松治愈措辞）。
String tierLabel(String attribute, int value) {
  final band = value < 40 ? 0 : (value < 60 ? 1 : (value < 80 ? 2 : 3));
  const copy = {
    '健康值': ['需要充电', '元气回升', '状态在线', '元气满满'],
    '自律值': ['散漫中', '渐入佳境', '自律在线', '自律大师'],
    '魅力值': ['默默无闻', '小有魅力', '闪闪发光', '魅力四射'],
  };
  return copy[attribute]![band];
}

class CharacterPage extends StatelessWidget {
  const CharacterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final c = controller.character;
    final atmosphere = atmosphereOf(controller.scene);
    final scheme = Theme.of(context).colorScheme;

    // 主角页是唯一没有 AppBar 的标签页，必须自己避开状态栏与前置摄像头挖孔
    // （MediaQuery.padding 已合并 DisplayCutout 安全区），否则顶部问候卡被遮挡。
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 问候英雄卡
          HeroCard(
            colors: [scheme.primaryContainer, scheme.secondaryContainer],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface.withValues(alpha: 0.55),
                    ),
                    child: Text(
                      atmosphere.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          atmosphere.greeting,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          atmosphere.tip,
                          style: TextStyle(
                            color: scheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _SettingsButton(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (c != null) _profileCard(context, controller, c),
          const SizedBox(height: 14),
          _sceneCard(context, controller),
        ],
      ),
    );
  }

  Widget _profileCard(
    BuildContext context,
    AppController controller,
    CharacterSnapshot c,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final level = levelForXp(c.xp);
    final into = xpIntoLevel(c.xp);
    final needed = xpNeededForNext(c.xp);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryContainer,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    _genderEmoji(c.gender),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_genderLabel(c.gender)} · ${c.age} 岁',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TagPill(
                        icon: Icons.stars,
                        text: 'Lv.$level ${titleForLevel(level)}',
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '编辑资料',
                  onPressed: () => _editProfile(context, controller, c),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (level < maxLevel) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: needed == 0 ? 1 : into / (into + needed),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '经验 $into / ${into + needed}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '累计 ${c.xp} EXP',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (controller.loginXpClaimedToday) ...[
                const SizedBox(height: 8),
                TagPill(
                  icon: Icons.wb_sunny_outlined,
                  text: '今日登录 +$dailyLoginXp 经验已到账',
                  color: scheme.primary,
                ),
              ],
            ] else
              TagPill(
                icon: Icons.emoji_events,
                text: '👑 满级！累计经验 ${c.xp}',
                color: scheme.primary,
              ),
            const SizedBox(height: 18),
            _attributeBar(
              context,
              '健康值',
              Icons.favorite,
              kHealthColor,
              c.health,
            ),
            const SizedBox(height: 12),
            _attributeBar(
              context,
              '自律值',
              Icons.bolt,
              kDisciplineColor,
              c.discipline,
            ),
            const SizedBox(height: 12),
            _attributeBar(
              context,
              '魅力值',
              Icons.auto_awesome,
              kCharmColor,
              c.charm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _attributeBar(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    int value,
  ) {
    return Row(
      children: [
        ClayAvatar(icon: icon, color: color, size: 36, iconSize: 19),
        const SizedBox(width: 10),
        SizedBox(
          width: 56,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TagPill(text: '$value · ${tierLabel(label, value)}', color: color),
      ],
    );
  }

  Widget _sceneCard(BuildContext context, AppController controller) {
    return _SceneCard(
      selected: controller.scene,
      onSelect: controller.setScene,
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    AppController controller,
    CharacterSnapshot c,
  ) async {
    final nameController = TextEditingController(text: c.name);
    var age = c.age;
    var gender = c.gender;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑主角资料'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  maxLength: 12,
                  decoration: const InputDecoration(labelText: '姓名'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('年龄', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () =>
                          setDialogState(() => age = (age - 1).clamp(1, 120)),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$age', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      onPressed: () =>
                          setDialogState(() => age = (age + 1).clamp(1, 120)),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<Gender>(
                  segments: const [
                    ButtonSegment(value: Gender.male, label: Text('男')),
                    ButtonSegment(value: Gender.female, label: Text('女')),
                    ButtonSegment(value: Gender.secret, label: Text('保密')),
                  ],
                  selected: {gender},
                  onSelectionChanged: (s) =>
                      setDialogState(() => gender = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                await controller.updateCharacterProfile(
                  name: name,
                  age: age,
                  gender: gender,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    // 注意：不在对话框关闭动画期间 dispose controller（见 notes_page 同款注释）。
  }
}

/// 场景切换卡：选中块在两个槽位之间平滑滑动，文字颜色/字重跟着过渡。
class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.selected, required this.onSelect});

  final Scene selected;
  final ValueChanged<Scene> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scenes = sceneAtmospheres.values.toList();
    final selectedIndex = scenes.indexWhere((a) => a.scene == selected);
    // 选中块的底色用**当前选中**场景的主色，切换时颜色也跟着淡变。
    final pillColor = atmosphereOf(selected).seed.withValues(alpha: 0.16);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('场景', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant, width: 1.2),
              ),
              child: Stack(
                children: [
                  // 选中块：按每个槽位 1/3 的宽度从左滑到右。
                  // 它只负责滑动，颜色由 slot 自己淡入淡出，两边不会打架。
                  Positioned.fill(
                    child: AnimatedAlign(
                      alignment: Alignment(
                        scenes.length > 1
                            ? -1 + 2 * selectedIndex / (scenes.length - 1)
                            : 0,
                        0,
                      ),
                      duration: kSceneSwitchDuration,
                      curve: Curves.easeOutCubic,
                      child: FractionallySizedBox(
                        widthFactor: 1 / scenes.length,
                        heightFactor: 1,
                        child: AnimatedContainer(
                          duration: kSceneSwitchDuration,
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: pillColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final atmosphere in scenes)
                        Expanded(
                          child: _sceneSegment(context, atmosphere),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sceneSegment(BuildContext context, SceneAtmosphere atmosphere) {
    final selected = this.selected == atmosphere.scene;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onSelect(atmosphere.scene),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          children: [
            Text(atmosphere.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: kSceneSwitchDuration,
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? atmosphere.seed
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: Text(atmosphere.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置入口：点击时由容器变换从图标位置放大到设置页。
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) => openContainerTransform(
    context: context,
    openBuilder: (context, close) => const SettingsPage(),
    closedBuilder: (context, open) => IconButton(
      tooltip: '设置',
      onPressed: open,
      icon: const Icon(Icons.settings_outlined),
    ),
  );
}
