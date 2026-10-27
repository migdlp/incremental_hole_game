# AUD01 — Inventario de habilidades y mecánicas

**Proyecto:** Feed the Hole · **Versión:** 0.23.0+36 · balance v 20 · JSON v 16  
**Fuente auditada:** `0778d139d4a85124e0af2a9f89d595dc19159430` · rama `build/apk-0.6.0+13`  
**Fecha:** 27/10/2026 · auditoría estática; sin cambios de gameplay o balance.

## Convenciones

Salvo indicación contraria, todo este inventario es **VERIFICADO EN CÓDIGO**, en el commit de cabecera. Las tablas son parámetros implementados, no balance final aprobado. Las mejoras normales parten de nivel 0, son secuenciales, cuestan monedas normales, solo se compran tras jornada 1 y entre jornadas; se pierden al terminar partida. Sus valores sustituyen la variable base (no se suman todos los niveles). Se congelan al crear `DaySettings` para la siguiente producción.

## Árbol normal: 22 familias, 55 niveles

Cada nivel y su vecindad aparecen individualmente en el informe/CSV. Aquí se incluyen todos los efectos y tablas:

### `prestige` — Prestigio

- **Estado:** implementado; categoría Prestigio; niveles 0–1.
- **Propósito/efecto:** Finaliza la partida inmediatamente y abre la tienda permanente, tras confirmación.
- **Aplicación:** Acción al comprar; se pierden monedas, árbol, cuotas y burbujas; conserva estrellas/P02/E03.
- **Acumulación/exclusiones:** No añade estrellas; coste y prerrequisitos provisionales heredados S03/BAL01.
- **Fuente:** `lib/app/game_session.dart:purchase/_endRun; lib/features/prestige/domain/meta_progress.dart:end`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 10000 | `prestige_action=1` action | generator:5&reward:5&duration:5 |

### `hand` — Capacidad de la mano

- **Estado:** implementado; categoría Control; niveles 0–5.
- **Propósito/efecto:** Aumenta la cantidad máxima de bolas sujetas; base 1. Fuerza fija ×4, sin niveles de fuerza.
- **Aplicación:** hand_capacity; siguiente jornada.
- **Acumulación/exclusiones:** No cambia valor; arrastre/lanzamiento facilita capturas; no afecta burbujas ni capacidad de bate.
- **Fuente:** `lib/features/board/domain/board.dart:handCapacity/_heldBalls/_moveTool`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 13 | `hand_capacity=2` balls | ninguno |
| 2 | 30 | `hand_capacity=3` balls | ninguno |
| 3 | 50 | `hand_capacity=4` balls | ninguno |
| 4 | 90 | `hand_capacity=5` balls | ninguno |
| 5 | 150 | `hand_capacity=6` balls | ninguno |

### `walls` — Paredes rebotadoras

- **Estado:** implementado; categoría Control; niveles 0–3.
- **Propósito/efecto:** Las cuatro paredes rebotan desde el inicio (×0,4); compra aumenta restitución normal.
- **Aplicación:** wall_restitution; siguiente jornada.
- **Acumulación/exclusiones:** Límite vectorial 380 tras ambas normales; compatible con E03 dirigido; no afecta monedas ni rebote propio P01.
- **Fuente:** `lib/features/board/domain/board.dart:_bounceWalls`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 40 | `wall_restitution=1.10` multiplier | hand:1 |
| 2 | 100 | `wall_restitution=1.35` multiplier | hand:1 |
| 3 | 220 | `wall_restitution=1.60` multiplier | hand:1 |

### `bat` — Bate de béisbol

- **Estado:** implementado; categoría Control; niveles 0–3.
- **Propósito/efecto:** Desbloquea bate y sube exclusivamente bonificación de golpe activo.
- **Aplicación:** bat_power; siguiente jornada; compra selecciona herramienta.
- **Acumulación/exclusiones:** Pasivo ×0,4; activo añade max(0,v_superficie·normal)×1,1×potencia; velocidad de giro incluida; tope 380; nuevos contactos.
- **Fuente:** `lib/features/board/domain/board.dart:_contactBat`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 60 | `bat_power=1` multiplier | hand:1 |
| 2 | 120 | `bat_power=1.35` multiplier | hand:1 |
| 3 | 240 | `bat_power=1.7` multiplier | hand:1 |

### `broom` — Escoba recta

