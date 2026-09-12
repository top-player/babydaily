# 宝宝日常

轻松治愈的个人成长 RPG（Android / Flutter）：主角通过完成任务、坚持习惯、随手写笔记获得成长，用等级、属性与连续记录鼓励长期坚持。

## 玩法

- **主角**：姓名/年龄/性别自设；经验值驱动等级（满级 50，称号随等级解锁）；健康值/自律值/魅力值 0–100，不衰减。
- **每日登录**：每天第一次打开应用 +1 经验（不开不涨），主角页标出当天已到账。
- **任务**：主线（长期目标，可拆子项，全部完成自动发完成奖励）、支线（一次性）、每日任务（每天 0 点重置，完成 +1 经验；未完成会扣除配置属性并记为失败，任务保留）；任何任务都可以手动标记失败——失败不删除，主线/支线进「已失败」归档。奖励只配置三属性，经验值由系统固定发放。
- **任务页**：主线/支线卡片可逐张折叠，已完成 / 已失败归档可整段折叠；每日任务入口卡展示今天的前几个任务与进度，点进详情页。
- **每日任务页**：顶部今天（可完成 / 可判失败），下方按日期上下滑动查看历史（完成与失败逐日留痕）。
- **习惯**：每日 / 每周 N 次；打卡默认 +1 自律、+5 经验；连续 10/20/30 天有一次性里程碑奖励；断签归零、累计次数永久保留；月历 + 年度热力图展示。
- **笔记**：一天多篇、按天翻页、全文搜索；只做记录，不发放经验。
- **场景**：家里 / 公司 / 游玩三套氛围（主题色、问候与提示文案），手动切换。
- **备份**：导出到手机「下载/BabyDaily」；导入用系统文件选择器挑任意位置的备份 json（换机、从电脑拷回都可以）。

## 工程

- 领域规则（经验经济、等级曲线、连续计算、每日结算、任务失败与每日历史）以单元测试锁定，见 `test/domain/`。
- 工程规范（改完必须提交、分 ABI 构建 release 并 adb 装机）：`AGENTS.md`。
- 设计上下文：`CONTEXT.md`（术语表）；关键决策：`docs/adr/`（本地 SQLite+JSON 备份 / 习惯与任务分离 / 经验经济 / 每日结算惩罚 / 公共下载目录备份 / 笔记不发经验 / 任务失败与每日历史 / 系统文件选择器导入 / 容器变换转场 / 动效性能实测）。
- 对话记录导出：`node tools/export_sessions.mjs` —— 把本项目在 DSH 里的全部会话（`~/.dsh/sessions/` 下的 zstd JSONL 日志）导出成 `exports/conversations/`：`index.html` 总览 + 每会话一份 HTML（气泡视图、工具调用可折叠、支持搜索过滤）+ 同名 Markdown + `sessions.json` 结构化数据。该目录不入库。

### 转场动效（容器变换）

页面切换与元素点击统一为 **容器变换**（Material 的 container transform）：点卡片时从该卡片的位置和尺寸放大到全屏二级页，返回缩回原卡片。实现都在 `lib/src/ui/motion.dart`，决策见 `docs/adr/0009-container-transform-transitions.md`，性能实测见 `docs/adr/0010-animation-performance.md`。

