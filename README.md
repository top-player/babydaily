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
- 设计上下文：`CONTEXT.md`（术语表）；关键决策：`docs/adr/`（本地 SQLite+JSON 备份 / 习惯与任务分离 / 经验经济 / 每日结算惩罚 / 公共下载目录备份 / 笔记不发经验 / 任务失败与每日历史 / 系统文件选择器导入 / 容器变换转场）。
- 对话记录导出：`node tools/export_sessions.mjs` —— 把本项目在 DSH 里的全部会话（`~/.dsh/sessions/` 下的 zstd JSONL 日志）导出成 `exports/conversations/`：`index.html` 总览 + 每会话一份 HTML（气泡视图、工具调用可折叠、支持搜索过滤）+ 同名 Markdown + `sessions.json` 结构化数据。该目录不入库。

### 转场动效（容器变换）

页面切换与元素点击统一为 **容器变换**（Material 的 container transform）：点卡片时从该卡片的位置和尺寸放大到全屏二级页，返回缩回原卡片。实现都在 `lib/src/ui/motion.dart`，决策见 `docs/adr/0009-container-transform-transitions.md`。

- **元素 → 二级页**：用 `openContainerTransform()` 包住卡片。`Opener` 必须装在一个 **StatefulWidget** 里只建一次，别在 `ListView.itemBuilder` 里现建——它内部靠 `GlobalKey` 挂状态，每帧换 key 会让容器状态反复重建。
- **容器路由是自研的**（没用 `animations` 包的 `OpenContainer`）：包的路由会给底层盖一层 `black54` 遮罩，转场期间整屏压暗、缩小的卡片四角变成「亮块压在暗底上」的硬边。自研那条只为把 `barrierColor` 设成 `null`，量测/隐藏/中断沿用同一套做法。
- **无源元素的页面跳转**：`pageTransitionsTheme` 在 `buildTheme()` 里统一配成 `ClayPageTransitionsBuilder`（0.92 放大淡入，各平台一致）。`PageTransitionsBuilder` 拿不到元素位置，所以有源元素的卡片点击**不要**指望它。
- **标签页滑动**：`HomeShell` 用 `Stack` + 每页一个 `Transform.translate` 做左右滑动（`Offstage` 关掉离屏页）。位移必须走 `Transform`，**不能**用 `FractionalTranslation`——后者命中测试不跟着位移走。
- **场景切换**：主角页场景卡的选中块是 `AnimatedAlign` + `FractionallySizedBox`，在两个槽位之间滑动。
- **减少动效**：系统开启「减少动效」时容器变换与标签滑动都短路成零时长，直接切页。
- **性能**：展开态整页、四个标签页各有一层 `RepaintBoundary`。
- **go_router**：本项目没用（`MaterialApp.home` + `Navigator`）；若以后要上，`CustomTransitionPage` 会覆盖全局转场主题，而「从元素位置放大」没有等价物。细节见 ADR-0009。

#### 在 profile 模式验证

动效与性能都必须在 **profile** 模式看（debug 的帧时间没有参考价值）：

```sh
flutter devices                            # 拿设备 ID
flutter run --profile -d <设备ID>          # 装到手机并附上 DevTools
```

- 手机开「开发者选项 → GPU 渲染模式分析 → 在屏幕上显示为条形图」，或 DevTools 的 **Performance Overlay**，
  看 `UI` 与 `Raster` 两条：连点卡片进出二级页，帧时间应稳定在 16ms 以下（60Hz）/ 8ms 以下（120Hz）。
- 验证 `RepaintBoundary` 是否生效：DevTools → **Performance** 里勾 `Highlight repaints`（或 Inspector 里选中
  `RepaintBoundary` 节点），转场时不应该看到整页跟着闪；本页的 `RepaintBoundary` 数量应是「卡片数 + 1」的量级，
  不随卡片内容变多而增加。
- 验证减少动效通路：手机「开发者选项 → 动画程序时长缩放 → 关闭」（或在系统设置里关掉动画）后重启应用，
  再点卡片应当是直接切页、没有缩放淡入。
- 想看一帧到底画了什么：`flutter screenshot --type=skia --vm-service-url=<run 输出的 VM Service 地址>`
  （`--type=skia` 需要 vm-service 地址；`--type=device` 是普通截屏）。
- 注意：profile 模式不支持热重载，改代码要重新 `flutter run --profile`，并且要重新走一遍上面的观察。

## 开发

```sh
flutter pub get
dart run build_runner build   # drift 代码生成
flutter test                  # 全部测试
flutter build apk --release --split-per-abi --split-debug-info=build/symbols --obfuscate
# 分 ABI 构建（8–9MB）：小米等 arm64 机型装 app-arm64-v8a-release.apk
# 符号表在 build/symbols/，配合混淆可还原崩溃栈
```

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
