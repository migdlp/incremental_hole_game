import 'dart:math' as math;
import '../../board/domain/coin_denomination.dart';
import 'reward_visual_config.dart';
import 'coin_plan.dart';
import 'daily_coin_collection.dart';

/// Economic delivery records are independent of the optional visual pool.
/// Inclusive ID ranges allow a bounded batch to represent any capture burst.
class PendingReward {
  PendingReward(this.first, this.last, this.amount, this.arrival);
  final int first;
  int last, amount;
  double arrival;
  Map<String, dynamic> toJson() => {
    'first': first,
    'last': last,
    'amount': amount,
    'arrival': arrival,
  };
}

class RewardDelivery {
  RewardDelivery({this.delay = 1, this.capacity = 128});
  final double delay;
  final int capacity;
  double clock = 0;
  int nextId = 1;
  final pending = <PendingReward>[];
  int get outstanding => pending.fold(0, (sum, r) => sum + r.amount);
  static const double hold = 1;
  static double jump(int id) => .24 + (id * 17 % 13) * .009;
  static double flight(int id) => .58 + (id * 23 % 17) * .012;

  int register(int amount) {
    if (amount <= 0) throw ArgumentError('Recompensa inválida');
    final id = nextId++;
    final arrival = clock + delay + jump(id) + hold + flight(id);
    if (pending.length < capacity) {
      pending.add(PendingReward(id, id, amount, arrival));
    } else {
      final batch = pending.last;
      batch.last = id;
      batch.amount += amount;
      batch.arrival = math.max(batch.arrival, arrival);
    }
    return id;
  }

  int advance(double dt) {
    clock += dt;
    var arrived = 0;
    for (var i = pending.length - 1; i >= 0; i--) {
      if (pending[i].arrival <= clock + 1e-9) {
        arrived += pending.removeAt(i).amount;
      }
    }
    return arrived;
  }

  int settle() {
    final total = outstanding;
    pending.clear();
    return total;
  }

  Map<String, dynamic> toJson() => {
    'clock': clock,
    'nextId': nextId,
    'pending': pending.map((r) => r.toJson()).toList(),
  };

  factory RewardDelivery.fromJson(
    Map<String, dynamic> json, {
    required int outstanding,
    required double delay,
    int capacity = 128,
  }) {
    final clock = json['clock'],
        next = json['nextId'],
        records = json['pending'];
    if (clock is! num ||
        !clock.isFinite ||
        clock < 0 ||
        next is! int ||
        next < 1 ||
        next > 0x1fffffffffffff ||
        records is! List ||
        records.length > capacity) {
      throw const FormatException('Registro de recompensas inválido');
    }
    final result = RewardDelivery(delay: delay, capacity: capacity)
      ..clock = clock.toDouble()
      ..nextId = next;
    var previous = 0;
    for (final record in records) {
      if (record is! Map<String, dynamic>) {
        throw const FormatException('Recompensa inválida');
      }
      final first = record['first'],
          last = record['last'],
          amount = record['amount'],
          arrival = record['arrival'];
      if (first is! int ||
          last is! int ||
          amount is! int ||
          arrival is! num ||
          first <= previous ||
          last < first ||
          last >= next ||
          amount < 1 ||
          amount > 0x1fffffffffffff ||
          !arrival.isFinite ||
          arrival < clock ||
          arrival > clock + delay + hold + 2) {
        throw const FormatException('Recompensa duplicada o incoherente');
      }
      result.pending.add(
        PendingReward(first, last, amount, arrival.toDouble()),
      );
      previous = last;
    }
    if (result.outstanding != outstanding) {
      throw const FormatException('Importe pendiente incoherente');
    }
    return result;
  }
}

