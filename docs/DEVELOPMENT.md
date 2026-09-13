# 宝宝日常 · 开发者文档

面向开发者与维护者的工程说明。面向用户的产品说明见 [`README.md`](../README.md)。

- 工程规范（改完必须提交、分 ABI 构建 release）：[`AGENTS.md`](../AGENTS.md)
- 领域术语表（唯一命名口径）：[`CONTEXT.md`](../CONTEXT.md)
- 关键决策记录：[`docs/adr/`](adr/)

---

## 1. 环境要求

| 项 | 值 |
| --- | --- |
| Flutter | 3.44.0（stable），仓库的构建与性能数据都在此版本上取得 |
| Dart | 随 Flutter 3.44 附带 |
| JDK | 17（`sourceCompatibility` / `jvmTarget` 均为 17） |
| Android compileSdk / targetSdk | 36 |
| Android minSdk | 24（Android 7.0） |
| 应用 ID | `com.yjym.baby.babydaily` |
| 显示名 | 宝宝日常 |
| 版本 | `pubspec.yaml` 的 `version:`（当前 `1.0.5+5001`） |

## 2. 快速开始

```sh
flutter pub get
dart run build_runner build   # drift 代码生成；改动表结构后必须重跑
flutter analyze
flutter test
flutter run -d <设备ID>
```

## 3. 目录结构

```
lib/main.dart                     入口：MaterialApp + 主题 + 路由装配
lib/src/domain/                   领域规则：纯函数、无 IO，全部由 test/domain 锁定
  xp_economy.dart                 经验来源、升级曲线、称号
  attributes.dart                 健康/自律/魅力三项属性与增减（封顶 100、下限 0）
  streak.dart                     每日连续天数、每周 N 次的连续达标周
  milestone.dart                  连续 10/20/30 天里程碑
  settlement.dart                 0 点每日结算（扣属性、上限下限截断）
  game_service.dart               编排：创建主角、完成任务发奖、升级判定、历史、备份往返
  enums.dart                      任务类型 / 状态等枚举
lib/src/data/
  database.dart                   drift 表定义、迁移、beforeOpen
  database.g.dart                 生成的数据库代码（入库，勿手改）
lib/src/ui/                       页面层
  app_controller.dart             应用级状态（AppScope）
  home_shell.dart                 四个标签页与左右滑动切页
  motion.dart                     容器变换（自研容器路由 + 全局兜底转场）
  theme.dart                      三场景 × 明暗的 ThemeData 构建与缓存
  clay.dart                       黏土拟物（Claymorphism）视觉件
  feedback.dart                   成长反馈层（升级 / 发奖 / 里程碑浮层）
  onboarding.dart                 新手引导
  character_page.dart             主角页（等级、称号、属性、场景切换）
  tasks_page.dart                 任务页（主线 / 支线 / 每日任务入口 + 归档）
  daily_tasks_page.dart           每日任务页（今天 + 按日期历史）
  habits_page.dart                习惯页（今日打卡、连续、累计、归档）
  habit_detail_page.dart          习惯详情（月历 + 年度热力图）
  notes_page.dart                 笔记页（按天翻页、全文搜索）
  settings_page.dart              设置页（备份导出 / 导入、安装包信息）
  editor_page.dart                整页表单骨架（容器变换的二级页基类）
  task_editor.dart                任务 / 每日任务表单
  habit_editor.dart               习惯表单
  note_editor.dart                笔记表单
test/domain/                      领域规则单元测试
test/ui/                          流程级 widget 测试（回归闸门）
integration_test/perf_test.dart   真机帧耗时测量（驱动界面，产出数据）
test_driver/perf_driver.dart      帧预算重算（120Hz → 8.33ms）
tools/icons/                      图标生成与核对脚本
tools/export_sessions.mjs         会话记录导出
docs/adr/                         决策记录
```

## 4. 领域规则（唯一事实来源）

规则集中在 `lib/src/domain/`，全是纯函数、无副作用，期望值以手工算例锁定在 `test/domain/`。

### 经验来源（ADR-0003；笔记自 ADR-0006 起不发放经验）

