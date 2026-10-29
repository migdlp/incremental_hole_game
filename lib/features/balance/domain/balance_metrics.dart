import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Stable JSON and digest. Domain counters never draw gameplay randomness.
Object? canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: canonical(value[key])};
  }
  if (value is Iterable) return value.map(canonical).toList();
  if (value is BigInt) return value.toString();
  if (value is num) {
    final bytes = ByteData(8)..setFloat64(0, value.toDouble(), Endian.big);
    return {
      '#f64': [
        for (var i = 0; i < 8; i++)
          bytes.getUint8(i).toRadixString(16).padLeft(2, '0'),
      ].join(),
    };
  }
  return value;
}

String configurationHash(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(canonical(value)))).toString();

/// One board/day; bounded by physical population, fixed source/reason vocabulary.
/// Time resolution is an update (normally 1/60 s), not a physical contact timestamp.
class BoardMetrics {
  BoardMetrics({this.enabled = true});
  final bool enabled;
  final counts = <String, int>{};
  final births = <int, (String, double)>{};
  double elapsed = 0, lifetimeSum = 0, radiusMax = 0;
  int peak = 0, initial = 0, capturedBaseline = 0;
  bool partial = false;
  int get emitted => count('emitted');
  int count(String key) => counts[key] ?? 0;
  void add(String key, [int amount = 1]) {
    if (enabled) counts.update(key, (n) => n + amount, ifAbsent: () => amount);
  }

  void birth(int id, String source, int population) {
    if (!enabled) return;
    births[id] = (source, elapsed);
    add('emitted');
    add('emitted.$source');
    peak = math.max(peak, population);
  }

  void capture(
    int id, {
    required bool instant,
    required bool golden,
    required bool heavy,
    required int base,
    required int combo,
    required int reward,
  }) {
    if (!enabled) return;
    final birth = births.remove(id);
    add('captured');
    add(instant ? 'captured_instant' : 'captured_ordinary');
    add('captured.${birth?.$1 ?? 'unknown'}');
    if (golden) add('golden_captured');
    if (heavy) add('heavy_captured');
    add('coins_base', base);
    add('coins_combo_golden', combo);
    add('coins_e03_bonus', reward - combo);
    if (birth == null) {
      add('age_unknown');
    } else {
      final age = math.max(0.0, elapsed - birth.$2);
      lifetimeSum += age;
      add('age_known');
      add(
        'age_bin_${age < 1
            ? 'lt1'
            : age < 5
            ? '1to5'
            : age < 15
            ? '5to15'
            : 'ge15'}',
      );
    }
  }

  void advance(double dt, double radius, String tool, int population) {
    if (!enabled) return;
    elapsed += dt;
    radiusMax = math.max(radiusMax, radius);
    peak = math.max(peak, population);
    add('tool_us.$tool', (dt * 1e6).round());
  }

  Map<String, Object?> report(int live) => {
    'counts': {for (final e in counts.entries) e.key: '${e.value}'},
    'initial': '$initial',
    'live': '$live',
    'peak': '$peak',
    'captured_baseline': '$capturedBaseline',
    'partial': partial,
    'active_sim_s': elapsed,
    'radius_max': radiusMax,
    'lifetime_sum_s': lifetimeSum,
    'age_censored': '${births.length}',
    'age_live_unknown': '${math.max(0, live - births.length)}',
    'validation': [
      if (!partial &&
          initial + emitted + count('debug_injected') !=
              count('captured') + live)
        'ball_conservation',
      if (count('captured') !=
          count('captured_ordinary') + count('captured_instant'))
        'capture_split',
    ],
  };
  Map<String, Object?> toJson() => {
    ...report(0),
    'births': {
      for (final e in births.entries) '${e.key}': [e.value.$1, e.value.$2],
    },
  };
  static BoardMetrics restore(
    Object? raw, {
    required List<int> liveIds,
    required int captured,
  }) {
    try {
      final j = raw as Map<String, dynamic>;
      final m = BoardMetrics();
      final c = j['counts'] as Map<String, dynamic>;
      if (c.length > 256) throw const FormatException('metric counts');
      for (final e in c.entries) {
        final n = int.parse(e.value as String);
        if (n < 0 || n > 0x1fffffffffffff || e.key.length > 80) {
          throw const FormatException('metric count');
        }
        m.counts[e.key] = n;
      }
      m.initial = int.parse(j['initial'] as String);
      m.capturedBaseline = int.parse(j['captured_baseline'] as String);
      m.peak = int.parse(j['peak'] as String);
      m.partial = j['partial'] as bool;
      m.elapsed = (j['active_sim_s'] as num).toDouble();
      m.radiusMax = (j['radius_max'] as num).toDouble();
      m.lifetimeSum = (j['lifetime_sum_s'] as num).toDouble();
      if ([
            m.elapsed,
            m.radiusMax,
            m.lifetimeSum,
          ].any((x) => !x.isFinite || x < 0) ||
          m.initial < 0 ||
          m.peak < 0 ||
          m.count('captured') + m.capturedBaseline != captured) {
        throw const FormatException('metric scope');
      }
      final b = j['births'] as Map<String, dynamic>;
      if (b.length > liveIds.length) {
        throw const FormatException('metric births');
      }
      final ids = liveIds.toSet();
      for (final e in b.entries) {
        final id = int.parse(e.key), row = e.value as List;
        final source = row[0] as String, time = (row[1] as num).toDouble();
        if (!ids.contains(id) ||
            source.length > 32 ||
            !time.isFinite ||
            time < 0 ||
            time > m.elapsed) {
          throw const FormatException('metric birth');
        }
        m.births[id] = (source, time);
      }
      if (!m.partial &&
          m.emitted + m.initial + m.count('debug_injected') !=
              captured + liveIds.length) {
        throw const FormatException('metric conservation');
      }
      return m;
    } catch (_) {
      return BoardMetrics()
        ..partial = true
        ..initial = liveIds.length
        ..peak = liveIds.length
        ..capturedBaseline = captured;
    }
  }
}

