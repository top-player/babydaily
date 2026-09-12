/// 动效性能测量：真机 profile 模式下量每段动效的每帧 build（UI 线程）与
/// raster（光栅线程）耗时，用于「改前 / 改后」对比，防止动效回退。
///
/// ```sh
/// flutter drive --profile --no-dds --no-pub -d <serial> \
///   --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
/// ```
///
/// 读数要点：
/// - 本机是 120Hz 屏，每帧预算 8.33ms（不是 16ms）——见 perf_driver.dart 里的重算；
/// - [LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive]：`pump` 只等待、不额外催帧，
///   引擎按真实 vsync 出帧，量到的就是屏幕上真正发生的事；
/// - 每段动效先热身跑一遍（不计量），把首次建页 / 首次取数 / 管线编译排除在数据外。
///
/// 本文件只驱动界面，不改任何业务数据（唯一写操作是场景切换，末尾会切回原场景）。
library;

import 'package:babydaily/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 每段动效的观察时长：比动效本身长，把收尾帧也收进来。
///
/// 由于用 benchmarkLive，静置期间不会产生帧，所以窗口给宽一点也不会污染数据。
const Duration _observe = Duration(milliseconds: 900);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('动效每帧耗时', (WidgetTester tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
    app.main();
    await tester.pumpAndSettle();
    await _ensureHome(tester);

    // 起点：任务页（后面几段都从这里出发）。
    await _tapNav(tester, '任务');

    await _measure(tester, binding, 'add_task', () async {
      // 「添加任务」表单：改前是对话框、改后是容器变换出来的编辑页，
      // 计量段只到「表单出现」为止（关闭动作在计量段之外）。
      await tester.tap(find.text('添加任务'));
      await tester.pump(_observe);
    }, cleanup: () => _dismissForm(tester));

    await _measure(tester, binding, 'container_open', () async {
      await tester.tap(find.text('每日任务'));
      await tester.pump(_observe);
    }, cleanup: () => _popBack(tester));

    await _measure(tester, binding, 'container_close', () async {
      await tester.tap(find.text('每日任务'));
      await tester.pump(_observe);
      await _popBack(tester, measured: true);
    });

    await _measure(tester, binding, 'tab_slide', () async {
      await _tapNav(tester, '习惯', observe: true);
    }, cleanup: () => _tapNav(tester, '任务'));

    await _measure(tester, binding, 'scene_switch', () async {
      await _tapNav(tester, '主角', observe: true);
      // 换场景会重算整套主题（AnimatedTheme 全树过渡），是最重的一段。
      await tester.tap(find.text('家里'));
      await tester.pump(_observe);
    }, cleanup: () async {
      await tester.tap(find.text('游玩'));
      await tester.pump(_observe);
      await _tapNav(tester, '任务');
    });
  });
}

/// 热身一次（不计量）→ 计量一次；`cleanup` 负责把界面恢复成可再跑的状态。
Future<void> _measure(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String reportKey,
  Future<void> Function() action, {
  Future<void> Function()? cleanup,
}) async {
  await action();
  if (cleanup != null) await cleanup();
  await binding.watchPerformance(action, reportKey: reportKey);
  if (cleanup != null) await cleanup();
}

/// 底部导航切页；`observe` 为真时把滑动本身也纳入计量窗口。
Future<void> _tapNav(
  WidgetTester tester,
  String label, {
  bool observe = false,
}) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    ),
  );
  await tester.pump(observe ? _observe : const Duration(milliseconds: 600));
}

/// 返回上一页；`measured` 为真时不额外等待（返回动画算在计量段里）。
Future<void> _popBack(WidgetTester tester, {bool measured = false}) async {
  await tester.tap(find.byType(BackButton));
  if (!measured) await tester.pump(_observe);
}

/// 关掉「添加任务」表单：对话框（旧版）点取消、整页编辑器（现在）点左上角 X。
///
/// 两种都认，是为了让这份测量脚本在改动前后跑的是同一段代码路径
/// （计量段本身只到「表单出现」为止，关闭动作不计时）。
Future<void> _dismissForm(WidgetTester tester) async {
  final cancel = find.text('取消');
  final close = find.byTooltip('取消');
  if (cancel.evaluate().isNotEmpty) {
    await tester.tap(cancel.first);
  } else if (close.evaluate().isNotEmpty) {
    await tester.tap(close.first);
  } else {
    await tester.tap(find.byType(BackButton));
  }
  await tester.pump(_observe);
}

/// 库里没有主角时会被引导页拦住：直接跳过（会建一个默认主角）。
Future<void> _ensureHome(WidgetTester tester) async {
  if (find.text('跳过').evaluate().isEmpty) return;
  await tester.tap(find.text('跳过'));
  await tester.pumpAndSettle();
}
