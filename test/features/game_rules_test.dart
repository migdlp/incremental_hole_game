import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/day_cycle/domain/day_cycle.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
import 'package:incremental_hole_game/persistence/store_native.dart';
import '../test_support.dart';

void advance(GameSession session, double seconds) {
  for (var i = 0; i < (seconds * 60).round(); i++) {
    session.tick(1 / 60);
  }
}

void capture(GameSession session) {
  final board = session.board!;
  board.balls.add(Ball(board.nextId++, Board.hole, Vec.zero));
  session.tick(1 / 60);
}

void main() {
  final catalog = testCatalog();
  test('balance source includes tool and coin unlocks with prerequisites', () {
    expect(catalog.definitions.length, 23);
    final levels = {for (final d in catalog.definitions) d.id: d.levels.length};
    final max = catalog.settings(levels);
    expect(max['production_duration'], 30);
    expect(max['ball_value'], 13);
    expect(max['spawn_interval'], closeTo(1 / (1.5 * 3.0517578125), 1e-9));
    expect(
      () => UpgradeCatalog.fromCsv('invalid\nbase,x'),
      throwsFormatException,
    );
  });
  test('timer reaches closing and exact end without overshooting', () {
    final clock = DayCycle(production: 60, closing: 5);
    expect(clock.advance(60), 60);
    expect(clock.phase, DayPhase.closing);
    expect(clock.advance(12), 5);
    expect(clock.phase, DayPhase.night);
    expect(clock.remaining, 0);
  });
  test('capture removes ball once and never directly credits balance', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    capture(session);
    expect(session.board!.captured, 1);
    expect(session.economy.generated, 1);
    expect(session.economy.collected, 0);
    expect(session.economy.balance, 0);
    advance(session, .3);
    expect(session.economy.generated, 1);
    advance(session, 2);
    expect(session.economy.collected, 1);
    expect(session.board!.pending, 0);
  });
  test('coin cap and queued denominations preserve every unit of value', () {
    final settings = catalog.settings({}, balanceVersion: 14);
    settings.values['coin_pile_limit'] = 2;
    final board = Board(settings);
    for (var i = 0; i < 1000; i++) {
      board.releaseCoin(5);
    }
    expect(board.coins.length, lessThanOrEqualTo(2));
    expect(board.pending, 5000);
    final restored = Board.fromJson(settings, board.toJson());
    expect(restored.pending, 5000);
  });
  test('fast pointer sweep collects between endpoints exactly once', () {
    final board = Board(catalog.settings({'sweep': 1}, balanceVersion: 14));
    board.coins.add(Coin(board.nextId++, const Vec(120, 300), 7, landing: 0));
    board.touch(const Vec(30, 300));
    var collected = board.drag(const Vec(240, 300));
    board.releasePointer();
    for (var i = 0; i < 20; i++) {
      collected += board.update(1 / 60, producing: false).collected;
    }
    expect(collected, 7);
    expect(board.coins, isEmpty);
  });
  test(
    'ten complete cycles bank once, discard pending and begin clean',
    () async {
      final session = GameSession(catalog, MemoryStore())
        ..levels.addAll({'hand': 1, 'reward': 1});
      for (var day = 1; day <= 10; day++) {
        session.startDay();
        expect(session.board!.coins, isEmpty);
        expect(session.board!.balls, isEmpty);
        capture(session);
        advance(session, .3);
        advance(session, 2);
        session.board!.balls.add(
          Ball(session.board!.nextId++, const Vec(40, 450), Vec.zero),
        );
        capture(session);
        advance(session, 66);
        expect(session.running, isFalse);
        expect(session.board, isNull);
        expect(jsonDecode(session.snapshot())['run'], isNull);
        expect(session.economy.balance, day * 4);
        expect(session.progress.last!.lost, 0);
        expect(session.progress.last!.income, 4);
        session.finishDay();
        expect(session.economy.balance, day * 4);
        await session.pendingWrites;
      }
      expect(session.progress.day, 11);
      expect(session.progress.record, 4);
    },
  );
  test(
    'purchases enforce phase, funds, prerequisite and level cap atomically',
    () {
      final session = GameSession(catalog, MemoryStore());
      final robot = catalog.definitions.firstWhere((d) => d.id == 'robot');
      final paddle = catalog.definitions.firstWhere((d) => d.id == 'paddle');
      session.economy.balance = 1000;
      expect(session.purchase(robot), isFalse);
      expect(session.economy.balance, 1000);
      for (final id in ['hand', 'hand', 'broom', 'paddle', 'paddle']) {
        expect(
          session.purchase(catalog.definitions.firstWhere((d) => d.id == id)),
          isTrue,
        );
      }
      expect(session.purchase(robot), isTrue);
      expect(session.economy.balance, 527);
      expect(session.purchase(robot), isFalse);
      session.startDay();
      expect(session.board!.settings['robot_count'], 1);
      expect(session.purchase(paddle), isFalse);
      expect(session.economy.balance, 527);
      session.finishDay();
      session.economy.balance = 0;
      expect(session.purchase(paddle), isFalse);
      expect(session.levels['paddle'], 2);
    },
  );
  test(
    'pause stops time, cancels gesture, resumes without wall clock catchup',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      session.touch(const Vec(100, 200));
      advance(session, 2);
      session.pause();
      final remaining = session.cycle!.remaining;
      advance(session, 100);
      expect(session.cycle!.remaining, remaining);
      expect(session.board!.paddle, isNull);
      session.resume();
      session.tick(1 / 60);
      expect(session.cycle!.remaining, closeTo(remaining - 1 / 60, .0001));
    },
  );
  test(
    'midday restore keeps objects, random state and accounting, stays paused',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      capture(session);
      advance(session, .1);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.paused, isTrue);
      expect(restored.board!.paddle, isNull);
      expect(restored.rewards.outstanding, 0);
      expect(restored.economy.collected, 1);
      expect(restored.board!.coins, isEmpty);
      expect(restored.board!.randomState, session.board!.randomState);
      restored.resume();
      advance(restored, .3);

      restored.finishDay();
      restored.finishDay();
      expect(restored.economy.balance, 1);
      final reopened = GameSession(catalog, MemoryStore())
        ..restore(restored.snapshot());
      expect(reopened.running, isFalse);
      expect(reopened.economy.balance, 1);
    },
  );
  test('restoring corrupt accounting does not mutate the existing session', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    final data = jsonDecode(session.snapshot()) as Map<String, dynamic>;
    data['balance'] = 999;
    data['run']['generated'] = 100;
    expect(() => session.restore(jsonEncode(data)), throwsFormatException);
    expect(session.economy.balance, 0);
  });
  test('save failure is surfaced and later saves can recover', () async {
    final store = MemoryStore()..fail = true;
    final session = GameSession(catalog, store)..startDay();
    await session.pendingWrites;
    expect(session.saveError, isNotNull);
    store.fail = false;
    await session.save();
    expect(session.saveError, isNull);
  });
  test(
    'loading uses a valid backup without overwriting corrupt saves',
    () async {
      final store = MemoryStore();
      final original = GameSession(catalog, store)..startDay();
      await original.pendingWrites;
      store.candidates = ['not json', original.snapshot()];
      final restored = GameSession(catalog, store);
      await restored.load();
      expect(restored.running, isTrue);
      expect(restored.recoveryMessage, isNotNull);
      store.candidates = ['broken', '{}'];
      expect(GameSession(catalog, store).load(), throwsFormatException);
    },
  );
  test(
    'file adapter replaces complete snapshots and retains valid backup',
    () async {
      final directory = await Directory.systemTemp.createTemp('garden-save-');
      addTearDown(() => directory.delete(recursive: true));
      final store = FileSaveStore(directory.path);
      final session = GameSession(catalog, store)..startDay();
      await session.pendingWrites;
      session.pause();
      await session.pendingWrites;
      final candidates = await store.loadCandidates();
      expect(candidates.length, 2);
      expect(() => jsonDecode(candidates.first), returnsNormally);
      expect(await File('${directory.path}/progress.tmp').exists(), isFalse);
      await File(
        '${directory.path}/progress.json',
      ).writeAsString('interrupted');
      final restored = GameSession(catalog, store);
      await restored.load();
      expect(restored.running, isTrue);
      expect(restored.paused, isTrue);
    },
  );
  test(
    'spatial collisions conserve packed balls or capture them inside bounds',
    () {
      final board = Board(catalog.settings({}));
      for (var i = 0; i < 10; i++) {
        board.balls.add(
          Ball(
            board.nextId++,
            Vec(100 + i % 5 * 11.0, 200 + i ~/ 5 * 11.0),
            Vec.zero,
          ),
        );
      }
      board.touch(const Vec(90, 200));
      board.drag(const Vec(170, 270));
      for (var i = 0; i < 300; i++) {
        board.update(1 / 60, producing: false);
      }
      expect(board.balls.length + board.captured, 10);
      expect(
        board.balls.every(
          (b) =>
              b.position.x >= 6 &&
              b.position.x <= 354 &&
              b.position.y >= 6 &&
              b.position.y <= 554,
        ),
        isTrue,
      );
    },
  );
  test(
    'robot pushes a reachable ball to the hole without collecting coins',
    () {
      final board = Board(
        catalog.settings({'broom': 1, 'paddle': 1, 'robot': 1}),
      );
      board.balls.add(Ball(board.nextId++, const Vec(180, 340), Vec.zero));
      var captured = 0;
      for (var i = 0; i < 60 * 30; i++) {
        final events = board.update(1 / 60, producing: false);
        captured += events.captured;
        if (events.captured > 0) board.releaseCoin(2);
        expect(events.collected, 0);
      }
      expect(captured, 1);
      expect(board.pending, 0);
    },
  );
  test('historical magnet works only with pointer held near the coin', () {
    final board = Board(
      catalog.settings({'collection': 1, 'magnet': 1}, balanceVersion: 14),
    );
    board.coins.add(Coin(board.nextId++, const Vec(140, 300), 2, landing: 0));
    for (var i = 0; i < 60; i++) {
      board.update(1 / 60, producing: false);
    }
    expect(board.pending, 2);
    board.touch(const Vec(100, 300));
    var collected = 0;
    for (var i = 0; i < 60; i++) {
      collected += board.update(1 / 60, producing: false).collected;
    }
    expect(collected, 2);
  });
}
