import '../../../core/vec.dart';

typedef RobotTarget = ({int id, Vec position});

class Robot {
  Vec position = const Vec(295, 360);
  int? targetId;
  double _decision = 0;
  double _stalled = 0;
  double _lastDistance = double.infinity;

  Vec? direction(double dt, List<RobotTarget> targets, Vec hole) {
    if (targets.isEmpty) {
      targetId = null;
      return null;
    }
    _decision -= dt;
    var target = targets.where((b) => b.id == targetId).firstOrNull;
    if (_decision <= 0 || target == null) {
      if (target == null || _stalled > 1) {
        final candidates = [...targets]
          ..sort(
            (a, b) => (a.position - position).length.compareTo(
              (b.position - position).length,
            ),
          );
        final alternatives = candidates.where(
          (candidate) => candidate.id != targetId,
        );
        target = _stalled > 1 && alternatives.isNotEmpty
            ? alternatives.first
            : candidates.first;
        targetId = target.id;
        _stalled = 0;
        _lastDistance = double.infinity;
      }
      _decision = .25;
    }
    final towardHole = (hole - target.position).unit;
    final behind = target.position - towardHole * 24;
    final delta = (position - behind).length;
    final alignment = ((target.position - position).unit - towardHole).length;
    final goal = delta < 10 || alignment < .35
        ? target.position + towardHole * 12
        : behind;
    final distance = (target.position - hole).length;
    _stalled = distance >= _lastDistance - .02 ? _stalled + dt : 0;
    _lastDistance = distance;
    return goal;
  }
}
