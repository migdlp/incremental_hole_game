import 'dart:math' as math;

class Vec {
  const Vec(this.x, this.y);
  final double x;
  final double y;
  static const zero = Vec(0, 0);
  Vec operator +(Vec other) => Vec(x + other.x, y + other.y);
  Vec operator -(Vec other) => Vec(x - other.x, y - other.y);
  Vec operator *(double scale) => Vec(x * scale, y * scale);
  double get length => math.sqrt(x * x + y * y);
  Vec get unit => length < .0001 ? const Vec(0, 1) : this * (1 / length);
  Vec limit(double maximum) => length > maximum ? unit * maximum : this;
  Vec inside(double margin) =>
      Vec(x.clamp(margin, 360 - margin), y.clamp(margin, 560 - margin));
  List<double> toJson() => [x, y];
  factory Vec.fromJson(dynamic value) {
    final list = value as List;
    final v = Vec((list[0] as num).toDouble(), (list[1] as num).toDouble());
    if (!v.x.isFinite || !v.y.isFinite) {
      throw const FormatException('Posición inválida');
    }
    return v;
  }
}

double segmentDistance(Vec point, Vec a, Vec b) {
  final delta = b - a;
  final squared = delta.x * delta.x + delta.y * delta.y;
  if (squared < .0001) return (point - a).length;
  final offset = point - a;
  final t = ((offset.x * delta.x + offset.y * delta.y) / squared).clamp(
    0.0,
    1.0,
  );
  return (point - (a + delta * t)).length;
}
