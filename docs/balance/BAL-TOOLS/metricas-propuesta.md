# BAL-TOOLS-01 — Borrador del contrato de métricas

Estado: **borrador histórico del28/10/2026**. El contrato normativo implementado
es [contrato-v1.md](contrato-v1.md); algunas ampliaciones aquí propuestas no se
miden en v1. Este borrador no acredita mediciones humanas.
Fuente actual inspeccionada: `720c4a0fd4f0c1460fcf334c08fa5cddd8ee555b`.

## Identidad y vocabulario

Versión de datos propuesta: `bal_metrics/1.0.0`, independiente de JSON de partida
v17 y balance v20. Cambiar significado/unidad exige major; añadir campos opcionales,
minor. Un lector rechaza major incompatible y tolera campos opcionales desconocidos.
`null` significa no medido/no disponible; cero solo significa cero observado.
Cada valor incluye disponibilidad y alcance si procede. No inferir historia perdida.

- **Sesión de evaluación**: una recogida/exportación de datos, puede contener varias partidas.
- **Partida**: vida de `MetaProgress.runId`, termina en derrota o prestigio voluntario.
- **Jornada**: producción real identificada por partida + ordinal, no abrir/cerrar tienda.
- **Segmento**: tramo continuo entre comienzo, pausa, restauración o cambio de contexto.
- **Ciclo**: vencimiento del reloj del generador; no equivale a emisión.
- **Demanda**: bola solicitada por un ciclo o habilidad, identificable aunque se reintente.
- **Intento**: ejecución de una solicitud de emisión que puede crear un cuerpo o bloquearse.
- **Sondeo de salida**: una posición comprobada internamente; no otra demanda ni otra bola.
- **Emisión**: creación confirmada de una bola capturable; no sprite, burbuja ni moneda.
- **Captura**: retirada confirmada de esa bola, una vez, por agujero/barrido o Captura total.
- **Descarte**: bola aún viva retirada al cierre/reset, separada de monedas perdidas.

No usar `generated` ni `lost` sin sufijo de unidad. La prioridad de BAL01 es
`balls.captured / balls.emitted` para jornadas completas con población inicial cero,
nunca `monedas / bolas` ni `captured / intentos`. En segmentos restaurados usar el
cohorte de nacimiento conocido o informar `captured / (initial + emitted)` como
ratio distinto; sin denominador/cobertura fiable, la tasa es null. Inyecciones
DEBUG se informan aparte y no entran en una tasa humana normal.

## Envoltorio propuesto

El export JSON contendrá `metadata`, `configurations`, `runs`, `days`, `events`,
`validation` y `coverage`. La lista de eventos puede ser opcional/acotada; los
agregados de jornada y eventos económicos/progresión necesarios deben ser coherentes.

| Campo | Tipo / unidad / regla |
| --- | --- |
| `schema_version` | `bal_metrics/1.0.0` |
| `evaluation_id`, `run_id`, `day_id`, `segment_id` | IDs locales no personales; sin usar RNG jugable para crearlos |
| `record_id`, `event_seq`, `revision` | identidad y orden estables; reconstruir/reexportar no crea otro evento |
| `app_version`, `version_code`, `source_commit`, `source_dirty` | versión real; commit completo o `unknown`, dirty booleano o null |
| `build_mode`, `platform`, `runtime_version` | debug/profile/release; Android/web/VM; SDK/OS cuando disponible |
| `test_kind`, `strategy_id`, `strategy_version` | `human_normal`, `human_debug`, `automated_physics`, `analytical` |
| `assistance[]`, `mutations[]` | intervención DEBUG/inyección/cambio de configuración, con secuencia y tiempo |
| `configuration_id`, `configuration_sha256` | JSON canónico de ajustes **efectivos**, no solo CSV ni niveles nominales |
| `settings`, `normal_levels`, `p02_owned`, `e03_levels`, `quota_curve` | snapshots, con cambios fechados y configuración de la jornada histórica |
| `seed_set`, `rng_initial`, `rng_checkpoints` | todas las fuentes jugables, no solo semilla principal; desconocido explícito |
| `sim_time_us`, `active_production_us`, `wall_elapsed_us` | enteros no negativos; relojes separados; no fecha de pared para simular |
| `pause_us`, `choice_ui_us`, `shop_us`, `background_us` | tiempo de pared por fase; no imputarlo a producción/captura activa |
| `device_context` | modelo/OS/Hz/build y condiciones térmicas declaradas; sin serial, cuenta, ubicación o nombre |
| `coverage`, `truncated_before`, `dropped_detail`, `restored_from` | límites de observación y recuperación, nunca pérdida silenciosa |

