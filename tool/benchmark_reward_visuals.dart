import 'dart:convert';
import 'dart:io';
import 'package:incremental_hole_game/features/rewards/domain/reward_delivery.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_visual_config.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/core/vec.dart';

void main(List<String> args) {
  final catalog = UpgradeCatalog.fromCsv(
    File('docs/balance.csv').readAsStringSync(),
  );
  final capacity = args.isEmpty
      ? catalog.base['reward_visual_limit']!.toInt()
      : int.parse(args.first);
  final results = <Map<String, Object>>[];
  var checksum = 0.0;
  for (final scenario in [
    (1, false, false),
    (10, false, false),
    (50, false, false),
    (100, false, false),
    (100, true, false),
    (100, true, true),
  ]) {
    final samples = <int>[];
    var peak = 0, grouped = 0, omitted = 0;
    final rssBefore = ProcessInfo.currentRss;
    for (var run = -1; run < 12; run++) {
      final v = RewardVisuals(
        capacity,
        catalog.base['reward_delay']!,
        config: RewardVisualConfig.fromMap(catalog.base),
      );
      Board? board;
      if (scenario.$3) {
        board = Board(catalog.settings({'paddle': 3, 'bat': 3, 'launcher': 1}));
        for (var i = 0; i < 200; i++) {
          board.balls.add(
            Ball(
              board.nextId++,
              Vec(15 + i % 20 * 17.0, 220 + i ~/ 20 * 22.0),
              Vec(i.isEven ? 50 : -50, 15),
            ),
          );
        }
      }
      var id = 0;
      for (var frame = 0; frame < 240; frame++) {
        final watch = Stopwatch()..start();
        if (frame == 0 || (scenario.$2 && frame < 60 && frame % 12 == 0)) {
          for (var i = 0; i < scenario.$1; i++) {
            v.add(++id, 34);
          }
        }
        v.observeFrame(1 / 60);
        v.advance(1 / 60);
        board?.update(1 / 60, producing: true);
        for (final c in v.coins) {
          if (c.active) checksum += c.x(310, v.delay) + c.y(28, v.delay);
        }
        watch.stop();
        if (run >= 0) samples.add(watch.elapsedMicroseconds);
      }
      peak = v.peak;
      grouped = v.grouped;
      omitted = v.omitted;
    }
    samples.sort();
    int percentile(double p) => samples[((samples.length - 1) * p).round()];
    results.add({
      'captures': scenario.$1,
      'repeated': scenario.$2,
      'loaded_board': scenario.$3,
      'samples': samples.length,
      'cpu_model_p50_us': percentile(.5),
      'cpu_model_p95_us': percentile(.95),
      'cpu_model_p99_us': percentile(.99),
      'cpu_model_max_us': samples.last,
      'rss_before_bytes': rssBefore,
      'rss_after_bytes': ProcessInfo.currentRss,
      'visual_peak': peak,
      'grouped': grouped,
      'omitted': omitted,
    });
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'scope':
          'Cloud Dart VM; model/curve/optional board CPU only. No Flutter painting, hardware GPU or Android FPS.',
      'capacity': capacity,
      'checksum': checksum,
      'scenarios': results,
    }),
  );
}
