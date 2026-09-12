/// 动效层：容器变换（Container Transform）与页面转场。
///
/// 两条通道，各管一段：
/// - **元素 → 二级页**：[openContainerTransform]——点列表/网格卡片时，从该卡片的
///   位置与尺寸平滑放大到全屏页；返回时缩小回原卡片（Material 的
///   container transform 模式）。
/// - **无源元素的页面跳转**：[buildClayPageTransitionsTheme]——配到
///   `ThemeData.pageTransitionsTheme`，让所有 `MaterialPageRoute` 走统一的
///   「放大淡入」转场，与容器变换同族、观感一致。
///
/// 为什么全局主题承担不了「从元素位置放大」：`PageTransitionsBuilder` 只拿到
/// `animation` 与子页，拿不到触发元素的位置与尺寸，所以卡片这类**有源元素**的
/// 转场必须由容器路由承担，`pageTransitionsTheme` 只做兜底。
///
/// 容器变换是**自研**的（没用 `animations` 包的 `OpenContainer`）：包的实现给
/// 底层路由盖了一层 `Colors.black54` 遮罩，转场期间整屏被压暗，缩小的卡片四角
/// 就成了「亮块压在暗底上」的硬边、颜色也和对不齐；自研 [ModalRoute] 才能把
/// `barrierColor` 设成 null。详见 ADR-0009。
///
/// 本项目没用 go_router（`MaterialApp.home` + `Navigator`）。若以后上 go_router：
/// 全局兜底转场仍作用于 `MaterialPageRoute`（`CustomTransitionPage` 会覆盖它，
/// 需显式带上本文件的 builder）；而「从元素位置放大」没有等价物——它依赖容器
/// 路由在转场期间仍能测到源元素。详见 ADR-0009。
library;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 容器变换时长：M3 大容器建议 300–400ms，黏土卡片取 400ms 更从容。
const Duration kContainerTransformDuration = Duration(milliseconds: 400);

/// 无源元素的页面转场时长（M3 正向转场 300ms）。
const Duration kPageTransitionDuration = Duration(milliseconds: 300);

/// 底部导航切页的滑动时长（比 M3 的 300ms 略快，跟手感更紧）。
const Duration kTabSlideDuration = Duration(milliseconds: 280);

/// 场景切换指示块的滑动时长（和 M3 主题色过渡的 200ms 同量级）。
const Duration kSceneSwitchDuration = Duration(milliseconds: 240);

/// 黏土的软 3D 观感：进出用同一条强调曲线，不做回弹。
const Curve kContainerTransformCurve = Curves.fastOutSlowIn;

/// 全局页面转场的缩放起点（从没铺满的 0.92 放大到 1.0）。
const double _kPageTransitionScaleBegin = 0.92;

/// 容器边缘的圆角（与黏土卡片的 22 一致）。
const BorderRadius _kContainerRadius = BorderRadius.all(Radius.circular(22));

/// 全局页面转场：按容器变换观感缩放的 [PageTransitionsBuilder]。
///
/// 用作 `pageTransitionsTheme` 的兜底——凡是没有源元素的 `MaterialPageRoute`
/// （例如以后新增的深层路由、或从 FAB 直接推的页）都走它，与卡片的容器变换
/// 保持同一种「由小到大」的语言。
///
/// 有源元素的卡片点击**不要**走这里（拿不到元素位置），用 [openContainerTransform]。
class ClayPageTransitionsBuilder extends PageTransitionsBuilder {
  /// 构造器。
  const ClayPageTransitionsBuilder();

  @override
  Duration get transitionDuration => kPageTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 首屏不做入场动画（与 MaterialPageRoute 的默认行为一致）。
    if (route.isFirst) return child;
    // 系统「减少动效」开关：直接落到终态。
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: kContainerTransformCurve,
      reverseCurve: kContainerTransformCurve.flipped,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: _kPageTransitionScaleBegin,
          end: 1,
        ).animate(curved),
        // 从偏上位置长大，与「卡片向上铺满全屏」同向。
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }
}

/// 全局页面转场主题：所有平台共用一个 builder，避免各端观感分叉。
PageTransitionsTheme buildClayPageTransitionsTheme() {
  const builder = ClayPageTransitionsBuilder();
  return const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: builder,
      TargetPlatform.iOS: builder,
      TargetPlatform.fuchsia: builder,
      TargetPlatform.linux: builder,
      TargetPlatform.macOS: builder,
      TargetPlatform.windows: builder,
    },
  );
}