- **Estado:** implementado; categoría Control; niveles 0–1.
- **Propósito/efecto:** Desbloquea escoba recta; uno/dos dedos trasladan/rotan.
- **Aplicación:** broom_unlocked; siguiente jornada; compra selecciona escoba.
- **Acumulación/exclusiones:** No recoge monedas en C01; interactúa bolas y burbujas; dimensiones mejoradas por paddle.
- **Fuente:** `lib/features/board/domain/board.dart:segments/_contactBroom; lib/features/board/domain/tool.dart:broomSegments`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 20 | `broom_unlocked=1` unlock | hand:2 |

### `paddle` — Escoba más ancha

- **Estado:** implementado; categoría Control; niveles 0–5.
- **Propósito/efecto:** Aumenta anchura total de escoba a 4×paddle_radius; base 80 u, niveles 96/112/128/144/160 u.
- **Aplicación:** paddle_radius; siguiente jornada.
- **Acumulación/exclusiones:** Afecta segmentos de escoba recta y V; no longitud del bate.
- **Fuente:** `lib/features/board/domain/board.dart:broomHalfWidth; lib/features/board/domain/tool.dart:broomSegments`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 40 | `paddle_radius=24` broom_width | broom:1 |
| 2 | 70 | `paddle_radius=28` broom_width | broom:1 |
| 3 | 110 | `paddle_radius=32` broom_width | broom:1 |
| 4 | 180 | `paddle_radius=36` broom_width | broom:1 |
| 5 | 300 | `paddle_radius=40` broom_width | broom:1 |

### `broom_v` — Escoba en V

- **Estado:** implementado; categoría Control; niveles 0–1.
- **Propósito/efecto:** Desbloquea geometría de escoba en V.
- **Aplicación:** v_unlocked; siguiente jornada; compra selecciona V.
- **Acumulación/exclusiones:** Anchura usa paddle; no herramienta generadora ni recolectora de monedas.
- **Fuente:** `lib/features/board/domain/tool.dart:broomSegments; lib/features/board/domain/board.dart:canUse`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 160 | `v_unlocked=1` unlock | paddle:1 |

### `double_spawn` — Doble emisión

- **Estado:** implementado; categoría Producción; niveles 0–1.
- **Propósito/efecto:** Cada ciclo normal intenta emitir dos bolas en vez de una.
- **Aplicación:** balls_per_spawn=2; siguiente jornada.
- **Acumulación/exclusiones:** Un ciclo sigue contando una vez para H02/E03; no duplica extras ni lanzador. Intentos bloqueados se consumen.
- **Fuente:** `lib/features/board/domain/board.dart:update/_emitMain`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 500 | `balls_per_spawn=2` balls_per_spawn | generator:3&paddle:3 |

### `generator` — Generador rápido

- **Estado:** implementado; categoría Producción; niveles 0–5.
- **Propósito/efecto:** Reduce intervalo del generador principal; valor absoluto por nivel.
- **Aplicación:** spawn_interval; siguiente jornada.
- **Acumulación/exclusiones:** Frecuencia multiplicada por boost y E03; no modifica intervalo del lanzador.
- **Fuente:** `lib/features/board/domain/board.dart:update`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 30 | `spawn_interval=0.5333333333333333` seconds | hand:1 |
| 2 | 50 | `spawn_interval=0.4266666666666667` seconds | hand:1 |
| 3 | 80 | `spawn_interval=0.3413333333333333` seconds | hand:1 |
| 4 | 130 | `spawn_interval=0.2730666666666667` seconds | hand:1 |
| 5 | 220 | `spawn_interval=0.21845333333333333` seconds | hand:1 |

### `launcher` — Generador lanzador

- **Estado:** implementado; categoría Producción; niveles 0–1.
- **Propósito/efecto:** Desbloquea segundo generador orientable en franja inferior 25%; cuerpo y cañón limitados a zona.
- **Aplicación:** launcher_unlocked; siguiente jornada.
- **Acumulación/exclusiones:** 1 bola por intento, velocidad 280; naturaldorada 1%; no H02, Midas, boost ni E03 ciclos; sin retroceso.
- **Fuente:** `lib/features/board/domain/launcher.dart; lib/features/board/domain/board.dart:_advanceLauncher`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 120 | `launcher_unlocked=1` boolean | generator:2 |

### `launcher_rate` — Frecuencia del lanzador

