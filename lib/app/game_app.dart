import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../features/board/presentation/garden_game.dart';
import '../features/board/presentation/coin_icon.dart';
import '../features/board/presentation/streak_indicator.dart';
import '../features/board/presentation/special_ability_bar.dart';
import '../features/day_cycle/domain/day_cycle.dart';
import '../features/feeding/presentation/feeding_summary.dart';
import '../features/upgrades/presentation/skill_tree_screen.dart';
import 'game_session.dart';
import '../features/prestige/presentation/prestige_screen.dart';

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
    title: 'Feed the Hole',
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
    widget.session.setBackgrounded(state != AppLifecycleState.resumed);
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
                  child: !widget.session.canPlayRun
                      ? PrestigeScreen(session: widget.session)
                      : widget.session.running ||
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
  final _walletKey = GlobalKey();
  final _boardKey = GlobalKey();
  int lastIncome = 0;
  void _frameTimings(List<FrameTiming> timings) {
    if (widget.session.debugEnabled) {
      widget.session.rewardFrameMetrics.add(timings);
    }
  }

  void _syncWallet() {
    final wallet = _walletKey.currentContext?.findRenderObject();
    final board = _boardKey.currentContext?.findRenderObject();
    if (wallet is RenderBox && board is RenderBox && game.size.x > 0) {
      final local = board.globalToLocal(
        wallet.localToGlobal(wallet.size.center(Offset.zero)),
      );
      final point = game.boardPoint(local);
      if (point != null) game.walletTarget = Offset(point.x, point.y);
    }
  }

  DateTime lastSound = DateTime(2000);
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_changes);
    SchedulerBinding.instance.addTimingsCallback(_frameTimings);
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
    SchedulerBinding.instance.removeTimingsCallback(_frameTimings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncWallet();
    });
    final closing = session.phase == DayPhase.closing;
    final cycle = session.cycle;
    final seconds = cycle == null
        ? 0
        : (closing ? cycle.remaining : cycle.remaining - cycle.closing).ceil();
    final remaining = cycle == null
        ? 0.0
        : (closing
                  ? cycle.remaining / cycle.closing
                  : (cycle.remaining - cycle.closing) / cycle.production)
              .clamp(0.0, 1.0);
    final color = closing ? const Color(0xffd1764c) : const Color(0xff69b4a5);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$seconds s',
                key: const ValueKey('remaining-seconds'),
                style: const TextStyle(
                  color: cream,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  key: const ValueKey('phase-timer'),
                  value: remaining,
                  minHeight: 5,
                  backgroundColor: surface,
                  color: color,
                  semanticsLabel: 'Tiempo restante',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 360 / 560,
              child: Stack(
                key: const ValueKey('gameplay-board'),
                children: [
                  Positioned.fill(
                    child: Listener(
                      key: _boardKey,
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
                  Positioned(
                    top: 6,
                    left: 6,
                    child: IconButton(
                      tooltip: 'Pausar',
                      onPressed: session.pause,
                      color: Colors.black,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xeef1e5cd),
                      ),
                      icon: const Icon(Icons.pause_rounded),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 16,
                    child: IgnorePointer(
                      child: AnimatedScale(
                        scale: session.rewardVisuals.receiptPulse > 0
                            ? 1.06
                            : 1,
                        duration: const Duration(milliseconds: 120),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xeef1e5cd),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            key: const ValueKey('gameplay-balance'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CoinIcon(key: _walletKey),
                              const SizedBox(width: 6),
                              Text(
                                '${session.economy.balance + (session.running ? session.economy.collected : 0)}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (session.running)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: StreakIndicator(
                          combo: session.board!.combo,
                          closing: closing,
                        ),
                      ),
                    ),
                  if (session.paused)
                    Positioned.fill(
                      child: ColoredBox(
                        color: const Color(0xc0111c2e),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.pause_rounded,
                                      size: 36,
                                      color: gold,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Juego pausado',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _SettingsOptions(session: session),
                                    FilledButton.icon(
                                      onPressed: session.resume,
                                      icon: const Icon(
                                        Icons.play_arrow_rounded,
                                      ),
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
          ),
        ),
        if (session.running) SpecialAbilityBar(session: session),
      ],
    );
  }
}

class _SettingsOptions extends StatelessWidget {
  const _SettingsOptions({required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Sonidos del sistema'),
        value: session.sound,
        onChanged: session.setSound,
      ),
      SwitchListTile(
        key: const ValueKey('haptics-setting'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Vibración'),
        value: session.haptics,
        onChanged: session.setHaptics,
      ),
      SwitchListTile(
        key: const ValueKey('visual-feedback-setting'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Feedback visual'),
        value: session.visualFeedback,
        onChanged: session.setVisualFeedback,
      ),
    ],
  );
}

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
                  last == null ? 'Feed the Hole' : 'Resultados',
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
                  'Cada bola cuenta.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FeedingSummary(session: session),
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
                _SettingsOptions(session: session),
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
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Tienda'),
                ),
                if (last == null) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: session.prestigeReady ? session.startDay : null,
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: const Text('Comenzar día'),
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
                  '${result.generated}',
                  'Recompensas',
                  result.lost == 0
                      ? const Color(0xff8fc7ba)
                      : const Color(0xffffbb7c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Cobro automático',
            style: TextStyle(color: Color(0xffb5bdc9), fontSize: 12),
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
