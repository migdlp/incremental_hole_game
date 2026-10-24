# Feed the Hole

## AJ-007 · Feedback audiovisual (0.19.0+30)

Audio offline centralizado con plops variables, absorción y rodadura compartidas,
cascadas musicales de monedas y cristal/estrellas. Háptica agrupada independiente,
volumen persistente y controles DEBUG. Cada bola se hunde bajo el borde del hoyo;
reacciones agrupadas y compatibles con su crecimiento. Sin cambios económicos.
Escucha, vibración y rendimiento en Android físico pendientes de calibración.
[Arquitectura, recursos, pruebas y límites](docs/aj007-feedback-audiovisual.md).


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
Incluye el rediseño AJ-008A. [Detalles y mediciones](docs/bug001-lluvia-monedas.md).

Validado: formato, análisis y **392 pruebas**, compilación Android y firma.
Código compilado `d41b711`; [APK 0.18.1+29 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557/artifacts/12569447730). Incluye AJ-008A y BUG-001.

## AJ-008A · Resultados animados (0.18.0+28)

Nuevo modal con monedas por denominación hacia el monedero real, seguido del
progreso del hoyo; Tienda aparece al finalizar. Saltos por bloque, movimiento
reducido y scroll móvil. Contabilidad de presentación separada del cobro real.
Paleta 1/10/50/100/500: bronce/plata/oro/verde/rojo. Sin cambios económicos.
Mockup y vídeo no adjuntos: fidelidad visual pendiente de cotejar; pruebas en
Android físico pendientes. [Detalles, archivos y validación](docs/aj008a-resultados.md).

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
no se añade una rama de nivel del agujero. [Estado y compatibilidad](docs/ajustes-version-actual.md).

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
P02 y BAL01 continúan pendientes. [Contrato y pruebas](docs/p01-estrellas-burbujas.md).

**S03 · 0.14.0+22:** [Prestigio y metaprogresión](docs/s03-prestigio-metaprogresion.md).
Derrota por cuota también en normal, tienda y reinicio; nodo grande girado 45° con
confirmación. Datos permanentes protegidos contra copias normales antiguas.
P01 ya aporta estrellas; P02 debe aportar catálogo y efectos. Balance provisional.

**C01 · 0.13.0+21:** [Cobro automático](docs/c01-cobro-automatico.md), monedas decorativas
y cierre directo sin recogida. Compras retiradas sin reembolso, según autorización
del usuario. Pool y presupuestos provisionales; medición Android físico pendiente.

**G01:** Feed the Hole `0.6.0+14` ya está disponible mediante la pipeline habitual.
La comprobación previa detectó una firma distinta de la APK anterior; esta
entrega no acredita actualización conservando su progreso. No desinstalar la
instalación anterior para resolver el conflicto de firma.
[Estado y comprobaciones de G01](docs/g01-feed-the-hole.md).

Prototipo jugable de un incremental móvil en Flutter + Flame. El jugador dirige bolas hacia un agujero, cobra automáticamente sus recompensas y compra mejoras permanentes entre jornadas. **Código y último APK entregado: 0.18.1+29, revisión `d41b711`**, 24/10/2026.

**Para continuar en otro chat:** leer [relevo de contexto](docs/relevo-contexto.md), [estado actual](docs/estado-actual.md) y [cambios futuros](docs/cambios-futuros-arbol-mejoras.md). El primero resume el estado jugable y las decisiones abiertas; el último contiene únicamente pendientes. [Índice de documentación](docs/README.md).

**[Descargar APK 0.18.1+29 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557/artifacts/12569447730)** · [Pipeline correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/40118367557): formato, análisis, **392 pruebas**, compilación Android y firma. Descomprimir el ZIP: contiene `feed-the-hole-debug.apk` y su SHA-256. Los artefactos tienen retención limitada.

