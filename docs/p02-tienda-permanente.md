# P02 — Tienda permanente de prestigio

Versión 0.21.0+34. Catálogo aprobado por el usuario; sin niveles ni requisitos.

| ID | Habilidad | Precio | Efecto |
|---|---|---:|---|
| H01 | Herencia | 2 ★ | 100 monedas al crear cada nueva partida |
| H02 | Eco de producción | 6 ★ | 5 bolas extra cada 20 ciclos principales |
| H04 | Fiebre dorada | 8 ★ | Una dorada extra por jornada, con instante aleatorio |
| H13 | Lluvia astral | 12 ★ | Tirada independiente del 50 % por cuota para duplicar burbujas |

## Compra y acceso

Se reutiliza la tienda de S03, accesible tras confirmar el nodo de prestigio.
El precio/requisitos del nodo normal se conservan; P02 no establece otros.
Las cuatro tarjetas muestran efecto, precio, saldo insuficiente o adquisición.
Una confirmación permite cancelar sin cambios. La operación vuelve a validar
fase, saldo y propiedad. Comprar conserva un registro con valor uno, sin niveles.
Se puede continuar con cero estrellas, sin comprar o después de comprarlo todo.
El antiguo estado de derrota solo se admite para restaurar guardados históricos;
no se crean derrotas ni estrellas de consolación. AJ-005B permanece íntegro.

Las compras y el descuento comparten un único snapshot con revisión permanente.
Se reutiliza `PrestigeStore`: checkpoint completo antes del guardado principal.
Si el guardado normal se interrumpe, se recupera toda la operación; nunca media
compra. Hasta que el checkpoint sea durable no se habilita la siguiente operación.
Cerrar en la tienda restaura la tienda. Estrellas sobrantes y habilidades no se
pierden. Los identificadores desconocidos antiguos se conservan sin interpretarlos.

## Comienzo de partida y primera jornada

Continuar crea una única partida nueva y guarda su estado completo antes de iniciar
la producción. Herencia incorpora 100 al saldo bancado en esa transición, sin pasar
por capturas, registro de recompensas, resultados ni colección AJ-009. Restaurar
no entrega nada. Cada nuevo prestigio vuelve a conceder exactamente 100, sin sumar
el historial de concesiones. Si se interrumpe antes de arrancar la producción,
la partida nueva queda lista para comenzar con su saldo ya guardado.

En normal se oculta la entrada a la tienda antes de acabar la primera jornada.
La ruta del árbol tampoco muestra nodos y la API de compra rechaza operaciones.
Al cerrar el día 1 se habilita el flujo de resultados/tienda. Tras prestigiar vuelve
a bloquearse. DEBUG conserva sus compras aisladas para poder probar el árbol;
salir restaura la partida normal, incluidas las habilidades y sus contadores.

## Generación

`PermanentRun` se comparte entre tableros de una partida. Eco guarda el resto de
ciclos (0–19) y las bolas extra pendientes. Cada disparo principal cuenta una vez,
incluso con doble emisión o si su salida está bloqueada. Sus extras usan la misma
factoría, valor, doradas y física que la producción principal; actualmente no hay
un catálogo de tiers/especiales de generación implementado que deba inventarse.
El lanzador y la dorada adicional no incrementan ciclos. Las extras bloqueadas se
reintentan con posiciones seguras en la salida; no se crean cuerpos superpuestos
ni se supera la población. Lo pendiente continúa entre jornadas, no entre partidas.

Fiebre dorada elige al comenzar la jornada un instante dentro de producción usando
el RNG persistente de eventos. Guarda instante, tiempo simulado y si ya apareció.
Se reserva una plaza del límite global mientras está pendiente, también frente al
lanzador; la emisión forzada respeta el límite completo. Una salida obstruida se
reintenta durante producción, sin sustituir una bola ni contar un ciclo de Eco.
La reserva es la opción inicial propuesta al usuario para evitar perder la plaza;
queda validar el bloqueo extremo de toda la salida en Android. Si permaneciese
completamente obstruida hasta el cierre, la seguridad física prevalece: no se
fuerza una superposición; esa condición no está certificada como garantía de emisión.
La pausa congela los relojes. Restaurar no vuelve a sortear ni repetir la dorada.

## Lluvia astral y burbujas

Antes de sortear se comprueba la marca de cuota del registro P01. Por cada cuota
nueva se consume una tirada del RNG, de forma independiente; la decisión y el
registro de recompensas se guardan juntos. Las copias tienen identificadores
nuevos, categoría/valor idénticos y requieren romperse para cobrar. No se conceden
estrellas por aparición, entrada en el hoyo o prestigio. Las cuotas siguen contando
bolas capturadas, una por bola, sin cambiar objetivos ni recompensas monetarias.