- **Estado:** implementado; categoría Producción; niveles 0–3.
- **Propósito/efecto:** Reduce intervalo de disparo del lanzador independiente.
- **Aplicación:** launcher_interval; siguiente jornada.
- **Acumulación/exclusiones:** No cambia fuerza; intentos obstruidos se consumen y no se apilan.
- **Fuente:** `lib/features/board/domain/board.dart:_advanceLauncher`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 100 | `launcher_interval=1.8` seconds | launcher:1 |
| 2 | 180 | `launcher_interval=1.2` seconds | launcher:1 |
| 3 | 300 | `launcher_interval=0.8` seconds | launcher:1 |

### `reward` — Mayor recompensa

- **Estado:** implementado; categoría Valor; niveles 0–5.
- **Propósito/efecto:** Valor global de cada bola capturada; base 1, no tiers individuales.
- **Aplicación:** ball_value; siguiente jornada.
- **Acumulación/exclusiones:** ×10 dorada, ×racha normal, ×suerte y ×millonaria; alimentación sigue +1.
- **Fuente:** `lib/features/board/domain/board.dart:captureBalls dentro de update`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 40 | `ball_value=2` coins | hand:1 |
| 2 | 70 | `ball_value=3` coins | hand:1 |
| 3 | 110 | `ball_value=5` coins | hand:1 |
| 4 | 180 | `ball_value=8` coins | hand:1 |
| 5 | 300 | `ball_value=13` coins | hand:1 |

### `duration` — Día más largo

- **Estado:** implementado; categoría Tiempo; niveles 0–5.
- **Propósito/efecto:** Amplía producción de 15 hasta 30 segundos activos.
- **Aplicación:** production_duration; siguiente jornada.
- **Acumulación/exclusiones:** Más ciclos/tiempo de control; todos los eventos se cortan al cerrar producción; cuotas siguen 4 jornadas.
- **Fuente:** `lib/app/game_session.dart:startDay; lib/features/day_cycle/domain/day_cycle.dart`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 80 | `production_duration=18` seconds | generator:2 |
| 2 | 130 | `production_duration=21` seconds | generator:2 |
| 3 | 220 | `production_duration=24` seconds | generator:2 |
| 4 | 360 | `production_duration=27` seconds | generator:2 |
| 5 | 590 | `production_duration=30` seconds | generator:2 |

### `robot` — Robot ayudante

- **Estado:** implementado; categoría Automatización; niveles 0–1.
- **Propósito/efecto:** Desbloquea un robot que empuja bolas hacia el hoyo; velocidadbase 45 u/s.
- **Aplicación:** robot_count=1; siguiente jornada.
- **Acumulación/exclusiones:** Requiere solo Escoba anchaII (Barrido retirado). Capturas conservan racha; no cobra monedas manuales.
- **Fuente:** `lib/features/automation/domain/robot.dart; lib/features/board/domain/board.dart:update/_push`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 300 | `robot_count=1` robots | paddle:2 |

### `robot_speed` — Velocidad del robot

- **Estado:** implementado; categoría Automatización; niveles 0–5.
- **Propósito/efecto:** Velocidad del robot:45×1,15^nivel u/s.
- **Aplicación:** robot_speed; siguiente jornada.
- **Acumulación/exclusiones:** Misma IA y cantidad 1; aumenta movilidad, no recompensa directa.
- **Fuente:** `lib/features/automation/domain/robot.dart:direction; lib/features/board/domain/board.dart:update`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 100 | `robot_speed=51.74999999999999` logical_units_per_second | robot:1 |
| 2 | 170 | `robot_speed=59.51249999999999` logical_units_per_second | robot:1 |
| 3 | 270 | `robot_speed=68.43937499999998` logical_units_per_second | robot:1 |
| 4 | 450 | `robot_speed=78.70528124999997` logical_units_per_second | robot:1 |
| 5 | 740 | `robot_speed=90.51107343749997` logical_units_per_second | robot:1 |

### `combo` — Racha de capturas

- **Estado:** implementado; categoría Valor; niveles 0–1.
- **Propósito/efecto:** Desbloquea racha normal: capturas encadenadas con intervalo máximo 1 s.
- **Aplicación:** combo_unlocked; siguiente jornada.
- **Acumulación/exclusiones:** Captura 5 ya×2; captura 10 ya×3; dorada×10 acumulable; robot/Captura total cuentan; independiente E03 millonaria.
- **Fuente:** `lib/features/board/domain/capture_combo.dart:CaptureCombo`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 40 | `combo_unlocked=1` unlock | hand:1 |