La entrega incluye [M01 · Paredes rebotadoras](docs/m01-paredes-rebotadoras.md): tres niveles permanentes, ondas elásticas y límite de velocidad, con balance provisional. Conserva **interfaz de juego simplificada, una sola barra de tiempo, saldo y pausa dentro del tablero y feedback visual opcional apagado por defecto**, además de racha comprable, especiales y escoba de dos dedos. La interfaz usa «Tienda» y «Comenzar día», sin mostrar números de día. Debug se abre con el botón DEBUG de arriba a la izquierda del árbol. La validación en Android físico y el ajuste de balance jugando siguen pendientes.

**M02 incluido (0.8.0+16):** bate independiente, tres potencias, gestos de uno/dos
dedos, impulso por movimiento y giro, y feedback configurable. Balance provisional. [Cómo probarlo en DEBUG](docs/m02-bate-beisbol.md).

**E01 incluido (0.9.0+17):** evento Gravedad por inclinación del teléfono, objeto
aleatorio rompible con 3–6 toques, duración limitada y prueba forzada desde DEBUG.
Pendiente de validación física. [Sensores y pruebas](docs/e01-gravedad.md).

**E02 incluido (0.10.0+18):** [Agujero negro](docs/e02-agujero-negro.md),
5 % por comprobación periódica, varios objetos rompibles y succión ampliada hasta
10 s sin ampliar captura. DEBUG permite forzar 1–3 objetos. Parámetros provisionales.

**M03 incluido (0.11.0+19):** [Generador lanzador](docs/m03-generador-lanzador.md),
segundo emisor orientable, frecuencia independiente, presión física y pose
persistente. Desbloqueo y parámetros provisionales; disponible en DEBUG.

**S01 (0.12.0+20):** [Alimentación y cuotas](docs/s01-alimentacion-cuotas.md).
Todas las capturas cuentan con racha y doradas, también Captura total, sin
necesidad de recoger monedas. Anillo y períodos de cinco jornadas; cuotas
provisionales en juego normal; S03 activa derrota al incumplir por autorización
expresa del usuario. Cantidades definitivas pendientes de BAL01.
DEBUG permite simular el fallo sin alterar la partida real.

El último código entregado está en `build/apk-0.6.0+13`; no asumir que está integrado en `main`. Los antecedentes de entregas se conservan en el [historial](CHANGELOG.md).

## Ejecutar

Flutter **3.35.7 estable**, Dart **3.9.2**. La versión está fijada en `.fvmrc` y las dependencias resueltas están en `pubspec.lock` (Flame 1.35.1).

```bash
flutter pub get
flutter run -d <dispositivo-android>
# Alternativa para revisar interacción desde el navegador:
flutter run -d chrome
```

En este entorno cloud: `source /workspace/dev-env/env.sh`. Para servir una compilación web local:

```bash
flutter build web --no-web-resources-cdn
python3 -m http.server 8123 --directory build/web
```

## Lo que ya funciona

- Tablero lógico 360 × 560, generador, fricción, colisiones y captura por el hoyo. Agarre individual inicial, capacidad mejorable a 2/3/4/5/6 bolas y lanzamiento manual según la velocidad final del gesto e inercia propia para las bolas adicionales. Solo una mano que ya lleva una bola atrae las cercanas, con peso y retraso; un tirón fuerte puede soltarlas. Cada bola emitida tiene un 1 % de probabilidad de ser dorada y valer ×10; con el valor base genera $10.
- Escoba física disponible solo tras comprarla, perpendicular al arrastre, giro suavizado, anchura mejorable y escoba en V; selector de herramientas compradas.
- Monedas decorativas en pool: salida del hoyo tras ~1 s y vuelo curvo al monedero. Cobro completo sin tocar, agrupar u omitir animaciones no cambia los ingresos. Cierre liquida pendientes.
- Día inicial de **15 segundos de producción, sin fase final de recogida**. **1,5 bolas por segundo** (una cada ⅔ s); pausa y taller sin temporizador. El ingreso completo se banca una sola vez al cierre.
- Árbol progresivo con conexiones, arrastre, zoom, ficha de efecto y compra manteniendo pulsado 1 segundo; las compras revelan nuevos caminos.
- 22 tipos y 55 nodos de mejora (la primera del árbol permite llevar dos bolas), con costes provisionales y requisitos del [balance actual](docs/balance.csv), robot que empuja bolas y Prestigio voluntario con confirmación.
- Resultados y estadísticas en un pop-up sobre el juego detenido, con un único botón para ir al árbol en su pantalla independiente. Desde el árbol se pulsa «Comenzar día»; ahorro y compras persistentes.
- Guardado JSON v13 con compatibilidad de jornadas anteriores, herramienta seleccionada, escrituras en orden, copia anterior válida y restauración pausada de jornadas interrumpidas. En Android se usa archivo temporal y reemplazo; en web, almacenamiento del navegador.
- Pausa al pasar a segundo plano y opción de silenciar los sonidos del sistema.

