/// 新手引导（可跳过）：创建主角 → 第一条主线（可拆子项）→ 第一个每日任务 → 第一个习惯。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;

  final _nameController = TextEditingController();
  int _age = 18;
  Gender _gender = Gender.secret;

  final _mainlineController = TextEditingController();
  final _subtasksController = TextEditingController();
  final _mainlineDisciplineController = TextEditingController(text: '1');

  final _dailyController = TextEditingController();
  final _dailyDisciplineController = TextEditingController(text: '1');

  final _habitController = TextEditingController();
  HabitFrequency _habitFrequency = HabitFrequency.daily;
  int _timesPerWeek = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _mainlineController.dispose();
    _subtasksController.dispose();
    _mainlineDisciplineController.dispose();
    _dailyController.dispose();
    _dailyDisciplineController.dispose();
    _habitController.dispose();
    super.dispose();
  }

  int _parseInt(String s, int fallback) => int.tryParse(s.trim()) ?? fallback;

  Future<void> _createCharacter({String? name}) async {
    final controller = AppScope.of(context);
    await controller.createCharacter(
      name:
          name ??
          (_nameController.text.trim().isEmpty
              ? '主角'
              : _nameController.text.trim()),
      age: _age,
      gender: _gender,
    );
  }

  Future<void> _finishStep1() async {
    if (_nameController.text.trim().isEmpty) {
      await _createCharacter(name: '主角');
    } else {
      await _createCharacter();
    }
    if (mounted) setState(() => _step = 1);
  }

  Future<void> _skipStep1() async {
    await _createCharacter(name: '主角');
    if (mounted) setState(() => _step = 1);
  }

  Future<void> _finishStep2() async {
    final controller = AppScope.of(context);
    final name = _mainlineController.text.trim();
    if (name.isNotEmpty) {
      final discipline = _parseInt(
        _mainlineDisciplineController.text,
        1,
      ).clamp(0, 100);
      final taskId = await controller.service.createTask(
        name: name,
        type: TaskType.mainline,
        reward: AttributeDelta(health: 0, discipline: discipline, charm: 0),
      );
      final lines = _subtasksController.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty);
      for (final line in lines) {
        await controller.service.createSubtask(taskId: taskId, name: line);
      }
    }
    if (mounted) setState(() => _step = 2);
  }

  Future<void> _finishStep3() async {
    final controller = AppScope.of(context);
    final name = _dailyController.text.trim();
    if (name.isNotEmpty) {
      final discipline = _parseInt(
        _dailyDisciplineController.text,
        1,
      ).clamp(0, 100);
      await controller.service.createTask(
        name: name,
        type: TaskType.daily,
        reward: AttributeDelta(health: 0, discipline: discipline, charm: 0),
      );
    }
    if (mounted) setState(() => _step = 3);
  }

  Future<void> _finishStep4() async {
    final controller = AppScope.of(context);
    final name = _habitController.text.trim();
    if (name.isNotEmpty) {
      await controller.service.createHabit(
        name: name,
        frequencyType: _habitFrequency,
        timesPerWeek: _habitFrequency == HabitFrequency.weekly
            ? _timesPerWeek.clamp(1, 7)
            : 1,
      );
    }
    if (mounted) setState(() => _step = 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                    ),
                    child: const Text('🐣', style: TextStyle(fontSize: 24)),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _step ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _step
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Expanded(child: _buildStep(context)),
              Row(
                children: [
                  if (_step < 4)
                    TextButton(
                      onPressed: () {
                        final next = _onSkip();
                        if (next != null) next();
                      },
                      child: const Text('跳过'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      final next = _onNext();
                      if (next != null) next();
                    },
                    child: Text(_step < 3 ? '下一步' : '开始成长 🎉'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback? _onNext() => switch (_step) {
    0 => _finishStep1,
    1 => _finishStep2,
    2 => _finishStep3,
    3 => _finishStep4,
    _ => null,
  };

  VoidCallback? _onSkip() => switch (_step) {
    0 => _skipStep1,
    1 => () => setState(() => _step = 2),
    2 => () => setState(() => _step = 3),
    3 => () => setState(() => _step = 4),
    _ => null,
  };

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _stepTitle(
          context,
          '先认识一下主角',
          '资料以后随时可改',
          children: [
            TextField(
              controller: _nameController,
              maxLength: 12,
              inputFormatters: [LengthLimitingTextInputFormatter(12)],
              decoration: const InputDecoration(
                labelText: '姓名',
                hintText: '给自己起个名字吧',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('年龄', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () =>
                      setState(() => _age = (_age - 1).clamp(1, 120)),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_age', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  onPressed: () =>
                      setState(() => _age = (_age + 1).clamp(1, 120)),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<Gender>(
              segments: const [
                ButtonSegment(value: Gender.male, label: Text('男')),
                ButtonSegment(value: Gender.female, label: Text('女')),
                ButtonSegment(value: Gender.secret, label: Text('保密')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
          ],
        );
      case 1:
        return _stepTitle(
          context,
          '立一个小目标（主线）',
          '重要的事，拆成小步子慢慢来',
          children: [
            TextField(
              controller: _mainlineController,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: '主线任务',
                hintText: '比如：读完一本书',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtasksController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '拆分子项（可选）',
                hintText: '每行一个，比如：\n读第一章\n读第二章',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mainlineDisciplineController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '完成奖励 · 自律值',
                helperText: '最后一个子项完成时自动发放；经验固定 +50',
              ),
            ),
          ],
        );
      case 2:
        return _stepTitle(
          context,
          '定一个每日任务',
          '每天 0 点重置；未完成会扣除对应属性哦',
          children: [
            TextField(
              controller: _dailyController,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: '每日任务',
                hintText: '比如：早起喝水',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dailyDisciplineController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '完成奖励 · 自律值',
                helperText: '提示：完成后 +N 自律；未完成 0 点扣 N 自律',
              ),
            ),
          ],
        );
      case 3:
        return _stepTitle(
          context,
          '养一个好习惯',
          '每天打卡，看着连续天数长大',
          children: [
            TextField(
              controller: _habitController,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: '习惯',
                hintText: '比如：早睡打卡',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<HabitFrequency>(
              segments: const [
                ButtonSegment(value: HabitFrequency.daily, label: Text('每日')),
                ButtonSegment(
                  value: HabitFrequency.weekly,
                  label: Text('每周 N 次'),
                ),
              ],
              selected: {_habitFrequency},
              onSelectionChanged: (s) =>
                  setState(() => _habitFrequency = s.first),
            ),
            if (_habitFrequency == HabitFrequency.weekly) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('每周次数', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => setState(
                      () => _timesPerWeek = (_timesPerWeek - 1).clamp(1, 7),
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_timesPerWeek 次',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => _timesPerWeek = (_timesPerWeek + 1).clamp(1, 7),
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '打卡默认 +1 自律、+5 经验；连续 10/20/30 天还有一次性里程碑奖励。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepTitle(
    BuildContext context,
    String title,
    String subtitle, {
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
