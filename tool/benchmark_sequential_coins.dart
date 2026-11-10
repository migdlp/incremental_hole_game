import 'dart:convert';
import 'dart:io';
import 'package:incremental_hole_game/features/rewards/domain/reward_delivery.dart';

// Uses the real planner and denominations; no economic or denomination overrides.
void main() {
  final reports = <Map<String, Object>>[];
  var checksum = 0.0;
  for (final amount in [1, 4, 46, 50, 100, 3400, 250000]) {
    for (final repeated in [false, true]) {
      final v = RewardVisuals(192, .2, seed: 17)..geometry(180, 123.2, 64);
      final samples = <int>[];
      var maxStarts = 0, peakPending = 0, lastStart = 0.0;
      var nextId = 1;
      for (var frame = 0; frame < 1500; frame++) {
        final w = Stopwatch()..start();
        if (frame == 0 || (repeated && frame < 900 && frame % 12 == 0)) {
          v.add(nextId++, amount);
        }
        final before = v.emittedObjects;
        v.advance(1 / 60);
        final starts = v.emittedObjects - before;
        if (starts > maxStarts) maxStarts = starts;
        if (starts > 0) lastStart = v.clock;
        if (v.pendingCount > peakPending) peakPending = v.pendingCount;
        for (final c in v.coins) {
          if (c.active) {
            checksum += c.x(320, .2, origin: 180) + c.y(28, .2, origin: 123.2);
          }
        }
        w.stop();
        samples.add(w.elapsedMicroseconds);
      }
      samples.sort();
      reports.add({
        'batch_amount': amount,
        'repeated_every_200ms_for_15s': repeated,
        'planned_coins': v.counts.values.fold<int>(0, (a, b) => a + b),
        'emitted_objects': v.emittedObjects,
        'grouped_coins': v.grouped,
        'omitted': v.omitted,
        'pending_after_25s': v.pendingCount,
        'active_peak': v.peak,
        'pending_peak': peakPending,
        'max_starts_per_frame': maxStarts,
        'last_start_at_sim_seconds': lastStart,
        'cpu_p95_us': samples[(samples.length * .95).floor()],
        'cpu_p99_us': samples[(samples.length * .99).floor()],
        'cpu_max_us': samples.last,
        'rss_bytes': ProcessInfo.currentRss,
      });
    }
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'scope':
          'Cloud AOT emitter, curves, grouping and real denomination planner. '
          'No Android GPU/FPS/audio timing certification. Last start is a simulation timestamp, not per-reward latency.',
      'checksum': checksum,
      'reports': reports,
    }),
  );
}