/// Preallocated presentation state: never used to calculate or award money.
class RewardCoin {
  bool active = false;
  int id = 0, amount = 0, quantity = 1, collectionSlot = -1;
  String collectionDay = '';
  CoinDenomination denomination = CoinDenomination.one;
  double hold = RewardDelivery.hold;
  double age = 0, jump = 0, flight = 0;
  double dx = 0, dy = 0, bend = 0;
  double offsetX = 0, offsetY = 0, arcHeight = 26, angle = 0, emittedAt = 0;
  void reset(
    int rewardId,
    int value, {
    CoinDenomination? type,
    int count = 1,
    RewardVisualConfig config = const RewardVisualConfig(),
  }) {
    active = true;
    offsetX = offsetY = 0;
    arcHeight = 26;
    id = rewardId;
    amount = value;
    quantity = count;
    denomination =
        type ??
        CoinDenomination.values.lastWhere(
          (d) => d.amount <= value,
          orElse: () => CoinDenomination.one,
        );
    hold = config.hold;
    age = 0;
    jump = RewardDelivery.jump(id);
    flight = RewardDelivery.flight(id) * config.flightScale;
    dx = (id.isEven ? 1 : -1) * (18 + id * 13 % 27).toDouble();
    dy = (id % 3 == 0 ? -1 : 1) * (8 + id * 7 % 17).toDouble();
    bend =
        (id.isEven ? 1 : -1) *
        (22 + id * 11 % 38).toDouble() *
        config.variation;
    dx *= config.variation;
    dy *= config.variation;
  }

  // Scalar polynomial curves, without trig or allocating vectors every frame.
  double x(
    double target,
    double delay, {
    double origin = 180,
    bool simple = false,
  }) {
    origin += offsetX;
    final t = age - delay;
    if (t <= 0) return origin;
    if (t < jump) return origin + dx * (t / jump);
    // Keep the same spatial curve, but ease into its traversal after resting.
    final progress = ((t - jump - hold) / flight).clamp(0.0, 1.0);
    final u = progress * progress;
    final eased = u * u * (3 - 2 * u);
    return origin +
        dx +
        (target - origin - dx) * eased +
        (simple ? 0 : bend) * u * (1 - u) * (1 - 2 * u);
  }

  double y(
    double target,
    double delay, {
    double origin = 50,
    bool simple = false,
  }) {
    origin += offsetY;
    final t = age - delay;
    if (t <= 0) return origin;
    if (t < jump) {
      final u = t / jump;
      return origin + dy * u - arcHeight * 4 * u * (1 - u);
    }
    // Keep the same spatial curve, but ease into its traversal after resting.
    final progress = ((t - jump - hold) / flight).clamp(0.0, 1.0);
    final u = progress * progress;
    final eased = u * u * (3 - 2 * u);
    final safeBend = bend.clamp(
      -4 * math.max(0.0, math.min(550 - origin - dy, 550 - target)),
      4 * math.max(0.0, math.min(origin + dy - 10, target - 10)),
    );
    return origin +
        dy +
        (target - origin - dy) * eased -
        (simple ? 0 : safeBend) * u * (1 - u);
  }
}

class RewardVisuals {
  RewardVisuals(
    this.capacity,
    this.delay, {
    this.config = const RewardVisualConfig(),
    int? seed,
  }) : _randomState = seed ?? math.Random().nextInt(0x100000000),
       coins = List.generate(capacity, (_) => RewardCoin());
  int _randomState;
  double _random() {
    _randomState = (1664525 * _randomState + 1013904223) & 0xffffffff;
    return _randomState / 0x100000000;
  }

  double clock = 0,
      _nextEmission = 0,
      _angle = 0,
      _load = 0,
      _lastEmission = -10;
  int emittedObjects = 0;
  final _recentAngles = <double>[];
  double holeX = 180,
      holeY = 50,
      holeRadius = 22,
      boardWidth = 360,
      boardHeight = 560;
  double get emissionInterval =>
      config.emitMax + (config.emitMin - config.emitMax) * _load;
  double get angularSpeed =>
      config.angularMin + (config.angularMax - config.angularMin) * _load;
  void geometry(double x, double y, double radius) {
    holeX = x;
    holeY = y;
    holeRadius = radius;
  }

