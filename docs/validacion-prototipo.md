# Registro de validación

## Entrega actual — 0.2.1+3, 18 de octubre de 2026

| Evidencia | Resultado y alcance |
| --- | --- |
| [PR #8](https://github.com/migdlp/incremental_hole_game/pull/8), `1a8fed7`, versión 0.2.0+2 | Mano, lanzamiento, escoba recta/V, anchura, barrido comprado y guardado v2; 36 pruebas |
| Navegador de controles, Chromium 390 × 844 | Generación normal y puntero: 2 capturas, 4 monedas por pulsación, recarga pausada con ingreso conservado; sin errores JavaScript. Cambio de herramientas y barrido persistente con guardado aislado de prueba |
| [PR #10](https://github.com/migdlp/incremental_hole_game/pull/10), `1d71843`, versión 0.2.1+3 | Día de 10 + 5 s, intervalos cuatro veces mayores, guardado v3 y balance por jornada |
| Validación local de 0.2.1+3 | Formato y análisis correctos, **41 pruebas**: 37 de dominio/sesión y 4 de widgets |
| [CI 39138119402](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402) | Correcta sobre `1d71843`: dependencias, formato, análisis, 41 pruebas, compilación Android, firma y subida |
| [APK del balance, antes del árbol](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402/artifacts/12141030218) | `0.2.1+3`; ZIP con APK/SHA-256, disponible hasta el 1 de noviembre de 2026 |
| [PR #12](https://github.com/migdlp/incremental_hole_game/pull/12), `1720fba` | Árbol progresivo, siete pruebas adicionales, sin cambiar versión de paquete ni guardado |
| [CI 39141075339](https://github.com/migdlp/incremental_hole_game/actions/runs/39141075339) | Correcta: formato, análisis, **48 pruebas** (39 de dominio/sesión y 9 de widgets), APK y firma |
| [APK actual con árbol](https://github.com/migdlp/incremental_hole_game/actions/runs/39141075339/artifacts/12142120297) | `0.2.1+3` sobre `1720fba`, ZIP con APK/SHA-256; retención hasta el 1 de noviembre |

Las pruebas nuevas comprueban 15 segundos totales, producción detenida durante cierre, primera emisión a los 3 s, intervalos por nivel y conservación de una jornada antigua en varias reaperturas antes de adoptar el balance nuevo. Las de controles comprueban lanzamiento con eventos de 30/60/120 Hz, colocación y parada, geometría, V hasta capturar ambos lados y entrada de puntero a través de widgets.

La revisión de navegador corresponde al control de `0.2.0+2`; no se presenta como una sesión manual con el nuevo balance. La compilación web de controles fue correcta; el build de Android y las pruebas de balance son los de `0.2.1+3`. No hay prueba de instalación, sensación, diez jornadas manuales ni perfil en Android físico. El ritmo de primera compra y robot está pendiente de redefinir; no se conserva la antigua hipótesis de 3–5 días como objetivo verificado.

## Primera implementación — registro histórico

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

## Presentación observada del prototipo 0.1.0+1

![Taller nocturno](imagenes/prototipo-noche.png)

![Jornada](imagenes/prototipo-dia.png)

## Pendiente antes de aceptar el MVP

- Ejecutar el APK en un teléfono Android físico y elegir un dispositivo de referencia.
- Validar comodidad del gesto, grupos de diez bolas y lectura de monedas entre muchos objetos.
- Jugar diez jornadas manualmente con los valores actuales y acordar primera compra y acceso al robot. La hipótesis histórica de 3–5 días necesita redefinirse.
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

## Dónde está cada prueba — suite actual

| Grupo | Ubicación | Alcance comprobado |
| --- | --- | --- |
| Catálogo y reloj | [game_rules_test.dart](../test/features/game_rules_test.dart) | Once mejoras actuales, configuración máxima, rechazo de CSV inválido y límite producción/cierre |
| Recompensas y monedas | [game_rules_test.dart](../test/features/game_rules_test.dart) | Captura única, fusión/saturación conservando valor y barrido entre eventos de puntero |
| Ciclo y compras | [game_rules_test.dart](../test/features/game_rules_test.dart) | Diez ciclos controlados, pérdida de pendientes, cierre repetido, fase/saldo/requisitos/máximos |
| Pausa y restauración | [game_rules_test.dart](../test/features/game_rules_test.dart) | Tiempo detenido, gesto cancelado, objetos en aterrizaje, estado aleatorio y cobro consistente |
| Errores de almacenamiento | [game_rules_test.dart](../test/features/game_rules_test.dart) | Contabilidad inválida, fallo recuperable, copia válida y principal de archivo interrumpido |
| Física y automatización | [game_rules_test.dart](../test/features/game_rules_test.dart) | Grupo dentro de bordes, robot en caso alcanzable e imán solo con puntero activo |
| Control de bolas | [ball_controls_test.dart](../test/features/ball_controls_test.dart) | Agarre único, inercia, frecuencia de eventos, escobas, anchura, captura en V y guardados |
| Balance y compatibilidad | [balance_test.dart](../test/features/balance_test.dart) | Contador 15 s, tres emisiones, cierre, niveles y compatibilidad del balance anterior |
| Árbol progresivo | [skill_tree_test.dart](../test/features/skill_tree_test.dart) | Dos pruebas de dominio y cinco de widgets: descubrimiento, compras heredadas, compra por pulsación, cancelación, saldo y zoom |
| Recorrido de pantalla | [widget_test.dart](../test/widget_test.dart) | Taller/ciclo, entrada real de puntero para monedas y mano, y cambio de herramientas sin excepción de widgets |

El mapa anterior apunta a las suites actuales: 16 de reglas/sesión, 16 de controles, 5 de balance, 2 de dominio del árbol, 4 de widgets generales y 5 de widgets del árbol (48 en total). La primera entrega tenía 17; se conserva arriba como evidencia histórica. La prueba de archivo sustituye el principal por contenido inválido; no reproduce todos los instantes de un corte eléctrico ni prueba el sistema de archivos Android. No hay suite `integration_test` ni un resultado de perfil físico registrado.