P02 sustituye el límite/espera anterior de representación de recompensas nuevas:
todas se materializan inmediatamente desde el hoyo, sin descartar ni aplazar las
copias. También reaparecen juntas las pendientes al comenzar otra jornada. La
restauración admite cuerpos por encima del antiguo límite siempre que tengan
identidades válidas en el registro. Se mantienen controles, flotación, rotura por
impacto, reexpulsión y cobro idempotente. Prestigiar borra las pendientes, incluidas
las copias, conservando únicamente las estrellas efectivamente cobradas.

Se reutilizan cubetas espaciales para descartar pares lejanos cuando hay más de
24 cuerpos, manteniendo el orden de pares y la respuesta de contacto. Las
correcciones de posición se vuelven a indexar en el siguiente paso físico. Para
poblaciones pequeñas se conserva el recorrido anterior. No se reducen recompensas
ni se reinstaura un máximo de burbujas para ahorrar tiempo.

## Persistencia y archivos

Formato raíz JSON v14 conservado, balance v20 intacto. Campo opcional
`permanentRun`: ciclos, extras pendientes, instante/estado de dorada y reloj.
Los guardados anteriores sin ese campo comienzan con contadores vacíos, sin
reembolsos ni concesiones retroactivas. Se validan rangos y coherencia con las
habilidades, fase y tiempo de producción antes de mutar la sesión.

- Catálogo y estado: `lib/features/prestige/domain/permanent_skills.dart`.
- Compra permanente: `meta_progress.dart`; interfaz: `prestige_screen.dart`.
- Integración/ciclo/guardado: `lib/app/game_session.dart`.
- Generación y optimización: `lib/features/board/domain/board.dart`.
- Recompensas/copias: `star_rewards.dart`, `star_bubbles.dart`.
- Bloqueo inicial: `game_app.dart`, `skill_tree_screen.dart`.
- Pruebas: `permanent_skills_test.dart` y fixtures de compras/UI anteriores.
- Medición reproducible: `tool/benchmark_permanent_skills.dart`.

## Validación y límites

Suite completa final: **441 pruebas correctas**, incluidas 17 nuevas de P02.
Formato y análisis sin incidencias. Pipeline de Android correcta.

Validado en GitHub Actions: **441 pruebas correctas**, formato, análisis,
compilación Android y firma. Código `e43a6522af09d573dc72340a5865dd9b6b631993`.
[APK 0.21.0+34 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40208961570/artifacts/12605207063) · [Pipeline](https://github.com/migdlp/incremental_hole_game/actions/runs/40208961570) · [Registros](https://github.com/migdlp/incremental_hole_game/actions/runs/40208961570/artifacts/12604148738).
`046ebb0` conservado. Comparación de actualización sobre APK anterior omitida;
no se certifica compatibilidad de instalación entre APKs en esta ejecución.
Saturación extrema y bloqueo total de Fiebre dorada siguen pendientes según el documento.

Se cubren precios, saldo exacto/insuficiente, cancelación, compras repetidas,
restauración, guardado fallido, varias partidas, árbol bloqueado, extras, contador
entre jornadas, lanzador independiente, dorada/pausa, tiradas por cuota y cuerpos
por encima del límite anterior.

Perfiles AOT de Cloud en `docs/performance/p02-bubbles-before.json` y
`p02-bubbles-after.json`, con 100 bolas y herramientas, 600 muestras tras 60 pasos
de calentamiento. El perfil final conserva también el máximo del calentamiento.
Antes, 500 burbujas: p95 22,592 ms, p99 32,778 ms, máximo 71,286 ms, RSS 41,37 MB.
Después, en otra ejecución con carga compartida: p95 23,082 ms, p99 34,556 ms,
máximo 44,443 ms y pico de calentamiento 66,161 ms; RSS 11,17 MB. Otra muestra
intermedia obtuvo p95 14,527 ms: existe variación del entorno y no se presenta
una mejora garantizada de latencia. Con 100 burbujas, el perfil final tiene p95
4,810 ms y pico 18,355 ms. Son tiempos de simulación, sin GPU/audio/render Android.

La acumulación extrema sigue teniendo picos perceptibles en Cloud. No se certifican
60 FPS ni rendimiento estable en móvil. Quedan prueba física, renderizado, GPU,
memoria total del juego y bloqueo extremo de Fiebre dorada. No se han inventado
nuevas habilidades, precios del nodo, narrativa ni un diseño definitivo de tienda.