/// 容器变换：构造一个 [Opener]。
///
/// 用法——把卡片包成一个小 StatefulWidget，`Opener` 每张卡只建一次
/// （在 `itemBuilder` 里重建 `Opener` 会同时重建它的 `GlobalKey`，
/// 容器状态会跟着重来）：
///
/// ```dart
/// class _HabitCard extends StatefulWidget {
///   const _HabitCard({required this.habit, required this.onReload});
///   final Habit habit;
///   final Future<void> Function() onReload;
///   @override
///   State<_HabitCard> createState() => _HabitCardState();
/// }
///
/// class _HabitCardState extends State<_HabitCard> {
///   late final Opener _opener = openContainerTransform(
///     context: context,
///     openBuilder: (context, close) => HabitDetailPage(habit: widget.habit),
///     closedBuilder: (context, open) => Card(
///       child: InkWell(onTap: open, child: _content()),
///     ),
///     onClosed: (_) => widget.onReload(),
///   );
///
///   @override
///   Widget build(BuildContext context) => _opener;
/// }
/// ```
///
/// 卡片需要局部状态（折叠、动画等）时把 `closedBuilder` 收到的 `open`
/// 传给它自己的 `onTap` 即可；本封装不代替卡片处理点击。
Opener openContainerTransform({
  required BuildContext context,
  required Widget Function(BuildContext context, VoidCallback openAction)
  closedBuilder,
  required Widget Function(BuildContext context, VoidCallback closeAction)
  openBuilder,
  ClosedCallback<Object?>? onClosed,
  RouteSettings? routeSettings,
  Duration transitionDuration = kContainerTransformDuration,
  ContainerTransitionType transitionType = ContainerTransitionType.fadeThrough,
  Color? middleColor,
  ShapeBorder openShape = const RoundedRectangleBorder(),
  bool useRootNavigator = false,
}) {
  // 「减少动效」在这里读一次：调用点都在 build 阶段（含 State 字段的
  // late 初始化），重建时会重新求值。
  final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return Opener._(
    stateKey: GlobalKey<ClayOpenContainerState>(),
    closedBuilder: closedBuilder,
    openBuilder: openBuilder,
    onClosed: onClosed,
    routeSettings: routeSettings,
    transitionDuration: reduceMotion ? Duration.zero : transitionDuration,
    transitionType: transitionType,
    middleColor: middleColor,
    openShape: openShape,
    useRootNavigator: useRootNavigator,
  );
}

/// 容器变换 widget：把「点元素」变成「元素长大成二级页」。
///
/// 由 [openContainerTransform] 构造，一般不用自己 new。
///
/// 收起态与展开态的构造器都做成**入参**（而不是塞在 State 里的字段）：
/// 调用点 `setState` 重建时，新的 builder 会随新 widget 实例传下来，
/// [State.didUpdateWidget] 才会把卡片重新构建一遍。若把 builder 固定在
/// State 里，页面数据刷新后卡片会一直停在旧内容上。
///
/// 房规（在封装里固定，调用点不再各写一遍）：
/// - 时长/曲线统一用 [kContainerTransformDuration] 与 [kContainerTransformCurve]；
/// - 容器**无遮罩**：转场期间不压暗底下的页面；
/// - 容器底色取卡片表面色（Card 未指定颜色时是 `colorScheme.surface`），
///   与卡片同色，四角不会透出另一种颜色；
/// - 容器不加自己的阴影（`elevation: 0`），阴影归卡片/二级页自己画；
/// - 系统开启「减少动效」时时长压到 0，直接切页；
/// - 点击手势交给卡片自带的 `InkWell`/`IconButton`（自带水波纹与无障碍语义），
///   本封装默认 `tappable: false`，不再套一层 GestureDetector。
class Opener extends StatefulWidget {
  const Opener._({
    required this.stateKey,
    required this.closedBuilder,
    required this.openBuilder,
    this.onClosed,
    this.routeSettings,
    this.transitionDuration = kContainerTransformDuration,
    this.transitionType = ContainerTransitionType.fadeThrough,
    this.middleColor,
    this.openShape = const RoundedRectangleBorder(),
    this.useRootNavigator = false,
  });

  /// 只挂在内部的容器上。
  ///
  /// 注意别把这个 key 也传给 [Opener] 自己：同一个 GlobalKey 在一棵树里
  /// 出现两次会直接抛 "Multiple widgets used the same GlobalKey"。
  final GlobalKey<ClayOpenContainerState> stateKey;

