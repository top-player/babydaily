/// drift 数据模型（ADR-0001：本地 SQLite）。
///
/// 日期语义：打卡日期与每日任务完成日使用本地 'yyyy-MM-dd' 字符串存储；
/// 时间戳统一用 DateTime（本地时区）。
library;

import 'package:drift/drift.dart';
import 'package:babydaily/src/domain/enums.dart';

part 'database.g.dart';

/// 主角表：单行（id 恒为 1）。
class Characters extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get age => integer()();
  TextColumn get gender => text()(); // Gender.name
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get health => integer().withDefault(const Constant(50))();
  IntColumn get discipline => integer().withDefault(const Constant(50))();
  IntColumn get charm => integer().withDefault(const Constant(50))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 任务表：主线/支线/每日任务统一存放。
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get type => intEnum<TaskType>()();
  IntColumn get rewardHealth => integer().withDefault(const Constant(0))();
  IntColumn get rewardDiscipline => integer().withDefault(const Constant(0))();
  IntColumn get rewardCharm => integer().withDefault(const Constant(0))();
  /// 主线/支线：是否已完成（完成后进入"已完成"归档）。
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  /// 主线/支线：是否已失败（失败是终态，任务保留在"已失败"归档，只能删除）。
  BoolColumn get isFailed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get failedAt => dateTime().nullable()();
  /// 每日任务：当天完成日期 'yyyy-MM-dd'，0 点结算时清空。
  TextColumn get completedOn => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// 任务子项：仅主线任务拥有，无独立奖励。
class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// 任务完成历史：删除任务后保留（taskId 置空，快照名称）。
class TaskCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().nullable()();
  TextColumn get taskName => text()();
  IntColumn get taskType => intEnum<TaskType>()();
  IntColumn get xpGained => integer()();
  IntColumn get healthGained => integer()();
  IntColumn get disciplineGained => integer()();
  IntColumn get charmGained => integer()();
  DateTimeColumn get completedAt => dateTime()();
}

/// 每日任务历史：每天每个每日任务的结果（完成 / 失败），供按日期回溯（ADR-0007）。
///
/// 与 [TaskCompletions] 的分工：后者是所有类型任务的完成奖励流水，
/// 这里是每日任务的逐日状态快照。任务被删除后记录仍保留（快照名称），
/// 因此 taskId 可悬空、不用外键。
class DailyTaskLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().nullable()();
  TextColumn get taskName => text()();
  TextColumn get date => text()(); // 'yyyy-MM-dd'
  IntColumn get status => intEnum<DailyTaskStatus>()();
  /// 当天该任务配置的惩罚值（实际扣除受属性下限 0 截断，见 ADR-0004）。
  IntColumn get penaltyHealth => integer().withDefault(const Constant(0))();
  IntColumn get penaltyDiscipline =>
      integer().withDefault(const Constant(0))();
  IntColumn get penaltyCharm => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// 习惯表：每日 / 每周 N 次。
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get frequencyType => intEnum<HabitFrequency>()();
  IntColumn get timesPerWeek => integer().withDefault(const Constant(1))();
  IntColumn get rewardHealth => integer().withDefault(const Constant(0))();
  IntColumn get rewardDiscipline => integer().withDefault(const Constant(1))();
  IntColumn get rewardCharm => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  /// 规则（频率/每周次数）最后一次变更时间；连续计数只统计此后的打卡。
  DateTimeColumn get ruleChangedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// 打卡记录：同一习惯每天最多一次（uniqueKeys 保证）。
class Checkins extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()(); // 'yyyy-MM-dd'
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date},
      ];
}

/// 习惯连续里程碑发放记录：每习惯每个档位终身一次。
class HabitMilestones extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get days => integer()(); // 10/20/30
  DateTimeColumn get grantedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, days},
      ];
}

/// 笔记：一天可多篇，按创建日期归天。
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// 键值设置：当前场景、新手引导完成标记等。
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Characters,
  Tasks,
  Subtasks,
  TaskCompletions,
  DailyTaskLogs,
  Habits,
  Checkins,
  HabitMilestones,
  Notes,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(habits, habits.ruleChangedAt);
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.isFailed);
            await m.addColumn(tasks, tasks.failedAt);
            await m.createTable(dailyTaskLogs);
          }
        },
        beforeOpen: (details) async {
          // SQLite 默认不启用外键；开启以保证级联删除（任务 → 子项）生效。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

