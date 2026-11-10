# AUD01 — Desconocidos, divergencias y riesgos

**Versión auditada:** 0.23.0+36 · commit `0778d139d4a85124e0af2a9f89d595dc19159430`.  
**Fecha:** 27/10/2026. No se han aplicado correcciones ni decisiones de balance.

## Hallazgos que requieren seguimiento

La prioridad expresa impacto estimado de auditoría, no una autorización para implementar. `VERIFICADO EN CÓDIGO` significa lectura estática; los riesgos inferidos no se presentan como bugs reproducidos en móvil.

| ID | Prioridad | Estado de evidencia | Comportamiento definido / esperado | Comportamiento actual y diferencia | Fuentes / propuesta separada |
|---|---|---|---|---|---|
| AUD-F01 | Alta | VERIFICADO EN CÓDIGO | Cada nodo 0–4 vecinos distintos | `hand:1` tiene 6: hand:2, generator:1, reward:1, walls:1, bat:1, combo:1. Único infractor | `SkillTree` + CSV; validar una propuesta de reconexión con usuario, sin aplicarla aquí |
| AUD-F02 | Alta | DESCONOCIDO / INFERIDO | BAL01 debe demostrar rutas jugables antes de cada vencimiento | No hay datos de captura humana; sin mejorar, máximo ideal 22 bolas/jornada×4=88<100. La curva×10 exige fuerte crecimiento; no implica imposibilidad con mejoras/permanentes | `FeedingProgress`, `Board.update`; medir cohortes y estrategias, dinero y compras por cierre |
| AUD-F03 | Alta | VERIFICADO EN CÓDIGO | H04 garantiza exactamente una dorada por jornada | Reserva capacidad, pero las 21 salidas pueden estar bloqueadas hasta fin. En ese caso no aparece y la siguiente jornada reinicia la aparición | `_emitExtra`, `PermanentRun.beginDay`, `startDay`; decidir y probar política de garantía sin atravesar cuerpos |
| AUD-F04 | Media | VERIFICADO EN CÓDIGO | AJ-008A: anillo avanza desde progreso anterior y celebra cuota completada | `_HolePainter` recibe fracción final sin interpolación; `foodBefore` se calcula pero no se usa para el arco. Al consumir cuota inmediatamente, estado normal siempre points<target, así que la etiqueta completada no se activa. Tampoco hay próximo objetivo explícito en ese bloque; presenta cuota activa siguiente | `ResultsData`, `ResultsOverlay._holeCard/_HolePainter`; adaptar presentación a cuotas múltiples manteniendo economía; comparar con referencia aprobada |
| AUD-F05 | Media | VERIFICADO EN CÓDIGO | Configuración de cuotas identificable sin ambigüedad | CSV conserva feeding_quota_initial=10/step=10, pero son inertes para las cuotas actuales 100×10^n y plazo 4 definidos en clase | `catalog.dart`, `GameSession.feedingInitialQuota`, `FeedingProgress`; centralizar después de validar, no balancear desde parámetros muertos |
| AUD-F06 | Media | VERIFICADO EN CÓDIGO / DIFERENCIA DOCUMENTAL | Descripción genérica de “física Flame” o tiers puede interpretarse como funcionalidad actual | Física propia en Dart; solo bola normal/dorada/pesada y valor global. No tiers ni potenciadora, duplicadora, bomba o ventilador jugable | `Board`, `BallTool`, `Ball`; separar roadmap y catálogo real, sin inventar reglas |
| AUD-F07 | Media | VERIFICADO EN CÓDIGO / DISEÑO ABIERTO | AJ-005A: crecer 16% de área; diseño de límite visible pendiente | Fórmula usa crecimiento exponencial hasta proyección que cubre todo el tablero; puede sobrepasar bordes visibles. Hambre multiplica radio efectivo sobre esa proyección | `syncHoleGrowth`, docs de cambios futuros; discutir tope/representación, sin imponer uno en AUD01 |
| AUD-F08 | Alta en saturación | VERIFICADO EN CÓDIGO / MEDICIÓN PENDIENTE | P01 antiguo limita cuerpos; P02 posterior exige aparición inmediata | `populateImmediate` ignora star_active_limit=8 e introduce todas las pendientes, incluso juntas en centro. Es una decisión posterior P02, no un límite 8 operativo. Puede aumentar cuerpos/solapamientos y coste | `StarBubbles`, `_stepBubbles`; medir acumulación extrema/latencia, sin eliminar recompensas |
| AUD-F09 | Media | VERIFICADO EN CÓDIGO / MEDICIÓN PENDIENTE | BUG002 permite lluvia abundante con límitealto y secuencia | Un inicio por frame impone≈60 emisiones/s a 60Hz aunque emitMin 8,3 ms permita más; presupuesto 192 incluye monedas en salto/pausa/vuelo. Agrupación puede activarse por espera estimada 5 s, no solo por GPUmedida | `RewardVisuals._drain`, `tick`; medir percepción y throughput, no eliminar regla secuencial |
| AUD-F10 | Media | VERIFICADO EN CÓDIGO | No confundir sprites con ingreso ni sincronía exacta de cada paquete | Ledger programa cobro por tiempos independientes; cola/emisión/orden de pilas puede retrasar el sprite. No hay doble crédito, pero llegada y recogido interno no están ligados 1:1 | `RewardDelivery`, `_step`; validar sincronía perceptiva sin convertir sprites en fuente económica |
| AUD-F11 | Media | VERIFICADO EN CÓDIGO | Capacidad visual de pilas sin corrupción | Fuera de franja se recorta, no compacta ni sustituye por contador. Reservas lógicas siguen existiendo; la lista no se reduce al número de monedas físicamente visibles | `CollectionGrid`, `collection_painter.dart`; diseño de overflow fuera de alcance, medir cantidad típica |
| AUD-F12 | Alta para BAL01 | DESCONOCIDO | Estimar estrellas realmente disponibles y adquisición P02 | Solo se conoce estrella potencial por cuota; no hay tasa de rotura de burbujas ni tiempo humano invertido/causa de impacto por cohorte | P01 y DebugDayReport; métricas no invasivas separadas, no asumir 100% de cobro |
| AUD-F13 | Media | VERIFICADO EN CÓDIGO / RIESGO INFERIDO | Precisión y guardado en recorridos muy largos | Cuotas BigInt, pero monedas/estrellas/IDs usanint y validaciones 2^53−1 en muchos puntos; no hay garantía arbitrariamente grande compartida por todos los subsistemas | `Economy`, `StarLedger`, `RewardDelivery`, `MetaProgress`; probar límites de enteros/sumas/migraciones antes de extender horizonte |
| AUD-F14 | Media | VERIFICADO EN CÓDIGO | Términos claros de generación/pérdida | `DayResult.generated/lost` miden monedas; `DebugDayReport.spawned/captured` miden bolas. Interpretar generated como emitidas falsea tasa de captura | `progress.dart`, `debug_day_report.dart`; exportar esquema explícito para BAL01 |
| AUD-F15 | Alta para certificar calidad | DESCONOCIDO | Android 60FPS, GPU, sonido agradable y háptica cómoda | No hay dispositivo físico conectado ni nuevas mediciones. Benchmark Linux AOT es solo simulación y cambia población entre escenarios | `docs/performance/e03-evolution.json`, `tool/benchmark_evolution.dart`; perfetto/FrameTiming/CPU/memoria y sesiones auditivas en dispositivo de referencia |
| AUD-F16 | Baja / documentación | VERIFICADO EN CÓDIGO | Parámetros vigentes fáciles de identificar | collection_radius/coin_pile_limit mantienen sentido legacy; reward_max_wait 0,4 no controla espera emisor, ahora reward_emit_wait 5 por default; capCSV no siempre se valida/aplica genéricamente | `catalog.dart`, `RewardVisualConfig`; marcar fuente efectiva por parámetro, no borrar históricos durante auditoría |
| AUD-F17 | Media / integración física | VERIFICADO EN CÓDIGO / INFERIDO | Crecimiento del agujero consistente con interacciones P01 | Captura de bolas usa radio crecido, reexpulsión de burbujas usa distancia fija radioBurbuja+12. No cambia con hole growth | `StarBubbles.integrate`, `Board.captureRadius`; comprobar sensación con agujero grande y confirmar criterio de reentrada |
| AUD-F18 | Media / persistencia | VERIFICADO EN CÓDIGO / LÍMITE DE PRUEBA | Recompensas confirmadas sobreviven a restauración | Se solicita guardado al cambiar ingreso/meta, con cola y checkpoint. Cierre abrupto antes de completarse una escritura aún puede perder el último estado en memoria; no es transacción física por captura en disco síncrona | `tick/save/_drainSaves`, `FileSaveStore`; pruebas de interrupción real, no prometer durabilidad antes de completar I/O |

