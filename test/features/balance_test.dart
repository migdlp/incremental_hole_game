import 'dart:convert';
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
  test('initial day lasts 15 seconds including five for collection', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    expect(session.cycle!.remaining, 15);
    advance(session, 600);
    expect(session.phase, DayPhase.closing);
    expect(session.cycle!.remaining, closeTo(5, .001));
    expect(session.board!.balls.length, 3);
    advance(session, 299);
    expect(session.running, isTrue);
    expect(session.board!.balls.length, 3); // no production during closing
    advance(session, 1);
    expect(session.running, isFalse);
  });

  test('generation is four times slower across all upgrade levels', () {
    for (var level = 0; level <= 3; level++) {
      final levels = {'generator': level};
      final old = catalog.settings(levels, balanceVersion: 1);
      final current = catalog.settings(levels);
      expect(
        current['spawn_interval'],
        closeTo(old['spawn_interval'] * 4, 1e-9),
      );
      expect(current['production_duration'], 10);
    }
    for (var level = 1; level <= 3; level++) {
      expect(
        catalog.settings({
          'generator': 1,
          'duration': level,
        })['production_duration'],
        10 + level * 5,
      );
    }
  });

  test('first ball waits three seconds, then generation continues slowly', () {
    final session = GameSession(catalog, MemoryStore())..startDay();
    advance(session, 179);
    expect(session.board!.balls, isEmpty);
    advance(session, 2);
    expect(session.board!.balls.length, 1);
    advance(session, 180);
    expect(session.board!.balls.length, 2);
  });

  test('old v2 run survives reload until next day adopts the new balance', () {
    final session = GameSession(catalog, MemoryStore());
    session.levels.addAll({'generator': 1, 'duration': 2});
    session.economy.balance = 123;
    session.startDay();
    final data = jsonDecode(session.snapshot()) as Map<String, dynamic>;
    data['version'] = 2;
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
    expect(reopened.cycle!.remaining, 25);
    expect(reopened.board!.settings['spawn_interval'], 2.6);
    expect(reopened.board!.settings.balanceVersion, 2);
    expect(reopened.economy.balance, 123);
    expect(reopened.levels, session.levels);
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
      expect(session.cycle!.remaining, 15);
    },
  );
}
