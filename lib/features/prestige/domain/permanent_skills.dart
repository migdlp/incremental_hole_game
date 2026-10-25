/// P02 initial approved catalogue. One purchase, no levels or prerequisites.
class PermanentSkill {
  const PermanentSkill(this.id, this.name, this.description, this.price);
  final String id, name, description;
  final int price;
  static const inheritance = 'H01', echo = 'H02', gold = 'H04', astral = 'H13';
  static const catalogue = [
    PermanentSkill(
      inheritance,
      'Herencia',
      'Comienza cada partida con 100 monedas.',
      2,
    ),
    PermanentSkill(
      echo,
      'Eco de producción',
      'Genera 5 bolas adicionales cada 20 ciclos del generador principal.',
      6,
    ),
    PermanentSkill(
      gold,
      'Fiebre dorada',
      'Una bola dorada adicional en un momento aleatorio de cada jornada.',
      8,
    ),
    PermanentSkill(
      astral,
      'Lluvia astral',
      '50 % de probabilidad de duplicar las burbujas de cada cuota.',
      12,
    ),
  ];
  static PermanentSkill? find(String id) =>
      catalogue.where((s) => s.id == id).firstOrNull;
}

/// Temporary state, shared across boards of one run, never across prestige.
class PermanentRun {
  int cycles = 0, pendingEcho = 0;
  double elapsed = 0;
  double? goldenAt;
  bool goldenSpawned = false;
  void beginDay({double? goldenTime}) {
    elapsed = 0;
    goldenAt = goldenTime;
    goldenSpawned = false;
  }

  void cycle({required bool echo}) {
    if (!echo) return;
    cycles = (cycles + 1) % 20;
    if (cycles == 0) pendingEcho += 5;
  }

  Map<String, dynamic> toJson() => {
    'cycles': cycles,
    'pendingEcho': pendingEcho,
    'elapsed': elapsed,
    'goldenAt': goldenAt,
    'goldenSpawned': goldenSpawned,
  };
  factory PermanentRun.fromJson(Map<String, dynamic> json) {
    final cycles = json['cycles'], pending = json['pendingEcho'];
    final elapsed = json['elapsed'],
        at = json['goldenAt'],
        spawned = json['goldenSpawned'];
    if (cycles is! int ||
        cycles < 0 ||
        cycles >= 20 ||
        pending is! int ||
        pending < 0 ||
        pending > 0x1fffffffffffff ||
        elapsed is! num ||
        !elapsed.isFinite ||
        elapsed < 0 ||
        (at != null && (at is! num || !at.isFinite || at < 0)) ||
        spawned is! bool ||
        (spawned && at == null)) {
      throw const FormatException('Estado temporal de prestigio inválido');
    }
    return PermanentRun()
      ..cycles = cycles
      ..pendingEcho = pending
      ..elapsed = elapsed.toDouble()
      ..goldenAt = (at as num?)?.toDouble()
      ..goldenSpawned = spawned;
  }
  PermanentRun();
}
