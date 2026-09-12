# 动效性能：先量再改（容器变换 / 切页 / 场景切换）

用户反馈「动画看起来卡卡的」。这次不靠猜：先搭一套**可重复的真机帧耗时测量**，拿到基线，再逐条改，改完复测对比。

## 测量方法（可重复）

`flutter test` 在 3.44 里**没有** `--profile`（源码里写死 `BuildMode.debug`），所以唯一的 profile 通道是 `flutter drive`：

```sh
flutter drive --profile --no-dds --no-pub -d <serial> \
  --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
```

- `integration_test/perf_test.dart` 驱动五段动效：打开整页表单、容器变换展开、容器变换收起、切标签滑动、场景切换。每段先热身一次（把首次建页/取数/管线编译排除在外）再 `watchPerformance` 计量。
- `framePolicy = benchmarkLive`：`pump` 只等待、不额外催帧，引擎按真实 vsync 出帧——量到的就是屏幕上真正发生的事。
- `test_driver/perf_driver.dart` 打印 build / raster 的 p50、p90、max 与超预算帧数；**jank 按真实刷新周期重算（8.33ms）**，不用 SDK 自带的 `missed_frame_*_budget_count`——它写死 16ms（`FrameTimingSummarizer.kBuildBudget`），在 120Hz 上会漏报一半。
- 本机是 120Hz 屏：每帧预算 8.33ms，不是 16.7ms。**这一点是本次的关键前提**——帧时间 5ms 在 60Hz 上毫无问题，在 120Hz 上就是稳稳的掉帧。
- 不能用 `dumpsys SurfaceFlinger --latency`：这台 Android 17 上它对 25 个层名（含故意写错的对照名）一律只回 `8333333`（= 刷新周期），ring buffer 取不到。`dumpsys gfxinfo framestats` 有数据，但它量的是平台窗口（实测 6 个 view、10KB 渲染节点），看不见 Flutter 引擎的 UI/raster 线程。

## 基线（改前）与结果（改后）

单位 ms，预算 8.33ms/帧；「jank」= 超预算帧数。

| 场景 | 指标 | 改前 | 改后 |
| --- | --- | --- | --- |
| 打开整页表单（原对话框 → 现容器变换） | build p90 / max | 0.6 / 5.7 | 1.4 / 8.1 |
| | raster p90 / max / jank | 1.1 / 11.7 / 1 | 1.0 / 2.7 / 0 |
| 容器变换·展开 | build p90 / max | 0.9 / 5.3 | 0.4 / 7.8 |
| | raster p90 / max / jank | **7.8 / 12.7 / 7** | **0.9 / 4.3 / 0** |
| 容器变换·收起 | raster p90 / max | 5.2 / 6.1 | 1.3 / 4.0 |
| 切标签滑动 | raster p90 / max | 0.9 / 6.4 | 0.5 / 0.6 |
| 场景切换 | build p90 / max / jank | 2.7 / **14.6** / 8 | 2.5 / 11.1 / 7 |
| | raster p90 / max / jank | 1.1 / 8.4 / 2 | 0.9 / 2.2 / 0 |

（同一份代码连测两次，各分位数会差 20–40%——热、后台进程、面板刷新率都会影响。所以只有「7 帧超预算 → 0 帧」这种量级的差别才算证据；下面第 5 条就是被这条标准否掉的。）

## 改了四条

1. **容器转场不再每帧重建两棵子树**。`_ClayContainerRoute.buildPage` 原来把 `closedBuilder` / `openBuilder` 放在每帧的 `AnimatedBuilder` 里调用：300ms 里把整页（列表、卡片、文字）重建三十多遍。现在两个 builder 的产物按「屏幕尺寸 + 方向」缓存，动画帧只重建外面那层尺寸/位移/底色的薄壳；`CurvedAnimation`、`ShapeBorderTween`、淡入淡出动画也都只建一次。`test/ui/motion_flow_test.dart` 里加了闸门：转场中每个动画帧都不许再调用 builder。
2. **二级页按自身尺寸 1:1 布局，改「缩放」为「裁剪露出」**（raster p90 7.8→0.9 的那一刀）。原来学 `animations` 包把整页缩放到容器宽度：缩放比每帧都在变，光栅线程每帧都得把整页重画一遍（且每帧新建一个离屏）。改成 `OverflowBox` 让页面按整屏尺寸布局、由容器的圆角裁剪一点点露出来——变换矩阵恒定，只有裁剪矩形在变。观感差别很小：容器宽度本来就从卡片宽度出发，卡片多数时候已经占满屏宽。
3. **二级页早淡入**。`fadeThrough` 原样照搬的话，二级页有 4/5 的时间带透明度，等于每帧给它开一层离屏合成。现在它在开头 1/6 内淡入完成，此后全程不透明直绘。
4. **切标签滑动不再做整屏渐隐**：两层整屏 `Opacity` 每帧各开一张离屏缓冲，而且滑到一半两页都只剩 20% 不透明、整屏发白。两页都是不透明的整屏页面，直接滑过去（ViewPager 那种观感）更快也更干净。另外 `buildTheme()` 按场景 + 亮度缓存 `ThemeData`：`RootGate.build` 每次业务通知都会调用它，不缓存就要重跑两遍 `ColorScheme.fromSeed`（HCT 调色，毫秒级）并拿到新实例。

另外把容器变换时长从 400ms 收到 **300ms**（对齐 M3 的 container transform / medium2），反向 **220ms**（出场比入场快一档）。动画越长，掉帧越容易被看见。

## 试过但否掉的

- **屏外页冻结主题**（给三个不可见的标签页一份不变的 `ThemeData`，让主题动画只重建当前页）：机制上确实少做三次整页重建，但实测场景切换的 build 超预算帧只从 7 降到 6、峰值 11.1→10.8ms，**落在噪声里**。为一次说不清的收益引入「离屏页拿到的是旧主题」这种隐式行为不划算，已回退。
- **`dumpsys SurfaceFlinger --latency` / `dumpsys gfxinfo framestats`**：前者在这台 Android 17 上取不到 ring buffer（对任何层名都只回刷新周期），后者量的是平台窗口而不是 Flutter 引擎。见「测量方法」。


## Consequences

- 最常点的「卡片 → 二级页」在 120Hz 上从 7 帧超预算变成 0 帧；「添加任务」从对话框换成容器变换到整页表单后，反而比原来的对话框更省（raster max 11.7 → 2.7）。
- **契约**：`closedBuilder` / `openBuilder` 的产物会被缓存复用，所以它们捕获的参数必须是「这次转场期间不会变」的值；页面要显示新数据得在页面自己的 State 里刷新。
- **契约**：`openContainerTransform()` 返回的 widget **每次 build 现出**，不能存进 State 字段反复用同一个实例——`Element.updateChild` 遇到「新旧 widget 完全同一个对象」会直接跳过整棵子树，卡片会一直停在旧内容上（本次真踩到：任务页数据加载完成后入口卡还是空态，因为改前是主题每次变化顺带把子树刷新的）。
- 场景切换的 UI 线程仍是本应用最重的一段（整页配色变化要让所有文字重新排版），只是从 8 帧超预算降到 7 帧、峰值 14.6→11.1ms；光栅侧则从 2 帧超预算降到 0。真要再压，只能牺牲「配色平滑过渡」这条观感（或调短 `themeAnimationDuration`，减少掉帧帧数而不是每帧耗时）。
