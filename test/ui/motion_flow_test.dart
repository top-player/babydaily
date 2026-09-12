import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/character_page.dart';
import 'package:babydaily/src/ui/habits_page.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:babydaily/src/ui/motion.dart';
import 'package:babydaily/src/ui/notes_page.dart';
import 'package:babydaily/src/ui/tasks_page.dart';
import 'package:babydaily/src/ui/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 切标签的滑动与场景切换的指示块滑动。
void main() {
  Future<AppController> makeApp() async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final controller = AppController(db);
    await controller.service.createCharacter(
      name: '小明',
      age: 18,
      gender: Gender.male,
    );
    await controller.init();
    return controller;
  }

  /// 某个页面的滑动位移（像素）：正位时没有包装层，返回 0。
  double slideOffsetOf(WidgetTester tester, Type page) {
    final transforms = find.ancestor(
      of: find.byType(page, skipOffstage: false),
      matching: find.byType(Transform, skipOffstage: false),
    );
    if (transforms.evaluate().isEmpty) return 0;
    return tester
        .widget<Transform>(transforms.last)
        .transform
        .getTranslation()
        .x;
  }

  /// 场景卡选中块的实时位置（返回它与槽位左边缘的距离，单位像素）。
  ///
  /// 直接量渲染出来的位置：`AnimatedAlign` 内部把补间求值后交给一个普通
  /// `Align`，读 widget 的 `alignment` 只会拿到静态目标值，量不到动画过程。
  double pillX(WidgetTester tester) {
    final pill = find.byType(AnimatedContainer).first;
    final row = find
        .ancestor(of: find.text('家里'), matching: find.byType(Row))
        .first;
    return tester.getTopLeft(pill).dx - tester.getTopLeft(row).dx;
  }

  testWidgets('切标签时页面滑动：中间帧有位移，稳定后回到正位', (tester) async {
    final controller = await makeApp();
    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();

    // 静止时四页都在正位、且**都挂在树上**（切过去不用重新取数）
    expect(slideOffsetOf(tester, CharacterPage), 0);
    expect(find.byType(CharacterPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(TasksPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(HabitsPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(NotesPage, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('习惯'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final incoming = slideOffsetOf(tester, HabitsPage);
    final outgoing = slideOffsetOf(tester, CharacterPage);
    expect(
      incoming,
      greaterThan(0),
      reason: '新页应当正在从右侧滑入（位移为正、且小于一页宽）',
    );
    expect(incoming, lessThan(800));
    expect(
      outgoing,
      lessThan(0),
      reason: '旧页应当正在往左滑出',
    );
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    // 落位：位移回到 0（正位时连包装层都不套）
    expect(slideOffsetOf(tester, HabitsPage), 0);
    expect(find.text('习惯'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('场景切换：选中块滑到目标槽位，中途位置介于两者之间', (tester) async {
    final controller = await makeApp();
    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();

    // 场景卡在主角页底部（ListView 懒构建），先滚进视口
    await tester.ensureVisible(find.text('游玩'));
    await tester.pumpAndSettle();
    // 指示块覆盖三个槽位，一个槽位约 (总宽-8)/3；先量出左端与右端位置
    final left = pillX(tester);
    expect(left, lessThan(4), reason: '默认「家里」时指示块应贴在左边');

    await tester.tap(find.text('游玩'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final mid = pillX(tester);
    expect(mid, greaterThan(left + 4), reason: '选中块应当开始往右滑');
    final right = tester.getSize(find.byType(AnimatedContainer).first).width;
    expect(mid, lessThan(left + right * 2), reason: '中途还没到最右');

    await tester.pumpAndSettle();
    final settled = pillX(tester);
    expect(settled, greaterThan(mid), reason: '最终应当落在最右槽位');
    expect(controller.scene, Scene.play);
    expect(tester.takeException(), isNull);

    // 再切回中间，位置应当落在中间槽位
    await tester.tap(find.text('公司'));
    await tester.pumpAndSettle();
    expect(pillX(tester), lessThan(settled));
    expect(pillX(tester), greaterThan(left));
    expect(controller.scene, Scene.company);
    expect(tester.takeException(), isNull);
  });

  testWidgets('容器变换路由不带遮罩（四角伪影的根因）', (tester) async {
    final controller = await makeApp();
    await controller.service.createHabit(
      name: '早睡打卡',
      frequencyType: HabitFrequency.daily,
    );
    await tester.pumpWidget(
      RootGate(controller: controller, navigatorObservers: [_Routes()]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('习惯'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('早睡打卡'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final route = _Routes.last;
    expect(route, isNotNull);
    expect(route!.transitionDuration, kContainerTransformDuration);
    expect(
      route.barrierColor,
      isNull,
      reason: '容器路由不能有黑色遮罩：会把整屏压暗、让缩小的卡片四角显形',
    );
    expect(route.barrierDismissible, isFalse);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('全局页面转场主题仍是容器变换型号（兜底通道没被改坏）', (tester) async {
    final theme = buildTheme(Scene.home);
    expect(
      theme.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<ClayPageTransitionsBuilder>(),
    );
  });

  testWidgets('容器变换：转场期间源元素与二级页各只构建一次（防重建风暴）', (tester) async {
    var closedBuilds = 0;
    var openBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => openContainerTransform(
              context: context,
              openBuilder: (context, close) {
                openBuilds++;
                return const SizedBox.expand(child: Text('二级页'));
              },
              closedBuilder: (context, open) {
                closedBuilds++;
                return TextButton(
                  onPressed: open,
                  child: const Text('打开'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 收起态在源路由里构建一次（第一次 build），后续 setState 会重新构建它。
    final closedAtRest = closedBuilds;
    expect(closedAtRest, greaterThan(0));

    await tester.tap(find.text('打开'));
    await tester.pump();
    final closedAfterFirstFrame = closedBuilds;
    final openAfterFirstFrame = openBuilds;
    expect(openAfterFirstFrame, greaterThan(0), reason: '二级页应当在转场第一帧就建好');

    // 转场中段：动画帧不该再重建任何一边（这条就是性能回归的闸门——
    // 每帧重建整页会让 120Hz 上的 8.3ms 预算直接爆掉）。
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        closedBuilds,
        closedAfterFirstFrame,
        reason: '第 $i 帧又重建了源元素',
      );
      expect(openBuilds, openAfterFirstFrame, reason: '第 $i 帧又重建了二级页');
    }

    await tester.pumpAndSettle();
    expect(find.text('二级页'), findsOneWidget);
    // 收尾时结构会换成「铺满整屏」的静态版本（二级页多一次），源路由也可能因为
    // 路由状态变化重建一次（收起态多一次）——所以只给个宽松上限；
    // 真正的闸门是上面「每个动画帧都不许重建」那两条。
    expect(closedBuilds, lessThanOrEqualTo(closedAtRest + 3));
    expect(openBuilds, lessThanOrEqualTo(openAfterFirstFrame + 1));
    expect(tester.takeException(), isNull);
  });
}

/// 记录推上来的路由。
class _Routes extends NavigatorObserver {
  static final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!route.isFirst) pushed.add(route);
  }

  static ModalRoute<dynamic>? get last {
    if (pushed.isEmpty) return null;
    final route = pushed.last;
    return route is ModalRoute<dynamic> ? route : null;
  }
}
