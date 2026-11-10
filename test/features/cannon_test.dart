import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/cannon.dart';

void main() {
  double deg(double degrees) => degrees * math.pi / 180;

  test('G1 sweeps a 150 degree arc at constant speed', () {
    final cannon = Cannon(cannonSlots[0]);
    double at(double t) => cannon.angleAt(t, arcDegrees: 150, period: 2);
    final base = math.pi / 2;
    expect(at(0), closeTo(base - deg(75), 1e-9));
    expect(at(.5), closeTo(base, 1e-9));
    expect(at(1), closeTo(base + deg(75), 1e-9));
    expect(at(1.5), closeTo(base, 1e-9));
    expect(at(2), closeTo(base - deg(75), 1e-9));
  });

  test('slots are phase shifted by a quarter period', () {
    final angle = Cannon(cannonSlots[1]).angleAt(0, arcDegrees: 150, period: 2);
    expect(angle, closeTo(0 + 0, 1e-9));
  });

  test('muzzle is 24 units along the aim', () {
    final muzzle = Cannon(cannonSlots[0]).muzzle(math.pi / 2);
    expect(muzzle.x, closeTo(180, 1e-9));
    expect(muzzle.y, closeTo(84, 1e-9));
  });

  test('tick never makes timers negative', () {
    final cannon = Cannon(cannonSlots[0], cooldown: .3)
      ..blockedFlash = .1
      ..recoil = .1;
    cannon.tick(1);
    expect(cannon.cooldown, 0);
    expect(cannon.blockedFlash, 0);
    expect(cannon.recoil, 0);
  });

  test('fromJson rejects mismatched slot and negative values', () {
    expect(
      () => Cannon.fromJson(cannonSlots[0], {
        'slot': 2,
        'cooldown': 0,
        'autoClock': 0,
      }),
      throwsFormatException,
    );
    expect(
      () => Cannon.fromJson(cannonSlots[0], {
        'slot': 1,
        'cooldown': -.1,
        'autoClock': 0,
      }),
      throwsFormatException,
    );
  });

  test('toJson roundtrip', () {
    final cannon = Cannon(cannonSlots[2], cooldown: .4, autoClock: 1.1);
    final restored = Cannon.fromJson(cannonSlots[2], cannon.toJson());
    expect(restored.cooldown, .4);
    expect(restored.autoClock, 1.1);
    expect(restored.slot.position, isA<Vec>());
  });
}
