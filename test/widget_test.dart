import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'test_support.dart';

void main() {
  testWidgets(
    'night shows actual balance, progression, and starts a playable day',
    (tester) async {
      final session = GameSession(testCatalog(), MemoryStore());
      await tester.pumpWidget(GardenApp(session: session));
      expect(find.text('JARDÍN MECÁNICO'), findsOneWidget);
      expect(find.text('Comenzar día 1'), findsOneWidget);
      await tester.tap(find.text('Comenzar día 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(session.running, isTrue);
      expect(find.byTooltip('Pausar'), findsOneWidget);
      await tester.tap(find.byTooltip('Pausar'));
      await tester.pump();
      expect(find.text('Un pequeño descanso'), findsOneWidget);
      final remaining = session.cycle!.remaining;
      await tester.pump(const Duration(seconds: 2));
      expect(session.cycle!.remaining, remaining);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(session.paused, isFalse);
      session.finishDay();
      await tester.pump();
      expect(find.text('Comenzar día 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );
}