- **元素 → 二级页**：用 `openContainerTransform()` 包住卡片/FAB/⋮。**每次 build 现出**它（别存进 State 字段复用同一个实例）：`Element.updateChild` 遇到完全相同的 widget 对象会跳过整棵子树，卡片会一直停在旧内容上。容器自身的 State 由 element 复用保留。
- **整页表单**：`openEditorTransform()` = 容器变换 + 容器底色取 `scaffoldBackgroundColor`。添加任务 / 添加每日任务 / 添加习惯 / 写笔记都是整页表单（原来是与 `showDialog` 的对话框——浮层没有可锚定的源元素，做不了容器变换）。
- **容器路由是自研的**（没用 `animations` 包的 `OpenContainer`）：包的路由会给底层盖一层 `black54` 遮罩，转场期间整屏压暗、缩小的卡片四角变成「亮块压在暗底上」的硬边。自研那条只为把 `barrierColor` 设成 `null`，量测/隐藏/中断沿用同一套做法。
- **契约**：`closedBuilder` / `openBuilder` 的产物在推入时各构建一次、之后被缓存，所以它们捕获的参数必须是「这次转场期间不会变」的值；页面要显示新数据得在页面自己的 State 里刷新（`test/ui/motion_flow_test.dart` 有闸门：转场中每个动画帧都不许再调用 builder）。
- **时长**：展开 300ms、收起 220ms（`kContainerTransformDuration` / `kContainerTransformReverseDuration`），曲线 `fastOutSlowIn`。
- **无源元素的页面跳转**：`pageTransitionsTheme` 在 `buildTheme()` 里统一配成 `ClayPageTransitionsBuilder`（0.92 放大淡入，各平台一致）。`PageTransitionsBuilder` 拿不到元素位置，所以有源元素的卡片点击**不要**指望它。
- **标签页滑动**：`HomeShell` 用 `Stack` + 每页一个 `Transform.translate` 做左右滑动（`Offstage` 关掉离屏页），**不做整屏渐隐**（两层整屏 `Opacity` 每帧各开一张离屏缓冲，滑到一半还会整屏发白）。位移必须走 `Transform`，**不能**用 `FractionalTranslation`——后者命中测试不跟着位移走。
- **场景切换**：主角页场景卡的选中块是 `AnimatedAlign` + `FractionallySizedBox`，在两个槽位之间滑动；整页配色由 `MaterialApp` 内部的 `AnimatedTheme` 过渡（这是全应用 UI 线程最重的一段，见 ADR-0010）。
- **减少动效**：系统开启「减少动效」时容器变换与标签滑动都短路成零时长，直接切页。
- **性能**：切页只平移不重建页面、容器转场不重建两棵子树、展开态整页与四个标签页各有一层 `RepaintBoundary`。
- **go_router**：本项目没用（`MaterialApp.home` + `Navigator`）；若以后要上，`CustomTransitionPage` 会覆盖全局转场主题，而「从元素位置放大」没有等价物。细节见 ADR-0009。

#### 在 profile 模式验证

动效与性能都必须在 **profile** 模式看（debug 的帧时间没有参考价值）：

```sh
flutter devices                            # 拿设备 ID
flutter run --profile -d <设备ID>          # 装到手机并附上 DevTools

# 或直接跑可重复的帧耗时测量（改前改后对比同一段脚本）：
flutter drive --profile --no-dds --no-pub -d <设备ID> \
  --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
```

- 测量脚本会给五段动效分别打印 build / raster 的 p50、p90、max 与**超预算帧数**，预算按真实刷新周期算（本机 120Hz → 8.33ms）。注意 SDK 自带的 `missed_frame_*_budget_count` 写死 16ms，在 120Hz 上会漏报，别用那个数。
- 手机开「开发者选项 → GPU 渲染模式分析 → 在屏幕上显示为条形图」，或 DevTools 的 **Performance Overlay**，
  看 `UI` 与 `Raster` 两条：连点卡片进出二级页，帧时间应稳定在 16ms 以下（60Hz）/ 8ms 以下（120Hz）。
- 验证 `RepaintBoundary` 是否生效：DevTools → **Performance** 里勾 `Highlight repaints`（或 Inspector 里选中
  `RepaintBoundary` 节点），转场时不应该看到整页跟着闪。
- 验证减少动效通路：手机「开发者选项 → 动画程序时长缩放 → 关闭」（或在系统设置里关掉动画）后重启应用，
  再点卡片应当是直接切页、没有缩放淡入。
- 想看一帧到底画了什么：`flutter screenshot --type=skia --vm-service-url=<run 输出的 VM Service 地址>`
  （`--type=skia` 需要 vm-service 地址；`--type=device` 是普通截屏）。
