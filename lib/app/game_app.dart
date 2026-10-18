import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/board/presentation/garden_game.dart';
import '../features/board/domain/tool.dart';
import '../features/day_cycle/domain/day_cycle.dart';
import '../features/upgrades/domain/catalog.dart';
import 'game_session.dart';

const ink = Color(0xff111c2e);
const surface = Color(0xff23334b);
const cream = Color(0xfff8f3e8);
const gold = Color(0xfff5b83d);
const teal = Color(0xff247d73);

class GardenApp extends StatelessWidget {
  const GardenApp({super.key, required this.session});
  final GameSession session;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Jardín mecánico',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: Color(0xff69b4a5),
        surface: surface,
        onSurface: cream,
      ),
      useMaterial3: true,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    home: SessionScreen(session: session),
  );
}

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.session});
  final GameSession session;
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) widget.session.pause();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                if (widget.session.saveError != null)
                  MaterialBanner(
                    content: Text(widget.session.saveError!),
                    actions: [
                      TextButton(
                        onPressed: () => unawaited(widget.session.save()),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                Expanded(
                  child: widget.session.running
                      ? DayScreen(session: widget.session)
                      : NightScreen(session: widget.session),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class DayScreen extends StatefulWidget {
  const DayScreen({super.key, required this.session});
  final GameSession session;
  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  late final GardenGame game = GardenGame(widget.session);
  int? pointer;
  int lastIncome = 0;
  DateTime lastSound = DateTime(2000);
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_changes);
  }

  void _changes() {
    if (widget.session.paused) pointer = null;
    if (widget.session.economy.collected > lastIncome &&
        widget.session.sound &&
        DateTime.now().difference(lastSound).inMilliseconds > 150) {
      unawaited(SystemSound.play(SystemSoundType.click));
      lastSound = DateTime.now();
    }
    lastIncome = widget.session.economy.collected;
  }

  @override
  void dispose() {
    widget.session.removeListener(_changes);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final closing = session.phase == DayPhase.closing;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DÍA ${session.progress.day}',
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Color(0xffb5bdc9),
                      ),
                    ),
                    Text(
                      '${session.cycle!.remaining.ceil()} s',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: closing ? const Color(0xffffae83) : cream,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.monetization_on_rounded, color: gold, size: 27),
              const SizedBox(width: 7),
              Text(
                '${session.economy.collected}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Pausar',
                onPressed: session.pause,
                icon: const Icon(Icons.pause_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value:
                  (session.cycle!.remaining /
                          (session.cycle!.production + session.cycle!.closing))
                      .clamp(0, 1),
              minHeight: 5,
              backgroundColor: surface,
              color: closing
                  ? const Color(0xffd1764c)
                  : const Color(0xff69b4a5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 5),
          child: Text(
            closing
                ? 'ÚLTIMOS SEGUNDOS · Recoge las monedas'
                : session.economy.generated > 0
                ? (session.board!.sweepEnabled
                      ? 'Toca o desliza para recoger las monedas'
                      : 'Pulsa las monedas para recogerlas')
                : session.selectedTool == BallTool.hand
                ? 'Agarra una bola · Arrastra y suelta para lanzar'
                : 'Barre hacia donde arrastras el dedo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: closing
                  ? const Color(0xffffae83)
                  : const Color(0xffc6cfdb),
            ),
          ),
        ),
        ToolSelector(session: session),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown: (event) {
                    if (pointer != null || session.paused) return;
                    final point = game.boardPoint(event.localPosition);
                    if (point == null) return;
                    pointer = event.pointer;
                    session.touch(
                      point,
                      time: event.timeStamp.inMicroseconds / 1e6,
                    );
                  },
                  onPointerMove: (event) {
                    if (event.pointer != pointer || session.paused) return;
                    final point = game.boardPoint(event.localPosition);
                    if (point != null) {
                      session.drag(
                        point,
                        time: event.timeStamp.inMicroseconds / 1e6,
                      );
                    } else {
                      pointer = null;
                      session.release(cancel: true);
                    }
                  },
                  onPointerUp: (event) {
                    if (event.pointer == pointer) {
                      pointer = null;
                      final point = game.boardPoint(event.localPosition);
                      if (point != null) {
                        session.drag(
                          point,
                          time: event.timeStamp.inMicroseconds / 1e6,
                        );
                      }
                      session.release(
                        cancel: point == null,
                        time: event.timeStamp.inMicroseconds / 1e6,
                      );
                    }
                  },
                  onPointerCancel: (event) {
                    if (event.pointer == pointer) {
                      pointer = null;
                      session.release(cancel: true);
                    }
                  },
                  child: GameWidget(game: game),
                ),
              ),
              if (session.paused)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xc0111c2e),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.nights_stay_outlined,
                                  size: 40,
                                  color: gold,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Un pequeño descanso',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'El tiempo está detenido. Tu jardín te espera.',
                                  textAlign: TextAlign.center,
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Sonidos del sistema'),
                                  value: session.sound,
                                  onChanged: session.setSound,
                                ),
                                FilledButton.icon(
                                  onPressed: session.resume,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Continuar'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class NightScreen extends StatelessWidget {
  const NightScreen({super.key, required this.session});
  final GameSession session;
  @override
  Widget build(BuildContext context) {
    final last = session.progress.last;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.spa_outlined,
                    color: Color(0xff69b4a5),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'JARDÍN MECÁNICO',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: session.sound
                        ? 'Silenciar sonidos'
                        : 'Activar sonidos',
                    onPressed: () => session.setSound(!session.sound),
                    icon: Icon(
                      session.sound
                          ? Icons.volume_up_outlined
                          : Icons.volume_off_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                last == null
                    ? 'Un pequeño gesto.\nUn jardín que crece.'
                    : 'La noche trae\nnuevas posibilidades.',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                last == null
                    ? 'Agarra una bola, llévala al hoyo y pulsa sus monedas. Desbloquea escobas para mover grupos.'
                    : 'Día ${last.day} completado. Invierte lo recogido o ahorra para más adelante.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xffb5bdc9),
                  height: 1.5,
                ),
              ),
              if (session.recoveryMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    session.recoveryMessage!,
                    style: const TextStyle(color: gold),
                  ),
                ),
              const SizedBox(height: 16),
              ToolSelector(session: session),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SALDO DISPONIBLE',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: Color(0xffb5bdc9),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: gold,
                            size: 34,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${session.economy.balance}',
                            style: const TextStyle(
                              fontSize: 38,
                              color: gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      if (last != null) ...[
                        const Divider(height: 28),
                        Wrap(
                          spacing: 22,
                          runSpacing: 16,
                          children: [
                            _stat('Recogidas', '${last.income}'),
                            _stat('Sin recoger', '${last.lost}'),
                            _stat('Bolas al hoyo', '${last.captured}'),
                            _stat(
                              'Récord diario',
                              '${session.progress.record}',
                            ),
                            if (last.previousIncome != null)
                              _stat(
                                'Respecto al anterior',
                                '${last.income - last.previousIncome! >= 0 ? '+' : ''}${last.income - last.previousIncome!}',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'El taller',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cada mejora empieza a funcionar el próximo día.',
                style: TextStyle(color: Color(0xffb5bdc9)),
              ),
              for (final branch in [
                'Control',
                'Producción',
                'Automatización',
              ]) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 10),
                  child: Text(
                    branch.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: Color(0xff8fc7ba),
                    ),
                  ),
                ),
                for (final definition in session.catalog.definitions.where(
                  (d) => d.branch == branch,
                ))
                  UpgradeCard(session: session, definition: definition),
              ],
              if (session.catalog.definitions.every(
                (d) => (session.levels[d.id] ?? 0) == d.levels.length,
              ))
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Mejoras del prototipo completadas. ¡A por un nuevo récord!',
                    style: TextStyle(color: gold),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
          decoration: const BoxDecoration(
            color: ink,
            border: Border(top: BorderSide(color: surface)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: session.startDay,
              icon: const Icon(Icons.wb_sunny_outlined),
              label: Text('Comenzar día ${session.progress.day}'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
      Text(
        label,
        style: const TextStyle(color: Color(0xffb5bdc9), fontSize: 11),
      ),
    ],
  );
}

