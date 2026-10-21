import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/board/domain/wall_impact.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();
  Board board(int level, {int version = 9, double speedLimit = 380}) {
    final settings = catalog.settings({
      'hand': 1,
      if (level > 0) 'walls': level,
    }, balanceVersion: version);
    if (version == 9) settings.values['ball_speed_limit'] = speedLimit;
    return Board(settings);
  }

  Ball ball(Board board, Vec position, Vec velocity, {bool golden = false}) {
    final ball = Ball(board.nextId++, position, velocity, golden: golden);
    board.balls.add(ball);
    return ball;
  }

  test('all four walls use progressively stronger normal restitution', () {
    for (final golden in [false, true]) {
      final sides = [
        (const Vec(6.01, 260), const Vec(-100, 0)),
        (const Vec(353.99, 260), const Vec(100, 0)),
        (const Vec(80, 6.01), const Vec(0, -100)),
        (const Vec(80, 553.99), const Vec(0, 100)),
      ];
      for (final (position, velocity) in sides) {
        var previousSpeed = 0.0;
        for (var level = 0; level <= 3; level++) {
          final b = board(level);
          final item = ball(b, position, velocity, golden: golden);
          b.update(1 / 240, producing: false);
          final coefficient = [.4, 1.1, 1.35, 1.6][level];
          expect(
            item.velocity.x * velocity.x + item.velocity.y * velocity.y,
            lessThan(0),
          );
          expect(
            item.velocity.length,
            closeTo(100 * math.exp(-1.6 / 240) * coefficient, .001),
          );
          expect(item.velocity.length, greaterThan(previousSpeed));
          previousSpeed = item.velocity.length;
          expect(b.wallImpacts.length, level == 0 ? 0 : 1);
        }
      }
    }
  });

  test('corners combine normals once, keep tangent and cap every result', () {
    for (final (position, incoming) in [
      (const Vec(6.01, 6.01), const Vec(-100, -100)),
      (const Vec(353.99, 6.01), const Vec(100, -100)),
      (const Vec(6.01, 553.99), const Vec(-100, 100)),
      (const Vec(353.99, 553.99), const Vec(100, 100)),
    ]) {
      final b = board(3);
      final item = ball(b, position, incoming);
      b.update(1 / 240, producing: false);
      expect(
        item.velocity.length,
        closeTo(incoming.length * math.exp(-1.6 / 240) * 1.6, .01),
      );
      expect(item.velocity.x * incoming.x, lessThan(0));
      expect(item.velocity.y * incoming.y, lessThan(0));
      expect(b.wallImpacts.length, 2);
    }
    final b = board(3);
    final item = ball(b, const Vec(6.01, 6.01), const Vec(-900, -900));
    b.update(1 / 240, producing: false);
    expect(item.velocity.length, closeTo(380, .001));
    final tangentBoard = board(3);
    final tangent = ball(
      tangentBoard,
      const Vec(6.01, 260),
      const Vec(-100, 30),
    );
    tangentBoard.update(1 / 240, producing: false);
    expect(tangent.velocity.y, closeTo(30 * math.exp(-1.6 / 240), .001));
    final capped = board(3, speedLimit: 200);
    final fast = ball(capped, const Vec(6.01, 260), const Vec(-380, 0));
    capped.update(1 / 240, producing: false);
    expect(fast.velocity.length, closeTo(200, .001));
  });

  test('stationary and inward wall contacts do not manufacture impulses', () {
    for (final velocity in [Vec.zero, const Vec(50, 0), const Vec(0, 50)]) {
      final b = board(3);
      final item = ball(b, const Vec(6, 260), velocity);
      for (var i = 0; i < 120; i++) {
        b.update(1 / 240, producing: false);
      }
      expect(item.velocity.length, lessThanOrEqualTo(velocity.length));
      expect(b.wallImpacts, isEmpty);
    }
    final b = board(3);
    final item = ball(b, const Vec(6.01, 260), const Vec(-100, 0));
    b.update(1 / 240, producing: false);
    final outgoing = item.velocity.length;
    for (var i = 0; i < 20; i++) {
      b.update(1 / 240, producing: false);
    }
    expect(item.velocity.length, lessThan(outgoing));
    expect(b.wallImpacts, hasLength(1));
  });

  test(
    'manual grip also respects the configured travel and velocity limit',
    () {
      final b = board(3);
      final item = ball(b, const Vec(60, 260), Vec.zero);
      b.touch(item.position, time: 0);
      b.drag(const Vec(340, 260), time: .01);
      final before = item.position;
      b.update(1 / 60, producing: false);
      expect(
        (item.position - before).length,
        lessThanOrEqualTo(380 / 60 + .00001),
      );
      expect(item.velocity.length, lessThanOrEqualTo(380.00001));
    },
  );

  test(
    'fast normal and golden balls are captured along the path after a rebound',
    () {
      for (final golden in [false, true]) {
        final b = board(3);
        final item = ball(
          b,
          const Vec(180, 6.01),
          const Vec(0, -380),
          golden: golden,
        );
        final events = b.update(.6, producing: false);
        expect(b.balls, isEmpty);
        expect(events.captured, 1);
        expect(events.goldenCaptured, golden ? 1 : 0);
        expect(events.rewards, [golden ? 10 : 1]);
        expect(
          b.wallImpacts.any((impact) => impact.wall == WallSide.top),
          isTrue,
        );
        expect(item.position.y, lessThan(80));
      }
      final b = board(3);
      ball(b, const Vec(140, 50), const Vec(380, 0));
      expect(b.update(.4, producing: false).captured, 1);
    },
  );

  test('coins and frozen collection-phase balls are unaffected', () {
    final snapshots = <String>[];
    for (final level in [0, 3]) {
      final b = board(level);
      b.coins.add(Coin(b.nextId++, const Vec(6, 200), 10, landing: 0));
      b.update(.1, producing: false);
      snapshots.add(jsonEncode(b.coins.single.toJson()));
      final item = ball(b, const Vec(6.01, 260), const Vec(-380, 0));
      b.enterClosing();
      b.update(1, producing: false);
      expect(item.position.x, 6.01);
      expect(item.velocity.x, -380);
      expect(b.wallImpacts, isEmpty);
    }
    expect(snapshots[0], snapshots[1]);
  });

  test(
    'purchases persist through reload and apply only to subsequent days',
    () async {
      final session = GameSession(catalog, MemoryStore());
      session.economy.balance = 10000;
      final hand = catalog.definitions.firstWhere((d) => d.id == 'hand');
      final walls = catalog.definitions.firstWhere((d) => d.id == 'walls');
      expect(session.purchase(walls), isFalse);
      expect(session.purchase(hand), isTrue);
      for (var level = 1; level <= 3; level++) {
        expect(session.purchase(walls), isTrue);
        final restored = GameSession(catalog, MemoryStore())
          ..restore(session.snapshot());
        expect(restored.levels['walls'], level);
        restored.startDay();
        expect(restored.board!.wallRestitution, walls.levels[level - 1].value);
        final before = restored.board!.settings.toJson();
        expect(restored.purchase(walls), isFalse);
        expect(restored.board!.settings.toJson(), before);
        final midDay = GameSession(catalog, MemoryStore())
          ..restore(restored.snapshot());
        expect(midDay.board!.wallRestitution, walls.levels[level - 1].value);
        midDay.resume();
        midDay.finishDay();
        midDay.startDay();
        expect(midDay.board!.wallRestitution, walls.levels[level - 1].value);
        await midDay.pendingWrites;
        midDay.dispose();
        await restored.pendingWrites;
        restored.dispose();
      }
      expect(session.purchase(walls), isFalse);
      await session.pendingWrites;
      session.dispose();
    },
  );

  test('v8 active saves keep their old settings until the next day', () async {
    final session = GameSession(catalog, MemoryStore())..startDay();
    final data = jsonDecode(session.snapshot()) as Map<String, dynamic>;
    data['run']['balanceVersion'] = 8;
    data['run']['settings'] = catalog.settings({}, balanceVersion: 8).toJson();
    final restored = GameSession(catalog, MemoryStore())
      ..restore(jsonEncode(data));
    expect(restored.board!.settings.balanceVersion, 8);
    expect(restored.board!.wallRestitution, .4);
    expect(restored.board!.maximumSpeed, 380);
    restored.resume();
    restored.finishDay();
    restored.startDay();
    expect(restored.board!.settings.balanceVersion, 10);
    expect(restored.board!.wallRestitution, .4);
    await session.pendingWrites;
    await restored.pendingWrites;
    session.dispose();
    restored.dispose();
  });

  test(
    '200 balls remain bounded and speed-limited; impacts are bounded and expire',
    () {
      final b = board(3);
      for (var i = 0; i < 200; i++) {
        ball(
          b,
          Vec(8 + (i % 20) * 18, 110 + (i ~/ 20) * 36),
          Vec(i.isEven ? -380 : 380, 60),
          golden: i % 5 == 0,
        );
      }
      for (var frame = 0; frame < 120; frame++) {
        b.update(1 / 60, producing: false);
        expect(
          b.wallImpacts.length,
          lessThanOrEqualTo(Board.maximumWallImpacts),
        );
        for (final ball in b.balls) {
          expect(ball.velocity.length.isFinite, isTrue);
          expect(ball.velocity.length, lessThanOrEqualTo(380.000001));
          expect(ball.position.x, inInclusiveRange(6, 354));
          expect(ball.position.y, inInclusiveRange(6, 554));
        }
      }
      b.balls.clear();
      b.update(WallImpact.lifetime + .01, producing: false);
      expect(b.wallImpacts, isEmpty);
    },
  );

  test(
    'elastic waves are symmetric, intensity-scaled and visual only',
    () async {
      final weak = WallImpact(WallSide.left, 260, .25)..age = .08;
      final strong = WallImpact(WallSide.left, 260, 1)..age = .08;
      expect(strong.displacementAt(240), strong.displacementAt(280));
      expect(
        strong.displacementAt(240),
        closeTo(weak.displacementAt(240) * 4, .0001),
      );
      final travelling = WallImpact(WallSide.left, 260, 1);
      final early = travelling.displacementAt(300).abs();
      travelling.age = .18;
      expect(travelling.displacementAt(300).abs(), greaterThan(early * 10));
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 1, 'walls': 3})
        ..startDay();
      ball(session.board!, const Vec(6.01, 260), const Vec(-200, 0));
      session.board!.update(1 / 240, producing: false);
      final before = jsonEncode(session.board!.toJson());
      final game = GardenGame(session)..onGameResize(Vector2(360, 560));
      Future<List<int>> render() async {
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(360, 560);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final bytes = List<int>.of(data.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        return bytes;
      }

      final animated = await render();
      game.wallEffectsEnabled = false;
      final reduced = await render();
      expect(animated, isNot(orderedEquals(reduced)));
      expect(jsonEncode(session.board!.toJson()), before);
      expect(
        session.visualFeedback,
        isFalse,
      ); // independent of pointer feedback
      await session.pendingWrites;
      session.dispose();
    },
  );
}