### `capture_all` — Captura total

- **Estado:** implementado; categoría Control; niveles 0–1.
- **Propósito/efecto:** Botón recargable marca todas las bolas actuales para captura en siguiente actualización.
- **Aplicación:** capture_all_unlocked; siguiente jornada.
- **Acumulación/exclusiones:** Empieza descargada; base 12 s; no consume carga si tablero vacío; captura individual exacta con todas sus bonificaciones; cada bola+1 cuota.
- **Fuente:** `lib/features/board/domain/board.dart:activateSpecial/update; lib/features/board/domain/special_abilities.dart`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 120 | `capture_all_unlocked=1` unlock | combo:1 |

### `capture_recharge` — Recarga de captura total

- **Estado:** implementado; categoría Control; niveles 0–2.
- **Propósito/efecto:** Reduce tiempo de carga de Captura total.
- **Aplicación:** capture_all_cooldown; siguiente jornada.
- **Acumulación/exclusiones:** Base 12 s; niveles 10/8 s. Carga solo producción activa; no se conserva carga entre jornadas.
- **Fuente:** `lib/features/board/domain/special_abilities.dart:advance/cooldown`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 160 | `capture_all_cooldown=10` seconds | capture_all:1 |
| 2 | 280 | `capture_all_cooldown=8` seconds | capture_all:1 |

### `boost` — Aceleración especial

- **Estado:** implementado; categoría Producción; niveles 0–1.
- **Propósito/efecto:** Botón que acelera temporalmente el generador principal.
- **Aplicación:** boost_unlocked; siguiente jornada.
- **Acumulación/exclusiones:** Empieza descargado; carga 10 s, activo 4 s×2; recarga después del efecto; no lanzador.
- **Fuente:** `lib/features/board/domain/special_abilities.dart; lib/features/board/domain/board.dart:update`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 100 | `boost_unlocked=1` unlock | generator:1 |

### `boost_power` — Potencia de aceleración

- **Estado:** implementado; categoría Producción; niveles 0–1.
- **Propósito/efecto:** Multiplicador de frecuencia durante aceleración: de×2 a×3.
- **Aplicación:** boost_multiplier; siguiente jornada.
- **Acumulación/exclusiones:** Multiplica frecuencia ya aumentada por E03; no cambia velocidad física de lanzamiento.
- **Fuente:** `lib/features/board/domain/board.dart:update`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 220 | `boost_multiplier=3` multiplier | boost:1 |

### `boost_duration` — Duración de aceleración

- **Estado:** implementado; categoría Producción; niveles 0–2.
- **Propósito/efecto:** Amplía duración activa del boost de 4 a 5/6 s.
- **Aplicación:** boost_duration; siguiente jornada.
- **Acumulación/exclusiones:** No alarga jornada ni persiste activo al cerrar; recarga comienza después.
- **Fuente:** `lib/features/board/domain/special_abilities.dart`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 140 | `boost_duration=5` seconds | boost:1 |
| 2 | 240 | `boost_duration=6` seconds | boost:1 |

### `boost_recharge` — Recarga de aceleración

- **Estado:** implementado; categoría Producción; niveles 0–2.
- **Propósito/efecto:** Reduce recarga del boost de 10 a 8/6 s.
- **Aplicación:** boost_cooldown; siguiente jornada.
- **Acumulación/exclusiones:** Recarga no avanza durante boost; carga inicial 0 por jornada.
- **Fuente:** `lib/features/board/domain/special_abilities.dart:advance`; `UpgradeCatalog.settings`, `GameSession.purchaseBlock`, `docs/balance.csv`.

| Nivel | Coste | Valor absoluto | Requisitos CSV |
|---:|---:|---|---|
| 1 | 140 | `boost_cooldown=8` seconds | boost:1 |
| 2 | 240 | `boost_cooldown=6` seconds | boost:1 |

## P02 — Cuatro compras permanentes con estrellas

Fuente: `lib/features/prestige/domain/permanent_skills.dart`, `PermanentSkill.catalogue/PermanentRun`; `MetaProgress.purchase`, `GameSession.beginNewRun/startDay/_step`; `Board.update/_emitExtra`. **Estado: implementado**, excepto garantía absoluta de H04 bajo obstrucción total, descrita aparte.

