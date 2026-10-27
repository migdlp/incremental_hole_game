# AUD01 — Economía, producción, captura y balance

**Proyecto:** Feed the Hole · **Versión:** 0.23.0+36 · balance v 20 · JSON v 16  
**Fuente auditada:** `0778d139d4a85124e0af2a9f89d595dc19159430` · rama `build/apk-0.6.0+13`  
**Fecha:** 27/10/2026 · auditoría estática; sin cambios de gameplay o balance.

## Qué se puede calcular y qué no

**VERIFICADO EN CÓDIGO:** fórmulas, precios, límites y orden de eventos que siguen. **INFERIDO:** máximos ideales y ejemplos aritméticos etiquetados. **DESCONOCIDO:** porcentajes de captura humana, ingreso típico por minuto, cuotas alcanzables por perfil de jugador y porcentaje de burbujas rotas. Generación no equivale a captura; estrellas potenciales no equivalen a estrellas cobradas; iconos no equivalen a dinero.

## 1. Tiempo de jornada

| Concepto | Valor real | Fuente |
|---|---|---|
| Producción base |15 segundos activos | `docs/balance.csv:production_duration`; `GameSession.startDay` |
| Producción niveles I–V |18/21/24/27/30 s | CSV `duration` |
| Recogida exclusiva |0 s; eliminada | `startDay` fuerza `DayCycle(...closing:0)`; C01 |
| Paso principal |1/60 s; dt entrante se limita a 0,1 s por tick | `GameSession.tick` |
| Física |Subpasos≤1/240 s | `Board.update` |
| Pausa, segundo plano, E03 |Sin avance de producción, simulación, microbatch ni efectos de gameplay | `tick`, `pause/resume`, `evolutionBlocked` |
| Resultados |Apertura 0,22 s +1,2 s por denominación no vacía +1,4 s alimentación; saltables | `ResultsSequence`; hasta 5 denominaciones actuales→7,62 s sin saltar |
| Transición visual residual |Hasta 0,45 s para vuelos ya activos, sin tiempo extra de bolas | `finishDay/_rewardTransitionRemaining` |

La duración medida con reloj real puede diferir de segundos activos si hay pausas o frames muy largos: el código descarta del tick lo que excede 0,1 s. No modelar una jornada como 15 s de reloj real bajo todas las cargas.

## 2. Producción principal

**Base:** intervalo `I0=2/3s`,1 bola por ciclo, velocidad inicial `(U(-18,18),−85)` u/s. El primer ciclo ocurre al acumular el primer intervalo; no hay bola inmediata gratuita al iniciar. Fuente `Board.update/_emitMain`, `EvolutionSkill.standardLaunchSpeed`.

| Nivel generador | Intervalo s | Ciclos/s ideales | Ciclos en 15 s, sin aceleraciones ni bloqueo | Coste incremental | Acumulado |
|---:|---:|---:|---:|---:|---:|
| 0 | 0.666666666667 | 1.5 | 22 | 0 | 0 |
| 1 | 0.533333333333 | 1.875 | 28 | 30 | 30 |
| 2 | 0.426666666667 | 2.34375 | 35 | 50 | 80 |
| 3 | 0.341333333333 | 2.9296875 | 43 | 80 | 160 |
| 4 | 0.273066666667 | 3.66210938 | 54 | 130 | 290 |
| 5 | 0.218453333333 | 4.57763672 | 68 | 220 | 510 |

`I(L)=I0×0,8^L`, L0–5, según las tablas actuales. Esta igualdad describe el catálogo; el runtime lee los valores explícitos, no recalcula una curva libre. Por ciclo intenta `b=1` o `b=2` con Doble emisión. **INFERIDO:** sin bloqueo y con multiplicadores constantes, `ciclos=floor((spawnClockInicial+tiempoEfectivo)/I)`. `spawnClock` comienza 0 cada jornada y persiste al restaurar la misma.

### Aceleraciones y extras

En producción, con nivel E03:

```
f(t) = 1 + frenzy + (t >= 0,75·D ? effort : 0)
b(t) = boostActivo ? boost_multiplier : 1
incremento spawnClock = integral(f(t)·b(t), dt)
```

