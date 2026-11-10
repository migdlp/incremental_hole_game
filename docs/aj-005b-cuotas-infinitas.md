# AJ-005B — Cuotas infinitas por bolas capturadas

> **27/10/2026 — Cuotas vigentes:** 25 → 50 → 100 → 500 → 1.000 → 10.000
> → 100.000 → 1.000.000 → ×10. [Curva y migración](cuotas-progresion-inicial.md).
> JSON v17; se conservan el plazo de cuatro jornadas y las cartas E03 actuales.


Implementado sobre `build/apk-0.6.0+13` (base `7d5266f`) e integrado con
AJ-007 y su banco de audio offline (`46b623a`). Sustituye las reglas
monetarias y los vencimientos de S01/S03; conserva economía C01, estrellas P01
y fórmula de área AJ-005A. No cambia duración, precios ni tienda de prestigio.

## Reglas vigentes

Cada bola capturable retirada por `Board.update` aporta una unidad mediante
`BoardEvents.captured`. Se incluyen doradas, racha, todos los generadores y
Captura total. Las recompensas `rewards`, `normalFood` e `instantFood` del tablero
siguen siendo importes económicos históricos: no se usan para alimentar.
Monedas visuales y burbujas de estrellas nunca emiten capturas de bolas.

La cuota 1 exige 100 bolas; cada nueva cuota multiplica el objetivo por 10.
Los campos `feeding_quota_initial` y `feeding_quota_step` del CSV se retienen
solo para validar configuraciones históricas: AJ-005B usa la fórmula confirmada
en `FeedingProgress`, sin reutilizar el paso monetario provisional.
El progreso se consume al completar cada objetivo, arrastrando todo excedente.
Una captura de 1.200 desde cero completa 100 y 1.000 y deja 100/10.000.
`FeedingProgress.credit` devuelve los niveles completados en orden, con un evento
por cuota. No hay máximo de cuotas definido ni relación con el día global.

La sesión aplica el crecimiento y entrega cada evento a `StarLedger.award` en
el mismo paso. Cada cuota genera su recompensa P01 una sola vez; se conservan
las identidades y la política existente de cobro de burbujas. AJ-007 recibe un evento audiovisual por cuota, respetando su agrupación de
sonido. No se espera al cierre de jornada ni se abre una pantalla al cumplir cuotas.

HUD, anillo, Tienda y resultados muestran inmediatamente la cuota activa,
progreso y bolas restantes. La animación de resultados puede animar el recuento
diario, pero no reproduce un objetivo antiguo ni revierte el indicador. No hay
cuenta atrás ni jornadas restantes para la alimentación. Los números se agrupan
con puntos; sobre 24 dígitos se usa notación científica, con ≈ si se abrevia.
La lógica y la persistencia siempre conservan todos los dígitos.

## Crecimiento y espacio físico

Cada cuota añade una aplicación de `área × 1,16`, equivalente a
`radio × sqrt(1,16)`, al contador persistente de AJ-005A. La sesión sincroniza
ese contador con el tablero, sin volver a ejecutar recompensas al restaurar.
Se conserva el centro configurable del agujero y el mismo radio para dibujo,
atracción ordinaria y captura directa/barrida.

El render existente recorta al tablero. La proyección física del radio solo se
satura cuando el círculo ya cubre la esquina más lejana: todos los puntos del
tablero están entonces dentro del área de captura. Esta equivalencia espacial
evita radios infinitos al evaluar crecimientos extremos. Las cuotas, eventos,
recompensas y contador de crecimientos siguen avanzando; no se limita la
progresión económica ni se cambia el tamaño o las paredes del tablero.

## Guardado y migración

JSON **v14**, sin cambiar balance v20 ni sus configuraciones históricas.
`feeding.rules = balls-v1`; objetivo inicial, objetivo actual, progreso normal e
instantáneo y capturas de jornada se guardan como cadenas decimales canónicas
de `BigInt`. Se guardan también nivel activo (`period`), cuotas completadas
(`period - 1`), `growths` y marcador `growthPeriod`. La lectura valida fórmula,
excedentes ya consumidos, marcadores y capturas de jornada antes de aplicar nada.

Los campos de jornada solo validan continuidad y restauración; no vencen ni
reinician cuotas. Se guarda al capturar, cambiar de cuota, terminar jornada,
comprar y pausar, usando el sistema serializado de snapshots/checkpoints existente.
Un cierre forzado puede retroceder al último guardado correcto, como antes.

Para v8–v13, el lector histórico valida primero las cantidades monetarias y su
coherencia con el tablero. Se conservan períodos históricos ya liquidados y la
cuota actual si ya estaba cumplida. Se preserva exactamente `growths`; una cuota
anterior a AJ-005A no recibe retrospectivamente un crecimiento. Tampoco se
reproducen eventos ni burbujas históricas, cobradas o pendientes.

**Limitación:** los contadores anteriores de la cuota y de la jornada almacenaban
importe, con posibles multiplicadores. No existe un historial fiable de bolas
para toda la cuota actual. Su progreso parcial monetario se inicia a cero, sin
interpretarlo como bolas. El contador `board.captured` solo describe la jornada
activa; se conserva como `runCapturedBaseline` para verificar nuevas capturas,
sin inventar un total del período ni acreditarlas dos veces. En v1–v7 se inicia
la cuota 1 sin alimentación histórica. Toda captura posterior a la migración
cuenta inmediatamente, también durante una jornada histórica interrumpida.

Se conservan dinero, compras, resultados, opciones, datos permanentes y burbujas
P01, respetando las migraciones ya existentes. Restaurar repetidamente no concede
crecimientos ni estrellas. Los checkpoints v14 se aceptan también en la carga
de metaprogresión; una copia antigua no revive una partida terminada.

## Prestigio y DEBUG

No existe transición a derrota por cuotas, en normal ni DEBUG, aunque se jueguen
muchas jornadas vacías. No se introduce otra causa de muerte ni prestigio
automático. El nodo voluntario y su confirmación mantienen las reglas de S03;
reinician alimentación y crecimiento una sola vez junto al resto de la partida.
Las pantallas/estados de derrota históricos siguen siendo legibles para recuperar
guardados anteriores; su rediseño queda pendiente.

DEBUG permite objetivos de prueba y reinicios aislados. Se elimina la opción
«Probar derrota y prestigio» y se cambia «Simular fallo» por cuotas de prueba sin
vencimiento. Salir de DEBUG restaura la partida real y no escribe sus recompensas.

## Verificación

La suite cubre excedentes 90+30 y 1.200, cuotas superiores a 64 bits y a double,
serialización exacta, capturas doradas/con racha y Captura total, monedas ajenas a
alimentación, 30 jornadas vacías, pausa, compra, recuperación, eventos múltiples
P01, crecimiento físico/visual AJ-005A y ausencia de duplicados. También conserva
las pruebas de economía y de recuperación de prestigio histórico.

El resultado de ejecución se registra en [validación](validacion-prototipo.md).
Validación táctil y rendimiento en Android físico pendientes.
