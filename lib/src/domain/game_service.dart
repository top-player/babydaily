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
              (await undoneSubtasks.getSingle())!.read(db.subtasks.id.count())!;
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
          (await undone.getSingle())!.read(db.subtasks.id.count())!;

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