El código integra el paso que cruza 75% y el final del boost (`EvolutionRun.productionTime`, `Board.update`). Frenzy y Effort **se suman**, el boost **multiplica**. Valores máximos: frecuencia×1,2 al inicio;×1,5 al final; con boost de potencia máxima×3:×3,6 y×4,5 respectivamente. “Disparo” se refiere a frecuencia, no a velocidad de la bola.

| Fuente | Extra | Qué cuenta | Bloqueo/fin |
|---|---|---|---|
| Doble emisión |+1 intento cada ciclo |Ciclo sigue 1 |Si no cabe, intento se pierde; no cola ordinaria |
| H02 |5 extras cada 20 ciclos |Solo principal normal |Pendientes físicos, reintenta; resto y pendientes cruzan jornadas |
| E03 Ariete |1 cada 50/45/40/35/30 |Solo ciclos principales, masa 3 |Pendiente reintentado, hasta 1 por update |
| E03 Doble ración |1 cada 40/35/30/25/20 |Solo ciclos principales |Pendiente reintentado, hasta 1 por update |
| H04 |1 dorada por jornada, si consigue emitirse |No ciclo |Reintenta mientras produce; si totalmente bloqueada no garantizada |
| Lanzador |1 por disparo exitoso |No ciclo principal |Intento fallido consumido |

**INFERIDO**, tasas largas si todas las extras caben: por ciclo principal se obtienen `b +0,25(H02)+1/kRam+1/kRation` bolas. Con todo al máximo y doble emisión: `2+0,25+1/30+1/20=2,333333…` bolas/ciclo. Para jornadas finitas utilizar divisiones enteras y restos guardados, no esa media; H04 y lanzador se suman aparte. Los ciclos normales **sí avanzan H02/E03 aunque una emisión ordinaria falle**: no sustituir ciclos por “bolas realmente emitidas”.

Generador al nivel V, jornada 30 y doble emisión sin boost/cartas: **137 ciclos y 274 intentos de bola** (ideal sin bloqueo, no 274 bolas garantizadas). Principal en base en 15 s:22 intentos; cuatro jornadas sin mejorar ni extras darían 88 intentos, insuficientes para cuota 100 aun con captura 100%. Esto no prueba derrota inevitable: se pueden comprar mejoras desde el primer cierre y las cartas/P02 alteran partidas futuras. Sí señala que BAL01 debe estudiar la progresión temprana y el dinero realmente capturable.

### Azar y doradas

- Principal natural: `p=min(1, max(0, 0.01 + midas))`. AlV de Midas p=0,035. La probabilidad se limita al intervalo 0–1 (0–100%).
- Extras de H02, Ariete y Doble ración pasan por `_emitMain`, mismas reglas naturales, salvo H04 que fuerza dorada.
- Lanzador usa RNG propio y p=0,01 fija; no Midas.
- Bolas no tienen tiers o valor individual guardado. El valor global de jornada aplica a todas, incluso ariete.
- RNG de bolas inicial por jornada `day×7919`; LCG32 bits `(1664525·state+1013904223)&0xffffffff`. El resultado depende también de intentos exitosos y bloqueos, que consumen números en distintos puntos.
- RNG de eventos inicia con `eventSeed` explícito o `math.Random()`; su estado se guarda. E01, E02, lanzador y E03 separan/subderivan sus secuencias; no afirmar independencia estadística perfecta de todos los generadores.

## 3. Segundo generador y población

Fuente `Launcher` y `Board._advanceLauncher/_contactLauncher`.

| Parámetro | Base / niveles |
|---|---|
| Intervalo |2,4 s; mejoras 1,8/1,2/0,8 s |
| Tasa ideal |0,4166667;0,5555556;0,8333333;1,25 bolas/s |
| Disparos ideales en 15 s |6;8;12;18 |
| Velocidad |280 u/s, orientación 360°; no mejora de potencia |
| Aparición |Salida del cañón, comprueba bola/cuerpo/escoba/bate/burbujas y pared |
| Zona |y≥420, todo cuerpo+cañón dentro de 360×560 |
| Resistencia |Stress=min(120, profundidad×3000+cierreNormal); presión vectorial total debe superar 400 |
| Desplazamiento |Masaefectiva 12, respuesta 12/s, damping 8/s, máximo 12 u/s; sin presión se detiene; no giro por impactos |

