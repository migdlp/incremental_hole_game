import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../domain/feedback_config.dart';
import '../domain/feedback_controller.dart';

class PlatformFeedbackBackend implements FeedbackBackend {
  static const channel = MethodChannel('feed_the_hole/feedback');
  bool _disposed = false, _available = true;
  bool ready = false;
  @override
  String status = "Sin preparar";
  Future<void> _send(String method, [Object? arguments]) async {
    if (_disposed || !_available) return;
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      _available = false;
      /* Unsupported platforms are silent. */
    } on PlatformException {
      /* Device/audio focus failure cannot affect gameplay. */
    } on Object {
      /* No platform binding in pure model tests. */
    }
  }

  @override
  Future<FeedbackBank?> prepare() async {
    if (kIsWeb || !Platform.isAndroid) {
      _available = false;
      status = 'Audio nativo disponible en Android';
      return null;
    }
    try {
      final raw =
          jsonDecode(await rootBundle.loadString('assets/audio/manifest.json'))
              as Map<String, dynamic>;
      final config = FeedbackConfig.fromJson(
        jsonDecode(await rootBundle.loadString('assets/audio/feedback.json'))
            as Map<String, dynamic>,
      );
      if (_disposed) return null;
      final loaded = await channel
          .invokeMapMethod<String, dynamic>('prepare', {
            'samples': raw,
            'maxStreams': 16,
          })
          .timeout(const Duration(seconds: 3));
      _available = true;
      ready = loaded?['loaded'] == raw.length;
      status = ready
          ? 'Recursos precargados'
          : 'Audio no disponible o carga incompleta';
      return FeedbackBank(config, {
        for (final e in raw.entries)
          e.key: (e.value['duration'] as num).toDouble(),
      });
    } on Object {
      _available = false;
      status = 'Audio nativo no disponible en esta plataforma';
      return null;
    }
  }

  @override
  void frame(
    List<SoundCue> play,
    List<int> stop,
    double absorb,
    double rolling,
    String? haptic,
  ) => unawaited(
    _send('frame', {
      'play': play.map((c) => c.toJson()).toList(growable: false),
      'stop': stop,
      'absorb': absorb,
      'rolling': rolling,
      'haptic': haptic,
    }),
  );
  @override
  void stop() => unawaited(_send('stop'));
  @override
  void dispose() {
    if (_disposed) return;
    unawaited(_send('dispose'));
    _disposed = true;
  }
}
