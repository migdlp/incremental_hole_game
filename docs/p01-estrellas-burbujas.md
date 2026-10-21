# P01 — Estrellas de prestigio y burbujas físicas

Prototipo **0.15.0+23**. Requisitos funcionales implementados; BAL01 y validación
física en Android pendientes. P02 sigue siendo otra tarea: no se inventa un
catálogo de compras permanentes.

## Reglas vigentes

Completar la cuota registra inmediatamente una recompensa identificada por
partida, período e identidad de burbuja. Cada período concede una sola vez.
La primera burbuja sale del centro del hoyo; las demás salen progresivamente
cuando hay espacio. La alimentación sigue contando toda la recompensa normal,
dorada y con racha, incluida Captura total. Las monedas automáticas son independientes.

Las burbujas flotan, chocan con bolas, paredes, escoba, bate y cuerpo del lanzador.
Se agarran directamente y se lanzan con la velocidad del gesto. Las herramientas
conservan prioridad cuando se toca su cuerpo; una burbuja agarrada impide agarrar
simultáneamente una bola o un segundo objeto. Dos dedos siguen siendo un control
de herramientas, no duplican agarres de burbuja.

El diámetro inicial es dos veces el de una bola, también en las colisiones.
Los impactos suaves rebotan; solo un impacto suficientemente fuerte contra una
pared o herramienta rompe la burbuja. Las herramientas incluyen su velocidad
de traslación y giro en la velocidad relativa del impacto. Las bolas pueden
impulsarla, pero no romperla directamente. El rebote de burbujas es propio y no
hereda los multiplicadores M01. Todas las velocidades se limitan al máximo técnico.

Una burbuja que vuelve al hoyo sale de nuevo con **la misma identidad y valor**,
con 0,8 s de protección frente a otra expulsión. No produce dinero, alimentación,
racha, emisiones ni activaciones destinadas a bolas normales. Captura total
solo captura las bolas ordinarias; no cobra ni elimina burbujas.

Al romperla se registra el cobro permanente una sola vez, se dibuja una rotura
breve y una estrella vuela al contador dentro del tablero. El saldo ya está
reconocido aunque la animación no pueda mostrarse o la aplicación se interrumpa.
El sonido de sistema de rotura respeta silencio y comparte limitación de 150 ms
con los avisos de monedas; la estética y audio definitivos quedan por calibrar.

## Jornadas y fin de partida

Al cerrar la jornada solo se retiran los cuerpos físicos. Todas las recompensas
pendientes siguen registradas y se expulsan otra vez desde el hoyo en la siguiente
producción. Conservar categoría e importe evita recalcular un premio por cambiar
los parámetros. Las burbujas cobradas no reaparecen.

**Decisión P01 aprobada:** derrota o prestigio voluntario descartan todas las
burbujas pendientes. Nunca se convierten automáticamente en estrellas. Las
estrellas cobradas, compras y descubrimientos permanentes se conservan. Esto
sustituye explícitamente la conservación opaca provisional que dejó S03.

## Contabilidad y guardado

JSON **v11**, balance **v17**, con v16 congelado para jornadas antiguas.
`MetaProgress.starLedger` guarda último período premiado, siguiente identidad y
pendientes con identidad/categoría/valor. Premiar una cuota y cobrar una burbuja
incrementan la revisión permanente; repetir las operaciones no duplica pagos.
Los cuerpos guardan posición, velocidad y protección del hoyo por separado en
la jornada activa, además de su configuración física congelada.

El checkpoint permanente se escribe antes que el guardado normal, con dos copias
actuales. Un guardado anterior al cobro no puede restaurar esa burbuja por encima
de un checkpoint más reciente. Las animaciones no se necesitan para recuperar
el dinero. Restaurar una jornada pausa su simulación. Un fallo de disco se muestra
y permite reintentar conservando el saldo en memoria, igual que S03.

Se admiten guardados v1–v10. No se reconstruyen recompensas de períodos históricos:
una cuota ya cumplida en el período activo se reconoce una sola vez al reanudar
producción. Los datos opacos antiguos se conservan mientras la partida siga
activa y se descartan al terminarla; no se interpretan como estrellas cobradas.

## Parámetros provisionales y DEBUG