El límite global es **200 bolas simultáneas**, no 200 generadas al día ni límite conjunto de bolas+burbujas. H04 pendiente reserva 1: otras emisiones usan 199 hasta emitir la dorada. Los cuerpos de estrellas no consumen ese contador pero sí bloquean salidas. Principal no crea si hay bola a≤2,2×radio, burbuja superpuesta o cuerpo del lanzador; extras prueban una cuadrícula 3×7. Lanzador empuja obstrucciones parciales con impulso 100 en eje y consume el intento; nunca libera una ráfaga acumulada de disparos fallidos.

No existe fuente normal que genere bolas por colisionar entre sí ni duplicadora. DEBUG puede inyectar bolas: excluirlas de las tasas de producción.

## 4. Captura real: recorrido y fórmulas

```
Ciclo/intento → validación de salida/población → spawned++ y Ball
→ integración y colisiones → captura → desaparición física inmediata
→ absorción visual0,24s + recompensa/feeding registrados
```

Un intento rechazado **no incrementa `spawned`**. Cada bola física permanece en `balls` hasta que una condición de captura la elimina; no se borra al rebotar. Al cerrar se descartan las bolas no capturadas con el tablero; no se convierten en dinero ni alimentación y no pasan a la siguiente jornada.

Captura confirmada en `captureBalls`, dentro de `Board.update`, si:

1. ID está marcado por Captura total, **o**
2. el segmento de desplazamiento ha cruzado el disco de radio de captura (`segmentDistance`), **o**
3. el centro de la bola está a distancia≤radio efectivo del centro del hoyo.

El disco se compara con el **centro** de la bola, sin sumar su radio 6. Hay comprobación antes y después de colisiones por subpaso; `removeWhere` elimina bola tras el primer cobro. Así una bola rápida no salta el hoyo ni genera dos capturas en el mismo paso. Los agarres son controlados, pero una bola agarrada que alcanza el disco puede capturarse normalmente. Cada captura física incluida en `events.captured` alimenta exactamente+1 en `_step`; los viejos contadores `normalFood/instantFood` son dinero histórico, **no cuotas**.

### Geometría, fuerzas y cuellos de botella

| Parámetro | Fórmula / valor | Fuente |
|---|---|---|
| Centro |(180,560×0,22)=(180,123,2) |`Board.holePosition` |
| Radio permanente tras q cuotas |`22×1,16^(q/2)` |`syncHoleGrowth`; área×1,16 por cuota |
| Saturación de proyección |Distancia al rincón más lejano ≈472,434 |Mismo símbolo; crecimiento persistente sigue contando, proyección física limitada a cobertura total |
| Radio efectivo |Radio permanente×(1+Hambre activa) |`captureRadius`; mismo valor para física y representación |
| Atracción ordinaria |220 u/s² hacia centro dentro de radioefectivo+15 |`Board.update`; no atracción ordinaria global |
| Agujero negro E02 |Dentro 180:420×(1−d/180)^2 |`BlackHoleEvent.accelerationAt`; combina con atracciónbase como máximo, no suma dos veces |
| Fuerzas E03 |Remolino 72 en alcance; Gravedad 9–45; Latido impulso 4,25–21,25 |`Board.update`, `EvolutionSkill` |
| Fricción bolas |Velocidad×exp(−1,6·dt), más damping 0,15 durante E01 real |`Board.update` |
| Tope velocidad |380 u/s vectorial |`maximumSpeed`, contactos y desplazamiento |
| Colisión bola-bola |Restitución implícita 0,3; impulso 1,3·velocidadnormal/(1/masaA+1/masaB) |`_collide`; corrección por masas inversas; sujetos se tratan inmóviles |

**INFERIDO físico, caso aislado ideal:** con velocidadvertical 85 y amortiguación 1,6, el recorrido libre asintótico sin otras fuerzas sería≈53,125 u, frente a unos 326,8 u desde salida principal y=450 hasta hoyo y 123,2. La emisión por sí sola no asegura captura; mano, impactos y fuerzas importan. No asignar un porcentaje de captura a partir de bolas/s.

