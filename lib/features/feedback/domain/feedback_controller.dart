import 'dart:math' as math;
import 'feedback_config.dart';

enum FeedbackEvent {
  capture,
  coinOut,
  coinIn,
  collision,
  crystal,
  star,
  upgrade,
  quota,
  special,
  launcher,
  bat,
}

class SoundCue {
  const SoundCue(
    this.token,
    this.sample,
    this.gain,
    this.rate,
    this.priority,
    this.duration,
  );
  final int token, priority;
  final String sample;
  final double gain, rate, duration;
  Map<String, Object> toJson() => {
    'token': token,
    'sample': sample,
    'gain': gain,
    'rate': rate,
    'priority': priority,
    'duration': duration,
  };
}

class FeedbackBank {
  FeedbackBank(this.config, this.durations);
  final FeedbackConfig config;
  final Map<String, double> durations;
}

abstract interface class FeedbackBackend {
  String get status;
  Future<FeedbackBank?> prepare();
  void frame(
    List<SoundCue> play,
    List<int> stop,
    double absorb,
    double rolling,
    String? haptic,
  );
  void stop();
  void dispose();
}

class _Pending {
  int count = 0;
  double strength = 0;
}

class _Voice {
  _Voice(this.token, this.priority, this.end, this.gain);
  final int token, priority;
  final double end, gain;
}

/// Audio and haptics consume confirmed events, never physics or economic writes.
class FeedbackController {
  FeedbackController({
    required this.backend,
    FeedbackConfig config = const FeedbackConfig(),
  }) : _config = config;
  final FeedbackBackend backend;
  void Function()? onActivity;
  bool get audioEnabled => sound && volume > 0;
  bool get needsFrames =>
      !background &&
      (_pending.isNotEmpty ||
          _voices.isNotEmpty ||
          clock < _hapticAfter ||
          _next.values.any((t) => clock < t) ||
          (audioEnabled &&
              (absorb > .001 ||
                  rolling > .001 ||
                  (playing && (_captureDensity > .01 || _motion > .001)))));
  FeedbackConfig _config;
  int _configRevision = 0;
  FeedbackConfig get config => _config;
  set config(FeedbackConfig value) {
    _config = value;
    _configRevision++;
  }

  Map<String, double> _durations = {};
  bool _prepared = false, _disposed = false;
  bool playing = false, background = false, sound = true, haptics = true;
  double _sentAbsorb = 0, _sentRolling = 0;
  double volume = .8,
      clock = 0,
      _groupAge = 0,
      _captureDensity = 0,
      _motion = 0;
  double absorb = 0, rolling = 0, _hapticAfter = 0;
  int _pitchCounter = 0,
      _token = 0,
      _variant = 0,
      _tone = 0,
      played = 0,
      skipped = 0,
      hapticPulses = 0,
      peakVoices = 0;
  final _pending = <FeedbackEvent, _Pending>{};
  final _next = <FeedbackEvent, double>{};
  final _voices = <_Voice>[];
  int get activeVoices =>
      _voices.length +
      (sound && volume > 0 && playing
          ? (absorb > .002 ? 1 : 0) + (rolling > .002 ? 1 : 0)
          : 0);
  Future<void> prepare() async {
    if (_prepared || _disposed) return;
    _prepared = true;
    final revision = _configRevision;
    final bank = await backend.prepare();
    if (_disposed) return;
    if (bank == null) _prepared = false;
    if (bank != null) {
      if (revision == _configRevision) _config = bank.config;
      _durations = bank.durations;
    }
  }

  void preferences({
    required bool sound,
    required bool haptics,
    required double volume,
  }) {
    final changed = this.sound != sound || this.volume != volume;
    this.sound = sound;
    this.haptics = haptics;
    this.volume = volume;
    if (changed && (!sound || volume == 0)) {
      _voices.clear();
      backend.stop();
    }
  }

  void setPlaying(bool value) {
    if (playing == value) return;
    playing = value;
    if (!value) reset();
  }

