# AJ-007 — Sonido, háptica y absorción

Versión: **0.19.0+30**. Implementación integrada; calibración artística y
mediciones en Android físico pendientes. No cambia recompensas, cuotas,
precios, física de bolas ni los tiempos o estética de las monedas BUG-001.

## Funcionamiento

`FeedbackController` consume eventos confirmados. Agrupa por tipo cada 50 ms,
prioriza estrellas/compras/cuotas y reserva dos voces para capas compartidas.
Límite inicial: ocho voces en total, configurable. Seis plops alternan timbre
con pitch sutil; la densidad reciente de capturas introduce y retira suavemente
una capa de absorción. El movimiento real alimenta una única rodadura discreta.
Los contactos persistentes no generan impactos por fotograma.

Las monedas emiten tintineos de salida y una cascada pentatónica de llegada.
La cantidad representada por paquetes agrupados influye en el evento, sin
convertirse en dinero adicional. El resumen AJ-008A reutiliza los eventos de
llegada; saltar sus animaciones no reproduce una ráfaga de sonidos antiguos.
P01 ya existente utiliza cristal suave y rotura/estrella al confirmar el cobro.
Solo las compras válidas emiten confirmación.

Android precarga una paleta offline con SoundPool reutilizable y dos bucles.
No crea reproductores por bola. El canal envía lotes, controla foco de audio,
interrupciones y rampas de volumen. La suma de ganancias individuales está
acotada, con margen para los bucles y prioridad para recompensas importantes.
En plataformas sin puente Android se omite el sonido sin afectar a la partida.

Háptica nativa independiente del sonido, agrupada y priorizada; intervalo
inicial de 180 ms, mayor en tandas. Se respeta la capacidad y los ajustes del
sistema. No se presupone control de amplitud arbitrario ni se genera vibración
continua. Los contadores DEBUG registran solicitudes, no respuesta física medida.

Cada bola capturada sale inmediatamente de la simulación económica/física y
crea una representación transitoria: avanza hacia el centro, se hunde, reduce
su tamaño y se oscurece. Una máscara circular compartida y el borde delantero
la ocultan. Doradas conservan su apariencia. Una sola reacción de borde agrupa
las capturas; usa el radio real, incluido el crecimiento de AJ-005A.
El pool inicial admite 1024 representaciones; no crea cuerpos físicos.

Pausar/segundo plano detienen efectos y vacían eventos sonoros pendientes.
Reanudar no reproduce eventos antiguos. Las animaciones transitorias no se
restauran ni participan en la contabilidad: una captura confirmada no vuelve
a generar ingresos por restaurar o terminar su animación.

## Configuración

Ajustes existentes: Sonido, volumen 0–100 % y Vibración independientes.
Silenciar conserva el último volumen. Preferencias persistentes; los guardados
anteriores usan 80 % como volumen inicial. JSON v13 y balance v20 conservados.

Parámetros y rangos: `assets/audio/feedback.json` y `FeedbackConfig`.
DEBUG, accesible desde el botón superior izquierdo de Tienda, añade controles
Audiovisual y preescuchas. Las modificaciones DEBUG se descartan al salir y no
sustituyen las preferencias/progreso reales. Los cambios de animación se aplican
al iniciar la jornada de prueba. Valores iniciales sujetos a calibración.

## Recursos y regeneración

23 WAV mono 22050 Hz, aproximadamente 308 KB: síntesis original y transitorios
procesados de Kenney Impact Sounds (CC0). Origen, licencia y hash del archivo
original en `assets/audio/LICENSE.md`; originales seleccionados en
`tool/audio_sources/kenney`. Generador reproducible:

```sh
python3 tool/generate_feedback_audio.py
```

Requiere Python y ffmpeg para regenerar; el juego funciona completamente offline.
Los sonidos se pueden sustituir conservando sus claves en el manifiesto.

## Archivos principales