**Métricas existentes:** `Board.spawned/captured/goldenCaptured`; `DebugDayReport` mantiene hasta 20 jornadas temporales con emitidas/capturadas/doradas/combo e ingresos, copia manual. `DayResult.captured` existe, pero su campo `generated` significa **dinero generado**, no bolas emitidas. `DayResult.lost=generated−income` también es dinero, no bolas perdidas. Para medir captura usar `captured/spawned` del debug, no `captured/DayResult.generated`.

| Métrica pedida | Situación |
|---|---|
| Capturadas/emitidas por jornada |Contadores existentes; ningún conjunto de sesiones humanas aportado en esta tarea |
| Tasa por normal/dorada/ariete/origen |No existe desglose completo; solo capturas doradas, sin denominador de doradas emitidas ni origen individual |
| Por tier |No aplica: tiers no implementados |
| Por radio/mejoras/herramienta |Estado reconstruible, pero no series comparables publicadas |
| Intentos fallidos del principal |No contador explícito; `spawnClock` y niveles permiten estimar intentos, no atribuir motivo exacto |
| Intentos lanzador |`attempts/shots`; sin distribución de todos los motivos |

Instrumentación propuesta como tarea separada: sampler en memoria/CSV de sesiones con semilla, nivel y radio por intervalo; origen e identidad de bolas; intentos/success/causa de rechazo; capturas por variante/origen, presentes al cierre; burbujas creadas/rotas/pendientes, eventos y frametimes. Sin escrituras por fotograma ni efectos de gameplay; no se ha implementado aquí.

## 5. Recompensa monetaria y sumideros

Fuente `CaptureCombo.capture`, `EvolutionRun.capture`, `Board.update`, `GameSession._step`.

```
V = ball_value de jornada: 1,2,3,5,8,13
G = dorada ? 10 : 1
C = racha normal desbloqueada ? (captura>=10 ? 3 : captura>=5 ? 2 : 1) : 1
L = Golpe de suerte acertado ? 2 : 1
M = millonaria activa ? (nivel<=3 ? 2 : 3) : 1
recompensa_bola = V × G × C × L × M
alimentación_bola = 1
```

La racha normal requiere que el intervalo entre capturas sucesivas sea≤1 s de simulación; al caducar vuelve 0. La captura 5 y 10 ya reciben su nuevo multiplicador. E03 Millonaria exige 10 en ventana 3 s y la captura disparadora ya recibe M. Capturas por herramientas, robot, doradas, ariete y Captura total siguen las mismas reglas. Ni tier ficticio ni saldo de monedas afectan alimentación. Orden: racha/dorada→triggersE03→suerte→millonaria. Ejemplo normal 7, suerte y M3:42; con racha 3 y dorada serían 1260. Valor máximo con tablas actuales 13×10×3×2×3=**2340 por bola**, sin cambiar número de capturas.

**INFERIDO estadístico condicional:** sin racha/E03 y entre bolas naturales con dorada 1%, E[recompensa]=`1,09·V`. Con MidasV p 3,5%: `1,315·V`. Con SuerteV, si sus tiradas se modelan uniformes, factor esperado adicional 1,05; no aplicar M×3 constante a toda jornada sin medir su tiempo activo. Doradas garantizadas H04 se suman separadamente. Este cálculo no es ingreso observado.

**Fuentes normales de dinero:** captura válida (incluidas instantáneas y variantes); Herencia 100 al inicio de partida siguiente si comprada. **Fuentes soloDEBUG:** `debugAddCoins`+1000 e inyección de bolas/compra libre; no BAL01. No se localizaron reembolsos, venta de mejoras, anuncios o pagos con dinero real. **Sumideros:** compras normales, precio del nodo de prestigio y pérdida/reset de saldo al morir/prestigiar. Alimentar no descuenta monedas. Comprar P02 gasta exclusivamente estrellas, no dinero normal.

### Contabilidad garantizada vs animación

