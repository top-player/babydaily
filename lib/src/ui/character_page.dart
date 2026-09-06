/// 主角页：角色面板（等级/称号/属性条）、场景切换、资料编辑。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/xp_economy.dart';
import 'package:babydaily/src/ui/app_controller.dart';
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 问候
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${atmosphere.emoji} ${atmosphere.greeting}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(atmosphere.tip,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '设置',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage()),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (c != null) _profileCard(context, controller, c),
        const SizedBox(height: 12),
        _sceneCard(context, controller),
      ],
    );
  }

  Widget _profileCard(
      BuildContext context, AppController controller, CharacterSnapshot c) {
    final level = levelForXp(c.xp);
    final into = xpIntoLevel(c.xp);
    final needed = xpNeededForNext(c.xp);
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_genderEmoji(c.gender),
                    style: const TextStyle(fontSize: 44)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                              '${_genderLabel(c.gender)} · ${c.age} 岁',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lv.$level ${titleForLevel(level)}',
                        style: Theme.of(context).textTheme.titleSmall,
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
            const SizedBox(height: 16),
            if (level < maxLevel) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: needed == 0 ? 1 : into / (into + needed),
                  minHeight: 10,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 4),
              Text('经验 $into / ${into + needed}（累计 ${c.xp}）',
                  style: Theme.of(context).textTheme.bodySmall),
            ] else
              Text('👑 满级！累计经验 ${c.xp}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _attributeBar(context, '健康值', '💪', c.health),
            const SizedBox(height: 8),
            _attributeBar(context, '自律值', '🎯', c.discipline),
            const SizedBox(height: 8),
            _attributeBar(context, '魅力值', '✨', c.charm),
          ],
        ),
      ),
    );
  }

  Widget _attributeBar(
      BuildContext context, String label, String emoji, int value) {
    return Row(
      children: [
        Text('$emoji $label',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 10,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 76,
          child: Text('$value · ${tierLabel(label, value)}',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  Widget _sceneCard(BuildContext context, AppController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('场景', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final atmosphere in sceneAtmospheres.values) ...[
                  _sceneChip(context, controller, atmosphere),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sceneChip(BuildContext context, AppController controller,
      SceneAtmosphere atmosphere) {
    final selected = controller.scene == atmosphere.scene;
    return ChoiceChip(
      avatar: Text(atmosphere.emoji),
      label: Text(atmosphere.label),
      selected: selected,
      onSelected: (_) => controller.setScene(atmosphere.scene),
    );
  }

  Future<void> _editProfile(BuildContext context, AppController controller,
      CharacterSnapshot c) async {
    final nameController = TextEditingController(text: c.name);
    var age = c.age;
    var gender = c.gender;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑主角资料'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                maxLength: 12,
                decoration: const InputDecoration(labelText: '姓名'),
              ),
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
                    name: name, age: age, gender: gender);
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
