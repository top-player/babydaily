import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/domain/milestone.dart';
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

  group('主线子项与自动完成', () {
    test('有未完成子项时主线不能直接完成', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final mainlineId = await service.createTask(
        name: '读完一本书',
        type: TaskType.mainline,
        reward: const AttributeDelta(health: 0, discipline: 2, charm: 0),
      );
      await service.createSubtask(taskId: mainlineId, name: '读第一章');
      expect(await service.completeTask(mainlineId, now: DateTime(2026, 6, 5, 10)), isNull);
    });

    test('完成子项本身不发奖；最后一个子项完成时主线自动完成并发奖', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final mainlineId = await service.createTask(
        name: '读完一本书',
        type: TaskType.mainline,
        reward: const AttributeDelta(health: 0, discipline: 2, charm: 0),
      );
      final s1 = await service.createSubtask(taskId: mainlineId, name: '读第一章');
      final s2 = await service.createSubtask(taskId: mainlineId, name: '读第二章');

      // 第一个子项：仅标记完成，不发奖、不升级、主线未完成
      final first = await service.completeSubtask(s1, now: DateTime(2026, 6, 5, 10));
      expect(first, isNotNull);
      expect(first!.xpGained, subtaskXp);
      expect(first.attrGain, AttributeDelta.zero);
      expect(first.leveledUp, isFalse);
      expect((await service.character())!.xp, 0);
      expect((await service.character())!.discipline, 50);
      expect(await service.completionLog(), isEmpty); // 子项完成不记任务历史

      // 最后一个子项：主线自动完成，发完成奖励 + 主线经验
      final last = await service.completeSubtask(s2, now: DateTime(2026, 6, 5, 11));
      expect(last, isNotNull);
      expect(last!.xpGained, mainlineXp);
      expect(last.attrGain, const AttributeDelta(health: 0, discipline: 2, charm: 0));
      final c = (await service.character())!;
      expect(c.xp, 50);
      expect(c.discipline, 52);
      expect(levelForXp(c.xp), 2);
      final log = await service.completionLog();
      expect(log, hasLength(1));
      expect(log.single.taskName, '读完一本书');
    });

    test('重复完成同一子项是空操作', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final mainlineId = await service.createTask(name: '目标', type: TaskType.mainline);
      final s1 = await service.createSubtask(taskId: mainlineId, name: '第一步');
      expect(await service.completeSubtask(s1, now: DateTime(2026, 6, 5, 10)), isNotNull);
      expect(await service.completeSubtask(s1, now: DateTime(2026, 6, 5, 11)), isNull);
    });

    test('删除任务级联删除子项，但保留完成历史（快照名称）', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final mainlineId = await service.createTask(name: '读完一本书', type: TaskType.mainline);
      final s1 = await service.createSubtask(taskId: mainlineId, name: '读第一章');
      await service.completeSubtask(s1, now: DateTime(2026, 6, 5, 10)); // 自动完成主线并记历史

      await service.deleteTask(mainlineId);

      expect(await service.completeTask(mainlineId, now: DateTime(2026, 6, 6, 10)), isNull);
      final log = await service.completionLog();
      expect(log, hasLength(1));
      expect(log.single.taskName, '读完一本书');
      expect(await service.subtasksOf(mainlineId), isEmpty);
    });
  });

  group('习惯打卡', () {
    test('每日习惯打卡：+5 经验、默认 +1 自律、连续天数递增', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final habitId = await service.createHabit(
        name: '早睡打卡',
        frequencyType: HabitFrequency.daily,
      );

      final day1 = await service.checkInHabit(habitId, now: DateTime(2026, 6, 1, 22));
      expect(day1, isNotNull);
      expect(day1!.xpGained, habitCheckinXp);
      expect(day1.attrGain, const AttributeDelta(health: 0, discipline: 1, charm: 0));
      expect(day1.streak, 1);
      expect(day1.milestones, isEmpty);

      final day2 = await service.checkInHabit(habitId, now: DateTime(2026, 6, 2, 22));
      expect(day2!.streak, 2);

      final c = (await service.character())!;
      expect(c.xp, 10); // 5 + 5
      expect(c.discipline, 52);
    });

    test('同一天重复打卡是空操作', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final habitId = await service.createHabit(
        name: '早睡打卡',
        frequencyType: HabitFrequency.daily,
      );
      expect(await service.checkInHabit(habitId, now: DateTime(2026, 6, 1, 22)), isNotNull);
      expect(await service.checkInHabit(habitId, now: DateTime(2026, 6, 1, 23)), isNull);
      expect((await service.character())!.xp, 5);
    });

    test('连续 10 天发放里程碑 +20，且每个习惯终身一次', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final habitId = await service.createHabit(
        name: '阅读 30 分钟',
        frequencyType: HabitFrequency.daily,
      );

      for (var i = 0; i < 9; i++) {
        await service.checkInHabit(habitId, now: DateTime(2026, 6, 1 + i, 22));
      }
      final day10 = await service.checkInHabit(habitId, now: DateTime(2026, 6, 10, 22));
      expect(day10!.streak, 10);
      expect(day10.milestones, [const MilestoneReached(days: 10, xp: 20)]);
      // 9×5 + 5 + 20 = 70
      expect((await service.character())!.xp, 70);

      // 断签后重建到 10 天：不再发放
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 20, 22)); // 新连续第 1 天
      for (var i = 1; i < 9; i++) {
        await service.checkInHabit(habitId, now: DateTime(2026, 6, 20 + i, 22));
      }
      final rebuiltDay10 = await service.checkInHabit(habitId, now: DateTime(2026, 6, 29, 22));
      expect(rebuiltDay10!.streak, 10);
      expect(rebuiltDay10.milestones, isEmpty);
    });

    test('连续 20/30 天分别发放对应里程碑', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final habitId = await service.createHabit(
        name: '阅读 30 分钟',
        frequencyType: HabitFrequency.daily,
      );
      for (var i = 0; i < 19; i++) {
        await service.checkInHabit(habitId, now: DateTime(2026, 6, 1 + i, 22));
      }
      final day20 = await service.checkInHabit(habitId, now: DateTime(2026, 6, 20, 22));
      expect(day20!.milestones, [const MilestoneReached(days: 20, xp: 30)]);

      for (var i = 20; i < 29; i++) {
        await service.checkInHabit(habitId, now: DateTime(2026, 6, 1 + i, 22));
      }
      final day30 = await service.checkInHabit(habitId, now: DateTime(2026, 6, 30, 22));
      expect(day30!.milestones, [const MilestoneReached(days: 30, xp: 50)]);
    });

    test('每周 3 次习惯：打卡 +5 经验，连续按达标周计算，无里程碑', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final habitId = await service.createHabit(
        name: '运动',
        frequencyType: HabitFrequency.weekly,
        timesPerWeek: 3,
        reward: const AttributeDelta(health: 1, discipline: 0, charm: 0),
      );
      // 2026-06-01 是周一。第 1 周（6/1-6/7）打卡 3 次
      final w1d1 = await service.checkInHabit(habitId, now: DateTime(2026, 6, 1, 8));
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 3, 8));
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 5, 8));
      expect(w1d1!.xpGained, habitCheckinXp);
      expect(w1d1.attrGain, const AttributeDelta(health: 1, discipline: 0, charm: 0));
      // 第 2 周周一打卡：本周未达标（进行中），连续 = 1（上周达标）
      final w2d1 = await service.checkInHabit(habitId, now: DateTime(2026, 6, 8, 8));
      expect(w2d1!.streak, 1);
      expect(w2d1.milestones, isEmpty);
      expect((await service.character())!.health, 54); // 4 次打卡 × 1 健康
    });

    test('每周习惯同一天多次打卡只计一次（连续周按打卡天数计）', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final habitId = await service.createHabit(
        name: '运动',
        frequencyType: HabitFrequency.weekly,
        timesPerWeek: 3,
      );
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 1, 8));
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 1, 20)); // 同一天
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 2, 8));
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 3, 8));
      // 打卡 3 天即达标：周日视角连续 1 周
      final outcome = await service.checkInHabit(habitId, now: DateTime(2026, 6, 3, 9));
      expect(outcome, isNull); // 6/3 已打卡
      final dates = await service.checkinDatesOf(habitId);
      expect(dates, hasLength(3));
      expect((await service.character())!.xp, 15); // 只有 3 次有效打卡
    });

    test('打卡不存在的习惯返回 null', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      expect(await service.checkInHabit(999, now: DateTime(2026, 6, 1, 22)), isNull);
    });
  });

  group('每日结算', () {
    test('0 点结算：未完成每日任务扣配置属性，完成的保留到重置', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final done = await service.createTask(
        name: '早起喝水',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 0, discipline: 1, charm: 0),
      );
      final missed = await service.createTask(
        name: '散步 10 分钟',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 2, discipline: 0, charm: 0),
      );
      await service.completeTask(done, now: DateTime(2026, 6, 5, 9));

      final outcome = await service.settleDay(now: DateTime(2026, 6, 6, 0, 5));
      expect(outcome, isNotNull);
      expect(outcome!.totalPenalty, const AttributeDelta(health: 2, discipline: 0, charm: 0));
      final c = (await service.character())!;
      expect(c.health, 48); // 50 - 2
      expect(c.discipline, 51); // 完成的任务 +1，未被扣
      expect(c.xp, 0); // 经验从不被扣

      // 结算后每日任务可再次完成（新的一天）
      expect(await service.completeTask(missed, now: DateTime(2026, 6, 6, 9)), isNotNull);
    });

    test('同一天重复结算只扣一次（幂等）', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      await service.createTask(
        name: '散步 10 分钟',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 2, discipline: 0, charm: 0),
      );
      final first = await service.settleDay(now: DateTime(2026, 6, 6, 0, 5));
      final second = await service.settleDay(now: DateTime(2026, 6, 6, 1, 5));
      expect(first, isNotNull);
      expect(second, isNull);
      expect((await service.character())!.health, 48);
    });

    test('属性已为 0 时结算停在下限，无负数债务', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      await (db.update(db.characters)..where((c) => c.id.equals(1))).write(
        const CharactersCompanion(
            health: Value(1), discipline: Value(0), charm: Value(0)),
      );
      await service.createTask(
        name: '散步 10 分钟',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 5, discipline: 0, charm: 0),
      );
      final outcome = await service.settleDay(now: DateTime(2026, 6, 6, 0, 5));
      expect(outcome!.totalPenalty, const AttributeDelta(health: 1, discipline: 0, charm: 0));
      expect((await service.character())!.health, 0);
    });

    test('没有未完成每日任务：不扣分', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final done = await service.createTask(
        name: '早起喝水',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 0, discipline: 1, charm: 0),
      );
      await service.completeTask(done, now: DateTime(2026, 6, 5, 9));
      final outcome = await service.settleDay(now: DateTime(2026, 6, 6, 0, 5));
      expect(outcome!.totalPenalty, AttributeDelta.zero);
      expect((await service.character())!.discipline, 51);
    });
  });

  group('笔记与经验', () {
    test('不足 20 字的笔记不给经验', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final result = await service.addNote('今天不错', now: DateTime(2026, 6, 5, 20));
      expect(result.xpGained, 0);
      expect(result.noteStreak, 0);
      expect((await service.character())!.xp, 0);
    });

    test('当天首篇 ≥20 字笔记 +10，且每天只发一次', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final long = '今天读完了第一章，感觉很有收获，继续加油。'; // >20 字
      final first = await service.addNote(long, now: DateTime(2026, 6, 5, 20));
      expect(first.xpGained, noteBaseXp);
      expect(first.noteStreak, 1);

      final second = await service.addNote(long, now: DateTime(2026, 6, 5, 21));
      expect(second.xpGained, 0);
      expect((await service.character())!.xp, 10);
    });

    test('连续写笔记：第 N 天 +10+min(N-1,5)，断档回到 10', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      const long = '今天读完了第一章，感觉很有收获，继续加油。';
      await service.addNote(long, now: DateTime(2026, 6, 1, 20)); // 10
      await service.addNote(long, now: DateTime(2026, 6, 2, 20)); // 11
      await service.addNote(long, now: DateTime(2026, 6, 3, 20)); // 12
      expect((await service.character())!.xp, 33);

      // 断档一天
      await service.addNote(long, now: DateTime(2026, 6, 5, 20)); // 回 10
      expect((await service.character())!.xp, 43);
      final r6 = await service.addNote(long, now: DateTime(2026, 6, 6, 20));
      expect(r6.noteStreak, 2);
      expect(r6.xpGained, 11);
    });

    test('连续加成封顶 +5（每天最多 15）', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      const long = '今天读完了第一章，感觉很有收获，继续加油。';
      for (var i = 0; i < 6; i++) {
        await service.addNote(long, now: DateTime(2026, 6, 1 + i, 20));
      }
      // 10+11+12+13+14+15 = 75
      expect((await service.character())!.xp, 75);
      final r7 = await service.addNote(long, now: DateTime(2026, 6, 7, 20));
      expect(r7.xpGained, 15);
      expect(r7.noteStreak, 7);
    });

    test('删除笔记不回追经验；短笔记改成合格笔记当天可补发', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      const long = '今天读完了第一章，感觉很有收获，继续加油。';
      final noteId = await service.addNote(long, now: DateTime(2026, 6, 5, 20)).then((r) => r.noteId!);
      expect((await service.character())!.xp, 10);
      await service.deleteNote(noteId);
      expect((await service.character())!.xp, 10); // 不回追

      // 新的一天：先写短笔记，再改长 → 当天补发
      final shortId = await service.addNote('打卡', now: DateTime(2026, 6, 6, 9)).then((r) => r.noteId!);
      expect((await service.character())!.xp, 10);
      await service.updateNote(shortId, long);
      expect((await service.character())!.xp, 20);
    });
  });

  group('笔记检索', () {
    test('按天浏览与关键词搜索（日期+内容）', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      await service.addNote('今天去公园散步，天气很好。', now: DateTime(2026, 6, 5, 20));
      await service.addNote('晚上读完了第二章。', now: DateTime(2026, 6, 5, 21));
      await service.addNote('公司项目上线，忙了一整天。', now: DateTime(2026, 6, 6, 22));

      final day5 = await service.notesForDay(DateTime(2026, 6, 5));
      expect(day5, hasLength(2));
      final day6 = await service.notesForDay(DateTime(2026, 6, 6));
      expect(day6, hasLength(1));

      final hits = await service.searchNotes('散步');
      expect(hits, hasLength(1));
      expect(hits.single.content, '今天去公园散步，天气很好。');

      final misses = await service.searchNotes('不存在的词');
      expect(misses, isEmpty);
    });
  });
}
