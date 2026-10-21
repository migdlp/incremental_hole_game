import 'dart:math' as math;

/// Provisional BAL01 parameters, shared by simulation and DEBUG.
class StarConfig {
  StarConfig(Map<String, double> values)
    : values = Map.unmodifiable({
        for (final key in ranges.keys)
          if (values.containsKey(key)) key: values[key]!,
      }) {
    for (final entry in ranges.entries) {
      final n = values[entry.key];
      if (n == null ||
          !n.isFinite ||
          n < entry.value.$1 ||
          n > entry.value.$2 ||
          (integers.contains(entry.key) && n != n.roundToDouble())) {
        throw FormatException('Parámetro de burbujas inválido: ${entry.key}');
      }
    }
  }
  final Map<String, double> values;
  double operator [](String key) => values[key]!;
  static const integers = {
    'star_count',
    'star_categories',
    'star_value',
    'star_category_periods',
    'star_active_limit',
    'star_color',
  };
  static const ranges = <String, (double, double)>{
    'star_count': (1, 8),
    'star_categories': (1, 5),
    'star_value': (1, 1000),
    'star_value_growth': (1, 10),
    'star_category_periods': (1, 20),
    'star_diameter_ratio': (2, 3),
    'star_size_growth': (1.10, 1.15),
    'star_eject_speed': (20, 300),
    'star_buoyancy': (1, 100),
    'star_damping': (.05, 3),
    'star_restitution': (.1, .95),
    'star_break_speed': (20, 350),
    'star_active_limit': (1, 24),
    'star_reentry_interval': (.1, 3),
    'star_color': (0, 359),
  };
  int category(int period) => math.min(
    (period - 1) ~/ this['star_category_periods'].toInt(),
    this['star_categories'].toInt() - 1,
  );
  int value(int category) =>
      (this['star_value'] * math.pow(this['star_value_growth'], category))
          .round();
  double radius(double ballRadius, int category) =>
      ballRadius *
      this['star_diameter_ratio'] *
      math.pow(this['star_size_growth'], category);
  StarConfig changed(String key, double value) =>
      StarConfig({...values, key: value});
  Map<String, double> toJson() => Map.of(values);
  factory StarConfig.fromJson(Map<String, dynamic> json) =>
      StarConfig(json.map((k, v) => MapEntry(k, (v as num).toDouble())));
}

class StarReward {
  const StarReward(this.id, this.category, this.value);
  final int id, category, value;
  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'value': value,
  };
  factory StarReward.fromJson(Map<String, dynamic> json) {
    final id = json['id'], category = json['category'], value = json['value'];
    if (id is! int ||
        id < 1 ||
        category is! int ||
        category < 0 ||
        category > 4 ||
        value is! int ||
        value < 1 ||
        value > 10000000) {
      throw const FormatException('Recompensa de estrellas inválida');
    }
    return StarReward(id, category, value);
  }
}

/// Run-scoped entitlement ledger, independent of visible bodies and animations.
/// A quota high-water mark and removal on payment make both operations idempotent.
class StarLedger {
  const StarLedger({this.quota = 0, this.nextId = 1, this.pending = const []});
  final int quota, nextId;
  final List<StarReward> pending;
  StarLedger award(int period, StarConfig config) {
    if (period <= quota) return this;
    final category = config.category(period);
    final count = config['star_count'].toInt();
    return StarLedger(
      quota: period,
      nextId: nextId + count,
      pending: List.unmodifiable([
        ...pending,
        for (var i = 0; i < count; i++)
          StarReward(nextId + i, category, config.value(category)),
      ]),
    );
  }

  ({StarLedger ledger, int paid}) redeem(Iterable<int> ids) {
    final unique = ids.toSet();
    final paid = pending
        .where((p) => unique.contains(p.id))
        .fold(0, (int n, p) => n + p.value);
    return (
      ledger: StarLedger(
        quota: quota,
        nextId: nextId,
        pending: List.unmodifiable(
          pending.where((p) => !unique.contains(p.id)),
        ),
      ),
      paid: paid,
    );
  }

  Map<String, dynamic> toJson() => {
    'quota': quota,
    'nextId': nextId,
    'pending': pending.map((p) => p.toJson()).toList(),
  };
  factory StarLedger.fromJson(Map<String, dynamic> json) {
    final quota = json['quota'], next = json['nextId'], rows = json['pending'];
    if (quota is! int ||
        quota < 0 ||
        quota > 0x1fffffffffffff ||
        next is! int ||
        next < 1 ||
        next > 0x1fffffffffffff ||
        rows is! List) {
      throw const FormatException('Registro de estrellas inválido');
    }
    final pending = rows
        .map((p) => StarReward.fromJson(p as Map<String, dynamic>))
        .toList();
    if (pending.any((p) => p.id >= next) ||
        pending.map((p) => p.id).toSet().length != pending.length) {
      throw const FormatException('Identidad de estrellas inválida');
    }
    return StarLedger(
      quota: quota,
      nextId: next,
      pending: List.unmodifiable(pending),
    );
  }
}
