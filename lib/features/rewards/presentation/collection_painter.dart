import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../../../app/game_session.dart';
import '../../board/presentation/coin_painter.dart';
import '../domain/daily_coin_collection.dart';

/// The placed collection is recorded once when its visible prefix changes.
class CollectionPicture {
  ui.Picture? _picture;
  DailyCoinCollection? _owner;
  int _count = -1, _generation = -1;
  int recordings = 0;
  CollectionGrid? _grid;
  double _width = 0;
  bool _details = true;
  final brush = Paint();
  void draw(
    Canvas canvas,
    DailyCoinCollection collection,
    CollectionGrid grid,
    double width, {
    bool details = true,
  }) {
    final count = math.min(collection.placed, grid.capacity);
    if (_owner != collection ||
        _generation != collection.generation ||
        count != _count ||
        _grid?.rows != grid.rows ||
        _width != width ||
        _details != details) {
      _picture?.dispose();
      recordings++;
      final recorder = ui.PictureRecorder();
      final recorded = Canvas(recorder);
      recorded.clipRect(Rect.fromLTWH(0, 0, width, grid.height));
      for (var i = 0; i < count; i++) {
        recorded.save();
        recorded.translate(grid.x(i), grid.y(i));
        recorded.scale(1, CollectionGrid.faceScaleY);
        paintCoin(
          recorded,
          Offset.zero,
          collection.coins[i].denomination,
          radius: CollectionGrid.diameter / 2,
          paint: brush,
          details: details,
        );
        recorded.restore();
      }
      _picture = recorder.endRecording();
      _generation = collection.generation;
      _owner = collection;
      _count = count;
      _grid = grid;
      _width = width;
      _details = details;
    }
    if (_picture != null) canvas.drawPicture(_picture!);
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
    _owner = null;
  }
}

class DailyCollectionPainter extends CustomPainter {
  DailyCollectionPainter(
    this.session,
    this.grid,
    this.boardHeight,
    this.picture,
  ) : collectionIdentity = session.rewardVisuals.collection,
      super(repaint: session.rewardRepaint);
  final Object collectionIdentity;
  final GameSession session;
  final CollectionGrid grid;
  final double boardHeight;
  final CollectionPicture picture;
  final brush = Paint();
  @override
  void paint(Canvas canvas, Size size) {
    final visuals = session.rewardVisuals;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    picture.draw(
      canvas,
      visuals.collection,
      grid,
      size.width,
      details: visuals.quality < 2,
    );
    if (visuals.activeCount > 0) {
      final scale = boardHeight / 560;
      for (final coin in visuals.coins) {
        if (!coin.active || coin.age < visuals.delay) continue;
        final targetX = grid.x(coin.collectionSlot) / scale;
        final targetY = (grid.y(coin.collectionSlot) - grid.height) / scale;
        final x = coin.x(
          targetX,
          visuals.delay,
          origin: visuals.holeX,
          simple: visuals.quality >= 2,
        );
        final y = coin.y(
          targetY,
          visuals.delay,
          origin: visuals.holeY,
          simple: visuals.quality >= 2,
        );
        final u =
            ((coin.age - visuals.delay - coin.jump - coin.hold) / coin.flight)
                .clamp(0.0, 1.0);
        final settle = ((u - .8) / .2).clamp(0.0, 1.0);
        final center = Offset(x * scale, grid.height + y * scale);
        final radius =
            7 * scale + (CollectionGrid.diameter / 2 - 7 * scale) * settle;
        if (settle > 0) {
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.scale(1, 1 + (CollectionGrid.faceScaleY - 1) * settle);
          paintCoin(
            canvas,
            Offset.zero,
            coin.denomination,
            radius: radius,
            paint: brush,
            details: visuals.quality < 2,
          );
          canvas.restore();
        } else {
          paintCoin(
            canvas,
            center,
            coin.denomination,
            radius: radius,
            paint: brush,
            details: visuals.quality < 2,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DailyCollectionPainter old) =>
      old.grid.rows != grid.rows ||
      old.grid.columns != grid.columns ||
      old.boardHeight != boardHeight ||
      old.session != session ||
      old.collectionIdentity != collectionIdentity;
}
