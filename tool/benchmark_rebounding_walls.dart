import 'dart:io';
import 'dart:math' as math;
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';

// Synthetic CPU load, not game balance or a device/GPU FPS certification.
// Reinforce velocities deliberately so the workload does not settle from friction.
void main() {
  final catalog = UpgradeCatalog.fromCsv(
    File('docs/balance.csv').readAsStringSync(),
  );
  final board = Board(catalog.settings({'hand': 1, 'walls': 3}));
  final random = math.Random(42);
  void frame() {
    while (board.balls.length < 200) {
      board.balls.add(
        Ball(
          board.nextId++,
          Vec(6 + random.nextDouble() * 348, 100 + random.nextDouble() * 420),
          Vec.zero,
        ),
      );
    }
    for (final ball in board.balls) {
      ball.velocity = Vec(
        ball.position.x < 180 ? -380 : 380,
        (ball.id % 3 - 1) * 20.0,
      );
    }
    board.update(1 / 60, producing: false);
  }

  for (var i = 0; i < 120; i++) {
    frame();
  }
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < 600; i++) {
    frame();
  }
  stopwatch.stop();
  stdout.writeln(
    '200 balls replenished and driven towards walls each frame; '
    '600 measured frames after 120 warm-up frames; '
    'mean ${(stopwatch.elapsedMicroseconds / 600 / 1000).toStringAsFixed(3)} ms/frame; '
    'impact buffer ${board.wallImpacts.length}/${Board.maximumWallImpacts}. '
    'Physics only, without rendering.',
  );
}
