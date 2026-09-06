/// 应用级控制器：持有数据库与服务、主角快照、当前场景。
///
/// 通过 InheritedNotifier 向下传递；任何写操作后 notifyListeners，
/// 页面随之重建。
library;

import 'package:flutter/widgets.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/enums.dart';
import 'package:babydaily/src/domain/game_service.dart';

class AppController extends ChangeNotifier {
  AppController(this.db) : service = GameService(db);

  final AppDatabase db;
  final GameService service;

  CharacterSnapshot? character;
  Scene scene = Scene.home;
  bool _initialized = false;
  bool get initialized => _initialized;

  bool get hasCharacter => character != null;

  Future<void> init() async {
    await _settleIfNeeded();
    character = await service.character();
    scene = await service.getScene() ?? Scene.home;
    _initialized = true;
    notifyListeners();
  }

  /// 应用回到前台/启动时，触发一次每日结算（内部幂等）。
  Future<void> settleIfNeeded() => _settleIfNeeded();

  Future<void> _settleIfNeeded() async {
    await service.settleDay(now: DateTime.now());
  }

  Future<void> createCharacter({
    required String name,
    required int age,
    required Gender gender,
  }) async {
    await service.createCharacter(name: name, age: age, gender: gender);
    await service.setSetting('onboarding_done', '1');
    character = await service.character();
    notifyListeners();
  }

  Future<void> updateCharacterProfile({
    required String name,
    required int age,
    required Gender gender,
  }) async {
    await service.updateCharacterProfile(name: name, age: age, gender: gender);
    character = await service.character();
    notifyListeners();
  }

  Future<void> setScene(Scene value) async {
    scene = value;
    notifyListeners();
    await service.setScene(value);
  }

  bool get onboardingDone =>
      _initialized && (character != null); // 主角存在即视为引导完成

  @override
  void dispose() {
    db.close();
    super.dispose();
  }
}

/// 便于页面取用的 InheritedNotifier。
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({super.key, required super.notifier, required super.child});

  static AppController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppScope>()!
      .notifier!;
}
