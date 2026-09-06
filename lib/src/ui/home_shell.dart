/// 应用外壳：主题（随场景切换）、根导航与生命周期结算。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/character_page.dart';
import 'package:babydaily/src/ui/habits_page.dart';
import 'package:babydaily/src/ui/onboarding.dart';
import 'package:babydaily/src/ui/tasks_page.dart';
import 'package:babydaily/src/ui/theme.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key, required this.controller});

  final AppController controller;

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 回到前台触发一次每日结算（内部幂等）
      widget.controller.settleIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AppScope(
      notifier: controller,
      child: Builder(builder: (context) {
        final scope = AppScope.of(context);
        return MaterialApp(
          title: '宝宝日常',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(scope.scene),
          home: switch ((scope.initialized, scope.hasCharacter)) {
            (false, _) => const _SplashPage(),
            (true, false) => const OnboardingPage(),
            (true, true) => const HomeShell(),
          },
        );
      }),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('🐣', style: TextStyle(fontSize: 64))),
    );
  }
}

/// 主界面：主角 / 任务 / 习惯 / 笔记 四个标签。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          CharacterPage(),
          TasksPage(),
          HabitsPage(),
          NotesPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.face_outlined), label: '主角'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: '任务'),
          NavigationDestination(icon: Icon(Icons.local_fire_department_outlined), label: '习惯'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), label: '笔记'),
        ],
      ),
    );
  }
}

// 笔记页在后续提交中实现。
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('笔记'));
}
