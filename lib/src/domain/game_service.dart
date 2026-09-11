/// 游戏用例：主角、任务、习惯、笔记与每日结算的统一入口。
///
/// 所有写操作都通过 drift 事务保证一致；规则常量与纯计算
/// 分别位于 xp_economy / streak / milestone / settlement / attributes。
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/attributes.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/milestone.dart';
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

/// 一次任务失败的结果。
class TaskFailOutcome {
  const TaskFailOutcome({
    required this.taskName,
    required this.taskType,
    required this.penalty,
  });

  final String taskName;
  final TaskType taskType;

  /// 实际扣除的属性：每日任务判失败时立即扣除（下限 0 截断后的真实值）；
  /// 主线/支线失败不涉及属性，恒为 [AttributeDelta.zero]。
  final AttributeDelta penalty;
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

  // ---- 备份（ADR-0001：JSON 导出/导入） ----

  /// 全量导出为 JSON 字符串。
  Future<String> exportJson() async {
    String? iso(DateTime? d) => d?.toIso8601String();
    final characterRow =
        await db.select(db.characters).getSingleOrNull();
    final data = <String, dynamic>{
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'character': characterRow == null
          ? null
          : {
              'name': characterRow.name,
              'age': characterRow.age,
              'gender': characterRow.gender,
              'xp': characterRow.xp,
              'health': characterRow.health,
              'discipline': characterRow.discipline,
              'charm': characterRow.charm,
              'created_at': iso(characterRow.createdAt),
              'updated_at': iso(characterRow.updatedAt),
            },
      'tasks': [
        for (final t in await db.select(db.tasks).get())
          {
            'name': t.name,
            'description': t.description,
            'type': t.type.name,
            'reward_health': t.rewardHealth,
            'reward_discipline': t.rewardDiscipline,
            'reward_charm': t.rewardCharm,
            'is_completed': t.isCompleted,
            'completed_at': iso(t.completedAt),
            'is_failed': t.isFailed,
            'failed_at': iso(t.failedAt),
            'completed_on': t.completedOn,
            'sort_order': t.sortOrder,
            'created_at': iso(t.createdAt),
          }
      ],
      'subtasks': [
        for (final s in await db.select(db.subtasks).get())
          {
            'task_name': (await (db.select(db.tasks)
                        ..where((t) => t.id.equals(s.taskId)))
                    .getSingleOrNull())
                ?.name,
            'name': s.name,
            'is_done': s.isDone,
            'sort_order': s.sortOrder,
            'created_at': iso(s.createdAt),
          }
      ],
      'task_completions': [
        for (final c in await db.select(db.taskCompletions).get())
          {
            'task_name': c.taskName,
            'task_type': c.taskType.name,
            'xp_gained': c.xpGained,
            'health_gained': c.healthGained,
            'discipline_gained': c.disciplineGained,
            'charm_gained': c.charmGained,
            'completed_at': iso(c.completedAt),
          }
      ],
      'daily_task_logs': [
        for (final l in await db.select(db.dailyTaskLogs).get())
          {
            'task_name': l.taskName,
            'date': l.date,
            'status': l.status.name,
            'penalty_health': l.penaltyHealth,
            'penalty_discipline': l.penaltyDiscipline,
            'penalty_charm': l.penaltyCharm,
            'created_at': iso(l.createdAt),
          }
      ],
      'habits': [
        for (final h in await db.select(db.habits).get())
          {
            'name': h.name,
            'description': h.description,
            'frequency_type': h.frequencyType.name,
            'times_per_week': h.timesPerWeek,
            'reward_health': h.rewardHealth,
            'reward_discipline': h.rewardDiscipline,
            'reward_charm': h.rewardCharm,
            'is_archived': h.isArchived,
            'rule_changed_at': iso(h.ruleChangedAt),
            'sort_order': h.sortOrder,
            'created_at': iso(h.createdAt),
          }
      ],
      'checkins': [
        for (final c in await db.select(db.checkins).get())
          {
            'habit_name': (await (db.select(db.habits)
                        ..where((h) => h.id.equals(c.habitId)))
                    .getSingleOrNull())
                ?.name,
            'date': c.date,
            'created_at': iso(c.createdAt),
          }
      ],
      'habit_milestones': [
        for (final m in await db.select(db.habitMilestones).get())
          {
            'habit_name': (await (db.select(db.habits)
                        ..where((h) => h.id.equals(m.habitId)))
                    .getSingleOrNull())
                ?.name,
            'days': m.days,
            'granted_at': iso(m.grantedAt),
          }
      ],
      'notes': [
        for (final n in await db.select(db.notes).get())
          {
            'content': n.content,
            'created_at': iso(n.createdAt),
            'updated_at': iso(n.updatedAt),
          }
      ],
      'settings': {
        for (final s in await db.select(db.settings).get()) s.key: s.value,
      },
    };
    return jsonEncode(data);
  }