  final collection = DailyCoinCollection();
  double _lastArrival = 0;
  final RewardVisualConfig config;
  final int capacity;
  // Curve offset retained for callers; coins are initialized at this offset on
  // emission. Only the microbatch window delays their first appearance.
  final double delay;
  final List<RewardCoin> coins;
  final counts = <int, int>{};
  final _pending = <int, int>{};
  final _pendingTimes = <int, double>{};
  int _batchAmount = 0, _serial = 0, _nextType = 0, _active = 0;
  double _batchAge = 0;
  int? debugLimit;
  int grouped = 0, omitted = 0, peak = 0, batches = 0, quality = 0;
  int emittedQuantity = 0, arrivedQuantity = 0;
  int get activeCount => _active;
  int get pendingCount => _pending.values.fold(0, (a, b) => a + b);
  int get limit => (debugLimit ?? _adaptiveLimit).clamp(0, capacity);
  late int _adaptiveLimit = capacity;
  final _costs = <double>[];
  double _recovery = 0;
  bool _renderSamples = false;
  double _displayInterval = 1 / 60;
  double receiptPulse = 0;
  void observeRenderCost(double seconds) {
    _renderSamples = true;
    _cost(seconds);
  }

  void observeFrame(double dt) {
    if (dt.isFinite && dt > 0) {
      _displayInterval += (dt.clamp(1 / 120, .1) - _displayInterval) * .1;
    }
    if (!_renderSamples) _cost(dt);
  }

  void _cost(double dt) {
    if (!dt.isFinite || dt <= 0) return;
    _costs.add(dt);
    if (_costs.length < config.samples) return;
    _costs.sort();
    final p95 = _costs[((_costs.length - 1) * .95).round()];
    _costs.clear();
    if (p95 * 1000 > config.badMs) {
      _recovery = 0;
      if (quality < 3) {
        quality++;
      } else {
        _adaptiveLimit = math.max(
          math.min(32, capacity),
          (_adaptiveLimit * .85).floor(),
        );
      }
    } else if (p95 <= 1 / 60 + 1e-9) {
      _recovery += config.samples / 60;
      if (_recovery >= config.recovery) {
        if (_adaptiveLimit < capacity) {
          _adaptiveLimit = math.min(
            capacity,
            _adaptiveLimit + math.max(1, capacity ~/ 8),
          );
        } else if (quality > 0) {
          quality--;
        }
        _recovery = 0;
      }
    }
  }

  void add(int id, int amount) {
    if (amount < 0 || _batchAmount + amount > 0x1fffffffffffff) {
      throw ArgumentError('Microlote inválido');
    }
    if (amount == 0) return;
    _batchAmount += amount;
  }

  Map<int, int> get projectedCounts {
    final result = Map<int, int>.of(counts);
    if (_batchAmount > 0) {
      for (final e in planCoins(_batchAmount, config).entries) {
        result.update(e.key, (n) => n + e.value, ifAbsent: () => e.value);
      }
    }
    return result;
  }

  void _close({bool emit = true}) {
    if (_batchAmount == 0) return;
    for (final e in planCoins(_batchAmount, config).entries) {
      counts.update(e.key, (n) => n + e.value, ifAbsent: () => e.value);
      if (emit) {
        final old = _pending[e.key] ?? 0;
        _pendingTimes[e.key] =
            ((_pendingTimes[e.key] ?? clock) * old + clock * e.value) /
            (old + e.value);
        _pending.update(e.key, (n) => n + e.value, ifAbsent: () => e.value);
      }
    }
    batches++;
    _batchAmount = 0;
    _batchAge = 0;
  }

