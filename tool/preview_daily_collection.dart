import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import '../test/test_support.dart';

void main() {
  testWidgets('preview actual gameplay daily collection', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
    await tester.runAsync(() async {
      final icons = File(
        '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) {
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(icons.readAsBytesSync())),
            ))
            .load();
      }
      if (font.existsSync()) {
        final loader = FontLoader('Preview')
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
        await loader.load();
      }
    });
    final s = GameSession(testCatalog(automaticSpawns: false), MemoryStore())
      ..economy.balance = 9876
      ..startDay();
    final b = s.board!;
    for (var i = 0; i < 70; i++) {
      b.balls.add(
        Ball(b.nextId++, b.holePosition, Vec.zero, golden: i % 10 == 0),
      );
    }
    for (var frame = 0; frame < 330; frame++) {
      s.tick(1 / 60);
    }
    for (var i = 0; i < 30; i++) {
      b.balls.add(
        Ball(
          b.nextId++,
          Vec(40 + (i % 6) * 50.0, 200 + (i ~/ 6) * 40.0),
          Vec.zero,
          golden: i % 10 == 0,
        ),
      );
    }
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Builder(
          builder: (context) {
            final app = GardenApp(session: s).build(context) as MaterialApp;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: app.theme!.copyWith(
                textTheme: app.theme!.textTheme.apply(fontFamily: 'Preview'),
              ),
              home: app.home,
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '/tmp/aj009-gameplay.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    expect(find.byKey(const ValueKey('gameplay-balance')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await s.pendingWrites;
    s.dispose();
  });
}
