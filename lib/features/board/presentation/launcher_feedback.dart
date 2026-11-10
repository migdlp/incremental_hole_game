import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/board.dart';

class LauncherFeedback {
  Board? _board;
  int _shots = 0;
  void sync(Board board, {required bool sound, required bool playing}) {
    final count = board.launcher.shots;
    if (_board != board || !playing || board.coinOnly) {
      _board = board;
      _shots = count;
      return;
    }
    final changed = count > _shots;
    _shots = count;
    if (changed && sound) unawaited(SystemSound.play(SystemSoundType.click));
  }
}
