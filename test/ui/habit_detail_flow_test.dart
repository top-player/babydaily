import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试：点击习惯卡片打开详情页，不得在 initState 中查找
/// InheritedWidget（会白屏卡死）。
void main() {
  testWidgets('习惯卡片 → 详情页正常渲染（月历/热力图）', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    final habitId = await controller.service.createHabit(
      name: '早睡打卡',
      frequencyType: HabitFrequency.daily,
      description: '22:30 前睡',
    );
    await controller.service
        .checkInHabit(habitId, now: DateTime.now());
    await controller.init();

    await tester.pumpWidget(RootGate(controller: controller));
    await tester.pumpAndSettle();

    // 切到习惯页
    await tester.tap(find.text('习惯'));
    await tester.pumpAndSettle();

    // 点击习惯卡片（含"已打卡"胶囊区域 → InkWell 卡片整体）
    await tester.tap(find.text('早睡打卡'));
    await tester.pumpAndSettle();

    // 详情页应正常渲染：AppBar 名称 + 统计卡（热力图在视口外，用统计文案断言）
    expect(find.text('早睡打卡'), findsWidgets);
    expect(find.textContaining('连续'), findsOneWidget);
    expect(find.textContaining('累计'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await db.close();
  });
}