| 事件 | 经验 |
| --- | --- |
| 主线任务完成 | +50 |
| 支线任务完成 | +20 |
| 任务子项完成 | 0（子项无独立奖励，最后一个子项完成时主线自动完成并发 +50） |
| 每日任务完成 | +1 |
| 习惯打卡 | +5 |
| 每日登录（当天第一次打开应用，含从后台回前台） | +1 |
| 习惯连续里程碑 10 / 20 / 30 天 | +20 / +30 / +50（每个习惯终身一次） |
| 写笔记 | 0 |

数值全部由系统固定发放，用户只能配置**属性**奖励，不能配置经验——奖励里没有经验字段。

### 升级曲线与称号

`nextExpForLevel(lv)` 分段线性：

- Lv1–9：`40 + (lv-1)×3`
- Lv10–29：`70 + (lv-10)×4`
- Lv30–49：`110 + (lv-30)×6`
- 满级 50，`xpNeededForNext` 在满级返回 0

称号门槛取「不超过当前等级的最高档」：Lv1 初出茅庐 / Lv5 小有所成 / Lv10 持之以恒 / Lv15 自律新星 / Lv20 自律达人 / Lv30 自律大师 / Lv40 生活冠军 / Lv50 人生赢家。

### 属性

健康值、自律值、魅力值，新建主角均为 50，范围 0–100，**不随时间衰减**。奖励发放时封顶 100，惩罚扣减时下限 0，不产生负数债务。

### 连续（`streak.dart`）

- 每日习惯：从今天往回数连续有打卡的日期；**今天尚未打卡不算断签**，从昨天继续数（当天可以补），断一天则归零，不提供补签。
- 每周 N 次习惯：按自然周（周一–周日）统计，周内打卡 ≥ N 次即达标周，连续按达标周数计算；**本周进行中且未达标视为「待定」不打断**，到了周日仍未达标才断。
- 累计次数永久保留，不受断签影响。

### 每日结算（`settlement.dart`，ADR-0004）

每天 0 点重置每日任务，未完成的按其配置的奖励求和扣除属性（下限 0），**不扣经验**。结算幂等（同一天重复结算只扣一次）、不追溯结算当天之后才创建的每日任务、不重复扣当天已手动判失败的任务。`SettlementOutcome.totalPenalty` 返回**实际生效**的扣除量，避免属性已为 0 时在反馈里虚报「-N」。

### 失败（ADR-0007）

失败是任务的终止状态之一，由用户手动标记（每日任务也可在 0 点结算时自动判失败）。失败**不删除任务**：每日任务保留、次日照常；主线/支线进入「已失败」归档。失败不发放奖励、不扣除属性、不可恢复。每日任务逐日结果（完成 / 失败，含当天配置的惩罚值）永久保留，任务删除后记录仍在，在每日任务页按日期上下滑动查看。

## 5. 数据层

- `drift` + `sqlite3_flutter_libs` + `path_provider`（ADR-0001），单个 SQLite 文件放在应用私有目录。
- `schemaVersion = 3`，10 张表：`Characters`、`Tasks`、`Subtasks`、`TaskCompletions`、`DailyTaskLogs`、`Habits`、`Checkins`、`HabitMilestones`、`Notes`、`Settings`。
- `beforeOpen` 里执行 `PRAGMA foreign_keys = ON`，级联删除才生效（删任务级联删子项、保留完成历史）。
- 改动表结构后必须 `dart run build_runner build` 重生成 `database.g.dart` 并入库。
- 习惯与任务是两个独立模块，不共用表（ADR-0002）。

## 6. 构建与发布

### 6.1 构建

分 ABI 的 release 包（不要出默认肥包）：

```sh
flutter build apk --release --split-per-abi --split-debug-info=build/symbols --obfuscate
```

- release 开启 R8 压缩与资源裁剪（`isMinifyEnabled` / `isShrinkResources`，`android/app/build.gradle.kts`），Dart 侧由 AOT + 树摇保证；`jniLibs.useLegacyPackaging = true` 让原生库在包内压缩、安装时解压，体积更小。
- 产物约 8–9MB（三 ABI 各一个），混淆符号表在 `build/symbols/`，用于还原崩溃栈。
- **签名**：release 目前用 debug 签名（`signingConfig = signingConfigs.getByName("debug")`），只够自用装机；对外分发前必须换成正式签名并在 `key.properties` 里配置，且注意 `*.jks` / `*.keystore` / `key.properties` 绝不入库（见 `.gitignore`）。