## Qué está implementado, sin confundir aprobación con ejecución

| Sistema | Integración real | Límites de afirmación |
|---|---|---|
| S03 | Derrota por cuotas 4 jornadas, confirmación de prestigio, reset, tienda y checkpoints | Precio/precondiciones de nodo siguen provisionalesBAL01; no narrativa final |
| C01 | Capturas crean obligación, presentación separada, restauración/liquidación, sin recogida manual en normal | Códigos de monedas físicas y balances previos se conservan para migración; no significa mecánica activa |
| AJ-008A | Dos tarjetas, secuencia monedas por denominación→hoyo→Tienda, saltos, monedero visual sin doble cobro | Parcial en interpolación de anillo/resumen de cuota completada; no comparar fidelidad de mockup sin imagen original |
| P01 | Ledger, burbujas físicas agarrables, umbral de impacto, cobro por rotura, reexpulsión/persistencia y pérdida | Parámetros de categoría/rotura provisionales; límite antiguo sobrepasado por P02 |
| P02 | Cuatro compras únicas, efectos y estados temporales/permanentes, confirmación/guardado y árbol bloqueado jornada 1 | H04 garantía absoluta no resuelta si completamente bloqueado |
| E03 | Doce cartas×5, sorteo/persistencia, pausa y elección por cuota, efectos físicos/económicos | Calibración humana y de dispositivo pendiente; no equivale a implementar tiers o otras CF |
| AJ009 | Pilas 2D por jornada, reservas/orden, restauración y reinicio visual | Overflow intencionadamente sin solución definitiva; saldo sigue independiente |

