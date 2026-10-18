import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import '../../../app/game_session.dart';
import '../../../core/vec.dart';
import '../domain/board.dart';
import '../domain/tool.dart';

class GardenGame extends FlameGame {
  GardenGame(this.session)
    : _displayBoard =
          session.board ?? Board(session.catalog.settings(session.levels));
  // Presentation only: the completed day has already been banked and discarded
  // by the session. Keeping this reference cannot generate or collect income.
  Board _displayBoard;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    session.addListener(_syncEngine);
    _syncEngine();
  }

  void _syncEngine() {
    if (session.board != null) _displayBoard = session.board!;
    if (session.running && !session.paused) {
      resumeEngine();
    } else {
      pauseEngine();
    }
  }

  @override
  void onRemove() {
    session.removeListener(_syncEngine);
    super.onRemove();
  }

  final GameSession session;
  double _time = 0;
  final _labels = <String, TextPainter>{};
  double get scale => math.min(size.x / Board.width, size.y / Board.height);
  Offset get origin => Offset(
    (size.x - Board.width * scale) / 2,
    (size.y - Board.height * scale) / 2,
  );
  Vec? boardPoint(Offset point) {
    if (scale <= 0) return null;
    final p = (point - origin) / scale;
    return p.dx < 0 || p.dy < 0 || p.dx > 360 || p.dy > 560
        ? null
        : Vec(p.dx, p.dy);
  }

  @override
  Color backgroundColor() => const Color(0xff111c2e);
  @override
  void update(double dt) {
    if (!session.running || session.paused) return;
    _displayBoard = session.board!;
    super.update(dt);
    session.tick(dt);
    if (session.running && !session.paused) _time += dt;
  }

  Paint paint(Color color, {double? stroke}) => Paint()
    ..color = color
    ..style = stroke == null ? PaintingStyle.fill : PaintingStyle.stroke
    ..strokeWidth = stroke ?? 1;
  Offset offset(Vec point) => Offset(point.x, point.y);
  void label(
    Canvas canvas,
    String text,
    Offset point, {
    Color color = const Color(0xff172333),
    double fontSize = 12,
  }) {
    final key = '$text/$color/$fontSize';
    final painter = _labels.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    if (_labels.length > 300) _labels.clear();
    painter.paint(
      canvas,
      point - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final board = session.board ?? _displayBoard;
    if (scale <= 0) return;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    const bounds = Rect.fromLTWH(0, 0, 360, 560);
    final border = RRect.fromRectAndRadius(
      bounds.deflate(2),
      const Radius.circular(28),
    );
    canvas.clipRRect(border);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, 0), Offset(360, 560), [
          Color(0xfff1e5cd),
          Color(0xffdac8a5),
        ]),
    );
    for (var x = 20.0; x < 360; x += 20) {
      for (var y = 20.0; y < 560; y += 20) {
        canvas.drawCircle(Offset(x, y), .8, paint(const Color(0x20877553)));
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.deflate(13), const Radius.circular(19)),
      paint(const Color(0x30766543), stroke: 2),
    );
    label(
      canvas,
      'J A R D Í N   M E C Á N I C O',
      const Offset(180, 525),
      color: const Color(0xff756347),
      fontSize: 10,
    );
    final hole = offset(Board.hole);
    final radius = board.settings['hole_capture_radius'];
    canvas.drawOval(
      Rect.fromCenter(
        center: hole + const Offset(0, 6),
        width: (radius + 13) * 2,
        height: (radius + 10) * 2,
      ),
      paint(const Color(0x30644c2d)),
    );
    canvas.drawCircle(hole, radius + 9, paint(const Color(0xffbbaa8a)));
    canvas.drawCircle(hole, radius + 5, paint(const Color(0xff697583)));
    canvas.drawCircle(hole, radius, paint(const Color(0xff172333)));
    canvas.drawCircle(
      hole + const Offset(0, -3),
      radius - 5,
      paint(const Color(0xff0c1523)),
    );
    canvas.drawArc(
      Rect.fromCircle(center: hole, radius: radius + 7),
      math.pi,
      math.pi,
      false,
      paint(const Color(0xffeaddc2), stroke: 3),
    );
    final pulse = (math.sin(_time * 3) + 1) / 2;
    canvas.drawCircle(
      hole,
      radius + 14 + pulse * 3,
      paint(const Color(0x15247d73), stroke: 2),
    );
    final generator = offset(Board.generator);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: generator + const Offset(0, 4),
          width: 66,
          height: 50,
        ),
        const Radius.circular(12),
      ),
      paint(const Color(0x30644c2d)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: generator, width: 62, height: 48),
        const Radius.circular(12),
      ),
      paint(const Color(0xff247d73)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: generator + const Offset(0, -6),
          width: 42,
          height: 22,
        ),
        const Radius.circular(5),
      ),
      paint(const Color(0xff172333)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: generator + const Offset(0, 21),
          width: 26,
          height: 12,
        ),
        const Radius.circular(4),
      ),
      paint(const Color(0xff697583)),
    );
    label(
      canvas,
      'GENERADOR',
      generator + const Offset(0, -38),
      color: const Color(0xff64573f),
      fontSize: 10,
    );
    for (final ball in board.balls) {
      final p = offset(ball.position);
      canvas.drawCircle(
        p + const Offset(0, 2),
        board.radius + 1,
        paint(const Color(0x40644c2d)),
      );
      canvas.drawCircle(p, board.radius, paint(const Color(0xff697583)));
      canvas.drawCircle(
        p + const Offset(-1.5, -2),
        board.radius * .48,
        paint(const Color(0xff97a2ad)),
      );
    }
    for (final coin in board.coins) {
      final t = (1 - coin.landing / .2).clamp(0.0, 1.0);
      final p =
          offset(Board.hole + (coin.position - Board.hole) * t) -
          Offset(0, math.sin(t * math.pi) * 25);
      canvas.drawCircle(
        p + const Offset(0, 3),
        10,
        paint(const Color(0x40644c2d)),
      );
      canvas.drawCircle(p, 10, paint(const Color(0xffad7416)));
      canvas.drawCircle(
        p - const Offset(0, 1),
        8.5,
        paint(const Color(0xfff5b83d)),
      );
      canvas.drawCircle(
        p - const Offset(0, 1),
        5.5,
        paint(const Color(0xffb47e20), stroke: 1),
      );
      label(canvas, '${coin.value}', p - const Offset(0, 1), fontSize: 9);
    }
    if (board.settings['robot_count'] > 0) {
      final p = offset(board.robot.position);
      canvas.drawCircle(
        p + const Offset(0, 4),
        18,
        paint(const Color(0x40644c2d)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: 29, height: 30),
          const Radius.circular(9),
        ),
        paint(const Color(0xffd1764c)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: p - const Offset(0, 2),
            width: 20,
            height: 12,
          ),
          const Radius.circular(4),
        ),
        paint(const Color(0xff172333)),
      );
      canvas.drawCircle(
        p + const Offset(-5, -2),
        2,
        paint(const Color(0xfff1e5cd)),
      );
      canvas.drawCircle(
        p + const Offset(5, -2),
        2,
        paint(const Color(0xfff1e5cd)),
      );
    }
    if (board.paddle case final Vec point) {
      final p = offset(point);
      if (board.settings['magnet_radius'] > 0) {
        canvas.drawCircle(
          p,
          board.settings['magnet_radius'],
          paint(const Color(0x12247d73)),
        );
        canvas.drawCircle(
          p,
          board.settings['magnet_radius'],
          paint(const Color(0x50247d73), stroke: 1),
        );
      }
      if (board.tool == BallTool.hand) {
        final ball = board.heldBall;
        final center = ball == null ? p : offset(ball.position);
        canvas.drawCircle(
          center,
          board.radius + 7,
          paint(const Color(0x40247d73)),
        );
        canvas.drawCircle(
          center,
          board.radius + 7,
          paint(const Color(0xff247d73), stroke: 2),
        );
        if (ball != null) {
          canvas.drawLine(p, center, paint(const Color(0xff247d73), stroke: 2));
        }
      } else {
        for (final segment in board.segments) {
          final a = offset(segment.a), b = offset(segment.b);
          canvas.drawLine(
            a + const Offset(0, 3),
            b + const Offset(0, 3),
            paint(const Color(0x40644c2d), stroke: Board.broomThickness * 2 + 2)
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawLine(
            a,
            b,
            paint(const Color(0xff247d73), stroke: Board.broomThickness * 2)
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawLine(
            a,
            b,
            paint(const Color(0xff8fc7ba), stroke: 2)
              ..strokeCap = StrokeCap.round,
          );
        }
        final direction = Vec(
          math.cos(board.toolAngle),
          math.sin(board.toolAngle),
        );
        canvas.drawLine(
          p,
          offset(point - direction * 21),
          paint(const Color(0xff756347), stroke: 4)
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    canvas.restore();
  }
}
