import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/habit_detail_page.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:babydaily/src/ui/motion.dart';
import 'package:babydaily/src/ui/settings_page.dart';
import 'package:babydaily/src/ui/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试：元素 → 二级页走容器变换，不是普通页面路由。
///
/// 锁四件事：
/// 1. 点卡片/图标/FAB 推的是容器路由，而不是 MaterialPageRoute，时长是房规值
///    （展开 300ms、收起 220ms）；
/// 2. 转场真的在动：中途路由动画值介于 0 与 1 之间、二级页还没归位到原点
///    （也就是「还在从源元素的位置长出来」），而不是瞬切；
/// 3. 转场结束后二级页铺满整屏；
/// 4. 返回同理（反向也在动画），并且回到原来的列表。
///
/// 注意：转场结束后**不能**去 find 源卡片——二级页是不透明路由，Flutter 会把
/// 被完全盖住的源路由从 Overlay 里摘掉（`OverlayEntry.opaque`），源元素本来就
/// 不在树里；容器的隐藏机制（`_Hideable`）只在转场那几帧有意义。
void main() {
  final pushedRoutes = <Route<dynamic>>[];

  Future<AppController> makeApp({String habitName = '早睡打卡'}) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final controller = AppController(db);
    await controller.service.createCharacter(
      name: '小明',
      age: 18,
      gender: Gender.male,
    );
    await controller.service.createHabit(
      name: habitName,
      frequencyType: HabitFrequency.daily,
      description: '22:30 前睡',
    );
    await controller.init();
    return controller;
  }

  Future<void> pumpApp(WidgetTester tester, AppController controller) async {
    await tester.pumpWidget(
      RootGate(
        controller: controller,
        navigatorObservers: [_RecordingObserver(pushedRoutes)],
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 最近推上来的那条路由（容器路由是 ModalRoute 的子类）。
  ModalRoute<dynamic>? lastRoute() {
    if (pushedRoutes.isEmpty) return null;
    final route = pushedRoutes.last;
    return route is ModalRoute<dynamic> ? route : null;
  }

  /// 断言最近推的是容器变换路由，而不是普通页面路由。
  void expectContainerRoute({Duration? duration}) {
    final route = lastRoute();
    expect(route, isNotNull, reason: '点元素应该推一条路由上来');
    expect(
      route!.runtimeType.toString(),
      contains('ContainerRoute'),
      reason: '元素点击必须走容器变换，不能退回 MaterialPageRoute',
    );
    if (duration != null) expect(route.transitionDuration, duration);
  }

  /// 转场中途的断言：路由动画在 0..1 之间，且二级页还没铺满整屏
  /// （左上角不在原点 = 它还贴在容器左上角，正从源元素的位置长大）。
  void expectMidTransition(WidgetTester tester, Finder page) {
    final route = lastRoute();
    expect(route?.animation, isNotNull, reason: '容器路由必须带转场动画');
    final value = route!.animation!.value;
    expect(value, greaterThan(0), reason: '转场应该已经开始');
    expect(value, lessThan(1), reason: '这一刻转场还没结束（不是瞬切）');
    expect(
      tester.getTopLeft(page),
      isNot(Offset.zero),
      reason: '二级页应当还在容器里长出来，而不是已经铺满整屏',
    );
  }

  setUp(pushedRoutes.clear);

  testWidgets('习惯卡片 → 详情页：从卡片位置放大，中途真的在动画，返回缩回列表', (tester) async {
    final controller = await makeApp();
    await pumpApp(tester, controller);

    await tester.tap(find.text('习惯'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitDetailPage), findsNothing);
    expect(pushedRoutes, isEmpty); // 切标签不是页面跳转

    await tester.tap(find.text('早睡打卡'));
    await tester.pump(); // 起帧：路由入栈 + 第一个转场帧
    await tester.pump(const Duration(milliseconds: 100)); // 300ms 转场的 1/3

    expectContainerRoute(duration: kContainerTransformDuration);
    expect(find.byType(HabitDetailPage), findsOneWidget);
    expectMidTransition(tester, find.byType(HabitDetailPage));

    // 转场没结束前一直处于中间态
    await tester.pump(const Duration(milliseconds: 100));
    expect(lastRoute()!.animation!.value, lessThan(1));

    await tester.pumpAndSettle();
    expect(find.byType(HabitDetailPage), findsOneWidget);
    expect(tester.getTopLeft(find.byType(HabitDetailPage)), Offset.zero);
    expect(find.text('早睡打卡'), findsWidgets); // 详情页标题

    // 返回：反向也在动画，最后回到习惯列表
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expectMidTransition(tester, find.byType(HabitDetailPage));
    expect(lastRoute()!.reverseTransitionDuration, kContainerTransformReverseDuration);
    await tester.pumpAndSettle();
    expect(find.byType(HabitDetailPage), findsNothing);
    expect(find.text('早睡打卡'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('设置图标 → 设置页：同样走容器变换', (tester) async {
    final controller = await makeApp();
    await pumpApp(tester, controller);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expectContainerRoute(duration: kContainerTransformDuration);
    expect(find.byType(SettingsPage), findsOneWidget);
    expectMidTransition(tester, find.byType(SettingsPage));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(SettingsPage)), Offset.zero);
    expect(find.text('设置'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expectMidTransition(tester, find.byType(SettingsPage));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('系统「减少动效」：容器变换时长压到 0，直接切页', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final controller = await makeApp();
    await pumpApp(tester, controller);
    await tester.tap(find.text('习惯'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('早睡打卡'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(lastRoute()?.transitionDuration, Duration.zero);
    expect(lastRoute()?.reverseTransitionDuration, Duration.zero);
    expect(find.byType(HabitDetailPage), findsOneWidget);
    expect(tester.getTopLeft(find.byType(HabitDetailPage)), Offset.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('全局 pageTransitionsTheme 在各平台都装上了容器变换转场', (tester) async {
    final theme = buildTheme(Scene.home);
    for (final platform in TargetPlatform.values) {
      expect(
        theme.pageTransitionsTheme.builders[platform],
        isA<ClayPageTransitionsBuilder>(),
        reason: '$platform 没有配 ClayPageTransitionsBuilder',
      );
    }
    // 主题本身能在 App 里正常构建
    final controller = await makeApp();
    await pumpApp(tester, controller);
    expect(tester.takeException(), isNull);
  });
}

/// 记录推上来的路由（Route 不是 widget，find 拿不到）。
class _RecordingObserver extends NavigatorObserver {
  _RecordingObserver(this.pushed);

  final List<Route<dynamic>> pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // 首屏也走 didPush，这里只要二级页，所以跳过 first。
    if (!route.isFirst) pushed.add(route);
  }
}
