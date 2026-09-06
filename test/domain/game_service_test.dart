import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/xp_economy.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late GameService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = GameService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('主角', () {
    test('创建后：50/50/50 起始属性、0 经验、Lv1', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final c = await service.character();
      expect(c, isNotNull);
      expect(c!.name, '小明');
      expect(c.age, 18);
      expect(c.gender, Gender.male);
      expect(c.xp, 0);
      expect(c.health, 50);
      expect(c.discipline, 50);
      expect(c.charm, 50);
      expect(levelForXp(c.xp), 1);
      expect(titleForLevel(levelForXp(c.xp)), '初出茅庐');
    });

    test('未创建时返回 null', () async {
      expect(await service.character(), isNull);
    });
  });

  group('完成任务', () {
    test('主线完成：+50 经验并升级（40 到 Lv2），发放配置属性，记录历史', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(
        name: '读完一本书',
        type: TaskType.mainline,
        reward: const AttributeDelta(health: 0, discipline: 2, charm: 0),
      );
      final outcome = await service.completeTask(id, now: DateTime(2026, 6, 5, 10));

      expect(outcome, isNotNull);
      expect(outcome!.xpGained, mainlineXp);
      expect(outcome.attrGain, const AttributeDelta(health: 0, discipline: 2, charm: 0));
      expect(outcome.levelBefore, 1);
      expect(outcome.levelAfter, 2);
      expect(outcome.leveledUp, isTrue);

      final c = (await service.character())!;
      expect(c.xp, 50);
      expect(c.discipline, 52);
      expect(levelForXp(c.xp), 2);

      final log = await service.completionLog();
      expect(log, hasLength(1));
      expect(log.single.taskName, '读完一本书');
      expect(log.single.xpGained, mainlineXp);
      expect(log.single.disciplineGained, 2);
    });

    test('支线完成：+20 经验，属性照发', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(
        name: '整理书桌',
        type: TaskType.side,
        reward: const AttributeDelta(health: 1, discipline: 0, charm: 0),
      );
      final outcome = await service.completeTask(id, now: DateTime(2026, 6, 5, 10));

      expect(outcome!.xpGained, sideQuestXp);
      expect(outcome.attrGain, const AttributeDelta(health: 1, discipline: 0, charm: 0));
      final c = (await service.character())!;
      expect(c.xp, 20);
      expect(c.health, 51);
      expect(levelForXp(c.xp), 1); // 20 < 40，未升级
    });

    test('每日任务完成：0 经验、只发属性', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(
        name: '早起喝水',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 0, discipline: 1, charm: 0),
      );
      final outcome = await service.completeTask(id, now: DateTime(2026, 6, 5, 10));

      expect(outcome!.xpGained, dailyTaskXp);
      expect(outcome.attrGain, const AttributeDelta(health: 0, discipline: 1, charm: 0));
      final c = (await service.character())!;
      expect(c.xp, 0);
      expect(c.discipline, 51);
    });

    test('每日任务同一天重复完成：不重复发奖', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(
        name: '早起喝水',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 0, discipline: 1, charm: 0),
      );
      final first = await service.completeTask(id, now: DateTime(2026, 6, 5, 10));
      final second = await service.completeTask(id, now: DateTime(2026, 6, 5, 11));

      expect(first, isNotNull);
      expect(second, isNull);
      final c = (await service.character())!;
      expect(c.discipline, 51);
      expect(await service.completionLog(), hasLength(1));
    });

    test('已完成的主线/支线不能再次完成', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(name: '整理书桌', type: TaskType.side);
      expect(await service.completeTask(id, now: DateTime(2026, 6, 5, 10)), isNotNull);
      expect(await service.completeTask(id, now: DateTime(2026, 6, 6, 10)), isNull);
      expect(await service.completionLog(), hasLength(1));
    });

    test('不存在或已删除的任务返回 null', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      expect(await service.completeTask(999, now: DateTime(2026, 6, 5, 10)), isNull);
    });
  });
}