Todos los enteros exactos de cuota/progreso/dinero/estrellas se exportarán como
cadenas decimales canónicas, incluido CSV. Índices y tiempos acotados pueden usar
números seguros ≤2^53−1. Los ratios derivados no son la fuente de verdad.

Los snapshots efectivos incluyen valores fuera del CSV: curva en FeedingProgress,
catálogo E03, P02, parámetros físicos, balanceVersion de jornadas antiguas y opciones
que afecten al experimento. Canonicalización: claves ordenadas, UTF-8, sin campos
volátiles, con regla de representación numérica documentada y probada entre Dart/JS.
Los decimales físicos se conservan con round-trip; no redondearlos al formar el hash.

## Diccionario mínimo

Conteos por jornada y suma por partida, salvo indicación. `by_source` debe
reconciliar con el total e incluir `unknown`, nunca repartirlo por estimación.

| Métrica | Definición, unidad y origen previsto |
| --- | --- |
| `production.main_cycles` | ciclos observados en el while de `Board.update` |
| `production.ideal_main_balls_full_day` | **calculada**, sin bloqueos ni extras/boost: floor(duración/intervalo) × balls_per_spawn; 22 solo en la configuración base de 15 s |
| `production.ideal_assumptions` | supuestos y horizonte completo/ejecutado del cálculo; si no se modelan efectos, no estimar un total ideal con E03 |
| `production.requests` | demandas creadas por ciclos y habilidades, antes de reintentos |
| `production.attempts`, `.successful`, `.blocked_by_reason` | cada intento lógico termina en éxito o bloqueo; motivos según primera condición evaluada, sin cambiar orden/short-circuit |
| `production.outlet_probes` | posiciones comprobadas por `_emitExtra`, separadas de intentos lógicos |
| `production.pending_extras_start/end`, `.cancelled_demands` | cola de efectos: lo pendiente no es emisión ni pérdida física |
| `balls.emitted`, `.emitted_by_source` | cuerpos creados; main, launcher, p02_echo, p02_golden, e03_ram, e03_ration; preservar fuente explícita y flags dorada/pesada |
| `balls.initial`, `.live`, `.peak`, `.discarded_by_reason` | población inicial/antes de cerrar/máximo observado y retiradas por cierre, derrota, prestigio o intervención |
| `balls.captured`, `.captured_ordinary`, `.captured_instant` | suma exacta; la causa es captura confirmada, no la herramienta más cercana |
| `balls.captured_by_source`, `.golden_captured`, `.heavy_captured` | origen de nacimiento estable; atributos no son nuevas emisiones |
| `capture.lifetime_sim_us` | histograma acotado, n/suma y percentiles aproximados identificados; edad desde creación, no desde última carga |
| `capture.age_unknown`, `capture.age_censored` | bolas importadas sin nacimiento conocido y bolas vivas al final; no edad ficticia cero |
| `capture.radius_start/end/max`, `capture.modifier_events` | radio efectivo de Board, crecimiento y E03 Hambre; unidades lógicas |
| `input.tool_selected_us`, `.grabs`, `.releases`, `.ability_attempts/activations` | duración de selección no prueba contribución causal; controles y poderes confirmados/rechazados separados |
| `coins.reward_base`, `.reward_after_combo_golden`, `.e03_bonus`, `.earned`, `.collected`, `.pending`, `.settled_at_close` | importes del cálculo existente, no recalcular ni cobrar desde métricas; base y bonus deben reconciliar con obligación económica |
| `coins.balance_start/end`, `.spent_normal`, `.refunds`, `.adjustments` | ahorro y flujos; ajuste/importación/inyección identificado, no ingreso de captura |
| `purchases.normal[]` | comando aceptado, ID/nivel, coste y saldo antes/después; `occurs_after_day` y `applies_from_day` si es nocturna |
| `quotas.activated[]`, `.completed[]`, `.progress_start/end` | ID de cuota, objetivo BigInt, excedente, día y tiempo; varias cuotas en un lote son varios eventos |
| `quotas.days_consumed`, `run.end_reason`, `run.prestige_count` | cuatro jornadas actuales; `quota_defeat`, `voluntary`, otro solo si existe en código; cierre normal no es derrota |
| `stars.awarded_value`, `.pending_value_start/end`, `.redeemed`, `.discarded`, `.spent_p02` | valor potencial realmente concedido en ledger frente a cobrado; distinguir valor de conteo de burbujas y categoría |
| `p02.purchases[]`, `e03.offered[]`, `e03.chosen[]` | IDs, niveles antes/después, coste en estrellas P02 y serial/opciones de carta; permanentes iniciales y finales |
| `performance.frames`, `.slow_frames`, `.build/raster/total_us` | FrameTiming; tamaño de ventana y ámbito del percentil explícitos |
| `performance.sim_step_us`, `.rss_bytes`, `.gc` | solo si se mide; en VM benchmark separado de gameplay Android; GC/GPU físico null si no hay herramienta |

