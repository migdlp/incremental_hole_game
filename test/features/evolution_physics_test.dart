import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/evolution/domain/evolution.dart';
import 'package:incremental_hole_game/features/prestige/domain/permanent_skills.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_bubbles.dart';
import 'package:incremental_hole_game/features/prestige/domain/star_rewards.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();
  Map<String, int> one(EvolutionId id, int level) => {
    EvolutionSkill.of(id).id: level,
  };
  test(
    'new forces point to the hole, combine, respect caps and never target P01',
    () {
      final levels = {
        ...one(EvolutionId.whirlpool, 5),
        ...one(EvolutionId.pulse, 5),
        ...one(EvolutionId.gravity, 5),
      };
      final b = Board(catalog.settings({}));
      final r = EvolutionRun(levels: levels)..pulseClock = 20 - 1 / 240;
      r.whirlpool.level = 5;
      r.whirlpool.remaining = 2;
      r.gravity.level = 5;
      r.gravity.remaining = 2;
      b.evolution = r;
      final ball = Ball(
        b.nextId++,
        b.holePosition + const Vec(50, 0),
        Vec.zero,
      );
      b.balls.add(ball);
      final config = StarConfig(catalog.base);
      final ledger = const StarLedger().award(1, config);
      final bubbles = StarBubbles(config, ballRadius: b.radius)
        ..sync(ledger)
        ..populateImmediate();
      final bubble = bubbles.bodies.single
        ..position = const Vec(60, 500)
        ..velocity = Vec.zero;
      b.starBubbles = bubbles;
      b.update(1 / 240, producing: true);
      expect(ball.velocity.x, lessThan(-20));
      expect(ball.velocity.length, lessThanOrEqualTo(380));
      expect(bubble.position.x, 60);
      expect(bubble.velocity.x, 0);
      expect(b.captured, 0);
    },
  );
  test(
    'held balls remain under player control while evolution attraction is active',
    () {
      final b = Board(catalog.settings({}));
      final r = EvolutionRun(levels: one(EvolutionId.gravity, 5));
      r.gravity.level = 5;
      r.gravity.remaining = 2;
      b.evolution = r;
      final ball = Ball(b.nextId++, const Vec(100, 300), Vec.zero);
      b.balls.add(ball);
      b.touch(ball.position);
      b.update(1 / 60, producing: true);
      expect(b.heldBalls, contains(ball));
      expect(ball.velocity.length, 0);
    },
  );
  test(
    'directed wall steering preserves bounce speed with deterministic probability',
    () {
      Board board(bool enhanced) {
        final b = Board(catalog.settings({}));
        if (enhanced)
          b.evolution = EvolutionRun(
            levels: one(EvolutionId.directed, 5),
            randomState: 0,
          );
        b.balls.add(
          Ball(b.nextId++, Vec(b.radius - .1, 300), const Vec(-100, 20)),
        );
        return b;
      }

      final normal = board(false), directed = board(true);
      normal.update(1 / 240, producing: true);
      directed.update(1 / 240, producing: true);
      expect(
        directed.balls.single.velocity.length,
        closeTo(normal.balls.single.velocity.length, 1e-8),
      );
      final target =
          (directed.holePosition - directed.balls.single.position).unit;
      double dot(Vec v) => v.unit.x * target.x + v.unit.y * target.y;
      expect(
        dot(directed.balls.single.velocity),
        greaterThan(dot(normal.balls.single.velocity)),
      );
    },
  );
  test(
    'ariete, ration and P02 echo fire together, with no recursive cycles',
    () {
      final b = Board(catalog.settings({}));
      final r =
          EvolutionRun(
              levels: {
                ...one(EvolutionId.ram, 1),
                ...one(EvolutionId.ration, 1),
              },
            )
            ..ramCycles = 49
            ..rationCycles = 39;
      final p = PermanentRun()..cycles = 19;
      b.evolution = r;
      b.permanentRun = p;
      b.productionEcho = true;
      b.spawnClock = b.settings['spawn_interval'];
      b.update(1 / 240, producing: true);
      expect(b.balls.length, 8);
      expect(b.balls.where((v) => v.heavy).length, 1);
      expect(r.ramCycles, 0);
      expect(r.rationCycles, 0);
      expect(p.cycles, 0);
      expect(r.pendingRam + r.pendingRation + p.pendingEcho, 0);
      for (final ball in b.balls) {
        expect(ball.velocity.length, lessThanOrEqualTo(380));
      }
    },
  );
  test(
    'extra balls retry blockage and retain their identity of pending production across JSON',
    () {
      final r = EvolutionRun(levels: one(EvolutionId.ram, 1))
        ..pendingRam = 2
        ..lastQuota = 0;
      final b = Board(catalog.settings({}))..evolution = r;
      for (var i = 0; i < b.settings['ball_limit']; i++) {
        b.balls.add(Ball(b.nextId++, const Vec(20, 500), Vec.zero));
      }
      b.update(1 / 240, producing: true);
      expect(r.pendingRam, 2);
      final saved = EvolutionRun.fromJson(
        jsonDecode(jsonEncode(r.toJson())),
        levels: r.levels,
      );
      expect(saved.pendingRam, 2);
      b.balls.clear();
      b.evolution = saved;
      b.update(1 / 240, producing: true);
      expect(saved.pendingRam, 1);
      expect(b.balls.single.heavy, isTrue);
    },
  );
  test(
    'Midas changes natural main probability only and never replaces guaranteed gold',
    () {
      Board create(bool enhanced) {
        final b = Board(catalog.settings({}), randomState: 66);
        if (enhanced)
          b.evolution = EvolutionRun(levels: one(EvolutionId.midas, 5));
        b.spawnClock = b.settings['spawn_interval'];
        return b;
      }

      final ordinary = create(false), midas = create(true);
      ordinary.update(1 / 240, producing: true);
      midas.update(1 / 240, producing: true);
      expect(ordinary.balls.single.golden, isFalse);
      expect(midas.balls.single.golden, isTrue);
      final guaranteed = PermanentRun()..beginDay(goldenTime: 0);
      midas.permanentRun = guaranteed;
      midas.balls.clear();
      midas.update(1 / 240, producing: true);
      expect(guaranteed.goldenSpawned, isTrue);
      expect(midas.balls.single.golden, isTrue);
      expect(guaranteed.cycles, 0);
    },
  );
  test('all five approved tables remain exact', () {
    expect(EvolutionSkill.of(EvolutionId.whirlpool).values, [
      1.5,
      1.75,
      2,
      2.25,
      2.5,
    ]);
    expect(EvolutionSkill.of(EvolutionId.hunger).values, [
      .04,
      .06,
      .08,
      .10,
      .12,
    ]);
    expect(EvolutionSkill.of(EvolutionId.ram).values, [50, 45, 40, 35, 30]);
    expect(EvolutionSkill.of(EvolutionId.ration).values, [40, 35, 30, 25, 20]);
    expect(EvolutionSkill.millionaireDurations, [3, 6, 7, 8, 10]);
    expect(EvolutionSkill.of(EvolutionId.millionaire).values, [2, 2, 2, 3, 3]);
    expect(EvolutionSkill.of(EvolutionId.midas).values, [
      .005,
      .01,
      .015,
      .02,
      .025,
    ]);
    expect(EvolutionSkill.of(EvolutionId.luck).values, [
      .01,
      .02,
      .03,
      .04,
      .05,
    ]);
  });
}