  /// 收起态元素构造器（`openAction` 可主动打开容器）。
  final Widget Function(BuildContext context, VoidCallback openAction)
  closedBuilder;

  /// 展开态全屏页构造器（`closeAction` 可关掉容器）。
  final Widget Function(BuildContext context, VoidCallback closeAction)
  openBuilder;

  /// 关闭回调，拿到二级页 pop 出来的返回值。
  final ClosedCallback<Object?>? onClosed;

  /// 传给展开态路由的设置（name、arguments 等）。
  final RouteSettings? routeSettings;

  /// 转场时长（0 = 不做动画，直接切页）。
  final Duration transitionDuration;

  /// 淡入淡出类型。
  final ContainerTransitionType transitionType;

  /// 转场中途的底色；默认取卡片表面色。
  final Color? middleColor;

  /// 展开态形状（默认铺满直角）。
  final ShapeBorder openShape;

  /// 是否推到根 Navigator。
  final bool useRootNavigator;

  /// 程序化打开容器（`closedBuilder` 里的 `openAction` 也是它）。
  void open() => stateKey.currentState?.openContainer();

  @override
  State<Opener> createState() => _OpenerState();
}

class _OpenerState extends State<Opener> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 卡片表面色：转场期间容器里画的是「淡出的源卡片」，容器底色必须与它同色，
    // 否则四角会透出底色变成另一种颜色。
    final cardSurface = theme.cardTheme.color ?? theme.colorScheme.surface;
    return RepaintBoundary(
      child: _ClayOpenContainer(
        key: widget.stateKey,
        // 点击交给卡片自带的 InkWell/IconButton：水波纹与语义都由它们提供。
        tappable: false,
        transitionDuration: widget.transitionDuration,
        transitionType: widget.transitionType,
        middleColor: widget.middleColor ?? cardSurface,
        openColor: cardSurface,
        openShape: widget.openShape,
        routeSettings: widget.routeSettings,
        useRootNavigator: widget.useRootNavigator,
        onClosed: widget.onClosed,
        // builder 每次都从 widget 上取：调用点 setState 后卡片跟着新数据重建。
        closedBuilder: widget.closedBuilder,
        openBuilder: (context, closeContainer) => RepaintBoundary(
          child: widget.openBuilder(context, closeContainer),
        ),
      ),
    );
  }
}

/// 容器变换的状态槽：收起态就是那个元素，点击后推一条容器路由。
class _ClayOpenContainer extends StatefulWidget {
  const _ClayOpenContainer({
    super.key,
    required this.tappable,
    required this.transitionDuration,
    required this.transitionType,
    required this.middleColor,
    required this.openColor,
    required this.openShape,
    required this.onClosed,
    required this.closedBuilder,
    required this.openBuilder,
    required this.useRootNavigator,
    this.routeSettings,
  });

  final bool tappable;
  final Duration transitionDuration;
  final ContainerTransitionType transitionType;
  final Color middleColor;
  final Color openColor;
  final ShapeBorder openShape;
  final ClosedCallback<Object?>? onClosed;
  final CloseContainerBuilder closedBuilder;
  final OpenContainerBuilder<Object?> openBuilder;
  final bool useRootNavigator;
  final RouteSettings? routeSettings;

  @override
  State<_ClayOpenContainer> createState() => ClayOpenContainerState();
}

/// [Opener] 的容器状态：收起态就是那个元素，点击后推一条容器路由。
///
/// 公开只是为了 [Opener.stateKey] 能放进 `GlobalKey`（`Opener.open()` 靠它
/// 程序化打开容器）；调用点不需要直接用它。
class ClayOpenContainerState extends State<_ClayOpenContainer> {
  /// 收起态被容器接管时，源路由里那一个换成同尺寸的占位（避免出现两份卡片）。
  final GlobalKey<_HideableState> _hideableKey = GlobalKey<_HideableState>();

  /// 转场期间把收起态元素的 State 从源路由搬进容器里复用。
  final GlobalKey _closedBuilderKey = GlobalKey();

  /// 打开容器：推一条容器路由，返回后回调 `onClosed`。
  Future<void> openContainer() async {
    final data = await Navigator.of(
      context,
      rootNavigator: widget.useRootNavigator,
    ).push<Object?>(
      _ClayContainerRoute(
        openColor: widget.openColor,
        middleColor: widget.middleColor,
        openShape: widget.openShape,
        transitionDuration: widget.transitionDuration,
        transitionType: widget.transitionType,
        closedBuilder: widget.closedBuilder,
        openBuilder: widget.openBuilder,
        hideableKey: _hideableKey,
        closedBuilderKey: _closedBuilderKey,
        useRootNavigator: widget.useRootNavigator,
        routeSettings: widget.routeSettings,
      ),
    );
    widget.onClosed?.call(data);
  }

