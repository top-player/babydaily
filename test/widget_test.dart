import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('首次启动（无主角）显示新手引导', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('先认识一下主角'), findsOneWidget);
    expect(find.text('宝宝日常'), findsNothing); // 标题不展示在引导页

    await db.close();
  });
}
