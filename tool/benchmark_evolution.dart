import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:incremental_hole_game/core/vec.dart';
import 'package:incremental_hole_game/features/board/domain/board.dart';
import 'package:incremental_hole_game/features/evolution/domain/evolution.dart';
import 'package:incremental_hole_game/features/upgrades/domain/catalog.dart';
void main() {
  final catalog=UpgradeCatalog.fromCsv(File('docs/balance.csv').readAsStringSync());
  final reports=<Map<String,Object>>[];
  for(final count in [100,200,500]) {
    for(final enabled in [false,true]) {
      final b=Board(catalog.settings({'walls':3,'bat':1,'launcher':1}));
      if(enabled) {
        final r=EvolutionRun(levels:{for(final s in EvolutionSkill.catalogue)s.id:5});
        r.pulseClock=19.95;r.gravityClock=29.95;r.hunger.count=24;
        for(var i=0;i<9;i++){r.capture(1);}
        b.evolution=r;
      }
      for(var i=0;i<count;i++) {
        b.balls.add(Ball(b.nextId++,Vec(15+(i%20)*17,180+(i~/20)*13),Vec((i%3-1)*120,-70),heavy:enabled&&i%10==0));
      }
      final samples=<int>[];var warmMax=0;
      for(var frame=-60;frame<600;frame++) {
        final w=Stopwatch()..start();b.update(1/60,producing:true);w.stop();
        if(frame<0){warmMax=math.max(warmMax,w.elapsedMicroseconds);}else{samples.add(w.elapsedMicroseconds);}
      }
      samples.sort();
      reports.add({'balls_initial':count,'evolution_maxed':enabled,'p50_us':samples[300],'p95_us':samples[570],
        'p99_us':samples[594],'max_us':samples.last,'warmup_max_us':warmMax,'balls_final':b.balls.length,
        'rss_bytes':ProcessInfo.currentRss,'finite_velocities':b.balls.every((v)=>v.velocity.length.isFinite&&v.velocity.length<=380.0001)});
    }
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert({'environment':'GitHub Actions Linux AOT; simulation only, no Android GPU/audio/render', 'reports':reports}));
}
