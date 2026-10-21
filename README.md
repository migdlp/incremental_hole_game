# Feed the Hole

**G01:** Feed the Hole `0.6.0+14` ya está disponible mediante la pipeline habitual.
La comprobación previa detectó una firma distinta de la APK anterior; esta
entrega no acredita actualización conservando su progreso. No desinstalar la
instalación anterior para resolver el conflicto de firma.
[Estado y comprobaciones de G01](docs/g01-feed-the-hole.md).

Prototipo jugable de un incremental móvil en Flutter + Flame. El jugador dirige bolas hacia un agujero, recoge sus monedas y compra mejoras permanentes entre jornadas. **Código y último APK entregado: 0.9.0+17, revisión `172872a`**, 21/10/2026.

**Para continuar en otro chat:** leer [relevo de contexto](docs/relevo-contexto.md), [estado actual](docs/estado-actual.md) y [cambios futuros](docs/cambios-futuros-arbol-mejoras.md). El primero resume el estado jugable y las decisiones abiertas; el último contiene únicamente pendientes. [Índice de documentación](docs/README.md).

**[Descargar APK 0.9.0+17 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39634096764/artifacts/12361665066)** · [Pipeline correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/39634096764): formato, análisis, **211 pruebas**, compilación Android y firma. Descomprimir el ZIP: contiene `feed-the-hole-debug.apk` y su SHA-256. Los artefactos tienen retención limitada.

La entrega incluye [M01 · Paredes rebotadoras](docs/m01-paredes-rebotadoras.md): tres niveles permanentes, ondas elásticas y límite de velocidad, con balance provisional. Conserva **interfaz de juego simplificada, una sola barra de tiempo, saldo y pausa dentro del tablero y feedback visual opcional apagado por defecto**, además de racha comprable, especiales y escoba de dos dedos. La interfaz usa «Tienda» y «Comenzar día», sin mostrar números de día. Debug se abre con el botón DEBUG de arriba a la izquierda del árbol. La validación en Android físico y el ajuste de balance jugando siguen pendientes.

**M02 incluido (0.8.0+16):** bate independiente, tres potencias, gestos de uno/dos
dedos, impulso por movimiento y giro, y feedback configurable. Balance provisional. [Cómo probarlo en DEBUG](docs/m02-bate-beisbol.md).

**E01 incluido (0.9.0+17):** evento Gravedad por inclinación del teléfono, objeto
aleatorio rompible con 3–6 toques, duración limitada y prueba forzada desde DEBUG.
Pendiente de validación física. [Sensores y pruebas](docs/e01-gravedad.md).

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
- Monedas de $1/$10/$50/$100/$500 con colores propios, sin cifras ni símbolos sobre sus caras; una bola genera $1 de base. Monedas individuales, aterrizaje, área manual mejorable sin imán y barrido opcional. No se fusionan; la reserva por denominaciones conserva el valor si se llena el límite visible. No se recogen ni atraen mientras se lleva una bola.
- Día inicial de **20 segundos en total: 15 de producción y 5 de recogida**. **1,5 bolas por segundo** (una cada ⅔ s); pausa y taller sin temporizador. El ingreso se banca una sola vez y lo pendiente se descarta.
- Árbol progresivo con conexiones, arrastre, zoom, ficha de efecto y compra manteniendo pulsado 1 segundo; las compras revelan nuevos caminos.
- 24 tipos y 65 nodos de mejora (la primera del árbol permite llevar dos bolas), con costes provisionales y requisitos del [balance actual](docs/balance.csv), robot que empuja e imán ligado al dedo activo.
- Resultados y estadísticas en un pop-up sobre el juego detenido, con un único botón para ir al árbol en su pantalla independiente. Desde el árbol se pulsa «Comenzar día»; ahorro y compras persistentes.
- Guardado JSON v7 con compatibilidad de jornadas anteriores, herramienta seleccionada, escrituras en orden, copia anterior válida y restauración pausada de jornadas interrumpidas. En Android se usa archivo temporal y reemplazo; en web, almacenamiento del navegador.
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

La entrega vigente pasa **211 pruebas**, análisis y compilación Android en la pipeline enlazada arriba. Los resultados de entregas anteriores se conservan en el [registro de validación](docs/validacion-prototipo.md).

La [pipeline manual](docs/ci.md) ejecuta doctor, dependencias, formato, análisis y pruebas, compila el APK de depuración y lo guarda como artefacto descargable junto con su SHA-256. Se activa en **Actions → Flutter - APK manual → Run workflow**; no se dispara con cada push.

## Límites de esta entrega

Es una primera implementación jugable, no una validación final del MVP. Falta probar en un móvil físico el agarre, los lanzamientos, el giro de ambas escobas, el balance y los 60 FPS bajo carga. Los precios siguen provisionales; el generador emite 1,5 bolas/s durante los quince segundos iniciales de producción, sujeto al espacio de salida. No hay dispositivo de referencia acordado. Los sonidos son clics del sistema con opción de silencio; no hay efectos de audio propios ni control independiente de volumen. El taller abre un árbol progresivo; su revisión táctil y el ajuste final de precios siguen pendientes. Ver [cómo se explora y compra](docs/arbol-de-mejoras.md).

El juego mantiene su progreso localmente y no genera ingresos mientras está cerrado. Se solicitan puntos de control cada cinco segundos de avance activo. Un cierre forzado puede perder progreso desde la última escritura correcta, y la recuperación de una copia puede retroceder más; al restaurar no se simula el tiempo cerrado. Si falla el guardado se avisa y se permite reintentarlo. Si el archivo y su copia están dañados, se pide una acción explícita antes de comenzar una partida nueva. La copia de seguridad puede recuperar un estado anterior.

Gráficos dibujados mediante primitivas, iconos Material/Cupertino incluidos por Flutter y tipografía predeterminada de Flutter; sin arte externo ni descargas de fuentes añadidas por la aplicación. Los iconos de instalación son todavía los de la plantilla de Flutter.

Ver [cómo está implementado](docs/implementacion.md), el [formato de guardado](docs/persistencia.md), las [decisiones técnicas](docs/decisiones.md), el [registro de validación](docs/validacion-prototipo.md) y el [historial de cambios](CHANGELOG.md).