/// Local evaluation history. It observes transactions and has no game authority.
class BalanceLab {
  static const schema = 'bal_metrics/1.0.0';
  static const maxDays = 500, maxEvents = 2000;
  static const version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.24.0+38',
  );
  static const commit = String.fromEnvironment(
    'SOURCE_COMMIT',
    defaultValue: 'unknown',
  );
  final days = <Map<String, dynamic>>[];
  final events = <Map<String, dynamic>>[];
  Map<String, dynamic>? _active;
  String? _encoded;
  Map<String, dynamic>? get active => _active;
  set active(Map<String, dynamic>? value) {
    _active = value == null ? null : _freeze(value);
    _encoded = null;
  }

  String checkpoint() => _encoded ??= jsonEncode(toJson());
  int sequence = 0, droppedDays = 0, droppedEvents = 0;
  bool recovered = false;
  int _dayBytes = 0, _eventBytes = 0;
  static Map<String, dynamic> _freeze(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  static int _bytes(Object? value) => utf8.encode(jsonEncode(value)).length;
  void _trim() {
    // Keep histories under 4 MiB, reserving 1 MiB for an active row/metadata.
    while (_dayBytes + _eventBytes > 4 * 1024 * 1024 &&
        (days.isNotEmpty || events.isNotEmpty)) {
      if (days.isNotEmpty && (_dayBytes >= _eventBytes || events.isEmpty)) {
        _dayBytes -= _bytes(days.removeAt(0));
        droppedDays++;
      } else {
        _eventBytes -= _bytes(events.removeAt(0));
        droppedEvents++;
      }
    }
  }

  void event(String type, Map<String, dynamic> data) {
    _encoded = null;
    events.add(_freeze({'seq': ++sequence, 'type': type, ...data}));
    _eventBytes += _bytes(events.last);
    if (events.length > maxEvents) {
      _eventBytes -= _bytes(events.removeAt(0));
      droppedEvents++;
    }
    _trim();
  }

  void finish(Map<String, dynamic> row) {
    if (days.any((d) => d['id'] == row['id'])) return;
    final frozen = _freeze(row);
    days.add(frozen);
    _dayBytes += _bytes(frozen);
    if (days.length > maxDays) {
      _dayBytes -= _bytes(days.removeAt(0));
      droppedDays++;
    }
    active = null;
    _trim();
  }

  Map<String, dynamic> toJson() => {
    'schema_version': schema,
    'days': days,
    'events': events,
    'active': active,
    'sequence': sequence,
    'dropped_days': droppedDays,
    'dropped_events': droppedEvents,
    'recovered': recovered,
  };
  static BalanceLab restore(Object? raw) {
    try {
      final j = raw as Map<String, dynamic>;
      if (j['schema_version'] != schema) throw const FormatException('schema');
      final lab = BalanceLab();
      final ds = (j['days'] as List).cast<Map<String, dynamic>>();
      final es = (j['events'] as List).cast<Map<String, dynamic>>();
      if (ds.length > maxDays ||
          es.length > maxEvents ||
          jsonEncode(j).length > 5 * 1024 * 1024) {
        throw const FormatException('retention');
      }
      lab.days.addAll(ds);
      lab.events.addAll(es);
      lab._dayBytes = ds.fold(0, (n, d) => n + _bytes(d));
      lab._eventBytes = es.fold(0, (n, e) => n + _bytes(e));
      lab.active = j['active'] as Map<String, dynamic>?;
      final current = lab.active;
      if (current != null &&
          (current['id'] is! String ||
              current['run_id'] is! String ||
              current['day'] is! int ||
              current['test_kind'] is! String ||
              current['quota_start'] is! Map ||
              (current['quota_start'] as Map)['period'] is! int ||
              (current['quota_start'] as Map)['period'] < 1)) {
        throw const FormatException('active metrics scope');
      }

      lab.sequence = j['sequence'] as int;
      lab.droppedDays = j['dropped_days'] as int;
      lab.droppedEvents = j['dropped_events'] as int;
      lab.recovered = j['recovered'] as bool;
      // Validate exported fields before metrics can be used by any view.
      for (final d in lab.days) {
        _cells(d);
        BigInt.parse(d['coins_earned'] as String);
        d['test_kind'] as String;
      }
      lab._trim();
      return lab;
    } catch (_) {
      return BalanceLab()..recovered = true;
    }
  }

  Map<String, dynamic> export({
    Map<String, dynamic>? current,
    Map<String, Object?> context = const {},
  }) => {
    ...toJson(),
    'metadata': {'app_version': version, 'source_commit': commit, ...context},
    'active': current ?? active,
    'coverage': {
      'retained_days': days.length,
      'dropped_days': droppedDays,
      'dropped_events': droppedEvents,
      'recovered_or_legacy': recovered,
    },
  };
  String json({
    Map<String, dynamic>? current,
    Map<String, Object?> context = const {},
  }) => const JsonEncoder.withIndent(
    '  ',
  ).convert(export(current: current, context: context));
  static const headers = [
    'id',
    'test_kind',
    'run_id',
    'day',
    'app_version',
    'source_commit',
    'configuration_sha256',
    'emitted',
    'captured',
    'live',
    'peak',
    'coins_earned',
    'coins_collected',
    'quota_completed',
    'end_reason',
    'partial',
    'capture_rate',
    'schema_version',
    'seed_set_json',
    'build_mode',
    'platform',
  ];
  static List<Object?> _cells(Map<String, dynamic> d) {
    final b = d['board'] as Map, c = b['counts'] as Map;
    final emitted = BigInt.parse('${c['emitted'] ?? '0'}');
    final captured = BigInt.parse('${c['captured'] ?? '0'}');
    final full =
        b['partial'] == false &&
        b['initial'] == '0' &&
        (c['debug_injected'] ?? '0') == '0' &&
        (b['validation'] as List).isEmpty;
    return [
      d['id'],
      d['test_kind'],
      d['run_id'],
      d['day'],
      d['app_version'],
      d['source_commit'],
      d['configuration_sha256'],
      c['emitted'] ?? '0',
      c['captured'] ?? '0',
      b['live'],
      b['peak'],
      d['coins_earned'],
      d['coins_collected'],
      d['quota_completed'],
      d['end_reason'],
      b['partial'],
      full && emitted > BigInt.zero
          ? captured.toDouble() / emitted.toDouble()
          : null,
      schema,
      jsonEncode(d['rng_initial']),
      d['build_mode'],
      d['platform'],
    ];
  }

  String get csv {
    String cell(Object? x) =>
        x == null ? '' : '"${x.toString().replaceAll('"', '""')}"';
    return [
      headers,
      ...days.map(_cells),
    ].map((row) => row.map(cell).join(',')).join('\r\n');
  }

  String get summary {
    final groups = <String, List<BigInt>>{};
    for (final d in days) {
      final c = (d['board'] as Map)['counts'] as Map;
      final values = groups.putIfAbsent(
        d['test_kind'] as String,
        () => List.filled(4, BigInt.zero),
      );
      values[0] += BigInt.one;
      values[1] += BigInt.parse('${c['emitted'] ?? 0}');
      values[2] += BigInt.parse('${c['captured'] ?? 0}');
      values[3] += BigInt.parse('${d['coins_earned']}');
    }
    final last = days.isEmpty ? null : days.last;
    final rng = last?['rng_initial'] as Map?;
    return '${days.length} jornadas retenidas\n'
        '${groups.entries.map((e) => '${e.key}: ${e.value[0]} jornadas · ${e.value[1]} emitidas · ${e.value[2]} capturadas · ${e.value[3]} monedas').join('\n')}\n'
        'Esquema $schema · exportador $version / $commit\n'
        'Última jornada: ${last?['id'] ?? 'ninguna'} · config ${last?['configuration_sha256'] ?? 'unknown'}\n'
        'RNG inicial última jornada: Board ${rng?['board'] ?? 'unknown'}, Launcher ${rng?['launcher'] ?? 'unknown'}, sesión ${rng?['session_events'] ?? 'unknown'}. Estados completos en JSON/CSV.\n'
        'Descartadas por retención: $droppedDays jornadas, $droppedEvents eventos.\n'
        'Cobertura recuperada/legacy: $recovered. Ver validación por jornada.\n'
        'Los contactos y usos observados no prueban efectos causales.';
  }
}
