import 'dart:convert';
import 'dart:ui' as ui;
import 'package:incremental_hole_game/features/feedback/platform/absorption_painter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/feedback/domain/absorption_effects.dart';
import 'package:incremental_hole_game/features/feedback/domain/feedback_controller.dart';
import '../test_support.dart';

void main() {
  void advance(FeedbackController fx, double seconds) {
    for (var i = 0; i < (seconds * 100).round(); i++) {
      fx.advance(.01);
    }
  }

  test('isolated captures sound once, cycle six variants and bound pitch', () {
    final backend = RecordingFeedbackBackend();
    final fx = FeedbackController(backend: backend)..setPlaying(true);
    for (var i = 0; i < 12; i++) {
      fx.emit(FeedbackEvent.capture);
      advance(fx, .4);
    }
    expect(backend.played.where((c) => c.sample.startsWith('plop')).length, 12);
    expect(backend.played.map((c) => c.sample).toSet().length, 6);
    expect(
      backend.played.every((c) => c.rate >= .955 && c.rate <= 1.045),
      isTrue,
    );
    fx.dispose();
  });
  test(
    '100 simultaneous and continuous captures use a shared smooth layer and bounded voices/haptics',
    () {
      final b = RecordingFeedbackBackend();
      final fx = FeedbackController(backend: b)..setPlaying(true);
      fx.emit(FeedbackEvent.capture, count: 100);
      advance(fx, .1);
      expect(b.played.length, 1);
      expect(b.absorb, greaterThan(0));
      expect(b.pulses.length, 1);
      for (var i = 0; i < 1500; i++) {
        fx.emit(FeedbackEvent.capture, count: 10);
        fx.advance(.01);
        expect(fx.activeVoices, lessThanOrEqualTo(8));
      }
      expect(fx.peakVoices, lessThanOrEqualTo(8));
      expect(b.played.length, lessThan(160));
      expect(b.pulses.length, lessThan(70));
      advance(fx, 8);
      expect(b.absorb, 0);
      expect(fx.activeVoices, 0);
      fx.dispose();
    },
  );
  test(
    'coin packets generate controlled ascending cascades, not a sound per unit',
    () {
      final b = RecordingFeedbackBackend();
      final fx = FeedbackController(backend: b)..setPlaying(true);
      for (var i = 0; i < 20; i++) {
        fx.emit(FeedbackEvent.coinIn, count: 500);
        fx.advance(.05);
      }
      final notes = b.played.where((c) => c.sample.startsWith('coin')).toList();
      expect(notes.length, lessThanOrEqualTo(10));
      expect(notes.map((n) => n.sample).toSet().length, 5);
      expect(b.pulses.length, lessThanOrEqualTo(4));
      expect(fx.peakVoices, lessThanOrEqualTo(8));
      fx.dispose();
    },
  );
  test(
    'stars win simultaneous haptic priority; high priority audio preempts low priority voices',
    () {
      final b = RecordingFeedbackBackend();
      final fx = FeedbackController(backend: b)..setPlaying(true);
      for (final e in [
        FeedbackEvent.collision,
        FeedbackEvent.coinOut,
        FeedbackEvent.launcher,
        FeedbackEvent.crystal,
        FeedbackEvent.bat,
        FeedbackEvent.capture,
      ]) {
        fx.emit(e);
      }
      fx.advance(.05);
      fx.emit(FeedbackEvent.coinIn, count: 100);
      fx.emit(FeedbackEvent.star, count: 3);
      fx.advance(.05);
      expect(b.played.any((c) => c.sample == 'star'), isTrue);
      expect(b.stopped, isNotEmpty);
      final other = RecordingFeedbackBackend();
      final g = FeedbackController(backend: other)..setPlaying(true);
      g.emit(FeedbackEvent.coinIn, count: 20);
      g.emit(FeedbackEvent.star);
      g.advance(.05);
      expect(other.pulses, ['reward']);
      fx.dispose();
      g.dispose();
    },
  );
  test(
    'mute, zero volume, disabled and unsupported haptics remain independent',
    () {
      for (final sound in [false, true]) {
        final b = RecordingFeedbackBackend();
        final fx = FeedbackController(backend: b)..setPlaying(true);
        fx.preferences(sound: sound, haptics: !sound, volume: .8);
        fx.emit(FeedbackEvent.capture);
        fx.advance(.05);
        expect(b.played.isNotEmpty, sound);
        expect(b.pulses.isNotEmpty, !sound);
        fx.dispose();
      }
      final b = RecordingFeedbackBackend(hasHaptics: false);
      final f = FeedbackController(backend: b)..setPlaying(true);
      f.preferences(sound: true, haptics: true, volume: 0);
      f.emit(FeedbackEvent.capture);
      f.advance(.05);
      expect(b.played, isEmpty);
      expect(b.pulses, isEmpty);
      f.dispose();
    },
  );
  test(
    'pausing/background immediately stop loops and never replay queued events',
    () {
      final b = RecordingFeedbackBackend();
      final fx = FeedbackController(backend: b)..setPlaying(true);
      fx.emit(FeedbackEvent.capture, count: 100);
      advance(fx, .2);
      expect(b.absorb, greaterThan(0));
      fx.setPlaying(false);
      expect(b.absorb, 0);
      final count = b.played.length;
      fx.emit(FeedbackEvent.capture, count: 100);
      advance(fx, 1);
      expect(b.played.length, count);
      fx.setPlaying(true);
      fx.emit(FeedbackEvent.capture);
      fx.setBackground(true);
      fx.advance(10);
      fx.setBackground(false);
      advance(fx, .2);
      expect(b.played.length, count);
      fx.dispose();
    },
  );
  test(
    '100 confirmed captures each have a sink actor without physical/economic duplication',
    () async {
      final backend = RecordingFeedbackBackend();
      final fx = FeedbackController(backend: backend);
      final s = GameSession(
        testCatalog(automaticSpawns: false),
        MemoryStore(),
        feedback: fx,
      )..startDay();
      for (var i = 0; i < 100; i++) {
        final b = s.board!;
        b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero, golden: i < 2));
      }
      s.tick(1 / 60);
      expect(s.board!.balls, isEmpty);
      expect(s.board!.captured, 100);
      expect(s.board!.absorption.active, 100);
      expect(s.board!.absorption.recycled, 0);
      expect(s.economy.generated, 118);
      fx.advance(.05);
      expect(
        backend.played.where((c) => c.sample.startsWith('plop')).length,
        1,
      );
      s.pause();
      final age = s.board!.absorption.balls.first.age;
      s.tick(.1);
      expect(s.board!.absorption.balls.first.age, age);
      final restored = GameSession(
        s.catalog,
        MemoryStore(),
        feedback: FeedbackController(backend: RecordingFeedbackBackend()),
      )..restore(s.snapshot());
      expect(restored.board!.absorption.active, 0);
      expect(restored.economy.collected, 118);
      restored.finishDay();
      expect(restored.economy.balance, 118);
      s.resume();
      for (var i = 0; i < 30; i++) {
        s.tick(1 / 60);
      }
      expect(s.board!.absorption.active, 0);
      s.finishDay();
      expect(s.economy.balance, 118);
      await s.pendingWrites;
      await restored.pendingWrites;
      s.dispose();
      restored.dispose();
    },
  );
  test('AJ-005B quota feedback counts balls and never replays on restore', () {
    final backend = RecordingFeedbackBackend();
    final fx = FeedbackController(backend: backend);
    final s = GameSession(
      testCatalog(automaticSpawns: false),
      MemoryStore(),
      feedback: fx,
    )..startDay();
    void capture(int count, {bool golden = false}) {
      final b = s.board!;
      for (var i = 0; i < count; i++) {
        b.balls.add(Ball(b.nextId++, b.holePosition, Vec.zero, golden: golden));
      }
      s.tick(1 / 60);
      fx.advance(.2);
    }

    capture(99, golden: true);
    expect(backend.played.where((c) => c.sample == 'quota'), isEmpty);
    capture(1);
    expect(s.feeding.period, 2);
    expect(backend.played.where((c) => c.sample == 'quota'), hasLength(1));
    s.restore(s.snapshot());
    s.resume();
    s.tick(.1);
    fx.advance(.2);
    expect(backend.played.where((c) => c.sample == 'quota'), hasLength(1));
    s.dispose();
  });

  test(
    'contact audio ignores persistent resting contacts and physics remains bounded',
    () {
      final b = Board(testCatalog().settings({}));
      final ball = Ball(1, const Vec(6, 300), Vec.zero);
      b.balls.add(ball);
      for (var i = 0; i < 100; i++) {
        b.update(1 / 60, producing: true);
      }
      expect(b.contactSerial, 0);
      ball.position = const Vec(7, 300);
      ball.velocity = const Vec(-300, 0);
      b.update(1 / 60, producing: true);
      expect(b.contactSerial, 1);
      final serial = b.contactSerial;
      ball.velocity = Vec.zero;
      for (var i = 0; i < 50; i++) {
        b.update(1 / 60, producing: true);
      }
      expect(b.contactSerial, serial);
    },
  );
  test(
    'volume and haptic preferences migrate, persist and keep the last nonmuted volume',
    () async {
      final s = GameSession(
        testCatalog(),
        MemoryStore(),
        feedback: FeedbackController(backend: RecordingFeedbackBackend()),
      );
      s.setEffectsVolume(.37);
      s.setSound(false);
      s.setHaptics(false);
      final r = GameSession(
        s.catalog,
        MemoryStore(),
        feedback: FeedbackController(backend: RecordingFeedbackBackend()),
      )..restore(s.snapshot());
      expect(r.effectsVolume, .37);
      expect(r.sound, isFalse);
      expect(r.haptics, isFalse);
      r.setSound(true);
      expect(r.effectsVolume, .37);
      final old = jsonDecode(s.snapshot()) as Map<String, dynamic>;
      old.remove('effectsVolume');
      r.restore(jsonEncode(old));
      expect(r.effectsVolume, .8);
      final bad = {...old, 'effectsVolume': 2};
      expect(() => r.restore(jsonEncode(bad)), throwsFormatException);
      await s.pendingWrites;
      await r.pendingWrites;
      s.dispose();
      r.dispose();
    },
  );
  test(
    'only successful real purchases emit feedback and rejected purchases are silent',
    () async {
      final b = RecordingFeedbackBackend();
      final fx = FeedbackController(backend: b);
      final s = GameSession(testCatalog(), MemoryStore(), feedback: fx)
        ..economy.balance = 100;
      // Fixture after the mandatory opening jornada (P02).
      prepareNormalShop(s);
      final d = s.catalog.definitions.firstWhere((d) => d.id == 'hand');
      expect(s.purchase(d), isTrue);
      fx.advance(.05);
      expect(b.played.where((c) => c.sample == 'upgrade').length, 1);
      s.economy.balance = 0;
      expect(s.purchase(d), isFalse);
      advance(fx, .5);
      expect(b.played.where((c) => c.sample == 'upgrade').length, 1);
      await s.pendingWrites;
      s.dispose();
    },
  );
  test(
    'sink pool is reused and transient ripples never change capture geometry',
    () {
      final v = AbsorptionEffects();
      final first = v.balls.first;
      for (var i = 0; i < 100; i++) {
        v.capture(i, const Vec(180, 123.2), const Vec(50, 30), 6, i.isEven);
      }
      expect(v.active, 100);
      expect(v.ripple, 1);
      v.advance(.3);
      expect(v.active, 0);
      v.capture(101, const Vec(10, 10), Vec.zero, 6, false);
      expect(v.balls.first, same(first));
      final board = Board(testCatalog().settings({}));
      final r = board.captureRadius;
      board.absorption.capture(1, board.holePosition, Vec.zero, 6, true);
      expect(board.captureRadius, r);
    },
  );
  test(
    'generated offline bank has six plops, all WAVs and bounded PCM peaks',
    () {
      final manifest =
          jsonDecode(File('assets/audio/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(manifest.keys.where((k) => k.startsWith('plop')).length, 6);
      for (final e in manifest.entries) {
        final bytes = File(e.value['file'] as String).readAsBytesSync();
        final data = ByteData.sublistView(bytes);
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
        expect(data.getUint16(22, Endian.little), 1);
        var maximum = 0;
        for (var i = 44; i + 1 < bytes.length; i += 2) {
          final n = data.getInt16(i, Endian.little).abs();
          if (n > maximum) maximum = n;
        }
        expect(maximum, lessThanOrEqualTo(20317));
      }
      expect(
        File('assets/audio/LICENSE.md').readAsStringSync(),
        contains('CC0'),
      );
    },
  );
  testWidgets('settings expose volume without coupling it to mute or haptics', (
    tester,
  ) async {
    final s = GameSession(
      testCatalog(),
      MemoryStore(),
      feedback: FeedbackController(backend: RecordingFeedbackBackend()),
    );
    await tester.pumpWidget(GardenApp(session: s));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('effects-volume')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('effects-volume')), findsOneWidget);
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('effects-volume')),
    );
    slider.onChanged!(.4);
    await tester.pump();
    expect(s.effectsVolume, .4);
    expect(s.haptics, isTrue);
    await tester.pumpWidget(const SizedBox());
    await s.pendingWrites;
    s.dispose();
  });
  test('mixed voices stay under headroom with simultaneous rewards', () {
    final b = RecordingFeedbackBackend(), active = <int, (double, double)>{};
    final fx = FeedbackController(backend: b)..setPlaying(true);
    var played = 0, stopped = 0;
    for (var n = 0; n < 300; n++) {
      for (final e in FeedbackEvent.values) {
        fx.emit(e, count: 100);
      }
      fx.motion(.9);
      fx.advance(.01);
      active.removeWhere((key, v) => v.$2 <= fx.clock);
      for (final token in b.stopped.skip(stopped)) {
        active.remove(token);
      }
      stopped = b.stopped.length;
      for (final cue in b.played.skip(played)) {
        active[cue.token] = (cue.gain, fx.clock + cue.duration);
      }
      played = b.played.length;
      final gain = active.values.fold<double>(0, (sum, v) => sum + v.$1);
      expect(gain, lessThanOrEqualTo(.85 * .8 + 1e-8));
      expect((gain + b.absorb + b.rolling) * .62, lessThan(1));
      expect(fx.activeVoices, lessThanOrEqualTo(8));
    }
    fx.dispose();
  });
  test('shared rolling fades to silence when physical movement stops', () {
    final b = RecordingFeedbackBackend();
    final fx = FeedbackController(backend: b)
      ..setPlaying(true)
      ..motion(.8);
    advance(fx, 1);
    expect(b.rolling, greaterThan(0));
    fx.motion(0);
    advance(fx, 4);
    expect(b.rolling, 0);
    expect(fx.needsFrames, isFalse);
    fx.dispose();
  });
  test('front rim masks late sinking balls at different hole sizes', () async {
    for (final radius in [64.0, 100.0]) {
      final effects = AbsorptionEffects()
        ..capture(1, const Vec(128, 110), Vec.zero, 8, true);
      effects.balls.first.age = .239;
      effects.ripple = 0;
      final recorder = ui.PictureRecorder();
      paintAbsorption(
        Canvas(recorder),
        effects,
        const Vec(128, 110),
        radius,
        Paint(),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(256, 256);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final y = (110 + radius * 1.2).floor();
      expect(bytes.getUint8((y * 256 + 128) * 4 + 3), 0);
      image.dispose();
      picture.dispose();
    }
  });
  test(
    'DEBUG audiovisual changes never replace the real preferences',
    () async {
      final s = GameSession(
        testCatalog(),
        MemoryStore(),
        feedback: FeedbackController(backend: RecordingFeedbackBackend()),
      );
      final baseline = s.snapshot();
      s.enterDebug();
      s.debugSetFeedbackParameter('sinkDuration', .4);
      s.debugSetFeedbackParameter('maxVoices', 4);
      expect(s.feedback.config['sinkDuration'], .4);
      s.debugPreviewFeedback(FeedbackEvent.star);
      s.feedback.advance(.05);
      s.exitDebug();
      expect(s.snapshot(), baseline);
      expect(s.feedback.config['sinkDuration'], .24);
      await s.pendingWrites;
      s.dispose();
    },
  );
  test('confirmed UI rewards wake an idle feedback ticker once per event', () {
    final fx = FeedbackController(backend: RecordingFeedbackBackend());
    var wakes = 0;
    fx.onActivity = () => wakes++;
    fx.emit(FeedbackEvent.upgrade, gameplay: false);
    expect(wakes, 1);
    expect(fx.needsFrames, isTrue);
    advance(fx, 2);
    expect(fx.needsFrames, isFalse);
    fx.setBackground(true);
    fx.emit(FeedbackEvent.coinIn, gameplay: false);
    expect(wakes, 1);
    fx.dispose();
  });
  test(
    'isolated coins reuse a short cascade without advancing the existing mass melody',
    () {
      final b = RecordingFeedbackBackend();
      final fx = FeedbackController(backend: b)..setPlaying(true);
      fx.emit(FeedbackEvent.coinIn);
      advance(fx, .5);
      expect(b.played.single.sample, 'coincascade');
      expect(b.played.single.rate, 1);
      fx.emit(FeedbackEvent.coinIn, count: 100);
      advance(fx, .5);
      expect(b.played.last.sample, 'coin0');
      fx.emit(FeedbackEvent.coinIn);
      advance(fx, .5);
      fx.emit(FeedbackEvent.coinIn, count: 100);
      advance(fx, .5);
      expect(b.played.last.sample, 'coin1');
      fx.dispose();
    },
  );
}
