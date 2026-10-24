import 'package:flutter/scheduler.dart';

/// Bounded diagnostic window. Flutter raster duration is a raster-thread proxy,
/// not a direct hardware GPU measurement. Use DevTools on the reference Android.
class RewardFrameMetrics {
  final _build = List<int>.filled(240, 0);
  final _raster = List<int>.filled(240, 0);
  final _total = List<int>.filled(240, 0);
  int count = 0, _cursor = 0;
  int totalFrames = 0, slowFrames = 0, maximumTotal = 0;
  void clear() {
    count = _cursor = totalFrames = slowFrames = maximumTotal = 0;
  }

  void add(List<FrameTiming> timings) {
    for (final frame in timings) {
      totalFrames++;
      final total = frame.totalSpan.inMicroseconds;
      if (total > 16667) slowFrames++;
      if (total > maximumTotal) maximumTotal = total;
      _build[_cursor] = frame.buildDuration.inMicroseconds;
      _raster[_cursor] = frame.rasterDuration.inMicroseconds;
      _total[_cursor] = frame.totalSpan.inMicroseconds;
      _cursor = (_cursor + 1) % _build.length;
      if (count < _build.length) count++;
    }
  }

  String get report {
    if (count == 0) return 'Sin muestras de frames todavía.';
    double percentile(List<int> source, [double p = .95]) {
      final copy = source.take(count).toList()..sort();
      return copy[((count - 1) * p).round()] / 1000;
    }

    return '$totalFrames frames jornada · p95 últimos $count build ${percentile(_build).toStringAsFixed(2)} ms · '
        'raster ${percentile(_raster).toStringAsFixed(2)} ms · '
        'total ${percentile(_total).toStringAsFixed(2)} ms · '
        'p99 ${percentile(_total, .99).toStringAsFixed(2)} ms · '
        'máx jornada ${(maximumTotal / 1000).toStringAsFixed(2)} ms · '
        '$slowFrames frames >16,67 ms';
  }
}
