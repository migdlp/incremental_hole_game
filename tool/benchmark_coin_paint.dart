import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/features/board/domain/coin_denomination.dart';
import 'package:incremental_hole_game/features/board/presentation/coin_painter.dart';
import 'package:incremental_hole_game/features/rewards/domain/reward_delivery.dart';

// Opt-in Cloud offscreen benchmark, not an Android GPU/FPS certification.
void main() {
  testWidgets('measure pooled coin drawing at several simultaneous counts', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final reports = <Map<String, Object>>[];
      for (final count in [1, 10, 24, 50, 100, 128, 192, 256, 512]) {
        final coins = List.generate(count, (i) {
          final c = RewardCoin()
            ..reset(i + 1, CoinDenomination.values[i % 5].amount);
          c.age = .2 + c.jump + c.hold + c.flight * (.1 + i % 8 * .1);
          return c;
        });
        final recording = <int>[], raster = <int>[];
        final rss = ProcessInfo.currentRss;
        final brush = Paint();
        for (var frame = -10; frame < 100; frame++) {
          final watch = Stopwatch()..start();
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawRect(
            const Rect.fromLTWH(0, 0, 360, 560),
            brush..color = const Color(0xff23334b),
          );
          for (final c in coins) {
            paintCoin(
              canvas,
              Offset(c.x(310, .2), c.y(28, .2, origin: 123.2)),
              c.denomination,
              radius: 7,
              paint: brush,
            );
          }
          final picture = recorder.endRecording();
          watch.stop();
          if (frame >= 0) recording.add(watch.elapsedMicroseconds);
          watch.reset();
          watch.start();
          final image = await picture.toImage(360, 560);
          watch.stop();
          if (frame >= 0) raster.add(watch.elapsedMicroseconds);
          image.dispose();
          picture.dispose();
        }
        recording.sort();
        raster.sort();
        int p(List<int> values, double percent) =>
            values[((values.length - 1) * percent).round()];
        reports.add({
          'coins': count,
          'samples': 100,
          'record_p95_us': p(recording, .95),
          'record_p99_us': p(recording, .99),
          'record_max_us': recording.last,
          'offscreen_raster_p95_us': p(raster, .95),
          'offscreen_raster_p99_us': p(raster, .99),
          'offscreen_raster_max_us': raster.last,
          'rss_before_bytes': rss,
          'rss_after_bytes': ProcessInfo.currentRss,
          'coin_objects_created': count,
          'coin_objects_recreated_per_frame': 0,
        });
      }
      await File('docs/performance/bug001-offscreen-paint.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'scope':
              'Cloud Flutter test engine, 360x560 offscreen images. Command recording and asynchronous image raster elapsed time; not hardware GPU time, not displayed FPS, not Android.',
          'reference_limit_before': 24,
          'provisional_limit_after': 192,
          'reports': reports,
        }),
      );
    });
  });
}