La tabla `docs/balance.csv` se empaqueta como recurso y se valida al cargar: es la fuente editable del balance actual. Las jornadas antiguas conservan su configuración hasta terminar; el siguiente día usa el balance nuevo. La noche descarta también cualquier bola agarrada.

**[Descargar APK anterior 0.2.1+3 y SHA-256](https://github.com/migdlp/incremental_hole_game/actions/runs/39141075339/artifacts/12142120297)**. Descomprime el ZIP e instala el APK; requiere sesión en GitHub. Artefacto disponible hasta el 1 de noviembre de 2026; después puede regenerarse con la [pipeline manual](docs/ci.md).

## Validar

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
# Con un teléfono Android conectado:
adb install -r build/app/outputs/flutter-apk/app-debug.apk
flutter build web --no-web-resources-cdn
```

La entrega vigente pasa **392 pruebas**, análisis y compilación Android en la pipeline enlazada arriba. Los resultados de entregas anteriores se conservan en el [registro de validación](docs/validacion-prototipo.md).

La [pipeline manual](docs/ci.md) ejecuta doctor, dependencias, formato, análisis y pruebas, compila el APK de depuración y lo guarda como artefacto descargable junto con su SHA-256. Se activa en **Actions → Flutter - APK manual → Run workflow**; no se dispara con cada push.

## Límites de esta entrega

Es una primera implementación jugable, no una validación final del MVP. Falta probar en un móvil físico el agarre, los lanzamientos, el giro de ambas escobas, el balance y los 60 FPS bajo carga. Los precios siguen provisionales; el generador emite 1,5 bolas/s durante los quince segundos iniciales de producción, sujeto al espacio de salida. No hay dispositivo de referencia acordado. Los sonidos son clics del sistema con opción de silencio; no hay efectos de audio propios ni control independiente de volumen. El taller abre un árbol progresivo; su revisión táctil y el ajuste final de precios siguen pendientes. Ver [cómo se explora y compra](docs/arbol-de-mejoras.md).

El juego mantiene su progreso localmente y no genera ingresos mientras está cerrado. Se solicitan puntos de control cada cinco segundos de avance activo. Un cierre forzado puede perder progreso desde la última escritura correcta, y la recuperación de una copia puede retroceder más; al restaurar no se simula el tiempo cerrado. Si falla el guardado se avisa y se permite reintentarlo. Si el archivo y su copia están dañados, se pide una acción explícita antes de comenzar una partida nueva. La copia de seguridad puede recuperar un estado anterior.

Gráficos dibujados mediante primitivas, iconos Material/Cupertino incluidos por Flutter y tipografía predeterminada de Flutter; sin arte externo ni descargas de fuentes añadidas por la aplicación. Los iconos de instalación son todavía los de la plantilla de Flutter.

Ver [cómo está implementado](docs/implementacion.md), el [formato de guardado](docs/persistencia.md), las [decisiones técnicas](docs/decisiones.md), el [registro de validación](docs/validacion-prototipo.md) y el [historial de cambios](CHANGELOG.md).