## Mediciones mínimas para BAL01 — propuestas, no implementadas

1. **Escenarios controlados:** primera partida sin permanentes; H01 solo; H02 solo; H04 solo; H13 solo; todas P02; perfilesE03 representativos y al 5. Guardar versión, semilla, tabla de compras, día, cuota y radio.
2. **Captura:** intentos normales, extras y secundarios, emisiones reales por variante, origen de cada captura, bolas presentes al cierre, fallos por motivo, capturas instantáneas por separado. `capturadas/emitidas` solo con denominador de cuerpos realmente creados.
3. **Interacción humana:** sesiones sin input/control básico/experto; tiempo de agarre, uso de poderes, herramientas y monedas/segundo activos según estrategia. No obtener tasa representativa de pruebas que inyectan bolas dentro del agujero.
4. **Prestigio:** burbujas emitidas/rotas/perdidas por categoría y cuota, impactos normales y fuerza, estrellas gastadas/conservadas; oportunidades reales de adquirir catálogo 28 ★ antes de terminarpartida.
5. **Rendimiento:** dispositivo Android identificado, build profile/release, CPU y GPU porframe,p 50/p 95/p 99/max, pausasGC, memoria, cuerpos/animaciones/voces simultáneas; pruebas 1/10/50/100/500 monedas y olas repetidas; 200 bolas+herramientas+burbujas.
6. **Persistencia:** interrupciones en captura/rotura/cartas/compra/prestigio, disco lleno/error, apertura tras fallo de archivo principal, restauración de opciones y estado último instante. Confirmar ausencia de crédito doble y tratamiento explícito del último snapshot duradero.

Diseño sugerido de exportación: un CSV temporal en memoria por escenario y resumen por jornada, con semilla/config y hashes; sin telemetría remota ni modificaciones de economía. Implementación y alcance deben ser una tarea aparte aprobada, tal como pide AUD01.

## Pruebas disponibles y verificación de esta entrega

- **En esta auditoría:** `AUD01_verificar.py` reconstruye directamente el grafo y contrasta nodos/conexionesCSV, referencias, grados, ciclos, componentes, requisitos, costes y posiciones. Valida aritmética de cuotas/área/denominaciones y hash de fuentes. Su salida se entrega en `AUD01_verificacion.txt`. Es extracción/análisisPython, **no ejecución de la implementaciónDart**.
- **Pruebas Flutter existentes localizadas:** `skill_tree_test`, `balance_test`, `four_day_quotas_test`, `feeding_test`, `hole_growth_test`, `currency_test`, `coin_rain_test`, `sequential_coin_emitter_test`, `daily_coin_collection_test`, `results_redesign_test`, `prestige_test`, `permanent_skills_test`, `star_bubbles_test`, `evolution_test`, `evolution_physics_test`, `evolution_persistence_test` y físicas/controles/audio. No se ejecutaron nuevamente por falta de SDK en PATH.
- **Regresión no cubierta identificada:** `skill_tree_test` verifica separación/descubrimiento/alcance, pero no impone máximo 4 vecinos. El conjunto previo 486 pasó aunque `hand:1` tenga 6.
- **Resultado previo de CI:** 486 correctas, análisis/compilación, [run 40327063421](https://github.com/migdlp/incremental_hole_game/actions/runs/40327063421). Se referencia; no se vende como ejecuciónAUD01.

## Criterios de aceptación de auditoría

- [x] Inventario completo de 55 nodos actuales y 15 nivelesretirados, con niveles/costes/requisitos/efectos/posición/persistencia/fuente.
- [x] Conteo de vecinos para cada nodo, regla 0–4 contrastada y un incumplimiento explícito sin corregir.
- [x] Grafo completo legible y conexionesprocesables distinguiendo arista de requisito.
- [x] Catálogo normal, P02/E03 y mecánicas ajenas; futuros marcados aparte.
- [x] Producción, captura, dinero, estrellas, tiempo, cuotas, derrota y reinicios documentados con fórmulas/fuentes.
- [x] Métricas faltantes e instrumentación propuesta sin inventar tasas.
- [x] Contradicciones y constantes inertes separadas de parámetros activos.
- [x] Entrega enMarkdown/CSV/JSON y documento único compartible.
- [x] Sin cambios en gameplay, balance, precios, dependencias, progresión o topología.
- [ ] Medición Android y captura humana: **no requerida para fingir datos; pendiente y declarada**.

El incumplimiento de diseño descubierto no impide completar AUD01: el objetivo de la auditoría es detectarlo y documentarlo. La corrección requiere otra tarea y discusión de topología con el usuario.
