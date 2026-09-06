# Flutter 引擎与嵌入层（R8 会裁剪到反射路径，需要保活）
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# 应用入口（Manifest 引用）
-keep class com.yjym.baby.babydaily.MainActivity { *; }

# Flutter 引擎引用的 Play Store 可选组件（本应用不发布到 Play、未使用延迟组件），
# 避免 R8 因缺失类中断构建。
-dontwarn com.google.android.play.core.**

# 插件与漂移（drift/sqlite3/path_provider）均为 Kotlin 通道或纯 Dart，
# 无反射依赖，无需额外 keep 规则。
