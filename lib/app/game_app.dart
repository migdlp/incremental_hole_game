import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/board/presentation/garden_game.dart';
import '../features/board/presentation/coin_icon.dart';
import '../features/board/presentation/streak_indicator.dart';
import '../features/board/presentation/special_ability_bar.dart';
import '../features/board/domain/coin_denomination.dart';
import '../features/day_cycle/domain/day_cycle.dart';
import '../features/upgrades/presentation/skill_tree_screen.dart';
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
                if (widget.session.debugEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Expanded(child: Text('DEBUG · prueba temporal')),
                        TextButton(
                          key: const ValueKey('session-debug-exit'),
                          onPressed: widget.session.exitDebug,
                          child: const Text('Salir de debug'),
                        ),
                      ],
                    ),
                  ),
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
                  child:
                      widget.session.running ||
                          widget.session.progress.last != null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: ExcludeFocus(
                                excluding: !widget.session.running,
                                child: ExcludeSemantics(
                                  excluding: !widget.session.running,
                                  child: IgnorePointer(
                                    ignoring: !widget.session.running,
                                    child: DayScreen(session: widget.session),
                                  ),
                                ),
                              ),
                            ),
                            if (!widget.session.running)
                              Positioned.fill(
                                child: _DayResultsOverlay(
                                  session: widget.session,
                                ),
                              ),
                          ],
                        )
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
  int? pointer, secondPointer;
  int lastIncome = 0;
  DateTime lastSound = DateTime(2000);
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_changes);
  }

  void _changes() {
    if (!widget.session.running || widget.session.paused) {
      pointer = secondPointer = null;
    }
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
        Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
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
                              'DÍA ${session.running ? session.progress.day : session.progress.last?.day ?? session.progress.day}',
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: 2,
                                color: Color(0xffb5bdc9),
                              ),
                            ),
                            Text(
                              '${session.cycle == null ? 0 : (closing ? session.cycle!.remaining : session.cycle!.remaining - session.cycle!.closing).ceil()} s',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: closing
                                    ? const Color(0xffffae83)
                                    : cream,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const CoinIcon(),
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
                  child: Column(
                    children: [
                      _phaseBar(
                        'day-timer',
                        'Día',
                        session.cycle == null
                            ? 0
                            : ((session.cycle!.remaining -
                                          session.cycle!.closing) /
                                      session.cycle!.production)
                                  .clamp(0.0, 1.0),
                        const Color(0xff69b4a5),
                      ),
                      if (closing) ...[
                        const SizedBox(height: 6),
                        _phaseBar(
                          'collection-timer',
                          'Recogida',
                          (session.cycle!.remaining / session.cycle!.closing)
                              .clamp(0.0, 1.0),
                          const Color(0xffd1764c),
                        ),
                      ],
                    ],
                  ),
                ),
                if (session.running)
                  StreakIndicator(
                    combo: session.board!.combo,
                    closing: closing,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 5),
                  child: Text(
                    !session.running
                        ? 'Jornada finalizada'
                        : closing
                        ? 'ÚLTIMOS SEGUNDOS · Recoge las monedas'
                        : session.economy.generated > 0
                        ? (session.board!.sweepEnabled
                              ? 'Toca o desliza para recoger las monedas'
                              : 'Pulsa las monedas para recogerlas')
                        : session.board!.broomUnlocked
                        ? 'Escoba: un dedo mueve; dos dedos orientan y barren'
                        : session.board!.handCapacity > 1
                        ? 'Agarra y acerca otras bolas'
                        : 'Agarra una bola y llévala al hoyo',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: closing
                          ? const Color(0xffffae83)
                          : const Color(0xffc6cfdb),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown: (event) {
                    if (session.paused) return;
                    final point = game.boardPoint(event.localPosition);
                    if (point == null) return;
                    if (pointer != null) {
                      if (secondPointer == null &&
                          session.grabSecondBroomPoint(point)) {
                        secondPointer = event.pointer;
                      }
                      return;
                    }
                    pointer = event.pointer;
                    session.touch(
                      point,
                      time: event.timeStamp.inMicroseconds / 1e6,
                    );
                  },
                  onPointerMove: (event) {
                    if (session.paused ||
                        (event.pointer != pointer &&
                            event.pointer != secondPointer)) {
                      return;
                    }
                    final point = game.boardPoint(event.localPosition);
                    if (point == null) {
                      pointer = secondPointer = null;
                      session.release(cancel: true);
                    } else if (event.pointer == secondPointer) {
                      session.dragSecondBroomPoint(point);
                    } else {
                      session.drag(
                        point,
                        time: event.timeStamp.inMicroseconds / 1e6,
                      );
                    }
                  },
                  onPointerUp: (event) {
                    if (event.pointer == secondPointer) {
                      session.releaseSecondBroomPoint();
                      secondPointer = null;
                    } else if (event.pointer == pointer) {
                      if (secondPointer != null) {
                        session.releaseSecondBroomPoint(promote: true);
                        pointer = secondPointer;
                        secondPointer = null;
                        return;
                      }
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
                    if (event.pointer == pointer ||
                        event.pointer == secondPointer) {
                      pointer = secondPointer = null;
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
                    child: SingleChildScrollView(
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
                                  'El tiempo está detenido.',
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
        if (session.running) SpecialAbilityBar(session: session),
      ],
    );
  }
}

Widget _phaseBar(String id, String label, double remaining, Color color) =>
    Semantics(
      label: label,
      value: '${(remaining * 100).round()} % de tiempo restante',
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: TextStyle(fontSize: 11, color: color)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                key: ValueKey(id),
                value: remaining,
                minHeight: 5,
                backgroundColor: surface,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );

class _DayResultsOverlay extends StatelessWidget {
  const _DayResultsOverlay({required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Stack(
      children: [
        const Positioned.fill(
          child: ModalBarrier(dismissible: false, color: Color(0x99111c2e)),
        ),
        Dialog(
          key: const ValueKey('day-results-popup'),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 24,
          ),
          backgroundColor: ink,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xff41516a)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 740),
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              namesRoute: true,
              label: 'Resultados y mejoras de la jornada',
              child: FocusScope(
                autofocus: true,
                child: NightScreen(session: session),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class NightScreen extends StatelessWidget {
  const NightScreen({super.key, required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final last = session.progress.last;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  last == null
                      ? 'JARDÍN MECÁNICO'
                      : 'Día ${last.day} completado',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const CoinIcon(),
              const SizedBox(width: 6),
              Text(
                '${session.economy.balance}',
                style: const TextStyle(
                  color: gold,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            children: [
              if (last != null)
                _results()
              else ...[
                const Text(
                  'Un pequeño gesto.\nUn jardín que crece.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Agarra una bola, llévala al hoyo y recoge sus monedas.',
                  style: TextStyle(color: Color(0xffb5bdc9), height: 1.4),
                ),
              ],
              if (session.recoveryMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    session.recoveryMessage!,
                    style: const TextStyle(color: gold),
                  ),
                ),
              if (last == null) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sonidos del sistema'),
                  value: session.sound,
                  onChanged: session.setSound,
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: surface)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SkillTreeScreen(session: session),
                    ),
                  ),
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('Ir al árbol de mejoras'),
                ),
                if (last == null) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: session.startDay,
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: Text('Comenzar día ${session.progress.day}'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _results() {
    final result = session.progress.last!;
    return Container(
      key: const ValueKey('visual-day-results'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(),
          const SizedBox(height: 8),
          const Text(
            'Dinero ganado',
            style: TextStyle(color: Color(0xffb5bdc9), fontSize: 13),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${result.income}',
              style: const TextStyle(
                color: gold,
                fontSize: 58,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _metric(
                  const Icon(Icons.adjust_rounded, size: 22, color: cream),
                  '${result.captured}',
                  'Bolas al hoyo',
                  cream,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _metric(
                  const CoinIcon(),
                  '${result.lost}',
                  'Sin recoger',
                  result.lost == 0
                      ? const Color(0xff8fc7ba)
                      : const Color(0xffffbb7c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Monedas recogidas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          if (result.collectedCoins == null)
            const Text(
              'Detalle no disponible para esta jornada anterior.',
              style: TextStyle(color: Color(0xffb5bdc9), fontSize: 12),
            )
          else if (result.collectedCoins!.values.every((count) => count == 0))
            const Text(
              'Sin monedas recogidas',
              style: TextStyle(color: Color(0xffb5bdc9), fontSize: 12),
            )
          else
            for (final denomination in CoinDenomination.values.reversed)
              if ((result.collectedCoins![denomination.amount] ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Semantics(
                    key: ValueKey('collected-coin-${denomination.amount}'),
                    label:
                        '${result.collectedCoins![denomination.amount]} monedas de ${denomination.amount}',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        CoinIcon(denomination: denomination),
                        const SizedBox(width: 8),
                        Text('${denomination.amount}'),
                        const Spacer(),
                        Text(
                          '× ${result.collectedCoins![denomination.amount]}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _metric(Widget icon, String value, String label, Color color) =>
      Column(
        children: [
          icon,
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xffb5bdc9), fontSize: 11),
          ),
        ],
      );
}
