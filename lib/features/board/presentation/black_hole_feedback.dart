import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/board.dart';

/// Consume activations once, without replaying restored or silenced announcements.
class BlackHoleFeedback {
  Board? _board;
  int _activations = 0;
  void sync(Board board, {required bool sound, required bool playing}) {
    final count = board.blackHole.activations;
    if (_board != board || !playing || board.coinOnly) {
      _board = board;
      _activations = count;
      return;
    }
    final changed = count > _activations;
    _activations = count;
    if (changed && sound) unawaited(SystemSound.play(SystemSoundType.click));
  }
}
