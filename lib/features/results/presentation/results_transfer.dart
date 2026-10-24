import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../board/presentation/coin_painter.dart';
import '../domain/results_sequence.dart';

class ResultsTransferPainter extends CustomPainter {
  ResultsTransferPainter(this.sequence, this.source, this.target);
  final ResultsSequence sequence;
  final Rect? Function(int) source;
  final Rect? Function() target;
  @override
  void paint(Canvas canvas, Size size) {
    if (sequence.phase != ResultsPhase.coins || sequence.data.stacks.isEmpty) {
      return;
    }
    final i = sequence.row, stack = sequence.data.stacks[i];
    final from = source(i), to = target();
    if (from == null || to == null) return;
    final a = Offset(from.center.dx, from.top + from.height * .4167),
        b = Offset(to.center.dx, to.top + to.height * .4167);
    final brush = Paint();
    for (var j = 0; j < stack.visualCount; j++) {
      final t =
          (sequence.age - sequence.flightStart(stack, j)) /
          ResultsSequence.flightDuration;
      if (t < 0 || t >= 1) continue;
      final u = Curves.easeInCubic.transform(t), q = 1 - u;
      final bend = (j.isEven ? -1 : 1) * (25 + j * 5.0);
      final c = Offset(
        (a.dx + b.dx) / 2 + bend,
        math.min(a.dy, b.dy) - 45 - j * 4,
      );
      final p = a * (q * q) + c * (2 * q * u) + b * (u * u);
      brush.color = const Color(0xfff5c45d).withValues(alpha: .22 * (1 - t));
      canvas.drawCircle(p + Offset(-5 * q, 7 * q), 3, brush);
      canvas.drawCircle(p + Offset(4 * q, 13 * q), 1.5, brush);
      paintCoin(canvas, p, stack.denomination, radius: 7, paint: brush);
    }
  }

  @override
  bool shouldRepaint(ResultsTransferPainter oldDelegate) => true;
}