- `_step` incrementa `economy.generated` por recompensa y crea una obligación `RewardDelivery.register` con ID/rango único.
- `Economy.collected` es la parte presentada/liquidada de jornada; `balance` es el saldo bancado entre jornadas. `Economy.begin` reinicia solo contadores diarios; `bank` añade collected al balance una vez al cierre normal.
- Los plazos del ledger (`delay+jump+hold+flight`) son independientes del presupuesto/cola de sprites. Pueden no coincidir exactamente con cada llegada tras BUG002/AJ009; la llegada visual **no vuelve a cobrar**.
- `finishDay` liquida íntegro el ledger antes del resultado o de determinar derrota. En derrota se reinicia la economía normal conforme S03: liquidar no significa conservar saldo de una partida terminada.
- Guardado/restauración de jornada conserva `generated−collected` como obligación; restaura y liquida directo sin volver a registrar capturas. En esta versión JSON16, bonusE03 queda separado y validado al restaurar.
- JSON/planificador validan importes hasta `0x1fffffffffffff` (2^53−1); cuotas usan BigInt aparte. No existe protección universal de suma de toda moneda en cada operación; riesgo de largo plazo a estudiar sin confundirlo con dinero infinito garantizado.

### Denominaciones y presentación

Valores actuales: **1(bronce),10(plata),50(oro),100(verde),500(rojo)**. No existe sexta denominación morada. `CoinDenomination` es única lista de valores. `planCoins` empieza con greedyexacto y, paraimporte≥50, divide denominaciones conservando suma; objetivo `round(64·ln(importe+1)/ln(51))` limitado 64..192; expansión puede exceder hasta 8 el objetivo, y cantidades ya grandes no se truncan. Stats guardan el desglose de microbatch, no número de iconos.

Microlote inicial 0,2 s: suma capturas de una ventana activa y luego cierra; captura aislada también sale. Para 34 (<50), exacto **3×10+4×1**,7 monedas si hay margen. Para cantidades elevadas se mezclan denominaciones; si se saturan memoria/tiempo/cola se agrupan paquetes de la misma denominación conservando cantidad e importe. Cada paquete ocupa una posición en AJ009.

Emisor único, máximo **1 inicio por frame real**, no 1 por subpaso. Separación adaptable 0,0083..0,075 s con suelo práctico de frame; rotación horaria 2..24 rad/s, variación 0,12; nuevaoleada aleatoria tras silencio>0,6 s; origen interior ligado al radio; salto 0,24..0,348 s, quieta 1 s, vuelo 0,58..0,772 s×escala, extendido para ordenar llegadas. Pool 192, agrupación por pendientes 1024 o tiempo estimado/edad 5 s; calidad adaptativa segúnp 95, umbral 18 ms y recuperación 2 s. El viejoCSV `reward_max_wait=0,4` **no es** el umbral actual `reward_emit_wait` (default 5 s).

En gameplay no hay saldo numérico total; las pilas reflejan paquetes recibidos esa jornada. Reiniciar pilas no resta saldo; gastar no las vacía. En resultados hay monedero propio de presentación: reconstruye saldo anterior y anima hasta final, sin operación económica. `ResultStack.visualCount≤6` y `ResultsSequence` no tienen API de cobro.

## 6. Precios del árbol y oportunidad de compra

Tablas exactas por nodo en informe/CSV. Se compran niveles secuenciales. El campoCSV`cap` es metadato, **no un nivel comprable**; no significa inflación automática. No hay costes exponenciales calculados en runtime ni rebajas por tiempo: son estas tablas fijas.

| Familia | Coste total para todos sus niveles |
|---|---:|
| Prestigio (`prestige`) | 10000 |
| Capacidad de la mano (`hand`) | 333 |
| Paredes rebotadoras (`walls`) | 360 |
| Bate de béisbol (`bat`) | 420 |
| Escoba recta (`broom`) | 20 |
| Escoba más ancha (`paddle`) | 700 |
| Escoba en V (`broom_v`) | 160 |
| Doble emisión (`double_spawn`) | 500 |
| Generador rápido (`generator`) | 510 |
| Generador lanzador (`launcher`) | 120 |
| Frecuencia del lanzador (`launcher_rate`) | 580 |
| Mayor recompensa (`reward`) | 700 |
| Día más largo (`duration`) | 1380 |
| Robot ayudante (`robot`) | 300 |
| Velocidad del robot (`robot_speed`) | 1730 |
| Racha de capturas (`combo`) | 40 |
| Captura total (`capture_all`) | 120 |
| Recarga de captura total (`capture_recharge`) | 440 |
| Aceleración especial (`boost`) | 100 |
| Potencia de aceleración (`boost_power`) | 220 |
| Duración de aceleración (`boost_duration`) | 380 |
| Recarga de aceleración (`boost_recharge`) | 380 |