class UpgradeCard extends StatelessWidget {
  const UpgradeCard({
    super.key,
    required this.session,
    required this.definition,
  });
  final GameSession session;
  final UpgradeDefinition definition;
  static const icons = {
    'broom': Icons.cleaning_services_outlined,
    'paddle': Icons.swap_horiz,
    'broom_v': Icons.call_merge,
    'sweep': Icons.swipe_outlined,
    'collection': Icons.touch_app_outlined,
    'magnet': Icons.sensors,
    'generator': Icons.speed,
    'reward': Icons.monetization_on_outlined,
    'duration': Icons.more_time,
    'robot': Icons.smart_toy_outlined,
    'robot_speed': Icons.bolt,
  };
  @override
  Widget build(BuildContext context) {
    final level = session.levels[definition.id] ?? 0;
    final complete = level == definition.levels.length;
    final next = complete ? null : definition.levels[level];
    final block = session.purchaseBlock(definition);
    final current = session.catalog.settings(session.levels)[definition.effect];
    String effect(double value) {
      final number = value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
      return switch (definition.unit) {
        'unlock' => value > 0 ? 'Desbloqueado' : 'Bloqueado',
        'broom_width' => '${(value * 4).round()} u de anchura',
        'seconds' => '$number s',
        'coins' => '$number monedas / bola',
        'robots' => value == 0 ? 'Sin robot' : '1 robot',
        'logical_units_per_second' => '$number u/s',
        _ => '$number u',
      };
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icons[definition.id],
                  color: complete ? const Color(0xff8fc7ba) : gold,
                  size: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    definition.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$level/${definition.levels.length}',
                  style: const TextStyle(color: Color(0xffb5bdc9)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${effect(current)}${next == null ? '' : '  →  ${effect(next.value)}'}',
              style: const TextStyle(color: Color(0xffd2d9e2)),
            ),
            if (definition.id == 'broom')
              const Text(
                'Barre grupos. Se orienta según tu movimiento.',
                style: TextStyle(fontSize: 12, color: Color(0xffb5bdc9)),
              ),
            if (definition.id == 'broom_v')
              const Text(
                'Los dos brazos reúnen las bolas hacia el centro.',
                style: TextStyle(fontSize: 12, color: Color(0xffb5bdc9)),
              ),
            if (definition.id == 'sweep')
              const Text(
                'Recoge monedas arrastrando. Antes, solo pulsando.',
                style: TextStyle(fontSize: 12, color: Color(0xffb5bdc9)),
              ),
            if (definition.id == 'magnet')
              const Text(
                'Atrae y recoge monedas cerca del dedo mientras tocas.',
                style: TextStyle(fontSize: 12, color: Color(0xffb5bdc9)),
              ),
            if (definition.id == 'robot')
              const Text(
                'Empuja bolas. Las monedas las recoges tú.',
                style: TextStyle(fontSize: 12, color: Color(0xffb5bdc9)),
              ),
            const SizedBox(height: 10),
            if (block != null)
              Text(
                block,
                style: TextStyle(
                  fontSize: 12,
                  color: complete
                      ? const Color(0xff8fc7ba)
                      : const Color(0xffb5bdc9),
                ),
              ),
            if (next != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: block == null
                      ? () {
                          if (session.purchase(definition) && session.sound) {
                            unawaited(SystemSound.play(SystemSoundType.click));
                          }
                        }
                      : null,
                  icon: Icon(
                    block == null
                        ? Icons.add_circle_outline
                        : Icons.lock_outline,
                    size: 19,
                  ),
                  label: Text('Mejorar · ${next.cost} monedas'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ToolSelector extends StatelessWidget {
  const ToolSelector({super.key, required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (final tool in BallTool.values)
          ChoiceChip(
            label: Text(tool.label),
            avatar: session.toolAvailable(tool)
                ? null
                : const Icon(Icons.lock_outline, size: 15),
            selected: session.selectedTool == tool,
            onSelected: session.toolAvailable(tool) && !session.paused
                ? (_) => session.selectTool(tool)
                : null,
          ),
      ],
    ),
  );
}