Los nombres finales, unidades, jerarquía, política de redondeo y enums quedan por
cerrar en 01. No atribuir capturas “al robot/escoba” por correlación: guardar contactos,
selecciones y contexto como **observaciones**; cualquier efecto causal estimado es
un análisis posterior etiquetado y con método. No implementar ventilador/embudo.

## Fuentes reales y huecos

| Fuente actual | Reutilizar | Falta / cautela |
| --- | --- | --- |
| `Board.spawned/captured/goldenCaptured`, `BoardEvents` | total emitido y captura del paso | spawned no se serializa actualmente; no origen/edad ni conteos de intentos principales |
| `Launcher.attempts/shots/toJson` | intentos y tiros del lanzador persistidos | faltan motivos; no equivalen a todos los generadores |
| `Board._emitMain/_emitExtra/_advanceLauncher` | puntos únicos de emisión | extra hace hasta 21 sondeos por intento; no multiplicar producción potencial por esos sondeos |
| `Board.normalFood/instantFood` | contabilidad monetaria histórica | son **monedas**, no bolas ni cuotas; contar tipos de captura en la retirada real |
| `DebugDayReport`, `GameSession.debugReports` | adaptar su resumen/copia a la fuente común | solo DEBUG, 20 jornadas, efímero, no guardar ni recuperar; no duplicar otro panel |
| `DayResult` y `Economy/RewardDelivery` | ingreso, saldo, obligación y liquidación | generated/lost son dinero; último resultado no historial; derrota retorna antes de crear DayResult |
| `FeedingProgress`, `StarLedger`, `PermanentRun`, `EvolutionRun` | cuotas, premios, compras y elecciones ya confirmadas | registrar antes de `_clearRun`; las animaciones no conceden ingresos |
| `RewardFrameMetrics` y callback en `game_app.dart` | ventana 240 y contadores; extender salida estructurada | solo añade muestras DEBUG activo; p95/p99 ventana ≠ jornada; raster ≠ GPU físico |
| `RewardVisuals`, feedback y benchmarks de `tool/` | límites, agrupación, voces y escenarios técnicos existentes | semillas cosméticas separadas; no convertir sprites en contabilidad ni benchmark Linux en Android real |

