import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';

void main() {
  final catalog = UpgradeCatalog.fromCsv(
    File('docs/balance.csv').readAsStringSync(),
  );
  final samples = <Map<String, Object?>>[];
  for (var repeat = 0; repeat < 7; repeat++) {
    for (final enabled in repeat.isEven ? [false, true] : [true, false]) {
      final b = Board(
        catalog.settings({'generator': 3, 'walls': 3, 'launcher': 1}),
        metricsEnabled: enabled,
        randomState: 42,
      );
      for (var i = 0; i < 180; i++) {
        b.balls.add(
          Ball(
            b.nextId++,
            Vec(15 + i % 18 * 18, 180 + i ~/ 18 * 28),
            Vec((i % 3 - 1) * 120, -70),
          ),
        );
        b.metrics.initial++;
      }
      final times = <int>[];
      for (var i = -120; i < 600; i++) {
        final watch = Stopwatch()..start();
        b.update(1 / 60, producing: true);
        watch.stop();
        if (i >= 0) times.add(watch.elapsedMicroseconds);
      }
      times.sort();
      samples.add({
        'repeat': repeat,
        'metrics': enabled,
        'p50_us': times[300],
        'p95_us': times[570],
        'p99_us': times[594],
        'total_us': times.reduce((a, b) => a + b),
        'metric_bytes': utf8.encode(jsonEncode(b.metrics.toJson())).length,
        'emitted': b.spawned,
        'captured': b.captured,
        'finite': b.balls.every((ball) => ball.velocity.length.isFinite),
        'max_bodies': math.max(b.balls.length, b.metrics.peak),
      });
    }
  }
  double median(String key, bool enabled) {
    final values =
        samples
            .where((s) => s['metrics'] == enabled)
            .map((s) => (s[key] as int).toDouble())
            .toList()
          ..sort();
    return values[values.length ~/ 2];
  }

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'scope':
          'Linux Dart AOT simulation CPU only; no Android/render/GPU measurement',
      'warmup_steps': 120,
      'measured_steps': 600,
      'alternating_repeats': 7,
      'p50_overhead_percent':
          (median('p50_us', true) / median('p50_us', false) - 1) * 100,
      'p95_overhead_percent':
          (median('p95_us', true) / median('p95_us', false) - 1) * 100,
      'samples': samples,
    }),
  );
}
