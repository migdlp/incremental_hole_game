import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import '../../../app/game_session.dart';
import '../../../core/vec.dart';
import '../domain/board.dart';
import '../domain/wall_impact.dart';
import '../domain/coin_denomination.dart';
import 'coin_painter.dart';
import 'bat_feedback.dart';
import 'black_hole_feedback.dart';
import 'launcher_feedback.dart';
import '../domain/black_hole_event.dart';
import '../domain/bat_impact.dart';

class GardenGame extends FlameGame {
  GardenGame(this.session, {this.wallEffectsEnabled = true})
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
    _launcherFeedback.sync(
      _displayBoard,
      sound: session.sound,
      playing: session.running && !session.paused,
    );
    _blackHoleFeedback.sync(
      _displayBoard,
      sound: session.sound,
      playing: session.running && !session.paused,
    );
    if (session.running && !session.paused) {
      resumeEngine();
    } else {
      _batFeedback.suppress(_displayBoard);
      pauseEngine();
    }
  }

  @override
  void onRemove() {
    session.removeListener(_syncEngine);
    super.onRemove();
  }

  final GameSession session;
  bool wallEffectsEnabled;
  final _batFeedback = BatFeedback();
  final _blackHoleFeedback = BlackHoleFeedback();
  final _launcherFeedback = LauncherFeedback();
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
    _launcherFeedback.sync(
      _displayBoard,
      sound: session.sound,
      playing: session.running && !session.paused,
    );
    if (session.running && !session.paused) {
      _batFeedback.update(
        dt,
        session.board!,
        sound: session.sound,
        haptics: session.haptics,
      );
    }
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

  void _renderElasticWalls(Canvas canvas, Board board) {
    if (board.wallRestitution <= 1) return;
    for (final wall in WallSide.values) {
      final vertical = wall == WallSide.left || wall == WallSide.right;
      final extent = vertical ? Board.height : Board.width;
      final impacts = wallEffectsEnabled
          ? board.wallImpacts.where((impact) => impact.wall == wall).toList()
          : <WallImpact>[];
      final path = Path();
      for (var coordinate = 4.0; coordinate <= extent - 4; coordinate += 8) {
        var deformation = 0.0;
        for (final impact in impacts) {
          deformation += impact.displacementAt(coordinate);
        }
        deformation = deformation.clamp(-10.0, 12.0);
        final point = switch (wall) {
          WallSide.left => Offset(4 + deformation, coordinate),
          WallSide.right => Offset(Board.width - 4 - deformation, coordinate),
          WallSide.top => Offset(coordinate, 4 + deformation),
          WallSide.bottom => Offset(coordinate, Board.height - 4 - deformation),
        };
        if (coordinate == 4) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint(const Color(0x40247d73), stroke: 6));
      canvas.drawPath(path, paint(const Color(0xff247d73), stroke: 2.5));
    }
  }

  void _renderGravity(Canvas canvas, Board board) {
    final event = board.gravity;
    if (board.gravityObjectVisible) {
      final p = offset(event.position);
      final flash = (event.damageFlash / .18).clamp(0.0, 1.0);
      canvas.drawCircle(p, 24 + flash * 4, paint(const Color(0x3038bdf8)));
      canvas.drawCircle(
        p + const Offset(0, 3),
        20,
        paint(const Color(0x40644c2d)),
      );
      canvas.drawCircle(
        p,
        19,
        paint(flash > .2 ? const Color(0xffc4f1fc) : const Color(0xff337eaa)),
      );
      canvas.drawCircle(p, 18, paint(const Color(0xff91e8f4), stroke: 2));
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 30, height: 12),
        paint(const Color(0xffc7f7fc), stroke: 1.5),
      );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 12, height: 30),
        paint(const Color(0xffc7f7fc), stroke: 1.5),
      );
      canvas.drawCircle(p, 5, paint(const Color(0xffe7fbff)));
      if (event.hits > 0) {
        final cracks = Path()
          ..moveTo(p.dx - 2, p.dy - 18)
          ..lineTo(p.dx + 3, p.dy - 9)
          ..lineTo(p.dx - 3, p.dy - 2)
          ..lineTo(p.dx + 4, p.dy + 7);
        if (event.hits * 2 >= event.hitsRequired) {
          cracks
            ..moveTo(p.dx - 3, p.dy - 2)
            ..lineTo(p.dx - 11, p.dy + 4)
            ..lineTo(p.dx - 16, p.dy + 11)
            ..moveTo(p.dx + 3, p.dy - 9)
            ..lineTo(p.dx + 14, p.dy - 13);
        }
        canvas.drawPath(cracks, paint(const Color(0xff183349), stroke: 2));
      }
    }
  }

  void _renderEventAnnouncements(Canvas canvas, Board board) {
    if (board.coinOnly) return;
    final notices = [
      if (board.gravity.announcement > 0)
        ('GRAVEDAD', board.gravity.announcement, const Color(0xff91e8f4)),
      if (board.blackHole.announcement > 0)
        (
          'AGUJERO NEGRO',
          board.blackHole.announcement,
          const Color(0xffc4b5fd),
        ),
    ];
    if (notices.isEmpty) return;
    final opacity = notices.map((n) => n.$2).reduce(math.max).clamp(0.0, 1.0);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 360, 560),
      paint(Color.fromRGBO(145, 195, 244, .16 * opacity)),
    );
    for (var i = 0; i < notices.length; i++) {
      final notice = notices[i];
      final y = notices.length == 1 ? 230.0 : 192.0 + i * 76;
      final intensity = notice.$2.clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(20, y, 320, 66),
          const Radius.circular(12),
        ),
        paint(Color.fromRGBO(17, 28, 46, .9 * intensity)),
      );
      label(
        canvas,
        'HABILIDAD ESPECIAL:',
        Offset(180, y + 20),
        fontSize: 15,
        color: Color.fromRGBO(231, 251, 255, intensity),
      );
      label(
        canvas,
        notice.$1,
        Offset(180, y + 46),
        fontSize: 22,
        color: notice.$3.withValues(alpha: intensity),
      );
    }
  }

  void _renderBlackHoleSuction(Canvas canvas, Board board) {
    final effect = board.blackHole;
    if (!effect.active || board.coinOnly) return;
    for (var i = 0; i < 3; i++) {
      final phase = (effect.elapsed * .7 + i / 3) % 1;
      final radius = 30 + (effect.reach - 30) * (1 - phase);
      canvas.drawCircle(
        offset(Board.hole),
        radius,
        paint(
          Color.fromRGBO(116, 81, 165, .14 * math.sin(phase * math.pi)),
          stroke: 1.5,
        ),
      );
    }
  }

  void _renderBlackHoleObjects(Canvas canvas, Board board) {
    for (final object in board.blackHole.objects) {
      final p = offset(object.position);
      final damage = object.damageFlash / .18;
      canvas.drawCircle(p, 23 + damage * 3, paint(const Color(0x407c3aed)));
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 42, height: 19),
        paint(const Color(0xffa78bfa), stroke: 2),
      );
      canvas.drawCircle(p, 17, paint(const Color(0xff1c1434)));
      canvas.drawCircle(
        p,
        16,
        paint(
          damage > .2 ? const Color(0xffddd6fe) : const Color(0xff7c3aed),
          stroke: 2,
        ),
      );
      canvas.drawCircle(p, 11, paint(const Color(0xff080a14)));
      if (object.hits > 0) {
        final cracks = Path()
          ..moveTo(p.dx - 1, p.dy - 17)
          ..lineTo(p.dx + 4, p.dy - 7)
          ..lineTo(p.dx - 3, p.dy + 1)
          ..lineTo(p.dx + 3, p.dy + 14);
        if (object.hits * 2 >= object.hitsRequired) {
          cracks
            ..moveTo(p.dx - 3, p.dy + 1)
            ..lineTo(p.dx - 14, p.dy + 9);
        }
        canvas.drawPath(cracks, paint(const Color(0xffc4b5fd), stroke: 2));
      }
    }
    for (final impact in board.blackHole.impacts) {
      final progress = (impact.age / BlackHoleImpact.lifetime).clamp(0.0, 1.0);
      canvas.drawCircle(
        offset(impact.position),
        20 + 10 * progress,
        paint(Color.fromRGBO(167, 139, 250, .6 * (1 - progress)), stroke: 2),
      );
    }
  }

  void _renderLauncher(Canvas canvas, Board board) {
    final launcher = board.launcher;
    if (!launcher.unlocked) return;
    if (launcher.boundaryFlash > 0) {
      canvas.drawLine(
        const Offset(0, 420),
        const Offset(360, 420),
        paint(const Color(0xffdc2626), stroke: 2),
      );
      canvas.drawRect(
        const Rect.fromLTWH(2, 420, 356, 138),
        paint(const Color(0xffdc2626), stroke: 2),
      );
    }
    final center = offset(launcher.position), muzzle = offset(launcher.muzzle);
    canvas.drawCircle(
      center + const Offset(0, 4),
      launcher.bodyRadius + 3,
      paint(const Color(0x40644c2d)),
    );
    canvas.drawLine(
      center,
      muzzle,
      paint(const Color(0xff172333), stroke: launcher.barrelRadius * 2 + 3),
    );
    canvas.drawLine(
      center,
      muzzle,
      paint(const Color(0xff71858a), stroke: launcher.barrelRadius * 2),
    );
    canvas.drawCircle(
      center,
      launcher.bodyRadius,
      paint(const Color(0xff344b50)),
    );
    canvas.drawCircle(
      center,
      launcher.bodyRadius - 4,
      paint(const Color(0xff7b9692)),
    );
    canvas.drawCircle(center, 5, paint(const Color(0xff25383d)));
    canvas.drawLine(
      muzzle - offset(launcher.axis) * 3,
      muzzle + offset(launcher.axis) * 2,
      paint(const Color(0xff111c2e), stroke: launcher.barrelRadius * 2),
    );
    if (launcher.flash > 0) {
      final intensity = launcher.flash / .15;
      final tip = muzzle + offset(launcher.axis) * (launcher.barrelRadius + 5);
      canvas.drawCircle(
        tip,
        8 * intensity + 3,
        paint(Color.fromRGBO(255, 213, 125, intensity * .8)),
      );
      canvas.drawCircle(tip, 3 * intensity, paint(const Color(0xfffff1ce)));
    }
    if (board.holdingLauncher) {
      for (final handle in launcher.handles) {
        canvas.drawCircle(offset(handle), 5, paint(const Color(0xffdcebe7)));
      }
    }
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
    _renderElasticWalls(canvas, board);
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
    final feeding = session.feeding;
    final feedingRadius = radius + 13;
    canvas.drawCircle(
      hole,
      feedingRadius,
      paint(const Color(0x40247d73), stroke: 3),
    );
    final progress = feeding.fraction;
    if (progress != null && progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: hole, radius: feedingRadius),
        -math.pi / 2,
        progress * math.pi * 2,
        false,
        paint(
          feeding.met ? const Color(0xff8dd4b2) : const Color(0xff247d73),
          stroke: 3,
        ),
      );
    }
    _renderBlackHoleSuction(canvas, board);
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
          center: generator + const Offset(0, 6),
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
          center: generator + const Offset(0, -21),
          width: 26,
          height: 12,
        ),
        const Radius.circular(4),
      ),
      paint(const Color(0xff697583)),
    );
    _renderLauncher(canvas, board);
    for (final ball in board.balls) {
      final p = offset(ball.position);
      canvas.drawCircle(
        p + const Offset(0, 2),
        board.radius + 1,
        paint(const Color(0x40644c2d)),
      );
      if (ball.golden) {
        canvas.drawCircle(p, board.radius + 1, paint(const Color(0xffb7791f)));
      }
      canvas.drawCircle(
        p,
        board.radius,
        paint(ball.golden ? const Color(0xffeab308) : const Color(0xff697583)),
      );
      canvas.drawCircle(
        p + const Offset(-1.5, -2),
        board.radius * .48,
        paint(ball.golden ? const Color(0xfffff4b0) : const Color(0xff97a2ad)),
      );
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
    if (session.visualFeedback && board.paddle != null) {
      final point = board.paddle!;
      final p = offset(point);
      if (board.canCollectCoins && board.settings['magnet_radius'] > 0) {
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
      if (!board.holdingPhysicalTool) {
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
          for (final held in board.heldBalls) {
            final position = offset(held.position);
            canvas.drawLine(
              p,
              position,
              paint(const Color(0xff247d73), stroke: 2),
            );
            if (held != ball) {
              canvas.drawCircle(
                position,
                board.radius + 4,
                paint(const Color(0xff247d73), stroke: 1.5),
              );
            }
          }
        }
      }
    }
    if (board.broomUnlocked) {
      final point = board.broomPosition;
      final p = offset(point);
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
      for (final handle in board.broomHandles) {
        final color = board.hasSecondBroomPoint
            ? const Color(0xff4ade80)
            : const Color(0xfff8f3e8);
        canvas.drawCircle(offset(handle), 8, paint(const Color(0xff172333)));
        canvas.drawCircle(offset(handle), 6, paint(color, stroke: 2));
      }
      final direction = Vec(
        math.cos(board.toolAngle),
        math.sin(board.toolAngle),
      );
      canvas.drawLine(
        p,
        offset(point - direction * 21),
        paint(const Color(0xff756347), stroke: 4)..strokeCap = StrokeCap.round,
      );
    }
    if (board.batUnlocked) {
      canvas.save();
      canvas.translate(board.batPosition.x, board.batPosition.y);
      canvas.rotate(board.batAngle);
      final length = board.batHalfLength;
      final thickness = board.batThickness;
      // Narrow wrapped handle, tapered wooden barrel, rounded striking end.
      final body = Path()
        ..moveTo(-length, -thickness * .38)
        ..lineTo(-length * .4, -thickness * .38)
        ..cubicTo(
          0,
          -thickness * .45,
          0,
          -thickness,
          length - thickness,
          -thickness,
        )
        ..quadraticBezierTo(length, -thickness, length, 0)
        ..quadraticBezierTo(length, thickness, length - thickness, thickness)
        ..cubicTo(
          0,
          thickness,
          0,
          thickness * .45,
          -length * .4,
          thickness * .38,
        )
        ..lineTo(-length, thickness * .38)
        ..close();
      canvas.drawPath(
        body.shift(const Offset(0, 3)),
        paint(const Color(0x40644c2d)),
      );
      canvas.drawPath(body, paint(const Color(0xffc58c51)));
      canvas.drawPath(body, paint(const Color(0xff67472e), stroke: 1));
      canvas.drawLine(
        Offset(-length, 0),
        Offset(-length * .45, 0),
        paint(const Color(0xff26344a), stroke: thickness * .9)
          ..strokeCap = StrokeCap.round,
      );
      for (var x = -length + 3; x < -length * .45; x += 4) {
        canvas.drawLine(
          Offset(x, -thickness * .4),
          Offset(x + 2, thickness * .4),
          paint(const Color(0xffb9c1c9), stroke: 1),
        );
      }
      canvas.drawLine(
        Offset(-length, -thickness * .65),
        Offset(-length, thickness * .65),
        paint(const Color(0xff67472e), stroke: 3)..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(2, -thickness * .4),
        Offset(length - thickness, -thickness * .4),
        paint(const Color(0xfff2cb91), stroke: 1.5)
          ..strokeCap = StrokeCap.round,
      );
      if (session.visualFeedback && board.holdingBat) {
        for (final x in [-length, length]) {
          canvas.drawCircle(
            Offset(x, 0),
            8,
            paint(const Color(0xff247d73), stroke: 2),
          );
        }
      }
      canvas.restore();
      if (session.visualFeedback) {
        for (final impact in board.batImpacts) {
          final progress = (impact.age / BatImpact.lifetime).clamp(0.0, 1.0);
          final color = Color.fromRGBO(255, 244, 192, 1 - progress);
          canvas.drawCircle(
            offset(impact.position),
            3 + progress * (5 + 6 * impact.intensity),
            paint(color, stroke: 2),
          );
        }
      }
    }
    _renderBlackHoleObjects(canvas, board);
    if (board.coinOnly) {
      canvas.drawRect(bounds, paint(const Color(0xa6000000)));
    }
    for (final coin in board.coins) {
      final t = (1 - coin.landing / .2).clamp(0.0, 1.0);
      final p =
          offset(Board.hole + (coin.position - Board.hole) * t) -
          Offset(0, math.sin(t * math.pi) * 25);
      paintCoin(
        canvas,
        p,
        CoinDenomination.values.firstWhere(
          (d) => d.amount == coin.value,
          orElse: () => CoinDenomination.one,
        ),
      );
    }
    _renderGravity(canvas, board);
    _renderEventAnnouncements(canvas, board);
    canvas.restore();
  }
}
