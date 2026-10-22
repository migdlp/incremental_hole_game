import 'dart:math' as math;

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
  static double jump(int id) => .24 + (id * 17 % 13) * .009;
  static double flight(int id) => .58 + (id * 23 % 17) * .012;

  int register(int amount) {
    if (amount <= 0) throw ArgumentError('Recompensa inválida');
    final id = nextId++;
    final arrival = clock + delay + jump(id) + flight(id);
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
          arrival > clock + delay + 2) {
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
  int id = 0, amount = 0;
  double age = 0, jump = 0, flight = 0;
  double dx = 0, dy = 0, bend = 0;
  void reset(int rewardId, int value) {
    active = true;
    id = rewardId;
    amount = value;
    age = 0;
    jump = RewardDelivery.jump(id);
    flight = RewardDelivery.flight(id);
    dx = (id.isEven ? 1 : -1) * (18 + id * 13 % 27).toDouble();
    dy = (id % 3 == 0 ? -1 : 1) * (8 + id * 7 % 17).toDouble();
    bend = (id.isEven ? 1 : -1) * (22 + id * 11 % 38).toDouble();
  }

  // Scalar polynomial curves, without trig or allocating vectors every frame.
  double x(double target, double delay, {double origin = 180}) {
    final t = age - delay;
    if (t <= 0) return origin;
    if (t < jump) return origin + dx * (t / jump);
    final u = ((t - jump) / flight).clamp(0.0, 1.0);
    final eased = u * u * (3 - 2 * u);
    return origin +
        dx +
        (target - origin - dx) * eased +
        bend * u * (1 - u) * (1 - 2 * u);
  }

  double y(double target, double delay, {double origin = 50}) {
    final t = age - delay;
    if (t <= 0) return origin;
    if (t < jump) {
      final u = t / jump;
      return origin + dy * u - (23 + id % 7) * 4 * u * (1 - u);
    }
    final u = ((t - jump) / flight).clamp(0.0, 1.0);
    final eased = u * u * (3 - 2 * u);
    return origin + dy + (target - origin - dy) * eased - bend * u * (1 - u);
  }
}

class RewardVisuals {
  RewardVisuals(this.capacity, this.delay)
    : coins = List.generate(capacity, (_) => RewardCoin());
  final int capacity;
  final double delay;
  final List<RewardCoin> coins;
  int? debugLimit;
  int grouped = 0, omitted = 0, peak = 0;
  int get activeCount => coins.where((c) => c.active).length;
  int get limit => debugLimit ?? _adaptiveLimit;
  late int _adaptiveLimit = capacity;
  double _recovery = 0;
  double receiptPulse = 0;
  void observeFrame(double dt) {
    if (dt > 1 / 40) {
      _adaptiveLimit = math.max(1, _adaptiveLimit ~/ 2);
      _recovery = 0;
    } else if (dt < 1 / 55) {
      _recovery += dt;
      if (_recovery > 2) {
        _adaptiveLimit = math.min(capacity, _adaptiveLimit + 1);
        _recovery = 0;
      }
    }
  }

  void add(int id, int amount) {
    RewardCoin? grouping;
    var count = 0;
    for (final coin in coins) {
      if (coin.active) {
        count++;
        // Only coalesce waiting coins: do not teleport a coin already in flight.
        if (coin.age < delay) grouping = coin;
      }
    }
    if (count < limit) {
      for (final coin in coins) {
        if (!coin.active) {
          coin.reset(id, amount);
          peak = math.max(peak, count + 1);
          return;
        }
      }
    }
    if (grouping != null) {
      grouping.amount += amount;
      grouped++;
    } else {
      omitted++;
    }
  }

  void advance(double dt) {
    receiptPulse = math.max(0, receiptPulse - dt);
    for (final coin in coins) {
      if (!coin.active) continue;
      coin.age += dt;
      if (coin.age + 1e-9 >= delay + coin.jump + coin.flight) {
        coin.active = false;
      }
    }
  }

  void receipt() => receiptPulse = .25;
  void clear() {
    for (final coin in coins) {
      coin.active = false;
    }
    receiptPulse = 0;
  }
}
