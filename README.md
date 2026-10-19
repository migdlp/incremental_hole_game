# Jardín mecánico

Prototipo jugable de un incremental en Flutter + Flame. Empieza agarrando una bola, llévala o lánzala al hoyo, pulsa sus monedas y desbloquea escobas para mover grupos. Versión actual: **0.3.2+7**.

El mapa de [cambios futuros](docs/cambios-futuros-arbol-mejoras.md) se incorpora al árbol: cuatro ramas iniciales, cinco niveles, seis colores, Doble emisión y alcance del imán. Se conservan las compras anteriores y el balance de las jornadas interrumpidas; las nuevas jornadas usan balance 5.

La aplicación y su pipeline manual de APK están fusionadas en `main`. La aceptación del MVP en un Android físico sigue pendiente. Empieza por el [índice de documentación](docs/README.md), el [estado actual](docs/estado-actual.md) o la [guía de desarrollo](docs/guia-desarrollo.md).

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

- Tablero lógico 360 × 560, generador, fricción, colisiones y captura por el hoyo. Agarre individual inicial, capacidad mejorable a 2/3/4/5/6 bolas y lanzamiento manual según la velocidad final del gesto e inercia propia para las bolas adicionales. Solo una mano que ya lleva una bola atrae las cercanas, con peso y retraso; un tirón fuerte puede soltarlas.
- Escoba física disponible solo tras comprarla, perpendicular al arrastre, giro suavizado, anchura mejorable y escoba en V; selector de herramientas compradas.
- Monedas de $1/$10/$50/$100/$500 con colores propios, sin cifras ni símbolos sobre sus caras; una bola genera $1 de base. Pilas con valor entero, aterrizaje, recogida por pulsación al inicio y por barrido tras comprar la mejora, fusión y límite de pilas sin perder valor.
- Día inicial de **13 segundos en total: 10 de producción y 3 de recogida**. **1,5 bolas por segundo** (una cada ⅔ s); pausa y taller sin temporizador. El ingreso se banca una sola vez y lo pendiente se descarta.
- Árbol progresivo con conexiones, arrastre, zoom, ficha de efecto y compra manteniendo pulsado 3 segundos; las compras revelan nuevos caminos.
- Catorce tipos y 44 nodos de mejora (la primera del árbol permite llevar dos bolas), con costes provisionales y requisitos del [balance actual](docs/balance.csv), robot que empuja e imán ligado al dedo activo.
- Resultados y estadísticas en un pop-up sobre el juego detenido, con un único botón para ir al árbol en su pantalla independiente. Desde el árbol se pulsa «Comenzar día»; ahorro y compras persistentes.
- Guardado JSON v4 con compatibilidad v1/v2/v3, herramienta seleccionada, escrituras en orden, copia anterior válida y restauración pausada de jornadas interrumpidas. En Android se usa archivo temporal y reemplazo; en web, almacenamiento del navegador.
- Pausa al pasar a segundo plano, instrucciones breves y opción de silenciar los sonidos del sistema.

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

El mapa actual pasa **82 pruebas**, análisis y compilación web. La entrega anterior con árbol tiene **48 pruebas superadas** y una pipeline Android correcta sobre `1720fba`; esta iteración pasa **51 pruebas**, incluyendo cadencia, compatibilidad y el recorrido pop-up → árbol → resumen → siguiente día. Consultar el commit y la [evidencia de cada entrega](docs/validacion-prototipo.md), porque ambas conservan el número de paquete `0.2.1+3`.

La [pipeline manual](docs/ci.md) ejecuta doctor, dependencias, formato, análisis y pruebas, compila el APK de depuración y lo guarda como artefacto descargable junto con su SHA-256. Se activa en **Actions → Flutter - APK manual → Run workflow**; no se dispara con cada push.

## Límites de esta entrega

Es una primera implementación jugable, no una validación final del MVP. Falta probar en un móvil físico el agarre, los lanzamientos, el giro de ambas escobas, el balance y los 60 FPS bajo carga. Los precios siguen provisionales; el generador intenta emitir quince bolas durante los diez segundos iniciales de producción, con un valor máximo base de $15 si se capturan y cobran todas sin bloqueos. No hay dispositivo de referencia acordado. Los sonidos son clics del sistema con opción de silencio; no hay efectos de audio propios ni control independiente de volumen. El taller abre un árbol progresivo; su revisión táctil y el ajuste final de precios siguen pendientes. Ver [cómo se explora y compra](docs/arbol-de-mejoras.md).

El juego mantiene su progreso localmente y no genera ingresos mientras está cerrado. Se solicitan puntos de control cada cinco segundos de avance activo. Un cierre forzado puede perder progreso desde la última escritura correcta, y la recuperación de una copia puede retroceder más; al restaurar no se simula el tiempo cerrado. Si falla el guardado se avisa y se permite reintentarlo. Si el archivo y su copia están dañados, se pide una acción explícita antes de comenzar una partida nueva. La copia de seguridad puede recuperar un estado anterior.

Gráficos dibujados mediante primitivas, iconos Material/Cupertino incluidos por Flutter y tipografía predeterminada de Flutter; sin arte externo ni descargas de fuentes añadidas por la aplicación. Los iconos de instalación son todavía los de la plantilla de Flutter.

Ver [cómo está implementado](docs/implementacion.md), el [formato de guardado](docs/persistencia.md), las [decisiones técnicas](docs/decisiones.md), el [registro de validación](docs/validacion-prototipo.md) y el [historial de cambios](CHANGELOG.md).