RNG a inventariar: Board, Launcher, eventos de sesión/gravedad/agujero negro,
EvolutionRun.randomState/cardRandom y semillas visuales. Las nuevas métricas no
pueden consumir ninguno. El simulador debe fijar todas las fuentes que afecten a
resultados; sensores requieren serie grabada/definida, no lecturas de pared.

## Coherencia y transiciones

1. `initial + emitted + debug_injected = captured + live + discarded` en cada
   frontera de segmento/jornada; inyección se marca y nunca cuenta como producción normal.
2. `captured = ordinary + instant = sum(captured_by_source)`; fuentes desconocidas
   explícitas. Monedas y estrellas no entran en este balance de bolas.
3. Por fuente, `attempts = successful + blocked`; demandas pendientes/reintentadas
   tienen IDs y ciclo de vida aparte. Sondeos no entran en esta igualdad.
4. `coins.earned = collected + pending` durante producción; al cerrar se liquida
   lo pendiente una sola vez en el modo automático actual. La restauración puede
   liquidarlo: registrar transición sin otra captura/ingreso ganado. No imponer
   esta política a jornadas legacy de cobro manual.
5. Cada compra aceptada cumple `saldo_después = saldo_antes − coste`; saldo de
   partida reconcilia bancos, gastos, devoluciones y ajustes. Registrar descarte de
   saldo al prestigiar/derrota, no como dinero gastado ni como captura perdida.
6. `pending_stars_end = pending_start + awarded − redeemed − discarded`;
   `wallet_stars_end = wallet_start + redeemed − spent_p02 + explicit_adjustments`.
   Conservar exactitud al cambiar de partida; no asumir 100% de rotura/cobro.
7. Cuota completada, crecimiento, concesión P01 y elección E03 tienen identidades
   y cardinalidad verificables según reglas/P02/E03 efectivos, sin reconstruir
   premios en el analizador. Restaurar/reexportar no concede ni cuenta dos veces.
8. Finalizar métricas de jornada **también en derrota y cierre tras carta E03**,
   antes de que el early return y `_clearRun` borren sus fuentes; idempotencia con
   ID/revisión. La historia de partida sobrevive al reinicio, con su retención explícita.
9. Desconocidos, inconsistencias, campos fuera de alcance y truncamientos aparecen
   en `validation/coverage`; CSV usa vacío/null documentado, no “0” engañoso.

## Integración mínima y coste propuesto

- Fuente única en dominio (Dart sin Flutter); adaptadores de Board/sesión/UI. El
  reporte DEBUG existente pasa a ser una vista, no otra contabilidad.
- Contadores/agregados durante el paso; sin escribir, serializar, ordenar
  percentiles ni asignar un objeto por contacto/frame. Sidecar por bola limitado a
  población física; histogramas/eventos acotados. Evitar otra lista ilimitada de posiciones.
- Persistencia local coordinada con snapshots y checkpoints, pero métricas sin
  autoridad sobre saldo/RNG. Recuperación de métricas ausentes/corruptas no debe
  invalidar una partida válida. No backfill inventado; abrir segmento de cobertura.
- Definir en 01 una política de retención y un presupuesto cuantitativo antes de
  implementar: propuesta inicial para evaluar, 1.000 jornadas/5 MiB de agregados,
  detalle rotatorio explícito; coste objetivo provisional <2% mediana y <5% p95
  CPU de simulación instrumentada frente a la misma carga y semillas, con ≥5
  repeticiones y dispersión. No son mediciones ni umbrales de gameplay aprobados.
- Publicar memoria máxima, operaciones por paso y metodología on/off. No hacer
  depender el desbloqueo de exportación de tener ya participantes Android de 04.
  Los tiempos CI compartidos son informativos; resultados de balance no deciden
  automáticamente precios ni cuotas, ni son gates temporales inestables.
