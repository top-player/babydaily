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

    test('修改每周次数后连续按新规则重算，累计次数不变', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final habitId = await service.createHabit(
        name: '运动',
        frequencyType: HabitFrequency.weekly,
        timesPerWeek: 3,
      );
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 1, 8));
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 3, 8));
      await service.checkInHabit(habitId, now: DateTime(2026, 6, 5, 8));

      // 改为每周 4 次：本周 3 次 < 4，连续归零；累计 3 保留
      await service.updateHabit(
        id: habitId,
        name: '运动',
        frequencyType: HabitFrequency.weekly,
        timesPerWeek: 4,
        reward: AttributeDelta.zero,
        now: DateTime(2026, 6, 5, 12),
      );
      var status = await service.habitStatus(habitId, now: DateTime(2026, 6, 7));
      expect(status.streak, 0);
      expect(status.cumulative, 3);

      // 新的一周（6/8 起）按新规则打卡 4 次 → 连续 1 周
      for (final day in [8, 10, 12, 14]) {
        await service.checkInHabit(habitId, now: DateTime(2026, 6, day, 8));
      }
      status = await service.habitStatus(habitId, now: DateTime(2026, 6, 14));
      expect(status.streak, 1);
      expect(status.cumulative, 7);
    });

    test('只改名称不改规则：连续不重置', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final habitId = await service.createHabit(
        name: '早睡打卡',
        frequencyType: HabitFrequency.daily,
      );
      for (final day in [1, 2, 3]) {
        await service.checkInHabit(habitId, now: DateTime(2026, 6, day, 22));
      }
      await service.updateHabit(
        id: habitId,
        name: '早睡（22:30）',
        frequencyType: HabitFrequency.daily,
        timesPerWeek: 1,
        reward: AttributeDelta.zero,
        now: DateTime(2026, 6, 3, 12),
      );
      final status = await service.habitStatus(habitId, now: DateTime(2026, 6, 3));
      expect(status.streak, 3);
    });

    test('归档后不能打卡；取消归档恢复', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final habitId = await service.createHabit(
        name: '早睡打卡',
        frequencyType: HabitFrequency.daily,
      );
      await service.setHabitArchived(habitId, true);
      expect(await service.checkInHabit(habitId, now: DateTime(2026, 6, 1, 22)), isNull);
      await service.setHabitArchived(habitId, false);
      expect(await service.checkInHabit(habitId, now: DateTime(2026, 6, 1, 22)), isNotNull);
    });
  });

  group('每日结算', () {
    test('0 点结算：未完成每日任务扣配置属性并记为失败，完成的保留到重置', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final created = DateTime(2026, 6, 1, 8);
      final done = await service.createTask(
        name: '早起喝水',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 0, discipline: 1, charm: 0),
        now: created,
      );
      final missed = await service.createTask(
        name: '散步 10 分钟',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 2, discipline: 0, charm: 0),
        now: created,
      );
      await service.completeTask(done, now: DateTime(2026, 6, 5, 9));

      final outcome = await service.settleDay(now: DateTime(2026, 6, 6, 0, 5));
      expect(outcome, isNotNull);
      expect(outcome!.totalPenalty, const AttributeDelta(health: 2, discipline: 0, charm: 0));
      final c = (await service.character())!;
      expect(c.health, 48); // 50 - 2
      expect(c.discipline, 51); // 完成的任务 +1，未被扣
      expect(c.xp, 0); // 经验从不被扣

      // 未完成的任务记为失败：任务保留、历史留痕
      expect(await service.dailyTasks(), hasLength(2));
      final logs = await service.dailyLogsOn(DateTime(2026, 6, 5));
      expect(logs, hasLength(2));
      final failedLog = logs.singleWhere(
        (l) => l.status == DailyTaskStatus.failed,
      );
      expect(failedLog.taskName, '散步 10 分钟');
      expect(failedLog.penaltyHealth, 2);
      expect(
        logs.singleWhere((l) => l.status == DailyTaskStatus.completed).taskName,
        '早起喝水',
      );

      // 结算后每日任务可再次完成（新的一天）
      expect(await service.completeTask(missed, now: DateTime(2026, 6, 6, 9)), isNotNull);
    });

    test('结算不追溯昨天之后才创建的每日任务', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      await service.createTask(
        name: '今天刚建的',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 3, discipline: 0, charm: 0),
        now: DateTime(2026, 6, 6, 8), // 结算当天才创建
      );
      final outcome = await service.settleDay(now: DateTime(2026, 6, 6, 9));
      expect(outcome!.totalPenalty, AttributeDelta.zero);
      expect((await service.character())!.health, 50);
      expect(await service.dailyLogsOn(DateTime(2026, 6, 5)), isEmpty);
    });

    test('同一天重复结算只扣一次（幂等）', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      await service.createTask(
        name: '散步 10 分钟',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 2, discipline: 0, charm: 0),
        now: DateTime(2026, 6, 1, 8),
      );
      final first = await service.settleDay(now: DateTime(2026, 6, 6, 0, 5));
      final second = await service.settleDay(now: DateTime(2026, 6, 6, 1, 5));
      expect(first, isNotNull);
      expect(second, isNull);
      expect((await service.character())!.health, 48);
      expect(await service.dailyLogsOn(DateTime(2026, 6, 5)), hasLength(1));
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
        now: DateTime(2026, 6, 1, 8),
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
        now: DateTime(2026, 6, 1, 8),
      );
      await service.completeTask(done, now: DateTime(2026, 6, 5, 9));
      final outcome = await service.settleDay(now: DateTime(2026, 6, 6, 0, 5));
      expect(outcome!.totalPenalty, AttributeDelta.zero);
      expect((await service.character())!.discipline, 51);
    });

    test('结算不重复扣当天已手动判失败的任务', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(
        name: '散步 10 分钟',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 2, discipline: 0, charm: 0),
        now: DateTime(2026, 6, 1, 8),
      );
      await service.failTask(id, now: DateTime(2026, 6, 5, 20)); // 手动失败已扣 2
      expect((await service.character())!.health, 48);

      final outcome = await service.settleDay(now: DateTime(2026, 6, 6, 0, 5));
      expect(outcome!.totalPenalty, AttributeDelta.zero);
      expect((await service.character())!.health, 48);
      expect(await service.dailyLogsOn(DateTime(2026, 6, 5)), hasLength(1));
    });
  });

  group('手动判失败（不删除任务）', () {
    test('每日任务：立即扣属性、记当天失败，当天不能再完成', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(
        name: '散步 10 分钟',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 2, discipline: 1, charm: 0),
      );
      final outcome = await service.failTask(id, now: DateTime(2026, 6, 5, 20));
      expect(outcome, isNotNull);
      expect(outcome!.penalty, const AttributeDelta(health: 2, discipline: 1, charm: 0));
      expect(outcome.taskType, TaskType.daily);

      final c = (await service.character())!;
      expect(c.health, 48);
      expect(c.discipline, 49);
      expect(c.xp, 0);

      // 任务保留，只是今天不能再完成；重复判失败无效
      expect(await service.dailyTasks(), hasLength(1));
      expect(await service.completeTask(id, now: DateTime(2026, 6, 5, 21)), isNull);
      expect(await service.failTask(id, now: DateTime(2026, 6, 5, 22)), isNull);
      expect((await service.character())!.health, 48);

      final logs = await service.dailyLogsOn(DateTime(2026, 6, 5));
      expect(logs, hasLength(1));
      expect(logs.single.status, DailyTaskStatus.failed);
      expect(logs.single.penaltyDiscipline, 1);

      // 第二天照常可完成
      expect(await service.completeTask(id, now: DateTime(2026, 6, 6, 9)), isNotNull);
    });

    test('每日任务：属性已为 0 时判失败不产生负数', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      await (db.update(db.characters)..where((c) => c.id.equals(1))).write(
        const CharactersCompanion(health: Value(1)),
      );
      final id = await service.createTask(
        name: '散步 10 分钟',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 5, discipline: 0, charm: 0),
      );
      final outcome = await service.failTask(id, now: DateTime(2026, 6, 5, 20));
      expect(outcome!.penalty, const AttributeDelta(health: 1, discipline: 0, charm: 0));
      expect((await service.character())!.health, 0);
    });

    test('每日任务：当天已完成不能判失败', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(
        name: '早起喝水',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 0, discipline: 1, charm: 0),
      );
      await service.completeTask(id, now: DateTime(2026, 6, 5, 9));
      expect(await service.failTask(id, now: DateTime(2026, 6, 5, 20)), isNull);
      expect((await service.character())!.discipline, 51);
    });

    test('主线/支线：进「已失败」归档，不发奖也不扣属性，且是终态', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final mainline = await service.createTask(
        name: '读完一本书',
        type: TaskType.mainline,
        reward: const AttributeDelta(health: 0, discipline: 2, charm: 0),
      );
      await service.createSubtask(taskId: mainline, name: '第一章');
      final side = await service.createTask(
        name: '整理书桌',
        type: TaskType.side,
        reward: const AttributeDelta(health: 1, discipline: 0, charm: 0),
      );

      final mainFail =
          await service.failTask(mainline, now: DateTime(2026, 6, 5, 20));
      final sideFail = await service.failTask(side, now: DateTime(2026, 6, 5, 20));
      expect(mainFail!.penalty, AttributeDelta.zero);
      expect(sideFail!.taskType, TaskType.side);

      final c = (await service.character())!;
      expect(c.xp, 0); // 失败不发经验
      expect(c.health, 50); // 也不扣属性
      expect(c.discipline, 50);

      // 任务没被删除，只是离开进行中列表
      expect(await service.tasksByType(TaskType.mainline), isEmpty);
      expect(await service.tasksByType(TaskType.side), isEmpty);
      expect(await service.tasksByType(TaskType.mainline, failed: true),
          hasLength(1));
      expect(await service.tasksByType(TaskType.side, failed: true), hasLength(1));
      expect(await service.completionLog(), isEmpty);

      // 终态：不能完成、不能重复判失败；子项也不再能勾选完成
      expect(await service.completeTask(mainline, now: DateTime(2026, 6, 6, 9)), isNull);
      expect(await service.failTask(side, now: DateTime(2026, 6, 6, 9)), isNull);
      final sub = (await service.subtasksOf(mainline)).single;
      expect(await service.completeSubtask(sub.id, now: DateTime(2026, 6, 6, 9)),
          isNull);
    });

    test('已完成的任务不能再判失败', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(
        name: '整理书桌',
        type: TaskType.side,
      );
      await service.completeTask(id, now: DateTime(2026, 6, 5, 10));
      expect(await service.failTask(id, now: DateTime(2026, 6, 5, 11)), isNull);
      expect(await service.tasksByType(TaskType.side, completed: true),
          hasLength(1));
    });

    test('每日任务历史：按日期分组、按日期倒序可查', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      final id = await service.createTask(
        name: '早起喝水',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 0, discipline: 1, charm: 0),
        now: DateTime(2026, 6, 1, 8),
      );
      await service.completeTask(id, now: DateTime(2026, 6, 4, 9));
      await service.failTask(id, now: DateTime(2026, 6, 5, 20));

      final logs = await service.dailyLogs();
      expect(logs, hasLength(2));
      expect(logs.first.date, '2026-06-05'); // 倒序：最新在前
      expect(logs.first.status, DailyTaskStatus.failed);
      expect(logs.last.date, '2026-06-04');
      expect(logs.last.status, DailyTaskStatus.completed);
      expect(await service.dailyLogsOn(DateTime(2026, 6, 4)), hasLength(1));
      expect(await service.dailyLogsOn(DateTime(2026, 6, 3)), isEmpty);
    });
  });

  group('笔记（不发经验，ADR-0006）', () {
    test('写任何长度的笔记都不发经验、不改属性', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      const long = '今天读完了第一章，感觉很有收获，继续加油。'; // >20 字
      await service.addNote(long, now: DateTime(2026, 6, 5, 20));
      await service.addNote('短笔记', now: DateTime(2026, 6, 5, 21));

      final c = (await service.character())!;
      expect(c.xp, 0);
      expect(c.health, 50);
      expect(c.discipline, 50);
      expect(c.charm, 50);
    });

    test('连写多天、编辑与删除都不产生经验', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      const long = '今天读完了第一章，感觉很有收获，继续加油。';
      final id = await service.addNote(long, now: DateTime(2026, 6, 5, 20));
      await service.updateNote(id, '$long 补充一句。');
      await service.updateNote(id, '短');
      await service.deleteNote(id);
      for (var i = 0; i < 5; i++) {
        await service.addNote(long, now: DateTime(2026, 6, 6 + i, 20));
      }
      expect((await service.character())!.xp, 0);
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

  group('备份（JSON 导出/导入，ADR-0001）', () {
    test('全量往返：导出 → 新库导入 → 数据一致', () async {
      await service.createCharacter(name: '小明', age: 18, gender: Gender.male);
      // 主线 + 子项（完成一个）
      final mainline = await service.createTask(
          name: '读完一本书', type: TaskType.mainline);
      final s1 = await service.createSubtask(taskId: mainline, name: '第一章');
      await service.createSubtask(taskId: mainline, name: '第二章');
      await service.completeSubtask(s1, now: DateTime(2026, 6, 1, 10));
      // 支线并完成（产生 +20 完成历史）
      final side = await service.createTask(
          name: '整理书桌',
          type: TaskType.side,
          reward: const AttributeDelta(health: 1, discipline: 0, charm: 0));
      await service.completeTask(side, now: DateTime(2026, 6, 2, 10));
      // 每日任务（已完成当天）
      final daily = await service.createTask(
          name: '早起喝水', type: TaskType.daily);
      await service.completeTask(daily, now: DateTime(2026, 6, 3, 9));
      // 一个失败的支线 + 一条每日任务失败历史
      final failedSide =
          await service.createTask(name: '写周报', type: TaskType.side);
      await service.failTask(failedSide, now: DateTime(2026, 6, 3, 18));
      await service.createTask(
        name: '散步 10 分钟',
        type: TaskType.daily,
        reward: const AttributeDelta(health: 2, discipline: 0, charm: 0),
        now: DateTime(2026, 6, 1, 8),
      );
      await service.settleDay(now: DateTime(2026, 6, 4, 0, 5)); // 6/3 未完成
      // 习惯打卡 3 天
      final habit = await service.createHabit(
          name: '早睡打卡', frequencyType: HabitFrequency.daily);
      for (final day in [1, 2, 3]) {
        await service.checkInHabit(habit, now: DateTime(2026, 6, day, 22));
      }
      // 两篇笔记
      await service.addNote('今天读完了第一章，感觉很有收获，继续加油。',
          now: DateTime(2026, 6, 1, 20));
      await service.addNote('第二章也读完了，进度不错。',
          now: DateTime(2026, 6, 2, 20));

      final json = await service.exportJson();

      final db2 = AppDatabase(NativeDatabase.memory());
      final service2 = GameService(db2);
      await service2.importJson(json, now: DateTime(2026, 6, 5));

      final c1 = (await service.character())!;
      final c2 = (await service2.character())!;
      expect(c2.name, c1.name);
      expect(c2.age, c1.age);
      expect(c2.gender, c1.gender);
      expect(c2.xp, c1.xp);
      expect(c2.health, c1.health);
      expect(c2.discipline, c1.discipline);
      expect(c2.charm, c1.charm);

      final tasks2 = await service2.dailyTasks();
      expect(tasks2, hasLength(2)); // 早起喝水 + 散步 10 分钟
      expect(await service2.tasksByType(TaskType.mainline, completed: false),
          hasLength(1));
      expect(await service2.tasksByType(TaskType.side, completed: true),
          hasLength(1));
      final failed2 = await service2.tasksByType(TaskType.side, failed: true);
      expect(failed2, hasLength(1));
      expect(failed2.single.name, '写周报');
      expect(failed2.single.failedAt, isNotNull);

      // 新库 id 重排，用主线任务行取 id
      final mainline2 =
          (await service2.tasksByType(TaskType.mainline, completed: false))
              .single;
      final subs = await service2.subtasksOf(mainline2.id);
      expect(subs, hasLength(2));
      expect(subs.where((s) => s.isDone), hasLength(1));

      final log2 = await service2.completionLog();
      expect(log2, hasLength(2)); // 支线 + 每日任务
      final sideLog = log2.singleWhere((l) => l.taskType == TaskType.side);
      expect(sideLog.xpGained, sideQuestXp);
      expect(sideLog.healthGained, 1);

      // 每日任务历史（完成 + 结算判失败）一并恢复
      final dailyLogs2 = await service2.dailyLogs();
      expect(dailyLogs2, hasLength(2));
      expect(
        dailyLogs2.where((l) => l.status == DailyTaskStatus.failed).single.taskName,
        '散步 10 分钟',
      );
      expect(await service2.dailyLogsOn(DateTime(2026, 6, 3)), hasLength(2));

      final habit2 = (await service2.habits()).single;
      expect(await service2.checkinDatesOf(habit2.id), hasLength(3));
      final status =
          await service2.habitStatus(habit2.id, now: DateTime(2026, 6, 3));
      expect(status.streak, 3);
      expect(status.cumulative, 3);

      final notes2 = await service2.notesForDay(DateTime(2026, 6, 1));
      expect(notes2, hasLength(1));
      expect(notes2.single.content, '今天读完了第一章，感觉很有收获，继续加油。');

      // 恢复当天不再触发每日结算
      final settlement =
          await service2.settleDay(now: DateTime(2026, 6, 5, 0, 5));
      expect(settlement, isNull);

      await db2.close();
    });

    test('错误版本拒绝导入', () async {
      await expectLater(
        service.importJson('{"version": 99}', now: DateTime(2026, 6, 5)),
        throwsFormatException,
      );
    });
  });
}
