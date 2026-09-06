// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _healthMeta = const VerificationMeta('health');
  @override
  late final GeneratedColumn<int> health = GeneratedColumn<int>(
    'health',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(50),
  );
  static const VerificationMeta _disciplineMeta = const VerificationMeta(
    'discipline',
  );
  @override
  late final GeneratedColumn<int> discipline = GeneratedColumn<int>(
    'discipline',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(50),
  );
  static const VerificationMeta _charmMeta = const VerificationMeta('charm');
  @override
  late final GeneratedColumn<int> charm = GeneratedColumn<int>(
    'charm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(50),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    age,
    gender,
    xp,
    health,
    discipline,
    charm,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Character> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    } else if (isInserting) {
      context.missing(_ageMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    if (data.containsKey('health')) {
      context.handle(
        _healthMeta,
        health.isAcceptableOrUnknown(data['health']!, _healthMeta),
      );
    }
    if (data.containsKey('discipline')) {
      context.handle(
        _disciplineMeta,
        discipline.isAcceptableOrUnknown(data['discipline']!, _disciplineMeta),
      );
    }
    if (data.containsKey('charm')) {
      context.handle(
        _charmMeta,
        charm.isAcceptableOrUnknown(data['charm']!, _charmMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      xp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp'],
      )!,
      health: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}health'],
      )!,
      discipline: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discipline'],
      )!,
      charm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}charm'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  final int id;
  final String name;
  final int age;
  final String gender;
  final int xp;
  final int health;
  final int discipline;
  final int charm;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Character({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.xp,
    required this.health,
    required this.discipline,
    required this.charm,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['age'] = Variable<int>(age);
    map['gender'] = Variable<String>(gender);
    map['xp'] = Variable<int>(xp);
    map['health'] = Variable<int>(health);
    map['discipline'] = Variable<int>(discipline);
    map['charm'] = Variable<int>(charm);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      name: Value(name),
      age: Value(age),
      gender: Value(gender),
      xp: Value(xp),
      health: Value(health),
      discipline: Value(discipline),
      charm: Value(charm),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Character.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      age: serializer.fromJson<int>(json['age']),
      gender: serializer.fromJson<String>(json['gender']),
      xp: serializer.fromJson<int>(json['xp']),
      health: serializer.fromJson<int>(json['health']),
      discipline: serializer.fromJson<int>(json['discipline']),
      charm: serializer.fromJson<int>(json['charm']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'age': serializer.toJson<int>(age),
      'gender': serializer.toJson<String>(gender),
      'xp': serializer.toJson<int>(xp),
      'health': serializer.toJson<int>(health),
      'discipline': serializer.toJson<int>(discipline),
      'charm': serializer.toJson<int>(charm),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Character copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    int? xp,
    int? health,
    int? discipline,
    int? charm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Character(
    id: id ?? this.id,
    name: name ?? this.name,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    xp: xp ?? this.xp,
    health: health ?? this.health,
    discipline: discipline ?? this.discipline,
    charm: charm ?? this.charm,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      age: data.age.present ? data.age.value : this.age,
      gender: data.gender.present ? data.gender.value : this.gender,
      xp: data.xp.present ? data.xp.value : this.xp,
      health: data.health.present ? data.health.value : this.health,
      discipline: data.discipline.present
          ? data.discipline.value
          : this.discipline,
      charm: data.charm.present ? data.charm.value : this.charm,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('age: $age, ')
          ..write('gender: $gender, ')
          ..write('xp: $xp, ')
          ..write('health: $health, ')
          ..write('discipline: $discipline, ')
          ..write('charm: $charm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    age,
    gender,
    xp,
    health,
    discipline,
    charm,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.id == this.id &&
          other.name == this.name &&
          other.age == this.age &&
          other.gender == this.gender &&
          other.xp == this.xp &&
          other.health == this.health &&
          other.discipline == this.discipline &&
          other.charm == this.charm &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> age;
  final Value<String> gender;
  final Value<int> xp;
  final Value<int> health;
  final Value<int> discipline;
  final Value<int> charm;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.age = const Value.absent(),
    this.gender = const Value.absent(),
    this.xp = const Value.absent(),
    this.health = const Value.absent(),
    this.discipline = const Value.absent(),
    this.charm = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CharactersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int age,
    required String gender,
    this.xp = const Value.absent(),
    this.health = const Value.absent(),
    this.discipline = const Value.absent(),
    this.charm = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       age = Value(age),
       gender = Value(gender),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Character> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? age,
    Expression<String>? gender,
    Expression<int>? xp,
    Expression<int>? health,
    Expression<int>? discipline,
    Expression<int>? charm,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (xp != null) 'xp': xp,
      if (health != null) 'health': health,
      if (discipline != null) 'discipline': discipline,
      if (charm != null) 'charm': charm,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CharactersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? age,
    Value<String>? gender,
    Value<int>? xp,
    Value<int>? health,
    Value<int>? discipline,
    Value<int>? charm,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CharactersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      xp: xp ?? this.xp,
      health: health ?? this.health,
      discipline: discipline ?? this.discipline,
      charm: charm ?? this.charm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (health.present) {
      map['health'] = Variable<int>(health.value);
    }
    if (discipline.present) {
      map['discipline'] = Variable<int>(discipline.value);
    }
    if (charm.present) {
      map['charm'] = Variable<int>(charm.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('age: $age, ')
          ..write('gender: $gender, ')
          ..write('xp: $xp, ')
          ..write('health: $health, ')
          ..write('discipline: $discipline, ')
          ..write('charm: $charm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskType>($TasksTable.$convertertype);
  static const VerificationMeta _rewardHealthMeta = const VerificationMeta(
    'rewardHealth',
  );
  @override
  late final GeneratedColumn<int> rewardHealth = GeneratedColumn<int>(
    'reward_health',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rewardDisciplineMeta = const VerificationMeta(
    'rewardDiscipline',
  );
  @override
  late final GeneratedColumn<int> rewardDiscipline = GeneratedColumn<int>(
    'reward_discipline',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rewardCharmMeta = const VerificationMeta(
    'rewardCharm',
  );
  @override
  late final GeneratedColumn<int> rewardCharm = GeneratedColumn<int>(
    'reward_charm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedOnMeta = const VerificationMeta(
    'completedOn',
  );
  @override
  late final GeneratedColumn<String> completedOn = GeneratedColumn<String>(
    'completed_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    type,
    rewardHealth,
    rewardDiscipline,
    rewardCharm,
    isCompleted,
    completedAt,
    completedOn,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('reward_health')) {
      context.handle(
        _rewardHealthMeta,
        rewardHealth.isAcceptableOrUnknown(
          data['reward_health']!,
          _rewardHealthMeta,
        ),
      );
    }
    if (data.containsKey('reward_discipline')) {
      context.handle(
        _rewardDisciplineMeta,
        rewardDiscipline.isAcceptableOrUnknown(
          data['reward_discipline']!,
          _rewardDisciplineMeta,
        ),
      );
    }
    if (data.containsKey('reward_charm')) {
      context.handle(
        _rewardCharmMeta,
        rewardCharm.isAcceptableOrUnknown(
          data['reward_charm']!,
          _rewardCharmMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('completed_on')) {
      context.handle(
        _completedOnMeta,
        completedOn.isAcceptableOrUnknown(
          data['completed_on']!,
          _completedOnMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      type: $TasksTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      rewardHealth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reward_health'],
      )!,
      rewardDiscipline: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reward_discipline'],
      )!,
      rewardCharm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reward_charm'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      completedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_on'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskType, int, int> $convertertype =
      const EnumIndexConverter<TaskType>(TaskType.values);
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String name;
  final String description;
  final TaskType type;
  final int rewardHealth;
  final int rewardDiscipline;
  final int rewardCharm;

  /// 主线/支线：是否已完成（完成后进入"已完成"归档）。
  final bool isCompleted;
  final DateTime? completedAt;

  /// 每日任务：当天完成日期 'yyyy-MM-dd'，0 点结算时清空。
  final String? completedOn;
  final int sortOrder;
  final DateTime createdAt;
  const Task({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rewardHealth,
    required this.rewardDiscipline,
    required this.rewardCharm,
    required this.isCompleted,
    this.completedAt,
    this.completedOn,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    {
      map['type'] = Variable<int>($TasksTable.$convertertype.toSql(type));
    }
    map['reward_health'] = Variable<int>(rewardHealth);
    map['reward_discipline'] = Variable<int>(rewardDiscipline);
    map['reward_charm'] = Variable<int>(rewardCharm);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || completedOn != null) {
      map['completed_on'] = Variable<String>(completedOn);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      rewardHealth: Value(rewardHealth),
      rewardDiscipline: Value(rewardDiscipline),
      rewardCharm: Value(rewardCharm),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completedOn: completedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(completedOn),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      type: $TasksTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      rewardHealth: serializer.fromJson<int>(json['rewardHealth']),
      rewardDiscipline: serializer.fromJson<int>(json['rewardDiscipline']),
      rewardCharm: serializer.fromJson<int>(json['rewardCharm']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      completedOn: serializer.fromJson<String?>(json['completedOn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<int>($TasksTable.$convertertype.toJson(type)),
      'rewardHealth': serializer.toJson<int>(rewardHealth),
      'rewardDiscipline': serializer.toJson<int>(rewardDiscipline),
      'rewardCharm': serializer.toJson<int>(rewardCharm),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'completedOn': serializer.toJson<String?>(completedOn),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Task copyWith({
    int? id,
    String? name,
    String? description,
    TaskType? type,
    int? rewardHealth,
    int? rewardDiscipline,
    int? rewardCharm,
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> completedOn = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
  }) => Task(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    rewardHealth: rewardHealth ?? this.rewardHealth,
    rewardDiscipline: rewardDiscipline ?? this.rewardDiscipline,
    rewardCharm: rewardCharm ?? this.rewardCharm,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    completedOn: completedOn.present ? completedOn.value : this.completedOn,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      rewardHealth: data.rewardHealth.present
          ? data.rewardHealth.value
          : this.rewardHealth,
      rewardDiscipline: data.rewardDiscipline.present
          ? data.rewardDiscipline.value
          : this.rewardDiscipline,
      rewardCharm: data.rewardCharm.present
          ? data.rewardCharm.value
          : this.rewardCharm,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      completedOn: data.completedOn.present
          ? data.completedOn.value
          : this.completedOn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('rewardHealth: $rewardHealth, ')
          ..write('rewardDiscipline: $rewardDiscipline, ')
          ..write('rewardCharm: $rewardCharm, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedOn: $completedOn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    type,
    rewardHealth,
    rewardDiscipline,
    rewardCharm,
    isCompleted,
    completedAt,
    completedOn,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.type == this.type &&
          other.rewardHealth == this.rewardHealth &&
          other.rewardDiscipline == this.rewardDiscipline &&
          other.rewardCharm == this.rewardCharm &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.completedOn == this.completedOn &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<TaskType> type;
  final Value<int> rewardHealth;
  final Value<int> rewardDiscipline;
  final Value<int> rewardCharm;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<String?> completedOn;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.rewardHealth = const Value.absent(),
    this.rewardDiscipline = const Value.absent(),
    this.rewardCharm = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedOn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required TaskType type,
    this.rewardHealth = const Value.absent(),
    this.rewardDiscipline = const Value.absent(),
    this.rewardCharm = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedOn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? type,
    Expression<int>? rewardHealth,
    Expression<int>? rewardDiscipline,
    Expression<int>? rewardCharm,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<String>? completedOn,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (rewardHealth != null) 'reward_health': rewardHealth,
      if (rewardDiscipline != null) 'reward_discipline': rewardDiscipline,
      if (rewardCharm != null) 'reward_charm': rewardCharm,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (completedOn != null) 'completed_on': completedOn,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? description,
    Value<TaskType>? type,
    Value<int>? rewardHealth,
    Value<int>? rewardDiscipline,
    Value<int>? rewardCharm,
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<String?>? completedOn,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rewardHealth: rewardHealth ?? this.rewardHealth,
      rewardDiscipline: rewardDiscipline ?? this.rewardDiscipline,
      rewardCharm: rewardCharm ?? this.rewardCharm,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedOn: completedOn ?? this.completedOn,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<int>($TasksTable.$convertertype.toSql(type.value));
    }
    if (rewardHealth.present) {
      map['reward_health'] = Variable<int>(rewardHealth.value);
    }
    if (rewardDiscipline.present) {
      map['reward_discipline'] = Variable<int>(rewardDiscipline.value);
    }
    if (rewardCharm.present) {
      map['reward_charm'] = Variable<int>(rewardCharm.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (completedOn.present) {
      map['completed_on'] = Variable<String>(completedOn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('rewardHealth: $rewardHealth, ')
          ..write('rewardDiscipline: $rewardDiscipline, ')
          ..write('rewardCharm: $rewardCharm, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedOn: $completedOn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SubtasksTable extends Subtasks with TableInfo<$SubtasksTable, Subtask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    name,
    isDone,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subtask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subtask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subtask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SubtasksTable createAlias(String alias) {
    return $SubtasksTable(attachedDatabase, alias);
  }
}

class Subtask extends DataClass implements Insertable<Subtask> {
  final int id;
  final int taskId;
  final String name;
  final bool isDone;
  final int sortOrder;
  final DateTime createdAt;
  const Subtask({
    required this.id,
    required this.taskId,
    required this.name,
    required this.isDone,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['name'] = Variable<String>(name);
    map['is_done'] = Variable<bool>(isDone);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SubtasksCompanion toCompanion(bool nullToAbsent) {
    return SubtasksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      name: Value(name),
      isDone: Value(isDone),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Subtask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subtask(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      name: serializer.fromJson<String>(json['name']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'name': serializer.toJson<String>(name),
      'isDone': serializer.toJson<bool>(isDone),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Subtask copyWith({
    int? id,
    int? taskId,
    String? name,
    bool? isDone,
    int? sortOrder,
    DateTime? createdAt,
  }) => Subtask(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    name: name ?? this.name,
    isDone: isDone ?? this.isDone,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Subtask copyWithCompanion(SubtasksCompanion data) {
    return Subtask(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      name: data.name.present ? data.name.value : this.name,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subtask(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('name: $name, ')
          ..write('isDone: $isDone, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, name, isDone, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subtask &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.name == this.name &&
          other.isDone == this.isDone &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class SubtasksCompanion extends UpdateCompanion<Subtask> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<String> name;
  final Value<bool> isDone;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const SubtasksCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.name = const Value.absent(),
    this.isDone = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SubtasksCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required String name,
    this.isDone = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
  }) : taskId = Value(taskId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Subtask> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? name,
    Expression<bool>? isDone,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (name != null) 'name': name,
      if (isDone != null) 'is_done': isDone,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SubtasksCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<String>? name,
    Value<bool>? isDone,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return SubtasksCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      name: name ?? this.name,
      isDone: isDone ?? this.isDone,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtasksCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('name: $name, ')
          ..write('isDone: $isDone, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TaskCompletionsTable extends TaskCompletions
    with TableInfo<$TaskCompletionsTable, TaskCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskNameMeta = const VerificationMeta(
    'taskName',
  );
  @override
  late final GeneratedColumn<String> taskName = GeneratedColumn<String>(
    'task_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskType, int> taskType =
      GeneratedColumn<int>(
        'task_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskType>($TaskCompletionsTable.$convertertaskType);
  static const VerificationMeta _xpGainedMeta = const VerificationMeta(
    'xpGained',
  );
  @override
  late final GeneratedColumn<int> xpGained = GeneratedColumn<int>(
    'xp_gained',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthGainedMeta = const VerificationMeta(
    'healthGained',
  );
  @override
  late final GeneratedColumn<int> healthGained = GeneratedColumn<int>(
    'health_gained',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disciplineGainedMeta = const VerificationMeta(
    'disciplineGained',
  );
  @override
  late final GeneratedColumn<int> disciplineGained = GeneratedColumn<int>(
    'discipline_gained',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _charmGainedMeta = const VerificationMeta(
    'charmGained',
  );
  @override
  late final GeneratedColumn<int> charmGained = GeneratedColumn<int>(
    'charm_gained',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    taskName,
    taskType,
    xpGained,
    healthGained,
    disciplineGained,
    charmGained,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskCompletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('task_name')) {
      context.handle(
        _taskNameMeta,
        taskName.isAcceptableOrUnknown(data['task_name']!, _taskNameMeta),
      );
    } else if (isInserting) {
      context.missing(_taskNameMeta);
    }
    if (data.containsKey('xp_gained')) {
      context.handle(
        _xpGainedMeta,
        xpGained.isAcceptableOrUnknown(data['xp_gained']!, _xpGainedMeta),
      );
    } else if (isInserting) {
      context.missing(_xpGainedMeta);
    }
    if (data.containsKey('health_gained')) {
      context.handle(
        _healthGainedMeta,
        healthGained.isAcceptableOrUnknown(
          data['health_gained']!,
          _healthGainedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_healthGainedMeta);
    }
    if (data.containsKey('discipline_gained')) {
      context.handle(
        _disciplineGainedMeta,
        disciplineGained.isAcceptableOrUnknown(
          data['discipline_gained']!,
          _disciplineGainedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disciplineGainedMeta);
    }
    if (data.containsKey('charm_gained')) {
      context.handle(
        _charmGainedMeta,
        charmGained.isAcceptableOrUnknown(
          data['charm_gained']!,
          _charmGainedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_charmGainedMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskCompletion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      ),
      taskName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_name'],
      )!,
      taskType: $TaskCompletionsTable.$convertertaskType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}task_type'],
        )!,
      ),
      xpGained: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_gained'],
      )!,
      healthGained: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}health_gained'],
      )!,
      disciplineGained: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discipline_gained'],
      )!,
      charmGained: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}charm_gained'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $TaskCompletionsTable createAlias(String alias) {
    return $TaskCompletionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskType, int, int> $convertertaskType =
      const EnumIndexConverter<TaskType>(TaskType.values);
}

class TaskCompletion extends DataClass implements Insertable<TaskCompletion> {
  final int id;
  final int? taskId;
  final String taskName;
  final TaskType taskType;
  final int xpGained;
  final int healthGained;
  final int disciplineGained;
  final int charmGained;
  final DateTime completedAt;
  const TaskCompletion({
    required this.id,
    this.taskId,
    required this.taskName,
    required this.taskType,
    required this.xpGained,
    required this.healthGained,
    required this.disciplineGained,
    required this.charmGained,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<int>(taskId);
    }
    map['task_name'] = Variable<String>(taskName);
    {
      map['task_type'] = Variable<int>(
        $TaskCompletionsTable.$convertertaskType.toSql(taskType),
      );
    }
    map['xp_gained'] = Variable<int>(xpGained);
    map['health_gained'] = Variable<int>(healthGained);
    map['discipline_gained'] = Variable<int>(disciplineGained);
    map['charm_gained'] = Variable<int>(charmGained);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  TaskCompletionsCompanion toCompanion(bool nullToAbsent) {
    return TaskCompletionsCompanion(
      id: Value(id),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      taskName: Value(taskName),
      taskType: Value(taskType),
      xpGained: Value(xpGained),
      healthGained: Value(healthGained),
      disciplineGained: Value(disciplineGained),
      charmGained: Value(charmGained),
      completedAt: Value(completedAt),
    );
  }

  factory TaskCompletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskCompletion(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int?>(json['taskId']),
      taskName: serializer.fromJson<String>(json['taskName']),
      taskType: $TaskCompletionsTable.$convertertaskType.fromJson(
        serializer.fromJson<int>(json['taskType']),
      ),
      xpGained: serializer.fromJson<int>(json['xpGained']),
      healthGained: serializer.fromJson<int>(json['healthGained']),
      disciplineGained: serializer.fromJson<int>(json['disciplineGained']),
      charmGained: serializer.fromJson<int>(json['charmGained']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int?>(taskId),
      'taskName': serializer.toJson<String>(taskName),
      'taskType': serializer.toJson<int>(
        $TaskCompletionsTable.$convertertaskType.toJson(taskType),
      ),
      'xpGained': serializer.toJson<int>(xpGained),
      'healthGained': serializer.toJson<int>(healthGained),
      'disciplineGained': serializer.toJson<int>(disciplineGained),
      'charmGained': serializer.toJson<int>(charmGained),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  TaskCompletion copyWith({
    int? id,
    Value<int?> taskId = const Value.absent(),
    String? taskName,
    TaskType? taskType,
    int? xpGained,
    int? healthGained,
    int? disciplineGained,
    int? charmGained,
    DateTime? completedAt,
  }) => TaskCompletion(
    id: id ?? this.id,
    taskId: taskId.present ? taskId.value : this.taskId,
    taskName: taskName ?? this.taskName,
    taskType: taskType ?? this.taskType,
    xpGained: xpGained ?? this.xpGained,
    healthGained: healthGained ?? this.healthGained,
    disciplineGained: disciplineGained ?? this.disciplineGained,
    charmGained: charmGained ?? this.charmGained,
    completedAt: completedAt ?? this.completedAt,
  );
  TaskCompletion copyWithCompanion(TaskCompletionsCompanion data) {
    return TaskCompletion(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      taskName: data.taskName.present ? data.taskName.value : this.taskName,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      xpGained: data.xpGained.present ? data.xpGained.value : this.xpGained,
      healthGained: data.healthGained.present
          ? data.healthGained.value
          : this.healthGained,
      disciplineGained: data.disciplineGained.present
          ? data.disciplineGained.value
          : this.disciplineGained,
      charmGained: data.charmGained.present
          ? data.charmGained.value
          : this.charmGained,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('taskName: $taskName, ')
          ..write('taskType: $taskType, ')
          ..write('xpGained: $xpGained, ')
          ..write('healthGained: $healthGained, ')
          ..write('disciplineGained: $disciplineGained, ')
          ..write('charmGained: $charmGained, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    taskName,
    taskType,
    xpGained,
    healthGained,
    disciplineGained,
    charmGained,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCompletion &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.taskName == this.taskName &&
          other.taskType == this.taskType &&
          other.xpGained == this.xpGained &&
          other.healthGained == this.healthGained &&
          other.disciplineGained == this.disciplineGained &&
          other.charmGained == this.charmGained &&
          other.completedAt == this.completedAt);
}

class TaskCompletionsCompanion extends UpdateCompanion<TaskCompletion> {
  final Value<int> id;
  final Value<int?> taskId;
  final Value<String> taskName;
  final Value<TaskType> taskType;
  final Value<int> xpGained;
  final Value<int> healthGained;
  final Value<int> disciplineGained;
  final Value<int> charmGained;
  final Value<DateTime> completedAt;
  const TaskCompletionsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.taskName = const Value.absent(),
    this.taskType = const Value.absent(),
    this.xpGained = const Value.absent(),
    this.healthGained = const Value.absent(),
    this.disciplineGained = const Value.absent(),
    this.charmGained = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  TaskCompletionsCompanion.insert({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    required String taskName,
    required TaskType taskType,
    required int xpGained,
    required int healthGained,
    required int disciplineGained,
    required int charmGained,
    required DateTime completedAt,
  }) : taskName = Value(taskName),
       taskType = Value(taskType),
       xpGained = Value(xpGained),
       healthGained = Value(healthGained),
       disciplineGained = Value(disciplineGained),
       charmGained = Value(charmGained),
       completedAt = Value(completedAt);
  static Insertable<TaskCompletion> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? taskName,
    Expression<int>? taskType,
    Expression<int>? xpGained,
    Expression<int>? healthGained,
    Expression<int>? disciplineGained,
    Expression<int>? charmGained,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (taskName != null) 'task_name': taskName,
      if (taskType != null) 'task_type': taskType,
      if (xpGained != null) 'xp_gained': xpGained,
      if (healthGained != null) 'health_gained': healthGained,
      if (disciplineGained != null) 'discipline_gained': disciplineGained,
      if (charmGained != null) 'charm_gained': charmGained,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  TaskCompletionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? taskId,
    Value<String>? taskName,
    Value<TaskType>? taskType,
    Value<int>? xpGained,
    Value<int>? healthGained,
    Value<int>? disciplineGained,
    Value<int>? charmGained,
    Value<DateTime>? completedAt,
  }) {
    return TaskCompletionsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      taskType: taskType ?? this.taskType,
      xpGained: xpGained ?? this.xpGained,
      healthGained: healthGained ?? this.healthGained,
      disciplineGained: disciplineGained ?? this.disciplineGained,
      charmGained: charmGained ?? this.charmGained,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (taskName.present) {
      map['task_name'] = Variable<String>(taskName.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<int>(
        $TaskCompletionsTable.$convertertaskType.toSql(taskType.value),
      );
    }
    if (xpGained.present) {
      map['xp_gained'] = Variable<int>(xpGained.value);
    }
    if (healthGained.present) {
      map['health_gained'] = Variable<int>(healthGained.value);
    }
    if (disciplineGained.present) {
      map['discipline_gained'] = Variable<int>(disciplineGained.value);
    }
    if (charmGained.present) {
      map['charm_gained'] = Variable<int>(charmGained.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletionsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('taskName: $taskName, ')
          ..write('taskType: $taskType, ')
          ..write('xpGained: $xpGained, ')
          ..write('healthGained: $healthGained, ')
          ..write('disciplineGained: $disciplineGained, ')
          ..write('charmGained: $charmGained, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitFrequency, int>
  frequencyType = GeneratedColumn<int>(
    'frequency_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<HabitFrequency>($HabitsTable.$converterfrequencyType);
  static const VerificationMeta _timesPerWeekMeta = const VerificationMeta(
    'timesPerWeek',
  );
  @override
  late final GeneratedColumn<int> timesPerWeek = GeneratedColumn<int>(
    'times_per_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _rewardHealthMeta = const VerificationMeta(
    'rewardHealth',
  );
  @override
  late final GeneratedColumn<int> rewardHealth = GeneratedColumn<int>(
    'reward_health',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rewardDisciplineMeta = const VerificationMeta(
    'rewardDiscipline',
  );
  @override
  late final GeneratedColumn<int> rewardDiscipline = GeneratedColumn<int>(
    'reward_discipline',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _rewardCharmMeta = const VerificationMeta(
    'rewardCharm',
  );
  @override
  late final GeneratedColumn<int> rewardCharm = GeneratedColumn<int>(
    'reward_charm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ruleChangedAtMeta = const VerificationMeta(
    'ruleChangedAt',
  );
  @override
  late final GeneratedColumn<DateTime> ruleChangedAt =
      GeneratedColumn<DateTime>(
        'rule_changed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    frequencyType,
    timesPerWeek,
    rewardHealth,
    rewardDiscipline,
    rewardCharm,
    isArchived,
    ruleChangedAt,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Habit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('times_per_week')) {
      context.handle(
        _timesPerWeekMeta,
        timesPerWeek.isAcceptableOrUnknown(
          data['times_per_week']!,
          _timesPerWeekMeta,
        ),
      );
    }
    if (data.containsKey('reward_health')) {
      context.handle(
        _rewardHealthMeta,
        rewardHealth.isAcceptableOrUnknown(
          data['reward_health']!,
          _rewardHealthMeta,
        ),
      );
    }
    if (data.containsKey('reward_discipline')) {
      context.handle(
        _rewardDisciplineMeta,
        rewardDiscipline.isAcceptableOrUnknown(
          data['reward_discipline']!,
          _rewardDisciplineMeta,
        ),
      );
    }
    if (data.containsKey('reward_charm')) {
      context.handle(
        _rewardCharmMeta,
        rewardCharm.isAcceptableOrUnknown(
          data['reward_charm']!,
          _rewardCharmMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('rule_changed_at')) {
      context.handle(
        _ruleChangedAtMeta,
        ruleChangedAt.isAcceptableOrUnknown(
          data['rule_changed_at']!,
          _ruleChangedAtMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      frequencyType: $HabitsTable.$converterfrequencyType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}frequency_type'],
        )!,
      ),
      timesPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_per_week'],
      )!,
      rewardHealth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reward_health'],
      )!,
      rewardDiscipline: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reward_discipline'],
      )!,
      rewardCharm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reward_charm'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      ruleChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rule_changed_at'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<HabitFrequency, int, int> $converterfrequencyType =
      const EnumIndexConverter<HabitFrequency>(HabitFrequency.values);
}

class Habit extends DataClass implements Insertable<Habit> {
  final int id;
  final String name;
  final String description;
  final HabitFrequency frequencyType;
  final int timesPerWeek;
  final int rewardHealth;
  final int rewardDiscipline;
  final int rewardCharm;
  final bool isArchived;

  /// 规则（频率/每周次数）最后一次变更时间；连续计数只统计此后的打卡。
  final DateTime? ruleChangedAt;
  final int sortOrder;
  final DateTime createdAt;
  const Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.frequencyType,
    required this.timesPerWeek,
    required this.rewardHealth,
    required this.rewardDiscipline,
    required this.rewardCharm,
    required this.isArchived,
    this.ruleChangedAt,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    {
      map['frequency_type'] = Variable<int>(
        $HabitsTable.$converterfrequencyType.toSql(frequencyType),
      );
    }
    map['times_per_week'] = Variable<int>(timesPerWeek);
    map['reward_health'] = Variable<int>(rewardHealth);
    map['reward_discipline'] = Variable<int>(rewardDiscipline);
    map['reward_charm'] = Variable<int>(rewardCharm);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || ruleChangedAt != null) {
      map['rule_changed_at'] = Variable<DateTime>(ruleChangedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      frequencyType: Value(frequencyType),
      timesPerWeek: Value(timesPerWeek),
      rewardHealth: Value(rewardHealth),
      rewardDiscipline: Value(rewardDiscipline),
      rewardCharm: Value(rewardCharm),
      isArchived: Value(isArchived),
      ruleChangedAt: ruleChangedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(ruleChangedAt),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      frequencyType: $HabitsTable.$converterfrequencyType.fromJson(
        serializer.fromJson<int>(json['frequencyType']),
      ),
      timesPerWeek: serializer.fromJson<int>(json['timesPerWeek']),
      rewardHealth: serializer.fromJson<int>(json['rewardHealth']),
      rewardDiscipline: serializer.fromJson<int>(json['rewardDiscipline']),
      rewardCharm: serializer.fromJson<int>(json['rewardCharm']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      ruleChangedAt: serializer.fromJson<DateTime?>(json['ruleChangedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'frequencyType': serializer.toJson<int>(
        $HabitsTable.$converterfrequencyType.toJson(frequencyType),
      ),
      'timesPerWeek': serializer.toJson<int>(timesPerWeek),
      'rewardHealth': serializer.toJson<int>(rewardHealth),
      'rewardDiscipline': serializer.toJson<int>(rewardDiscipline),
      'rewardCharm': serializer.toJson<int>(rewardCharm),
      'isArchived': serializer.toJson<bool>(isArchived),
      'ruleChangedAt': serializer.toJson<DateTime?>(ruleChangedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    HabitFrequency? frequencyType,
    int? timesPerWeek,
    int? rewardHealth,
    int? rewardDiscipline,
    int? rewardCharm,
    bool? isArchived,
    Value<DateTime?> ruleChangedAt = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
  }) => Habit(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    frequencyType: frequencyType ?? this.frequencyType,
    timesPerWeek: timesPerWeek ?? this.timesPerWeek,
    rewardHealth: rewardHealth ?? this.rewardHealth,
    rewardDiscipline: rewardDiscipline ?? this.rewardDiscipline,
    rewardCharm: rewardCharm ?? this.rewardCharm,
    isArchived: isArchived ?? this.isArchived,
    ruleChangedAt: ruleChangedAt.present
        ? ruleChangedAt.value
        : this.ruleChangedAt,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      frequencyType: data.frequencyType.present
          ? data.frequencyType.value
          : this.frequencyType,
      timesPerWeek: data.timesPerWeek.present
          ? data.timesPerWeek.value
          : this.timesPerWeek,
      rewardHealth: data.rewardHealth.present
          ? data.rewardHealth.value
          : this.rewardHealth,
      rewardDiscipline: data.rewardDiscipline.present
          ? data.rewardDiscipline.value
          : this.rewardDiscipline,
      rewardCharm: data.rewardCharm.present
          ? data.rewardCharm.value
          : this.rewardCharm,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      ruleChangedAt: data.ruleChangedAt.present
          ? data.ruleChangedAt.value
          : this.ruleChangedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('frequencyType: $frequencyType, ')
          ..write('timesPerWeek: $timesPerWeek, ')
          ..write('rewardHealth: $rewardHealth, ')
          ..write('rewardDiscipline: $rewardDiscipline, ')
          ..write('rewardCharm: $rewardCharm, ')
          ..write('isArchived: $isArchived, ')
          ..write('ruleChangedAt: $ruleChangedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    frequencyType,
    timesPerWeek,
    rewardHealth,
    rewardDiscipline,
    rewardCharm,
    isArchived,
    ruleChangedAt,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.frequencyType == this.frequencyType &&
          other.timesPerWeek == this.timesPerWeek &&
          other.rewardHealth == this.rewardHealth &&
          other.rewardDiscipline == this.rewardDiscipline &&
          other.rewardCharm == this.rewardCharm &&
          other.isArchived == this.isArchived &&
          other.ruleChangedAt == this.ruleChangedAt &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<HabitFrequency> frequencyType;
  final Value<int> timesPerWeek;
  final Value<int> rewardHealth;
  final Value<int> rewardDiscipline;
  final Value<int> rewardCharm;
  final Value<bool> isArchived;
  final Value<DateTime?> ruleChangedAt;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.frequencyType = const Value.absent(),
    this.timesPerWeek = const Value.absent(),
    this.rewardHealth = const Value.absent(),
    this.rewardDiscipline = const Value.absent(),
    this.rewardCharm = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.ruleChangedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required HabitFrequency frequencyType,
    this.timesPerWeek = const Value.absent(),
    this.rewardHealth = const Value.absent(),
    this.rewardDiscipline = const Value.absent(),
    this.rewardCharm = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.ruleChangedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       frequencyType = Value(frequencyType),
       createdAt = Value(createdAt);
  static Insertable<Habit> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? frequencyType,
    Expression<int>? timesPerWeek,
    Expression<int>? rewardHealth,
    Expression<int>? rewardDiscipline,
    Expression<int>? rewardCharm,
    Expression<bool>? isArchived,
    Expression<DateTime>? ruleChangedAt,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (frequencyType != null) 'frequency_type': frequencyType,
      if (timesPerWeek != null) 'times_per_week': timesPerWeek,
      if (rewardHealth != null) 'reward_health': rewardHealth,
      if (rewardDiscipline != null) 'reward_discipline': rewardDiscipline,
      if (rewardCharm != null) 'reward_charm': rewardCharm,
      if (isArchived != null) 'is_archived': isArchived,
      if (ruleChangedAt != null) 'rule_changed_at': ruleChangedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? description,
    Value<HabitFrequency>? frequencyType,
    Value<int>? timesPerWeek,
    Value<int>? rewardHealth,
    Value<int>? rewardDiscipline,
    Value<int>? rewardCharm,
    Value<bool>? isArchived,
    Value<DateTime?>? ruleChangedAt,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequencyType: frequencyType ?? this.frequencyType,
      timesPerWeek: timesPerWeek ?? this.timesPerWeek,
      rewardHealth: rewardHealth ?? this.rewardHealth,
      rewardDiscipline: rewardDiscipline ?? this.rewardDiscipline,
      rewardCharm: rewardCharm ?? this.rewardCharm,
      isArchived: isArchived ?? this.isArchived,
      ruleChangedAt: ruleChangedAt ?? this.ruleChangedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (frequencyType.present) {
      map['frequency_type'] = Variable<int>(
        $HabitsTable.$converterfrequencyType.toSql(frequencyType.value),
      );
    }
    if (timesPerWeek.present) {
      map['times_per_week'] = Variable<int>(timesPerWeek.value);
    }
    if (rewardHealth.present) {
      map['reward_health'] = Variable<int>(rewardHealth.value);
    }
    if (rewardDiscipline.present) {
      map['reward_discipline'] = Variable<int>(rewardDiscipline.value);
    }
    if (rewardCharm.present) {
      map['reward_charm'] = Variable<int>(rewardCharm.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (ruleChangedAt.present) {
      map['rule_changed_at'] = Variable<DateTime>(ruleChangedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('frequencyType: $frequencyType, ')
          ..write('timesPerWeek: $timesPerWeek, ')
          ..write('rewardHealth: $rewardHealth, ')
          ..write('rewardDiscipline: $rewardDiscipline, ')
          ..write('rewardCharm: $rewardCharm, ')
          ..write('isArchived: $isArchived, ')
          ..write('ruleChangedAt: $ruleChangedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CheckinsTable extends Checkins with TableInfo<$CheckinsTable, Checkin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, date, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checkins';
  @override
  VerificationContext validateIntegrity(
    Insertable<Checkin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, date},
  ];
  @override
  Checkin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Checkin(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CheckinsTable createAlias(String alias) {
    return $CheckinsTable(attachedDatabase, alias);
  }
}

class Checkin extends DataClass implements Insertable<Checkin> {
  final int id;
  final int habitId;
  final String date;
  final DateTime createdAt;
  const Checkin({
    required this.id,
    required this.habitId,
    required this.date,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['date'] = Variable<String>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CheckinsCompanion toCompanion(bool nullToAbsent) {
    return CheckinsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
      createdAt: Value(createdAt),
    );
  }

  factory Checkin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Checkin(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'date': serializer.toJson<String>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Checkin copyWith({
    int? id,
    int? habitId,
    String? date,
    DateTime? createdAt,
  }) => Checkin(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
  );
  Checkin copyWithCompanion(CheckinsCompanion data) {
    return Checkin(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Checkin(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, date, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Checkin &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.date == this.date &&
          other.createdAt == this.createdAt);
}

class CheckinsCompanion extends UpdateCompanion<Checkin> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<String> date;
  final Value<DateTime> createdAt;
  const CheckinsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CheckinsCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required String date,
    required DateTime createdAt,
  }) : habitId = Value(habitId),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<Checkin> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<String>? date,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CheckinsCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<String>? date,
    Value<DateTime>? createdAt,
  }) {
    return CheckinsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckinsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $HabitMilestonesTable extends HabitMilestones
    with TableInfo<$HabitMilestonesTable, HabitMilestone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitMilestonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<int> days = GeneratedColumn<int>(
    'days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grantedAtMeta = const VerificationMeta(
    'grantedAt',
  );
  @override
  late final GeneratedColumn<DateTime> grantedAt = GeneratedColumn<DateTime>(
    'granted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, days, grantedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_milestones';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitMilestone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    } else if (isInserting) {
      context.missing(_daysMeta);
    }
    if (data.containsKey('granted_at')) {
      context.handle(
        _grantedAtMeta,
        grantedAt.isAcceptableOrUnknown(data['granted_at']!, _grantedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_grantedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, days},
  ];
  @override
  HabitMilestone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitMilestone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
      )!,
      days: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days'],
      )!,
      grantedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}granted_at'],
      )!,
    );
  }

  @override
  $HabitMilestonesTable createAlias(String alias) {
    return $HabitMilestonesTable(attachedDatabase, alias);
  }
}

class HabitMilestone extends DataClass implements Insertable<HabitMilestone> {
  final int id;
  final int habitId;
  final int days;
  final DateTime grantedAt;
  const HabitMilestone({
    required this.id,
    required this.habitId,
    required this.days,
    required this.grantedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['days'] = Variable<int>(days);
    map['granted_at'] = Variable<DateTime>(grantedAt);
    return map;
  }

  HabitMilestonesCompanion toCompanion(bool nullToAbsent) {
    return HabitMilestonesCompanion(
      id: Value(id),
      habitId: Value(habitId),
      days: Value(days),
      grantedAt: Value(grantedAt),
    );
  }

  factory HabitMilestone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitMilestone(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      days: serializer.fromJson<int>(json['days']),
      grantedAt: serializer.fromJson<DateTime>(json['grantedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'days': serializer.toJson<int>(days),
      'grantedAt': serializer.toJson<DateTime>(grantedAt),
    };
  }

  HabitMilestone copyWith({
    int? id,
    int? habitId,
    int? days,
    DateTime? grantedAt,
  }) => HabitMilestone(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    days: days ?? this.days,
    grantedAt: grantedAt ?? this.grantedAt,
  );
  HabitMilestone copyWithCompanion(HabitMilestonesCompanion data) {
    return HabitMilestone(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      days: data.days.present ? data.days.value : this.days,
      grantedAt: data.grantedAt.present ? data.grantedAt.value : this.grantedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitMilestone(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('days: $days, ')
          ..write('grantedAt: $grantedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, days, grantedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitMilestone &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.days == this.days &&
          other.grantedAt == this.grantedAt);
}

class HabitMilestonesCompanion extends UpdateCompanion<HabitMilestone> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<int> days;
  final Value<DateTime> grantedAt;
  const HabitMilestonesCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.days = const Value.absent(),
    this.grantedAt = const Value.absent(),
  });
  HabitMilestonesCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required int days,
    required DateTime grantedAt,
  }) : habitId = Value(habitId),
       days = Value(days),
       grantedAt = Value(grantedAt);
  static Insertable<HabitMilestone> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<int>? days,
    Expression<DateTime>? grantedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (days != null) 'days': days,
      if (grantedAt != null) 'granted_at': grantedAt,
    });
  }

  HabitMilestonesCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<int>? days,
    Value<DateTime>? grantedAt,
  }) {
    return HabitMilestonesCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      days: days ?? this.days,
      grantedAt: grantedAt ?? this.grantedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (days.present) {
      map['days'] = Variable<int>(days.value);
    }
    if (grantedAt.present) {
      map['granted_at'] = Variable<DateTime>(grantedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitMilestonesCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('days: $days, ')
          ..write('grantedAt: $grantedAt')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, content, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Note copyWith({
    int? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Note(
    id: id ?? this.id,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $SubtasksTable subtasks = $SubtasksTable(this);
  late final $TaskCompletionsTable taskCompletions = $TaskCompletionsTable(
    this,
  );
  late final $HabitsTable habits = $HabitsTable(this);
  late final $CheckinsTable checkins = $CheckinsTable(this);
  late final $HabitMilestonesTable habitMilestones = $HabitMilestonesTable(
    this,
  );
  late final $NotesTable notes = $NotesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    characters,
    tasks,
    subtasks,
    taskCompletions,
    habits,
    checkins,
    habitMilestones,
    notes,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('subtasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('checkins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_milestones', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CharactersTableCreateCompanionBuilder =
    CharactersCompanion Function({
      Value<int> id,
      required String name,
      required int age,
      required String gender,
      Value<int> xp,
      Value<int> health,
      Value<int> discipline,
      Value<int> charm,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$CharactersTableUpdateCompanionBuilder =
    CharactersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> age,
      Value<String> gender,
      Value<int> xp,
      Value<int> health,
      Value<int> discipline,
      Value<int> charm,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get health => $composableBuilder(
    column: $table.health,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discipline => $composableBuilder(
    column: $table.discipline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charm => $composableBuilder(
    column: $table.charm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get health => $composableBuilder(
    column: $table.health,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discipline => $composableBuilder(
    column: $table.discipline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charm => $composableBuilder(
    column: $table.charm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<int> get health =>
      $composableBuilder(column: $table.health, builder: (column) => column);

  GeneratedColumn<int> get discipline => $composableBuilder(
    column: $table.discipline,
    builder: (column) => column,
  );

  GeneratedColumn<int> get charm =>
      $composableBuilder(column: $table.charm, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharactersTable,
          Character,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (
            Character,
            BaseReferences<_$AppDatabase, $CharactersTable, Character>,
          ),
          Character,
          PrefetchHooks Function()
        > {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> age = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<int> health = const Value.absent(),
                Value<int> discipline = const Value.absent(),
                Value<int> charm = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CharactersCompanion(
                id: id,
                name: name,
                age: age,
                gender: gender,
                xp: xp,
                health: health,
                discipline: discipline,
                charm: charm,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int age,
                required String gender,
                Value<int> xp = const Value.absent(),
                Value<int> health = const Value.absent(),
                Value<int> discipline = const Value.absent(),
                Value<int> charm = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CharactersCompanion.insert(
                id: id,
                name: name,
                age: age,
                gender: gender,
                xp: xp,
                health: health,
                discipline: discipline,
                charm: charm,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CharactersTable, Character>(table),
                  BaseReferences<_$AppDatabase, $CharactersTable, Character>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharactersTable,
      Character,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (Character, BaseReferences<_$AppDatabase, $CharactersTable, Character>),
      Character,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      required String name,
      Value<String> description,
      required TaskType type,
      Value<int> rewardHealth,
      Value<int> rewardDiscipline,
      Value<int> rewardCharm,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<String?> completedOn,
      Value<int> sortOrder,
      required DateTime createdAt,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> description,
      Value<TaskType> type,
      Value<int> rewardHealth,
      Value<int> rewardDiscipline,
      Value<int> rewardCharm,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<String?> completedOn,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SubtasksTable, List<Subtask>> _subtasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.subtasks,
    aliasName: 'tasks__id__subtasks__task_id',
  );

  $$SubtasksTableProcessedTableManager get subtasksRefs {
    final manager = $$SubtasksTableTableManager(
      $_db,
      $_db.subtasks,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subtasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskType, TaskType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get rewardHealth => $composableBuilder(
    column: $table.rewardHealth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewardDiscipline => $composableBuilder(
    column: $table.rewardDiscipline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewardCharm => $composableBuilder(
    column: $table.rewardCharm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedOn => $composableBuilder(
    column: $table.completedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> subtasksRefs(
    Expression<bool> Function($$SubtasksTableFilterComposer f) f,
  ) {
    final $$SubtasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableFilterComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewardHealth => $composableBuilder(
    column: $table.rewardHealth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewardDiscipline => $composableBuilder(
    column: $table.rewardDiscipline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewardCharm => $composableBuilder(
    column: $table.rewardCharm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedOn => $composableBuilder(
    column: $table.completedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TaskType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get rewardHealth => $composableBuilder(
    column: $table.rewardHealth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rewardDiscipline => $composableBuilder(
    column: $table.rewardDiscipline,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rewardCharm => $composableBuilder(
    column: $table.rewardCharm,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completedOn => $composableBuilder(
    column: $table.completedOn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> subtasksRefs<T extends Object>(
    Expression<T> Function($$SubtasksTableAnnotationComposer a) f,
  ) {
    final $$SubtasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableAnnotationComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({bool subtasksRefs})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<TaskType> type = const Value.absent(),
                Value<int> rewardHealth = const Value.absent(),
                Value<int> rewardDiscipline = const Value.absent(),
                Value<int> rewardCharm = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> completedOn = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                name: name,
                description: description,
                type: type,
                rewardHealth: rewardHealth,
                rewardDiscipline: rewardDiscipline,
                rewardCharm: rewardCharm,
                isCompleted: isCompleted,
                completedAt: completedAt,
                completedOn: completedOn,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> description = const Value.absent(),
                required TaskType type,
                Value<int> rewardHealth = const Value.absent(),
                Value<int> rewardDiscipline = const Value.absent(),
                Value<int> rewardCharm = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> completedOn = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
              }) => TasksCompanion.insert(
                id: id,
                name: name,
                description: description,
                type: type,
                rewardHealth: rewardHealth,
                rewardDiscipline: rewardDiscipline,
                rewardCharm: rewardCharm,
                isCompleted: isCompleted,
                completedAt: completedAt,
                completedOn: completedOn,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({subtasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (subtasksRefs) db.subtasks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (subtasksRefs)
                    await $_getPrefetchedData<Task, $TasksTable, Subtask>(
                      currentTable: table,
                      referencedTable: $$TasksTableReferences
                          ._subtasksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TasksTableReferences(db, table, p0).subtasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.taskId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({bool subtasksRefs})
    >;
typedef $$SubtasksTableCreateCompanionBuilder =
    SubtasksCompanion Function({
      Value<int> id,
      required int taskId,
      required String name,
      Value<bool> isDone,
      Value<int> sortOrder,
      required DateTime createdAt,
    });
typedef $$SubtasksTableUpdateCompanionBuilder =
    SubtasksCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<String> name,
      Value<bool> isDone,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$SubtasksTableReferences
    extends BaseReferences<_$AppDatabase, $SubtasksTable, Subtask> {
  $$SubtasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('subtasks__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubtasksTable,
          Subtask,
          $$SubtasksTableFilterComposer,
          $$SubtasksTableOrderingComposer,
          $$SubtasksTableAnnotationComposer,
          $$SubtasksTableCreateCompanionBuilder,
          $$SubtasksTableUpdateCompanionBuilder,
          (Subtask, $$SubtasksTableReferences),
          Subtask,
          PrefetchHooks Function({bool taskId})
        > {
  $$SubtasksTableTableManager(_$AppDatabase db, $SubtasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SubtasksCompanion(
                id: id,
                taskId: taskId,
                name: name,
                isDone: isDone,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required String name,
                Value<bool> isDone = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
              }) => SubtasksCompanion.insert(
                id: id,
                taskId: taskId,
                name: name,
                isDone: isDone,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubtasksTable, Subtask>(table),
                  $$SubtasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$SubtasksTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$SubtasksTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SubtasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubtasksTable,
      Subtask,
      $$SubtasksTableFilterComposer,
      $$SubtasksTableOrderingComposer,
      $$SubtasksTableAnnotationComposer,
      $$SubtasksTableCreateCompanionBuilder,
      $$SubtasksTableUpdateCompanionBuilder,
      (Subtask, $$SubtasksTableReferences),
      Subtask,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskCompletionsTableCreateCompanionBuilder =
    TaskCompletionsCompanion Function({
      Value<int> id,
      Value<int?> taskId,
      required String taskName,
      required TaskType taskType,
      required int xpGained,
      required int healthGained,
      required int disciplineGained,
      required int charmGained,
      required DateTime completedAt,
    });
typedef $$TaskCompletionsTableUpdateCompanionBuilder =
    TaskCompletionsCompanion Function({
      Value<int> id,
      Value<int?> taskId,
      Value<String> taskName,
      Value<TaskType> taskType,
      Value<int> xpGained,
      Value<int> healthGained,
      Value<int> disciplineGained,
      Value<int> charmGained,
      Value<DateTime> completedAt,
    });

class $$TaskCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskName => $composableBuilder(
    column: $table.taskName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskType, TaskType, int> get taskType =>
      $composableBuilder(
        column: $table.taskType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get xpGained => $composableBuilder(
    column: $table.xpGained,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get healthGained => $composableBuilder(
    column: $table.healthGained,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get disciplineGained => $composableBuilder(
    column: $table.disciplineGained,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charmGained => $composableBuilder(
    column: $table.charmGained,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskName => $composableBuilder(
    column: $table.taskName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpGained => $composableBuilder(
    column: $table.xpGained,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get healthGained => $composableBuilder(
    column: $table.healthGained,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get disciplineGained => $composableBuilder(
    column: $table.disciplineGained,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charmGained => $composableBuilder(
    column: $table.charmGained,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get taskName =>
      $composableBuilder(column: $table.taskName, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskType, int> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<int> get xpGained =>
      $composableBuilder(column: $table.xpGained, builder: (column) => column);

  GeneratedColumn<int> get healthGained => $composableBuilder(
    column: $table.healthGained,
    builder: (column) => column,
  );

  GeneratedColumn<int> get disciplineGained => $composableBuilder(
    column: $table.disciplineGained,
    builder: (column) => column,
  );

  GeneratedColumn<int> get charmGained => $composableBuilder(
    column: $table.charmGained,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$TaskCompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskCompletionsTable,
          TaskCompletion,
          $$TaskCompletionsTableFilterComposer,
          $$TaskCompletionsTableOrderingComposer,
          $$TaskCompletionsTableAnnotationComposer,
          $$TaskCompletionsTableCreateCompanionBuilder,
          $$TaskCompletionsTableUpdateCompanionBuilder,
          (
            TaskCompletion,
            BaseReferences<
              _$AppDatabase,
              $TaskCompletionsTable,
              TaskCompletion
            >,
          ),
          TaskCompletion,
          PrefetchHooks Function()
        > {
  $$TaskCompletionsTableTableManager(
    _$AppDatabase db,
    $TaskCompletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskCompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> taskId = const Value.absent(),
                Value<String> taskName = const Value.absent(),
                Value<TaskType> taskType = const Value.absent(),
                Value<int> xpGained = const Value.absent(),
                Value<int> healthGained = const Value.absent(),
                Value<int> disciplineGained = const Value.absent(),
                Value<int> charmGained = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => TaskCompletionsCompanion(
                id: id,
                taskId: taskId,
                taskName: taskName,
                taskType: taskType,
                xpGained: xpGained,
                healthGained: healthGained,
                disciplineGained: disciplineGained,
                charmGained: charmGained,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> taskId = const Value.absent(),
                required String taskName,
                required TaskType taskType,
                required int xpGained,
                required int healthGained,
                required int disciplineGained,
                required int charmGained,
                required DateTime completedAt,
              }) => TaskCompletionsCompanion.insert(
                id: id,
                taskId: taskId,
                taskName: taskName,
                taskType: taskType,
                xpGained: xpGained,
                healthGained: healthGained,
                disciplineGained: disciplineGained,
                charmGained: charmGained,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskCompletionsTable, TaskCompletion>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TaskCompletionsTable,
                    TaskCompletion
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskCompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskCompletionsTable,
      TaskCompletion,
      $$TaskCompletionsTableFilterComposer,
      $$TaskCompletionsTableOrderingComposer,
      $$TaskCompletionsTableAnnotationComposer,
      $$TaskCompletionsTableCreateCompanionBuilder,
      $$TaskCompletionsTableUpdateCompanionBuilder,
      (
        TaskCompletion,
        BaseReferences<_$AppDatabase, $TaskCompletionsTable, TaskCompletion>,
      ),
      TaskCompletion,
      PrefetchHooks Function()
    >;
typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> description,
      required HabitFrequency frequencyType,
      Value<int> timesPerWeek,
      Value<int> rewardHealth,
      Value<int> rewardDiscipline,
      Value<int> rewardCharm,
      Value<bool> isArchived,
      Value<DateTime?> ruleChangedAt,
      Value<int> sortOrder,
      required DateTime createdAt,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> description,
      Value<HabitFrequency> frequencyType,
      Value<int> timesPerWeek,
      Value<int> rewardHealth,
      Value<int> rewardDiscipline,
      Value<int> rewardCharm,
      Value<bool> isArchived,
      Value<DateTime?> ruleChangedAt,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, Habit> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CheckinsTable, List<Checkin>> _checkinsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.checkins,
    aliasName: 'habits__id__checkins__habit_id',
  );

  $$CheckinsTableProcessedTableManager get checkinsRefs {
    final manager = $$CheckinsTableTableManager(
      $_db,
      $_db.checkins,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_checkinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HabitMilestonesTable, List<HabitMilestone>>
  _habitMilestonesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitMilestones,
    aliasName: 'habits__id__habit_milestones__habit_id',
  );

  $$HabitMilestonesTableProcessedTableManager get habitMilestonesRefs {
    final manager = $$HabitMilestonesTableTableManager(
      $_db,
      $_db.habitMilestones,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _habitMilestonesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HabitFrequency, HabitFrequency, int>
  get frequencyType => $composableBuilder(
    column: $table.frequencyType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get timesPerWeek => $composableBuilder(
    column: $table.timesPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewardHealth => $composableBuilder(
    column: $table.rewardHealth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewardDiscipline => $composableBuilder(
    column: $table.rewardDiscipline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewardCharm => $composableBuilder(
    column: $table.rewardCharm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ruleChangedAt => $composableBuilder(
    column: $table.ruleChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> checkinsRefs(
    Expression<bool> Function($$CheckinsTableFilterComposer f) f,
  ) {
    final $$CheckinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkins,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckinsTableFilterComposer(
            $db: $db,
            $table: $db.checkins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitMilestonesRefs(
    Expression<bool> Function($$HabitMilestonesTableFilterComposer f) f,
  ) {
    final $$HabitMilestonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitMilestones,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitMilestonesTableFilterComposer(
            $db: $db,
            $table: $db.habitMilestones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frequencyType => $composableBuilder(
    column: $table.frequencyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesPerWeek => $composableBuilder(
    column: $table.timesPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewardHealth => $composableBuilder(
    column: $table.rewardHealth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewardDiscipline => $composableBuilder(
    column: $table.rewardDiscipline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewardCharm => $composableBuilder(
    column: $table.rewardCharm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ruleChangedAt => $composableBuilder(
    column: $table.ruleChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<HabitFrequency, int> get frequencyType =>
      $composableBuilder(
        column: $table.frequencyType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get timesPerWeek => $composableBuilder(
    column: $table.timesPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rewardHealth => $composableBuilder(
    column: $table.rewardHealth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rewardDiscipline => $composableBuilder(
    column: $table.rewardDiscipline,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rewardCharm => $composableBuilder(
    column: $table.rewardCharm,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ruleChangedAt => $composableBuilder(
    column: $table.ruleChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> checkinsRefs<T extends Object>(
    Expression<T> Function($$CheckinsTableAnnotationComposer a) f,
  ) {
    final $$CheckinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkins,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckinsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitMilestonesRefs<T extends Object>(
    Expression<T> Function($$HabitMilestonesTableAnnotationComposer a) f,
  ) {
    final $$HabitMilestonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitMilestones,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitMilestonesTableAnnotationComposer(
            $db: $db,
            $table: $db.habitMilestones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, $$HabitsTableReferences),
          Habit,
          PrefetchHooks Function({bool checkinsRefs, bool habitMilestonesRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<HabitFrequency> frequencyType = const Value.absent(),
                Value<int> timesPerWeek = const Value.absent(),
                Value<int> rewardHealth = const Value.absent(),
                Value<int> rewardDiscipline = const Value.absent(),
                Value<int> rewardCharm = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime?> ruleChangedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                description: description,
                frequencyType: frequencyType,
                timesPerWeek: timesPerWeek,
                rewardHealth: rewardHealth,
                rewardDiscipline: rewardDiscipline,
                rewardCharm: rewardCharm,
                isArchived: isArchived,
                ruleChangedAt: ruleChangedAt,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> description = const Value.absent(),
                required HabitFrequency frequencyType,
                Value<int> timesPerWeek = const Value.absent(),
                Value<int> rewardHealth = const Value.absent(),
                Value<int> rewardDiscipline = const Value.absent(),
                Value<int> rewardCharm = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime?> ruleChangedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                description: description,
                frequencyType: frequencyType,
                timesPerWeek: timesPerWeek,
                rewardHealth: rewardHealth,
                rewardDiscipline: rewardDiscipline,
                rewardCharm: rewardCharm,
                isArchived: isArchived,
                ruleChangedAt: ruleChangedAt,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitsTable, Habit>(table),
                  $$HabitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({checkinsRefs = false, habitMilestonesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (checkinsRefs) db.checkins,
                    if (habitMilestonesRefs) db.habitMilestones,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (checkinsRefs)
                        await $_getPrefetchedData<Habit, $HabitsTable, Checkin>(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._checkinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).checkinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.habitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (habitMilestonesRefs)
                        await $_getPrefetchedData<
                          Habit,
                          $HabitsTable,
                          HabitMilestone
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._habitMilestonesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).habitMilestonesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.habitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, $$HabitsTableReferences),
      Habit,
      PrefetchHooks Function({bool checkinsRefs, bool habitMilestonesRefs})
    >;
typedef $$CheckinsTableCreateCompanionBuilder =
    CheckinsCompanion Function({
      Value<int> id,
      required int habitId,
      required String date,
      required DateTime createdAt,
    });
typedef $$CheckinsTableUpdateCompanionBuilder =
    CheckinsCompanion Function({
      Value<int> id,
      Value<int> habitId,
      Value<String> date,
      Value<DateTime> createdAt,
    });

final class $$CheckinsTableReferences
    extends BaseReferences<_$AppDatabase, $CheckinsTable, Checkin> {
  $$CheckinsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias('checkins__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckinsTable> {
  $$CheckinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckinsTable> {
  $$CheckinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckinsTable> {
  $$CheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckinsTable,
          Checkin,
          $$CheckinsTableFilterComposer,
          $$CheckinsTableOrderingComposer,
          $$CheckinsTableAnnotationComposer,
          $$CheckinsTableCreateCompanionBuilder,
          $$CheckinsTableUpdateCompanionBuilder,
          (Checkin, $$CheckinsTableReferences),
          Checkin,
          PrefetchHooks Function({bool habitId})
        > {
  $$CheckinsTableTableManager(_$AppDatabase db, $CheckinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> habitId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CheckinsCompanion(
                id: id,
                habitId: habitId,
                date: date,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required String date,
                required DateTime createdAt,
              }) => CheckinsCompanion.insert(
                id: id,
                habitId: habitId,
                date: date,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckinsTable, Checkin>(table),
                  $$CheckinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable: $$CheckinsTableReferences
                                    ._habitIdTable(db),
                                referencedColumn: $$CheckinsTableReferences
                                    ._habitIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CheckinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckinsTable,
      Checkin,
      $$CheckinsTableFilterComposer,
      $$CheckinsTableOrderingComposer,
      $$CheckinsTableAnnotationComposer,
      $$CheckinsTableCreateCompanionBuilder,
      $$CheckinsTableUpdateCompanionBuilder,
      (Checkin, $$CheckinsTableReferences),
      Checkin,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$HabitMilestonesTableCreateCompanionBuilder =
    HabitMilestonesCompanion Function({
      Value<int> id,
      required int habitId,
      required int days,
      required DateTime grantedAt,
    });
typedef $$HabitMilestonesTableUpdateCompanionBuilder =
    HabitMilestonesCompanion Function({
      Value<int> id,
      Value<int> habitId,
      Value<int> days,
      Value<DateTime> grantedAt,
    });

final class $$HabitMilestonesTableReferences
    extends
        BaseReferences<_$AppDatabase, $HabitMilestonesTable, HabitMilestone> {
  $$HabitMilestonesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias('habit_milestones__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitMilestonesTableFilterComposer
    extends Composer<_$AppDatabase, $HabitMilestonesTable> {
  $$HabitMilestonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get grantedAt => $composableBuilder(
    column: $table.grantedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitMilestonesTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitMilestonesTable> {
  $$HabitMilestonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get grantedAt => $composableBuilder(
    column: $table.grantedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitMilestonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitMilestonesTable> {
  $$HabitMilestonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<DateTime> get grantedAt =>
      $composableBuilder(column: $table.grantedAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitMilestonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitMilestonesTable,
          HabitMilestone,
          $$HabitMilestonesTableFilterComposer,
          $$HabitMilestonesTableOrderingComposer,
          $$HabitMilestonesTableAnnotationComposer,
          $$HabitMilestonesTableCreateCompanionBuilder,
          $$HabitMilestonesTableUpdateCompanionBuilder,
          (HabitMilestone, $$HabitMilestonesTableReferences),
          HabitMilestone,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitMilestonesTableTableManager(
    _$AppDatabase db,
    $HabitMilestonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitMilestonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitMilestonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitMilestonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> habitId = const Value.absent(),
                Value<int> days = const Value.absent(),
                Value<DateTime> grantedAt = const Value.absent(),
              }) => HabitMilestonesCompanion(
                id: id,
                habitId: habitId,
                days: days,
                grantedAt: grantedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required int days,
                required DateTime grantedAt,
              }) => HabitMilestonesCompanion.insert(
                id: id,
                habitId: habitId,
                days: days,
                grantedAt: grantedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitMilestonesTable, HabitMilestone>(table),
                  $$HabitMilestonesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable:
                                    $$HabitMilestonesTableReferences
                                        ._habitIdTable(db),
                                referencedColumn:
                                    $$HabitMilestonesTableReferences
                                        ._habitIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitMilestonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitMilestonesTable,
      HabitMilestone,
      $$HabitMilestonesTableFilterComposer,
      $$HabitMilestonesTableOrderingComposer,
      $$HabitMilestonesTableAnnotationComposer,
      $$HabitMilestonesTableCreateCompanionBuilder,
      $$HabitMilestonesTableUpdateCompanionBuilder,
      (HabitMilestone, $$HabitMilestonesTableReferences),
      HabitMilestone,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      required String content,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => NotesCompanion.insert(
                id: id,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, Note>(table),
                  BaseReferences<_$AppDatabase, $NotesTable, Note>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db, _db.subtasks);
  $$TaskCompletionsTableTableManager get taskCompletions =>
      $$TaskCompletionsTableTableManager(_db, _db.taskCompletions);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$CheckinsTableTableManager get checkins =>
      $$CheckinsTableTableManager(_db, _db.checkins);
  $$HabitMilestonesTableTableManager get habitMilestones =>
      $$HabitMilestonesTableTableManager(_db, _db.habitMilestones);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
