import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/presentation/garden_game.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();

  test(
    'feedback defaults off, persists, and older saves default off',
    () async {
      final session = GameSession(catalog, MemoryStore());
      expect(session.visualFeedback, isFalse);
      session.setVisualFeedback(true);
      final restored = GameSession(catalog, MemoryStore())
        ..restore(session.snapshot());
      expect(restored.visualFeedback, isTrue);
      final legacy = jsonDecode(session.snapshot()) as Map<String, dynamic>;
      legacy.remove('visualFeedback');
      restored.restore(jsonEncode(legacy));
      expect(restored.visualFeedback, isFalse);
      await session.pendingWrites;
      session.dispose();
      restored.dispose();
    },
  );

  test(
    'feedback toggles only touch drawing, preserving board and controls',
    () async {
      final session = GameSession(catalog, MemoryStore())..startDay();
      session.touch(const Vec(120, 240));
      final boardBefore = jsonEncode(session.board!.toJson());
      final game = GardenGame(session)..onGameResize(Vector2(360, 560));
      Future<List<int>> pixels() async {
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(360, 560);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final result = List<int>.of(data.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        return result;
      }

      final off = await pixels();
      session.setVisualFeedback(true);
      final on = await pixels();
      expect(on, isNot(orderedEquals(off)));
      session.setVisualFeedback(false);
      expect(await pixels(), orderedEquals(off));
      expect(jsonEncode(session.board!.toJson()), boardBefore);
      await session.pendingWrites;
      session.dispose();
    },
  );

  testWidgets(
    'pause settings toggle feedback and total balance stays on board',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final session = GameSession(catalog, MemoryStore());
      session.economy.balance = 120;
      session.startDay();
      session.economy.generated = 4;
      session.economy.collected = 4;
      session.pause();
      await tester.pumpWidget(GardenApp(session: session));
      await tester.pump();
      final balance = find.byKey(const ValueKey('gameplay-balance'));
      expect(
        find.descendant(of: balance, matching: find.text('124')),
        findsOneWidget,
      );
      final setting = find.byKey(const ValueKey('visual-feedback-setting'));
      expect(tester.widget<SwitchListTile>(setting).value, isFalse);
      await tester.tap(setting);
      await tester.pump();
      expect(session.visualFeedback, isTrue);
      expect(session.paused, isTrue);
      expect(find.text('Juego pausado'), findsOneWidget);
      expect(find.byIcon(Icons.nights_stay_outlined), findsNothing);
      expect(find.text('El tiempo está detenido.'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );
}
