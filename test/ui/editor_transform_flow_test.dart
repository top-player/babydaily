import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/habit_editor.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:babydaily/src/ui/note_editor.dart';
import 'package:babydaily/src/ui/task_editor.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试：三处「添加」入口（添加任务 / 添加习惯 / 写笔记）与卡片 ⋮ 的「编辑」
/// 都走容器变换（从按钮或 ⋮ 的位置与尺寸长大成整页表单），并且表单真的落库。
///
/// 这几处原来是与 `showDialog` 的对话框：浮层没有可锚定的源元素，没法做
/// 容器变换。改成整页表单后语义不变——保存 `pop(true)` / 取消 `pop(null)`。
void main() {
  final pushedRoutes = <Route<dynamic>>[];

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

  Future<void> pumpApp(WidgetTester tester, AppController controller) async {
    await tester.pumpWidget(
      RootGate(
        controller: controller,
        navigatorObservers: [_RecordingObserver(pushedRoutes)],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// 点一个入口，断言它推的是容器路由并且表单已经长出来。
  Future<void> tapAndExpectTransform(
    WidgetTester tester,
    Finder trigger,
    Finder page,
  ) async {
    await tester.tap(trigger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(pushedRoutes, isNotEmpty, reason: '入口应该推一条路由上来');
    expect(
      pushedRoutes.last.runtimeType.toString(),
      contains('ContainerRoute'),
      reason: '整页表单必须走容器变换，不能退回 MaterialPageRoute',
    );
    expect(page, findsOneWidget);
    expect(
      tester.getTopLeft(page),
      isNot(Offset.zero),
      reason: '中途二级页应当还在从源元素的位置长出来',
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(page), Offset.zero);
  }

  /// 表单里的输入框：第 0 个是名称/正文，后面是描述与属性。
  TextField fieldAt(WidgetTester tester, int index) =>
      tester.widgetList<TextField>(find.byType(TextField)).elementAt(index);

  setUp(pushedRoutes.clear);

  testWidgets('添加任务：FAB 长大成整页表单，保存后落库并回到列表', (tester) async {
    final controller = await makeApp();
    await pumpApp(tester, controller);
    await openTab(tester, '任务');

    await tapAndExpectTransform(
      tester,
      find.text('添加任务'),
      find.byType(TaskEditorPage),
    );

    await tester.enterText(find.byType(TextField).first, '写周报');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskEditorPage), findsNothing);
    expect(find.text('写周报'), findsOneWidget);
    expect(await controller.service.tasksByType(TaskType.mainline), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('添加任务：取消（X）不落库', (tester) async {
    final controller = await makeApp();
    await pumpApp(tester, controller);
    await openTab(tester, '任务');

    await tapAndExpectTransform(
      tester,
      find.text('添加任务'),
      find.byType(TaskEditorPage),
    );

    await tester.enterText(find.byType(TextField).first, '不要保存');
    await tester.tap(find.byTooltip('取消'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskEditorPage), findsNothing);
    expect(await controller.service.tasksByType(TaskType.mainline), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('添加习惯：FAB 长大成整页表单，每日/每周切换可用', (tester) async {
    final controller = await makeApp();
    await pumpApp(tester, controller);
    await openTab(tester, '习惯');

    await tapAndExpectTransform(
      tester,
      find.text('添加习惯'),
      find.byType(HabitEditorPage),
    );

    await tester.enterText(find.byType(TextField).first, '早睡打卡');
    // 每周 N 次：切到「每周」才会出现次数调节
    await tester.tap(find.text('每周 N 次'));
    await tester.pumpAndSettle();
    expect(find.text('每周次数'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitEditorPage), findsNothing);
    expect(find.text('早睡打卡'), findsOneWidget);
    final habits = await controller.service.habits(includeArchived: true);
    expect(habits, hasLength(1));
    expect(habits.single.frequencyType, HabitFrequency.weekly);
    expect(tester.takeException(), isNull);
  });

  testWidgets('写笔记：FAB 长大成整页表单，保存后列表出现新笔记', (tester) async {
    final controller = await makeApp();
    await pumpApp(tester, controller);
    await openTab(tester, '笔记');

    await tapAndExpectTransform(
      tester,
      find.text('写笔记'),
      find.byType(NoteEditorPage),
    );

    await tester.enterText(find.byType(TextField).first, '今天走了 8000 步。');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorPage), findsNothing);
    expect(find.text('今天走了 8000 步。'), findsOneWidget);
    final notes = await controller.service.notesForDay(DateTime.now());
    expect(notes, hasLength(1));
    expect(notes.single.content, '今天走了 8000 步。');
    expect(tester.takeException(), isNull);
  });

  testWidgets('卡片 ⋮ → 编辑：⋮ 也当容器变换的源元素，名称带进表单', (tester) async {
    final controller = await makeApp();
    await controller.service.createTask(
      name: '读完一本书',
      type: TaskType.mainline,
    );
    await pumpApp(tester, controller);
    await openTab(tester, '任务');

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(pushedRoutes, isNotEmpty);
    expect(pushedRoutes.last.runtimeType.toString(), contains('ContainerRoute'));
    expect(find.byType(TaskEditorPage), findsOneWidget);
    expect(fieldAt(tester, 0).controller!.text, '读完一本书');

    await tester.enterText(find.byType(TextField).first, '读完两本书');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('读完两本书'), findsOneWidget);
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
