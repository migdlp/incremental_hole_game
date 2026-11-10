# Relevo de contexto — Feed the Hole

## BAL-TOOLS — Laboratorio de balance (29/10/2026)

[Estado y tickets #21–#26](balance/BAL-TOOLS/README.md) ·
[Contrato v1](balance/BAL-TOOLS/contrato-v1.md) · [Uso](balance/BAL-TOOLS/uso.md) ·
[Entrega y evidencias](balance/BAL-TOOLS/entrega.md).
Build instrumentada0.24.0+38, JSON v17/balance20. Exportación local DEBUG,
runner de GameSession y comparador disponibles. BAL01 puede iniciar recogida;
04 y referencia humana de06 pendientes de testers Android. Sin cambios de
cuotas/precios/físicas. AUD01 sigue siendo histórico de0.23.0+36.

> **27/10/2026 — Cuotas vigentes:** 25 → 50 → 100 → 500 → 1.000 → 10.000
> → 100.000 → 1.000.000 → ×10. [Curva y migración](cuotas-progresion-inicial.md).
> JSON v17; se conservan el plazo de cuatro jornadas y las cartas E03 actuales.


## E03 · Cartas de evolución permanente (0.23.0+36)

Cada cuota concede una elección persistente entre hasta tres habilidades elegibles,
con doce habilidades de cinco niveles. Tablero y relojes congelados hasta resolver
la secuencia y guardar cada subida; los niveles sobreviven a muerte/prestigio y los
contadores se reinician por partida. Compatible con cuotas de cuatro jornadas,
P01, P02 y AJ-009; JSON v16 y balance v20. Sin costes ni cambios en el catálogo P02.
[Especificación](e03-cartas-evolucion-especificacion.md) · [Implementación, archivos y pruebas](e03-evolucion-implementacion.md).

Entrega validada: **486 pruebas correctas**, formato, análisis, compilación Android
y firma. Fuente `a385b8592d37b88121c87f72abf1ced21a876204`.
[APK 0.23.0+36 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40327063421/artifacts/12652625160) · [Pipeline](https://github.com/migdlp/incremental_hole_game/actions/runs/40327063421) · [Registros](https://github.com/migdlp/incremental_hole_game/actions/runs/40327063421/artifacts/12651519034).
Validación y perfil de simulación: ejecución `40325929678`. Pendiente Android físico.
`046ebb0` conservado en el historial. Comparación de actualización con APK anterior
omitida; compatibilidad de instalación entre APKs no verificada en esta ejecución.


## S03 / AJ-005B · Cuotas de cuatro jornadas (0.22.0+35)

Cada cuota dispone de cuatro jornadas; la siguiente comienza inmediatamente y
cuenta como primera la jornada en que se activa. Al cerrar la cuarta sin cumplir,
DERROTA directa sin resultados → tienda P02. Crecimiento y premios se procesan
antes de evaluar el vencimiento. Plazo visible únicamente en el resumen.
Día siguiente al comenzar producción; migración segura sin derrota retroactiva.
JSON v15, balance v20, catálogo/precios P02 y nodo voluntario sin cambios.
[Especificación](s03-aj005b-cuotas-4-jornadas.md) · [Implementación y pruebas](cuotas-4-jornadas-implementacion.md).
Esta regla sustituye los textos históricos de cuotas sin vencimiento.

Entrega validada: **457 pruebas correctas**, formato, análisis, compilación Android
y firma. Código `07803a5eed44571e9d91757b1c15e3cbfa8b9c7d`.
[APK 0.22.0+35 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40217807563/artifacts/12607534495) · [Pipeline](https://github.com/migdlp/incremental_hole_game/actions/runs/40217807563) · [Registros](https://github.com/migdlp/incremental_hole_game/actions/runs/40217807563/artifacts/12607624051).
`046ebb0` permanece en el historial. Prueba de actualización con APK anterior omitida;
compatibilidad de instalación entre APKs no verificada en esta ejecución.
Pendientes Android físico y balance BAL01.


## P02 · Tienda permanente (0.21.0+34)

Cuatro compras únicas con estrellas: Herencia (2), Eco de producción (6), Fiebre
dorada (8) y Lluvia astral (12). Confirmación y checkpoint íntegro de compra;
contadores de partida separados. Continuar prepara la nueva partida y comienza
su primera jornada. La tienda normal queda bloqueada hasta terminar el día 1.
Burbujas de cuotas nuevas inmediatas; se conservan sus reglas de rotura y cobro.
[Implementación, pruebas y límites](p02-tienda-permanente.md). Android físico y saturación extrema pendientes.

Validado en GitHub Actions: **441 pruebas correctas**, formato, análisis,
compilación Android y firma. Código `e43a6522af09d573dc72340a5865dd9b6b631993`.
[APK 0.21.0+34 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40208961570/artifacts/12605207063) · [Pipeline](https://github.com/migdlp/incremental_hole_game/actions/runs/40208961570) · [Registros](https://github.com/migdlp/incremental_hole_game/actions/runs/40208961570/artifacts/12604148738).
`046ebb0` conservado. Comparación de actualización sobre APK anterior omitida;
no se certifica compatibilidad de instalación entre APKs en esta ejecución.
Saturación extrema y bloqueo total de Fiebre dorada siguen pendientes según el documento.


## AJ-009 · Pilas de monedas de la jornada (0.20.0+33)

El gameplay sustituye el saldo numérico por pilas 2D superpuestas, con perspectiva
ovalada, en una franja fija entre tiempo y tablero. Aspecto aprobado por el usuario.
Reservas y llegadas ordenadas, reinicio diario, pausa/restauración y cierre visual
acotado; economía, denominaciones y compras intactas. JSON v14 y balance v20.
[Detalles, imagen aprobada y pruebas](aj009-coleccion-monedas.md). Android físico pendiente.

Validación publicada: **424 pruebas correctas**, formato, análisis, compilación y firma.
Código `6f83f479b1d2e82d5c8e33fa538fb05956822c0d`, con `046ebb0` conservado en el historial.
[APK 0.20.0+33 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40184781696/artifacts/12596006493) · [Pipeline](https://github.com/migdlp/incremental_hole_game/actions/runs/40184781696) · [Registros](https://github.com/migdlp/incremental_hole_game/actions/runs/40184781696/artifacts/12596281025).
Prueba de actualización sobre APK anterior omitida por la configuración habitual;
compatibilidad de instalación entre APKs no verificada en esta ejecución.


## Monedas aisladas · 0.19.2+32

Las monedas aisladas usan un tintineo corto con tres notas de la cascada existente
(350 ms), en lugar de una nota suelta. La secuencia y los archivos de la lluvia
masiva permanecen idénticos. Una sola voz precargada por tintineo, con los límites
de mezcla y háptica de AJ-007. Sin cambios visuales, económicos ni de guardado.
Recurso `coincascade.wav`, regenerable con `tool/generate_feedback_audio.py`.

Validación: 20 pruebas de audio locales y pipeline completa correcta.
Código compilado `595a2db`.
[APK 0.19.2+32 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40145151929/artifacts/12581060597).
La escucha final en móvil queda pendiente de la valoración del jugador.


## BUG-002 · Expulsión secuencial (0.19.1+31)

Un emisor compartido sustituye las familias de dirección y el escalonado repetido.
Una moneda nueva por fotograma, dispersión pequeña variada y ola horaria con
cadencia/giro progresivos. Trayectorias adaptadas al hoyo y a los bordes;
pausa de un segundo y vuelo al monedero conservados. Parámetros DEBUG, pool
adaptativo y contabilidad intacta; balance v20 y JSON v14 de AJ-005B conservados.
[Detalles, archivos, pruebas y límites](bug002-expulsion-secuencial.md). Android físico pendiente.

Validado en la pipeline: **412 pruebas**, análisis, formato, compilación y firma.
Código compilado `038f026`.
[Descargar APK 0.19.1+31 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40142624007/artifacts/12578883845).
Incluye la integración remota de AJ-005B.


La rama remota incorporó AJ-005B durante BUG-002: cuotas infinitas por bolas,
sin vencimiento, JSON v14. Se conserva íntegramente; prevalece sobre las reglas
históricas. Detalles: [AJ-005B](aj-005b-cuotas-infinitas.md).

## AJ-007 · Feedback audiovisual (0.19.0+30)

Audio offline centralizado con plops variables, absorción y rodadura compartidas,
cascadas musicales de monedas y cristal/estrellas. Háptica agrupada independiente,
volumen persistente y controles DEBUG. Cada bola se hunde bajo el borde del hoyo;
reacciones agrupadas y compatibles con su crecimiento. Sin cambios económicos.
Escucha, vibración y rendimiento en Android físico pendientes de calibración.
[Arquitectura, recursos, pruebas y límites](aj007-feedback-audiovisual.md).


Validado en GitHub Actions: formato, análisis, **410 pruebas**, compilación Android
y firma correctos. Código `46b623a`.
[Descargar APK 0.19.0+30 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40140079810/artifacts/12578322298).
Comparación de firma con APK anterior no ejecutada; no certifica actualización.

## BUG-001 · Lluvia de monedas (0.18.1+29)

Microlotes de 200 ms, siete monedas para 34, expansión exacta y variada para
recompensas grandes, pool reutilizable y agrupación solo bajo presión. Los
recuentos del resumen AJ-008A proceden del microlote, no de los iconos agrupados.
Salida normal en 0,2–0,32 s; se mantiene la pausa tras el salto. Pool inicial
provisional de 192 basado en medidas de Cloud; rendimiento Android físico
pendiente, sin certificación de 60 FPS. Balance v20, con v19 congelado.
Incluye el rediseño AJ-008A. [Detalles y mediciones](bug001-lluvia-monedas.md).

Validado: formato, análisis y **392 pruebas**, compilación Android y firma.
Código compilado `d41b711`; [APK 0.18.1+29 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557/artifacts/12569447730). Incluye AJ-008A y BUG-001.

## AJ-008A · Resultados animados (0.18.0+28)

Nuevo modal con monedas por denominación hacia el monedero real, seguido del
progreso del hoyo; Tienda aparece al finalizar. Saltos por bloque, movimiento
reducido y scroll móvil. Contabilidad de presentación separada del cobro real.
Paleta 1/10/50/100/500: bronce/plata/oro/verde/rojo. Sin cambios económicos.
Mockup y vídeo no adjuntos: fidelidad visual pendiente de cotejar; pruebas en
Android físico pendientes. [Detalles, archivos y validación](aj008a-resultados.md).

## AJ-005A · Crecimiento por cuota (0.17.0+27)

Cada cuota completada aumenta el **área de captura un 16 %**, una sola vez:
radio = radio base × √(1,16^cuotas). El dibujo y la captura usan el mismo radio.
Se aplica en la jornada actual y persiste entre jornadas y reinicios; se pierde
al terminar la partida normal, como el resto de su progresión temporal.
No depende de compras, no añade nodos y conserva el centro al 22 % de altura.
JSON v13 registra número de crecimientos y última cuota aplicada. Los guardados
anteriores conservan su progreso y empiezan a crecer con la siguiente cuota;
las cuotas ya completadas no se vuelven a premiar. Balance v19 sin cambios.
Los tiempos y la estética de monedas de 0.16.2 se conservan.
**Decisión consultada aún abierta:** tamaño al llegar a los bordes. No se añade
un tope de balance sin aprobación; se mantiene el crecimiento solicitado del 16 %.

Validado: formato, análisis y **369 pruebas**, compilación Android y firma.
Código compilado `9615d08`; [APK 0.17.0+27 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40111416219/artifacts/12566373126). Prueba táctil en Android físico pendiente.

## Tiempos de monedas · 0.16.2+26

Se conserva el dibujo, el salto de salida y el recorrido de las monedas.
Tras aterrizar quedan inmóviles **1 segundo** y después vuelan al monedero
con un inicio más lento y aceleración progresiva, manteniendo el final suave.
El cobro visual espera también esa pausa; importes, liquidación al cerrar,
restauración y ausencia de física/interacción permanecen iguales.
Incluye la corrección del hoyo al 22 % de altura descrita debajo.

Validado: formato, análisis y **360 pruebas**, compilación Android y firma.
Código compilado `e409af8`; [APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39861748135/artifacts/12462915831). Sin prueba táctil en Android físico.

## Posición actual · 0.16.1+25

Por nueva indicación del usuario, el hoyo pasa del 74 % al **22 % de altura**:
centro **(180,123.2)**, con la horizontal en 180. Captura, succión, monedas y
estrellas comparten la posición. Balance v19 con v18 congelado; las jornadas
ya empezadas conservan su configuración y la siguiente usa el 22 %.
La aclaración posterior AJ-005A vincula el crecimiento a cuotas; esta entrega histórica solo cambió la posición.

## Entrega anterior · AJ-001 a AJ-004 (0.16.0+24)

Fuerza de agarre alta desde el inicio, sin niveles ni rama; capacidad 1–6
conservada. Compras de fuerza anteriores devueltas una sola vez. Monedas con
cara/canto/grabado y contador sin fondo. Hoyo en (180,414.4), aproximadamente al 75 % del tablero,
con origen compartido por captura, succión, monedas y estrellas.

JSON v12 / balance v18 con v17 congelado para jornadas ya empezadas. Su siguiente
jornada aplica los cambios. Acercar el hoyo al generador hace posibles capturas
rápidas automáticas: no se compensan cambiando otras mecánicas.
**Aclaración posterior AJ-005A:** el crecimiento corresponde a cuotas completadas;
no se añade una rama de nivel del agujero. [Estado y compatibilidad](ajustes-version-actual.md).

## P01 · Estrellas y burbujas físicas (0.15.0+23)

Completar una cuota expulsa burbujas físicas; agarrarlas y lanzarlas contra paredes
o herramientas permite romperlas y cobrar estrellas permanentes. Un premio por
cuota y un cobro por identidad, separados del vuelo visual. Pendientes reaparecen
entre jornadas, con un límite de cuerpos activos que no elimina recompensas.
**Al morir o prestigiar se pierden las pendientes; las cobradas se conservan.**
Esta regla P01 sustituye la conservación opaca provisional descrita en la entrega
S03 inferior. No se convierten pendientes en saldo automáticamente.

JSON v11 / balance v17 con v16 congelado. DEBUG permite forzar premios y ajustar
todos los parámetros provisionales. Gravedad/succión se comparan mediante
interruptores experimentales en DEBUG; su integración final sigue abierta.
P02 y BAL01 continúan pendientes. [Contrato y pruebas](p01-estrellas-burbujas.md).

## Entrega anterior S03 · Prestigio y derrota (0.14.0+22)

**Decisión expresa del usuario:** activar derrota en juego normal con las cuotas
provisionales actuales. Al incumplir el quinto día se termina la partida y aparece
**DERROTA**, sin estadísticas. Continuar abre la tienda de prestigio; Nueva partida
vuelve al día 1. Se reinician monedas, mejoras, herramientas y alimentación, y se
conservan estrellas cobradas, compras permanentes, descubrimientos y datos P01 pendientes.

Nodo Prestigio visible desde el comienzo al explorar, mayor y girado 45°, tanto en
normal como DEBUG. Su compra exige confirmación y reinicia inmediatamente, sin
botón posterior. Configuración de prueba: 10.000 monedas, Generador V + Valor V +
Duración V, esquina avanzada (48,48). **No son decisiones finales de BAL01.**

La tienda muestra estrellas y permite nueva partida, sin catálogo P02 ni premios
P01 inventados. Morir no concede estrellas. JSON v10 / balance v16, con v15 congelado.
Checkpoint permanente independiente, dos copias actuales y barrera de revisión:
una copia normal antigua no puede reabrir una partida terminada. DEBUG es temporal.
[Contrato, integración y pruebas](s03-prestigio-metaprogresion.md).

S03 sustituyó las cuotas sin derrota. P01 ya añade burbujas; P02 y BAL01 siguen pendientes.

## C01 · Cobro automático vigente (0.13.0+21)

Cada captura calcula una única recompensa completa (Valor, dorada y racha),
alimenta inmediatamente y registra el importe garantizado. Tras aproximadamente
1 s, una moneda decorativa salta del hoyo y vuela en curva al monedero; el saldo
visible aumenta al recibirse. No hay colisiones, recogida manual ni fase final
de recogida: producción base 15 s y cierre directo con liquidación íntegra.

Barrido, Área, Imán y Atracción salen del catálogo activo. El usuario autorizó
retirar sus compras **sin reembolso**; no se altera saldo ni otras mejoras.
Robot conserva solo Escoba ancha II como requisito, confirmado por el usuario.
JSON v9 / balance v15, con v14 congelado para física de jornadas antiguas.
Registros económicos y pool visual independientes; agrupación u omisión visual
no pierde dinero. Restaurar liquida directamente lo pendiente, una sola vez.
[Implementación, DEBUG y medición pendiente](c01-cobro-automatico.md).

Las referencias anteriores a recogida manual o fase final describen versiones
históricas y quedan sustituidas por C01.

**Actualizado: 24/10/2026 · Último APK entregado: 0.18.1+29, revisión `d41b711`.**

Este es el punto de entrada para continuar en un chat nuevo. El objetivo es mejorar la diversión y progresión de un incremental móvil con físicas, manteniendo una participación manual importante. El usuario prefiere avances concretos y documentación que sirva de fuente de verdad; no necesita un repaso de commits.

## Leer primero

1. [Estado actual](estado-actual.md): reglas implementadas, UI, debug, último APK y límites de verificación.
2. [Cambios futuros](cambios-futuros-arbol-mejoras.md): detalle de cada propuesta, dependencias y preguntas abiertas.
3. [Árbol vigente](arbol-de-mejoras.md) y [balance.csv](balance.csv): mapa actual y fuente de cifras/requisitos.

## Estado que hay que conservar

- **Posición vigente: hoyo al 22 % en (180,123.2), generador (180,480), emisión hacia arriba.** Sustituye el 74 % de la entrega anterior.
- Ajuste posterior al APK de `046ebb0`: agujero en (180, 50), generador en (180, 480), sin leyenda del jardín en el tablero ni «Tu jardín te espera» en pausa. Se ha seguido la última indicación del usuario de subir el agujero y bajar el generador; comprobar las posiciones jugando en móvil.
- **15 s de producción sin fase final de recogida**; una sola barra verde, con segundos pequeños encima a la derecha y sin nombres de fase. El cierre liquida automáticamente lo pendiente. No hay temporizador en compras.
- Generación base 1,5 bolas/s; límite de 200 bolas. Mano base de una bola, capacidad mejorable hasta seis y fuerza alta desde el inicio sin mejoras. Escoba física desbloqueable, anchura/V y robot que empuja bolas.
- Capturar registra dinero garantizado y alimentación. Monedas decorativas al monedero tras ~1 s; sin recogida manual ni pérdidas. El control de bolas es independiente.
- Monedas decorativas sin cifras, colores por rango; UI con icono, sin prefijo dólar. Resumen de cobro automático íntegro.
- Recompensa global actual **1 → 2/3/5/8/13**; todavía no existen tiers individuales. Doradas con probabilidad 1 % y recompensa ×10.
- Racha comprable tras Mano I por 40: ventana 1 s, quinta captura ×2, décima ×3, sin retroactividad. También cuentan capturas asistidas provisionalmente. Indicador desde la primera captura, multiplicador y barra temporal; no explicar umbrales en UI.
- Árbol de 55 nodos y 22 tipos, descubrimiento progresivo y seis colores por categoría. Primera mejora de mano cuesta 13. Barrido, Área, Imán y Atracción retirados sin reembolso; Robot solo requiere Escoba ancha II, confirmado por el usuario.
- Árbol sin título, botón visible de atrás ni botones de zoom; ficha solo al tocar, cantidades en verde y compra manteniendo el botón 1 s. Resultados → Tienda → Comenzar día. No mostrar números de día al jugador.
- **Debug:** botón DEBUG, arriba a la izquierda del árbol. Sustituye la pulsación de 3 s porque el usuario reportó que no funcionaba en móvil. Mapa completo/compras gratis/comprar todo o Vista del jugador; reinicio y monedas de prueba. Progreso temporal, sin sobrescribir la partida normal. Para ver el inicio como jugador, reiniciar prueba y activar esa vista.

Incluido en el APK de `4d815d9`: informes temporales de las últimas
20 jornadas debug con emisiones, capturas/doradas, pico de combo y monedas
generadas/cobradas/perdidas; se pueden copiar desde el panel. La petición inicial fue recorrer las mejoras futuras y añadir
las nuevas bolas como mejoras probables desde debug; después el usuario priorizó
Racha comprable, dos especiales recargables y control de escoba con dos puntos. Se ha propuesto aislar
prototipos configurables en debug, probar ambas variantes de bomba y una tabla
provisional de tiers 1/2/3/5/8. **Son propuestas pendientes de respuesta, no
reglas aprobadas.** También sigue pendiente la interacción dorada → tier máximo.

Incluidos en el APK: dos especiales comprables —Captura total y Aceleración—,
con carga automática durante producción y mejoras de recarga, potencia y duración.
Las cifras son **provisionales de prueba**, no un balance definitivo; ver estado
actual y CSV. Escoba con dos dedos: uno traslada, dos orientan; soltar uno conserva
el otro agarre. Guardado v12 / balance v18, con balances anteriores congelados para jornadas
antiguas. Verificación CI de la entrega: 392 pruebas y análisis
sin avisos, incluidos gestos de dos dedos, habilidades, guardado y pantalla pequeña.

## M01 implementado en la última entrega

Cuatro paredes con rebote base ×0,40 y mejora permanente I/II/III ×1,10/1,35/1,60; velocidad máxima 380 u/s. Línea elástica y ondas al impactar, sin cambiar monedas ni congelación final. Compras persistentes, aplicadas desde la jornada siguiente; jornadas v8 conservadas. Para probar: Tienda → DEBUG → comprar Paredes rebotadoras con requisitos → Comenzar día de prueba.

Multiplicadores, límite y costes 40/100/220 con Mano I son **provisionales**, pendientes de validación de balance. [Implementación y pruebas](m01-paredes-rebotadoras.md). Sigue pendiente la compatibilidad de firma con APK anteriores descrita en [G01](g01-feed-the-hole.md); la pipeline estándar verifica la firma de esta APK, sin acreditar actualización sobre la anterior. No desinstalar para resolverlo si se quiere conservar su progreso.

## M02 · prototipo entregado

APK 0.8.0+16 entregado por la pipeline habitual. Bate físico aparte de la escoba, tres niveles de
potencia activa y control de uno/dos dedos compartido. Velocidad relativa y giro,
rebote pasivo constante, contacto persistente sin bonificaciones repetidas y cap
380 u/s. Monedas y activación de especiales conservadas. Compra y pose persistentes,
recogida congelada y DEBUG aislado. Nueva preferencia Vibración; destellos y sonido
respetan ajustes, con respuesta agrupada. JSON v7, balance v10 con v9 congelado.
Precios 60/120/240, Mano I y potencia ×1/×1,35/×1,70 son **provisionales**.
[Estado M02 y guía de prueba](m02-bate-beisbol.md). No implementar otras piezas
ni nuevas bolas como parte de esta tarea.

## S01 · Alimentación y cuotas

Cada captura alimenta con toda su recompensa, incluidos racha y dorada ×10.
**Captura total sigue la misma regla**, por decisión expresa del usuario.
No hace falta recoger las monedas y alimentar no descuenta dinero.
Anillo alrededor del hoyo y resumen entre jornadas; períodos de cinco jornadas,
sin cierre anticipado al cumplir; P01 añade las burbujas de estrellas. Al empezar el siguiente período
se reinicia la alimentación y aumenta la cuota.

El usuario aprobó **cuotas provisionales también en juego normal**: objetivo
inicial 10 y aumento 10 por período, centralizados en `balance.csv`. Son valores
para probar, pendientes de BAL01, no balance definitivo. S03 activa ahora la derrota al incumplir, también en juego normal por autorización
expresa del usuario; los valores continúan provisionales hasta BAL01.
DEBUG permite simular un fallo reversible sin modificar la partida real.
JSON v8 / balance v14, con v13 congelado y sin inventar capturas históricas.
[Contrato y pruebas](s01-alimentacion-cuotas.md).

## M03 · Generador lanzador

Prototipo 0.11.0+19: nuevo emisor de Producción, independiente del principal,
frecuencia propia y potencia fija. Un/dos dedos, disparo agarrado, franja inferior
completa y línea roja. Presión vectorial de contactos, tres esfuerzos máximos
insuficientes, desplazamiento lento sin giro/recoil; obstrucciones consumen
intento sin bolas superpuestas ni ráfagas. Pose entre días/reinicios, reloj/RNG
guardados y DEBUG aislado. JSON v7 / balance v13 con v12 congelado, 69 nodos y
26 tipos. Generador II, costes, 280 u/s, intervalos y resistencia son **provisionales**.
No añadir otros cañones, bolas ni mejoras de fuerza. [Guía y valores](m03-generador-lanzador.md).

## E02 · Agujero negro

Prototipo 0.10.0+18: comprobaciones independientes 5 % cada 3 s, varios objetos
sin sensores, 3–6 pulsaciones y succión ampliada sobre bolas libres. Captura,
monedas y herramientas conservadas. Duración hasta 10 s, otra activación
restablece tiempo sin acumular potencia. **Usuario decidió retirar también los
objetos sin romper al terminar producción**, como Gravedad. Pausa/restore sin
repetir activación, JSON v7 / balance v12 con v11 congelado. DEBUG fuerza 1–3
objetos temporales. Intervalo/radio/fuerza/curva/deriva/audio/estética siguen
provisionales. [Guía, parámetros y pruebas](e02-agujero-negro.md).

## E01 · Gravedad entregada

APK 0.9.0+17 generado por la pipeline habitual. 5 % por jornada compatible, máximo un objeto,
3–6 pulsaciones y hasta 10 s de producción inclinando el móvil. La detección Android
exige una lectura real (gravedad, o acelerómetro filtrado); sin sensores no
aparece en juego normal. Bolas y escoba/bate libres reciben fuerza gradual;
agarres y monedas no. Se conservan estado y tiempo al pausar/restaurar, sin nuevo
sorteo ni activación; cierre limpia todo. RNG separado del emisor de bolas.
JSON v7 / balance v11 con v10 congelado. DEBUG → Gravedad permite forzar y simular
sin alterar guardado real. Apariencia y física provisionales; discutir daño por
bolas, otros eventos simultáneos y balance futuro antes de cerrar esas reglas.
[Implementación y protocolo de prueba](e01-gravedad.md).

## Próximas mejoras y decisiones abiertas

| Tema | Qué se quiere | Qué falta antes de programar |
| --- | --- | --- |
| CF-16 · Tiers individuales | Valor propio por bola y reemplazo de Valor I–V | Número, valores, colores, probabilidades, nueva rama y migración de compras |
| CF-17 · Potenciadora | Elevar tiers por contacto estratégico | Depende de CF-16; cargas, consumo, contactos, objetivos y límites |
| CF-18 · Combos | Revisar la implementación y posibles mejoras | Probar ventana/multiplicadores; confirmar capturas asistidas y posibles ampliaciones del árbol; desbloqueo por compra ya implementado |
| CF-19 · Tres habilidades aleatorias | Elegir una tras noches/hitos, además del árbol | Frecuencia, catálogo, rarezas, duración, acumulación y guardado |
| CF-20 · Pinball | Flippers manuales y bumpers físicos | Controles móviles, colocación, fuerza, tamaño y límites de contacto |
| CF-21 · Fábrica configurable | Barreras, deflectores, aros, núcleos, aspas, cañones o ráfagas | Elegir piezas y concretar controles, anclajes, capacidades, requisitos y economía |
| CF-22 · Duplicadora | Crear una copia al contactar con otra bola | Objetivos, estados copiados, cargas/cadenas, recompensa y límite de 200 |
| CF-23 · Bomba o impulso | Cuenta atrás roja 3, 2, 1 tras colisión | **Elegir** destrucción o impulso; radio, efectos, cadenas y guardado |
| CF-24 · Controles | Lanzamiento mejorable, abanico, tirachinas o escoba cargada | Diferencia respecto al gesto actual, gestos, límites y comodidad |

**Reglas futuras de doradas que sí están acordadas:** ×10 del valor de su tier; el tier máximo no puede ser dorado ni generarse dorado. **No se ha decidido** qué sucede cuando una bola ya dorada intenta evolucionar al tier máximo. Discutirlo; no escoger automáticamente entre bloquear la evolución, quitar el dorado u otra solución.

La duplicadora y la bomba/impulso siguen siendo ideas para planificar. El usuario pidió inicialmente no implementar esas bolas todavía; la petición posterior de implementar lo posible no cerró sus reglas pendientes. No presentarlas como hechas ni inventar reglas definitivas.

Los combos ya existen: su pendiente es revisar balance y evolución, no implementarlos de nuevo. Los cambios de UI/monedas/agarre/timers/debug y las posiciones del tablero ya están hechos: no volver a listarlos como pendientes.

## Qué conviene resolver a continuación

Sugerencia, no nueva decisión del usuario: comprobar el último APK en móvil y observar el ritmo con el agujero arriba; después concretar CF-16 antes de CF-17. Registrar capturas, monedas cobradas/perdidas y días entre compras antes de reajustar economía. Los mecanismos y habilidades necesitan diseño separado para no complicar los controles.

No se ha registrado aceptación física del último APK. El usuario reportó antes que el «modo dibujo» no funcionaba, tratado aquí como debug del árbol. Las pruebas automáticas pasan, pero no consta reproducción ni confirmación manual de que el último APK resuelva ese reporte.

## Última entrega y comprobaciones

[Descargar APK 0.18.1+29 (ZIP con APK y SHA-256)](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557/artifacts/12569447730). Descomprimir: contiene `feed-the-hole-debug.apk`. Retención limitada de GitHub; regenerar si caduca.

392 pruebas, formato, análisis, compilación Android y firma correctos en la [pipeline de entrega](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557). Sin prueba en teléfono físico. El último código entregado está en `build/apk-0.6.0+13`; no asumir que `main` lo contiene. La pipeline Android es manual; el entorno local usado no tiene Android SDK.

## Acceso a GitHub desde Codex Cloud (20/10/2026)

El commit `046ebb06aa28b4662f5ca1d8635f4bde0d9a4101` se publicó sin force push
en `build/apk-0.6.0+13`. Los primeros intentos desde el sandbox devolvían
`Failed to connect to proxy port 8080` y `gh auth status` indicaba token inválido.
La solución comprobada fue ejecutar los comandos de red con
`sandbox_permissions: "with_additional_permissions"` y
`additional_permissions: {"network": {"enabled": true}}` en `exec_command`.
Con esa configuración funcionaron `git ls-remote`, `git push`, `gh auth status`
y el lanzamiento del workflow manual. No hubo que cambiar el proxy, las
credenciales ni la política del environment. No interpretar esos errores desde
un comando sin acceso de red como prueba de credenciales caducadas.

Para el APK, usar `.github/workflows/flutter-manual.yml` sobre la rama publicada;
GitHub Actions instala Flutter y Android SDK. Flutter encontrado en `/tmp/flutter`
no estaba en el PATH de esta tarea y no había Android SDK local. No instalar un
SDK completo solo para suplir la pipeline. Conservar los commits y comprobar el
SHA remoto antes de publicar; no usar reset, clean ni force push para reparar
conectividad.

La [pipeline 39436411074](https://github.com/migdlp/incremental_hole_game/actions/runs/39436411074)
terminó correctamente sobre ese SHA: formato, análisis, pruebas, APK y firma v2.
[Descargar el APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39436411074/artifacts/12272966859).
La reparación de conectividad no necesitó cambios en el código ni en las
credenciales; `046ebb0` está publicado.

## Cómo trabajar al retomar

- Distinguir siempre implementación vigente, dirección de diseño y reglas pendientes. Leer este documento no es una orden de implementar todo el brainstorm.
- Atender la siguiente petición concreta del usuario. Ante una decisión expresamente abierta, proponer reglas y discutirla antes de fijarla.
- Usar `balance.csv` para cifras/requisitos. Respetar compras y guardados; no borrar progreso para adaptar la economía.
- Mantener física y participación manual: las máquinas ayudan, no convierten el juego en totalmente pasivo. El dinero normal se cobra automáticamente tras capturar; las estrellas exigen romper burbujas.
- Al terminar una tarea, quitarla de cambios futuros y actualizar estado/contexto. No acumular listas de cambios ya hechos entre los pendientes.
- Documentos históricos pueden contener tiempos, versiones y reglas reemplazados. Las referencias vigentes son estado actual, cambios futuros, CSV y código.

## Mensaje para pegar en un chat nuevo

```text
Continúa el proyecto Feed the Hole del repo
migdlp/incremental_hole_game. Lee primero docs/relevo-contexto.md,
docs/estado-actual.md y docs/cambios-futuros-arbol-mejoras.md.
Me interesa especialmente el estado jugable y las mejoras futuras,
no reconstruir el historial de commits. El último APK es 0.18.1+29:
agujero arriba, generador abajo, producción de 15 s con cobro automático y sin recogida final, alimentación con racha y cuotas provisionales con derrota, tienda de prestigio y nodo voluntario confirmado, generador lanzador, eventos Agujero negro y Gravedad por inclinación, paredes rebotadoras, bate de tres potencias, racha comprable, especiales, escoba de dos dedos y debug por botón.
No des por implementados los tiers ni las bolas especiales, ni cierres
las decisiones abiertas sin discutirlas. Después continúa con mi
siguiente petición concreta.
```

## Última simplificación de interfaz

El saldo total y la pausa negra están dentro del tablero. Se eliminan números
de día, instrucciones de juego y la leyenda del generador. La interfaz usa
Tienda y Comenzar día. Feedback visual en ajustes normales empieza desactivado,
se guarda y solo oculta/muestra las marcas de pulsación/área/agarre. La pausa
muestra Juego pausado con icono de pausa, ajustes y Continuar. Ver estado actual.

## G01 — Feed the Hole

La marca comercial pasa a Feed the Hole en el build 0.6.0+14. No renombrar
`GardenApp`, `GardenGame`, el paquete Dart, el repositorio ni el identificador
Android por motivos cosméticos. Se mantienen `progress.json`, su copia, el
guardado v7 y todas las migraciones. Iconos, gráficos y reglas se conservan.
La actualización sobre APK anteriores requiere además conservar la firma;
verificarla contra la entrega anterior antes de afirmar compatibilidad.

**Resultado G01:** código de marca publicado en `fd3d8f2`; el APK compila y su
nombre/paquete son correctos. La comparación con la última APK detectó firmas
diferentes y detuvo la publicación. Falta localizar y reutilizar el keystore
original para cumplir la actualización conservando datos.
[Diagnóstico y evidencia de G01](g01-feed-the-hole.md).

**Entrega posterior G01 (21/10/2026):** APK Feed the Hole `0.6.0+14` generada
con la pipeline habitual sobre `4f100fc`, a petición del usuario.
[Descarga](https://github.com/migdlp/incremental_hole_game/actions/runs/39557666293/artifacts/12326019753).
Pasaron formato, análisis, 154 pruebas, compilación y validación del nombre,
paquete y firma del binario. Se omitió la comparación de actualización con la
APK anterior: el conflicto de firma previamente confirmado sigue pendiente.
No presentar esta entrega como actualización que conserve el progreso instalado.

## M01 — paredes rebotadoras

Implementadas en 0.7.0+15: rebote base ×0,40 y rama Paredes rebotadoras I–III
(×1,10/×1,35/×1,60), con límite configurable inicial de 380 u/s. Precios
40/100/220 y Mano I son provisionales de prueba, no aprobados. Efectos elásticos
y ondas independientes de la física; monedas y recogida conservan sus reglas.
Guardado v7, balance v9 y balance v8 congelado para jornadas anteriores.
[Detalle y pruebas M01](m01-paredes-rebotadoras.md). No dar por implementadas
las otras piezas de pinball ni las nuevas bolas especiales.