| ID | Habilidad | Coste ★ | Máximo | Disparador y efecto | Persistencia/exclusiones |
|---|---|---:|---:|---|---|
| H01 | Herencia | 2 | 1 | `beginNewRun` asigna saldo 100 tras reinicio; una vez | No suma ingresos/monedas diarias; restaurar no vuelve a dar 100; no puede gastarse hasta cerrar jornada 1 |
| H02 | Eco de producción | 6 | 1 | Cada 20 ciclos normales principales añade 5 a `pendingEcho`; intenta hasta 5 extras por update | Resto 0–19 y extras pendientes cruzan jornadas; reset por partida; ciclo con 2 bolas cuenta 1; extras y lanzador no cuentan |
| H04 | Fiebre dorada | 8 | 1 | Una extra dorada principal, instante `D×(0,05+0,85×u)`; intervalo [5%,90%) de producción | Estado diario y RNG guardados; no consume ciclo, no sustituye natural; reserva 1 hueco global; si no logra aparecer reintenta solo mientras produce |
| H13 | Lluvia astral | 12 | 1 | Tirada independiente 50% por cuota nueva; duplica número de burbujas con misma categoría/valor | IDs nuevos; no estrellas directas; ledger impide repetir cuota; sin límite activo antiguo para aparición inmediata |

Tienda accesible solo tras finalización por derrota o prestigio voluntario. Las cuatro visibles desde primer acceso, sin otros requisitos. Confirmación antes de compra, cancelación sin efecto, precio exacto, adquisición única y sin reembolso. Revalida saldo/adquisición al confirmar; actualización completa de meta se guarda con revisión/checkpoint; se bloquean nuevas operaciones hasta persistencia coherente. Continuar está permitido con cero estrellas y sin comprar, crea nueva partida y comienza producción 1 tras guardar. Cierre dentro de tienda restaura tienda. Compras P02 y niveles E03 son mapas separados.

**H04: implementación parcial respecto a “exactamente una garantizada”.** Se reserva capacidad, pero `_emitExtra(forceGolden:true)` puede devolverfalse si sus 21 posiciones están bloqueadas por sólidos/bolas/burbujas. Si sucede hasta el último instante, la jornada acaba sin emitirla; `beginDay` reinicia su estado para la siguiente. No hay entrega automática diferida ni captura ficticia. No se corrige en AUD01.

## E03 — Doce cartas permanentes, niveles 0–5

Fuentes: `lib/features/evolution/domain/evolution.dart` (`EvolutionSkill`, `EvolutionEffect`, `EvolutionRun`); `Board.update/_bounceWalls/_emitMain/_collide`; `GameSession.chooseEvolution/_step/snapshot/restore`; selector en `evolution_selector.dart`.

**Coste:** cero monedas/estrellas. Una elección por cuota; 60 subidas posibles entre las doce habilidades. Cada oferta es uniforme entre habilidades no maximizadas, sin repetición dentro de la oferta, hasta 3; cuando quedan 2/1 ofrece 2/1; con todas al 5 no ofrece más ni recompensa alternativa. Las ofertas no se ponderan por nivel y no hay reroll. `cardRandom` separado de RNG de efectos; ambos LCG32 bits y persistidos. Mismas opciones, orden, pendientes y serial tras restauración. Cuotas repetidas en una partida nueva vuelven a ofrecer carta.

Elección tras resolver todas las capturas del paso, crecimiento y P01/H13. Pausa tablero, relojes y producción; elección de un solo toque/serial, incremento de meta y checkpoint antes de reanudar. Si coincide con último instante válido, resuelve cartas antes de resultados sin conceder más tiempo/capturas. El efecto de una subida E03 aplica al reanudar (no espera la siguiente jornada, a diferencia del árbol normal); efectos temporales ya activados conservan el nivel con el que se activaron.

