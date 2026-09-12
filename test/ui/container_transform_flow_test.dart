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

/// 回归测试：元素 → 二级页走容器变换（OpenContainer），不是普通页面路由。
///
/// 锁四件事：
/// 1. 点卡片/图标推的是容器路由（`_OpenContainerRoute`），而不是 MaterialPageRoute，
///    时长是房规里的 400ms；
/// 2. 转场真的在动：中途页面在淡入（opacity 介于 0 与 1 之间）；
/// 3. 400ms 之内不会瞬切完（100ms、200ms 时都还在转场），之后才稳定；
/// 4. 返回同理（反向也在动画），并且回到原来的列表。
///
/// 注意：转场结束后**不能**去 find 源卡片——二级页是不透明路由，Flutter 会把
/// 被完全盖住的源路由从 Overlay 里摘掉（`OverlayEntry.opaque`），源元素本来就
/// 不在树里；OpenContainer 的隐藏机制（`_Hideable`）只在转场那几帧有意义。
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

  /// 转场中途页面淡入的透明度（没在转场时为空）。
  List<double> midTransitionOpacities(WidgetTester tester) => tester
      .widgetList<FadeTransition>(find.byType(FadeTransition))
      .map((t) => t.opacity.value)
      .where((v) => v > 0 && v < 1)
      .toList();

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
    await tester.pump(const Duration(milliseconds: 100)); // 400ms 转场的 1/4

    expectContainerRoute(duration: kContainerTransformDuration);
    expect(find.byType(HabitDetailPage), findsOneWidget);
    expect(
      midTransitionOpacities(tester),
      isNotEmpty,
      reason: '转场中途应有介于 0 与 1 之间的淡入（说明真的在动画，而不是瞬切）',
    );

    // 400ms 之内不该已经稳定（还在转场）
    await tester.pump(const Duration(milliseconds: 100));
    expect(midTransitionOpacities(tester), isNotEmpty);

    await tester.pumpAndSettle();
    expect(find.byType(HabitDetailPage), findsOneWidget);
    expect(find.text('早睡打卡'), findsWidgets); // 详情页标题

    // 返回：反向也在动画，最后回到习惯列表
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(midTransitionOpacities(tester), isNotEmpty);
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
    expect(midTransitionOpacities(tester), isNotEmpty);

    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(midTransitionOpacities(tester), isNotEmpty);
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
    expect(find.byType(HabitDetailPage), findsOneWidget);
    expect(midTransitionOpacities(tester), isEmpty);
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
