import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/board.dart';

/// One feedback burst per rendered batch, at most one every 120 ms of simulation.
/// Dropped contacts are never queued for playback after silence/pause.
class BatFeedback {
  Board? _board;
  int _serial = 0;
  double _cooldown = 0;

  void suppress(Board board) {
    _board = board;
    _serial = board.batImpactSerial;
  }

  void update(
    double dt,
    Board board, {
    required bool sound,
    required bool haptics,
  }) {
    if (_board != board) {
      _board = board;
      _serial = 0;
      _cooldown = 0;
    }
    _cooldown = (_cooldown - dt).clamp(0.0, .12);
    if (_serial == board.batImpactSerial) return;
    _serial = board.batImpactSerial;
    if (board.coinOnly || _cooldown > 0) return;
    _cooldown = .12;
    if (sound) unawaited(SystemSound.play(SystemSoundType.click));
    if (haptics) {
      unawaited(
        board.lastBatImpactStrength > .65
            ? HapticFeedback.mediumImpact()
            : HapticFeedback.lightImpact(),
      );
    }
  }
}
