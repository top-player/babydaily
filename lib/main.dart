import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/home_shell.dart';

/// 打开本地 SQLite（ADR-0001：应用文档目录 + drift 原生连接）。
Future<AppDatabase> _openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'babydaily.sqlite'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await _openDatabase();
  runApp(RootGate(controller: AppController(db)));
}