### 6.2 安装到手机

```sh
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
adb shell dumpsys package com.yjym.baby.babydaily | grep version   # 核对 versionName / versionCode
```

ABI 选择：小米等 arm64 机型装 `app-arm64-v8a-release.apk`。

### 6.3 版本号与 ABI 偏移的坑（Flutter 3.44）

`--split-per-abi` 会给每个 ABI 的 versionCode 加偏移——`armeabi-v7a = 基准+1000`、`arm64-v8a = 基准+2000`、`x86_64 = 基准+4000`，基准就是 pubspec 的 `+N`（可用 `--build-number` 覆盖）。所以 **arm64 手机上看到的 versionCode 是 `N+2000`**，而 `adb install -r` 要求它**不小于**已装的值，否则报 `INSTALL_FAILED_VERSION_DOWNGRADE`（`flutter run` / `flutter drive` 遇到降级会**先卸载再装**，应用数据会被清空）：

- 本机曾用 `--build-number 3000` 的 release（arm64 → 5000），而 pubspec 的 `+9` 比它小得多，于是把 pubspec 提到了 `1.0.5+5001`：**不分 ABI 的 profile/debug 安装用 pubspec 的 `+N` 本身当 versionCode**，必须大于手机上的值才不会被判降级；
- 分 ABI 的 release 装机时用 `--build-number <基准>`，让 `arm64 = 基准+2000` 越过手机当前值（例如 `--build-number 5001` → 7001）；
- 先看一眼实际值再决定，比猜快：`aapt dump badging <apk> | findstr package` 或上面的 `dumpsys package` 命令。

### 6.4 产物命名

构建产物一律改名成 `babydaily-<版本号>-<abi>.apk`（版本号取 pubspec 的 `x.y.z`）再交付或存档：

```sh
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
   dist/babydaily-1.0.5-arm64-v8a.apk
```

## 7. 应用图标

源图 `icon2.png`（圆角方块插画：小人爬楼梯奔向星星，奶油底 `#FCF0DF`）。资源由脚本生成，**不要手改 `mipmap-*` 下的 PNG**：

```sh
python tools/icons/gen_icons.py        # 五档传统图标 48–192px + 五档自适应前景（108/108 dp 满铺）
python tools/icons/verify_icon2.py     # 合成圆形/圆角方形/方形遮罩预览，核对底色与前景无接缝
python tools/icons/icon_audit.py       # 核对手机里装的图标与仓库资源是否一致（先 adb pull 安装包）
```

- API < 26 用 `ic_launcher.png`（原图圆角方块直接缩放）。
- API ≥ 26 用自适应图标：前景按 108/108 dp 满铺遮罩视口，底色层 `#FCF0DF` 与前景方块填色通道差 ≤1，任何遮罩形状下都不会露出色环或接缝。
- 真正进包的是 `mipmap-*` 下的 PNG，`icon2.png` 只是源图：**换图后必须重跑 `gen_icons.py` 再重新构建安装**。脚本里的裁剪框 `TILE_BOX = (23, 28, 366, 364)` 是按当前 386×386 的源图量的，换新图要重新量，否则会裁错。
- 辅助脚本：`analyze_icon2.py`（量源图的方块包围盒、圆角半径、边缘色）、`seam_check.py`（量方块内部与角上的奶油色差，用来挑一个不会露出接缝的底色）、`preview_icon2.py`（按 Android 的合成方式预览自适应图标在各遮罩下的效果）。
- 改完图标但桌面还是旧图时，先分清两件事：`icon_audit.py` 一致 ⇒ 包里已是新图，那就是启动器缓存——小米/红米（MIUI/HyperOS）桌面按包名缓存图标位图，`adb install -r` 覆盖安装**不会**刷新已放在桌面上的图标。刷新办法：把桌面图标拖掉重新添加、重启手机，或「设置 → 应用设置 → 应用管理 → 系统桌面 → 清除缓存」（别点清除数据，会重置桌面布局）。若主题开了「图标重绘」或用了图标包，桌面图标由主题提供，改应用自身图标不会生效。

## 8. 转场动效（容器变换）

