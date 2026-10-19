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
    duration: const Duration(seconds: 1),
  )..addStatusListener(_holdStatus);
  SkillNode? selected;
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
    final visible = tree.visible(session.levels);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        actions: [
          const Icon(Icons.monetization_on_outlined, color: _gold, size: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 0, 20, 0),
            child: Center(
              child: Text(
                '\$${session.economy.balance}',
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
                      final value = transform.value;
                      transform.value = value.clone()
                        ..setTranslationRaw(
                          value.storage[12] +
                              (viewport!.width - previousViewport.width) / 2,
                          value.storage[13] +
                              (viewport!.height - previousViewport.height) / 2,
                          0,
                        );
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
                              width: 880,
                              height: 1120,
                              child: CustomPaint(
                                painter: _TreePainter(visible, session.levels),
                                child: Stack(
                                  children: [
                                    for (final node in visible)
                                      Positioned(
                                        key: ValueKey('position-${node.id}'),
                                        left: node.x - 40,
                                        top: node.y - 32,
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
                    onPressed: session.running
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

  Widget _node(SkillNode node) {
    final owned = node.owned(widget.session.levels);
    final affordable = _canBuy(node);
    final isSelected = selected?.id == node.id;
    final typeColor = _typeColor(node);
    final color = owned
        ? typeColor
        : affordable
        ? const Color(0xffe2e8f0)
        : const Color(0xff64738a);
    final locked = !tree.unlocked(node, widget.session.levels);
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${_description(node)}. ${owned ? 'Adquirida' : '\$${node.upgrade.cost}'}.',
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
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 64,
                  height: 64,
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
                      Icon(_icons[node.definition.id], size: 30, color: color),
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
    final node = selected!;
    final owned = node.owned(widget.session.levels);
    final affordable = _canBuy(node);
    final current = node.level == 1
        ? (node.definition.id == 'attraction'
              ? 65.0
              : widget.session.catalog.base[node.definition.effect] ?? 0)
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
                child: Text(
                  owned ? 'Adquirida' : '\$${node.upgrade.cost}',
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
                                affordable ? 'Comprar · 1 s' : 'No disponible',
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
  'generator' || 'double_spawn' => const Color(0xff22c55e),
  'reward' => const Color(0xffeab308),
  'sweep' ||
  'collection' ||
  'magnet' ||
  'attraction' => const Color(0xff3b82f6),
  'duration' => const Color(0xfff97316),
  'robot' || 'robot_speed' => const Color(0xfff43f5e),
  _ => const Color(0xffa855f7),
};

const _icons = {
  'hand': Icons.back_hand_outlined,
  'broom': Icons.cleaning_services_outlined,
  'paddle': Icons.swap_horiz,
  'broom_v': Icons.call_merge,
  'sweep': Icons.swipe_outlined,
  'collection': Icons.touch_app_outlined,
  'magnet': Icons.sensors,
  'attraction': Icons.radar,
  'double_spawn': Icons.filter_2_outlined,
  'generator': Icons.speed,
  'reward': Icons.monetization_on_outlined,
  'duration': Icons.more_time,
  'robot': Icons.smart_toy_outlined,
  'robot_speed': Icons.bolt,
};

String _description(SkillNode node) => switch (node.definition.id) {
  'hand' =>
    'Lleva hasta ${node.upgrade.value.toInt()} bolas: agarra una y acerca la mano a otras para atraerlas',
  'broom' => 'Desbloquea la escoba para empujar grupos de bolas',
  'paddle' => 'Aumenta la anchura de la escoba',
  'broom_v' => 'Reúne las bolas con una escoba en V',
  'sweep' => 'Recoge monedas al deslizar el dedo',
  'collection' => 'Aumenta el radio de recogida de monedas',
  'magnet' => 'Atrae monedas cerca del dedo mientras tocas',
  'attraction' => 'Amplía el alcance del imán de monedas',
  'double_spawn' => 'Emite dos bolas a la vez sin cambiar la cadencia',
  'generator' => 'El generador lanza bolas más rápido',
  'reward' => 'Obtén más monedas por cada bola',
  'duration' => 'Aumenta el tiempo de producción del día',
  'robot' => 'Un robot empuja bolas hacia el hoyo',
  'robot_speed' => 'El robot se mueve más rápido',
  _ => '',
};

TextSpan _summary(SkillNode node) {
  final value = node.upgrade.value;
  String number(double n) =>
      n == n.roundToDouble() ? '${n.toInt()}' : n.toStringAsFixed(2);
  final (before, amount, after) = switch (node.definition.id) {
    'hand' => ('La mano agarra ', number(value), ' bolas.'),
    'paddle' => ('La escoba abarca ', number(value * 4), ' u.'),
    'collection' => ('Recoge monedas a ', number(value), ' u de distancia.'),
    'magnet' || 'attraction' => ('El imán alcanza ', number(value), ' u.'),
    'generator' => ('Genera ', number(1 / value), ' bolas/s.'),
    'reward' => ('Cada bola da ', '\$${number(value)}', '.'),
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
    'unlock' => value > 0 ? 'Desbloqueada' : 'Sin desbloquear',
    'seconds' => '${number(value)} s',
    'coins' => '\$${number(value)}/bola',
    'balls_per_spawn' => '${number(value)} bolas/emisión',
    'balls' => '${number(value)} bolas',
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
              ? _typeColor(node).withValues(alpha: .8)
              : const Color(0xff475269)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        final start = Offset(parent.x, parent.y);
        final end = Offset(node.x, node.y);
        // Cross-branch dependencies use empty corridors instead of crossing nodes.
        final bends = switch ((id, node.id)) {
          ('generator:3', 'double_spawn:1') => [
            Offset(32, start.dy),
            Offset(32, end.dy),
          ],
          ('paddle:3', 'double_spawn:1') => [
            Offset(660, start.dy),
            const Offset(660, 840),
            const Offset(88, 840),
          ],
          ('sweep:1', 'robot:1') => [
            const Offset(440, 216),
            const Offset(748, 216),
            Offset(748, end.dy),
          ],
          _ => <Offset>[],
        };
        final points = [start, ...bends, end];
        final firstDirection =
            (points[1] - start) / (points[1] - start).distance;
        final lastDirection =
            (end - points[points.length - 2]) /
            (end - points[points.length - 2]).distance;
        final path = Path()
          ..moveTo(
            start.dx + firstDirection.dx * 36,
            start.dy + firstDirection.dy * 36,
          );
        for (final bend in bends) {
          path.lineTo(bend.dx, bend.dy);
        }
        path.lineTo(
          end.dx - lastDirection.dx * 36,
          end.dy - lastDirection.dy * 36,
        );
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) => true;
}
