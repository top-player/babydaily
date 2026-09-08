import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/character_page.dart';
import 'package:babydaily/src/ui/clay.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试：主角页是唯一没有 AppBar 的标签页，必须自己避开状态栏与
/// 前置摄像头挖孔（DisplayCutout 会并入 MediaQuery.padding），
/// 否则顶部问候卡被状态栏/挖孔遮挡。
void main() {
  testWidgets('主角页顶部内容位于状态栏/挖孔安全区之下', (tester) async {
    // 模拟挖孔屏：顶部安全区 44 逻辑像素（物理 132 @ dpr 3）。
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.padding = const FakeViewPadding(top: 132);
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service.createCharacter(
      name: '小明',
      age: 18,
      gender: Gender.male,
    );
    await controller.init();

    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();

    const double topInset = 132 / 3.0;
    final greetingCard = find.descendant(
      of: find.byType(CharacterPage),
      matching: find.byType(HeroCard),
    );
    expect(greetingCard, findsOneWidget);
    expect(tester.getTopLeft(greetingCard).dy, greaterThanOrEqualTo(topInset));

    await db.close();
  });
}
