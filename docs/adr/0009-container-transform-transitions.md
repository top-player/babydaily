# 页面切换与元素点击统一为容器变换（Container Transform）

元素点击与页面跳转的动画收敛成一套「由小到大」的语言：点列表/网格里的卡片时，从**该卡片自己的位置与尺寸**平滑放大到全屏二级页，返回时缩回原卡片（Material 的 container transform）。同时给没有任何源元素的页面跳转（以后新增的深层路由等）配一个同族的全局兜底转场。实现落在新的动效层 `lib/src/ui/motion.dart`。

**为什么必须拆成两条通道**

`ThemeData.pageTransitionsTheme` 里的 `PageTransitionsBuilder` 只拿得到 `animation`、`context` 与子页，**拿不到触发元素的位置和尺寸**——那要等路由 `didPush` 时按元素自己的 `GlobalKey` 现场测量。所以「从元素位置放大」不可能由全局主题完成，只能由容器路由在内部自己做 `RectTween` 插值；全局主题只负责没有源元素的那种跳转，保证观感同族。

**Considered Options**
- 只配 `pageTransitionsTheme`（如 `ZoomPageTransitionsBuilder`）：被否——Android 上本来就是它，且满足不了「从元素位置和尺寸放大」这个核心诉求。
- `Hero` + 普通路由：被否——Hero 只能搬运一个「飞行 widget」，两级页面在飞行期间无法互相变形（圆角卡片 → 方角全屏页的形变、进出内容的交叉淡入都要手写），而且 Hero 与容器变换同时用会互相抢 repaint boundary。
- **自研容器路由**（最终采用）：一开始用的是 `animations` 包（纯 Dart、无原生代码）的 `OpenContainer`，但它给底层路由盖了一层 `Colors.black54` 遮罩（`_OpenContainerRoute.barrierColor`）：转场期间**整屏被压暗**，缩小的卡片四角就成了「亮块压在暗底上」的硬边，卡片表面色也被遮罩染成灰调——实测缩小时的卡片内部像素是 `(209,205,197)`，而卡片本色是 `(255,246,236)`。`barrierColor` 是私有路由的 getter，包外改不掉，所以照它的结构自己实现了一条 `ModalRoute`（尺寸量测、源元素隐藏、中断处理沿用同一套做法），只为把 `barrierColor` 设成 `null`。
- 自己写 `PageRouteBuilder` + 源元素 `GlobalKey` 测量：可行但要重写一遍已经被验证过的量测与边界处理，被否（自研那版正是照着包的结构写的）。

**Consequences**
- 三处二级页全部改走容器变换：习惯卡片 → 习惯详情、任务页「每日任务」入口卡 → 每日任务页、主角页设置图标 → 设置页。`Navigator.push(MaterialPageRoute)` 在这三处消失，业务逻辑、路由结果与状态管理不变（`onClosed` 承担原来 push 之后的 `_load()`）。
- 房规集中在 `openContainerTransform()`：时长 400ms、曲线 `fastOutSlowIn`、**无遮罩**、容器底色取卡片表面色（`theme.cardTheme.color`，四角不会透出另一种颜色）、`elevation: 0`（阴影归卡片/二级页自己画）、`tappable: false`（点击手势仍由卡片自己的 `InkWell`/`IconButton` 处理，保住水波纹与无障碍语义）。
- 容器里的「收起态元素」与「二级页」都要按**自身尺寸**布局（`FittedBox` + 定尺寸 `SizedBox`），否则会被容器当前的小尺寸压扁：列表卡片内部是 `Column`，压扁会直接抛 `RenderFlex overflow`，二级页布局会缩水变形。
- 容器里那份收起态元素**不能带 `closedBuilderKey`**：源路由里那一个还活着（由 `_Hideable` 占位遮住），同一帧两棵树各挂一个同名 `GlobalKey` 会抛 `Multiple widgets used the same GlobalKey`。它只是一张用来淡出的画，State 不需要搬。
- 系统「减少动效」（`MediaQuery.disableAnimations`）时时长压到 0，直接切页；全局兜底转场同样短路。
- **性能**：容器转场每帧都会重建整棵容器子树。展开态整页包一层 `RepaintBoundary`，重建不会顺带触发整页重绘。
- **列表卡片的 Opener 必须装进一个 StatefulWidget**，不能放进 `ListView` 的 `itemBuilder` 里现建：容器状态挂在 `GlobalKey` 上，每帧换新 key 会让容器状态反复重建。
- **`Opener` 自身是 StatefulWidget，但两个 builder 是它的入参**（不是塞在 State 里的字段）：调用点 `setState` 后新的 builder 会随新 widget 实例传下来，卡片才会重新构建。早期版本把 builder 固定在 State 里，导致「任务页数据加载完成、入口卡却一直显示空态」。
- **二级页会与源卡片同时存在于树里**（转场期间），所以两个 builder 的产物不能带同一个 `GlobalKey`。当前二级页都用 `didChangeDependencies` 里的一次性 `_loadStarted` 取数，不会被多构建一次放大成重复请求；以后新增页面要沿用这个写法。
- 转场结束后源卡片本来就不在树里（不透明路由会把被盖住的源路由从 Overlay 摘掉），所以测试不要用「找到源卡片被隐藏」来断言，改用「推上来的路由是不是容器路由」+「转场中途透明度是不是介于 0 与 1」。
- **go_router 适配**：本项目没用 go_router（`MaterialApp.home` + `Navigator`），所以这次不动路由栈。若以后真的要上 go_router，结论是**两件事分开看**：
  - 全局兜底转场（`pageTransitionsTheme`）继续生效于 `MaterialPageRoute`/`CupertinoPageRoute`；但 go_router 的 `GoRoute.pageBuilder` 返回的 `CustomTransitionPage` 会覆盖它，需要显式带上 `transitionsBuilder: ClayPageTransitionsBuilder().buildTransitions`（或继续用 `MaterialPage` 让主题生效）。
  - 卡片这类「从元素位置放大」**没有等价物**：go_router 只能推一条新路由，而容器路由之所以量得到源元素，是因为源路由在转场期间仍在树里（`OverlayEntry.opaque` 暂未置位）。真要在 go_router 下复刻，得自己实现一条同款 `PageRoute`，并把源元素的 `GlobalKey` 通过 `extra` 传进去量测——除非确实需要深链（web/桌面 URL），否则不值得。
  - 折中做法（不推荐但可行）：继续用 `Navigator.push(容器路由)` 做动画，跳转完成后用 `GoRouter.of(context).go(...)` 同步地址栏。本项目是纯 Android，没有地址栏需求，不采用。

