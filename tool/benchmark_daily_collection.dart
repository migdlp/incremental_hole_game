import 'dart:convert';
import 'dart:io';
import 'package:incremental_hole_game/features/board/domain/coin_denomination.dart';
import 'package:incremental_hole_game/features/rewards/domain/daily_coin_collection.dart';

void main() {
  final reports = <Map<String, Object>>[];
  for (final count in [10, 100, 500, 2000]) {
    final c = DailyCoinCollection()..begin('1:1');
    final creation = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      c.reserve(CoinDenomination.values[i % 5], 1);
    }
    c.resolve();
    creation.stop();
    final samples = <int>[];
    var bytes = 0;
    for (var i = -10; i < 500; i++) {
      final w = Stopwatch()..start();
      final encoded = jsonEncode(c.toJson());
      w.stop();
      bytes = encoded.length;
      if (i >= 0) samples.add(w.elapsedMicroseconds);
    }
    samples.sort();
    reports.add({
      'coins': count,
      'reserve_and_place_us': creation.elapsedMicroseconds,
      'serialize_p95_us': samples[(samples.length * .95).floor()],
      'serialize_p99_us': samples[(samples.length * .99).floor()],
      'serialize_max_us': samples.last,
      'json_bytes': bytes,
      'process_rss_bytes': ProcessInfo.currentRss,
    });
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'scope':
          'Cloud AOT collection and JSON serialization; no Android CPU/GPU or displayed FPS.',
      'reports': reports,
    }),
  );
}