  void _drain({required bool allowEmission}) {
    if (_pending.isEmpty) return;
    if (limit == 0) {
      omitted += pendingCount;
      _pending.clear();
      _pendingTimes.clear();
      return;
    }
    // Capacity includes the one-start-per-frame constraint. A queue which
    // remains nonempty is not necessarily old: continuous small batches must
    // never be grouped merely because the stream has lasted several seconds.
    final lifetime = .36 + config.hold + .8 * config.flightScale;
    final throughput = math.min(
      1 / math.max(config.emitMin, math.max(1 / 60, _displayInterval)),
      limit / lifetime,
    );
    final packetBudget = math.max(1, (config.wait * throughput).floor());
    final aged = _pendingTimes.values.any((t) => clock - t >= config.wait);
    final saturated =
        pendingCount > config.pending || pendingCount > packetBudget || aged;
    if (saturated && _active >= limit) {
      // Coalesce only coins still resting, with the same denomination. Never
      // recolor or teleport a flying coin, and never discard the pending value.
      for (final c in coins) {
        if (c.active && c.age < delay + c.jump + c.hold) {
          final n = _pending.remove(c.denomination.amount) ?? 0;
          _pendingTimes.remove(c.denomination.amount);
          collection.addQuantity(c.collectionSlot, n);
          c.quantity += n;
          c.amount += n * c.denomination.amount;
          grouped += n;
        }
      }
    }
    if (!allowEmission || clock + 1e-9 < _nextEmission) return;
    var free = math.max(0, limit - _active);
    for (final coin in coins) {
      if (free == 0 || _pending.isEmpty) break;
      if (coin.active) continue;
      CoinDenomination? type;
      for (
        var attempt = 0;
        attempt < CoinDenomination.values.length;
        attempt++
      ) {
        final candidate = CoinDenomination
            .values[_nextType++ % CoinDenomination.values.length];
        if ((_pending[candidate.amount] ?? 0) > 0) {
          type = candidate;
          break;
        }
      }
      if (type == null) break;
      final count = _pending[type.amount]!;
      final slots = math.max(1, free ~/ _pending.length);
      final timeSlots = math.max(1, packetBudget ~/ _pending.length);
      final age = clock - (_pendingTimes[type.amount] ?? clock);
      final portion = age >= config.wait
          ? count
          : saturated
          ? (count + math.min(slots, timeSlots) - 1) ~/
                math.min(slots, timeSlots)
          : 1;
      final n = math.min(count, portion);
      if (n == count) {
        _pending.remove(type.amount);
        _pendingTimes.remove(type.amount);
      } else {
        _pending[type.amount] = count - n;
      }
      coin.reset(
        ++_serial,
        type.amount * n,
        type: type,
        count: n,
        config: config,
      );
      if (clock - _lastEmission > .6) {
        _angle = _random() * math.pi * 2;
        _recentAngles.clear();
      } else {
        final turn =
            angularSpeed * math.max(emissionInterval, clock - _lastEmission);
        final scattered = 1.8 + _random() * 1.1;
        final blend = ((_load - .15) / .2).clamp(0.0, 1.0);
        final rotation = blend * blend * (3 - 2 * blend);
        _angle +=
            (scattered * (1 - rotation) + turn * rotation) *
            (1 + (_random() * 2 - 1) * config.angleJitter);
      }
      if (_load < .22) {
        for (var attempt = 0; attempt < 64; attempt++) {
          final close = _recentAngles.any(
            (a) =>
                ((_angle - a + math.pi) % (2 * math.pi) - math.pi).abs() <
                config.smallSeparation,
          );
          if (!close) break;
          _angle += math.pi / 32;
        }
      }
      _recentAngles.add(_angle);
      if (_recentAngles.length > 3) _recentAngles.removeAt(0);
      coin.angle = _angle;
      coin.emittedAt = clock;
      final cos = math.cos(_angle), sin = math.sin(_angle);
      final originRadius =
          math.min(holeRadius * .18, 14.0) * (.5 + _random() * .5);
      coin.offsetX = (cos * originRadius).clamp(
        10 - holeX,
        boardWidth - 10 - holeX,
      );
      coin.offsetY = (sin * originRadius).clamp(
        10 - holeY,
        boardHeight - 10 - holeY,
      );
      final distance = config.jumpDistance * (.7 + _random() * .6);
      coin.dx = (cos * distance).clamp(
        10 - holeX - coin.offsetX,
        boardWidth - 10 - holeX - coin.offsetX,
      );
      coin.dy = (sin * distance).clamp(
        10 - holeY - coin.offsetY,
        boardHeight - 10 - holeY - coin.offsetY,
      );
      coin.arcHeight = math.max(
        0,
        math.min(
          23 + _random() * 6,
          math.min(holeY + coin.offsetY, holeY + coin.offsetY + coin.dy) - 10,
        ),
      );
      final margin = math.max(
        0.0,
        math.min(
          holeX + coin.offsetX + coin.dx - 10,
          boardWidth - 10 - holeX - coin.offsetX - coin.dx,
        ),
      );
      coin.bend = coin.bend.clamp(-margin, margin);
      coin.collectionSlot = collection.reserve(type, n);
      coin.collectionDay = collection.day;
      final natural = clock + coin.jump + coin.hold + coin.flight;
      final finish = math.max(natural, _lastArrival + 1 / 60);
      coin.flight += finish - natural;
      _lastArrival = finish;
      coin.age = delay;
      emittedQuantity += coin.quantity;
      emittedObjects++;
      _lastEmission = clock;
      _nextEmission =
          clock +
          (emissionInterval * (1 + (_random() - .5) * config.wave)).clamp(
            config.emitMin,
            config.emitMax,
          );
      _active++;
      free--;
      grouped += n - 1;
      peak = math.max(peak, _active);
      break; // One global emitter: never catch up with multiple starts in a frame.
    }
  }

