/// 游戏用例：主角、任务、习惯、笔记与每日结算的统一入口。
///
/// 所有写操作都通过 drift 事务保证一致；规则常量与纯计算
/// 分别位于 xp_economy / streak / milestone / note_xp / settlement / attributes。
library;

import 'package:drift/drift.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/milestone.dart';
import 'package:babydaily/src/domain/note_xp.dart';
import 'package:babydaily/src/domain/settlement.dart';
import 'package:babydaily/src/domain/streak.dart';
import 'package:babydaily/src/domain/xp_economy.dart';

/// 本地日期字符串 'yyyy-MM-dd'。
String dateString(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

/// 主角快照（等级/称号由 xp 派生，不落库）。
class CharacterSnapshot {
  const CharacterSnapshot({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.xp,
    required this.health,
    required this.discipline,
    required this.charm,
  });

  final int id;
  final String name;
  final int age;
  final Gender gender;
  final int xp;
  final int health;
  final int discipline;
  final int charm;

  Attributes get attributes =>
      Attributes(health: health, discipline: discipline, charm: charm);
}

/// 一次成长反馈：发放的经验与属性、是否升级。
class GrowthOutcome {
  const GrowthOutcome({
    required this.xpGained,
    required this.attrGain,
    required this.levelBefore,
    required this.levelAfter,
    required this.leveledUp,
    this.newTitle,
  });

  final int xpGained;
  final AttributeDelta attrGain;
  final int levelBefore;
  final int levelAfter;
  final bool leveledUp;
  final String? newTitle;
}

/// 一次习惯打卡的反馈。
class CheckinOutcome extends GrowthOutcome {
  const CheckinOutcome({
    required super.xpGained,
    required super.attrGain,
    required super.levelBefore,
    required super.levelAfter,
    required super.leveledUp,
    super.newTitle,
    required this.streak,
    required this.milestones,
  });

  /// 打卡后的连续天数。
  final int streak;
  final List<MilestoneReached> milestones;
}

/// 一次每日结算的结果。
class SettlementResult {
  const SettlementResult({
    required this.totalPenalty,
    required this.penalizedTaskNames,
  });

  /// 实际扣除的属性（受下限 0 截断）。
  final AttributeDelta totalPenalty;
  final List<String> penalizedTaskNames;
}

/// 一次写笔记的结果。
class NoteResult {
  const NoteResult({
    required this.noteId,
    required this.xpGained,
    required this.noteStreak,
  });

  final int noteId;
  final int xpGained;
  final int noteStreak;
}

/// 习惯展示状态（连续/累计/今日/打卡日期）。
class HabitStatus {
  const HabitStatus({
    required this.streak,
    required this.cumulative,
    required this.checkedToday,
    required this.checkinDates,
  });

  final int streak;
  final int cumulative;
  final bool checkedToday;
  final List<String> checkinDates;
}

class GameService {
  GameService(this.db);

  final AppDatabase db;

  // ---- 主角 ----

  Future<CharacterSnapshot?> character() async {
    final row = await (db.select(db.characters)..where((c) => c.id.equals(1)))
        .getSingleOrNull();
    if (row == null) return null;
    return _snapshot(row);
  }

  Future<void> createCharacter({
    required String name,
    required int age,
    required Gender gender,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    await db.into(db.characters).insertOnConflictUpdate(
          CharactersCompanion.insert(
            id: const Value(1),
            name: name,
            age: age,
            gender: gender.name,
            xp: const Value(0),
            health: Value(Attributes.starting.health),
            discipline: Value(Attributes.starting.discipline),
            charm: Value(Attributes.starting.charm),
            createdAt: ts,
            updatedAt: ts,
          ),
        );
  }

  CharacterSnapshot _snapshot(Character row) => CharacterSnapshot(
        id: row.id,
        name: row.name,
        age: row.age,
        gender: Gender.values.byName(row.gender),
        xp: row.xp,
        health: row.health,
        discipline: row.discipline,
        charm: row.charm,
      );

  /// 更新主角资料（姓名/年龄/性别）。
  Future<void> updateCharacterProfile({
    required String name,
    required int age,
    required Gender gender,
  }) async {
    await (db.update(db.characters)..where((c) => c.id.equals(1))).write(
      CharactersCompanion(
        name: Value(name),
        age: Value(age),
        gender: Value(gender.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---- 设置 ----

  Future<Scene?> getScene() async {
    final row = await (db.select(db.settings)
          ..where((s) => s.key.equals('scene')))
        .getSingleOrNull();
    if (row == null) return null;
    return Scene.values.byName(row.value);
  }

  Future<void> setScene(Scene scene) async {
    await db.into(db.settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: 'scene', value: scene.name));
  }

  Future<void> setSetting(String key, String value) async {
    await db.into(db.settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: value));
  }

  // ---- 任务 ----

  Future<int> createTask({
    required String name,
    String description = '',
    required TaskType type,
    AttributeDelta reward = AttributeDelta.zero,
    int sortOrder = 0,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    return db.into(db.tasks).insert(TasksCompanion.insert(
          name: name,
          description: Value(description),
          type: type,
          rewardHealth: Value(reward.health),
          rewardDiscipline: Value(reward.discipline),
          rewardCharm: Value(reward.charm),
          sortOrder: Value(sortOrder),
          createdAt: ts,
        ));
  }

  /// 完成任务：按类型发放固定经验与配置属性；重复完成返回 null。
  Future<GrowthOutcome?> completeTask(int taskId, {required DateTime now}) {
    return db.transaction(() async {
      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();
      if (task == null) return null;

      final reward = AttributeDelta(
        health: task.rewardHealth,
        discipline: task.rewardDiscipline,
        charm: task.rewardCharm,
      );

      int xpGain;
      switch (task.type) {
        case TaskType.daily:
          if (task.completedOn == dateString(now)) return null;
          xpGain = dailyTaskXp;
          await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
            TasksCompanion(completedOn: Value(dateString(now))),
          );
        case TaskType.mainline:
          if (task.isCompleted) return null;
          final undoneSubtasks = db.selectOnly(db.subtasks)
            ..addColumns([db.subtasks.id.count()])
            ..where(db.subtasks.taskId.equals(taskId) &
                db.subtasks.isDone.equals(false));
          final undone =
              (await undoneSubtasks.getSingle()).read(db.subtasks.id.count())!;
          if (undone > 0) return null; // 必须先完成全部子项
          xpGain = mainlineXp;
          await _markTaskCompleted(taskId, now);
        case TaskType.side:
          if (task.isCompleted) return null;
          xpGain = sideQuestXp;
          await _markTaskCompleted(taskId, now);
      }

      final outcome = await _grant(xp: xpGain, attrs: reward);
      await db.into(db.taskCompletions).insert(TaskCompletionsCompanion.insert(
            taskId: Value(task.id),
            taskName: task.name,
            taskType: task.type,
            xpGained: xpGain,
            healthGained: reward.health,
            disciplineGained: reward.discipline,
            charmGained: reward.charm,
            completedAt: now,
          ));
      return outcome;
    });
  }

  Future<void> _markTaskCompleted(int taskId, DateTime now) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        isCompleted: const Value(true),
        completedAt: Value(now),
      ),
    );
  }

  // ---- 任务子项 ----

  Future<int> createSubtask({
    required int taskId,
    required String name,
    int sortOrder = 0,
    DateTime? now,
  }) async {
    return db.into(db.subtasks).insert(SubtasksCompanion.insert(
          taskId: taskId,
          name: name,
          sortOrder: Value(sortOrder),
          createdAt: now ?? DateTime.now(),
        ));
  }

  /// 完成任务子项：子项本身不发奖；若为主线最后一个未完成子项，
  /// 主线自动完成并发放主线完成奖励与固定经验。
  Future<GrowthOutcome?> completeSubtask(int subtaskId,
      {required DateTime now}) {
    return db.transaction(() async {
      final sub = await (db.select(db.subtasks)
            ..where((s) => s.id.equals(subtaskId)))
          .getSingleOrNull();
      if (sub == null || sub.isDone) return null;

      final task = await (db.select(db.tasks)
            ..where((t) => t.id.equals(sub.taskId)))
          .getSingleOrNull();
      if (task == null || task.isCompleted || task.type != TaskType.mainline) {
        return null;
      }

      await (db.update(db.subtasks)..where((s) => s.id.equals(subtaskId)))
          .write(const SubtasksCompanion(isDone: Value(true)));

      final undone = db.selectOnly(db.subtasks)
        ..addColumns([db.subtasks.id.count()])
        ..where(db.subtasks.taskId.equals(task.id) &
            db.subtasks.isDone.equals(false));
      final remaining =
          (await undone.getSingle()).read(db.subtasks.id.count())!;

      if (remaining > 0) {
        final row = await (db.select(db.characters)
              ..where((c) => c.id.equals(1)))
            .getSingle();
        final level = levelForXp(row.xp);
        return GrowthOutcome(
          xpGained: subtaskXp,
          attrGain: AttributeDelta.zero,
          levelBefore: level,
          levelAfter: level,
          leveledUp: false,
        );
      }

      // 最后一个子项：主线自动完成
      final reward = AttributeDelta(
        health: task.rewardHealth,
        discipline: task.rewardDiscipline,
        charm: task.rewardCharm,
      );
      await _markTaskCompleted(task.id, now);
      final outcome = await _grant(xp: mainlineXp, attrs: reward);
      await db.into(db.taskCompletions).insert(TaskCompletionsCompanion.insert(
            taskId: Value(task.id),
            taskName: task.name,
            taskType: task.type,
            xpGained: mainlineXp,
            healthGained: reward.health,
            disciplineGained: reward.discipline,
            charmGained: reward.charm,
            completedAt: now,
          ));
      return outcome;
    });
  }

  Future<List<Subtask>> subtasksOf(int taskId) async {
    final query = db.select(db.subtasks)
      ..where((s) => s.taskId.equals(taskId))
      ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]);
    return query.get();
  }

  /// 某类型的任务（主线/支线按是否已完成过滤；每日任务用 dailyTasks）。
  Future<List<Task>> tasksByType(TaskType type, {required bool completed}) async {
    final query = db.select(db.tasks)
      ..where((t) =>
          t.type.equalsValue(type) & t.isCompleted.equals(completed))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  /// 全部每日任务（按顺序）。
  Future<List<Task>> dailyTasks() async {
    final query = db.select(db.tasks)
      ..where((t) => t.type.equalsValue(TaskType.daily))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  /// 更新任务名称/描述/奖励（历史不受影响）。
  Future<void> updateTask({
    required int id,
    required String name,
    String description = '',
    AttributeDelta reward = AttributeDelta.zero,
  }) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        name: Value(name),
        description: Value(description),
        rewardHealth: Value(reward.health),
        rewardDiscipline: Value(reward.discipline),
        rewardCharm: Value(reward.charm),
      ),
    );
  }

  /// 删除单个子项。
  Future<void> deleteSubtask(int subtaskId) async {
    await (db.delete(db.subtasks)..where((s) => s.id.equals(subtaskId))).go();
  }

  /// 删除任务：子项级联删除；完成历史保留（快照名称）。
  Future<void> deleteTask(int taskId) async {
    await (db.delete(db.tasks)..where((t) => t.id.equals(taskId))).go();
  }

  /// 完成历史（快照，删除任务后保留）。
  Future<List<TaskCompletion>> completionLog() async {
    final query = db.select(db.taskCompletions)
      ..orderBy([
        (t) => OrderingTerm.desc(t.completedAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.get();
  }

  // ---- 习惯 ----

  Future<int> createHabit({
    required String name,
    String description = '',
    required HabitFrequency frequencyType,
    int timesPerWeek = 1,
    AttributeDelta reward = const AttributeDelta(
        health: 0, discipline: 1, charm: 0),
    int sortOrder = 0,
    DateTime? now,
  }) async {
    return db.into(db.habits).insert(HabitsCompanion.insert(
          name: name,
          description: Value(description),
          frequencyType: frequencyType,
          timesPerWeek: Value(timesPerWeek),
          rewardHealth: Value(reward.health),
          rewardDiscipline: Value(reward.discipline),
          rewardCharm: Value(reward.charm),
          sortOrder: Value(sortOrder),
          createdAt: now ?? DateTime.now(),
        ));
  }

  /// 打卡：同一习惯每天最多一次；打卡 +5 固定经验 + 配置属性；
  /// 每日习惯跨越 10/20/30 天里程碑时额外发放一次性经验。
  Future<CheckinOutcome?> checkInHabit(int habitId, {required DateTime now}) {
    return db.transaction(() async {
      final habit = await (db.select(db.habits)
            ..where((h) => h.id.equals(habitId)))
          .getSingleOrNull();
      if (habit == null || habit.isArchived) return null;

      final today = dateString(now);
      final existing = await (db.select(db.checkins)
            ..where((c) => c.habitId.equals(habitId)))
          .get();
      if (existing.any((c) => c.date == today)) return null;

      await db.into(db.checkins).insert(CheckinsCompanion.insert(
            habitId: habitId,
            date: today,
            createdAt: now,
          ));

      final reward = AttributeDelta(
        health: habit.rewardHealth,
        discipline: habit.rewardDiscipline,
        charm: habit.rewardCharm,
      );

      final allDates = {for (final c in existing) _parseDate(c.date), dateOnly(now)};
      // 规则变更后：连续计数只统计变更日（含）以来的打卡
      final afterRule = habit.ruleChangedAt == null
          ? allDates
          : allDates
              .where((d) => !d.isBefore(dateOnly(habit.ruleChangedAt!)))
              .toSet();
      final milestones = <MilestoneReached>[];
      int streak;
      if (habit.frequencyType == HabitFrequency.daily) {
        final previous =
            currentDailyStreak(afterRule.difference({dateOnly(now)}), now);
        streak = currentDailyStreak(afterRule, now);
        final granted = await (db.select(db.habitMilestones)
              ..where((m) => m.habitId.equals(habitId)))
            .get();
        milestones.addAll(newlyReachedMilestones(
          previousStreak: previous,
          newStreak: streak,
          alreadyGranted: {for (final m in granted) m.days},
        ));
        for (final m in milestones) {
          await db.into(db.habitMilestones).insert(
              HabitMilestonesCompanion.insert(
                  habitId: habitId, days: m.days, grantedAt: now));
        }
      } else {
        streak = currentWeeklyStreak(afterRule, habit.timesPerWeek, now);
      }

      final milestoneXp =
          milestones.fold<int>(0, (sum, m) => sum + m.xp);
      final growth = await _grant(
        xp: habitCheckinXp + milestoneXp,
        attrs: reward,
      );
      return CheckinOutcome(
        xpGained: growth.xpGained,
        attrGain: growth.attrGain,
        levelBefore: growth.levelBefore,
        levelAfter: growth.levelAfter,
        leveledUp: growth.leveledUp,
        newTitle: growth.newTitle,
        streak: streak,
        milestones: milestones,
      );
    });
  }

  /// 某习惯的全部打卡日期（'yyyy-MM-dd'，升序）。
  Future<List<String>> checkinDatesOf(int habitId) async {
    final query = db.select(db.checkins)
      ..where((c) => c.habitId.equals(habitId))
      ..orderBy([(c) => OrderingTerm.asc(c.date)]);
    final rows = await query.get();
    return [for (final r in rows) r.date];
  }

  /// 习惯列表（默认不含已归档）。
  Future<List<Habit>> habits({bool includeArchived = false}) async {
    final query = db.select(db.habits)
      ..where((h) =>
          includeArchived ? const Constant(true) : h.isArchived.equals(false))
      ..orderBy([
        (h) => OrderingTerm.asc(h.isArchived),
        (h) => OrderingTerm.asc(h.sortOrder),
        (h) => OrderingTerm.asc(h.id),
      ]);
    return query.get();
  }

  Future<Habit?> habitById(int id) async {
    return (db.select(db.habits)..where((h) => h.id.equals(id)))
        .getSingleOrNull();
  }

  /// 某习惯的展示状态：连续、累计、今日是否已打卡、全部打卡日期。
  Future<HabitStatus> habitStatus(int habitId, {required DateTime now}) async {
    final habit = await habitById(habitId);
    if (habit == null) {
      return HabitStatus(
          streak: 0, cumulative: 0, checkedToday: false, checkinDates: const []);
    }
    final dates = await checkinDatesOf(habitId);
    final afterRule = habit.ruleChangedAt == null
        ? dates.map(_parseDate).toSet()
        : dates
            .map(_parseDate)
            .where((d) => !d.isBefore(dateOnly(habit.ruleChangedAt!)))
            .toSet();
    final streak = habit.frequencyType == HabitFrequency.daily
        ? currentDailyStreak(afterRule, now)
        : currentWeeklyStreak(afterRule, habit.timesPerWeek, now);
    return HabitStatus(
      streak: streak,
      cumulative: dates.length,
      checkedToday: dates.contains(dateString(now)),
      checkinDates: dates,
    );
  }

  /// 更新习惯；频率或每周次数变化时记录 [ruleChangedAt]（连续重新计算）。
  Future<void> updateHabit({
    required int id,
    required String name,
    String description = '',
    required HabitFrequency frequencyType,
    required int timesPerWeek,
    required AttributeDelta reward,
    required DateTime now,
  }) async {
    final habit = await habitById(id);
    if (habit == null) return;
    final ruleChanged = habit.frequencyType != frequencyType ||
        (frequencyType == HabitFrequency.weekly &&
            habit.timesPerWeek != timesPerWeek);
    await (db.update(db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        name: Value(name),
        description: Value(description),
        frequencyType: Value(frequencyType),
        timesPerWeek: Value(timesPerWeek),
        rewardHealth: Value(reward.health),
        rewardDiscipline: Value(reward.discipline),
        rewardCharm: Value(reward.charm),
        ruleChangedAt:
            Value(ruleChanged ? now : habit.ruleChangedAt),
      ),
    );
  }

  /// 归档/取消归档：归档后保留历史与日历，只是停止打卡。
  Future<void> setHabitArchived(int id, bool archived) async {
    await (db.update(db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(isArchived: Value(archived)),
    );
  }

  /// 删除习惯：打卡记录与里程碑随之删除（二次确认在 UI 层）。
  Future<void> deleteHabit(int id) async {
    await (db.delete(db.habits)..where((h) => h.id.equals(id))).go();
  }

  DateTime _parseDate(String s) {
    final parts = s.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  // ---- 每日结算 ----

  /// 0 点结算（ADR-0004）：结算 [now] 的前一天。
  ///
  /// 前一天未完成的每日任务扣除其配置属性（下限 0、不扣经验）；
  /// 全部每日任务重置为未完成。同一天重复调用返回 null（幂等）。
  Future<SettlementResult?> settleDay({required DateTime now}) {
    return db.transaction(() async {
      final today = dateString(now);
      final last = await (db.select(db.settings)
            ..where((s) => s.key.equals('last_settled_on')))
          .getSingleOrNull();
      if (last?.value == today) return null;

      final yesterday = dateString(now.subtract(const Duration(days: 1)));
      final dailyTasks = await (db.select(db.tasks)
            ..where((t) => t.type.equalsValue(TaskType.daily)))
          .get();
      final missed = [
        for (final t in dailyTasks)
          if (t.completedOn != yesterday) t,
      ];

      final row = await (db.select(db.characters)
            ..where((c) => c.id.equals(1)))
          .getSingleOrNull();
      if (row == null) {
        // 尚无主角：只记录结算标记，不处理
        await db.into(db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(key: 'last_settled_on', value: today));
        return SettlementResult(
            totalPenalty: AttributeDelta.zero, penalizedTaskNames: const []);
      }
      final current = Attributes(
        health: row.health,
        discipline: row.discipline,
        charm: row.charm,
      );
      final outcome = settleDailyTasks(current: current, penalties: [
        for (final t in missed)
          AttributeDelta(
            health: t.rewardHealth,
            discipline: t.rewardDiscipline,
            charm: t.rewardCharm,
          ),
      ]);

      await (db.update(db.characters)..where((c) => c.id.equals(1))).write(
        CharactersCompanion(
          health: Value(outcome.after.health),
          discipline: Value(outcome.after.discipline),
          charm: Value(outcome.after.charm),
          updatedAt: Value(now),
        ),
      );

      // 全部每日任务重置为未完成
      for (final t in dailyTasks) {
        if (t.completedOn != null) {
          await (db.update(db.tasks)..where((x) => x.id.equals(t.id))).write(
            const TasksCompanion(completedOn: Value(null)),
          );
        }
      }

      await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: 'last_settled_on', value: today));

      return SettlementResult(
        totalPenalty: outcome.totalPenalty,
        penalizedTaskNames: [for (final t in missed) t.name],
      );
    });
  }

  // ---- 笔记 ----

  Future<NoteResult> addNote(String content, {required DateTime now}) async {
    final id = await db.into(db.notes).insert(NotesCompanion.insert(
          content: content,
          createdAt: now,
          updatedAt: now,
        ));
    return _grantNoteXpIfQualified(
      qualifying: content.trim().length >= 20,
      now: now,
      noteId: id,
      excludeNoteId: id,
    );
  }

  Future<NoteResult> updateNote(int noteId, String content) async {
    final note = await (db.select(db.notes)..where((n) => n.id.equals(noteId)))
        .getSingleOrNull();
    if (note == null) {
      return NoteResult(noteId: noteId, xpGained: 0, noteStreak: 0);
    }
    final updatedAt = DateTime.now();
    await (db.update(db.notes)..where((n) => n.id.equals(noteId))).write(
      NotesCompanion(
        content: Value(content),
        updatedAt: Value(updatedAt),
      ),
    );
    return _grantNoteXpIfQualified(
      qualifying: content.trim().length >= 20,
      // 经验归属笔记的创建日，而不是编辑日
      now: note.createdAt,
      noteId: noteId,
      excludeNoteId: noteId,
    );
  }

  /// 删除笔记：不回追已发放的经验（ADR-0003）。
  Future<void> deleteNote(int noteId) async {
    await (db.delete(db.notes)..where((n) => n.id.equals(noteId))).go();
  }

  /// 当天首篇合格（≥20 字）笔记发放经验：10 + min(连续天数-1, 5)。
  Future<NoteResult> _grantNoteXpIfQualified({
    required bool qualifying,
    required DateTime now,
    required int noteId,
    required int? excludeNoteId,
  }) async {
    final char = await character();
    if (!qualifying || char == null) {
      return NoteResult(noteId: noteId, xpGained: 0, noteStreak: 0);
    }

    // 今天是否已存在其他合格笔记（决定今天是否已经发过）
    final today = dateOnly(now);
    final allNotes = await db.select(db.notes).get();
    final hadQualifyingToday = allNotes.any((n) =>
        n.id != excludeNoteId &&
        dateOnly(n.createdAt) == today &&
        n.content.trim().length >= 20);

    final qualifyingDays = <DateTime>{
      for (final n in allNotes)
        if (n.content.trim().length >= 20) dateOnly(n.createdAt),
    };
    final streak = noteStreakDays(qualifyingDays, now);

    if (hadQualifyingToday) {
      return NoteResult(noteId: noteId, xpGained: 0, noteStreak: streak);
    }

    final growth = await _grant(xp: noteXpForStreak(streak), attrs: AttributeDelta.zero);
    return NoteResult(
      noteId: noteId,
      xpGained: growth.xpGained,
      noteStreak: streak,
    );
  }

  /// 某天的全部笔记（按创建时间升序）。
  Future<List<Note>> notesForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final query = db.select(db.notes)
      ..where((n) => n.createdAt.isBiggerOrEqualValue(start) & n.createdAt.isSmallerThanValue(end))
      ..orderBy([(n) => OrderingTerm.asc(n.createdAt)]);
    return query.get();
  }

  /// 全文关键词搜索（LIKE 子串匹配，按日期倒序）。
  Future<List<Note>> searchNotes(String keyword) async {
    if (keyword.trim().isEmpty) return const [];
    final query = db.select(db.notes)
      ..where((n) => n.content.like('%$keyword%'))
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
    return query.get();
  }

  // ---- 成长发放 ----

  /// 给主角发放经验与属性，返回成长反馈（含升级判定）。
  Future<GrowthOutcome> _grant({
    required int xp,
    required AttributeDelta attrs,
  }) async {
    final row = await (db.select(db.characters)..where((c) => c.id.equals(1)))
        .getSingle();
    final levelBefore = levelForXp(row.xp);
    final newXp = row.xp + xp;
    final levelAfter = levelForXp(newXp);
    final attrsAfter = Attributes(
      health: row.health,
      discipline: row.discipline,
      charm: row.charm,
    ).applyGain(attrs);

    await (db.update(db.characters)..where((c) => c.id.equals(1))).write(
      CharactersCompanion(
        xp: Value(newXp),
        health: Value(attrsAfter.health),
        discipline: Value(attrsAfter.discipline),
        charm: Value(attrsAfter.charm),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return GrowthOutcome(
      xpGained: xp,
      attrGain: attrs,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      leveledUp: levelAfter > levelBefore,
      newTitle: levelAfter > levelBefore ? titleForLevel(levelAfter) : null,
    );
  }
}