  @override
  Widget build(BuildContext context) {
    // 不画自己的底与阴影：卡片由 Card 自己画，再叠一层 Material 阴影会变成
    // 双层投影。
    final child = Builder(
      key: _closedBuilderKey,
      builder: (context) => widget.closedBuilder(context, openContainer),
    );
    return _Hideable(
      key: _hideableKey,
      // 只有「整块可点」时才套一层 GestureDetector：它是 opaque 的、会吃掉
      // 尺寸（在无界约束下直接报 "given an infinite size"），而本项目三个
      // 调用点都是 tappable: false（点击交给卡片自己的 InkWell/IconButton，
      // 水波纹与无障碍语义都归它们）。
      child: widget.tappable
          ? GestureDetector(onTap: openContainer, child: child)
          : child,
    );
  }
}

/// 容器路由：从源元素矩形长大到整屏，返回时缩回。
///
/// 与 `animations` 包的 `_OpenContainerRoute` 同构，差别只有两条：
/// 无遮罩（[barrierColor] 为 null），以及收起态元素按「量到的原始尺寸」绘制。
class _ClayContainerRoute extends ModalRoute<Object?> {
  _ClayContainerRoute({
    required this.openColor,
    required this.middleColor,
    required this.openShape,
    required this.transitionDuration,
    required this.transitionType,
    required this.closedBuilder,
    required this.openBuilder,
    required this.hideableKey,
    required this.closedBuilderKey,
    required this.useRootNavigator,
    required RouteSettings? routeSettings,
  }) : _colorTween = _colorTweenFor(
         transitionType: transitionType,
         closedColor: middleColor,
         middleColor: middleColor,
         openColor: openColor,
       ),
       _closedOpacityTween = _closedOpacityTweenFor(transitionType),
       _openOpacityTween = _openOpacityTweenFor(transitionType),
       super(settings: routeSettings);

  final Color openColor;
  final Color middleColor;
  final ShapeBorder openShape;

  @override
  final Duration transitionDuration;
  final ContainerTransitionType transitionType;
  final CloseContainerBuilder closedBuilder;
  final OpenContainerBuilder<Object?> openBuilder;

  /// 源路由里收起态元素的可见性开关。
  final GlobalKey<_HideableState> hideableKey;

  /// 把源路由里收起态元素的 State 搬进容器的钥匙。
  final GlobalKey closedBuilderKey;

  final bool useRootNavigator;

  final _FlippableTweenSequence<Color?> _colorTween;
  final _FlippableTweenSequence<double> _closedOpacityTween;
  final _FlippableTweenSequence<double> _openOpacityTween;

  /// 收起态 → 整屏的尺寸插值（`begin` 在 [didPush] 里现场量）。
  final RectTween _rectTween = RectTween();

  /// 二级页的钥匙：动画收尾时树形结构会变（去掉转场的临时代码），靠它保住 State。
  final GlobalKey _openBuilderKey = GlobalKey();

  AnimationStatus? _lastStatus;
  AnimationStatus? _currentStatus;

  static _FlippableTweenSequence<Color?> _colorTweenFor({
    required ContainerTransitionType transitionType,
    required Color closedColor,
    required Color middleColor,
    required Color openColor,
  }) {
    switch (transitionType) {
      case ContainerTransitionType.fade:
        return _FlippableTweenSequence<Color?>(<TweenSequenceItem<Color?>>[
          TweenSequenceItem<Color>(
            tween: ConstantTween<Color>(closedColor),
            weight: 1 / 5,
          ),
          TweenSequenceItem<Color?>(
            tween: ColorTween(begin: closedColor, end: openColor),
            weight: 1 / 5,
          ),
          TweenSequenceItem<Color>(
            tween: ConstantTween<Color>(openColor),
            weight: 3 / 5,
          ),
        ]);
      case ContainerTransitionType.fadeThrough:
        return _FlippableTweenSequence<Color?>(<TweenSequenceItem<Color?>>[
          TweenSequenceItem<Color?>(
            tween: ColorTween(begin: closedColor, end: middleColor),
            weight: 1 / 5,
          ),
          TweenSequenceItem<Color?>(
            tween: ColorTween(begin: middleColor, end: openColor),
            weight: 4 / 5,
          ),
        ]);
    }
  }

