/// 动效性能测量的驱动端：把 integration_test/perf_test.dart 采到的每帧耗时
/// 打印成可直接对比的摘要（build = UI 线程，raster = 光栅线程）。
///
/// 跑法见 README「动效性能」一节：
///
/// ```sh
/// flutter drive --profile --no-dds --no-pub -d <serial> \
///   --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
/// ```
///
/// 为什么自己算 jank：集成测试自带的 `missed_frame_build_budget_count` 用的是
/// `FrameTimingSummarizer.kBuildBudget`（写死 16ms），而本机是 120Hz 屏、真实
/// 预算是 8.33ms，用 16ms 会漏报一半以上的掉帧。这里按真实刷新周期重算。
library;

import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// 120Hz 的每帧预算（微秒）。改成 16667 即为 60Hz 设备的预算。
const int kFrameBudgetUs = 8334;

Future<void> main() => integrationDriver(
  responseDataCallback: (Map<String, dynamic>? data) async {
    if (data == null) return;
    final buffer = StringBuffer()
      ..writeln()
      ..writeln('==== 动效每帧耗时（真机 profile，预算 ${kFrameBudgetUs / 1000} ms/帧）====')
      ..writeln(
        '${'场景'.padRight(18)}${'帧数'.padLeft(5)}'
        '${'build p50'.padLeft(11)}${'p90'.padLeft(8)}${'max'.padLeft(8)}'
        '${'jank'.padLeft(7)}'
        '${'raster p50'.padLeft(12)}${'p90'.padLeft(8)}${'max'.padLeft(8)}'
        '${'jank'.padLeft(7)}',
      );
    for (final MapEntry<String, dynamic> entry in data.entries) {
      buffer.writeln(_format(entry.key, entry.value as Map<String, dynamic>));
    }
    stdout.writeln(buffer.toString());
    // 原始数组（微秒）也落盘，方便复算分位数。
    await writeResponseData(data);
  },
);

String _format(String key, Map<String, dynamic> summary) {
  final build = _ints(summary['frame_build_times']);
  final raster = _ints(summary['frame_rasterizer_times']);
  final buildJank = build.where((t) => t > kFrameBudgetUs).length;
  final rasterJank = raster.where((t) => t > kFrameBudgetUs).length;
  return key.padRight(18) +
      '${build.length}'.padLeft(5) +
      _stats(build).padLeft(27) +
      '$buildJank'.padLeft(7) +
      _stats(raster).padLeft(28) +
      '$rasterJank'.padLeft(7);
}

/// `p50 / p90 / max`（微秒 → 毫秒，一位小数）。
String _stats(List<int> samples) {
  if (samples.isEmpty) return '-';
  final sorted = [...samples]..sort();
  String ms(int us) => (us / 1000).toStringAsFixed(1);
  return '${ms(_percentile(sorted, 0.5))}/${ms(_percentile(sorted, 0.9))}/'
      '${ms(sorted.last)}';
}

int _percentile(List<int> sorted, double q) =>
    sorted[((sorted.length - 1) * q).round()];

List<int> _ints(Object? value) => (value as List<dynamic>? ?? const [])
    .map((e) => (e as num).toInt())
    .toList();
