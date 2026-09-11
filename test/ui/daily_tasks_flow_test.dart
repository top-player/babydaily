import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 每日任务页：今天可完成/可判失败，历史按日期铺开。
void main() {
  testWidgets('每日任务页：今天判失败立即扣属性，历史同时留痕', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    // 昨天完成过的任务 → 历史里应有一条"完成"
    final doneYesterday = await controller.service.createTask(
      name: '早起喝水',
      type: TaskType.daily,
    );
    await controller.service.completeTask(
      doneYesterday,
      now: DateTime.now().subtract(const Duration(days: 1)),
    );
    // 今天要判失败的任务（奖励健康 2 → 立即扣 2）
    final toFail = await controller.service.createTask(
      name: '散步 10 分钟',
      type: TaskType.daily,
      reward: const AttributeDelta(health: 2, discipline: 0, charm: 0),
    );
    await controller.init();

    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();

    // 任务页 → 每日任务入口
    await tester.tap(find.text('任务'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('每日任务'));
    await tester.pumpAndSettle();

    // 今天 + 历史（昨天那一条）
    expect(find.textContaining('今天 ·'), findsOneWidget);
    expect(find.text('历史'), findsOneWidget);
    expect(
      find.textContaining(
        '昨天 · ${_dayLabel(DateTime.now().subtract(const Duration(days: 1)))}',
      ),
      findsOneWidget,
    );
    expect(find.text('1 完成'), findsOneWidget);

    // 判「散步 10 分钟」失败（第二张卡片的按钮）
    await tester.tap(find.text('标记失败').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '标记失败'));
    await tester.pumpAndSettle();

    expect((await controller.service.character())!.health, 48); // 50 - 2
    expect(find.textContaining('今日已记为失败，扣除 健康 -2'), findsOneWidget);

    // 今天的历史记为失败；任务本身没被删除
    final logs = await controller.service.dailyLogsOn(DateTime.now());
    expect(logs, hasLength(1));
    expect(logs.single.status, DailyTaskStatus.failed);
    expect(logs.single.taskId, toFail);
    expect(await controller.service.dailyTasks(), hasLength(2));

    await _flushTimers(tester);
    expect(tester.takeException(), isNull);
    await db.close();
  });

  testWidgets('每日任务页：完成任务后显示已完成并落完成记录', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    await controller.service.createTask(
      name: '早起喝水',
      type: TaskType.daily,
      reward: const AttributeDelta(health: 0, discipline: 1, charm: 0),
    );
    await controller.init();

    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('任务'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('每日任务'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    expect(find.text('今日已完成，明天继续'), findsOneWidget);
    expect((await controller.service.character())!.discipline, 51);
    final logs = await controller.service.dailyLogsOn(DateTime.now());
    expect(logs.single.status, DailyTaskStatus.completed);

    await _flushTimers(tester);
    expect(tester.takeException(), isNull);
    await db.close();
  });

  testWidgets('任务页：主线可以手动判失败，失败后进「已失败」且不删除', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    await controller.service.createTask(
      name: '读完一本书',
      type: TaskType.mainline,
      reward: const AttributeDelta(health: 0, discipline: 2, charm: 0),
    );
    await controller.init();

    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('任务'));
    await tester.pumpAndSettle();

    // 卡片菜单 → 标记失败
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('标记失败').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '标记失败'));
    await tester.pumpAndSettle();

    expect(find.text('已失败'), findsOneWidget);
    expect(find.text('读完一本书'), findsOneWidget); // 任务保留
    expect(await controller.service.tasksByType(TaskType.mainline), isEmpty);
    expect(
      await controller.service.tasksByType(TaskType.mainline, failed: true),
      hasLength(1),
    );
    expect((await controller.service.character())!.discipline, 50); // 不扣属性

    await _flushTimers(tester);
    expect(tester.takeException(), isNull);
    await db.close();
  });
}

/// 冲掉 SnackBar（3 秒）与成长浮层（1.6 秒）的定时器，
/// 否则测试结束时会报 "A Timer is still pending"。
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

/// '2026年6月5日 周五'
String _dayLabel(DateTime day) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${day.year}年${day.month}月${day.day}日 周${weekdays[day.weekday - 1]}';
}