Suma de mejoras ordinarias sin prestigio: **9493 monedas**. Sumando nodo de prestigio: **19493**. No equivale a dinero mínimo para prestigiar: camino mínimo actual de requisitos **12603** = ManoI13 + GeneradorI–V510 + RecompensaI–V700 + DuraciónI–V1380 + nodo 10000. Esto ignora otras mejoras que puedan necesitarse para conseguir el dinero antes de las cuotas; es un mínimo de requisitos, no una ruta jugable garantizada.

Árbol bloqueado antes de finalizar jornada 1 de **cada partida** (`normalShopAvailable`); tampoco se compra durante producción/pausa. Desde el primer cierre se gasta saldo normal incluyendo Herencia. Los mapas guardan nivel familiar, no IDs de cada nodo por separado; `SkillTree` deriva los 55 nodos. Prestigio aparece como nodo destacado al explorar, pero exige GeneradorV/RecompensaV/DuraciónV y 10000. Coste y dependencias **existen en código**, son configuración provisional heredada; no confundir “pendiente de BAL01” con “sin implementar”. La confirmación indica pérdida de burbujas/partida y conservación de permanentes.

## 7. Cuotas, crecimiento, derrota y prestigio

**Regla actual** `FeedingProgress.initialQuota=100`, `quotaDays=4`, `creditBalls`:

```
objetivo_cuota(k) = 100 × 10^(k−1), k>=1
saldoAlimentación += capturasVálidas
mientras saldoAlimentación >= objetivo:
    saldoAlimentación -= objetivo
    cuotaCompletada++
    siguienteObjetivo = objetivo×10
    quotaStartDay = jornadaActual
```

El excedente permanece una sola vez en siguiente cuota; varias completadas en un paso producen eventos separados. Para completar las primeraskcuotas de una partida desde 0 se necesitan `100·(10^k−1)/9` capturas acumuladas (100,1100,11100…). No confundir 1000 como total desde el origen con 1000 adicional de cuota 2.

Cada cuota comienza con su jornada de activación como primera, aunque a mitad o final de producción; vencimiento al cierre `quotaStartDay+3`. `quotaDay=clamp(day−quotaStartDay+1,1,4)` y futuras=4−quotaDay. Comprobar **después** de todas las capturas válidas, crecimiento, P01/H13 y cartaspendientes; si se completó en el último instante el plazo es el de la siguiente cuota reciénactivada y no se pierde. No hay tiempo extra. En cuarta jornada fallida: `finishDay→_endRun(false)→DERROTA→continuar→P02`; sin resumen normal.

El plazo está en `ResultsOverlay`: JornadaXde 4 y QuedanN jornadas; no enHUD. `FeedingSummary` muestra cuota/bolas sin plazo. Si falla cuarta, no hay resumen que permita comprar para arreglarla después.

Completar cuota: incrementa contador de crecimiento una vez, radio×√1,16, premia burbuja P01, tiradaH13 si adquirida y elecciónE03. No entrega monedas adicionales ni estrellas directas. Los antiguos `feeding_quota_initial=10`, `feeding_quota_step=10` del CSV **no controlan** esta lógica: GameSession consulta `FeedingProgress.initialQuota`, constante 100. No hay amortización de monedas por alimentar.

| Estado | Cruza jornadas | Cruza muerte/prestigio |
|---|---|---|
| Saldo normal/compras normales |Sí |No |
| Bolas, rachas activas, cargas especiales/E01/E02 |No (salvo snapshot de jornada interrumpida) |No |
| Alimentación/cuota/crecimiento permanente de esa partida |Sí |No |
| Burbujas sin romper, identidad y valor |Sí, reexpulsión al empezar jornada |No |
| Estrellas cobradas/sobrantes |Sí |Sí |
| P02 compradas/E03 niveles |Sí |Sí |
| Contadores H02/E03 de partida |Sí según reglas particulares |No |
| Pilas AJ009 |No |No |

## 8. Estrellas P01 y economía permanente

Fuente `StarConfig.category/value/radius`, `StarLedger.award/redeem`, `StarBubbles.impact`, `GameSession._step`.