| ID / símbolo | Nombre | Valores por nivel I/II/III/IV/V | Disparador, duración, recarga y exclusiones |
|---|---|---|---|
| E03-01 / whirlpool | Remolino | Alcance 1,5 / 1,75 / 2 / 2,25 / 2,5 ×radio efectivo | 10 capturas en ventana móvil 3 s elegibles; activo 2 s; recarga 10 s al terminar. Aceleración constante 72 u/s² (=40%×180), solo bolas libres dentro alcance |
| E03-02 / hunger | Hambre insaciable | Radio+4 / 6 / 8 / 10 / 12 % | 25 capturas elegibles; activo 4 s; recarga 12 s. Multiplica radio permanente crecido, no área; visual y captura usan mismo radio |
| E03-03 / pulse | Latido | Impulso 4,25 / 8,5 / 12,75 / 17 / 21,25 u/s | Cada 20 s activos de producción, alcance 3×radio efectivo; impulso hacia centro, referencia 85×[5/10/15/20/25%] |
| E03-04 / directed | Rebote dirigido | Probabilidad 10 / 20 / 30 / 40 / 50 % | Por contacto nuevo con cada pared; blend direcciones 75%salida+25%centro normalizado preservando velocidad; esquina prueba por cada pared nueva |
| E03-05 / ram | Bola ariete | Una extra cada 50 / 45 / 40 / 35 / 30 ciclos | Principal; masa 3, tamaño/valor estándar, puede ser dorada por reglas principales; pendientes reintentados; sin ciclos recursivos |
| E03-06 / gravity | Gravedad traviesa | Aceleración 9 / 18 / 27 / 36 / 45 u/s² | Cada 30 s de producción; activo 2 s; hacia centro, solo bolas libres; no inclinación/sensores ni herramientas |
| E03-07 / frenzy | Disparo frenético | Frecuencia+4 / 8 / 12 / 16 / 20 % | Siempre principal; no modifica velocidad física de lanzamiento |
| E03-08 / effort | Último esfuerzo | Frecuencia+10 / 15 / 20 / 25 / 30 % | Último 25% del tiempo de la jornada; suma con frenzy; partición exacta al cruzar 75% |
| E03-09 / ration | Doble ración | Una extra cada 40 / 35 / 30 / 25 / 20 ciclos | Principal, una bola estándar extra; no duplica todas las emisiones; pendientes reintentados, no recursión |
| E03-10 / millionaire | Racha millonaria | Multiplicador 2 / 2 / 2 / 3 / 3; duración 3 / 6 / 7 / 8 / 10 s | 10 capturas en ventana 3 s; la décima ya bonificada; recarga 10 s al terminar, sin acumular capturas activo/recargando; independiente de racha normal |
| E03-11 / midas | Toque de Midas | +0,5 / 1 / 1,5 / 2 / 2,5 puntos porcentuales | Natural principal 1%→1,5/2/2,5/3/3,5%; extras principales incluidas, no lanzador ni dorada H04 forzada |
| E03-12 / luck | Golpe de suerte | Probabilidad 1 / 2 / 3 / 4 / 5 % | Tirada por captura; duplica recompensa monetaria normal y luego aplica millonaria; no duplica alimentación ni estrellas |

**Persistencia temporal:** niveles permanentes sobreviven a muerte/prestigio; tiempos y contadores se reinician por partida. Entre jornadas se conservan `pulseClock/gravityClock`, restos de ciclos y extras pendientes; contador parcial de Hambre se conserva. Ventanas móviles de 3 s se limpian al cambiar jornada. Efectos activos terminan al cerrar producción; si tenían recarga la inician/conservan para jornadas futuras; la recarga solo consume producción activa. Subir nivel no renueva un efecto activo ni resetea contadores. No hay captura acumulable para activar Remolino/Hambre/Millonaria mientras su propio efecto esté activo o en recarga.

## Otros sistemas y mecánicas (catálogo real)

