# Ejecutar, probar y modificar el prototipo

Guía para una copia del repositorio. El [README](../README.md) ofrece el inicio rápido; aquí se explican requisitos, primer recorrido y problemas conocidos.

## 1. Preparar herramientas

| Herramienta | Versión de esta entrega | Dónde se fija o comprueba |
| --- | --- | --- |
| Flutter | 3.35.7, canal estable | [.fvmrc](../.fvmrc), [workflow](../.github/workflows/flutter-manual.yml) y `flutter --version` |
| Dart | 3.9.2, incluido en Flutter | `dart --version`; no instalar un SDK independiente para esta app |
| Flame | 1.35.1 resuelta | [pubspec.lock](../pubspec.lock); la declaración permite versiones compatibles |
| JDK completo | Temurin 21 en CI; 21.0.12.1 probado localmente | `java -version` y `javac -version` |
| Android SDK | Platforms 35/36, Build Tools 35.0.0 | `sdkmanager --list_installed` |
| Herramientas nativas Android | NDK 27.0.12077973, CMake 3.22.1 | [workflow](../.github/workflows/flutter-manual.yml) |
| Gradle / AGP / Kotlin | 8.12 / 8.9.1 / 2.1.0 | [wrapper](../android/gradle/wrapper/gradle-wrapper.properties), [settings](../android/settings.gradle.kts) |

El proyecto declara mínimos compatibles en `pubspec.yaml`; `.fvmrc` y CI seleccionan una versión exacta. `.fvmrc` no instala FVM: se puede usar Flutter directamente, siempre comprobando su versión. Con Flutter 3.35.7, Android hereda `minSdk 24`, `compileSdk 36` y `targetSdk 36` de la extensión de Flutter; el [build de la app](../android/app/build.gradle.kts) no los duplica.

Instala Flutter 3.35.7 desde el archivo oficial usado en el workflow, un JDK con compilador, Android command-line tools y, para web, Chrome/Chromium. Añade `flutter/bin` al `PATH` y establece `JAVA_HOME` y `ANDROID_HOME` con tus rutas reales. Después:

```bash
flutter --version
dart --version
java -version
javac -version
flutter config --jdk-dir "$JAVA_HOME" --android-sdk "$ANDROID_HOME"
sdkmanager --sdk_root="$ANDROID_HOME" \
  'platforms;android-35' 'platforms;android-36' \
  'build-tools;35.0.0' 'ndk;27.0.12077973' 'cmake;3.22.1'
flutter doctor --android-licenses
flutter doctor -v
```

Revisa y acepta las licencias que correspondan a tu instalación. Android Studio es un IDE opcional para este flujo por CLI. Los avisos de compilación de escritorio Linux no impiden compilar Android o web; el destino Linux nativo no está configurado como entrega.

### Entorno cloud ya preparado

Solo en el entorno de esta sesión:

```bash
source /workspace/dev-env/env.sh
cd /workspace/incremental_hole_game
/workspace/dev-env/check.sh
```

| Elemento local | Ruta o configuración |
| --- | --- |
| Flutter | `/workspace/flutter` |
| JDK completo | `/workspace/dev-env/jdk` |
| Android SDK | `/workspace/android-sdk` |
| Caché Dart | `/workspace/dev-env/pub-cache` |
| Activación | `/workspace/dev-env/env.sh`, cargado desde los perfiles Bash del usuario |
| Registros locales | `/workspace/dev-env/logs/` |
| Comprobaciones | `check.sh` acepta una ruta de proyecto y usa el juego por defecto |

Estos scripts y SDK no se distribuyen dentro del repositorio. Clonar el código en otro equipo no crea `/workspace/dev-env`. En el entorno cloud se configuró el proxy de Gradle en `~/.gradle/gradle.properties` y la confianza de certificados para el JDK; en otro equipo hay que usar su propia configuración de red. No copiar credenciales ni desactivar TLS para reproducir el build.

## 2. Instalar dependencias y arrancar

Si necesitas una nueva copia:

```bash
git clone https://github.com/migdlp/incremental_hole_game.git
cd incremental_hole_game
```

Desde la raíz del repositorio:

```bash
flutter pub get --enforce-lockfile
flutter devices
flutter run -d <id-del-dispositivo-android>
```

Sustituye `<id-del-dispositivo-android>` por el identificador que muestra `flutter devices`, con depuración USB habilitada y autorizada. Para apoyo en navegador:

```bash
flutter run -d chrome
```

En un servidor sin interfaz gráfica:

```bash
flutter build web --no-web-resources-cdn
python3 -m http.server 8123 --directory build/web
```

Abre el servidor desde un navegador que tenga acceso a ese entorno. El puerto es local al equipo donde se ejecuta Python; el comando no publica un sitio ni crea un túnel. Mantener la misma URL/origen ayuda a reutilizar el progreso web.

## 3. Primera partida y resultado esperado

