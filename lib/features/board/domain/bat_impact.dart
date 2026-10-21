import '../../../core/vec.dart';

class BatImpact {
  BatImpact(this.position, this.intensity);
  final Vec position;
  final double intensity;
  double age = 0;
  static const lifetime = .16;
}
