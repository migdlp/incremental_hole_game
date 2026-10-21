import 'dart:math' as math;
import '../../../core/vec.dart';

/// Rigid translation with one contact, translation and rotation with two.
/// Shared by the broom and bat; contacts never stretch the physical tool.
class TwoPointGrip {
  TwoPointGrip(Vec center, double angle, Vec primary)
    : _offset = center - primary,
      _desiredAngle = angle;
  Vec _offset, _pivotOffset = Vec.zero;
  Vec? second;
  double _referenceAngle = 0, _referenceToolAngle = 0, _desiredAngle;

  void addSecond(Vec point, Vec primary, Vec center, double angle) {
    second = point.inside(0);
    final axis = point - primary;
    _referenceAngle = math.atan2(axis.y, axis.x);
    _referenceToolAngle = angle;
    _pivotOffset = center - (primary + point) * .5;
  }

  void releaseSecond(Vec primary, Vec center, double angle) {
    second = null;
    _offset = center - primary;
    _desiredAngle = angle;
  }

  ({Vec center, double angle, Vec velocity, double angularVelocity}) move(
    Vec primary,
    Vec center,
    double angle,
    double dt, {
    required double margin,
    required double speed,
    required double angularSpeed,
    bool symmetric = false,
  }) {
    var destination = primary + _offset;
    final other = second;
    if (other != null) {
      final axis = other - primary;
      if (axis.length >= 18) {
        _desiredAngle =
            _referenceToolAngle + math.atan2(axis.y, axis.x) - _referenceAngle;
      }
      final turn = _desiredAngle - _referenceToolAngle;
      final c = math.cos(turn), s = math.sin(turn);
      destination =
          (primary + other) * .5 +
          Vec(
            _pivotOffset.x * c - _pivotOffset.y * s,
            _pivotOffset.x * s + _pivotOffset.y * c,
          );
    }
    final next =
        center + (destination.inside(margin) - center).limit(speed * dt);
    var delta = (_desiredAngle - angle + math.pi) % (2 * math.pi) - math.pi;
    if (symmetric) {
      if (delta > math.pi / 2) delta -= math.pi;
      if (delta < -math.pi / 2) delta += math.pi;
    }
    final turn = delta.clamp(-angularSpeed * dt, angularSpeed * dt);
    return (
      center: next,
      angle: (angle + turn) % (2 * math.pi),
      velocity: (next - center) * (1 / dt),
      angularVelocity: turn / dt,
    );
  }
}