- 注意：profile 模式不支持热重载，改代码要重新 `flutter run --profile`，并且要重新走一遍上面的观察。
- 这台设备上 `dumpsys SurfaceFlinger --latency` 取不到数据（对任何层名都只回刷新周期），`dumpsys gfxinfo framestats` 量的是平台窗口而不是 Flutter 引擎——别用它们做结论。


## 开发

```sh
flutter pub get
dart run build_runner build   # drift 代码生成
flutter test                  # 全部测试
flutter build apk --release --split-per-abi --split-debug-info=build/symbols --obfuscate
# 分 ABI 构建（8–9MB）：小米等 arm64 机型装 app-arm64-v8a-release.apk
# 符号表在 build/symbols/，配合混淆可还原崩溃栈
```

**版本号的坑（Flutter 3.44）**：`--split-per-abi` 会给每个 ABI 的 versionCode 加偏移——`armeabi-v7a = 基准+1000`、`arm64-v8a = 基准+2000`、`x86_64 = 基准+4000`，基准就是 pubspec 的 `+N`（或用 `--build-number` 覆盖）。所以 **arm64 手机上看到的 versionCode 是 `N+2000`**，而 `adb install -r` 要求它**不小于**已装的值，否则报 `INSTALL_FAILED_VERSION_DOWNGRADE`（`flutter run`/`flutter drive` 遇到降级会**先卸载再装**，应用数据会被清空）：

- 这台手机上跑过 `--build-number 3000` 的 release（arm64 → 5000），pubspec 的 `+9` 比它小得多，所以后来把 pubspec 提到了 `1.0.5+5001`：**不分 ABI 的 profile/debug 安装用 pubspec 的 `+N` 本身当 versionCode**，要大于手机上的值才不会被判降级；
- 分 ABI 的 release 装机时用 `--build-number <基准>`，让 `arm64 = 基准+2000` 越过手机当前值（本次 `--build-number 5001` → 7001）；
- 先 `aapt dump badging <apk> | findstr package`（或 `adb shell dumpsys package com.yjym.baby.babydaily | grep version`）看一眼实际 versionCode，比猜快。


### 应用图标

源图 `icon2.png`（圆角方块插画：小人爬楼梯奔向星星，奶油底 `#FCF0DF`）。资源由脚本生成，不要手改 `mipmap-*` 下的 PNG：

```sh
python tools/icons/gen_icons.py      # 五档传统图标 48–192px + 五档自适应前景（108/108 dp 满铺）
python tools/icons/verify_icon2.py   # 合成圆形/圆角方形/方形遮罩预览，核对底色与前景无接缝
python tools/icons/icon_audit.py     # 核对手机里装的图标与仓库资源是否一致（先 adb pull 安装包）
```

- API < 26 用 `ic_launcher.png`（原图圆角方块直接缩放）。
- API ≥ 26 用自适应图标：前景按 108/108 dp 满铺遮罩视口，底色层 `#FCF0DF` 与前景方块填色通道差 ≤1，任何遮罩形状下都不会露出色环或接缝。
- 真正进包的是 `mipmap-*` 下的 PNG，`icon2.png` 只是源图：**换图后必须重跑 `gen_icons.py` 再重新构建安装**。脚本里的裁剪框 `TILE_BOX = (23, 28, 366, 364)` 是按当前 386×386 的源图量的，换新图要重新量，否则会裁错。
- 改完图标但桌面还是旧图时，先分清两件事：`icon_audit.py` 一致 ⇒ 包里已是新图，那就是启动器缓存——小米/红米（MIUI/HyperOS）桌面按包名缓存图标位图，`adb install -r` 覆盖安装**不会**刷新已放在桌面上的图标。刷新办法：把桌面图标拖掉重新添加、重启手机，或「设置 → 应用设置 → 应用管理 → 系统桌面 → 清除缓存」（别点清除数据，会重置桌面布局）。若主题开了「图标重绘」或用了图标包，桌面图标由主题提供，改应用自身图标不会生效。