页面切换与元素点击统一为**容器变换**（Material 的 container transform）：点卡片时从该卡片的位置和尺寸放大到全屏二级页，返回缩回原卡片。实现都在 `lib/src/ui/motion.dart`，决策见 [ADR-0009](adr/0009-container-transform-transitions.md)，性能实测见 [ADR-0010](adr/0010-animation-performance.md)。

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

### 8.1 在 profile 模式验证

动效与性能都必须在 **profile** 模式看（debug 的帧时间没有参考价值）：

```sh
flutter devices                            # 拿设备 ID
flutter run --profile -d <设备ID>          # 装到手机并附上 DevTools

# 或直接跑可重复的帧耗时测量（改前改后对比同一段脚本）：
flutter drive --profile --no-dds --no-pub -d <设备ID> \
  --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
```

- 测量脚本会给五段动效（`add_task`、`container_open`、`container_close`、`tab_slide`、`scene_switch`）分别打印 build / raster 的 p50、p90、max 与**超预算帧数**，预算按真实刷新周期算（本机 120Hz → 8.33ms）。注意 SDK 自带的 `missed_frame_*_budget_count` 写死 16ms，在 120Hz 上会漏报，别用那个数（`perf_driver.dart` 里重算）。
- 测量用 `LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive`：`pump` 只等待、不额外催帧，引擎按真实 vsync 出帧；每段动效先热身一遍（不计量），把首次建页、首次取数、管线编译排除在数据外。脚本只驱动界面、不改业务数据（唯一写操作是场景切换，末尾会切回原场景）。
- 手机开「开发者选项 → GPU 渲染模式分析 → 在屏幕上显示为条形图」，或 DevTools 的 **Performance Overlay**，看 `UI` 与 `Raster` 两条：连点卡片进出二级页，帧时间应稳定在 16ms 以下（60Hz）/ 8ms 以下（120Hz）。
- 验证 `RepaintBoundary` 是否生效：DevTools → **Performance** 里勾 `Highlight repaints`（或 Inspector 里选中 `RepaintBoundary` 节点），转场时不应该看到整页跟着闪。
- 验证减少动效通路：手机「开发者选项 → 动画程序时长缩放 → 关闭」（或在系统设置里关掉动画）后重启应用，再点卡片应当是直接切页、没有缩放淡入。
- 想看一帧到底画了什么：`flutter screenshot --type=skia --vm-service-url=<run 输出的 VM Service 地址>`（`--type=skia` 需要 vm-service 地址；`--type=device` 是普通截屏）。
- 注意：profile 模式不支持热重载，改代码要重新 `flutter run --profile`，并且要重新走一遍上面的观察。
- 这台设备上 `dumpsys SurfaceFlinger --latency` 取不到数据（对任何层名都只回刷新周期），`dumpsys gfxinfo framestats` 量的是平台窗口而不是 Flutter 引擎——别用它们做结论。

## 9. 备份与恢复

- **导出**（ADR-0005）：Android 10+ 通过 MediaStore 写入公共目录「下载/BabyDaily」，文件名 `babydaily_backup_<时间戳>.json`；Android 9 及以下用 `WRITE_EXTERNAL_STORAGE`（`maxSdkVersion="28"`）。原生通道不可用时兜底写应用文档目录。备份是完整的 JSON 快照：主角、任务、每日任务历史、习惯（含打卡与里程碑）、笔记、设置。
- **导入**（ADR-0008）：用系统文件选择器（SAF）挑任意位置的备份 json，换机、从电脑拷回都可以；也支持把 json 改名成 `babydaily_restore.json` 放进应用文档目录后走兜底恢复。版本号不匹配的备份会被拒绝导入。
- **恢复当天免结算**：导入后当天不再触发结算，避免刚恢复就被扣属性。
- 备份往返在 `test/domain/game_service_test.dart` 里有全量一致性测试，UI 流程在 `test/ui/settings_backup_flow_test.dart`。

## 10. 测试

```sh
flutter analyze
flutter test        # 领域规则 + 流程级 widget 测试
```

### 领域（纯函数，`test/domain/`）

