import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/game_session.dart';
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
    duration: const Duration(seconds: 3),
  )..addStatusListener(_holdStatus);
  late SkillNode selected = tree.root;
  SkillNode? holding;
  int? activePointer;
  Offset? origin;
  bool moved = false;
  final pointers = <int>{};
  Size? viewport;
  bool initialized = false;
  String? announcement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.session.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    if (holding != null && !_canBuy(holding!)) _cancel();
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

  bool _canBuy(SkillNode node) =>
      !node.owned(widget.session.levels) &&
      (widget.session.levels[node.definition.id] ?? 0) == node.level - 1 &&
      tree.unlocked(node, widget.session.levels) &&
      widget.session.purchaseBlock(node.definition) == null;

  void _cancel() {
    hold.reset();
    holding = null;
  }

  void _holdStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final node = holding;
    holding = null;
    hold.reset();
    if (node == null || !_canBuy(node)) return;
    if (widget.session.purchase(node.definition)) {
      if (widget.session.sound) {
        unawaited(SystemSound.play(SystemSoundType.click));
      }
      unawaited(HapticFeedback.lightImpact());
      setState(
        () => announcement = 'Mejora adquirida. Nuevos caminos disponibles.',
      );
    }
  }

  void _down(PointerDownEvent event, SkillNode node) {
    if (pointers.length > 1 || activePointer != null) return;
    activePointer = event.pointer;
    origin = event.position;
    moved = false;
    if (selected.id == node.id && _canBuy(node)) {
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
        if (selected.id != node.id) announcement = null;
        selected = node;
      });
    }
  }

  void _center(Size size, {SkillNode? node}) {
    final target = node ?? selected;
    const scale = .85;
    transform.value = Matrix4.diagonal3Values(scale, scale, scale)
      ..setTranslationRaw(
        size.width / 2 - target.x * scale,
        size.height / 2 - target.y * scale,
        0,
      );
  }

  void _zoom(double factor) {
    _cancel();
    final size = viewport;
    if (size == null) return;
    final current = transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(.35, 1.8);
    final focal = Offset(size.width / 2, size.height / 2);
    final scene = transform.toScene(focal);
    transform.value = Matrix4.diagonal3Values(next, next, next)
      ..setTranslationRaw(
        focal.dx - scene.dx * next,
        focal.dy - scene.dy * next,
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
    final visible = tree.visible(session.levels);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('Árbol de mejoras', style: TextStyle(fontSize: 19)),
        actions: [
          const Icon(Icons.monetization_on_outlined, color: _gold, size: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 0, 20, 0),
            child: Center(
              child: Text(
                '${session.economy.balance}',
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
              ),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Arrastra para explorar · Pellizca para acercarte',
                  style: TextStyle(color: Color(0xffa5b2c5), fontSize: 12),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    viewport = constraints.biggest;
                    if (!initialized) {
                      initialized = true;
                      _center(viewport!, node: tree.root);
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
                            minScale: .35,
                            maxScale: 1.8,
                            child: SizedBox(
                              width: 1500,
                              height: 1600,
                              child: CustomPaint(
                                painter: _TreePainter(visible, session.levels),
                                child: Stack(
                                  children: [
                                    for (final node in visible)
                                      Positioned(
                                        key: ValueKey('position-${node.id}'),
                                        left: node.x - 40,
                                        top: node.y - 40,
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
                        Positioned(
                          right: 12,
                          top: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xf023334b),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Acercar',
                                  onPressed: () => _zoom(1.25),
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  tooltip: 'Alejar',
                                  onPressed: () => _zoom(.8),
                                  icon: const Icon(Icons.remove),
                                ),
                                IconButton(
                                  tooltip: 'Centrar selección',
                                  onPressed: () {
                                    _cancel();
                                    _center(viewport!);
                                  },
                                  icon: const Icon(
                                    Icons.center_focus_strong_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          bottom: 12,
                          child: IgnorePointer(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 15,
                                  color: _mint,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${tree.nodes.where((n) => n.owned(session.levels)).length} adquiridas',
                                  style: const TextStyle(
                                    color: _mint,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              _details(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _node(SkillNode node) {
    final owned = node.owned(widget.session.levels);
    final affordable = _canBuy(node);
    final isSelected = selected.id == node.id;
    final color = owned
        ? _mint
        : affordable
        ? _gold
        : const Color(0xff64738a);
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
            width: 80,
            height: 98,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: owned
                        ? const Color(0xff233f40)
                        : affordable
                        ? const Color(0xff3b3325)
                        : const Color(0xff172235),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Colors.white : color,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: affordable
                        ? [
                            BoxShadow(
                              color: _gold.withValues(alpha: .16),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        owned
                            ? Icons.check_rounded
                            : _icons[node.definition.id],
                        size: 30,
                        color: color,
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
                const SizedBox(height: 3),
                ExcludeSemantics(
                  child: Text(
                    owned ? '✓' : '${node.upgrade.cost}',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _details() {
    final node = selected;
    final owned = node.owned(widget.session.levels);
    final affordable = _canBuy(node);
    final current = node.level == 1
        ? (widget.session.catalog.base[node.definition.effect] ?? 0)
        : node.definition.levels[node.level - 2].value;
    final next = node.upgrade.value;
    final isInterval = node.definition.effect == 'spawn_interval';
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
          Row(
            children: [
              Icon(
                _icons[node.definition.id],
                size: 22,
                color: owned ? _mint : _gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _description(node),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (percentage != null)
            Text(
              '+${percentage.toStringAsFixed(1)} %  ·  ${_value(node, current)} → ${_value(node, next)}',
              style: const TextStyle(color: _mint, fontSize: 14),
            ),
          if (percentage == null && node.definition.unit != 'unlock')
            Text(_value(node, next), style: const TextStyle(color: _mint)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  owned ? 'Adquirida' : '${node.upgrade.cost} monedas',
                  style: TextStyle(
                    color: owned ? _mint : _gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              if (!owned && !affordable)
                Flexible(
                  child: Text(
                    !tree.unlocked(node, widget.session.levels)
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
                    ? 'Mantén pulsado tres segundos para comprar'
                    : 'Saldo insuficiente',
                child: Listener(
                  key: const ValueKey('hold-purchase'),
                  onPointerDown: (e) => _down(e, node),
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
                                    ? 'Mantén pulsado · 3 s'
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
          const SizedBox(height: 6),
          const Text(
            'Las mejoras se aplican al próximo día.',
            style: TextStyle(color: Color(0xffa5b2c5), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

const _icons = {
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

String _description(SkillNode node) => switch (node.definition.id) {
  'broom' => 'Desbloquea la escoba para empujar grupos de bolas',
  'paddle' => 'Aumenta la anchura de la escoba',
  'broom_v' => 'Reúne las bolas con una escoba en V',
  'sweep' => 'Recoge monedas al deslizar el dedo',
  'collection' => 'Aumenta el radio de recogida de monedas',
  'magnet' => 'Atrae monedas cerca del dedo mientras tocas',
  'generator' => 'El generador lanza bolas más rápido',
  'reward' => 'Obtén más monedas por cada bola',
  'duration' => 'Aumenta el tiempo de producción del día',
  'robot' => 'Un robot empuja bolas hacia el hoyo',
  'robot_speed' => 'El robot se mueve más rápido',
  _ => '',
};

String _value(SkillNode node, double value) {
  String number(double n) => n == n.roundToDouble()
      ? '${n.toInt()}'
      : n.toStringAsFixed(n.abs() < 1 ? 2 : 1);
  return switch (node.definition.unit) {
    'seconds' => '${number(value)} s',
    'coins' => '${number(value)} monedas/bola',
    'robots' => '${number(value)} robot',
    'broom_width' => '${number(value * 4)} u',
    'logical_units_per_second' => '${number(value)} u/s',
    _ => '${number(value)} u',
  };
}

class _TreePainter extends CustomPainter {
  _TreePainter(this.nodes, this.levels);
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
              ? _mint.withValues(alpha: .65)
              : const Color(0xff475269)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        final start = Offset(parent.x, parent.y);
        final end = Offset(node.x, node.y);
        final midY = (start.dy + end.dy) / 2;
        canvas.drawPath(
          Path()
            ..moveTo(start.dx, start.dy)
            ..cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) => true;
}
