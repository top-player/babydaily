import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 备份导入导出：导入走系统文件选择器（原生通道），导出落到「下载/BabyDaily」。
void main() {
  const channel = MethodChannel('com.yjym.baby.babydaily/storage');

  /// 造一份"另一个设备"的备份（主角 + 失败任务 + 每日任务历史）。
  Future<String> buildBackup() async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = GameService(db);
    await service.createCharacter(name: '小红', age: 20, gender: Gender.female);
    final side = await service.createTask(name: '写周报', type: TaskType.side);
    await service.failTask(side, now: DateTime(2026, 9, 1, 10));
    final json = await service.exportJson();
    await db.close();
    return json;
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
  }

  testWidgets('导入：系统文件选择器返回的备份，确认后覆盖当前数据', (tester) async {
    final json = await buildBackup();
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    await controller.init();

    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'pickBackup') {
        return {'name': 'babydaily_backup_20260901.json', 'json': json};
      }
      return null;
    });

    await tester.pumpWidget(RootGate(controller: controller));
    await openSettings(tester);
    await tester.tap(find.text('导入备份'));
    await tester.pumpAndSettle();

    // 走的是文件选择器通道，并在确认框里显示备份摘要
    expect(calls, contains('pickBackup'));
    expect(find.text('babydaily_backup_20260901.json'), findsOneWidget);
    expect(find.textContaining('主角：小红'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '导入'));
    await tester.pumpAndSettle();

    final restored = (await controller.service.character())!;
    expect(restored.name, '小红');
    expect(restored.age, 20);
    expect(
      await controller.service.tasksByType(TaskType.side, failed: true),
      hasLength(1),
    );

    await tester.pump(const Duration(seconds: 4)); // 冲掉提示条的定时器
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await db.close();
  });

  testWidgets('导入：取消选择不改动任何数据', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    await controller.init();

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async => null); // 用户取消：通道返回 null

    await tester.pumpWidget(RootGate(controller: controller));
    await openSettings(tester);
    await tester.tap(find.text('导入备份'));
    await tester.pumpAndSettle();

    expect((await controller.service.character())!.name, '小明');
    expect(find.text('导入备份'), findsOneWidget); // 没有弹出确认框

    expect(tester.takeException(), isNull);
    await db.close();
  });

  testWidgets('导入：选到非备份文件时给出提示且不覆盖', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    await controller.init();

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'pickBackup') {
        return {'name': '照片.json', 'json': '{"hello": "world"}'};
      }
      return null;
    });

    await tester.pumpWidget(RootGate(controller: controller));
    await openSettings(tester);
    await tester.tap(find.text('导入备份'));
    await tester.pumpAndSettle();

    expect(find.textContaining('这不是宝宝日常导出的备份文件'), findsOneWidget);
    expect((await controller.service.character())!.name, '小明');

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await db.close();
  });

  testWidgets('导出：写入公共下载目录并展示落点', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final controller = AppController(db);
    await controller.service
        .createCharacter(name: '小明', age: 18, gender: Gender.male);
    await controller.init();

    String? savedJson;
    String? savedName;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'saveBackup') {
        savedJson = call.arguments['json'] as String?;
        savedName = call.arguments['name'] as String?;
        return 'Download/BabyDaily/$savedName';
      }
      return null;
    });

    await tester.pumpWidget(RootGate(controller: controller));
    await openSettings(tester);
    await tester.tap(find.text('导出备份（JSON）'));
    await tester.pumpAndSettle();

    expect(savedName, startsWith('babydaily_backup_'));
    expect(savedJson, contains('"小明"'));
    expect(find.text('下载/BabyDaily/$savedName'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await db.close();
  });
}
