# Jardín mecánico

Prototipo jugable de un incremental en Flutter + Flame. Empuja piedras con una pala circular hacia el hoyo, recoge las monedas físicas y compra mejoras durante la noche.

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

- Tablero lógico 360 × 560, escalado uniforme, generador, fricción, colisiones con rejilla espacial, pala y captura por el hoyo.
- Monedas con valor entero, aterrizaje, recogida por toque o barrido, fusión y límite de pilas sin perder valor.
- Días de 60 segundos de producción y 5 de recogida; pausa y taller sin temporizador. El ingreso se banca una sola vez y lo pendiente se descarta.
- Ocho mejoras, con niveles, costes y requisitos del [balance original](docs/balance.csv), robot que empuja e imán ligado a la pala.
- Resultados, récord, comparación entre días, ahorro y compras persistentes.
- Guardado JSON versionado, escrituras en orden, copia anterior válida y restauración pausada de jornadas interrumpidas. En Android se usa archivo temporal y reemplazo; en web, almacenamiento del navegador.
- Pausa al pasar a segundo plano, instrucciones breves y opción de silenciar los sonidos del sistema.

La tabla `docs/balance.csv` se empaqueta como recurso y se valida al cargar: es la única fuente editable del balance.

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

La [pipeline manual](docs/ci.md) ejecuta doctor, dependencias, formato, análisis y pruebas, compila el APK de depuración y lo guarda como artefacto descargable junto con su SHA-256. Se activa en **Actions → Flutter - APK manual → Run workflow**; no se dispara con cada push.

## Límites de esta entrega

Es una primera implementación jugable, no una validación final del MVP. Falta probar en un móvil físico el gesto, el balance, el acceso al robot en 3–5 días y los 60 FPS bajo carga. No hay dispositivo de referencia acordado. Los sonidos son clics del sistema con opción de silencio; no hay efectos de audio propios ni control independiente de volumen. El taller presenta las ramas y requisitos en una lista, sin el grafo visual definitivo.

No hay progreso sin conexión. Un cierre forzado puede perder hasta los últimos cinco segundos desde el punto de control; al restaurar no se simula el tiempo cerrado. Si falla el guardado se avisa y se permite reintentarlo. Si el archivo y su copia están dañados, se pide una acción explícita antes de comenzar una partida nueva. La copia de seguridad puede recuperar un estado anterior.

Gráficos dibujados mediante primitivas, iconos Material/Cupertino incluidos por Flutter y fuentes del sistema; sin arte externo ni descargas de fuentes añadidas por la aplicación. Los iconos de instalación son todavía los de la plantilla de Flutter.

Ver el [registro de validación](docs/validacion-prototipo.md) y el [índice de diseño](docs/README.md).