| ID documental | Nombre / estado | Parámetros y activación | Límites, sinergias y código |
|---|---|---|---|
| BASE-BALL | Bola normal, implementada | Radio 6, masa 1, valor global 1–13; velocidad principal `(U(-18,18),-85)` | Sin tier individual; tope 380; `Board.Ball/_emitMain` |
| GOLD | Variante dorada, implementada | Natural 1% por bola emitida, valor×10 | Puede ser también ariete; misma física/radio; Midas solo principal; `Ball.golden`, `CaptureCombo.capture` |
| RAM | Ariete E03, implementado | `Ball.heavy`, masa 3, radio 6 y recompensa normal | No habilidad por tocar pared; colisión bola-bola usa masas; no cuenta como nuevo ciclo |
| HAND | Mano, implementada |1–6 bolas; fuerza 4, radio de atraer otras `2×6+24=36`; muelle 80, amortiguación 14, aceleración 900×fuerza y umbral de rotura 72×(1+0,2×(fuerza−1))=115,2 u con fuerza 4 | Bola principal manual y adicionales con muelle; lanzamiento por historial de gesto; `Board.touch/_moveTool/_releaseVelocity` |
| BROOM | Escoba recta/V, implementada | Segmentos sin cuerpos físicos, grosor 3,5; largo 80–160 | Control uno/dos puntos; V vértice −0,45×semianchura, boca+0,35; `tool.dart`, `TwoPointGrip` |
| BAT | Bate, implementado | Semilargo 36, grosor 6; desplazamiento hasta 900 u/s, giro 3 rad/s | Superficie incluye v+ω×brazo; niveles solo fuerza activa; no monedas; `Board._contactBat` |
| M01 | Paredes, implementadas | Restitución 0,4→1,1→1,35→1,6; tope 380 | Rebota componente normal en cada pared, limita vector una vez en esquina; visual elástico independiente, pool 32 impactos; `Board._bounceWalls` |
| M03 | Lanzador, implementado | Zona y≥420 de tablero 560; radio 18, cañón 30 y radio 7; base 2,4 s, velocidad 280 | Presión por contacto≤120, umbral 400; ≤3 bolas no lo desplazan; masa 12, amortiguación 8, máximo 12 u/s de desplazamiento; solo jugador gira; `Launcher.applyPressure` |
| ROBOT | Robot, implementado | Un robot; base 45 u/s×1,15^nivel; decide cada 0,25 s | Va detrás de bola y empuja hacia hoyo; cambia objetivo si estanca>1 s; `Robot.direction`, `Board._push` |
| E01 | Objeto Gravedad, implementado | Tirada 5% por jornada si sensor real disponible; máximo 1; aparición uniforme dentro producción;3–6 toques equiprobables | Deriva 8 u/s; activo≤10 s; inclinación filtrada respuesta 6, aceleración 180; bolas/herramientas libres, no monedas; retira al cierre; `gravity_event.dart`, `android_motion_input.dart` |
| E02 | Objeto Agujero negro, implementado | Tirada 5% cada 3 s estrictamente antes de fin;3–6 toques; deriva 8; varios coexistentes | Activo 10 s, reactivación reinicia 10; alcance 180; aceleración 420×(1−d/180)^2; no cambia radio captura; solo bolas libres en normal; retira al cierre; `black_hole_event.dart` |
| P01 | Burbujas de estrellas, implementadas |1 burbuja/cuota, categorías por pares de cuotas; impacto pared/herramienta normal relativo≥110 rompe | Radio 12×1,12^categoría, flotación 12, amortiguación 0,3, rebote 0,65; lanzamiento 100; recobro por ledger; `star_rewards.dart`, `star_bubbles.dart`, `Board._stepBubbles` |
| C01/BUG001/002 | Cobro y lluvia de monedas, implementados | Microlotes 0,2 s, valores 1/10/50/100/500, emisor único secuencial, salto+1 s quieta+vuelo curvo | Pool 192 y pendientes agrupables 1024, exactitud económica independiente; no cuerpos físicos, no colisiones; `coin_plan.dart`, `reward_delivery.dart` |
| AJ009 | Pilas diarias, implementadas | Óvalos 16×8,8, desplazamiento vertical 2,5, paso columna 17;1–10 capas según alto | Reserva por llegada, identidad run:día; sin saldo total en gameplay, sin compactación de exceso; `daily_coin_collection.dart`, `collection_painter.dart` |
| AJ008A | Resultados, integrado | Monedas por denominación→hoyo→Tienda;0,22 s apertura,1,2 s por denominación,1,4 s hoyo | Máximo 6 iconos de vuelo por denominación; salto por fases con bloqueo 0,25 s/serial; saldo visual sin nueva acreditación; `results_sequence.dart/results_data.dart/results_overlay.dart` |
| AJ007 | Audio/háptica/absorción, integrado | Gestor central, sonidos offline, agrupación y límites; volumen y vibración persistentes separados | No altera economía; monedas aisladas usan cascada también; sin calibración física certificada; `feedback_controller.dart`, `feedback_config.dart`, `assets/audio/feedback.json` |
| DEBUG | Pruebas aisladas, implementado | BotónDEBUG en tienda; snapshots de partida real, compras/desbloqueos y eventos forzables | No interpretar +1000 debug ni capturas inyectadas como producción real; `GameSession.enableDebug/debugPurchase/debugAddCoins/disableDebug` |

**Precisión sobre la masa ariete:** la respuesta ponderada por masa está en `_collide` para bola-bola. Robot, herramientas y colisión burbuja-bola usan sus reglas específicas de velocidad, sin resolver una masa global uniforme en todos los pares. No prometer una simulación rígida de masa 3 en todas las interacciones.

