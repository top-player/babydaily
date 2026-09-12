import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试：笔记编辑器（整页表单）开→存→再开→取消 全流程不崩溃。
///
/// 这条路径曾经真的崩过：对话框关闭动画期间提前 dispose TextEditingController
/// 会触发框架断言（_dependents.isEmpty）。改成整页表单后 State.dispose 发生在
/// 路由真正卸载之后，这条回归仍然守着「关表单时别把还挂着的 controller 扔掉」。
void main() {
  testWidgets('笔记页：写笔记/搜索/跳转/日期选择全流程不崩溃', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    await controller.service.addNote(
        '今天读完了第一章，感觉很有收获，继续加油。',
        now: DateTime.now());
    await controller.init();

    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();

    // 切到笔记页
    await tester.tap(find.text('笔记'));
    await tester.pumpAndSettle();

    // 写一篇长笔记并保存
    await tester.tap(find.text('写笔记'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, '第二章也读完了，进度不错，明天继续。');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('第二章也读完了，进度不错，明天继续。'), findsOneWidget);

    // 再次打开编辑器再取消（复现关闭期 dispose 崩溃的路径）
    await tester.tap(find.text('写笔记'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('取消'));
    await tester.pumpAndSettle();
    expect(find.text('第二章也读完了，进度不错，明天继续。'), findsOneWidget);

    // 点笔记卡进编辑页，改完保存
    await tester.tap(find.text('第二章也读完了，进度不错，明天继续。'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '第三章开始，继续保持。');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('第三章开始，继续保持。'), findsOneWidget);

    // 搜索 + 命中跳转
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '第三章');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('第三章').first);
    await tester.pumpAndSettle();

    // 日期选择器（无中文本地化时按钮为 OK）
    await tester.tap(find.textContaining('年'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await db.close();
  });
}
