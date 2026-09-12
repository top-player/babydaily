/// 动效层：容器变换（Container Transform）转场。
///
/// 两条通道，各管一段：
/// - **元素 → 二级页**：[openContainerTransform]——点列表/网格卡片时，从该卡片的
///   位置与尺寸平滑放大到全屏页；返回时缩小回原卡片（Material 的
///   container transform 模式，由 animations 包的 OpenContainer 实现）。
/// - **无源元素的页面跳转**：[buildClayPageTransitionsTheme]——配到
///   `ThemeData.pageTransitionsTheme`，让所有 `MaterialPageRoute` 走统一的
///   「放大淡入」转场，与容器变换同族、观感一致。
///
/// 为什么全局主题承担不了「从元素位置放大」：`PageTransitionsBuilder` 只拿到
/// `animation` 与子页，拿不到触发元素的位置与尺寸，所以卡片这类**有源元素**的
/// 转场必须由 OpenContainer 承担，`pageTransitionsTheme` 只做兜底。
///
/// 本项目没用 go_router（`MaterialApp.home` + `Navigator`）。若以后上 go_router：
/// 全局兜底转场仍作用于 `MaterialPageRoute`（`CustomTransitionPage` 会覆盖它，
/// 需显式带上本文件的 builder）；而「从元素位置放大」没有等价物——它依赖
/// `_OpenContainerRoute` 在转场期间仍能测到源元素。详见 ADR-0009。
library;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// 容器变换时长：M3 大容器建议 300–400ms，黏土卡片取 400ms 更从容。
const Duration kContainerTransformDuration = Duration(milliseconds: 400);

/// 无源元素的页面转场时长（M3 正向转场 300ms）。
const Duration kPageTransitionDuration = Duration(milliseconds: 300);

/// 黏土的软 3D 观感：进出用同一条强调曲线，不做回弹。
const Curve kContainerTransformCurve = Curves.fastOutSlowIn;

/// 全局页面转场的缩放起点（从没铺满的 0.92 放大到 1.0）。
const double _kPageTransitionScaleBegin = 0.92;

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

/// 容器变换 widget：把「点元素」变成「元素长大成二级页」。
///
/// 由 [openContainerTransform] 构造，一般不用自己 new。
///
/// 房规（在封装里固定，调用点不再各写一遍）：
/// - 时长/曲线统一用 [kContainerTransformDuration] 与 [kContainerTransformCurve]；
/// - 收起态**不加阴影**（透明底 + `elevation: 0`），因为黏土卡片自带 `Card`
///   阴影，再叠一层 Material 阴影会变成双层投影；
/// - 展开态铺主题的 scaffold 背景色，转场中途是个逐渐长大的页面色块，
///   不会透出下面的列表；
/// - 系统开启「减少动效」时时长压到 0，直接切页；
/// - 点击手势交给卡片自带的 `InkWell`/`IconButton`（自带水波纹与无障碍语义），
///   本封装 `tappable: false`，不再套一层 GestureDetector。
class Opener extends StatelessWidget {
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

  /// 只挂在内部的 [OpenContainer] 上。
  ///
  /// 注意别把这个 key 也传给 [Opener] 自己：同一个 GlobalKey 在一棵树里
  /// 出现两次会直接抛 "Multiple widgets used the same GlobalKey"。
  final GlobalKey<OpenContainerState<Object?>> stateKey;

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

  /// 转场中途的底色；默认取主题的 scaffold 背景色。
  final Color? middleColor;

  /// 展开态形状（默认铺满直角）。
  final ShapeBorder openShape;

  /// 是否推到根 Navigator。
  final bool useRootNavigator;

  /// 程序化打开容器（`closedBuilder` 里的 `openAction` 也是它）。
  void open() => stateKey.currentState?.openContainer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OpenContainer<Object?>(
      key: stateKey,
      // 点击交给卡片自带的 InkWell/IconButton：水波纹与语义都由它们提供。
      tappable: false,
      transitionDuration: transitionDuration,
      transitionType: transitionType,
      middleColor: middleColor ?? theme.scaffoldBackgroundColor,
      openShape: openShape,
      routeSettings: routeSettings,
      useRootNavigator: useRootNavigator,
      // 收起态不画自己的底与阴影（透明 + elevation 0）：卡片由 Card 画，
      // 再叠一层 Material 阴影会变成双层投影。
      closedColor: Colors.transparent,
      closedElevation: 0,
      closedShape: const RoundedRectangleBorder(),
      // 展开态铺页面底色：转场中容器从卡片大小长大，若底色透明会直接透出
      // 下面的列表（观感是"卡片内容浮在列表上"）；铺底色后就是一个
      // 逐渐长大的页面色块，敞开后与二级页背景同色、看不出接缝。
      openColor: theme.scaffoldBackgroundColor,
      // 阴影仍归 Card/Scaffold 自己画，容器不再加一层。
      openElevation: 0,
      onClosed: onClosed,
      // 转场期间本容器每帧重建：RepaintBoundary 把元素/整页的绘制隔开，
      // 重建不会顺带触发元素子树重绘。
      closedBuilder: (context, openContainer) => RepaintBoundary(
        child: closedBuilder(context, openContainer),
      ),
      openBuilder: (context, closeContainer) => RepaintBoundary(
        child: openBuilder(context, closeContainer),
      ),
    );
  }
}

/// 容器变换：构造一个 [Opener]。
///
/// 用法——把卡片包成一个小 StatefulWidget，`Opener` 每张卡只建一次
/// （在 `itemBuilder` 里重建 `Opener` 会同时重建它的 `GlobalKey`，
/// `OpenContainer` 的状态会跟着重来）：
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
    stateKey: GlobalKey<OpenContainerState<Object?>>(),
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