  void setBackground(bool value) {
    background = value;
    if (value) reset();
  }

  void reset() {
    _pending.clear();
    _voices.clear();
    _next.clear();
    _groupAge = 0;
    _hapticAfter = clock;
    _captureDensity = _motion = absorb = rolling = 0;
    _sentAbsorb = _sentRolling = 0;
    backend.stop();
  }

  void motion(double activity) {
    _motion = activity.clamp(0, 1);
    if (_motion > .001 && playing && audioEnabled) onActivity?.call();
  }

  void emit(
    FeedbackEvent event, {
    int count = 1,
    double strength = 1,
    bool gameplay = true,
  }) {
    if (_disposed ||
        background ||
        (gameplay && !playing) ||
        count <= 0 ||
        (!audioEnabled && !haptics)) {
      return;
    }
    final p = _pending.putIfAbsent(event, _Pending.new);
    p.count = math.min(1000000, p.count + count);
    p.strength = math.max(p.strength, strength.clamp(0, 1));
    if (event == FeedbackEvent.capture) {
      _captureDensity = math.min(
        config['massRate'] * config['captureWindow'] * 2,
        _captureDensity + count,
      );
    }
    onActivity?.call();
  }

  static int priority(FeedbackEvent e) => switch (e) {
    FeedbackEvent.star => 100,
    FeedbackEvent.upgrade => 90,
    FeedbackEvent.quota => 85,
    FeedbackEvent.special => 75,
    FeedbackEvent.capture => 65,
    FeedbackEvent.bat => 60,
    FeedbackEvent.coinIn => 50,
    FeedbackEvent.coinOut => 30,
    FeedbackEvent.crystal => 25,
    FeedbackEvent.launcher => 20,
    FeedbackEvent.collision => 10,
  };
  double cooldown(FeedbackEvent e) => switch (e) {
    FeedbackEvent.capture =>
      .045 + .065 * (_captureDensity / config['massRate']).clamp(0, 1),
    FeedbackEvent.coinIn => .075,
    FeedbackEvent.coinOut => .09,
    FeedbackEvent.star || FeedbackEvent.upgrade || FeedbackEvent.quota => .12,
    _ => .09,
  };
  String sample(FeedbackEvent e, int count) => switch (e) {
    FeedbackEvent.capture => 'plop${_variant++ % 6}',
    FeedbackEvent.coinIn => 'coin${count > 1 ? _tone++ % 5 : _variant++ % 5}',
    FeedbackEvent.coinOut => 'coinout${_variant++ % 2}',
    FeedbackEvent.star => 'star',
    FeedbackEvent.crystal => 'crystal',
    FeedbackEvent.upgrade => 'upgrade',
    FeedbackEvent.quota => 'quota',
    FeedbackEvent.special => 'special',
    _ => 'impact${_variant++ % 3}',
  };
  double gain(FeedbackEvent e) => switch (e) {
    FeedbackEvent.capture => config['captureGain'],
    FeedbackEvent.coinIn || FeedbackEvent.coinOut =>
      config['coinGain'] * (e == FeedbackEvent.coinOut ? .5 : 1),
    FeedbackEvent.star || FeedbackEvent.crystal =>
      config['starGain'] * (e == FeedbackEvent.crystal ? .2 : 1),
    FeedbackEvent.upgrade ||
    FeedbackEvent.quota ||
    FeedbackEvent.special => config['upgradeGain'],
    _ => config['impactGain'],
  };
  void advance(double dt) {
    if (_disposed || background || !dt.isFinite || dt <= 0) return;
    dt = dt.clamp(0, .1);
    clock += dt;
    _groupAge += dt;
    _voices.removeWhere((v) => v.end <= clock);
    final rate = _captureDensity / config['captureWindow'];
    final target = playing
        ? ((rate - config['frequentRate']) /
                  (config['massRate'] - config['frequentRate']))
              .clamp(0.0, 1.0)
        : 0.0;
    final k = target > absorb ? config['attack'] : config['release'];
    absorb += (target - absorb) * (1 - math.exp(-k * dt));
    rolling +=
        ((playing ? _motion : 0) - rolling) *
        (1 - math.exp(-config['release'] * dt));
    _captureDensity *= math.exp(-dt / config['captureWindow']);
    if (_groupAge + 1e-9 < config['groupWindow']) return;
    _groupAge = 0;
    final play = <SoundCue>[], stop = <int>[];
    final events = _pending.keys.toList()
      ..sort((a, b) => priority(b).compareTo(priority(a)));
    String? pulse;
    for (final e in events) {
      final p = _pending[e]!;
      if (clock < (_next[e] ?? 0)) {
        skipped++;
        continue;
      }
      _next[e] = clock + cooldown(e);
      if (haptics &&
          pulse == null &&
          clock >= _hapticAfter &&
          [
            FeedbackEvent.capture,
            FeedbackEvent.coinIn,
            FeedbackEvent.star,
            FeedbackEvent.upgrade,
            FeedbackEvent.quota,
            FeedbackEvent.bat,
          ].contains(e)) {
        pulse = priority(e) >= 85 ? 'reward' : 'light';
        _hapticAfter =
            clock + config['hapticInterval'] * (p.count > 3 ? 1.5 : 1);
        hapticPulses++;
      }
      if (!sound || volume <= 0 || gain(e) <= 0) continue;
      final maximum = config['maxVoices'].toInt() - 2;
      if (_voices.length >= maximum) {
        final weakest = _voices.reduce(
          (a, b) => a.priority < b.priority ? a : b,
        );
        if (weakest.priority >= priority(e)) {
          skipped++;
          continue;
        }
        stop.add(weakest.token);
        _voices.remove(weakest);
      }
      final key = sample(e, p.count),
          variation =
              ((_pitchCounter++ * 37 % 101) / 50 - 1) *
              config['pitchVariation'];
      final pitch = e == FeedbackEvent.coinIn ? 1.0 : 1 + variation;
      final duration = (_durations[key] ?? .36) / pitch + .025;
      final density = e == FeedbackEvent.capture
          ? 1 - .45 * (_captureDensity / config['massRate']).clamp(0.0, 1.0)
          : 1.0;
      final desired =
          gain(e) *
          (1 + math.log(1 + p.count) * .08) *
          p.strength *
          density *
          volume;
      final budget = .85 * volume;
      double used() => _voices.fold<double>(0, (sum, v) => sum + v.gain);
      while (budget - used() < desired * .6 &&
          _voices.any((v) => v.priority < priority(e))) {
        final weak = _voices
            .where((v) => v.priority < priority(e))
            .reduce((a, b) => a.priority < b.priority ? a : b);
        stop.add(weak.token);
        _voices.remove(weak);
      }
      final level = math.min(desired, math.max(0.0, budget - used()));
      if (level <= 0) continue;
      final token = ++_token;
      play.add(SoundCue(token, key, level, pitch, priority(e), duration));
      _voices.add(_Voice(token, priority(e), clock + duration, level));
      played++;
    }
    _pending.clear();
    final enabled = sound && volume > 0 && playing;
    final rawA = enabled ? absorb * config['absorbGain'] * volume : 0.0;
    final rawR = enabled ? rolling * config['rollingGain'] * volume : 0.0;
    final a = rawA > .0005 ? rawA : 0.0, r = rawR > .0005 ? rawR : 0.0;
    if (play.isNotEmpty ||
        stop.isNotEmpty ||
        pulse != null ||
        (a - _sentAbsorb).abs() > .0005 ||
        (r - _sentRolling).abs() > .0005 ||
        (a < .0005 && _sentAbsorb > 0) ||
        (r < .0005 && _sentRolling > 0)) {
      _sentAbsorb = a;
      _sentRolling = r;
      backend.frame(play, stop, a, r, pulse);
    }
    peakVoices = math.max(peakVoices, activeVoices);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    backend.dispose();
  }
}
