import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/upgrades/domain/skill_tree.dart';
import 'package:incremental_hole_game/features/upgrades/presentation/skill_tree_screen.dart';
import '../test_support.dart';

void main() {
  final catalog = testCatalog();
  final tree = SkillTree(catalog);
  bool buy(GameSession session, String id) =>
      session.purchase(catalog.definitions.firstWhere((d) => d.id == id));

  test(
    'map has nine initial paths, five-level lines and the agreed crossings',
    () {
      expect(tree.nodes, hasLength(55));
      expect(tree.root.id, 'hand:1');
      expect(
        tree
            .visible({'hand': 1})
            .where((n) => !n.owned({'hand': 1}))
            .map((n) => n.id)
            .toSet(),
        {
          'prestige:1',
          'generator:1',
          'reward:1',
          'hand:2',
          'combo:1',
          'walls:1',
          'bat:1',
        },
      );
      expect(tree.byId('broom:1').parents, ['hand:2']);
      expect(tree.byId('paddle:1').parents, ['broom:1']);
      expect(tree.byId('broom_v:1').parents, ['paddle:1']);
      expect(tree.byId('duration:1').parents, ['generator:2']);
      expect(tree.nodes.any((n) => n.definition.id == 'collection'), isFalse);
      expect(tree.byId('robot:1').parents.toSet(), {'paddle:2'});
      expect(tree.byId('double_spawn:1').parents.toSet(), {
        'generator:3',
        'paddle:3',
      });
      for (final id in [
        'hand',
        'generator',
        'reward',
        'paddle',
        'duration',
        'robot_speed',
      ]) {
        expect(
          catalog.definitions.firstWhere((d) => d.id == id).levels,
          hasLength(5),
        );
      }
    },
  );

  test('session enforces every path and crossing, and purchases persist', () {
    final session = GameSession(catalog, MemoryStore())
      ..economy.balance = 100000;
    for (final id in [
      'generator',
      'reward',
      'broom',
      'robot',
      'double_spawn',
    ]) {
      expect(buy(session, id), isFalse, reason: id);
    }
    expect(buy(session, 'hand'), isTrue);
    expect(buy(session, 'generator'), isTrue);
    expect(buy(session, 'duration'), isFalse);
    expect(buy(session, 'generator'), isTrue);
    expect(buy(session, 'duration'), isTrue);
    expect(buy(session, 'hand'), isTrue);
    expect(buy(session, 'broom'), isTrue);
    expect(buy(session, 'paddle'), isTrue);
    expect(buy(session, 'broom_v'), isTrue);
    expect(buy(session, 'paddle'), isTrue);
    expect(buy(session, 'robot'), isTrue);
    expect(buy(session, 'generator'), isTrue);
    expect(buy(session, 'double_spawn'), isFalse);
    expect(buy(session, 'paddle'), isTrue);
    expect(buy(session, 'double_spawn'), isTrue);
    session.startDay();
    final restored = GameSession(catalog, MemoryStore())
      ..restore(session.snapshot());
    expect(restored.levels, session.levels);
    expect(restored.economy.balance, session.economy.balance);
    expect(restored.board!.settings['balls_per_spawn'], 2);
    expect(restored.board!.settings['magnet_radius'], 0);
    expect(restored.board!.settings['production_duration'], 18);
  });

  test(
    'legacy purchases survive without free prerequisites and keep their active balance',
    () {
      final owned = {
        'generator': 1,
        'duration': 2,
        'broom': 1,
        'paddle': 1,
        'robot': 1,
        'collection': 1,
        'magnet': 1,
      };
      for (var version = 1; version <= 3; version++) {
        final historical = catalog.settings(
          owned,
          balanceVersion: version == 3 ? 3 : 1,
        );
        final board = Board(historical);
        final json =
            jsonDecode(GameSession(catalog, MemoryStore()).snapshot())
                as Map<String, dynamic>;
        json['version'] = version;
        json.remove('grandfathered');
        json['levels'] = Map.of(owned);
        json['balance'] = 123;
        json['run'] = {
          'remaining': historical['production_duration'] + 5,
          'collected': 0,
          'generated': 0,
          'settings': historical.toJson()..remove('hand_capacity'),
          'balanceVersion': 3,
          'board': board.toJson()..remove('combo'),
        };
        if (version == 1) {
          for (final key in ['broom_unlocked', 'v_unlocked', 'coin_sweep']) {
            json['run']['settings'].remove(key);
          }
        }
        final migrated = GameSession(catalog, MemoryStore())
          ..restore(jsonEncode(json));
        expect(
          migrated.levels,
          Map.of(owned)
            ..remove('collection')
            ..remove('magnet'),
        );
        expect(
          migrated.board!.settings['spawn_interval'],
          historical['spawn_interval'],
        );
        final reopened = GameSession(catalog, MemoryStore())
          ..restore(migrated.snapshot());
        expect(
          reopened.levels,
          Map.of(owned)
            ..remove('collection')
            ..remove('magnet'),
        );
        reopened.finishDay();
        expect(
          buy(reopened, 'generator'),
          isFalse,
        ); // next purchase follows the new map
        reopened.startDay();
        expect(reopened.board!.settings.balanceVersion, 18);
        expect(reopened.board!.settings['production_duration'], 21);
        expect(reopened.levels.containsKey('hand'), isFalse);
        expect(reopened.levels.containsKey('sweep'), isFalse);
        expect(reopened.economy.balance, 123);
        expect(
          () =>
              GameSession(catalog, MemoryStore()).restore(reopened.snapshot()),
          returnsNormally,
        );
      }
    },
  );

  test(
    'current saves cannot claim a new mechanic as an inherited purchase',
    () {
      final session = GameSession(catalog, MemoryStore());
      final json = jsonDecode(session.snapshot()) as Map<String, dynamic>;
      json['levels'] = {'double_spawn': 1};
      json['grandfathered'] = {'double_spawn': 1};
      expect(() => session.restore(jsonEncode(json)), throwsFormatException);
      expect(session.levels, isEmpty);
    },
  );

  test(
    'double emission produces a spaced pair and respects technical limits',
    () {
      final settings = catalog.settings({'double_spawn': 1});
      final board = Board(settings);
      for (var i = 0; i < 40; i++) {
        board.update(1 / 60, producing: true);
      }
      expect(board.balls, hasLength(2));
      expect(
        (board.balls[0].position - board.balls[1].position).length,
        greaterThan(board.radius * 2),
      );
      settings.values['ball_limit'] = 3;
      board.balls.clear();
      board.balls.addAll([
        Ball(board.nextId++, const Vec(50, 300), Vec.zero),
        Ball(board.nextId++, const Vec(90, 300), Vec.zero),
      ]);
      for (var i = 0; i < 40; i++) {
        board.update(1 / 60, producing: true);
      }
      expect(board.balls, hasLength(3));
      board.enterClosing();
      final count = board.balls.length;
      board.update(1, producing: true);
      expect(board.balls, hasLength(count));
    },
  );

  test('attraction increases coin reach only while the pointer is active', () {
    final board = Board(
      catalog.settings({'magnet': 1, 'attraction': 3}, balanceVersion: 14),
    );
    final coin = Coin(board.nextId++, const Vec(190, 250), 2, landing: 0);
    board.coins.add(coin);
    board.update(.1, producing: false);
    expect(coin.position.x, 190);
    board.touch(const Vec(100, 250));
    var collected = 0;
    for (var i = 0; i < 120; i++) {
      collected += board.update(1 / 60, producing: false).collected;
    }
    expect(collected, 2);
    final locked = Board(catalog.settings({'magnet': 1}, balanceVersion: 14));
    final distant = Coin(locked.nextId++, const Vec(190, 250), 2, landing: 0);
    locked.coins.add(distant);
    locked.touch(const Vec(100, 250));
    locked.update(1, producing: false);
    expect(distant.position.x, 190);
  });

  test(
    'maximum production remains finite, bounded and within the ball cap',
    () {
      final settings = catalog.settings({
        for (final d in catalog.definitions) d.id: d.levels.length,
      });
      final board = Board(settings);
      for (var i = 0; i < 200; i++) {
        board.balls.add(
          Ball(
            board.nextId++,
            Vec(30 + (i % 20) * 15, 180 + (i ~/ 20) * 15),
            Vec.zero,
          ),
        );
      }
      for (var i = 0; i < 1500; i++) {
        board.update(1 / 60, producing: true);
      }
      expect(board.balls.length, lessThanOrEqualTo(200));
      expect(board.balls.length + board.captured, greaterThanOrEqualTo(200));
      for (final b in board.balls) {
        expect(
          b.position.x,
          inInclusiveRange(board.radius, Board.width - board.radius),
        );
        expect(
          b.position.y,
          inInclusiveRange(board.radius, Board.height - board.radius),
        );
        expect(b.velocity.length, lessThanOrEqualTo(380));
        expect(b.velocity.length.isFinite, isTrue);
      }
      expect(settings['ball_value'], 13);
      expect(
        settings['spawn_interval'],
        closeTo(1 / (1.5 * math.pow(1.25, 5)), 1e-9),
      );
    },
  );

  testWidgets(
    'unowned nodes are dim, affordable nodes are white and bought nodes keep their type',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = GameSession(catalog, MemoryStore());
      await tester.pumpWidget(
        MaterialApp(home: SkillTreeScreen(session: session)),
      );
      await tester.pumpAndSettle();
      final root = find.byKey(const ValueKey('node-hand:1'));
      Color? iconColor() => tester
          .widget<Icon>(
            find.descendant(
              of: root,
              matching: find.byIcon(Icons.back_hand_outlined),
            ),
          )
          .color;
      expect(iconColor(), const Color(0xff64738a));
      session.economy.balance = 20;
      session.setSound(false);
      await tester.pumpAndSettle();
      expect(iconColor(), const Color(0xffe2e8f0));
      await tester.tap(root);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('hold-purchase'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(session.levels['hand'], 1);
      expect(iconColor(), const Color(0xffa855f7));
      expect(find.byKey(const ValueKey('tree-start-day')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.pendingWrites;
      session.dispose();
    },
  );

  testWidgets('node types keep their colors when purchased and show a check', (
    tester,
  ) async {
    final session = GameSession(catalog, MemoryStore())..levels['hand'] = 1;
    await tester.pumpWidget(
      MaterialApp(home: SkillTreeScreen(session: session)),
    );
    await tester.pumpAndSettle();
    final root = find.byKey(const ValueKey('node-hand:1'));
    final icon = tester.widget<Icon>(
      find.descendant(
        of: root,
        matching: find.byIcon(Icons.back_hand_outlined),
      ),
    );
    expect(icon.color, const Color(0xffa855f7));
    expect(
      find.descendant(of: root, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await session.pendingWrites;
    session.dispose();
  });
}