**Parámetros actuales (provisionales de BAL01):**1 burbuja por cuota;3 categorías; categoría sube cada 2 cuotas; valor base 1 y crecimiento×5; diámetro burbuja más pequeña 2×bola normal; cada categoría diámetro×1,12. Umbralrotura 110 u/s normalrelativa, flotación 12, expulsión 100, damping 0,3 y rebote 0,65. Ver CSV de constantes para límites configurables.

| Cuotas de la partida | Categoría | Valor por burbuja | Radio / diámetro (u) | Cantidad sin/con H13 acertado |
|---|---:|---:|---|---|
|1–2 |0 |1★ |12 /24 |1 /2 |
|3–4 |1 |5★ |13,44 /26,88 |1 /2 |
|5+ |2 |25★ |15,0528 /30,1056 |1 /2 |

Todas las burbujas por cuota tienen su categoría determinada; no hay sorteo de denominación. H13: 50 % por cada cuota no procesada duplica objetos de misma denominación, no valor individual. **INFERIDO:** estrella potencial esperada por cuota con H13 es 1,5×valor; sin H13 es el valor. Cobro real exige romper burbuja, por tanto **no es ingreso permanente garantizado**.

La burbuja no alimenta, no da monedas, no cuenta como bola emitida/capturada ni activa combos. Pared/herramienta a velocidad relativa normal≥110 rompe. En esquina se evalúa máximo de componentes normales de pared, no velocidadvectorialtotal; bolas empujan pero no rompen directamente por bola-burbuja. Las estrellas se acreditan al procesar IDsrotos por ledger y se guardan; vuelo 0,85 s es decorativo, pool 24 sin condicionar pago.

Si quedan pendientes se recrean físicamente al siguienteinicio conservando ID/categoría/valor. Al finalizarpartida pierden sin conversión. El antiguo `star_active_limit=8` y entrada 0,4 s **no limitan** `populateImmediate`: P02 exige materializar todas las pendientes al empezar jornada o nueva cuota. No se elimina valor por rendimiento; sí hay riesgo de máscuerpos, tratado en riesgos. Las reexpulsiones del hoyo llevan 0,8 s de enfriamiento.

PreciosP02 totales:2+6+8+12=**28 ★**. Son compras únicas sin niveles/reembolsos; ordenlibre; no hay conversión monedas→estrellas. No se otorgan estrellas de consolación por morir ni por prestigiar. Para proyecciónBAL01 se necesita tasa real de rotura y costes de oportunidad de tiempo/gestos.

## 9. Constantes y mediciones

`AUD01_constantes.csv` enumera **todos** los registrosbase del balance 20, valor, unidad y capdeclarado. No basta leer unbase para afirmar que controla gameplay: los casos inertes o sustituidos (`feeding_quota_*`, `collection_radius`, `coin_pile_limit`, `reward_max_wait`, `star_active_limit`enaparicióninmediata) se separan en riesgos. Parámetros E03 están en `EvolutionSkill`, P02 en `PermanentSkill`, audio en `assets/audio/feedback.json`; no solo CSV.

Benchmark previo `docs/performance/e03-evolution.json`, AOTLinux, no Android GPU/audio:

| Bolas iniciales | E03 | p 95 CPU simulación ms | Pico ms | Bolas finales |
|---:|---|---:|---:|---:|
|100 |Sin |0,495 |0,519 |113 |
|100 |Máximo |0,395 |0,492 |66 |
|200 |Sin |0,924 |1,008 |200 |
|200 |Máximo |0,946 |1,037 |149 |
|500 |Sin |2,424 |2,546 |493 |
|500 |Máximo |2,746 |2,881 |426 |

**REFERENCIA DE EJECUCIÓN PREVIA**, no repetida enAUD01. `tool/benchmark_evolution.dart`:60 pasos de calentamiento +600 medidos a 1/60, semilla Board 42; paredesIII/bateI/lanzadorI; E03 al nivel 5 en comparación,10%pesadas, colocación determinista. El escenario 500 excede población normal 200 mediante inyección directa. Población final difiere, por tanto no estima sobrecoste E03 a cargaidéntica ni tasa de captura normal ni FPSde Android. RSS final≈10,67–11,64MB del proceso AOT (no memoria de la APK completa). No se midióGPU, audio, háptica ni calidadperceptiva.
