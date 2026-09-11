import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 任务页：卡片与归档分区都能折叠；每日任务入口卡展示今天的前几个任务。
void main() {
  Future<void> openTasksPage(
    WidgetTester tester,
    AppController controller,
  ) async {
    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('任务'));
    await tester.pumpAndSettle();
  }

  testWidgets('主线/支线卡片可以分别折叠，已完成/已失败分区可以折叠', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    // 先走一次启动结算（真实顺序：打开应用结算在前，用户操作在后）
    await controller.init();

    final main1 = await controller.service.createTask(
      name: '主线一',
      type: TaskType.mainline,
    );
    await controller.service.createSubtask(taskId: main1, name: '第一章');
    await controller.service.createTask(name: '主线二', type: TaskType.mainline);
    await controller.service.createTask(name: '支线一', type: TaskType.side);
    final archived = await controller.service.createTask(
      name: '归档支线',
      type: TaskType.side,
    );
    await controller.service.completeTask(archived, now: DateTime.now());
    final failed = await controller.service.createTask(
      name: '失败支线',
      type: TaskType.side,
    );
    await controller.service.failTask(failed, now: DateTime.now());

    await openTasksPage(tester, controller);

    // 默认全部展开：主线一有子项、主线二无子项
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('完成剩余 1 个子项后自动完成'), findsOneWidget);
    expect(find.text('完成主线'), findsOneWidget);

    // 折叠主线一：子项与提示收起，只留一行摘要
    await tester.tap(find.text('主线一'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('完成剩余 1 个子项后自动完成'), findsNothing);
    expect(find.text('子项 0/1 已完成'), findsOneWidget);

    // 主线二独立折叠
    await tester.tap(find.text('主线二'));
    await tester.pumpAndSettle();
    expect(find.text('完成主线'), findsNothing);

    // 支线一（可能在折叠之下）：先滚到可见再独立折叠
    await tester.scrollUntilVisible(find.text('支线一'), 120);
    await tester.pumpAndSettle();
    expect(find.text('完成'), findsOneWidget);
    await tester.tap(find.text('支线一'));
    await tester.pumpAndSettle();
    expect(find.text('完成'), findsNothing);

    // 已完成分区整体收起 / 展开
    await tester.scrollUntilVisible(find.text('已完成'), 120);
    await tester.pumpAndSettle();
    expect(find.text('归档支线'), findsOneWidget);
    await tester.tap(find.text('已完成'));
    await tester.pumpAndSettle();
    expect(find.text('归档支线'), findsNothing);
    await tester.tap(find.text('已完成'));
    await tester.pumpAndSettle();
    expect(find.text('归档支线'), findsOneWidget);

    // 已失败分区整体收起 / 展开
    await tester.scrollUntilVisible(find.text('已失败'), 120);
    await tester.pumpAndSettle();
    expect(find.text('失败支线'), findsOneWidget);
    await tester.tap(find.text('已失败'));
    await tester.pumpAndSettle();
    expect(find.text('失败支线'), findsNothing);
    await tester.tap(find.text('已失败'));
    await tester.pumpAndSettle();
    expect(find.text('失败支线'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await db.close();
  });

  testWidgets('每日任务入口卡：展示前三个任务与进度，点击进详情页且没有「历史」字样', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    await controller.init(); // 启动结算后再操作

    final done = await controller.service.createTask(
      name: '早起喝水',
      type: TaskType.daily,
      reward: const AttributeDelta(health: 0, discipline: 1, charm: 0),
    );
    await controller.service.completeTask(done, now: DateTime.now());
    for (final name in ['散步 10 分钟', '读书 20 页', '记账', '拉伸']) {
      await controller.service.createTask(name: name, type: TaskType.daily);
    }

    await openTasksPage(tester, controller);

    // 进度 + 前三个任务（第四个往后折叠成"还有 2 个"）
    expect(find.textContaining('今天 1/5 已完成'), findsOneWidget);
    expect(find.text('早起喝水'), findsOneWidget);
    expect(find.text('散步 10 分钟'), findsOneWidget);
    expect(find.text('读书 20 页'), findsOneWidget);
    expect(find.text('记账'), findsNothing);
    expect(find.text('还有 2 个每日任务…'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget); // 完成态标记
    expect(find.text('待完成'), findsNWidgets(2));

    // 卡片上不再写「历史」
    expect(find.text('历史'), findsNothing);

    // 点卡片进入每日任务页
    await tester.tap(find.text('每日任务'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '每日任务'), findsOneWidget);
    expect(find.textContaining('今天 ·'), findsOneWidget);
    expect(find.text('拉伸'), findsOneWidget); // 详情页里 5 个任务都在

    expect(tester.takeException(), isNull);
    await db.close();
  });
}
