# Registro de la primera implementación

Fecha: 17 de octubre de 2026. La implementación original de `feat/playable-prototype` quedó fusionada en `main` como `70556fb` mediante la [PR #2](https://github.com/migdlp/incremental_hole_game/pull/2). Este registro conserva evidencia histórica; no equivale a repetir las pruebas en cada modificación documental.

## Entorno

Flutter 3.35.7 estable, Dart 3.9.2, Flame 1.35.1. Linux Debian 13, Chromium 154 en modo headless, viewport de 390 × 844. Android SDK API 36 y OpenJDK 21. El viewport simula el tamaño de un móvil, no su rendimiento ni sus condiciones de entrada.

## Comprobaciones completadas

| Comprobación | Resultado |
| --- | --- |
| Dependencias con `flutter pub get` | Correcto; versiones fijadas en lockfile |
| `dart format --output=none --set-exit-if-changed lib test` | Sin cambios pendientes |
| `flutter analyze` | Sin incidencias |
| `flutter test` | 17 pruebas superadas |
| Compilación web sin CDN de CanvasKit | Correcta |
| `flutter build apk --debug --no-pub` | APK generado correctamente; firma verificada con apksigner |
| Navegador: apertura, comienzo de jornada y pausa | Correcto; sin errores de JavaScript |
| Navegador: recarga de jornada interrumpida | Restaurada pausada, con botón Continuar |
| Navegador: empuje y recogida mediante ratón | 3 capturas, 6 monedas cobradas, 0 pendientes, sin errores de JavaScript |

Las pruebas automáticas cubren diez ciclos completos, conservación de valor al fusionar y saturar pilas, capturas y recogidas únicas, barrido rápido, requisitos y saldo de compras, límite del día, pausa, robot, imán, restauración de objetos en aterrizaje, rechazo de contabilidad corrupta, fallo de escritura y recuperación mediante copia de seguridad. La prueba de widgets recorre taller → jornada → pausa → continuar → siguiente noche.

Las pruebas de simulación introducen objetos controlados para verificar invariantes; no certifican dificultad, diversión ni balance. La prueba del navegador usa el generador y gestos reales de puntero.

## Presentación observada

![Taller nocturno](imagenes/prototipo-noche.png)

![Jornada](imagenes/prototipo-dia.png)

## Pendiente antes de aceptar el MVP

- Ejecutar el APK en un teléfono Android físico y elegir un dispositivo de referencia.
- Validar comodidad del gesto, grupos de diez bolas y lectura de monedas entre muchos objetos.
- Jugar diez jornadas manualmente y comprobar primera compra y robot en aproximadamente 3–5 días.
- Medir en modo profile la carga de 200 bolas y 100 pilas durante tres jornadas y después de diez ciclos. No se afirma haber alcanzado 60 FPS.
- Validar guardado/reemplazo en Android ante segundo plano, cierre forzado y recuperación de archivos.
- Completar audio propio, control de volumen, grafo visual del árbol e iconos de instalación.

No hay progresión sin conexión. Los puntos de control se solicitan cada cinco segundos de avance activo. Un cierre abrupto puede perder el trabajo desde la última escritura correcta; fallos de guardado o recuperación de una copia anterior pueden retroceder más. Ver [garantías y límites del guardado](persistencia.md).

## Preparación Android comprobada

Se instalaron el JDK completo Temurin 21.0.12.1, SDK Platforms 35 y 36, Build Tools 35.0.0, NDK 27.0.12077973 y CMake 3.22.1. Se configuraron proxy y confianza de certificados del entorno para Gradle. El ajuste del proyecto limita Gradle a 3 GB de heap y dos workers para evitar agotar la memoria de este entorno.

APK de depuración generado en `build/app/outputs/flutter-apk/app-debug.apk`. La compilación y su firma son correctas; esto no sustituye una prueba de instalación y juego en un teléfono físico.

## Evidencia de CI sobre main

La [PR #3](https://github.com/migdlp/incremental_hole_game/pull/3) incorporó la pipeline manual como `44d0aeb`. La [ejecución 39020361800](https://github.com/migdlp/incremental_hole_game/actions/runs/39020361800), iniciada con `workflow_dispatch` el 17 de octubre de 2026, terminó con `success` sobre ese commit. Pasaron formato, análisis y pruebas; se compiló el APK, se comprobó su firma y se subieron APK/SHA-256 y registros.

Los artefactos `jardin-mecanico-debug-apk` y `flutter-validation-logs` tienen retención de 14 días, hasta el 31 de octubre de 2026 para esa ejecución. Una descarga caducada no implica que fallase el build: se puede lanzar una nueva ejecución mediante la [guía de CI](ci.md).

## Dónde está cada prueba

| Grupo | Ubicación | Alcance comprobado |
| --- | --- | --- |
| Catálogo y reloj | [game_rules_test.dart](../test/features/game_rules_test.dart) | Ocho mejoras, configuración máxima, rechazo de CSV inválido y límite producción/cierre |
| Recompensas y monedas | [game_rules_test.dart](../test/features/game_rules_test.dart) | Captura única, fusión/saturación conservando valor y barrido entre eventos de puntero |
| Ciclo y compras | [game_rules_test.dart](../test/features/game_rules_test.dart) | Diez ciclos controlados, pérdida de pendientes, cierre repetido, fase/saldo/requisitos/máximos |
| Pausa y restauración | [game_rules_test.dart](../test/features/game_rules_test.dart) | Tiempo detenido, gesto cancelado, objetos en aterrizaje, estado aleatorio y cobro consistente |
| Errores de almacenamiento | [game_rules_test.dart](../test/features/game_rules_test.dart) | Contabilidad inválida, fallo recuperable, copia válida y principal de archivo interrumpido |
| Física y automatización | [game_rules_test.dart](../test/features/game_rules_test.dart) | Grupo dentro de bordes, robot en caso alcanzable e imán solo con pala activa |
| Recorrido de pantalla | [widget_test.dart](../test/widget_test.dart) | Taller, inicio, pausa, continuación y siguiente noche sin excepción de widgets |

Son 16 pruebas en la suite de reglas/sesión y una de widgets. La prueba de archivo sustituye el principal por contenido inválido; no reproduce todos los instantes de un corte eléctrico ni prueba el sistema de archivos Android. No hay suite `integration_test` ni un resultado de perfil físico registrado.
