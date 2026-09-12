# 页面切换与元素点击统一为容器变换（Container Transform）

元素点击与页面跳转的动画收敛成一套「由小到大」的语言：点列表/网格里的卡片时，从**该卡片自己的位置与尺寸**平滑放大到全屏二级页，返回时缩回原卡片（Material 的 container transform）。同时给没有任何源元素的页面跳转（以后新增的深层路由等）配一个同族的全局兜底转场。实现落在新的动效层 `lib/src/ui/motion.dart`。

**为什么必须拆成两条通道**

`ThemeData.pageTransitionsTheme` 里的 `PageTransitionsBuilder` 只拿得到 `animation`、`context` 与子页，**拿不到触发元素的位置和尺寸**——那要等路由 `didPush` 时按元素自己的 `GlobalKey` 现场测量。所以「从元素位置放大」不可能由全局主题完成，只能由 `OpenContainer`（animations 包）在路由内部自己做 `RectTween` 插值；全局主题只负责没有源元素的那种跳转，保证观感同族。

**Considered Options**
- 只配 `pageTransitionsTheme`（如 `ZoomPageTransitionsBuilder`）：被否——Android 上本来就是它，且满足不了「从元素位置和尺寸放大」这个核心诉求。
- `Hero` + 普通路由：被否——Hero 只能搬运一个「飞行 widget」，两级页面在飞行期间无法互相变形（圆角卡片 → 方角全屏页的形变、进出内容的交叉淡入都要手写），而且 Hero 与 OpenContainer 同时用会互相抢 repaint boundary。
- 自己写 `PageRouteBuilder` + 源元素 `GlobalKey` 测量：可行但要重写一遍 OpenContainer 已经做对的量测、被盖路由的隐藏（`_Hideable`）、中断转场（连点两次）等边界；被否。
- 依赖 animations 包（`^2.1.2`，Flutter 官方 flutter/packages 下的 Material 动效库，纯 Dart、无原生代码）：**采用**。release 分 ABI 包体积不变（纯 Dart 代码进 Dart AOT 快照）。

**Consequences**
- 三处二级页全部改走容器变换：习惯卡片 → 习惯详情、任务页「每日任务」入口卡 → 每日任务页、主角页设置图标 → 设置页。`Navigator.push(MaterialPageRoute)` 在这三处消失，业务逻辑、路由结果与状态管理不变（`onClosed` 承担原来 push 之后的 `_load()`）。
- 房规集中在 `openContainerTransform()`：时长 400ms、曲线 `fastOutSlowIn`、收起态透明且 `elevation: 0`（避免与 `Card` 阴影叠成双层投影）、展开态铺主题 scaffold 底色（转场中途是个逐渐长大的页面色块，不会透出下面的列表）、`tappable: false`（点击手势仍由卡片自己的 `InkWell`/`IconButton` 处理，保住水波纹与无障碍语义）。
- 系统「减少动效」（`MediaQuery.disableAnimations`）时时长压到 0，直接切页；全局兜底转场同样短路。
- **性能**：容器转场每帧都会重建整棵容器子树。收起态元素与展开态整页各包一层 `RepaintBoundary`，重建不会顺带触发元素/整页重绘；`HomeShell` 的四个标签页也各包一层，切标签不再标脏四个页面。
- **列表卡片的 Opener 必须装进一个 StatefulWidget**，不能放进 `ListView` 的 `itemBuilder` 里现建：`OpenContainer` 的状态挂在 `GlobalKey` 上，每帧换新 key 会让容器状态反复重建。
- **二级页会与源卡片同时存在于树里**（转场期间），所以 `closedBuilder`/`openBuilder` 的产物不能带同一个 `GlobalKey`。当前二级页都用 `didChangeDependencies` 里的一次性 `_loadStarted` 取数，不会被多构建一次放大成重复请求；以后新增页面要沿用这个写法。
- 转场结束后源卡片本来就不在树里（不透明路由会把被盖住的源路由从 Overlay 摘掉），所以测试不要用「找到源卡片被隐藏」来断言，改用「推上来的路由是不是 `_OpenContainerRoute`」+「转场中途透明度是不是介于 0 与 1」。
- **go_router 适配**：本项目没用 go_router（`MaterialApp.home` + `Navigator`），所以这次不动路由栈。若以后真的要上 go_router，结论是**两件事分开看**：
  - 全局兜底转场（`pageTransitionsTheme`）继续生效于 `MaterialPageRoute`/`CupertinoPageRoute`；但 go_router 的 `GoRoute.pageBuilder` 返回的 `CustomTransitionPage` 会覆盖它，需要显式带上 `transitionsBuilder: ClayPageTransitionsBuilder().buildTransitions`（或继续用 `MaterialPage` 让主题生效）。
  - 卡片这类「从元素位置放大」**没有等价物**：go_router 只能推一条新路由，而 `_OpenContainerRoute` 之所以量得到源元素，是因为它是 `ModalRoute` 且源路由在转场期间仍在树里（`OverlayEntry.opaque` 标注为 false）。真要在 go_router 下复刻，得自己实现一条同款 `PageRoute`，并把源元素的 `GlobalKey` 通过 `extra` 传进去量测——除非确实需要深链（web/桌面 URL），否则不值得为它放弃 `OpenContainer` 已经处理好的量测、隐藏与中断边界。
  - 折中做法（不推荐但可行）：继续用 `Navigator.push(OpenContainer 的容器路由)` 做动画，跳转完成后用 `GoRouter.of(context).go(...)` 同步地址栏。本项目是纯 Android，没有地址栏需求，不采用。
