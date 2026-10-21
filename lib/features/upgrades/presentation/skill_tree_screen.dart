import '../../feeding/presentation/feeding_summary.dart';
import '../../prestige/domain/star_rewards.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/game_session.dart';
import '../../board/presentation/coin_icon.dart';
import '../domain/skill_tree.dart';

const _background = Color(0xff101a2b);
const _gold = Color(0xfff5b83d);
const _mint = Color(0xff8fc7ba);

class SkillTreeScreen extends StatefulWidget {
  const SkillTreeScreen({super.key, required this.session});
  final GameSession session;
  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final tree = SkillTree(widget.session.catalog);
  final transform = TransformationController();
  late final hold = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..addStatusListener(_holdStatus);
  SkillNode? selected;
  SkillNode? holding;
  int? activePointer;
  Offset? origin;
  bool moved = false;
  bool _prestigeDialogOpen = false;
  bool _closingPrestigeRoute = false;
  final pointers = <int>{};
  Size? viewport;
  bool initialized = false;
  String? announcement;
  late bool _wasDebugEnabled;
  late bool _wasFullTree;
  bool get _debugBuying => widget.session.debugFullTree;
  List<SkillNode> get _visible =>
      _debugBuying ? tree.nodes : tree.visible(widget.session.levels);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wasDebugEnabled = widget.session.debugEnabled;
    _wasFullTree = widget.session.debugFullTree;
    widget.session.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    final session = widget.session;
    if (!session.canPlayRun && !_closingPrestigeRoute) {
      _closingPrestigeRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
    final changedMode =
        _wasDebugEnabled != session.debugEnabled ||
        _wasFullTree != session.debugFullTree;
    _wasDebugEnabled = session.debugEnabled;
    _wasFullTree = session.debugFullTree;
    if (changedMode || (holding != null && !_canBuy(holding!))) {
      _cancel();
      activePointer = null;
      pointers.clear();
    }
    if (selected != null && !_visible.any((n) => n.id == selected!.id)) {
      selected = null;
      announcement = null;
    }
    if (changedMode && viewport != null) _center(viewport!, node: tree.root);
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _cancel();
      activePointer = null;
      pointers.clear();
      moved = true;
    }
  }

  bool _canBuy(SkillNode node) {
    final session = widget.session;
    if (!session.canPlayRun || !session.prestigeReady) return false;
    if (_debugBuying) return !session.running && !node.owned(session.levels);
    return !node.owned(session.levels) &&
        (session.levels[node.definition.id] ?? 0) == node.level - 1 &&
        tree.unlocked(node, session.levels) &&
        session.purchaseBlock(node.definition) == null;
  }

  void _cancel() {
    hold.reset();
    holding = null;
  }

  void _holdStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed) return;
    final node = holding;
    holding = null;
    hold.reset();
    if (node == null || !_canBuy(node)) return;
    if (node.definition.id == 'prestige') {
      if (_prestigeDialogOpen) return;
      _prestigeDialogOpen = true;
      final session = widget.session;
      final revision = session.meta.revision, runId = session.meta.runId;
      final wasDebug = session.debugEnabled;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Reiniciar la partida?'),
          content: const Text(
            'Comprar Prestigio termina esta partida inmediatamente. Se reinician las monedas y las mejoras normales. Conservas tus estrellas y mejoras permanentes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('prestige-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reiniciar y prestigiar'),
            ),
          ],
        ),
      );
      _prestigeDialogOpen = false;
      if (!mounted ||
          confirmed != true ||
          session.meta.revision != revision ||
          session.meta.runId != runId ||
          session.debugEnabled != wasDebug ||
          !_canBuy(node)) {
        return;
      }
      final ended = _debugBuying
          ? session.debugPurchase('prestige', 1, confirmPrestige: true)
          : session.purchase(node.definition, confirmPrestige: true);
      if (ended && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }
    final purchased = _debugBuying
        ? widget.session.debugPurchase(node.definition.id, node.level)
        : widget.session.purchase(node.definition);
    if (purchased) {
      if (widget.session.sound) {
        unawaited(SystemSound.play(SystemSoundType.click));
      }
      unawaited(HapticFeedback.lightImpact());
      setState(
        () => announcement = 'Mejora adquirida. Nuevos caminos disponibles.',
      );
    }
  }

  void _down(PointerDownEvent event, SkillNode node, {bool purchase = false}) {
    if (pointers.length > 1 || activePointer != null) return;
    activePointer = event.pointer;
    origin = event.position;
    moved = false;
    if (purchase && selected?.id == node.id && _canBuy(node)) {
      holding = node;
      hold.forward(from: 0);
    }
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer == activePointer &&
        origin != null &&
        (event.position - origin!).distance > 10) {
      moved = true;
      _cancel();
    }
  }

  void _up(PointerEvent event, SkillNode node, {bool cancel = false}) {
    if (event.pointer != activePointer) return;
    _cancel();
    activePointer = null;
    if (!cancel && !moved && pointers.length <= 1) {
      setState(() {
        if (selected?.id != node.id) announcement = null;
        selected = node;
      });
    }
  }

  void _center(Size size, {SkillNode? node}) {
    if (_debugBuying) {
      final scale = math
          .min(
            (size.width - 24) / SkillTree.canvasSize,
            (size.height - 24) / SkillTree.canvasSize,
          )
          .clamp(.2, 1.0);
      transform.value = Matrix4.diagonal3Values(scale, scale, scale)
        ..setTranslationRaw(
          (size.width - SkillTree.canvasSize * scale) / 2,
          (size.height - SkillTree.canvasSize * scale) / 2,
          0,
        );
      return;
    }
    final target = node ?? selected ?? tree.root;
    const scale = .85;
    transform.value = Matrix4.diagonal3Values(scale, scale, scale)
      ..setTranslationRaw(
        size.width / 2 - target.x * scale,
        size.height / 2 - target.y * scale,
        0,
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.session.removeListener(_sessionChanged);
    hold.dispose();
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final visible = _visible;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        centerTitle: false,
        titleSpacing: 12,
        title: TextButton.icon(
          key: const ValueKey('tree-debug-tools'),
          onPressed: _openDebug,
          icon: const Icon(Icons.bug_report_outlined, size: 18),
          label: const Text('DEBUG'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: Row(
              children: [
                const CoinIcon(),
                const SizedBox(width: 7),
                Text(
                  '${session.economy.balance}',
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Listener(
        onPointerDown: (e) {
          pointers.add(e.pointer);
          if (pointers.length > 1) {
            moved = true;
            _cancel();
          }
        },
        onPointerSignal: (_) => _cancel(),
        onPointerPanZoomStart: (_) => _cancel(),
        onPointerUp: (e) => pointers.remove(e.pointer),
        onPointerCancel: (e) {
          pointers.remove(e.pointer);
          _cancel();
        },
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              FeedingSummary(session: session, compact: true),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final previousViewport = viewport;
                    viewport = constraints.biggest;
                    if (!initialized) {
                      initialized = true;
                      _center(viewport!, node: tree.root);
                    } else if (previousViewport != null &&
                        previousViewport != viewport) {
                      if (_debugBuying) {
                        _center(viewport!);
                      } else {
                        final value = transform.value;
                        transform.value = value.clone()
                          ..setTranslationRaw(
                            value.storage[12] +
                                (viewport!.width - previousViewport.width) / 2,
                            value.storage[13] +
                                (viewport!.height - previousViewport.height) /
                                    2,
                            0,
                          );
                      }
                    }
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: InteractiveViewer(
                            key: const ValueKey('skill-tree-viewer'),
                            transformationController: transform,
                            constrained: false,
                            alignment: Alignment.topLeft,
                            boundaryMargin: const EdgeInsets.all(800),
                            minScale: _debugBuying ? .2 : .35,
                            maxScale: 1.8,
                            child: SizedBox(
                              width: SkillTree.canvasSize,
                              height: SkillTree.canvasSize,
                              child: CustomPaint(
                                painter: _TreePainter(
                                  visible,
                                  session.levels,
                                  tree.paths,
                                ),
                                child: Stack(
                                  children: [
                                    for (final node in visible)
                                      Positioned(
                                        key: ValueKey('position-${node.id}'),
                                        left:
                                            node.x -
                                            (node.definition.id == 'prestige'
                                                ? 40
                                                : 32),
                                        top:
                                            node.y -
                                            (node.definition.id == 'prestige'
                                                ? 40
                                                : 32),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: 1),
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          builder: (_, value, child) => Opacity(
                                            opacity: value,
                                            child: child,
                                          ),
                                          child: _node(node),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (selected != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .46,
                  ),
                  child: SingleChildScrollView(child: _details()),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('tree-start-day'),
                    onPressed:
                        session.running ||
                            session.debugFeedingFailed ||
                            !session.canPlayRun ||
                            !session.prestigeReady
                        ? null
                        : () {
                            _cancel();
                            activePointer = null;
                            pointers.clear();
                            session.startDay();
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: const Text('Comenzar día'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDebug() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    final session = widget.session;
    if (!session.debugEnabled && !session.enterDebug()) return;
    _cancel();
    activePointer = null;
    pointers.clear();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: session,
              builder: (_, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Depuración',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pruebas temporales: tu partida guardada se conserva. '
                    'Puedes comenzar días con estas mejoras.',
                  ),
                  SwitchListTile(
                    key: const ValueKey('debug-player-view'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vista del jugador'),
                    subtitle: Text(
                      session.debugFullTree
                          ? 'Tienda completa. Compras gratuitas con sus requisitos.'
                          : 'Solo nodos comprados y siguientes; precios y estados normales.',
                    ),
                    value: !session.debugFullTree,
                    onChanged: (value) => session.setDebugFullTree(!value),
                  ),
                  const Text(
                    'La vista del jugador usa tus compras de prueba. '
                    'Reinicia la prueba para ver cómo empieza una partida.',
                  ),
                  const SizedBox(height: 12),
                  if (session.debugReports.isNotEmpty) ...[
                    const Text('Última jornada de prueba'),
                    SelectableText(
                      session.debugReports.last.summary,
                      key: const ValueKey('debug-day-report'),
                    ),
                    TextButton.icon(
                      key: const ValueKey('debug-copy-reports'),
                      onPressed: () => Clipboard.setData(
                        ClipboardData(
                          text: session.debugReports
                              .map((report) => report.summary)
                              .join('\n\n'),
                        ),
                      ),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar jornadas de prueba'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    key: const ValueKey('debug-buy-all'),
                    onPressed: session.running
                        ? null
                        : () => session.debugBuyAll(),
                    child: const Text('Comprar todo'),
                  ),
                  TextButton(
                    key: const ValueKey('debug-add-coins'),
                    onPressed: session.running ? null : session.debugAddCoins,
                    child: const Text('Añadir 1000 monedas de prueba'),
                  ),
                  TextButton(
                    key: const ValueKey('debug-reset'),
                    onPressed: session.running ? null : session.debugReset,
                    child: const Text('Reiniciar prueba desde cero'),
                  ),
                  TextButton(
                    key: const ValueKey('debug-close-tools'),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Volver a la tienda'),
                  ),
                  OutlinedButton(
                    key: const ValueKey('debug-exit'),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      session.exitDebug();
                    },
                    child: const Text('Salir de depuración'),
                  ),
                  ExpansionTile(
                    key: const ValueKey('debug-gravity-tools'),
                    title: const Text('Gravedad'),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Inclinación de prueba',
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            key: const ValueKey('debug-gravity-tilt'),
                            value: session.debugGravityTilt,
                            isExpanded: true,
                            items: GameSession.gravityDebugTilts.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(
                                      entry.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                session.debugSetGravityTilt(value);
                              }
                            },
                          ),
                        ),
                      ),
                      SwitchListTile(
                        key: const ValueKey('debug-force-gravity'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Forzar Gravedad en la próxima jornada',
                        ),
                        subtitle: Text(
                          session.gravityAvailable
                              ? 'Un objeto, desde el inicio de la prueba.'
                              : 'Sin sensor compatible: elige una inclinación simulada para probar.',
                        ),
                        value: session.debugForceGravity,
                        onChanged: session.running || !session.gravityAvailable
                            ? null
                            : session.debugSetForceGravity,
                      ),
                    ],
                  ),
                  ExpansionTile(
                    key: const ValueKey('debug-black-hole-tools'),
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Agujero negro'),
                    children: [
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Objetos al comenzar la próxima prueba',
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            key: const ValueKey('debug-black-hole-count'),
                            value: session.debugBlackHoleObjects,
                            isExpanded: true,
                            items: [
                              for (var count = 0; count <= 3; count++)
                                DropdownMenuItem(
                                  value: count,
                                  child: Text(
                                    count == 0
                                        ? 'Solo apariciones aleatorias'
                                        : '$count objeto${count == 1 ? '' : 's'} de prueba',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: session.running
                                ? null
                                : (count) {
                                    if (count != null) {
                                      session.debugSetBlackHoleObjects(count);
                                    }
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    key: const ValueKey('debug-star-tools'),
                    title: const Text('Estrellas y burbujas · P01'),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      const Text(
                        'Parámetros provisionales BAL01. Ajustarlos antes de comenzar la prueba. Interacciones especiales experimentales.',
                      ),
                      Text(
                        '${session.meta.stars} estrellas · ${session.meta.starLedger.pending.length} burbujas pendientes',
                      ),
                      TextButton.icon(
                        key: const ValueKey('debug-star-award'),
                        onPressed: session.debugAwardStarBubbles,
                        icon: const Icon(Icons.bubble_chart),
                        label: const Text('Añadir recompensa de prueba'),
                      ),
                      for (final entry in StarConfig.ranges.entries)
                        TextFormField(
                          key: ValueKey('debug-${entry.key}'),
                          initialValue: '${session.starConfig[entry.key]}',
                          enabled: !session.running,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: entry.key,
                            helperText: '${entry.value.$1}–${entry.value.$2}',
                          ),
                          onChanged: (raw) {
                            final n = double.tryParse(raw);
                            if (n == null ||
                                !n.isFinite ||
                                n < entry.value.$1 ||
                                n > entry.value.$2 ||
                                (StarConfig.integers.contains(entry.key) &&
                                    n != n.roundToDouble())) {
                              return;
                            }
                            session.debugSetStarParameter(entry.key, n);
                          },
                        ),
                      SwitchListTile(
                        title: const Text('Experimento: Gravedad en burbujas'),
                        value: session.debugBubbleGravity,
                        onChanged: (v) =>
                            session.debugSetBubbleInteractions(gravity: v),
                      ),
                      SwitchListTile(
                        title: const Text('Experimento: succión en burbujas'),
                        value: session.debugBubbleBlackHole,
                        onChanged: (v) =>
                            session.debugSetBubbleInteractions(blackHole: v),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    key: const ValueKey('debug-reward-tools'),
                    title: const Text('Monedas automáticas · rendimiento'),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      const Text(
                        'Presupuesto visual provisional; no cambia los ingresos.',
                      ),
                      DropdownButtonFormField<int>(
                        key: const ValueKey('debug-reward-limit'),
                        initialValue: session.rewardVisuals.debugLimit ?? -1,
                        items: [
                          for (final n in {
                            -1,
                            0,
                            8,
                            16,
                            session.rewardVisuals.capacity,
                          })
                            DropdownMenuItem(
                              value: n,
                              child: Text(
                                n == -1
                                    ? 'Adaptativo'
                                    : n == 0
                                    ? 'Sin animaciones'
                                    : '$n monedas',
                              ),
                            ),
                        ],
                        onChanged: (n) {
                          if (n != null) {
                            session.debugSetRewardLimit(n < 0 ? null : n);
                          }
                        },
                      ),
                      Text(session.rewardFrameMetrics.report),
                      TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar medición'),
                        onPressed: () => Clipboard.setData(
                          ClipboardData(
                            text:
                                '${session.rewardFrameMetrics.report}\nPresupuesto provisional ${session.rewardVisuals.limit}; pico ${session.rewardVisuals.peak}; agrupadas ${session.rewardVisuals.grouped}; omitidas ${session.rewardVisuals.omitted}.',
                          ),
                        ),
                      ),
                      Text(
                        'Última jornada: pico ${session.rewardVisuals.peak}, agrupadas ${session.rewardVisuals.grouped}, omitidas ${session.rewardVisuals.omitted}',
                      ),
                    ],
                  ),
                  SwitchListTile(
                    key: const ValueKey('debug-prestige-rules'),
                    title: const Text('Probar derrota y prestigio'),
                    subtitle: const Text(
                      'El fallo de cuota termina solo la partida de prueba.',
                    ),
                    value: session.debugPrestigeRules,
                    onChanged: session.running
                        ? null
                        : session.debugSetPrestigeRules,
                  ),
                  ExpansionTile(
                    key: const ValueKey('debug-feeding-tools'),
                    title: const Text('Alimentación y cuotas'),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      const Text(
                        'Cuotas experimentales. Cambiar una opción reinicia solo el período de prueba.',
                      ),
                      SwitchListTile(
                        key: const ValueKey('debug-feeding-enabled'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Simular fallo de cuota'),
                        value: session.debugFeedingQuotas,
                        onChanged: session.running
                            ? null
                            : (value) =>
                                  session.debugConfigureFeeding(quotas: value),
                      ),
                      DropdownButton<int>(
                        key: const ValueKey('debug-feeding-target'),
                        isExpanded: true,
                        value:
                            session.feeding.target ??
                            session.feedingInitialQuota,
                        items:
                            {
                                  ...[
                                    1,
                                    session.feedingInitialQuota,
                                    100,
                                    1000,
                                  ],
                                  if (session.feeding.target != null)
                                    session.feeding.target!,
                                }
                                .map(
                                  (amount) => DropdownMenuItem(
                                    value: amount,
                                    child: Text('Cuota de prueba: $amount'),
                                  ),
                                )
                                .toList(),
                        onChanged: session.running
                            ? null
                            : (amount) {
                                if (amount != null) {
                                  session.debugConfigureFeeding(
                                    quotas: true,
                                    target: amount,
                                  );
                                }
                              },
                      ),
                      TextButton(
                        key: const ValueKey('debug-feeding-empty-day'),
                        onPressed:
                            session.running ||
                                session.debugFeedingFailed ||
                                !session.canPlayRun ||
                                !session.prestigeReady
                            ? null
                            : session.debugSimulateEmptyDay,
                        child: const Text('Simular jornada sin capturas'),
                      ),
                      TextButton(
                        key: const ValueKey('debug-feeding-restart'),
                        onPressed: session.running
                            ? null
                            : session.debugRestartFeedingPeriod,
                        child: const Text('Reiniciar período de prueba'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _prestigeNode(SkillNode node) {
    final affordable = _canBuy(node);
    return Semantics(
      button: true,
      label: 'Prestigio. Reinicia la partida tras confirmación.',
      onTap: () => setState(() => selected = node),
      child: Listener(
        key: ValueKey('node-${node.id}'),
        onPointerDown: (e) => _down(e, node),
        onPointerMove: _move,
        onPointerUp: (e) => _up(e, node),
        onPointerCancel: (e) => _up(e, node, cancel: true),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Center(
            child: Transform.rotate(
              key: const ValueKey('prestige-diamond'),
              angle: math.pi / 4,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: affordable ? Colors.white : _gold,
                    width: 2,
                  ),
                ),
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: const Icon(Icons.auto_awesome, color: _gold, size: 30),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _node(SkillNode node) {
    if (node.definition.id == 'prestige') return _prestigeNode(node);
    final owned = node.owned(widget.session.levels);
    final affordable = _canBuy(node);
    final isSelected = selected?.id == node.id;
    final typeColor = _typeColor(node);
    final color = owned
        ? typeColor
        : affordable
        ? const Color(0xffe2e8f0)
        : const Color(0xff64738a);
    final locked = !_debugBuying && !tree.unlocked(node, widget.session.levels);
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${_description(node)}. ${owned ? 'Adquirida' : '${node.upgrade.cost} monedas'}.',
      onTap: () {
        _cancel();
        setState(() => selected = node);
      },
      child: Listener(
        key: ValueKey('node-${node.id}'),
        onPointerDown: (e) => _down(e, node),
        onPointerMove: _move,
        onPointerUp: (e) => _up(e, node),
        onPointerCancel: (e) => _up(e, node, cancel: true),
        child: AnimatedBuilder(
          animation: hold,
          builder: (context, _) => SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: owned
                        ? .18
                        : affordable
                        ? .12
                        : .05,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: affordable
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: .16),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(_icons[node.definition.id], size: 26, color: color),
                    if (owned || locked)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          owned ? Icons.check_circle : Icons.lock_outline,
                          size: 16,
                          color: color,
                        ),
                      ),
                    if (holding?.id == node.id)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: CircularProgressIndicator(
                            value: hold.value,
                            color: _gold,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _details() {
    final node = selected!;
    final owned = node.owned(widget.session.levels);
    final affordable = _canBuy(node);
    final current = node.level == 1
        ? (node.definition.id == 'hand_grip'
              ? 1.0
              : node.definition.id == 'attraction'
              ? 65.0
              : widget.session.catalog.base[node.definition.effect] ?? 0)
        : node.definition.levels[node.level - 2].value;
    final next = node.upgrade.value;
    final isInterval =
        node.definition.effect == 'spawn_interval' ||
        node.definition.id == 'capture_recharge' ||
        node.definition.id == 'boost_recharge';
    final percentage = current > 0
        ? ((isInterval ? current / next : next / current) - 1) * 100
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xff1d2b40),
        border: Border(top: BorderSide(color: Color(0xff34465e))),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message:
                '${node.definition.name} · nivel ${node.level}. '
                '${_description(node)}. '
                '${_value(node, current)} → ${_value(node, next)}'
                '${percentage == null ? '' : ' (+${percentage.toStringAsFixed(1)} %)'}',
            child: Text.rich(
              _summary(node),
              key: const ValueKey('upgrade-summary'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (!owned) ...[const CoinIcon(), const SizedBox(width: 6)],
                    Flexible(
                      child: Text(
                        owned
                            ? 'Adquirida'
                            : _debugBuying
                            ? 'Gratis · DEBUG'
                            : '${node.upgrade.cost}',
                        style: TextStyle(
                          color: owned ? _mint : _gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!owned && !affordable)
                Flexible(
                  child: Text(
                    !tree.unlocked(node, widget.session.levels) &&
                            node.definition.id != 'prestige'
                        ? 'Completa la mejora anterior'
                        : widget.session.purchaseBlock(node.definition) ?? '',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xffa5b2c5),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!owned)
            Focus(
              onFocusChange: (focused) {
                if (!focused) _cancel();
              },
              onKeyEvent: (_, event) {
                if (event.logicalKey != LogicalKeyboardKey.space &&
                    event.logicalKey != LogicalKeyboardKey.enter) {
                  return KeyEventResult.ignored;
                }
                if (event is KeyDownEvent && affordable) {
                  holding = node;
                  hold.forward(from: 0);
                }
                if (event is KeyUpEvent) _cancel();
                return KeyEventResult.handled;
              },
              child: Semantics(
                label: affordable
                    ? 'Mantén pulsado un segundo para comprar'
                    : 'Saldo insuficiente',
                child: Listener(
                  key: const ValueKey('hold-purchase'),
                  onPointerDown: (e) => _down(e, node, purchase: true),
                  onPointerMove: _move,
                  onPointerUp: (e) => _up(e, node),
                  onPointerCancel: (e) => _up(e, node, cancel: true),
                  child: AnimatedBuilder(
                    animation: hold,
                    builder: (context, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Container(
                            height: 50,
                            color: affordable
                                ? const Color(0xff3b3a2e)
                                : const Color(0xff263349),
                          ),
                          if (holding?.id == node.id)
                            FractionallySizedBox(
                              widthFactor: hold.value,
                              child: Container(
                                height: 50,
                                color: _gold.withValues(alpha: .35),
                              ),
                            ),
                          SizedBox(
                            height: 50,
                            child: Center(
                              child: Text(
                                affordable
                                    ? (_debugBuying
                                          ? 'Comprar gratis · 1 s'
                                          : 'Comprar · 1 s')
                                    : 'No disponible',
                                style: TextStyle(
                                  color: affordable
                                      ? _gold
                                      : const Color(0xff9aa8bc),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (announcement != null)
            Semantics(
              liveRegion: true,
              child: Text(
                announcement!,
                style: const TextStyle(color: _mint, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

Color _typeColor(SkillNode node) => switch (node.definition.id) {
  'prestige' => const Color(0xffeab308),
  'launcher' ||
  'launcher_rate' ||
  'generator' ||
  'double_spawn' ||
  'boost' ||
  'boost_power' ||
  'boost_duration' ||
  'boost_recharge' => const Color(0xff22c55e),
  'reward' || 'combo' => const Color(0xffeab308),
  'sweep' ||
  'collection' ||
  'magnet' ||
  'attraction' => const Color(0xff3b82f6),
  'duration' => const Color(0xfff97316),
  'robot' || 'robot_speed' => const Color(0xfff43f5e),
  _ => const Color(0xffa855f7),
};

const _icons = {
  'prestige': Icons.auto_awesome,
  'hand': Icons.back_hand_outlined,
  'hand_grip': Icons.front_hand_outlined,
  'walls': Icons.compare_arrows,
  'bat': Icons.sports_baseball_outlined,
  'broom': Icons.cleaning_services_outlined,
  'paddle': Icons.swap_horiz,
  'broom_v': Icons.call_merge,
  'sweep': Icons.swipe_outlined,
  'collection': Icons.touch_app_outlined,
  'magnet': Icons.sensors,
  'attraction': Icons.radar,
  'double_spawn': Icons.filter_2_outlined,
  'generator': Icons.speed,
  'launcher': Icons.rocket_launch_outlined,
  'launcher_rate': Icons.av_timer,
  'reward': Icons.toll_outlined,
  'combo': Icons.local_fire_department_outlined,
  'capture_all': Icons.blur_circular,
  'capture_recharge': Icons.hourglass_bottom,
  'boost': Icons.rocket_launch_outlined,
  'boost_power': Icons.bolt,
  'boost_duration': Icons.timer_outlined,
  'boost_recharge': Icons.hourglass_bottom,
  'duration': Icons.more_time,
  'robot': Icons.smart_toy_outlined,
  'robot_speed': Icons.bolt,
};

String _description(SkillNode node) => switch (node.definition.id) {
  'prestige' =>
    'Termina esta partida y abre Prestigio. Reinicia monedas y mejoras normales; conserva estrellas y mejoras permanentes',
  'hand' =>
    'Lleva hasta ${node.upgrade.value.toInt()} bolas: agarra una y acerca la mano a otras para atraerlas',
  'walls' => 'Aumenta la potencia del rebote de las cuatro paredes',
  'hand_grip' =>
    'Atrae y sujeta más rápido las bolas adicionales mientras llevas una bola',
  'bat' => 'Golpea bolas con un bate: un dedo traslada y dos giran',
  'broom' => 'Desbloquea la escoba para empujar grupos de bolas',
  'paddle' => 'Aumenta la anchura de la escoba',
  'broom_v' => 'Reúne las bolas con una escoba en V',
  'sweep' => 'Recoge monedas al deslizar el dedo',
  'collection' => 'Recoge varias monedas cercanas en cada pulsación, sin imán',
  'magnet' => 'Atrae monedas cerca del dedo solo con la mano vacía',
  'attraction' => 'Amplía el alcance del imán de monedas',
  'double_spawn' => 'Emite dos bolas a la vez sin cambiar la cadencia',
  'generator' => 'El generador lanza bolas más rápido',
  'launcher' => 'Un segundo generador orientable en la zona inferior',
  'launcher_rate' => 'Reduce el intervalo entre disparos del lanzador',
  'reward' => 'Obtén más monedas por cada bola',
  'combo' => 'Encadena capturas para multiplicar sus monedas',
  'capture_all' =>
    'Activa la habilidad cargada para capturar todas las bolas; recoge sus monedas',
  'capture_recharge' => 'Reduce el tiempo de carga de Captura total',
  'boost' =>
    'Activa la habilidad cargada para acelerar temporalmente el generador',
  'boost_power' =>
    'Aumenta la velocidad del generador durante la aceleración especial',
  'boost_duration' =>
    'Mantiene activa la aceleración especial durante más tiempo',
  'boost_recharge' => 'Reduce el tiempo de carga de la aceleración especial',
  'duration' => 'Aumenta el tiempo de producción del día',
  'robot' => 'Un robot empuja bolas hacia el hoyo',
  'robot_speed' => 'El robot se mueve más rápido',
  _ => '',
};

TextSpan _summary(SkillNode node) {
  if (node.definition.id == 'prestige') {
    return const TextSpan(
      text:
          'Reinicia esta partida y abre la tienda de prestigio. Se pedirá confirmación.',
    );
  }
  final value = node.upgrade.value;
  String number(double n) =>
      n == n.roundToDouble() ? '${n.toInt()}' : n.toStringAsFixed(2);
  final (before, amount, after) = switch (node.definition.id) {
    'hand' => ('La mano agarra ', number(value), ' bolas.'),
    'bat' => (
      node.level == 1
          ? 'Desbloquea el bate: golpe manual '
          : 'Golpe manual del bate ',
      '×${number(value)}',
      '.',
    ),
    'walls' => ('Rebote de paredes ', '×${number(value)}', '.'),
    'hand_grip' => ('Fuerza de agarre ', '×${number(value)}', '.'),
    'paddle' => ('La escoba abarca ', number(value * 4), ' u.'),
    'collection' => ('Recoge monedas a ', number(value), ' u de distancia.'),
    'magnet' || 'attraction' => ('El imán alcanza ', number(value), ' u.'),
    'launcher' => ('', 'Desbloquea el lanzador', ' independiente.'),
    'launcher_rate' => ('Dispara cada ', number(value), ' s.'),
    'generator' => ('Genera ', number(1 / value), ' bolas/s.'),
    'reward' => ('Cada bola da ', number(value), '.'),
    'combo' => ('', 'Desbloquea la racha', ' de capturas.'),
    'capture_all' => (
      '',
      'Captura todas las bolas',
      ' con una habilidad recargable.',
    ),
    'capture_recharge' => ('Captura total carga en ', number(value), ' s.'),
    'boost' => ('', 'Acelera el generador', ' con una habilidad recargable.'),
    'boost_power' => ('Aceleración especial ', '×${number(value)}', '.'),
    'boost_duration' => ('La aceleración dura ', number(value), ' s.'),
    'boost_recharge' => ('La aceleración carga en ', number(value), ' s.'),
    'duration' => ('Produce durante ', number(value), ' s.'),
    'robot_speed' => ('El robot avanza a ', number(value), ' u/s.'),
    'double_spawn' => (
      'El generador emite ',
      number(value),
      ' bolas a la vez.',
    ),
    'robot' => ('', '1 robot', ' empuja bolas al hoyo.'),
    'broom' => ('', 'Desbloquea la escoba', ' para empujar bolas.'),
    'broom_v' => ('', 'Transforma la escoba en V', ' para reunir bolas.'),
    'sweep' => ('', 'Recoge deslizando', ' el dedo.'),
    _ => ('', node.definition.name, '.'),
  };
  return TextSpan(
    children: [
      TextSpan(text: before),
      if (node.definition.id == 'reward')
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: CoinIcon(),
        ),
      TextSpan(
        text: amount,
        style: const TextStyle(
          color: Color(0xff22c55e),
          fontWeight: FontWeight.w800,
        ),
      ),
      TextSpan(text: after),
    ],
  );
}

String _value(SkillNode node, double value) {
  String number(double n) => n == n.roundToDouble()
      ? '${n.toInt()}'
      : n.toStringAsFixed(n.abs() < 1 ? 2 : 1);
  return switch (node.definition.unit) {
    'multiplier' => '×${number(value == 0 ? 1 : value)}',
    'unlock' => value > 0 ? 'Desbloqueada' : 'Sin desbloquear',
    'action' => value > 0 ? 'Nueva partida' : 'Partida actual',
    'seconds' => '${number(value)} s',
    'coins' => '${number(value)} monedas/bola',
    'balls_per_spawn' => '${number(value)} bolas/emisión',
    'balls' => '${number(value)} bolas',
    'robots' => '${number(value)} robot',
    'broom_width' => '${number(value * 4)} u',
    'logical_units_per_second' => '${number(value)} u/s',
    _ => '${number(value)} u',
  };
}

class _TreePainter extends CustomPainter {
  _TreePainter(this.nodes, this.levels, this.paths);
  final Map<(String, String), List<(double, double)>> paths;
  final List<SkillNode> nodes;
  final Map<String, int> levels;
  @override
  void paint(Canvas canvas, Size size) {
    final dots = Paint()..color = const Color(0xff26344a);
    for (var x = 0.0; x < size.width; x += 30) {
      for (var y = 0.0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1, dots);
      }
    }
    for (final node in nodes) {
      for (final id in node.parents) {
        final parent = nodes.where((n) => n.id == id).firstOrNull;
        if (parent == null) continue;
        final paint = Paint()
          ..color = node.owned(levels)
              ? _typeColor(node).withValues(alpha: .8)
              : const Color(0xff475269)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        final start = Offset(parent.x, parent.y);
        final end = Offset(node.x, node.y);
        final points = paths[(id, node.id)]!
            .map((p) => Offset(p.$1, p.$2))
            .toList();
        final firstDirection =
            (points[1] - start) / (points[1] - start).distance;
        final lastDirection =
            (end - points[points.length - 2]) /
            (end - points[points.length - 2]).distance;
        final path = Path()
          ..moveTo(
            start.dx + firstDirection.dx * 28,
            start.dy + firstDirection.dy * 28,
          );
        for (final bend in points.skip(1).take(points.length - 2)) {
          path.lineTo(bend.dx, bend.dy);
        }
        path.lineTo(
          end.dx - lastDirection.dx * 28,
          end.dy - lastDirection.dy * 28,
        );
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) => true;
}
