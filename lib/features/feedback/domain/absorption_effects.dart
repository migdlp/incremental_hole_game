import '../../../core/vec.dart';
import 'feedback_config.dart';

class SinkingBall {
  bool active = false, golden = false;
  int id = 0;
  double x = 0, y = 0, vx = 0, vy = 0, radius = 6, age = 0;
  void reset(int id, Vec p, Vec v, double size, bool gold) {
    active = true;
    this.id = id;
    x = p.x;
    y = p.y;
    vx = v.x;
    vy = v.y;
    radius = size;
    golden = gold;
    age = 0;
  }
}

/// Presentation only. Captured balls have already left collision/economic state.
class AbsorptionEffects {
  AbsorptionEffects({this.config = const FeedbackConfig()})
    : balls = List.generate(
        config['sinkCapacity'].toInt(),
        (_) => SinkingBall(),
      );
  final FeedbackConfig config;
  final List<SinkingBall> balls;
  int active = 0, peak = 0, recycled = 0, _cursor = 0;
  double ripple = 0;
  void capture(int id, Vec position, Vec velocity, double radius, bool golden) {
    for (var i = 0; i < balls.length; i++) {
      final index = (_cursor + i) % balls.length, b = balls[index];
      if (b.active) continue;
      b.reset(id, position, velocity, radius, golden);
      _cursor = (index + 1) % balls.length;
      active++;
      if (active > peak) peak = active;
      ripple = (ripple + .18).clamp(0, 1);
      return;
    }
    // Safety for impossible/custom DEBUG bursts; never create unbounded bodies.
    balls[_cursor].reset(id, position, velocity, radius, golden);
    _cursor = (_cursor + 1) % balls.length;
    recycled++;
  }

  void advance(double dt) {
    ripple = (ripple - dt * 4).clamp(0, 1);
    if (active == 0) return;
    for (final b in balls) {
      if (!b.active) continue;
      b.age += dt;
      if (b.age >= config['sinkDuration']) {
        b.active = false;
        active--;
      }
    }
  }

  void clear() {
    for (final b in balls) {
      b.active = false;
    }
    active = 0;
    ripple = 0;
  }
}
