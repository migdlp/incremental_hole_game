# BAL-TOOLS-01 — Contrato implementado v1

Esquema `bal_metrics/1.0.0`, juego 0.24.0+38, guardado compatible v17,
balance v20. Este contrato sustituye como normativa al borrador
[metricas-propuesta.md](metricas-propuesta.md). El borrador conserva el inventario
original y las posibles ampliaciones; no todo campo allí propuesto se ha medido.
No modifica cuotas, física, premios, precios, duración ni RNG.

## Estructura y tipos

`session.json`: objeto con `schema_version`, `metadata`, `days`, `events`,
`active`, `sequence`, `coverage`, `dropped_days`, `dropped_events`, `recovered`.
`days` son jornadas cerradas; `active` es un snapshot parcial del día en curso
cuando se exporta. CSV incluye solo días cerrados; no inventar el resto del día.

Cada jornada contiene:

| Campo | Tipo/unidad y fuente |
|---|---|
| `id`, `run_id`, `day` | ID local partida:día:secuencia, run decimal, ordinal seguro; GameSession |
| `test_kind` | `human_normal`, `human_debug`, `automated_physics`; fijado al comenzar |
| `app_version`, `source_commit` | versión real y define de build; `unknown` si no suministrado |
| `configuration`, `configuration_sha256` | settings efectivos, niveles normales, P02/E03, reglas de cuota, estrellas, herramienta/sensor y digest del catálogo |
| `capture_radius_start/end`, `board.radius_max` | unidades lógicas; inicio/fin/máximo muestreado por update |
| `rng_initial/end` | Board, Launcher, sesión, gravedad/agujero negro y Evolution; estados efectivos, sin draws nuevos |
| `quota_start/end` | snapshots FeedingProgress, objetivos/progreso como decimal BigInt, cuatro jornadas vigentes |
| `quota_completed` | **cuotas completadas durante ese día**, no el ordinal acumulado |
| `coins_balance_start`, `coins_balance_end_before_bank`, `coins_balance_end` | cadenas decimales; saldo, antes del banco, resultado de cierre (0 en derrota/prestigio) |
| `coins_earned`, `coins_collected`, `coins_pending` | monedas de Economy/RewardDelivery; ingresos ganados, cobrados y obligación pendiente |
| `stars_start/end`, `e03_end` | snapshots autoritativos MetaProgress/EvolutionRun; ledger potencial, monedero, permanentes y cartas |
| `pending_extras_start/end` | colas reales P02/E03; inicio adicional en rng_initial.evolution |
| `ideal_main_balls_full_day`, `ideal_assumptions` | estimación analítica sin bloqueos/boost/extras/aceleración; no emisión observada |
| `board` | contadores, población, tiempo/edad y validación descritos abajo |
| `end_reason` | `day_complete`, `manual_finish`, `quota_defeat`, `voluntary`; `in_progress` en active |
| `discarded_live_at_close` | cuerpos vivos que se retirarán al cerrar; no sumarlos otra vez a `board.live` |
| `performance` | FrameTiming: frames/slow_frames >16667us, máximo jornada, p95/p99 de ventana última de hasta240; null sin muestras |

La metadata de exportación identifica plataforma objetivo Flutter y modo de build, catálogo
completo (precios normales, reglas P02/E03/estrellas), su digest y estado dirty
cuando se conoce. La versión de cada día histórico se conserva; el exportador
puede ser posterior. El runner añade escenario, semillas, estrategia v1, dt,
horizonte, condiciones, digest y motivo de parada. No incluye identificadores
personales ni necesita red. Contexto de dispositivo humano se adjunta con plantilla.

Los conteos e importes de métricas y CSV son **cadenas decimales exactas**.
Snapshots internos reutilizados (`stars_*`, `quota_*`, `rng_*`) conservan el formato
nativo v17: importes/IDs acotados a enteros seguros ≤2^53−1; objetivos/progreso de
cuotas son strings BigInt. No confundir que una cuota admita BigInt con economía
ilimitada. Segundos/radios son doubles finitos; ordinales/secuencias/µs de frames
son enteros seguros. Ratio derivado puede ser double; los operandos exactos mandan.

Digest: SHA-256 de JSON con claves ordenadas y orden de listas conservado. Los
números del JSON canónico del **hash** se representan como `{"#f64":"hex IEEE754
big endian de 8 bytes"}`; así 1/1.0 y VM/web producen la misma identidad. BigInt
es decimal string. No redondear settings. El archivo exportado sigue siendo JSON
legible normal; no usar `json.dumps` arbitrario para recalcular su digest.

## Board: diccionario de contadores

`board.counts` es un mapa disperso: **clave ausente significa cero dentro del
tramo observado**. No significa que el tramo anterior desconocido valiera cero.
`partial`, `initial`, `captured_baseline` y `partial_start` delimitan la cobertura.
Fuentes: main, launcher, p02_echo, p02_golden, e03_ram, e03_ration, unknown.

