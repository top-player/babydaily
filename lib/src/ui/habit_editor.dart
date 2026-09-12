/// 习惯编辑器页：新建 / 编辑习惯（从 FAB 或卡片 ⋮ 菜单容器变换进来）。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/editor_page.dart';

/// 新建/编辑习惯的整页表单。
///
/// 保存成功 `pop(true)`；名称为空则不落库并直接关闭（与原来的对话框一致）。
class HabitEditorPage extends StatefulWidget {
  const HabitEditorPage({super.key, this.habit});

  /// 为空表示新建。
  final Habit? habit;

  @override
  State<HabitEditorPage> createState() => _HabitEditorPageState();
}

class _HabitEditorPageState extends State<HabitEditorPage> {
  late final TextEditingController _name = TextEditingController(
    text: widget.habit?.name ?? '',
  );
  late final TextEditingController _desc = TextEditingController(
    text: widget.habit?.description ?? '',
  );
  late final TextEditingController _health = TextEditingController(
    text: _initial(widget.habit?.rewardHealth, 0),
  );
  late final TextEditingController _discipline = TextEditingController(
    text: _initial(widget.habit?.rewardDiscipline, 1),
  );
  late final TextEditingController _charm = TextEditingController(
    text: _initial(widget.habit?.rewardCharm, 0),
  );
  late HabitFrequency _frequency =
      widget.habit?.frequencyType ?? HabitFrequency.daily;
  late int _timesPerWeek = widget.habit?.timesPerWeek ?? 3;

  /// 旧的对话框取值规则：已有值大于 0 就用它，否则用默认（新建自律默认 1）。
  static String _initial(int? value, int fallback) =>
      value != null && value > 0 ? '$value' : '$fallback';

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _health.dispose();
    _discipline.dispose();
    _charm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final navigator = Navigator.of(context);
    if (name.isEmpty) {
      navigator.pop();
      return;
    }
    final controller = AppScope.read(context);
    final reward = AttributeDelta(
      health: parseAttribute(_health.text),
      discipline: parseAttribute(_discipline.text),
      charm: parseAttribute(_charm.text),
    );
    final timesPerWeek = _frequency == HabitFrequency.weekly
        ? _timesPerWeek
        : 1;
    final habit = widget.habit;
    if (habit == null) {
      await controller.service.createHabit(
        name: name,
        description: _desc.text.trim(),
        frequencyType: _frequency,
        timesPerWeek: timesPerWeek,
        reward: reward,
      );
    } else {
      await controller.service.updateHabit(
        id: habit.id,
        name: name,
        description: _desc.text.trim(),
        frequencyType: _frequency,
        timesPerWeek: timesPerWeek,
        reward: reward,
        now: DateTime.now(),
      );
    }
    if (mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.habit != null;
    return EditorPage(
      title: editing ? '编辑习惯' : '添加习惯',
      subtitle: '打卡奖励的属性每天结算一次，经验固定 +5。',
      onSave: _save,
      children: [
        TextField(
          controller: _name,
          maxLength: 30,
          autofocus: !editing,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        TextField(
          controller: _desc,
          maxLength: 100,
          decoration: const InputDecoration(labelText: '描述（可选）'),
        ),
        const SizedBox(height: 8),
        SegmentedButton<HabitFrequency>(
          segments: const [
            ButtonSegment(value: HabitFrequency.daily, label: Text('每日')),
            ButtonSegment(value: HabitFrequency.weekly, label: Text('每周 N 次')),
          ],
          selected: {_frequency},
          onSelectionChanged: (s) => setState(() => _frequency = s.first),
        ),
        if (_frequency == HabitFrequency.weekly) ...[
          const SizedBox(height: 12),
          WeeklyTimesRow(
            times: _timesPerWeek,
            onChanged: (value) => setState(() => _timesPerWeek = value),
          ),
        ],
        const SizedBox(height: 16),
        Text('打卡奖励（属性）', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: RewardField(label: '健康', controller: _health)),
            const SizedBox(width: 8),
            Expanded(
              child: RewardField(label: '自律', controller: _discipline),
            ),
            const SizedBox(width: 8),
            Expanded(child: RewardField(label: '魅力', controller: _charm)),
          ],
        ),
        if (editing)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '修改频率或每周次数会重新计算连续天数（累计保留）。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
