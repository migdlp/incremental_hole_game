// Run with each checkout's package configuration; hashes exclude instrumentation.
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/special_abilities.dart';
import 'package:incremental_hole_game/features/evolution/domain/evolution.dart';
import 'package:incremental_hole_game/features/prestige/domain/permanent_skills.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_bubbles.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_rewards.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';

void main() {
  final catalog = UpgradeCatalog.fromCsv(
    File('docs/balance.csv').readAsStringSync(),
  );
  final rows = <Map<String, Object>>[];
  for (final seed in [42, 79, 2026]) {
    for (final extras in [false, true]) {
      final settings = catalog.settings({
        'generator': 3,
        'double_spawn': 1,
        'launcher': 1,
        'walls': 3,
        'robot': 1,
        'capture_all': 1,
      });
      final b = Board(settings, randomState: seed);
      if (extras) {
        b.evolution = EvolutionRun(
          levels: {for (final skill in EvolutionSkill.catalogue) skill.id: 5},
          randomState: seed,
          cardRandom: seed ^ 79,
        );
        b.permanentRun = PermanentRun()..beginDay(goldenTime: 2);
        b.productionEcho = true;
        b.starBubbles = StarBubbles(
          StarConfig(catalog.base),
          ballRadius: b.radius,
          maximumSpeed: b.maximumSpeed,
          hole: b.holePosition,
        );
      }
      final events = <Object>[];
      for (var i = 0; i < 1200; i++) {
        if (i % 120 == 0 && b.balls.isNotEmpty) {
          b.touch(b.balls.first.position, time: i / 60);
        }
        if (i % 120 < 90) b.drag(Vec(180, 490 - i % 120 * 4.0), time: i / 60);
        if (i % 120 == 90) b.releasePointer(time: i / 60);
        if (i % 300 == 0) b.activateSpecial(SpecialAbility.captureAll);
        final e = b.update(1 / 60, producing: i < 900);
        events.add([
          e.captured,
          e.collected,
          e.goldenCaptured,
          e.rewards,
          e.normalFood,
          e.instantFood,
        ]);
      }
      final game = b.toJson()..remove('balanceMetrics');
      final digest = sha256
          .convert(
            utf8.encode(
              jsonEncode({
                'board': game,
                'events': events,
                'evolution': b.evolution?.toJson(),
                'permanent': b.permanentRun?.toJson(),
                'spawned': b.spawned,
              }),
            ),
          )
          .toString();
      rows.add({
        'seed': seed,
        'extras': extras,
        'digest': digest,
        'captured': b.captured,
        'spawned': b.spawned,
      });
    }
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({'physics_fingerprints': rows}),
  );
}