## 追加：标签页滑动与场景切换（同日）

**底部导航切页加滑动**。四个标签页仍然全在树里（各自的滚动位置、表单状态、启动取数与过去一致），只是叠了一层水平位移：

- 页面容器不能用 `PageView`：它是懒构建的，会变成「切到才建、切到才取数」，各页的取数时机与手感都和过去不同。
- 也不能用 `Stack` + `Visibility` 拼：`Visibility` 只影响绘制，屏外页面照样能被 `find.text` 找到，四个页面里同名的「任务」「习惯」文案会互相打架（`IndexedStack` 是靠 `debugVisitOnstageChildren` 把屏外页挡在查找之外的）。
- 最终用 `Stack` + `Positioned.fill` + 每页一个 `Transform.translate`：位移走 `Transform`（**不是** `FractionalTranslation`——后者的命中测试不跟着位移走，会出现「看着在这一页、点了没反应」），离屏页用 `Offstage` 关掉（保留 State、不布局不绘制、也不进 finder）。每页的 widget 实例是常量，动画帧只重建很薄的一层包装。
- 位置控制器是 `AnimationController(upperBound: 3)`——**注意它的值域默认是 0..1**，不给 `upperBound` 的话 `animateTo(2)` 会被夹到 1。

**主角页场景切换加动画**。选中块（原来的静态 `Container`）换成 `AnimatedAlign` + `FractionallySizedBox`，在两个槽位之间平滑滑动，底色跟着场景主色淡变；文字用 `AnimatedDefaultTextStyle` 过渡颜色与字重。整个页面的配色本来就由 `ThemeData` 驱动（`MaterialApp` 内部的 `AnimatedTheme` 会在 200ms 内插值），所以指示块滑动与全页变色是同一条时间线。

**测试注意**：`AnimatedAlign` 内部把补间交给一个普通 `Align`，读 widget 的 `alignment` 只会拿到静态目标值；要断言动画过程，得量渲染出来的位置（`tester.getTopLeft`）。

## 追加：三处「添加」也统一为容器变换（同日）

「添加任务 / 添加每日任务 / 添加习惯 / 写笔记」原来都是 `showDialog` 的对话框，现在全部换成**整页表单**，并且由容器变换从触发元素长大出来：

- **为什么必须换成整页**：对话框是浮层，没有可以锚定的位置与尺寸，「从按钮长出来」无从谈起；顺带解决表单在对话框里被键盘挤到只能滚两行的窘境（笔记正文原来是个 8 行小框）。副产物：保存/取消语义不变（保存 `pop(true)`、取消 `pop(null)`），调用方据此决定要不要刷新列表——取消时不再无脑刷新。
- **源元素**：`添加任务`/`添加每日任务`/`添加习惯`/`写笔记` 用 FAB；卡片上的 **⋮ 菜单**也当源元素（点「编辑」时从 ⋮ 长大成编辑页）；笔记卡点正文进编辑页用卡片本身。
- **FAB 要关掉 `Hero`**（`heroTag: null`）：容器里那份快照带着同一个 tag，会在推入瞬间触发一次「源按钮 → 快照」的飞行，两边一起消失，和容器变换抢同一段位移。
- **表单页的容器底色取 `scaffoldBackgroundColor`**（新增的 `openEditorTransform()` 封装），不能用卡片表面色——表单页贴的是页面底色，否则收尾一帧会看见白底闪一下。
- 编辑器页共用 `EditorPage` 骨架（左上角 X、右上角保存、正文可滚），三个表单只写各自的字段与落库逻辑。

**`Opener` 的缓存契约被推翻**（这条改动的真正教训）：原来要求「`Opener` 装进 StatefulWidget 里只建一次」，理由是它内部挂 `GlobalKey`。但把一个 widget **实例**存进 State 字段反复返回，会让 `Element.updateChild` 因为「新旧 widget 完全同一个对象」直接跳过整棵子树的重建——任务页数据加载完成后入口卡还停在空态，就是因为过去每次业务通知都会新建一份 `ThemeData`，顺带把子树刷了一遍。现在 `Opener` 不再持有外部 `GlobalKey`，**每次 build 现出**即可（`.open()` 这种程序化打开也随之删掉，调用点都改用 `closedBuilder` 给的 `openAction`）。

