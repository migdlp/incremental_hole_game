import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/features/board/presentation/coin_painter.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_delivery.dart';

// Diagnostic snapshots of the actual coin painter and emitter, not an Android screenshot.
void main() {
  testWidgets('render sequential emitter diagnostic snapshots', (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder), brush = Paint();
      var column = 0;
      for (final scenario in [(4, 45), (50000, 75), (250000, 120)]) {
        final v = RewardVisuals(192, .2, seed: 2026)
          ..geometry(180, 123.2, 36)
          ..add(1, scenario.$1);
        for (var i = 0; i < scenario.$2; i++) {
          v.advance(1 / 60);
        }
        canvas.save();
        canvas.translate(column++ * 360.0, 0);
        canvas.clipRect(const Rect.fromLTWH(0, 0, 360, 560));
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 360, 560),
          brush..color = const Color(0xff23334b),
        );
        canvas.drawCircle(
          const Offset(180, 123.2),
          39,
          brush..color = const Color(0xff697583),
        );
        canvas.drawCircle(
          const Offset(180, 123.2),
          36,
          brush..color = const Color(0xff080e18),
        );
        for (final c in v.coins.where((c) => c.active)) {
          paintCoin(
            canvas,
            Offset(c.x(320, .2, origin: 180), c.y(28, .2, origin: 123.2)),
            c.denomination,
            radius: 7,
            paint: brush,
          );
        }
        final text = TextPainter(
          text: TextSpan(
            text:
                '${v.emittedObjects} / ${v.counts.values.fold<int>(0, (s, n) => s + n)}',
            style: const TextStyle(color: Color(0xfff8f3e8), fontSize: 16),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, const Offset(16, 510));
        canvas.restore();
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(1080, 560);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '/tmp/bug002-preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    });
  });
}
