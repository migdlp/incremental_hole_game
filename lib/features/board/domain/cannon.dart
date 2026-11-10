import 'dart:math' as math;
import '../../../core/vec.dart';

class CannonSlot {
  const CannonSlot(this.index, this.position, this.baseAngle);
  final int index; // 1..4
  final Vec position;
  final double baseAngle; // radians, board coordinates (y grows downwards)
}

const cannonSlots = [
  CannonSlot(1, Vec(180, 60), math.pi / 2),
  CannonSlot(2, Vec(20, 150), 0),
  CannonSlot(3, Vec(340, 150), math.pi),
  CannonSlot(4, Vec(180, 540), -math.pi / 2),
];

class Cannon {
  Cannon(this.slot, {this.cooldown = 0, this.autoClock = 0});

  factory Cannon.fromJson(CannonSlot slot, Map<String, dynamic> json) {
    final cooldown = (json['cooldown'] as num).toDouble();
    final autoClock = (json['autoClock'] as num).toDouble();
    if (json['slot'] != slot.index ||
        !cooldown.isFinite ||
        !autoClock.isFinite ||
        cooldown < 0 ||
        autoClock < 0) {
      throw const FormatException('Cañón guardado inválido');
    }
    return Cannon(slot, cooldown: cooldown, autoClock: autoClock);
  }

  final CannonSlot slot;
  double cooldown; // seconds until a shot is allowed
  double autoClock; // seconds accumulated towards the next automatic shot
  double blockedFlash = 0; // presentation only, not saved
  double recoil = 0; // presentation only, not saved
  static const bodyRadius = 16.0;
  static const muzzleDistance = 24.0;
  static const touchRadius = 28.0;
  static const blockedSeconds = .3;
  static const recoilSeconds = .12;

  /// Triangle wave: constant angular speed, full back-and-forth per period.
  double angleAt(
    double clock, {
    required double arcDegrees,
    required double period,
  }) {
    final s = (clock / period + (slot.index - 1) * .25) % 1.0;
    final tri = 1 - 4 * (s - .5).abs(); // -1 → 1 → -1
    return slot.baseAngle + tri * arcDegrees * math.pi / 360;
  }

  Vec muzzle(double angle) =>
      slot.position + Vec(math.cos(angle), math.sin(angle)) * muzzleDistance;

  /// Advances presentation timers and cooldown. Never negative.
  void tick(double dt) {
    cooldown = math.max(0, cooldown - dt);
    blockedFlash = math.max(0, blockedFlash - dt);
    recoil = math.max(0, recoil - dt);
  }

  Map<String, dynamic> toJson() => {
    'slot': slot.index,
    'cooldown': cooldown,
    'autoClock': autoClock,
  };
}