**P01 frente a eventos:** en modo normal `bubbleGravity=false` y `bubbleBlackHole=false`; las opciones experimentales solo DEBUG. E03 no aplica fuerzas a burbujas, herramientas ni monedas. Las burbujas reciben impulsos de bolas, pero solo pared/herramienta provoca rotura, no bola-bola por sí misma. Si entran en el hoyo, se reexpulsan con la misma identidad (cooldown 0,8 s, umbral de cercanía `radioBurbuja+12`, independiente del agujero crecido).

## Definido pero no implementado / retirado

| Propuesta | Estado real y evidencia |
|---|---|
| CF16: tiers individuales | **DEFINIDO PERO NO IMPLEMENTADO**; `Ball` solo id/posición/velocidad/golden/heavy. Valor sigue rama global reward. Cantidades/colores/probabilidades y dorada-tiermáximo abiertos en `docs/cambios-futuros-arbol-mejoras.md` |
| CF17: potenciadora | No existe clase/tipo activable en Ball; depende tiers; reglas abiertas |
| CF20/21: flippers, bumpers, barreras, fábrica | No implementados como nuevas piezas; paredes/bate/lanzador no equivalen a esos sistemas futuros |
| CF22/23: duplicadora/bomba/impulso | Ideas pendientes, sin tipo de bola ni lógica real |
| Ventilador | No aparece como herramienta implementada en `BallTool` ni clase del tablero; solo referencias de diseño futuras |
| CF19: tres habilidades | La propuesta histórica no debe confundirse con una segunda mecánica: E03 sí implementa la especificación posterior de cartas por cuota |
| Barrido/Área/Imán/Atracción/Fuerza de agarre | Retirados del catálogo activo, 15 niveles históricos inventariados en CSV; no sumar a coste/economía actuales |

No hay compras con dinero real, tienda IAP, anuncios que otorguen recursos ni segundo prestigio localizados en `lib`/`pubspec`. **VERIFICADO EN CÓDIGO** como ausencia en el alcance revisado, no como promesa sobre futuras versiones.

## Parámetros audiovisuales activos (AJ-007)

**VERIFICADO EN CÓDIGO:** `assets/audio/feedback.json`, `FeedbackController.priority/cooldown/sample/advance`. Valores de mezcla iniciales; no ingresos ni balance económico.

| Parámetro | Valor |
|---|---:|
| `maxVoices` | 8 |
| `groupWindow` | 0.05 |
| `captureWindow` | 0.5 |
| `frequentRate` | 6 |
| `massRate` | 30 |
| `attack` | 9 |
| `release` | 4 |
| `pitchVariation` | 0.045 |
| `captureGain` | 0.24 |
| `coinGain` | 0.22 |
| `impactGain` | 0.08 |
| `starGain` | 0.3 |
| `upgradeGain` | 0.25 |
| `absorbGain` | 0.065 |
| `rollingGain` | 0.028 |
| `impactThreshold` | 24 |
| `hapticInterval` | 0.18 |
| `sinkDuration` | 0.24 |
| `sinkCapacity` | 1024 |
| `rippleGain` | 0.035 |

Límite de8 voces total: reserva2 para capas continuas, hasta6 efectos individuales. Eventos agrupados cada0,05s; captura tiene cooldown0,045..0,11s según densidad; llegada0,075s; salida0,09s; estrella/compra/cuota0,12s. Prioridades: estrella100, compra90, cuota85, especial75, captura65, bate60, llegada50, salida30, cristal25, lanzador20, choque10. Presupuesto de ganancia individual acumulada0,85×volumen; se retiran voces inferiores antes de saturar. Capturas:6 variantes plop; monedas aisladas usan `coincascade`, múltiples alternan5 tonos `coin0..4`; salida2 variantes. Pitch de llegadas fijo1, otras variación±0,045.

Háptica: un pulso del evento elegible de mayor prioridad por grupo; intervalo mínimo0,18s, multiplicado1,5 si grupo>3; prioridad≥85 usa patrón reward y resto light. No se exige control de amplitud inexistente en dispositivo. Hundimiento0,24s y pool1024, ondas agrupadas0,035. Volumen inicial del controlador0,8 y rango de preferencia0–1; sonido/vibración independientes y persistidos. Validación subjetiva en Android pendiente.