- Dominio: `lib/features/feedback/domain/{feedback_config,feedback_controller,absorption_effects}.dart`.
- Plataforma: `lib/features/feedback/platform/{platform_feedback_backend,absorption_painter}.dart`.
- Android: `FeedbackBridge.kt`, `MainActivity.kt`, `android/app/build.gradle.kts`.
- Integración: `game_session.dart`, `game_app.dart`, `main.dart`, `board.dart`,
  `garden_game.dart`, `star_bubbles.dart`, `reward_delivery.dart`,
  `results_sequence.dart`, `results_overlay.dart`, `skill_tree_screen.dart`.
- Recursos: `assets/audio`, `tool/generate_feedback_audio.py`, `pubspec.yaml`.
- Pruebas: `audiovisual_feedback_test.dart`, `star_bubbles_test.dart`,
  `visual_feedback_test.dart`, `test_support.dart`.
- Mediciones: `tool/benchmark_feedback.dart`, perfiles `docs/performance/aj007-*`.

## Validación y límites

Las pruebas cubren agrupación, prioridades, límite de voces/ganancia, silencio,
háptica independiente, pausas, compras válidas, persistencia, aislamiento DEBUG,
reciclaje, bancos WAV y ocultación de bolas con diferentes radios. Las pruebas
económicas existentes siguen verificando el cobro y restauración sin duplicados.

Los benchmarks de Cloud miden CPU del modelo/mezclador, curvas, pool y tablero
cargado. No equivalen a CPU/GPU de Android, latencia SoundPool, respuesta háptica
ni una certificación de 60 FPS. Es obligatorio escuchar y sentir el APK en un
móvil, probar varias jornadas y ajustar timbre/volúmenes/frecuencia háptica.
Pendientes: CPU/GPU/frame pacing/memoria Android, picos bajo capturas masivas,
latencia percibida y aprobación artística. No se ha simulado esa aprobación.

### Mediciones Cloud reproducibles

Comparación AOT contra `7d5266f`, 2880 muestras por escenario (1/10/50/100
capturas, repetidas y tablero con 200 bolas/escoba/bate/lanzador):

| Escenario | Antes p95 / p99 / pico | Después p95 / p99 / pico |
|---|---:|---:|
| 100 capturas repetidas, modelo monedas | 3 / 32 / 252 µs | 3 / 40 / 531 µs |
| Lo anterior y tablero cargado | 3869 / 14542 / 35525 µs | 2738 / 13131 / 50337 µs |

Son observaciones de un host compartido, no una mejora de velocidad garantizada.
El pico de 50,3 ms impide declarar ausencia de tirones incluso en esta prueba;
la física cargada ya presenta picos antes del cambio. RSS final del proceso de
modelo: 10,49 MB antes y 11,24 MB después, no memoria Android ni atribución
precisa por componente. No se modificó la física para ocultar este resultado.

Mezclador + pool de hundimiento, tandas de 100 cada 200 ms durante 15 s:
p95 9 µs, p99 14 µs, pico 2606 µs, siete voces lógicas máximas,
200 hundimientos simultáneos y cero reciclajes forzados. 38 solicitudes
hápticas agrupadas frente a 7500 capturas. RSS final 8,25 MB. La prueba usa un
backend sin reproducción, por lo que no mide coste del mezclador Android.
JSON completos en `docs/performance/aj007-{before-model,after-model,feedback-cpu}.json`.

```sh
dart --suppress-analytics compile exe tool/benchmark_reward_visuals.dart -o /tmp/reward-bench
/tmp/reward-bench
dart --suppress-analytics compile exe tool/benchmark_feedback.dart -o /tmp/feedback-bench
/tmp/feedback-bench
```

Validación local: suite completa de 409 pruebas correcta y 18 pruebas específicas
correctas tras añadir el caso de despertar del ticker (410 casos en el conjunto
final). Análisis sin incidencias y formato sin cambios. La pipeline vuelve a
validar el conjunto completo y compila el puente Kotlin Android.
