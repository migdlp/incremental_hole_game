import 'dart:convert';
import 'dart:io';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/feedback/domain/feedback_controller.dart';
import 'package:incremental_hole_game/features/feedback/domain/absorption_effects.dart';

class Probe implements FeedbackBackend {
  @override
  String get status => 'CPU benchmark; no native playback';
  @override
  Future<FeedbackBank?> prepare() async => null;
  @override
  void frame(
    List<SoundCue> play,
    List<int> stop,
    double absorb,
    double rolling,
    String? haptic,
  ) {}
  @override
  void stop() {}
  @override
  void dispose() {}
}

void main() {
  final rows = <Map<String, Object>>[];
  for (final count in [1, 10, 50, 100]) {
    for (final continuous in [false, true]) {
      final times = <int>[];
      final f = FeedbackController(backend: Probe())..setPlaying(true);
      final sink = AbsorptionEffects();
      var id = 0;
      for (var frame = 0; frame < 900; frame++) {
        final w = Stopwatch()..start();
        if (frame == 0 || (continuous && frame % 12 == 0)) {
          f.emit(FeedbackEvent.capture, count: count);
          f.emit(FeedbackEvent.coinOut, count: count * 7);
          f.emit(FeedbackEvent.coinIn, count: count * 7);
          for (var n = 0; n < count; n++) {
            sink.capture(++id, Vec(180, 125), Vec(0, 80), 6, n % 10 == 0);
          }
        }
        f.motion(continuous ? .5 : 0);
        sink.advance(1 / 60);
        f.advance(1 / 60);
        w.stop();
        times.add(w.elapsedMicroseconds);
      }
      times.sort();
      rows.add({
        'captures_per_burst': count,
        'continuous_15_seconds': continuous,
        'cpu_p95_us': times[(times.length * .95).floor()],
        'cpu_p99_us': times[(times.length * .99).floor()],
        'cpu_max_us': times.last,
        'requested_voice_peak': f.peakVoices,
        'haptic_requests': f.hapticPulses,
        'sink_peak': sink.peak,
        'sink_recycled': sink.recycled,
        'rss_bytes': ProcessInfo.currentRss,
      });
    }
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'scope':
          'Cloud AOT CPU: central mixer plus nonphysical sink pool. '
          'No native audio, hardware GPU, Android latency or physical haptics.',
      'scenarios': rows,
    }),
  );
}
