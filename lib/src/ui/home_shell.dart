/// 应用外壳：主题（随场景切换）、根导航与生命周期结算。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/character_page.dart';
import 'package:babydaily/src/ui/habits_page.dart';
import 'package:babydaily/src/ui/motion.dart';
import 'package:babydaily/src/ui/notes_page.dart';
import 'package:babydaily/src/ui/onboarding.dart';
import 'package:babydaily/src/ui/tasks_page.dart';
import 'package:babydaily/src/ui/theme.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key, required this.controller, this.navigatorObservers});

  final AppController controller;

  /// 追加到根 Navigator 的观察者（测试用来核对推的是哪条路由）。
  final List<NavigatorObserver>? navigatorObservers;

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
      // 回到前台触发一次每日结算与每日登录经验（内部幂等）
      widget.controller.settleIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AppScope(
      notifier: controller,
      child: Builder(
        builder: (context) {
          final scope = AppScope.of(context);
          return MaterialApp(
            title: '宝宝日常',
            debugShowCheckedModeBanner: false,
            navigatorObservers: widget.navigatorObservers ?? const [],
            theme: buildTheme(scope.scene),
            darkTheme: buildTheme(scope.scene, brightness: Brightness.dark),
            themeMode: ThemeMode.system,
            home: switch ((scope.initialized, scope.hasCharacter)) {
              (false, _) => const _SplashPage(),
              (true, false) => const OnboardingPage(),
              (true, true) => const HomeShell(),
            },
          );
        },
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x228A6A3B),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Text('🐣', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 24),
            Text(
              '宝宝日常',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('轻轻松松，长成自己的样子', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// 主界面：主角 / 任务 / 习惯 / 笔记 四个标签。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  /// 四个标签页。必须保持常量实例（见 [build] 的注释）。
  static const List<Widget> _tabPages = <Widget>[
    RepaintBoundary(child: CharacterPage()),
    RepaintBoundary(child: TasksPage()),
    RepaintBoundary(child: HabitsPage()),
    RepaintBoundary(child: NotesPage()),
  ];

  /// 0..3 的「页面位置」。注意 AnimationController 的值域默认是 0..1，
  /// 必须显式给 `upperBound`，否则 animateTo(2) 会被夹到 1。
  late final AnimationController _pagePosition = AnimationController(
    vsync: this,
    duration: kTabSlideDuration,
    upperBound: 3,
    value: 0,
  );

  @override
  void dispose() {
    _pagePosition.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    // 系统「减少动效」：直接落位，不滑。
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _pagePosition.value = index.toDouble();
      return;
    }
    _pagePosition.animateTo(
      index.toDouble(),
      duration: kTabSlideDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 四个标签页排成一行，按 _pagePosition 平移切页（新页滑入、旧页滑出）。
      // 每页都是常量实例，动画帧只重建很薄的包装层、不重建页面子树。
      body: ClipRect(
        child: Stack(
          children: [
            for (var i = 0; i < _tabPages.length; i++)
              Positioned.fill(
                key: ValueKey<int>(i),
                child: _SlotPage(
                  slot: i,
                  position: _pagePosition,
                  child: _tabPages[i],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.face_outlined),
            selectedIcon: Icon(Icons.face),
            label: '主角',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: '任务',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: '习惯',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: '笔记',
          ),
        ],
      ),
    );
  }
}

/// 滑轨上的一格：按与当前位置的差距水平平移，完全滑出屏幕后不布局不绘制。
///
/// [child] 通过 [AnimatedBuilder] 的 `child` 参数传入，动画帧不会重建页面
/// 子树——切标签只是平移，不会让页面重新挂载（重新取数、丢滚动位置）。
///
/// 只平移、**不做透明度渐隐**：原来两层整屏 `Opacity` 会让光栅线程每帧各开一张
/// 离屏缓冲，而且滑到一半时两页都只剩 20% 不透明、整屏发白。两页都是不透明的
/// 整屏页面，直接滑过去（ViewPager 那种观感）更快也更干净。
///
/// 离屏页用 [Offstage] 关掉：它保留 State、不布局不绘制，
/// 而且和 `IndexedStack` 一样让屏外页面在 `find.text` 这类默认
/// `skipOffstage: true` 的查找里不可见（否则四个页面里同名的「任务」「习惯」
/// 文案会互相打架）。
class _SlotPage extends StatelessWidget {
  const _SlotPage({
    required this.slot,
    required this.position,
    required this.child,
  });

  /// 本页所在槽位（0..3）。
  final int slot;

  /// 0..3 的页面位置。
  final Animation<double> position;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: position,
      child: child,
      builder: (context, page) {
        final distance = slot - position.value;
        final width = MediaQuery.sizeOf(context).width;
        return Transform.translate(
          // 第 i 页平时的位置在 i 页宽处，减去当前平移量就是它现在该在的位置。
          offset: Offset(distance * width, 0),
          child: Offstage(
            // 完全滑出屏幕就不布局/不绘制，也不进 finder（页面 State 保留）。
            offstage: distance.abs() >= 1,
            child: page,
          ),
        );
      },
    );
  }
}

