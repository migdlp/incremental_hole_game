import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'results_data.dart';

enum ResultsPhase { opening, coins, hole, completed }

class ResultsSequence extends ChangeNotifier {
  ResultsSequence(this.data);
  final ResultsData data;
  static const openingDuration = .22, rowDuration = 1.2, holeDuration = 1.4;
  static const revealDuration = .18, countDuration = .52, flightDuration = .46;
  ResultsPhase phase = ResultsPhase.opening;
  double age = 0, clock = 0, _lastSkip = -1;
  int row = 0, generation = 0;
  bool get done => phase == ResultsPhase.completed;
  bool get showHole => phase == ResultsPhase.hole || done;
  double get holeProgress => done
      ? 1
      : showHole
      ? (age / holeDuration).clamp(0, 1)
      : 0;
  double rowAge(int index) => showHole || index < row
      ? rowDuration
      : index == row && phase == ResultsPhase.coins
      ? age
      : 0;
  double reveal(int index) => (rowAge(index) / revealDuration).clamp(0, 1);
  int counted(int index) =>
      (data.stacks[index].count *
              ((rowAge(index) - revealDuration) / countDuration).clamp(0, 1))
          .floor();
  double flightStart(ResultStack stack, int packet) =>
      revealDuration + countDuration * (packet + .5) / stack.visualCount;
  int get total => data.stacks.indexed.fold<int>(
    0,
    (sum, entry) => sum + counted(entry.$1) * entry.$2.denomination.amount,
  );
  int get wallet {
    var amount = data.startingBalance;
    for (var i = 0; i < data.stacks.length; i++) {
      final stack = data.stacks[i];
      var received = 0;
      for (var j = 0; j < stack.visualCount; j++) {
        if (rowAge(i) + 1e-9 >= flightStart(stack, j) + flightDuration) {
          received = stack.countThrough(j);
        }
      }
      amount += received * stack.denomination.amount;
    }
    return math.min(data.balance, amount);
  }

  double get walletPulse {
    if (phase != ResultsPhase.coins || data.stacks.isEmpty) return 0;
    final stack = data.stacks[row];
    var pulse = 0.0;
    for (var j = 0; j < stack.visualCount; j++) {
      final since = age - flightStart(stack, j) - flightDuration;
      if (since >= 0 && since < .16) pulse = math.max(pulse, 1 - since / .16);
    }
    return pulse;
  }

  void _enter(ResultsPhase next) {
    phase = next;
    age = 0;
    generation++;
  }

  void advance(double dt) {
    if (done || !dt.isFinite || dt <= 0) return;
    clock += dt;
    age += dt;
    // Carry overshoot across transitions, so frame rates do not change results.
    while (!done) {
      final duration = switch (phase) {
        ResultsPhase.opening => openingDuration,
        ResultsPhase.coins => data.stacks.isEmpty ? 0.0 : rowDuration,
        ResultsPhase.hole => holeDuration,
        ResultsPhase.completed => 0.0,
      };
      if (age + 1e-9 < duration) break;
      final rest = math.max(0.0, age - duration);
      if (phase == ResultsPhase.opening) {
        _enter(ResultsPhase.coins);
      } else if (phase == ResultsPhase.coins) {
        if (row + 1 < data.stacks.length) {
          row++;
          age = 0;
        } else {
          _enter(ResultsPhase.hole);
        }
      } else {
        _enter(ResultsPhase.completed);
      }
      age = rest;
    }
    notifyListeners();
  }

  void skip(int expectedGeneration) {
    if (done || generation != expectedGeneration || clock - _lastSkip < .25) {
      return;
    }
    _lastSkip = clock;
    _enter(showHole ? ResultsPhase.completed : ResultsPhase.hole);
    notifyListeners();
  }

  void completeAll() {
    if (done) return;
    _enter(ResultsPhase.completed);
    notifyListeners();
  }
}
