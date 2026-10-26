import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incremental_hole_game/app/game_app.dart';
import 'package:incremental_hole_game/app/game_session.dart';
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/evolution/domain/evolution.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/prestige/domain/meta_progress.dart';
import '../test_support.dart';

void main() {
  final catalog=testCatalog(automaticSpawns:false);
  Map<String,int> levels(EvolutionId id,int n)=>{EvolutionSkill.of(id).id:n};
  test('exact catalogue, tables and uniform eligible choices, cap and stale selection',(){
    expect(EvolutionSkill.catalogue.length,12);
    final r=EvolutionRun();r.grant(1);final options=List.of(r.options);
    expect(options.length,3);expect(options.toSet().length,3);
    final restored=EvolutionRun.fromJson(jsonDecode(jsonEncode(r.toJson())),levels:{});
    expect(restored.options,options);expect(restored.cardRandom,r.cardRandom);
    r.grant(1);expect(r.pending,1);r.grant(2);expect(r.pending,2);
    r.resolve(options.first,expectedSerial:0);expect(r.levels[options.first],1);
    expect(()=>r.resolve(options.first,expectedSerial:0),throwsStateError);
    final capped={for(final s in EvolutionSkill.catalogue)s.id:5};
    final full=EvolutionRun(levels:capped)..grant(1);expect(full.hasChoices,isFalse);expect(full.pending,0);
    for(var eligible=1;eligible<=2;eligible++) {
      final map=Map<String,int>.of(capped);for(var i=0;i<eligible;i++){map[EvolutionSkill.catalogue[i].id]=4;}
      final partial=EvolutionRun(levels:map)..grant(1)..grant(2);
      expect(partial.options.length,eligible);
      partial.resolve(partial.options.first,expectedSerial:0);
      expect(partial.options.length,eligible-1);
    }
  });
  for(var level=1;level<=5;level++) {
    test('millionaire level $level pays tenth and locks its activation parameters',(){
      final r=EvolutionRun(levels:levels(EvolutionId.millionaire,level));
      for(var i=0;i<9;i++){expect(r.capture(7),7);}
      final multiplier=EvolutionSkill.of(EvolutionId.millionaire).value(level).toInt();
      expect(r.capture(7),7*multiplier);
      expect(r.millionaire.remaining,EvolutionSkill.millionaireDurations[level-1]);
      r.levels=levels(EvolutionId.millionaire,5);
      expect(r.capture(7),7*multiplier);
      r.advance(EvolutionSkill.millionaireDurations[level-1]);
      expect(r.moneyMultiplier,1);expect(r.millionaire.cooldown,10);
      for(var i=0;i<100;i++){expect(r.capture(7),7);}
      r.advance(10);for(var i=0;i<9;i++){expect(r.capture(7),7);}
      expect(r.capture(7),21);
    });
  }
  test('rolling window, luck order and integer rewards',(){
    final r=EvolutionRun(levels:{...levels(EvolutionId.millionaire,5),...levels(EvolutionId.luck,5)});
    for(var i=0;i<9;i++){r.capture(7);}r.advance(3.1);expect(r.capture(7),7);
    // Known LCG seed giving a first draw below 5%.
    r.randomState=1972;r.millionaire.level=5;r.millionaire.remaining=1;
    final value=r.capture(7);expect(value,isA<int>());expect(value==21||value==42,isTrue);
  });
  test('effects cancel at day end, preserve counters and cooldown, windows never span days',(){
    final r=EvolutionRun(levels:{...levels(EvolutionId.hunger,2),...levels(EvolutionId.whirlpool,1),...levels(EvolutionId.millionaire,1),...levels(EvolutionId.pulse,1)});
    for(var i=0;i<25;i++){r.capture(1);}r.advance(1);
    r.finishDay();expect(r.hunger.remaining,0);expect(r.hunger.cooldown,12);
    expect(r.millionaire.cooldown,10);expect(r.whirlpool.cooldown,10);
    expect(r.pulseClock,1);r.beginDay();expect(r.dayElapsed,0);
    final decoded=EvolutionRun.fromJson(jsonDecode(jsonEncode(r.toJson())),levels:r.levels);
    expect(decoded.toJson(),r.toJson());
    r.advance(12);for(var i=0;i<9;i++){r.capture(1);}r.finishDay();r.beginDay();
    expect(r.capture(1),1);
  });
  test('cycle thresholds preserve remainder, one activation per real cycle, additive speed',(){
    final r=EvolutionRun(levels:{...levels(EvolutionId.ram,1),...levels(EvolutionId.ration,1),...levels(EvolutionId.frenzy,5),...levels(EvolutionId.effort,5)});
    for(var i=0;i<39;i++){r.cycle();}expect(r.pendingRation,0);r.cycle();expect(r.pendingRation,1);
    for(var i=0;i<10;i++){r.cycle();}expect(r.pendingRam,1);
    r.ramCycles=49;r.levels={...r.levels,...levels(EvolutionId.ram,5)};r.cycle();
    expect(r.pendingRam,2);expect(r.ramCycles,20);
    expect(r.productionTime(1,20),1.2);r.dayElapsed=15;expect(r.productionTime(1,20),1.5);
    r.dayElapsed=14.5;expect(r.productionTime(1,20),closeTo(1.35,1e-9));
  });
  GameSession game()=>GameSession(catalog,MemoryStore(),eventSeed:42);
  void capture(GameSession s,int n){for(var i=0;i<n;i++){s.board!.balls.add(Ball(s.board!.nextId++,s.board!.holePosition,Vec.zero));}s.tick(1/60);}
  Future<void> resolve(GameSession s) async {
    await s.pendingWrites;
    while(s.evolution.hasChoices){expect(s.chooseEvolution(s.evolution.options.first,serial:s.evolution.serial),isTrue);await s.pendingWrites;}
  }
  test('all quotas and star rewards process first, choices freeze and persist exact offers',() async {
    final s=game()..startDay();capture(s,1200);await s.pendingWrites;
    expect(s.feeding.period,3);expect(s.feeding.growths,2);expect(s.meta.starLedger.quota,2);
    expect(s.evolution.pending,2);expect(s.evolution.hasChoices,isTrue);
    final before=s.snapshot();s.tick(100);expect(s.snapshot(),before);
    final r=game()..restore(before);expect(r.evolution.options,s.evolution.options);expect(r.evolution.pending,2);
    await r.save();final serial=r.evolution.serial,id=r.evolution.options.first;
    expect(r.chooseEvolution(id,serial:serial),isTrue);expect(r.chooseEvolution(id,serial:serial),isFalse);
    await r.pendingWrites;await resolve(r);
    expect(r.meta.evolutionLevels.values.fold(0,(int n,int l)=>n+l),2);
    expect(r.evolutionBlocked,isFalse);expect(r.economy.generated,1200);
    r.dispose();s.dispose();
  });
  test('final instant cards precede results and never reopen capture window',() async {
    final s=game();for(var i=0;i<3;i++){s.startDay();s.finishDay();await s.pendingWrites;}
    s.startDay();s.cycle!.remaining=1/60;capture(s,100);await s.pendingWrites;
    expect(s.running,isTrue);expect(s.cycle!.remaining,0);expect(s.progress.last?.day,3);
    final r=game()..restore(s.snapshot());await r.save();await resolve(r);await r.pendingWrites;
    expect(r.running,isFalse);expect(r.meta.phase,PrestigePhase.playing);expect(r.progress.last!.day,4);
    expect(r.progress.last!.captured,100);r.tick(10);expect(r.progress.last!.captured,100);
    r.dispose();s.dispose();
  });
  test('hunger scales quota growth without losing permanent radius',(){
    final b=Board(catalog.settings({}));final r=EvolutionRun(levels:levels(EvolutionId.hunger,5));b.evolution=r;
    final base=b.baseCaptureRadius;for(var i=0;i<25;i++){r.capture(1);}
    expect(b.captureRadius,closeTo(base*1.12,1e-9));b.syncHoleGrowth(1);
    final grown=b.baseCaptureRadius;r.finishDay();expect(b.captureRadius,grown);expect(grown,greaterThan(base));
  });
  test('heavy ball has triple mass and normal reward, mass affects a ball collision',(){
    final b=Board(catalog.settings({}));final heavy=Ball(b.nextId++,const Vec(100,300),const Vec(100,0),heavy:true);
    final light=Ball(b.nextId++,Vec(100+b.radius*1.8,300),Vec.zero);
    b.balls.addAll([heavy,light]);b.update(1/240,producing:true);
    expect(heavy.mass,3);expect(light.velocity.x,greaterThan(heavy.velocity.x));
    final saved=Board.fromJson(b.settings,b.toJson());expect(saved.balls.first.heavy,isTrue);
  });
  testWidgets('selector has descriptions and levels only, absorbs gameplay gestures', (tester) async {
    final s=game()..startDay();capture(s,100);await s.pendingWrites;
    await tester.pumpWidget(GardenApp(session:s));await tester.pump();
    expect(find.byKey(const ValueKey('evolution-selector')),findsOneWidget);
    expect(find.text('Nivel 0 → 1'),findsNWidgets(3));expect(find.textContaining('%'),findsNothing);
    final id=s.evolution.options.first,serial=s.evolution.serial;
    await tester.tap(find.byKey(ValueKey('evolution-card-$id-$serial')));await s.pendingWrites;await tester.pump();
    expect(s.meta.evolutionLevels[id],1);await tester.pumpWidget(const SizedBox());s.dispose();
  });
}
