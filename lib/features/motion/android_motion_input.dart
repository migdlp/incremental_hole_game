import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/vec.dart';
import 'motion_input.dart';

class AndroidMotionInput implements MotionInput {
  AndroidMotionInput({bool? androidSupported, Stream<dynamic>? samples})
    : _samples = samples,
      _androidSupported =
          androidSupported ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  static const control = MethodChannel('feed_the_hole/motion');
  static const events = EventChannel('feed_the_hole/motion/events');
  final bool _androidSupported;
  final Stream<dynamic>? _samples;
  int _epoch = 0;
  bool _available = false, _disposed = false, _active = false;
  Vec _tilt = Vec.zero;
  StreamSubscription<dynamic>? _subscription;
  Timer? _stale;
  @override
  bool get available => _available;
  @override
  Vec get tilt => _active && _available ? _tilt : Vec.zero;

  Future<void> initialize() async {
    if (!_androidSupported || _disposed) return;
    try {
      final result = await control
          .invokeMapMethod<String, dynamic>('probe')
          .timeout(const Duration(seconds: 3));
      if (!_disposed) _available = result?['available'] == true;
    } on Object {
      _available = false;
    }
  }

  /// Android gravity/accelerometer axes are tied to the natural device display.
  /// Project to the current portrait display, then reverse proper acceleration.
  static Vec? decode(dynamic sample) {
    if (sample is! Map || sample['available'] != true) return null;
    final x = sample['x'], y = sample['y'], z = sample['z'];
    final rotation = sample['rotation'];
    if (x is! num ||
        y is! num ||
        z is! num ||
        !x.isFinite ||
        !y.isFinite ||
        !z.isFinite ||
        rotation is! int ||
        rotation < 0 ||
        rotation > 3) {
      return null;
    }
    final norm = x * x + y * y + z * z;
    if (norm < 1 || norm > 900) return null;
    final (horizontal, vertical) = switch (rotation) {
      0 => (x, y),
      1 => (-y, x),
      2 => (-x, -y),
      _ => (y, -x),
    };
    return Vec(-horizontal / 9.80665, vertical / 9.80665).limit(1);
  }

  void _lost() {
    _available = false;
    _tilt = Vec.zero;
  }

  void _watchFreshness(Duration timeout) {
    _stale?.cancel();
    _stale = Timer(timeout, _lost);
  }

  @override
  void setActive(bool active) {
    if (_disposed || !_androidSupported || active == _active) return;
    final epoch = ++_epoch;
    _active = active;
    _tilt = Vec.zero;
    if (!active) {
      _stale?.cancel();
      final subscription = _subscription;
      _subscription = null;
      if (subscription != null) unawaited(subscription.cancel());
      return;
    }
    _watchFreshness(const Duration(milliseconds: 1500));
    _subscription = (_samples ?? events.receiveBroadcastStream()).listen(
      (dynamic sample) {
        if (!_active || _disposed || epoch != _epoch) return;
        final value = decode(sample);
        if (value == null) {
          _lost();
        } else {
          _available = true;
          _tilt = value;
          _watchFreshness(const Duration(seconds: 1));
        }
      },
      onError: (Object error) {
        if (epoch == _epoch) _lost();
      },
      onDone: () {
        if (epoch == _epoch) _lost();
      },
    );
  }

  @override
  void dispose() {
    setActive(false);
    _disposed = true;
    _stale?.cancel();
    _lost();
  }
}