Fuente central: `balance.csv`, validados por `StarConfig`. Valores **de prueba**:

| Parámetro | Inicial |
| --- | --- |
| Burbujas por cuota | 1 |
| Categorías | 3 |
| Valor inicial y crecimiento | 1 estrella; ×5 por categoría |
| Introducción de categoría | Cada 2 períodos, hasta el límite configurado |
| Diámetro respecto a bola | ×2 |
| Crecimiento por categoría | ×1,12 |
| Expulsión | 100 u/s |
| Flotación / amortiguación | 12 u/s² hacia arriba / 0,3 s⁻¹ |
| Rebote propio | ×0,65 |
| Umbral relativo de rotura | 110 u/s |
| Cuerpos activos | 8 |
| Intervalo de reintroducción | 0,4 s |
| Color base | Matiz 45°, separación de 100° entre categorías |

No son cantidades, colores ni límites definitivos aprobados por BAL01.
Todos se pueden ajustar entre jornadas desde **Tienda → DEBUG → Estrellas y
burbujas · P01**. Editar un campo válido aplica el valor; comenzar día usa esa
configuración. «Añadir recompensa de prueba» permite empezar con pendientes sin
necesitar capturar primero. Para repetir una cuota desde cero, reiniciar el período
de alimentación o la prueba. Salir de DEBUG recupera íntegramente la partida real,
incluidas estrellas y pendientes; no se escribe el ensayo en sus guardados.

**Interacciones pendientes de decisión:** Gravedad y Agujero negro no se aplican
a burbujas en normal por ahora. Hay dos interruptores experimentales independientes
en DEBUG para compararlas, sin fijar su diseño final; los agarres siempre quedan
bajo control del jugador. Ventilador todavía no existe y no se añade en P01.

## Rendimiento y pruebas

El límite configurable de cuerpos activos difiere de la cantidad de recompensas
pendientes: saturar el tablero no borra premios ni los cobra. Solo se reintroduce
una burbuja por intervalo y si la salida está despejada de otras burbujas.
El pool reutilizable de roturas/vuelos tiene 24 entradas; saturarlo omite únicamente
ese dibujo. No hay colas de animaciones ilimitadas. La física trabaja en los
subpasos existentes y las burbujas no entran en la cuadrícula de bolas ni en sus
contadores. El render no simula ni hace compras o cobros.

Pruebas automáticas: cuota única, tamaños, cobro idempotente, paredes/esquinas,
contacto continuo, choques suaves/fuertes, empuje por bolas, escoba/bate y giro,
agarre exclusivo/lanzamiento, retorno al hoyo, congelación, reaparición entre días,
pérdida al terminar partida, checkpoint por encima de copias antiguas, fallo de
disco/reintento, restauración, saturación, 200 bolas con 24 cuerpos y 100 pendientes,
interacciones experimentales y aislamiento DEBUG.

Pendiente **medir en Android físico en profile**: CPU y raster/GPU por fotograma,
frames perdidos, memoria/asignaciones, choques masivos y Captura total. Usar
DevTools y los contadores de frames del panel de rendimiento, comparando 1/8/16/24
burbujas y el mismo número de bolas. Las pruebas de límites no certifican 60 FPS,
el umbral agradable para los dedos ni que se rompan naturalmente con la frecuencia
deseada. No cerrar BAL01 sin esas mediciones y pruebas de juego.

## Entrega verificada

Código publicado: `0ac69d0` en `build/apk-0.6.0+13`; `046ebb0` sigue siendo
antepasado. La [pipeline 39686480457](https://github.com/migdlp/incremental_hole_game/actions/runs/39686480457)
completó formato, análisis sin avisos, **354 pruebas**, compilación Android y
verificación de firma. [APK 0.15.0+23 y SHA-256 en ZIP](https://github.com/migdlp/incremental_hole_game/actions/runs/39686480457/artifacts/12386228786).
Paquete Android conservado: `com.migdlp.incremental_hole_game`; nombre Feed the Hole.

No se ha probado en Android físico. La firma de esta APK se verifica, pero sigue
pendiente reutilizar una identidad de firma estable para acreditar actualización
sobre instalaciones anteriores conservando sus datos. No desinstalar para sortear
ese conflicto si se necesita conservar el progreso.
