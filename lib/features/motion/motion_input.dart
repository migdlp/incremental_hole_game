import '../../core/vec.dart';

/// Board coordinates: x right, y down. Values are fractions of earth gravity.
abstract class MotionInput {
  bool get available;
  Vec get tilt;
  void setActive(bool active);
  void dispose();
}

class NoMotionInput implements MotionInput {
  const NoMotionInput();
  @override
  bool get available => false;
  @override
  Vec get tilt => Vec.zero;
  @override
  void setActive(bool active) {}
  @override
  void dispose() {}
}
