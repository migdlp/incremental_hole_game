import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/features/board/domain/coin_denomination.dart';
import 'package:incremental_hole_game/features/rewards/domain/daily_coin_collection.dart';
import 'package:incremental_hole_game/features/rewards/presentation/collection_painter.dart';
import '../test/test_support.dart';

void main() {
  testWidgets('measure cached daily coin collection drawing', (tester) async {
    await tester.runAsync(() async {
      final reports = <Map<String, Object>>[];
      for (final count in [1, 10, 50, 100, 500]) {
        final s = GameSession(
          testCatalog(automaticSpawns: false),
          MemoryStore(),
        )..startDay();
        for (var i = 0; i < count; i++) {
          s.rewardVisuals.collection.reserve(CoinDenomination.values[i % 5], 1);
        }
        s.rewardVisuals.collection.resolve();
        final grid = CollectionGrid(360, 700), cache = CollectionPicture();
        final painter = DailyCollectionPainter(s, grid, 560, cache);
        final record = <int>[], raster = <int>[];
        for (var frame = -5; frame < 60; frame++) {
          final rec = ui.PictureRecorder(), watch = Stopwatch()..start();
          painter.paint(Canvas(rec), Size(360, grid.height + 560));
          final scene = rec.endRecording();
          watch.stop();
          if (frame >= 0) record.add(watch.elapsedMicroseconds);
          watch.reset();
          watch.start();
          final image = await scene.toImage(360, 680);
          watch.stop();
          if (frame >= 0) raster.add(watch.elapsedMicroseconds);
          image.dispose();
          scene.dispose();
        }
        record.sort();
        raster.sort();
        reports.add({
          'coins': count,
          'visible_cells': count < grid.capacity ? count : grid.capacity,
          'static_recordings': cache.recordings,
          'record_p95_us': record[57],
          'record_p99_us': record[59],
          'record_max_us': record.last,
          'offscreen_raster_p95_us': raster[57],
          'offscreen_raster_p99_us': raster[59],
          'offscreen_raster_max_us': raster.last,
          'process_rss_bytes': ProcessInfo.currentRss,
        });
        cache.dispose();
        await s.pendingWrites;
        s.dispose();
      }
      await File('docs/performance/aj009-collection-paint.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'scope':
              'Cloud Flutter test engine. Cached command recording and offscreen image wall time; not Android GPU/FPS.',
          'reports': reports,
        }),
      );
    });
  });
}