  void advance(double dt, {bool allowEmission = true}) {
    if (!dt.isFinite || dt <= 0) return;
    clock += dt;
    final targetLoad = pendingCount / (pendingCount + config.loadScale);
    _load += (targetLoad - _load) * (1 - math.exp(-10 * dt));
    receiptPulse = math.max(0, receiptPulse - dt);
    for (final coin in coins) {
      if (!coin.active) continue;
      final wasHidden = coin.age < delay;
      coin.age += dt;
      if (wasHidden && coin.age >= delay) emittedQuantity += coin.quantity;
      if (coin.age + 1e-9 >= delay + coin.jump + coin.hold + coin.flight) {
        arrivedQuantity += collection.arrive(
          coin.collectionSlot,
          coin.collectionDay,
        );
        coin.active = false;
        _active--;
      }
    }
    if (_batchAmount > 0) {
      _batchAge += dt;
      if (_batchAge + 1e-9 >= config.window) _close();
    }
    _drain(allowEmission: allowEmission);
  }

  Map<String, dynamic> toJson() => {
    'counts': counts.map((key, value) => MapEntry('$key', value)),
    'batchAmount': _batchAmount,
    'batchAge': _batchAge,
    'collection': collection.toJson(),
  };
  void restoreCounts(Map<int, int> value) {
    counts
      ..clear()
      ..addAll(value);
  }

  void restorePresentation(Map<String, dynamic> json, {required int expected}) {
    final restored = CoinDenomination.readCounts(json['counts']);
    final amount = json['batchAmount'], age = json['batchAge'];
    if (amount is! int ||
        amount < 0 ||
        amount > 0x1fffffffffffff ||
        age is! num ||
        !age.isFinite ||
        age < 0 ||
        age > .5 ||
        (amount == 0 && age != 0) ||
        restored.entries.fold<int>(0, (sum, e) => sum + e.key * e.value) +
                amount !=
            expected) {
      throw const FormatException('Presentación de recompensas inválida');
    }
    restoreCounts(restored);
    _batchAmount = amount;
    // Restored money is settled by its ledger, not by replaying animations.
    _close(emit: false);
  }

  void receipt() => receiptPulse = .25;
  void stopEmitting() {
    _close(emit: false);
    _pending.clear();
    _pendingTimes.clear();
  }

  void clear({bool preserveCollection = false}) {
    stopEmitting();
    if (preserveCollection) {
      collection.resolve();
    } else {
      collection.begin(collection.day);
    }
    _lastArrival = clock;
    for (final coin in coins) {
      coin.active = false;
    }
    _active = 0;
    _pending.clear();
    _pendingTimes.clear();
    _load = 0;
    _lastEmission = -10;
    _nextEmission = clock;
    _recentAngles.clear();
    receiptPulse = 0;
  }
}
