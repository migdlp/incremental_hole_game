import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
import 'package:incremental_hole_game/features/prestige/domain/permanent_skills.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_rewards.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_bubbles.dart';

void main() {
  final catalog = UpgradeCatalog.fromCsv(
    File('docs/balance.csv').readAsStringSync(),
  );
  final reports = <Map<String, Object>>[];
  for (final count in [0, 24, 100, 500]) {
    final board = Board(catalog.settings({'launcher': 1, 'hand': 1, 'bat': 1}));
    final config = StarConfig(catalog.base);
    var ledger = const StarLedger();
    for (var q = 1; ledger.pending.length < count; q++) {
      ledger = ledger.award(q, config);
    }
    final bubbles = StarBubbles(config, ballRadius: board.radius)..sync(ledger);
    final create = Stopwatch()..start();
    bubbles.populateImmediate();
    create.stop();
    board.starBubbles = bubbles;
    board.permanentRun = PermanentRun()..beginDay(goldenTime: 5);
    board.productionEcho = true;
    for (var i = 0; i < 100; i++) {
      board.balls.add(
        Ball(
          board.nextId++,
          Vec(20 + (i % 10) * 32, 200 + (i ~/ 10) * 24),
          Vec((i % 3 - 1) * 35, -20),
        ),
      );
    }
    final samples = <int>[];
    var warmupMax = 0;
    for (var i = -60; i < 600; i++) {
      final w = Stopwatch()..start();
      board.update(1 / 60, producing: true);
      w.stop();
      if (i >= 0) {
        samples.add(w.elapsedMicroseconds);
      } else {
        warmupMax = math.max(warmupMax, w.elapsedMicroseconds);
      }
    }
    samples.sort();
    reports.add({
      'initial_bubbles': count,
      'creation_us': create.elapsedMicroseconds,
      'warmup_max_us': warmupMax,
      'step_p50_us': samples[300],
      'step_p95_us': samples[570],
      'step_p99_us': samples[594],
      'step_max_us': samples.last,
      'remaining_bubbles': bubbles.bodies.length,
      'initial_ball_count': 100,
      'rss_bytes': ProcessInfo.currentRss,
      'frames': samples.length,
      'max_ball_speed': board.balls.fold<double>(
        0.0,
        (n, b) => math.max(n, b.velocity.length),
      ),
    });
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'environment':
          'Cloud Linux AOT; simulation only, no Android renderer/audio/GPU',
      'reports': reports,
    }),
  );
}