  /// 从 JSON 导入：清空当前数据后恢复备份内容（事务保证原子性）。
  ///
  /// 关联通过名称还原（任务名/习惯名），导入后当天不再触发每日结算。
  /// 版本 1 的快照按增量字段读取：旧备份没有失败/每日历史的键时按默认值恢复，
  /// 因此新旧备份都能导入。
  Future<void> importJson(String json, {required DateTime now}) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    if (data['version'] != 1) {
      throw const FormatException('不支持的备份版本');
    }
    await db.transaction(() async {
      // FK 顺序清空
      await db.delete(db.subtasks).go();
      await db.delete(db.checkins).go();
      await db.delete(db.habitMilestones).go();
      await db.delete(db.taskCompletions).go();
      await db.delete(db.dailyTaskLogs).go();
      await db.delete(db.tasks).go();
      await db.delete(db.habits).go();
      await db.delete(db.notes).go();
      await db.delete(db.settings).go();
      await db.delete(db.characters).go();

      DateTime? parseIso(dynamic v) =>
          v == null ? null : DateTime.parse(v as String);
      final taskNameToId = <String, int>{};
      final habitNameToId = <String, int>{};

      final character = data['character'] as Map<String, dynamic>?;
      if (character != null) {
        await db.into(db.characters).insert(CharactersCompanion.insert(
              id: const Value(1),
              name: character['name'] as String,
              age: character['age'] as int,
              gender: character['gender'] as String,
              xp: Value(character['xp'] as int),
              health: Value(character['health'] as int),
              discipline: Value(character['discipline'] as int),
              charm: Value(character['charm'] as int),
              createdAt: parseIso(character['created_at']) ?? now,
              updatedAt: parseIso(character['updated_at']) ?? now,
            ));
      }

      for (final t in (data['tasks'] as List).cast<Map<String, dynamic>>()) {
        final id = await db.into(db.tasks).insert(TasksCompanion.insert(
              name: t['name'] as String,
              description: Value(t['description'] as String? ?? ''),
              type: TaskType.values.byName(t['type'] as String),
              rewardHealth: Value(t['reward_health'] as int),
              rewardDiscipline: Value(t['reward_discipline'] as int),
              rewardCharm: Value(t['reward_charm'] as int),
              isCompleted: Value(t['is_completed'] as bool),
              completedAt: Value(parseIso(t['completed_at'])),
              isFailed: Value(t['is_failed'] as bool? ?? false),
              failedAt: Value(parseIso(t['failed_at'])),
              completedOn: Value(t['completed_on'] as String?),
              sortOrder: Value(t['sort_order'] as int),
              createdAt: parseIso(t['created_at']) ?? now,
            ));
        taskNameToId[t['name'] as String] = id;
      }

      for (final s in (data['subtasks'] as List).cast<Map<String, dynamic>>()) {
        final taskId = taskNameToId[s['task_name']];
        if (taskId == null) continue;
        await db.into(db.subtasks).insert(SubtasksCompanion.insert(
              taskId: taskId,
              name: s['name'] as String,
              isDone: Value(s['is_done'] as bool),
              sortOrder: Value(s['sort_order'] as int),
              createdAt: parseIso(s['created_at']) ?? now,
            ));
      }

      for (final c
          in (data['task_completions'] as List).cast<Map<String, dynamic>>()) {
        await db.into(db.taskCompletions).insert(
            TaskCompletionsCompanion.insert(
              taskName: c['task_name'] as String,
              taskType: TaskType.values.byName(c['task_type'] as String),
              xpGained: c['xp_gained'] as int,
              healthGained: c['health_gained'] as int,
              disciplineGained: c['discipline_gained'] as int,
              charmGained: c['charm_gained'] as int,
              completedAt: parseIso(c['completed_at']) ?? now,
            ));
      }

      for (final l in ((data['daily_task_logs'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()) {
        await db.into(db.dailyTaskLogs).insert(DailyTaskLogsCompanion.insert(
              taskId: Value(taskNameToId[l['task_name']]),
              taskName: l['task_name'] as String,
              date: l['date'] as String,
              status: DailyTaskStatus.values.byName(l['status'] as String),
              penaltyHealth: Value(l['penalty_health'] as int? ?? 0),
              penaltyDiscipline: Value(l['penalty_discipline'] as int? ?? 0),
              penaltyCharm: Value(l['penalty_charm'] as int? ?? 0),
              createdAt: parseIso(l['created_at']) ?? now,
            ));
      }

      for (final h in (data['habits'] as List).cast<Map<String, dynamic>>()) {
        final id = await db.into(db.habits).insert(HabitsCompanion.insert(
              name: h['name'] as String,
              description: Value(h['description'] as String? ?? ''),
              frequencyType: HabitFrequency.values
                  .byName(h['frequency_type'] as String),
              timesPerWeek: Value(h['times_per_week'] as int),
              rewardHealth: Value(h['reward_health'] as int),
              rewardDiscipline: Value(h['reward_discipline'] as int),
              rewardCharm: Value(h['reward_charm'] as int),
              isArchived: Value(h['is_archived'] as bool),
              ruleChangedAt: Value(parseIso(h['rule_changed_at'])),
              sortOrder: Value(h['sort_order'] as int),
              createdAt: parseIso(h['created_at']) ?? now,
            ));
        habitNameToId[h['name'] as String] = id;
      }

      for (final c in (data['checkins'] as List).cast<Map<String, dynamic>>()) {
        final habitId = habitNameToId[c['habit_name']];
        if (habitId == null) continue;
        await db.into(db.checkins).insert(CheckinsCompanion.insert(
              habitId: habitId,
              date: c['date'] as String,
              createdAt: parseIso(c['created_at']) ?? now,
            ));
      }

      for (final m in (data['habit_milestones'] as List)
          .cast<Map<String, dynamic>>()) {
        final habitId = habitNameToId[m['habit_name']];
        if (habitId == null) continue;
        await db.into(db.habitMilestones).insert(
            HabitMilestonesCompanion.insert(
              habitId: habitId,
              days: m['days'] as int,
              grantedAt: parseIso(m['granted_at']) ?? now,
            ));
      }

      for (final n in (data['notes'] as List).cast<Map<String, dynamic>>()) {
        await db.into(db.notes).insert(NotesCompanion.insert(
              content: n['content'] as String,
              createdAt: parseIso(n['created_at']) ?? now,
              updatedAt: parseIso(n['updated_at']) ?? now,
            ));
      }

      final settings = (data['settings'] as Map<String, dynamic>? ?? {})
          .cast<String, String>();
      await db.batch((b) {
        b.insertAll(db.settings, [
          for (final e in settings.entries)
            SettingsCompanion.insert(key: e.key, value: e.value),
        ]);
      });
      // 恢复当天不再触发每日结算（友好：不给恢复动作加惩罚）
      await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(
              key: 'last_settled_on', value: dateString(now)));
    });
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

  /// 完成任务：按类型发放固定经验与配置属性；重复完成或已判失败返回 null。
  Future<GrowthOutcome?> completeTask(int taskId, {required DateTime now}) {
    return db.transaction(() async {
      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();
      if (task == null || task.isFailed) return null;

      final reward = AttributeDelta(
        health: task.rewardHealth,
        discipline: task.rewardDiscipline,
        charm: task.rewardCharm,
      );

      int xpGain;
      switch (task.type) {
        case TaskType.daily:
          final today = dateString(now);
          if (task.completedOn == today) return null;
          // 今天已被判失败：当天不能再完成（不能既扣属性又拿奖励）
          final loggedToday = await (db.select(db.dailyTaskLogs)
                ..where((l) => l.taskId.equals(taskId) & l.date.equals(today)))
              .getSingleOrNull();
          if (loggedToday != null) return null;
          xpGain = dailyTaskXp;
          await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
            TasksCompanion(completedOn: Value(today)),
          );
          // 逐日历史：完成也要落一条，历史页才能按日期回溯
          await _insertDailyLog(
            task: task,
            date: today,
            status: DailyTaskStatus.completed,
            now: now,
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

  /// 手动把任务判为失败（失败后不删除；主线/支线失败是终态，只能删除）。
  ///
  /// 详见 ADR-0007：
  /// - 每日任务：立即按配置扣除属性并落当天的失败记录；当天已完成则返回 null。
  /// - 主线/支线：标记为失败后离开进行中列表，进入「已失败」归档，不发奖也不扣属性。
  ///
  /// 重复判失败返回 null。
  Future<TaskFailOutcome?> failTask(int taskId, {required DateTime now}) {
    return db.transaction(() async {
      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();
      if (task == null) return null;

      if (task.type != TaskType.daily) {
        if (task.isCompleted || task.isFailed) return null;
        await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
          TasksCompanion(
            isFailed: const Value(true),
            failedAt: Value(now),
          ),
        );
        return TaskFailOutcome(
          taskName: task.name,
          taskType: task.type,
          penalty: AttributeDelta.zero,
        );
      }

      final today = dateString(now);
      if (task.completedOn == today) return null; // 今天已完成，不能判失败
      final logged = await (db.select(db.dailyTaskLogs)
            ..where((l) => l.taskId.equals(taskId) & l.date.equals(today)))
          .getSingleOrNull();
      if (logged != null) return null; // 今天已有结论（完成/失败）

      final applied = await _applyPenalty(
        AttributeDelta(
          health: task.rewardHealth,
          discipline: task.rewardDiscipline,
          charm: task.rewardCharm,
        ),
        now: now,
      );
      await _insertDailyLog(
        task: task,
        date: today,
        status: DailyTaskStatus.failed,
        now: now,
      );
      return TaskFailOutcome(
        taskName: task.name,
        taskType: task.type,
        penalty: applied,
      );
    });
  }

  /// 落一条每日任务历史（配置惩罚值随快照保存，任务删除后仍可回溯）。
  Future<void> _insertDailyLog({
    required Task task,
    required String date,
    required DailyTaskStatus status,
    required DateTime now,
  }) async {
    await db.into(db.dailyTaskLogs).insert(DailyTaskLogsCompanion.insert(
          taskId: Value(task.id),
          taskName: task.name,
          date: date,
          status: status,
          penaltyHealth: Value(task.rewardHealth),
          penaltyDiscipline: Value(task.rewardDiscipline),
          penaltyCharm: Value(task.rewardCharm),
          createdAt: now,
        ));
  }

  /// 立即扣除属性，返回实际生效的扣除量（下限 0 截断）。
  Future<AttributeDelta> _applyPenalty(
    AttributeDelta penalty, {
    required DateTime now,
  }) async {
    final row = await (db.select(db.characters)..where((c) => c.id.equals(1)))
        .getSingleOrNull();
    if (row == null) return AttributeDelta.zero;
    final current = Attributes(
      health: row.health,
      discipline: row.discipline,
      charm: row.charm,
    );
    final after = current.applyPenalty(penalty);
    await (db.update(db.characters)..where((c) => c.id.equals(1))).write(
      CharactersCompanion(
        health: Value(after.health),
        discipline: Value(after.discipline),
        charm: Value(after.charm),
        updatedAt: Value(now),
      ),
    );
    return AttributeDelta(
      health: current.health - after.health,
      discipline: current.discipline - after.discipline,
      charm: current.charm - after.charm,
    );
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
      if (task == null ||
          task.isCompleted ||
          task.isFailed ||
          task.type != TaskType.mainline) {
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

  /// 某类型的任务，按状态过滤：进行中（默认）/ 已完成 / 已失败。
  ///
  /// [completed] 与 [failed] 互斥，同时为 true 不会有结果。
  Future<List<Task>> tasksByType(
    TaskType type, {
    bool completed = false,
    bool failed = false,
  }) async {
    final query = db.select(db.tasks)
      ..where((t) =>
          t.type.equalsValue(type) &
          t.isCompleted.equals(completed) &
          t.isFailed.equals(failed))
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

  /// 全部每日任务历史（日期倒序，同日按记录顺序），供按天回溯。
  Future<List<DailyTaskLog>> dailyLogs() async {
    final query = db.select(db.dailyTaskLogs)
      ..orderBy([
        (l) => OrderingTerm.desc(l.date),
        (l) => OrderingTerm.asc(l.id),
      ]);
    return query.get();
  }

  /// 某一天的每日任务历史。
  Future<List<DailyTaskLog>> dailyLogsOn(DateTime day) async {
    final query = db.select(db.dailyTaskLogs)
      ..where((l) => l.date.equals(dateString(day)))
      ..orderBy([(l) => OrderingTerm.asc(l.id)]);
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

  /// 0 点结算（ADR-0004 / ADR-0007）：结算 [now] 的前一天。
  ///
  /// 前一天未完成的每日任务扣除其配置属性（下限 0、不扣经验），
  /// 并把前一天记为失败写进每日任务历史（任务本身保留，只重置当天状态）；
  /// 全部每日任务重置为未完成。同一天重复调用返回 null（幂等）。
  Future<SettlementResult?> settleDay({required DateTime now}) {
    return db.transaction(() async {
      final today = dateString(now);
      final last = await (db.select(db.settings)
            ..where((s) => s.key.equals('last_settled_on')))
          .getSingleOrNull();
      if (last?.value == today) return null;

      final yesterday = dateString(now.subtract(const Duration(days: 1)));
      final dayStart = DateTime(now.year, now.month, now.day); // 昨天 24:00
      final loggedYesterday = await (db.select(db.dailyTaskLogs)
            ..where((l) => l.date.equals(yesterday)))
          .get();
      final alreadyFailed = {
        for (final l in loggedYesterday)
          if (l.status == DailyTaskStatus.failed) l.taskId,
      };
      final dailyTasks = await (db.select(db.tasks)
            ..where((t) => t.type.equalsValue(TaskType.daily)))
          .get();
      // 未完成 = 昨天没完成、昨天已经存在（不追溯昨天之后才建的任务）、
      // 且没有在昨天被手动判失败（手动判失败时已扣过，不重复扣）
      final missed = [
        for (final t in dailyTasks)
          if (t.completedOn != yesterday &&
              !t.createdAt.isAfter(dayStart) &&
              !alreadyFailed.contains(t.id))
            t,
      ];

      final row = await (db.select(db.characters)
            ..where((c) => c.id.equals(1)))
          .getSingleOrNull();
      if (row == null) {
        // 尚无主角：只记录结算标记与失败历史，不扣属性
        for (final t in missed) {
          await _insertDailyLog(
            task: t,
            date: yesterday,
            status: DailyTaskStatus.failed,
            now: now,
          );
        }
        await _resetDailyTasks(dailyTasks);
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

      // 昨天未完成的每日任务记为失败（不删除任务）
      for (final t in missed) {
        await _insertDailyLog(
          task: t,
          date: yesterday,
          status: DailyTaskStatus.failed,
          now: now,
        );
      }

      await _resetDailyTasks(dailyTasks);

      await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: 'last_settled_on', value: today));

      return SettlementResult(
        totalPenalty: outcome.totalPenalty,
        penalizedTaskNames: [for (final t in missed) t.name],
      );
    });
  }

  /// 结算后把每日任务重置为未完成（任务与历史都保留）。
  Future<void> _resetDailyTasks(List<Task> dailyTasks) async {
    for (final t in dailyTasks) {
      if (t.completedOn != null) {
        await (db.update(db.tasks)..where((x) => x.id.equals(t.id))).write(
          const TasksCompanion(completedOn: Value(null)),
        );
      }
    }
  }

  // ---- 笔记 ----

  /// 新增笔记，返回笔记 id。
  ///
  /// 笔记只做记录：不发经验、不参与成长结算（ADR-0006）。
  Future<int> addNote(String content, {required DateTime now}) async {
    return db.into(db.notes).insert(NotesCompanion.insert(
          content: content,
          createdAt: now,
          updatedAt: now,
        ));
  }

  /// 编辑笔记内容（同样不发经验）。
  Future<void> updateNote(int noteId, String content) async {
    await (db.update(db.notes)..where((n) => n.id.equals(noteId))).write(
      NotesCompanion(
        content: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 删除笔记（笔记无经验与奖励，删除不影响任何数值）。
  Future<void> deleteNote(int noteId) async {
    await (db.delete(db.notes)..where((n) => n.id.equals(noteId))).go();
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
