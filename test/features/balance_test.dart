import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/day_cycle/domain/day_cycle.dart';
import '../test_support.dart';

void advance(GameSession session, int frames) {
  for (var i = 0; i < frames; i++) {
    session.tick(1 / 60);
  }
}

void main() {
  final catalog = testCatalog();
  test('initial day lasts 20 seconds: 15 production and 5 collection', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    expect(session.cycle!.remaining, 20);
    advance(session, 900);
    expect(session.phase, DayPhase.closing);
    expect(session.cycle!.remaining, closeTo(5, .001));
    expect(session.board!.balls.length, 22);
    advance(session, 299);
    expect(session.running, isTrue);
    expect(session.board!.balls.length, 22); // no production during closing
    advance(session, 1);
    expect(session.running, isFalse);
  });

  test(
    'generation starts at 1.5 balls per second and every upgrade is faster',
    () {
      for (var level = 0; level <= 5; level++) {
        final levels = {'generator': level};
        final current = catalog.settings(levels);
        expect(
          current['spawn_interval'],
          closeTo(1 / (1.5 * pow(1.25, level)), 1e-9),
        );
        expect(current['production_duration'], 15);
        if (level == 0) {
          expect(1 / current['spawn_interval'], closeTo(1.5, 1e-9));
        }
        if (level > 0) {
          expect(
            current['spawn_interval'],
            lessThan(
              catalog.settings({'generator': level - 1})['spawn_interval'],
            ),
          );
        }
      }
      for (var level = 1; level <= 3; level++) {
        expect(
          catalog.settings({
            'generator': 1,
            'duration': level,
          })['production_duration'],
          15 + level * 3,
        );
      }
    },
  );

  test(
    'first ball waits two thirds of a second, then three spawn every two seconds',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      advance(session, 39);
      expect(session.board!.balls, isEmpty);
      advance(session, 1);
      expect(session.board!.balls.length, 1);
      advance(session, 80);
      expect(session.board!.balls.length, 3);
    },
  );

  test('old v2 run survives reload until next day adopts the new balance', () {
    final session = GameSession(catalog, MemoryStore());
    session.levels.addAll({'generator': 1, 'duration': 2});
    session.economy.balance = 123;
    session.startDay();
    final data = jsonDecode(session.snapshot()) as Map<String, dynamic>;
    data['version'] = 2;
    data['run']['board'].remove('combo');
    data['run']['board'].remove('specials');
    data['run']['board'].remove('captureAllIds');
    data['run'].remove('balanceVersion');
    data['run']['settings'] = catalog
        .settings(session.levels, balanceVersion: 1)
        .toJson();
    data['run']['remaining'] = 72.0;
    final restored = GameSession(catalog, MemoryStore())
      ..restore(jsonEncode(data));
    expect(restored.cycle!.remaining, 72);
    expect(restored.board!.settings['production_duration'], 70);
    expect(restored.board!.settings['spawn_interval'], .65);
    expect(restored.economy.balance, 123);
    final reopened = GameSession(catalog, MemoryStore())
      ..restore(restored.snapshot());
    expect(reopened.board!.settings.balanceVersion, 1);
    expect(reopened.board!.settings['production_duration'], 70);
    reopened.finishDay();
    reopened.startDay();
    expect(reopened.cycle!.remaining, 26);
    expect(
      reopened.board!.settings['spawn_interval'],
      closeTo(1 / 1.875, 1e-9),
    );
    expect(reopened.board!.settings.balanceVersion, 8);
    expect(reopened.economy.balance, 123);
    expect(reopened.levels, session.levels);
  });

  test('saved balance 2 keeps its cadence until the next day', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    final json = jsonDecode(session.snapshot()) as Map<String, dynamic>;
    json['run']['board'].remove('specials');
    json['run']['board'].remove('captureAllIds');
    json['run']['balanceVersion'] = 2;
    json['run']['settings'] = catalog.settings({}, balanceVersion: 2).toJson();
    json['run']['remaining'] = 15;
    final restored = GameSession(catalog, MemoryStore())
      ..restore(jsonEncode(json));
    expect(restored.paused, isTrue);
    expect(restored.board!.settings['spawn_interval'], 3);
    final reloaded = GameSession(catalog, MemoryStore())
      ..restore(restored.snapshot());
    expect(reloaded.board!.settings.balanceVersion, 2);
    reloaded.finishDay();
    reloaded.startDay();
    expect(1 / reloaded.board!.settings['spawn_interval'], closeTo(1.5, 1e-9));
    expect(reloaded.board!.settings.balanceVersion, 8);
  });

  test('saved balance 6 keeps the old 10 plus 3 second day', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    final json = jsonDecode(session.snapshot()) as Map<String, dynamic>;
    json['run']['board'].remove('specials');
    json['run']['board'].remove('captureAllIds');
    json['run']['balanceVersion'] = 6;
    json['run']['settings'] = catalog.settings({}, balanceVersion: 6).toJson();
    json['run']['remaining'] = 13;
    final restored = GameSession(catalog, MemoryStore())
      ..restore(jsonEncode(json));
    expect(restored.board!.settings['production_duration'], 10);
    expect(restored.board!.settings['closing_duration'], 3);
    expect(restored.cycle!.remaining, 13);
    restored.finishDay();
    restored.startDay();
    expect(restored.board!.settings.balanceVersion, 8);
    expect(restored.cycle!.remaining, 20);
  });

  test(
    'unknown balance and unpurchased configuration are rejected atomically',
    () {
      final session = GameSession(catalog, MemoryStore())..startDay();
      final data = jsonDecode(session.snapshot()) as Map<String, dynamic>;
      data['run']['balanceVersion'] = 999;
      expect(() => session.restore(jsonEncode(data)), throwsFormatException);
      data['run']['balanceVersion'] = 2;
      data['run']['settings']['production_duration'] = 75;
      expect(() => session.restore(jsonEncode(data)), throwsFormatException);
      expect(session.cycle!.remaining, 20);
    },
  );
}