| Clave | Definición |
|---|---|
| `main_cycles` | vencimientos reales del reloj del generador |
| `requests.<source>` | demandas nuevas; cambios positivos de colas P02/E03 y oportunidades normales/lanzador; H04 una por día programado |
| `attempts.<source>` | una ejecución lógica; un extra puede reintentarse en distintos updates |
| `successful.<source>` | ejecuciones que crean exactamente un cuerpo |
| `blocked.<source>.<reason>` | primera condición bloqueante; main population/bubble/launcher/ball; launcher population/geometry/bubble/ball; extras outlet_exhausted |
| `outlet_probes`, `probe_blocked.<reason>` | posiciones comprobadas en salida extra (máximo21/intento), no demandas |
| `emitted`, `emitted.<source>` | cuerpos creados confirmados, excluye inyecciones |
| `debug_injected` | cuerpos de lluvia de monedas DEBUG; no producción humana normal |
| `captured`, `captured_ordinary/instant`, `captured.<source>` | retirada real única, instantánea si estaba en captureAllIds |
| `golden_captured`, `heavy_captured` | atributos, no nuevas capturas |
| `coins_base`, `coins_combo_golden`, `coins_e03_bonus` | valor base ordinario, importe tras combo/dorada y bonus E03; observados en el cálculo existente |
| `age_known/unknown`, `age_bin_lt1/1to5/5to15/ge15` | edad aproximada al update, histograma fijo; bins en segundos |
| `tool_us.<tool>` | tiempo de simulación seleccionado, redondeado por update; no contribución causal |
| `tool_selected.<tool>`, `ability_attempts/activations.<ability>` | selección/solicitud/activación confirmada |
| `input_touches/drags/releases/cancelled_releases` | llamadas observadas; cancelaciones pueden ser automáticas, no todas humanas |

`initial`, `live`, `peak`: población inicial/restante/máxima. `active_sim_s` suma
dt activos; pausa no llama update. `lifetime_sum_s` y age_known permiten media
observada; las bolas vivas tienen edad censurada (`age_censored`) o desconocida
(`age_live_unknown`). Los nacimientos se guardan solo para cuerpos aún presentes.
Resolución temporal: un update, normalmente1/60s; no timestamp exacto de contacto.
No guardar posiciones/trazas ilimitadas. `normalFood/instantFood` siguen siendo
monedas históricas y no se usan como contadores de bolas.

## Eventos y coherencia

Los snapshots de evento/inicio/fin se copian profundamente al observarlos: las
ventanas mutables de E03 no pueden cambiar la historia.

Eventos con secuencia persistida: cuotas completadas/activadas (orden de cuotas,
ordinal de crecimiento, estado final del lote), cuota activa al comenzar día,
star transaction antes/después/paid, compras normales (coste/saldo/nivel), P02,
ofertas/elecciones E03 (serial/opciones), pause, run_end y run_start.
Un evento quota_activated **no concede** otra recompensa. Estados `after_batch`
son posteriores al lote completo, no falsos snapshots intermedios.

1. `initial + emitted + debug_injected = captured + live` antes de retirar cuerpos.
   Al cerrar `live` pasa a descartes por causa; no contarlo dos veces.
2. `captured = ordinary + instant = sum(captured.<source>)`;
   emitted = suma de emisiones por fuente.
3. Por fuente: attempts = successful + suma de blocked. Sondeos se cuentan aparte.
   Colas inicial/final explican solicitudes que sobreviven; no hay IDs individuales
   de demanda ni se atribuyen a un nuevo día las demandas heredadas.
4. `coins_earned = collected + pending` en modo automático actual; liquidar o
   restaurar no produce otra captura ni otro earned. Compras aceptadas:
   balance_after = balance_before − cost. El monedero reiniciado se registra aparte.
5. P01 se observa desde ledger antes/después, no desde sprites; paid es cobro.
   Event_seq y datos guardados conservan historia; restaurar no reproduce premios.
6. Captura relativa = captured/emitted solo con initial0, cobertura completa,
   sin inyecciones y validación vacía. En otro caso null; no presentar una tasa falsa.
7. Validaciones fallidas se exportan/denuncian; métricas nunca reparan gameplay.
   El validador compara invariantes, no certifica balance ni experiencia humana.

## Persistencia, retención y coste

Campos opcionales `balanceLab` raíz v17 y `balanceMetrics` del tablero. Ausentes o
ilegibles: recuperar juego intacto, abrir tramo parcial y marcar recovered/partial;
no reinterpretar dinero ni inventar emisiones pasadas. Fecha/pared no entra en RNG.
DEBUG conserva sandbox existente: las jornadas normales previas se leen sin
reetiquetar; los días DEBUG se exportan **antes de salir/cerrar sandbox** y no se
escriben en la partida normal. No deshacer esta protección para instrumentar.

Máximo500 jornadas,2.000 eventos y4MiB de historias UTF-8, reservando1MiB para
metadatos/tramo activo. Descartes por retención se explicitan; totales son del
historial retenido. Escrituras coalescidas con guardado existente; contadores O(1)
por evento/update, sidecar O(población), sin serialización ni E/S adicionales por contacto/frame; los checkpoints ya
existentes serializan el tablero activo y copian el JSON histórico cacheado.
Serializar eventos de transacciones y exportaciones sí puede asignar memoria.

Objetivo provisional de CPU AOT: <2% mediana y<5% p95; medir mínimo5 repeticiones
alternadas, con carga/semillas iguales, sin otra tarea CPU simultánea. Informar
muestras/dispersión, no imponer gate temporal en CI compartida. Android se valida
en04; benchmark Linux no mide render/GPU. Resultados en `results/` y entrega.

## Disponible automáticamente / pendiente de medición manual

Automático: lo descrito arriba, incluidos bloqueos, capturas, estado económico,
cuotas, cartas, estrellas, herramientas y FrameTiming. No implementado/medido en
v1: tiempo de pared de pausa/tienda/selector/background (null), modelo/estado térmico
real, GC/GPU físico (null), historia anterior a instrumentación, contactos causales
por herramienta, percentiles exactos de toda la jornada y cohortes retrospectivos.
Manual: condiciones humanas, experiencia, estrategia real, ayudas, fluidez/atascos,
modelo/OS/Hz y observaciones térmicas. Usar protocolo04; no suplirlos con bots.
