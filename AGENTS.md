# 项目规范

「宝宝日常」的工程约定，所有改动都必须遵守。

## 1. 改完代码必须提交到 git

- 任何代码、资源或配置改动完成后，**任务结束前必须提交到 git**，不要留下未提交的改动。
- 提交信息沿用仓库风格：`type(scope): 摘要——细节；细节`（如 `fix(ui): ...`、`build: ...`）。
- 一次改动拆成若干语义清晰的提交；提交前跑通 `flutter analyze` 与 `flutter test`。

## 2. 构建 APK：分 ABI 的 release 包 + adb 安装到手机

构建一律用分 ABI 的 release 命令，不要出默认肥包：

```sh
flutter build apk --release --split-per-abi --split-debug-info=build/symbols --obfuscate
```

构建完成后通过 adb 安装到手机，按设备 ABI 选择对应包：

```sh
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

- ABI 选择：小米等 arm64 机型装 `app-arm64-v8a-release.apk`。
- 发布前递增 `pubspec.yaml` 的 `version: x.y.z+N`（build 号 +1，保证覆盖安装升级）。
- 安装后用 `adb shell dumpsys package com.yjym.baby.babydaily | grep version` 核对设备上的 versionName / versionCode。
- 混淆符号表在 `build/symbols/`，用于还原崩溃栈。
