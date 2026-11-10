import 'dart:math' as math;

enum WallSide { left, right, top, bottom }

/// Bounded, transient visual information. Never used for collision geometry.
class WallImpact {
  WallImpact(this.wall, this.coordinate, this.intensity);
  static const lifetime = .45;
  final WallSide wall;
  final double coordinate, intensity;
  double age = 0;

  double displacementAt(double point) {
    final distance = (point - coordinate).abs();
    final dent = math.exp(-distance * distance / 180) * math.exp(-age * 14);
    final waveDistance = (distance - age * 220) / 12;
    final wave =
        math.exp(-waveDistance * waveDistance) *
        math.sin(age * 36 - distance * .07) *
        (1 - age / lifetime);
    return intensity * 9 * (dent + .7 * wave);
  }
}