1. Con almacenamiento vacío aparece el taller, saldo cero y «Comenzar día 1».
2. Inicia el día: el contador empieza en 15 s: 10 de producción y 5 de cierre. La primera bola se intenta emitir a los 3 s y no hay bola inmediata.
3. Pulsa una bola para agarrarla y arrástrala al hoyo; suelta despacio para colocar o con un gesto final rápido para lanzar. Una captura produce una moneda visible; el contador diario no sube hasta recogerla.
4. Pulsa y levanta sobre las monedas aterrizadas para cobrarlas. Cruzarlas arrastrando no cobra sin comprar barrido. Pulsa pausa: tiempo y simulación deben detenerse; al continuar no se recupera tiempo de pared.
5. En los últimos cinco segundos aparece el aviso de recogida y se detiene el generador.
6. Al acabar, el taller muestra ingreso, pérdida pendiente, capturas, récord y saldo. Compra si alcanza el saldo o ahorra; el siguiente día puede iniciarse sin comprar.
7. Sal a segundo plano durante una jornada y vuelve: debe abrirse pausada. Una recarga web recupera el último guardado disponible, también pausado.

El día base produce tres bolas sin bloqueos y puede generar seis monedas si entran todas; una compra de veinte requiere ahorrar varias jornadas. Costes y ritmo siguen provisionales. Comprar escoba recta, anchura y V permite comparar controles; selecciona las herramientas compradas con los botones Mano / Escoba / Escoba en V. Ambas escobas giran según tu arrastre, con suavizado.

Si cargas una jornada v1/v2, terminará con sus tiempos anteriores: el día siguiente adopta el balance nuevo. No borres la partida para aplicar el cambio. Ver [migraciones](persistencia.md#compatibilidad-entre-versiones).

## 4. Validar y generar instalables

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

El APK local es de depuración. La [pipeline manual](ci.md) genera otro instalable, verifica firma y guarda APK/SHA-256. Para perfil en teléfono, usar `flutter run --profile -d <id-del-dispositivo-android>`; recopilar resultados siguiendo el [registro de validación](validacion-prototipo.md).

`adb install -r` exige una firma compatible con la versión instalada. Los runners de CI no conservan un keystore de depuración gestionado por este proyecto, de modo que distintas ejecuciones o builds locales pueden usar certificados diferentes. Si aparece `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, no desinstales automáticamente: desinstalar puede borrar el progreso. Decide si puedes descartarlo o mantén la firma compatible en tu entorno de pruebas. El proyecto no define todavía una estrategia de firma de producción.

## 5. Modificar sin romper contratos

| Cambio | Punto de entrada | Comprobación necesaria |
| --- | --- | --- |
| Precios, valores y niveles existentes | [balance.csv](balance.csv) | Catálogo, compras, progresión y compatibilidad de jornadas guardadas |
| Nueva mejora o comportamiento | [catálogo](../lib/features/upgrades/domain/catalog.dart), tablero/sesión y UI | IDs estables, efecto, requisitos, guardado y pruebas; no basta añadir una fila |
| Física o geometría | [Board](../lib/features/board/domain/board.dart), [geometría de herramientas](../lib/features/board/domain/tool.dart), [Vec](../lib/core/vec.dart) y render | Colisiones, barrido, captura, límites y gesto real |
| Fases, reloj o cierre | [GameSession](../lib/app/game_session.dart), [DayCycle](../lib/features/day_cycle/domain/day_cycle.dart) | Límite temporal, cobro único y restauración |
| Guardado | [Referencia](persistencia.md) y adaptadores | Principal/copia, fallos, versiones y partidas previas |
| Pantallas y sonido | [game_app.dart](../lib/app/game_app.dart) | Recorrido de widgets, pausa y prueba visual/sonora en destino |
| SDK o CI | [.fvmrc](../.fvmrc), configuración y [workflow](../.github/workflows/flutter-manual.yml) | Resolver lockfile, actualizar hash del SDK y verificar la ejecución manual |

Tras cambiar comportamiento, actualiza su explicación y evidencia siguiendo la [guía de documentación](guia-documentacion.md). No añadas pruebas que solo repitan constantes; prioriza conservación de valor, transiciones y recuperación.

## Problemas conocidos de preparación

| Síntoma | Qué revisar |
| --- | --- |
| `flutter`/`dart` no están en PATH o usan otra versión | Activación del SDK correcto y `command -v flutter`; no mezclar Dart independiente |
| Java funciona, pero Gradle indica que falta `JAVA_COMPILER` | `javac -version`, JDK completo y `flutter config --jdk-dir` |
| Conexión rechazada o certificados al resolver Gradle | Gradle no hereda por sí solo toda configuración de proxy del shell; configurar el entorno y su almacén de confianza |
| Daemon de Gradle desaparece con memoria agotada | Mantener límites de [gradle.properties](../android/gradle.properties): heap 3 GB, dos workers, Kotlin 768 MB; revisar memoria y procesos del equipo |
| Dependencias fijadas no se pueden resolver | Usar el SDK exacto y revisar el error antes de cambiar `pubspec.lock` |
| No se recupera una partida | Leer el aviso y [las reglas de recuperación](persistencia.md); no borrar principal y copia para ocultar el fallo |

Los fallos de proxy, ausencia de compilador y memoria se detectaron y resolvieron durante la preparación local. No son requisitos adicionales de lógica del juego.
