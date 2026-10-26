import 'dart:math' as math;

enum EvolutionId { whirlpool, hunger, pulse, directed, ram, gravity, frenzy, effort, ration, millionaire, midas, luck }

/// Approved E03 tables. No weights, rarities, costs or further levels.
class EvolutionSkill {
  const EvolutionSkill(this.kind, this.name, this.description, this.values, {this.duration = 0, this.cooldown = 0, this.threshold = 0, this.window = 0, this.period = 0});
  final EvolutionId kind;
  final String name, description;
  final List<double> values;
  final double duration, cooldown, window, period;
  final int threshold;
  String get id => 'E03-${(kind.index+1).toString().padLeft(2,'0')}';
  double value(int level) => level == 0 ? 0 : values[level-1];
  static const maxLevel = 5, gravityFraction = .4, standardLaunchSpeed = 85.0;
  static const steering = .25, ramMass = 3.0;
  static const millionaireDurations = [3.0,6.0,7.0,8.0,10.0];
  static const catalogue = [
    EvolutionSkill(EvolutionId.whirlpool,'Remolino','Las capturas rápidas atraen las bolas cercanas al agujero.',[1.5,1.75,2,2.25,2.5],duration:2,cooldown:10,threshold:10,window:3),
    EvolutionSkill(EvolutionId.hunger,'Hambre insaciable','Tras varias capturas, el agujero se expande brevemente.',[.04,.06,.08,.10,.12],duration:4,cooldown:12,threshold:25),
    EvolutionSkill(EvolutionId.pulse,'Latido','El agujero emite pulsos que empujan las bolas hacia su centro.',[.05,.10,.15,.20,.25],period:20),
    EvolutionSkill(EvolutionId.directed,'Rebote dirigido','Algunos rebotes se orientan parcialmente hacia el agujero.',[.10,.20,.30,.40,.50]),
    EvolutionSkill(EvolutionId.ram,'Bola ariete','El generador produce ocasionalmente una bola más pesada.',[50,45,40,35,30]),
    EvolutionSkill(EvolutionId.gravity,'Gravedad traviesa','Una fuerza periódica acerca las bolas al agujero.',[.05,.10,.15,.20,.25],period:30,duration:2),
    EvolutionSkill(EvolutionId.frenzy,'Disparo frenético','El generador principal produce más deprisa.',[.04,.08,.12,.16,.20]),
    EvolutionSkill(EvolutionId.effort,'Último esfuerzo','El generador se acelera al final de la jornada.',[.10,.15,.20,.25,.30]),
    EvolutionSkill(EvolutionId.ration,'Doble ración','El generador produce bolas adicionales periódicamente.',[40,35,30,25,20]),
    EvolutionSkill(EvolutionId.millionaire,'Racha millonaria','Las capturas rápidas activan una racha de monedas.',[2,2,2,3,3],cooldown:10,threshold:10,window:3),
    EvolutionSkill(EvolutionId.midas,'Toque de Midas','Aumenta la posibilidad de generar bolas doradas.',[.005,.010,.015,.020,.025]),
    EvolutionSkill(EvolutionId.luck,'Golpe de suerte','Algunas capturas conceden una recompensa extra.',[.01,.02,.03,.04,.05]),
  ];
  static EvolutionSkill of(EvolutionId id) => catalogue[id.index];
  static EvolutionSkill? find(String id) => catalogue.where((s)=>s.id==id).firstOrNull;
  static Map<String,int> readLevels(dynamic raw) {
    if(raw is! Map<String,dynamic> || raw.entries.any((e)=>find(e.key)==null || e.value is! int || e.value<0 || e.value>maxLevel)) {
      throw const FormatException('Niveles E03 inválidos');
    }
    return Map.unmodifiable(raw.cast<String,int>());
  }
}

class EvolutionEffect {
  double remaining=0, cooldown=0;
  int level=0;
  final captures=<double>[];
  int count=0;
  bool get ready => remaining<=0 && cooldown<=0;
  void advance(double dt, double recharge) {
    if(remaining>0) {
      final active=math.min(dt,remaining); remaining=math.max(0,remaining-active);dt-=active;
      if(remaining<=0) {cooldown=recharge;captures.clear();count=0;}
    }
    cooldown=math.max(0,cooldown-dt);
  }
  void finish(double recharge) {
    if(remaining>0) cooldown=math.max(cooldown,recharge);
    remaining=0;captures.clear();
  }
  Map<String,dynamic> toJson()=>{'remaining':remaining,'cooldown':cooldown,'level':level,'captures':captures,'count':count};
}

