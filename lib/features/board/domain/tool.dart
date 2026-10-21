import 'dart:math' as math;
import '../../../core/vec.dart';

enum BallTool {
  hand('Mano'),
  broom('Escoba'),
  vee('Escoba en V'),
  bat('Bate');

  const BallTool(this.label);
  final String label;
}

class ToolSegment {
  const ToolSegment(this.a, this.b);
  final Vec a, b;
  Vec closest(Vec point) {
    final delta = b - a;
    final squared = delta.x * delta.x + delta.y * delta.y;
    if (squared < .0001) return a;
    final offset = point - a;
    final t = ((offset.x * delta.x + offset.y * delta.y) / squared).clamp(
      0.0,
      1.0,
    );
    return a + delta * t;
  }
}

/// Shared by rendering and physics: a thick line, or a V opening forwards.
List<ToolSegment> broomSegments(
  BallTool tool,
  Vec center,
  double angle,
  double halfWidth,
) {
  final forward = Vec(math.cos(angle), math.sin(angle));
  final side = Vec(-forward.y, forward.x);
  if (tool == BallTool.hand || tool == BallTool.bat) return const [];
  if (tool == BallTool.broom) {
    return [ToolSegment(center - side * halfWidth, center + side * halfWidth)];
  }
  final vertex = center - forward * (halfWidth * .45);
  final mouth = center + forward * (halfWidth * .35);
  return [
    ToolSegment(mouth - side * halfWidth, vertex),
    ToolSegment(vertex, mouth + side * halfWidth),
  ];
}
