import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../../core/vec.dart';
import '../domain/absorption_effects.dart';

/// One shared circular clip, followed by the foreground rim. No physical bodies.
void paintAbsorption(
  Canvas canvas,
  AbsorptionEffects effects,
  Vec hole,
  double radius,
  Paint brush,
) {
  if (effects.active == 0 && effects.ripple == 0) return;
  final center = Offset(hole.x, hole.y);
  void draw(bool inside) {
    for (final b in effects.balls) {
      if (!b.active) continue;
      final t = (b.age / effects.config['sinkDuration']).clamp(0.0, 1.0);
      final u = t * t * (3 - 2 * t), inertia = t * (1 - t) * .018;
      final entry = (u / .65).clamp(0.0, 1.0),
          depth = ((u - .65) / .35).clamp(0.0, 1.0);
      final x = b.x + (hole.x - b.x) * entry + b.vx * inertia;
      final y =
          b.y + (hole.y - b.y) * entry + radius * 1.22 * depth + b.vy * inertia;
      final within =
          u >= .65 ||
          (x - hole.x) * (x - hole.x) + (y - hole.y) * (y - hole.y) <=
              radius * radius;
      if (within != inside) continue;
      // Keep a substantial ball size: disappearance comes from occlusion, not
      // shrinking to a point. Once inside, it descends under the front edge.
      final size = b.radius * (1 - .45 * t);
      brush
        ..style = PaintingStyle.fill
        ..color = Color.lerp(
          b.golden ? const Color(0xffeab308) : const Color(0xff697583),
          const Color(0xff080e18),
          t * .9,
        )!;
      canvas.drawCircle(Offset(x, y), size, brush);
      brush.color = Color.lerp(
        b.golden ? const Color(0xfffff4b0) : const Color(0xff97a2ad),
        const Color(0xff080e18),
        t,
      )!;
      canvas.drawCircle(
        Offset(x - size * .25, y - size * .3),
        size * .45,
        brush,
      );
    }
  }

  draw(false);
  canvas.save();
  canvas.clipPath(
    Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
  );
  draw(true);
  canvas.restore();
  final displacement =
      math.sin(effects.ripple * math.pi) *
      effects.config['rippleGain'] *
      radius;
  brush
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..color = const Color(0xff697583);
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: radius + 3 + displacement),
    0,
    math.pi,
    false,
    brush,
  );
  brush
    ..strokeWidth = 2
    ..color = const Color(0xffbbaa8a);
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: radius + 7 + displacement),
    0,
    math.pi,
    false,
    brush,
  );
  brush.style = PaintingStyle.fill;
}