/// Run-owned state. Levels are a read-only reference to the independent meta map.
class EvolutionRun {
  EvolutionRun({this.levels=const {},this.randomState=42,this.cardRandom=79});
  Map<String,int> levels;
  int randomState,cardRandom;
  int lastQuota=0,pending=0,serial=0,ramCycles=0,rationCycles=0,pendingRam=0,pendingRation=0;
  List<String> options=[];
  bool closingPending=false;
  double dayElapsed=0,pulseClock=0,gravityClock=0;
  bool pulseNow=false;
  final whirlpool=EvolutionEffect(), hunger=EvolutionEffect(), millionaire=EvolutionEffect(), gravity=EvolutionEffect();
  int level(EvolutionId id)=>levels[EvolutionSkill.of(id).id]??0;
  double value(EvolutionId id)=>EvolutionSkill.of(id).value(level(id));
  bool get hasChoices=>pending>0 && options.isNotEmpty;
  int get moneyMultiplier=>millionaire.remaining>0?EvolutionSkill.of(EvolutionId.millionaire).value(millionaire.level).toInt():1;
  double random() {randomState=(1664525*randomState+1013904223)&0xffffffff;return randomState/4294967296;}
  double _cardRandom() {cardRandom=(1664525*cardRandom+1013904223)&0xffffffff;return cardRandom/4294967296;}
  void grant(int quota) {
    if(quota<=lastQuota)return;
    lastQuota=quota; pending++; offer();
  }
  void offer() {
    if(options.isNotEmpty || pending==0)return;
    final eligible=EvolutionSkill.catalogue.where((s)=>level(s.kind)<EvolutionSkill.maxLevel).map((s)=>s.id).toList();
    if(eligible.isEmpty){pending=0;return;}
    for(var i=0;i<math.min(3,eligible.length);i++) {
      final j=i+(_cardRandom()*(eligible.length-i)).floor();
      final tmp=eligible[i];eligible[i]=eligible[j];eligible[j]=tmp;
    }
    options=List.unmodifiable(eligible.take(3));
  }
  Map<String,int> resolve(String id,{required int expectedSerial}) {
    if(!hasChoices || serial!=expectedSerial || !options.contains(id))throw StateError('Elección E03 no disponible');
    final next={...levels,id:(levels[id]??0)+1};
    levels=Map.unmodifiable(next);pending--;serial++;options=[];offer();return levels;
  }
  void beginDay() {dayElapsed=0;whirlpool.captures.clear();millionaire.captures.clear();closingPending=false;}
  void finishDay() {
    whirlpool.finish(EvolutionSkill.of(EvolutionId.whirlpool).cooldown);
    hunger.finish(EvolutionSkill.of(EvolutionId.hunger).cooldown);
    millionaire.finish(EvolutionSkill.of(EvolutionId.millionaire).cooldown);
    gravity.finish(0);whirlpool.count=0;millionaire.count=0;pulseNow=false;
  }
  void advance(double dt) {
    pulseNow=false;dayElapsed+=dt;
    whirlpool.advance(dt,EvolutionSkill.of(EvolutionId.whirlpool).cooldown);
    hunger.advance(dt,EvolutionSkill.of(EvolutionId.hunger).cooldown);
    millionaire.advance(dt,EvolutionSkill.of(EvolutionId.millionaire).cooldown);
    gravity.advance(dt,0);
    if(level(EvolutionId.pulse)>0){pulseClock+=dt;if(pulseClock+1e-9>=EvolutionSkill.of(EvolutionId.pulse).period){pulseClock=math.max(0,pulseClock-EvolutionSkill.of(EvolutionId.pulse).period);pulseNow=true;}}
    if(level(EvolutionId.gravity)>0){gravityClock+=dt;if(gravityClock+1e-9>=EvolutionSkill.of(EvolutionId.gravity).period){gravityClock=math.max(0,gravityClock-EvolutionSkill.of(EvolutionId.gravity).period);gravity.level=level(EvolutionId.gravity);gravity.remaining=EvolutionSkill.of(EvolutionId.gravity).duration;}}
  }
  void _capture(EvolutionId id,EvolutionEffect effect) {
    final l=level(id),skill=EvolutionSkill.of(id);
    if(l==0 || !effect.ready)return;
    if(skill.window>0){effect.captures.removeWhere((t)=>t<dayElapsed-skill.window-1e-9);effect.captures.add(dayElapsed);effect.count=effect.captures.length;}
    else {effect.count++;}
    if(effect.count>=skill.threshold){effect.level=l;effect.remaining=id==EvolutionId.millionaire?EvolutionSkill.millionaireDurations[l-1]:skill.duration;effect.count=0;effect.captures.clear();}
  }
  int capture(int base) {
    _capture(EvolutionId.whirlpool,whirlpool);_capture(EvolutionId.hunger,hunger);_capture(EvolutionId.millionaire,millionaire);
    final lucky=level(EvolutionId.luck)>0 && random()<value(EvolutionId.luck);
    return base*(lucky?2:1)*moneyMultiplier;
  }
  void cycle() {
    if(level(EvolutionId.ram)>0){ramCycles++;if(ramCycles>=value(EvolutionId.ram)){ramCycles-=value(EvolutionId.ram).toInt();pendingRam++;}}
    if(level(EvolutionId.ration)>0){rationCycles++;if(rationCycles>=value(EvolutionId.ration)){rationCycles-=value(EvolutionId.ration).toInt();pendingRation++;}}
  }
  double productionTime(double dt,double duration) {
    final late=(dayElapsed+dt-math.max(dayElapsed,duration*.75)).clamp(0,dt);
    return dt*(1+value(EvolutionId.frenzy))+late*value(EvolutionId.effort);
  }
  Map<String,dynamic> toJson()=>{
    'random':randomState,'cardRandom':cardRandom,'lastQuota':lastQuota,'pending':pending,'serial':serial,'options':options,'closingPending':closingPending,
    'ramCycles':ramCycles,'rationCycles':rationCycles,'pendingRam':pendingRam,'pendingRation':pendingRation,
    'dayElapsed':dayElapsed,'pulseClock':pulseClock,'gravityClock':gravityClock,
    'whirlpool':whirlpool.toJson(),'hunger':hunger.toJson(),'millionaire':millionaire.toJson(),'gravity':gravity.toJson(),
  };
  factory EvolutionRun.fromJson(Map<String,dynamic> j,{required Map<String,int> levels}) {
    int integer(String key,{int max=0x1fffffffffffff}) {final n=j[key];if(n is! int||n<0||n>max)throw const FormatException('Contador E03 inválido');return n;}
    double number(Map m,String key,{double max=1e12}) {final n=m[key];if(n is! num||!n.isFinite||n<0||n>max)throw const FormatException('Tiempo E03 inválido');return n.toDouble();}
    final s=EvolutionRun(levels:levels,randomState:integer('random',max:0xffffffff),cardRandom:integer('cardRandom',max:0xffffffff))
      ..lastQuota=integer('lastQuota')..pending=integer('pending')..serial=integer('serial')
      ..ramCycles=integer('ramCycles',max:49)..rationCycles=integer('rationCycles',max:39)
      ..pendingRam=integer('pendingRam')..pendingRation=integer('pendingRation')
      ..dayElapsed=number(j,'dayElapsed')..pulseClock=number(j,'pulseClock',max:20)..gravityClock=number(j,'gravityClock',max:30);
    final raw=j['options'];
    if(raw is! List || raw.any((v)=>v is! String || EvolutionSkill.find(v)==null || (levels[v]??0)>=5) || raw.toSet().length!=raw.length || j['closingPending'] is! bool)throw const FormatException('Selector E03 inválido');
    s.options=List.unmodifiable(raw.cast<String>());s.closingPending=j['closingPending'] as bool;
    final eligible=EvolutionSkill.catalogue.where((v)=>s.level(v.kind)<5).length;
    if((s.pending==0?s.options.isNotEmpty:s.options.length!=math.min(3,eligible)) || s.pending>s.lastQuota || (s.pending>0&&eligible==0))throw const FormatException('Elecciones E03 incoherentes');
    void readEffect(String key,EvolutionId id,EvolutionEffect effect) {
      final m=j[key];if(m is! Map<String,dynamic>)throw const FormatException('Efecto E03 inválido');
      final l=m['level'],count=m['count'],captures=m['captures'];final skill=EvolutionSkill.of(id);
      if(l is! int||l<0||l>s.level(id)||count is! int||count<0||count>=math.max(1,skill.threshold)||captures is! List||captures.length>9)throw const FormatException('Activación E03 inválida');
      effect.level=l;effect.count=count;effect.remaining=number(m,'remaining',max:id==EvolutionId.millionaire?10:skill.duration);effect.cooldown=number(m,'cooldown',max:skill.cooldown);
      if((effect.remaining>0&&(l==0||effect.cooldown>0)) || (l==0&&effect.remaining>0))throw const FormatException('Recarga E03 inválida');
      double previous=-1;for(final t in captures){if(t is! num||!t.isFinite||t<0||t>s.dayElapsed||t<previous)throw const FormatException('Ventana E03 inválida');effect.captures.add(t.toDouble());previous=t.toDouble();}
      if((!effect.ready && (count!=0||captures.isNotEmpty)) || (skill.window>0&&effect.count!=captures.length))throw const FormatException('Capturas E03 inválidas');
    }
    readEffect('whirlpool',EvolutionId.whirlpool,s.whirlpool);readEffect('hunger',EvolutionId.hunger,s.hunger);readEffect('millionaire',EvolutionId.millionaire,s.millionaire);readEffect('gravity',EvolutionId.gravity,s.gravity);
    return s;
  }
}