| 文件 | 锁定的规则 |
| --- | --- |
| `xp_economy_test.dart` | 分段升级曲线的每一段数值与累计经验 |
| `streak_test.dart` | 每日连续天数、每周 N 次的连续达标周（含「本周待定不打断」） |
| `milestone_test.dart` | 10/20/30 里程碑的发放条件、跳变逐个发放、终身一次 |
| `settlement_test.dart` | 属性的封顶/下限与结算扣除量 |
| `game_service_test.dart` | 端到端编排：建主角、各类任务发奖、子项自动完成、习惯打卡与规则变更重算、每日结算幂等、每日登录、手动判失败、每日任务历史、笔记不发经验、备份往返与错误版本拒绝 |

### 界面（流程级 widget 测试，`test/ui/`）

| 文件 | 锁定的行为 |
| --- | --- |
| `character_page_safe_area_test.dart` | 主角页是唯一没有 AppBar 的标签页，内容必须自己避开状态栏与挖孔 |
| `container_transform_flow_test.dart` | 元素 → 二级页走容器路由（不是 `MaterialPageRoute`）、转场中途真的在动画、返回也动画、减少动效走零时长、全局转场主题已装配 |
| `editor_transform_flow_test.dart` | 添加任务 / 添加每日任务 / 添加习惯 / 写笔记四个入口都推容器路由；表单保存落库、取消不落库；卡片 ⋮ 的「编辑」也走容器变换并把原名带进表单 |
| `daily_tasks_flow_test.dart` | 每日任务页：今天判失败立即扣属性，历史同时留痕 |
| `habit_detail_flow_test.dart` | 习惯卡片 → 详情页不在 `initState` 里查库（否则白屏），月历/热力图正常 |
| `notes_flow_test.dart` | 笔记编辑器开 → 存 → 再开 → 取消全流程不崩溃，搜索与日期跳转可用 |
| `settings_backup_flow_test.dart` | 导入走系统文件选择器（原生通道），导出落到「下载/BabyDaily」 |
| `tasks_page_collapse_test.dart` | 任务卡片与归档分区都能折叠；每日任务入口卡展示前三个任务与进度 |
| `motion_flow_test.dart` | 切标签的滑动与场景指示块滑动；容器路由无遮罩；**闸门：转场每个动画帧都不许再调用 builder** |
| `widget_test.dart` | 首次启动（无主角）显示新手引导 |

## 11. 工具

### 会话记录导出

```sh
node tools/export_sessions.mjs
```

把本项目在 DSH 里的全部会话（`~/.dsh/sessions/` 下的 zstd JSONL 日志）导出成 `exports/conversations/`：`index.html` 总览 + 每会话一份 HTML（气泡视图、工具调用可折叠、支持搜索过滤）+ 同名 Markdown + `sessions.json` 结构化数据。该目录含私人对话，**不入库**（见 `.gitignore`）。

### 图标脚本

见第 7 节。`tools/icons/` 下 `gen_icons.py` 是生成器，其余是核对/预览工具。

## 12. 决策记录索引（`docs/adr/`）

| 编号 | 决策 |
| --- | --- |
| 0001 | 本地 SQLite（drift）+ JSON 手动备份作为唯一持久化 |
| 0002 | 习惯与任务是两个独立模块 |
| 0003 | 经验值经济：固定来源、不可配置、满级 50 |
| 0004 | 每日结算惩罚：未完成的每日任务扣除配置属性 |
| 0005 | 备份落到公共下载目录（MediaStore），数据库仍在应用私有目录 |
| 0006 | 笔记不发放经验：只做记录，不参与成长结算 |
| 0007 | 任务失败状态与每日任务逐日历史 |
| 0008 | 备份导入改用系统文件选择器（SAF），导出仍写公共下载目录 |
| 0009 | 页面切换与元素点击统一为容器变换（Container Transform） |
| 0010 | 动效性能：先量再改（容器变换 / 切页 / 场景切换） |

## 13. 仓库内容边界

- **入库**：源码、测试、`database.g.dart`、`mipmap-*` 图标 PNG、Gradle wrapper、脚本、文档。
- **不入库**：`/build/`、`/exports/`、`.dart_tool/`、`*.apk` / `*.aab`、签名材料（`*.jks` / `*.keystore` / `key.properties`）、符号与混淆映射（`app.*.symbols` / `app.*.map.json`）、第三方技能目录（`.agents/`、`.claude/`，来源记录在 `skills-lock.json`）。
