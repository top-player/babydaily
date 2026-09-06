import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试：对话框（写笔记/编辑）关闭动画期间不得 dispose TextEditingController，
/// 否则会触发框架断言（_dependents.isEmpty）崩溃。
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

    // 写一篇长笔记并保存（曾因提前 dispose controller 而崩溃）
    await tester.tap(find.text('写笔记'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, '第二章也读完了，进度不错，明天继续。');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 再次打开写笔记对话框并取消（复现关闭动画期崩溃的路径）
    await tester.tap(find.text('写笔记'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 搜索 + 命中跳转
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '第二章');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('第二章').first);
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
