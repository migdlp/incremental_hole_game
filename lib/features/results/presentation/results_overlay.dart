import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../board/presentation/coin_icon.dart';
import '../domain/results_data.dart';
import '../domain/results_sequence.dart';
import 'results_transfer.dart';

const _navy = Color(0xff111c2e), _card = Color(0xff23334b);
const _gold = Color(0xfff5c45d), _mint = Color(0xff8dd4b2);

class ResultsOverlay extends StatefulWidget {
  const ResultsOverlay({
    super.key,
    required this.data,
    required this.walletAnchor,
    required this.onShop,
    this.onCoinReceipt,
  });
  final ResultsData data;
  final GlobalKey walletAnchor;
  final Future<void> Function() onShop;
  final void Function(int count)? onCoinReceipt;
  @override
  State<ResultsOverlay> createState() => _ResultsOverlayState();
}

class _ResultsOverlayState extends State<ResultsOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ResultsSequence sequence = ResultsSequence(widget.data);
  late final Ticker ticker = createTicker(_tick);
  final rootKey = GlobalKey(), walletKey = GlobalKey();
  late final rowKeys = List.generate(
    widget.data.stacks.length,
    (_) => GlobalKey(),
  );
  final scroll = ScrollController();
  Duration? last;
  int? tapGeneration;
  int lastRow = -1, _receivedCoins = 0;
  bool shopOpened = false;
  Rect? anchor;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      sequence.completeAll();
      _receivedCoins = sequence.receivedCoins;
      ticker.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      ticker.stop();
      last = null;
    } else if (!sequence.done && !MediaQuery.disableAnimationsOf(context)) {
      last = null;
      ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = last == null ? 0.0 : (elapsed - last!).inMicroseconds / 1e6;
    last = elapsed;
    sequence.advance(dt);
    final received = sequence.receivedCoins;
    if (received > _receivedCoins) {
      widget.onCoinReceipt?.call(received - _receivedCoins);
    }
    _receivedCoins = received;
    if (sequence.done) ticker.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    sequence.dispose();
    scroll.dispose();
    super.dispose();
  }

  Rect? _rect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    final root = rootKey.currentContext?.findRenderObject();
    if (box is! RenderBox ||
        root is! RenderBox ||
        !box.hasSize ||
        !root.hasSize) {
      return null;
    }
    return root.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
  }

  void _afterLayout() {
    if (!mounted) return;
    final measured = _rect(widget.walletAnchor);
    if (measured != null && measured != anchor) {
      setState(() => anchor = measured);
    }
    final wanted = sequence.showHole
        ? rowKeys.length + (sequence.done ? 1 : 0)
        : sequence.row;
    // A new row is laid out one frame after its reveal starts.
    if (!sequence.showHole &&
        wanted < rowKeys.length &&
        rowKeys[wanted].currentContext == null) {
      return;
    }
    if (lastRow != wanted) {
      lastRow = wanted;
      if (scroll.hasClients) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
      }
    }
  }

  void _skip() {
    final generation = tapGeneration;
    tapGeneration = null;
    if (generation != null) sequence.skip(generation);
    _receivedCoins = sequence.receivedCoins;
    if (sequence.done) ticker.stop();
  }

  Widget _number(
    int value, {
    Color color = Colors.white,
    double size = 18,
    Key? key,
  }) => Semantics(
    label: '$value',
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        resultNumber(value),
        key: key,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
  Widget _coinCard() => _panel(
    key: const ValueKey('visual-day-results'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Monedas conseguidas',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        for (var i = 0; i < widget.data.stacks.length; i++)
          if (sequence.reveal(i) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Opacity(
                opacity: sequence.reveal(i),
                child: Row(
                  key: ValueKey(
                    'results-row-${widget.data.stacks[i].denomination.amount}',
                  ),
                  children: [
                    Transform.scale(
                      scale:
                          .8 +
                          .2 * Curves.easeOutBack.transform(sequence.reveal(i)),
                      child: CoinIcon(
                        key: rowKeys[i],
                        denomination: widget.data.stacks[i].denomination,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _number(
                          sequence.counted(i),
                          key: ValueKey('results-count-$i'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _number(
                          sequence.counted(i) *
                              widget.data.stacks[i].denomination.amount,
                          color: _gold,
                          key: ValueKey('results-subtotal-$i'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Divider(color: Color(0xff40516b), height: 1),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Total del día',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CoinIcon(),
                        const SizedBox(width: 6),
                        Text(
                          resultNumber(sequence.total),
                          key: const ValueKey('results-total'),
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _panel({Key? key, required Widget child}) => Container(
    key: key,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
  Widget _holeCard() {
    final d = widget.data,
        p = Curves.easeInOut.transform(sequence.holeProgress);
    final food = d.foodBefore + ((d.foodAfter - d.foodBefore) * p).floor();
    final target = d.target;
    final met = target != null && food >= target;
    final fraction = target == null ? 0.0 : (food / target).clamp(0.0, 1.0);
    final appeared = sequence.done ? 1.0 : (sequence.age / .2).clamp(0.0, 1.0);
    return Opacity(
      opacity: appeared,
      child: _panel(
        key: const ValueKey('feeding-summary'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Progreso del hoyo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final holeWidth = (c.maxWidth * .4).clamp(76.0, 128.0);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: holeWidth,
                      child: Column(
                        children: [
                          SizedBox(
                            width: holeWidth,
                            height: holeWidth,
                            child: CustomPaint(
                              painter: _HolePainter(
                                fraction,
                                sequence.holeProgress,
                                !sequence.done,
                              ),
                            ),
                          ),
                          _number(
                            (d.captured * p).floor(),
                            size: 28,
                            key: const ValueKey('results-captured'),
                          ),
                          const Text(
                            'Bolas al hoyo',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (met)
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _mint,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Cuota completada',
                                    key: ValueKey('results-quota-met'),
                                    style: TextStyle(
                                      color: _mint,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'Cuota en curso',
                              style: TextStyle(
                                color: _mint,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            target == null
                                ? 'Alimentación: ${resultNumber(food)}'
                                : 'Cuota actual: ${resultNumber(food)} / ${resultNumber(target)}',
                            key: const ValueKey('results-food'),
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (target != null)
                            Text(
                              'Restante: ${resultNumber(math.max(0, target - food))}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          Text(
                            'Jornadas restantes: ${d.daysRemaining}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            if (sequence.done && d.nextTarget != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Próximo objetivo: ${resultNumber(d.nextTarget!)}',
                  style: const TextStyle(
                    color: _mint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AnimatedBuilder(
      animation: sequence,
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _afterLayout());
        return LayoutBuilder(
          builder: (context, constraints) {
            final right = anchor == null
                ? 16.0
                : math.max(8.0, constraints.maxWidth - anchor!.right);
            final top = anchor?.top ?? 15.0;
            return Stack(
              key: rootKey,
              children: [
                const Positioned.fill(
                  child: ModalBarrier(
                    dismissible: false,
                    color: Color(0xb3111c2e),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      math.max(72, top + 46),
                      14,
                      16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 620,
                          maxHeight: 740,
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => tapGeneration = sequence.generation,
                          onTapCancel: () => tapGeneration = null,
                          onTap: _skip,
                          child: Opacity(
                            opacity: sequence.phase == ResultsPhase.opening
                                ? (sequence.age /
                                          ResultsSequence.openingDuration)
                                      .clamp(0.0, 1.0)
                                : 1.0,
                            child: Material(
                              key: const ValueKey('day-results-popup'),
                              color: _navy,
                              borderRadius: BorderRadius.circular(26),
                              clipBehavior: Clip.antiAlias,
                              child: Semantics(
                                scopesRoute: true,
                                explicitChildNodes: true,
                                namesRoute: true,
                                label: 'Resultados del día',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        18,
                                        18,
                                        18,
                                        14,
                                      ),
                                      child: Text(
                                        'Resultados del día',
                                        style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: SingleChildScrollView(
                                        controller: scroll,
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          14,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _coinCard(),
                                            if (sequence.showHole) ...[
                                              const SizedBox(height: 12),
                                              _holeCard(),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (sequence.done)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          0,
                                          14,
                                          14,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            key: const ValueKey('results-shop'),
                                            onPressed: () async {
                                              if (shopOpened) return;
                                              shopOpened = true;
                                              await widget.onShop();
                                              if (mounted) shopOpened = false;
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _gold,
                                              foregroundColor: _navy,
                                              minimumSize: const Size(48, 54),
                                              shape: const StadiumBorder(),
                                            ),
                                            icon: const Icon(
                                              Icons.storefront_outlined,
                                            ),
                                            label: const Text(
                                              'Tienda',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
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
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: top,
                  right: right,
                  child: IgnorePointer(
                    child: Transform.scale(
                      scale: 1 + sequence.walletPulse * .08,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CoinIcon(key: walletKey),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth - 100,
                              ),
                              child: _number(
                                sequence.done
                                    ? widget.data.balance
                                    : sequence.wallet,
                                color: _gold,
                                size: 21,
                                key: const ValueKey('results-wallet'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: ResultsTransferPainter(
                        sequence,
                        (i) => _rect(rowKeys[i]),
                        () => _rect(walletKey),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

class _HolePainter extends CustomPainter {
  _HolePainter(this.fraction, this.progress, this.animate);
  final double fraction, progress;
  final bool animate;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .55),
        r = size.width * .33;
    final p = Paint()..color = const Color(0xff697583);
    canvas.drawCircle(center, r + 4, p);
    p.color = const Color(0xff172333);
    canvas.drawCircle(center, r, p);
    p.color = const Color(0xff080f1b);
    canvas.drawCircle(center + const Offset(0, -2), r * .82, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xff3c5660);
    canvas.drawCircle(center, r + 10, p);
    p.color = _mint;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r + 10),
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      p,
    );
    if (animate) {
      p.style = PaintingStyle.fill;
      for (var i = 0; i < 5; i++) {
        final t = (progress * 1.8 - i * .14).clamp(0.0, 1.0);
        if (t <= 0 || t >= 1) continue;
        p.color = i.isEven ? const Color(0xfff0d596) : const Color(0xffccd7df);
        final a = Offset(center.dx + (i - 2) * 8, 0);
        canvas.drawCircle(
          Offset.lerp(a, center, t * t)!,
          4.5 * (1 - math.pow(t, 5)),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HolePainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.progress != progress ||
      oldDelegate.animate != animate;
}