  static _FlippableTweenSequence<double> _closedOpacityTweenFor(
    ContainerTransitionType transitionType,
  ) {
    switch (transitionType) {
      case ContainerTransitionType.fade:
        return _FlippableTweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 1),
        ]);
      case ContainerTransitionType.fadeThrough:
        return _FlippableTweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1, end: 0),
            weight: 1 / 5,
          ),
          TweenSequenceItem<double>(
            tween: ConstantTween<double>(0),
            weight: 4 / 5,
          ),
        ]);
    }
  }

  static _FlippableTweenSequence<double> _openOpacityTweenFor(
    ContainerTransitionType transitionType,
  ) {
    switch (transitionType) {
      case ContainerTransitionType.fade:
        return _FlippableTweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: ConstantTween<double>(0),
            weight: 1 / 5,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0, end: 1),
            weight: 1 / 5,
          ),
          TweenSequenceItem<double>(
            tween: ConstantTween<double>(1),
            weight: 3 / 5,
          ),
        ]);
      case ContainerTransitionType.fadeThrough:
        return _FlippableTweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: ConstantTween<double>(0),
            weight: 1 / 5,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0, end: 1),
            weight: 4 / 5,
          ),
        ]);
    }
  }

  /// 关掉容器：直接 pop 这条路由。
  void closeContainer({Object? returnValue}) {
    Navigator.of(subtreeContext!, rootNavigator: useRootNavigator).pop(returnValue);
  }

  @override
  bool get maintainState => true;

  /// 无遮罩：转场期间不压暗底下的页面（四角伪影的根因，见类文档）。
  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => true;

  @override
  TickerFuture didPush() {
    _takeMeasurements(hideableKey.currentContext!);
    animation!.addStatusListener(_onAnimationStatus);
    return super.didPush();
  }

  @override
  bool didPop(Object? result) {
    // 返回时源元素在底下（可能还在 rebuild），下一帧再量。
    _takeMeasurements(subtreeContext!, delayForSourceRoute: true);
    return super.didPop(result);
  }

  void _onAnimationStatus(AnimationStatus status) {
    _lastStatus = _currentStatus;
    _currentStatus = status;
    switch (status) {
      case AnimationStatus.dismissed:
        _toggleHideable(hide: false);
      case AnimationStatus.completed:
        _toggleHideable(hide: true);
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
    }
  }

  /// 源路由里那个收起态元素：隐藏时留同尺寸占位，避免出现两份卡片。
  void _toggleHideable({required bool hide}) {
    hideableKey.currentState
      ?..placeholderSize = null
      ..isVisible = !hide;
  }

  void _takeMeasurements(
    BuildContext sourceContext, {
    bool delayForSourceRoute = false,
  }) {
    final navigator =
        Navigator.of(
              sourceContext,
              rootNavigator: useRootNavigator,
            ).context.findRenderObject()!
            as RenderBox;
    _rectTween.end = Offset.zero & navigator.size;

    void measureSource() {
      final hideable = hideableKey.currentState;
      final source = hideableKey.currentContext;
      if (hideable == null || source == null || !navigator.attached) return;
      final render = source.findRenderObject()! as RenderBox;
      _rectTween.begin = MatrixUtils.transformRect(
        render.getTransformTo(navigator),
        Offset.zero & render.size,
      );
      // 量完立刻把源元素换成占位：转场期间容器里画的是同一个元素。
      hideable.placeholderSize = _rectTween.begin!.size;
    }

    if (delayForSourceRoute) {
      SchedulerBinding.instance.addPostFrameCallback((_) => measureSource());
    } else {
      measureSource();
    }
  }

  /// 转场是否被打断过（连点两次）：打断后不再翻转透明度序列，否则回弹时闪。
  bool get _interrupted {
    bool running(AnimationStatus? status) =>
        status == AnimationStatus.forward || status == AnimationStatus.reverse;
    return running(_lastStatus) && running(_currentStatus);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        if (animation.isCompleted) {
          return SizedBox.expand(
            child: Material(
              color: openColor,
              shape: openShape,
              child: RepaintBoundary(
                child: Builder(
                  key: _openBuilderKey,
                  builder: (context) => openBuilder(context, closeContainer),
                ),
              ),
            ),
          );
        }

        final curved = CurvedAnimation(
          parent: animation,
          curve: kContainerTransformCurve,
          reverseCurve: _interrupted
              ? null
              : kContainerTransformCurve.flipped,
        );
        final TweenSequence<Color?> colorTween;
        final TweenSequence<double> closedOpacityTween;
        final TweenSequence<double> openOpacityTween;
        if (animation.status == AnimationStatus.reverse && !_interrupted) {
          // 收起：先缩页面，再让卡片浮现。
          colorTween = _colorTween.flipped;
          closedOpacityTween = _closedOpacityTween.flipped;
          openOpacityTween = _openOpacityTween.flipped;
        } else {
          colorTween = _colorTween;
          closedOpacityTween = _closedOpacityTween;
          openOpacityTween = _openOpacityTween;
        }

        final screen = MediaQuery.sizeOf(context);
        final rect = _rectTween.evaluate(curved)!;
        final sourceRect = _rectTween.begin ?? rect;
        return SizedBox.expand(
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: rect.topLeft,
              child: SizedBox(
                width: rect.width,
                height: rect.height,
                child: Material(
                  clipBehavior: Clip.antiAlias,
                  animationDuration: Duration.zero,
                  color: colorTween.evaluate(animation),
                  shape: ShapeBorderTween(
                    begin: const RoundedRectangleBorder(
                      borderRadius: _kContainerRadius,
                    ),
                    end: openShape,
                  ).evaluate(curved),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      // 收起态元素淡出。FittedBox 把元素按**自身尺寸**布局后整体
                      // 缩放到容器宽度；SizedBox 给出确定尺寸，否则 FittedBox 会
                      // 把无界约束透传给里面的卡片（RenderPointerListener 报
                      // "given an infinite size"）。
                      ClipRect(
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: sourceRect.width,
                            height: sourceRect.height,
                            child: FadeTransition(
                              opacity: closedOpacityTween.animate(animation),
                              // 注意：这里**不能**用 closedBuilderKey——
                              // 源路由里那个元素还活着（由 _Hideable 占位遮住），
                              // 同一帧两棵树各挂一个同名 GlobalKey 会直接抛
                              // "Multiple widgets used the same GlobalKey"。
                              // 容器里这份只是一张用来淡出的画，State 不需要搬。
                              child: Builder(
                                builder: (context) =>
                                    closedBuilder(context, () {}),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 二级页淡入：按整屏尺寸布局后整体缩放，容器只负责裁剪。
                      ClipRect(
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: screen.width,
                            height: screen.height,
                            child: FadeTransition(
                              opacity: openOpacityTween.animate(animation),
                              child: Builder(
                                key: _openBuilderKey,
                                builder: (context) =>
                                    openBuilder(context, closeContainer),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 控制子树可见性：不可见时留同尺寸占位（转场期间源元素不画但仍占位）。
class _Hideable extends StatefulWidget {
  const _Hideable({super.key, required this.child});

  final Widget child;

  @override
  State<_Hideable> createState() => _HideableState();
}

class _HideableState extends State<_Hideable> {
  /// 非空时子树整个换成同尺寸的 `SizedBox`。
  Size? get placeholderSize => _placeholderSize;
  Size? _placeholderSize;
  set placeholderSize(Size? value) {
    if (_placeholderSize == value) return;
    setState(() => _placeholderSize = value);
  }

  /// 为真时子树留在树里但不画。
  bool get isVisible => _visible;
  bool _visible = true;
  set isVisible(bool value) {
    if (_visible == value) return;
    setState(() => _visible = value);
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = _placeholderSize;
    if (placeholder != null) {
      return SizedBox.fromSize(size: placeholder);
    }
    return Visibility(
      visible: _visible,
      maintainSize: true,
      maintainState: true,
      maintainAnimation: true,
      child: widget.child,
    );
  }
}

/// 可翻转（正放/倒放）的补间序列，转场反向时权重也镜像过来。
class _FlippableTweenSequence<T> extends TweenSequence<T> {
  _FlippableTweenSequence(this._items) : super(_items);

  final List<TweenSequenceItem<T>> _items;
  _FlippableTweenSequence<T>? _flipped;

  _FlippableTweenSequence<T> get flipped {
    _flipped ??= _FlippableTweenSequence<T>(<TweenSequenceItem<T>>[
      for (var i = 0; i < _items.length; i++)
        TweenSequenceItem<T>(
          tween: _items[i].tween,
          weight: _items[_items.length - 1 - i].weight,
        ),
    ]);
    return _flipped!;
  }
}
