# Uso permanente del laboratorio

## Exportar una partida

Al acabar una jornada, árbol → DEBUG → Laboratorio de balance. Exportar
`session.json`, `days.csv`, `summary.txt` con los botones de compartir/descargar.
En Android se abre la hoja de compartir; en web se descarga si compartir archivos
no está disponible. Copiar JSON es una alternativa local si el sistema no ofrece
destinos. No se necesita servidor. La hoja de compartir es la del sistema: elegir
el destino es una acción del tester.

El JSON tiene el detalle/configuración y validador; el CSV una fila por jornada
cerrada. `summary.txt` separa normal, DEBUG y bots. Un día activo se exporta como
`active` en JSON y todavía no ocupa una fila CSV. Enteros largos son texto decimal:
importar las columnas como texto en hojas de cálculo para evitar redondeo.
Los archivos contienen solo el historial retenido y explican sus truncamientos.

Entrar a DEBUG para exportar **no reetiqueta** días normales anteriores. Los días
jugados dentro de DEBUG son temporales y deben exportarse antes de abandonar el
sandbox; no se mezclan con el guardado normal. No hay resultados humanos incluidos
por defecto. Consulte [contrato-v1.md](contrato-v1.md) para unidades/cobertura y
[partidas-humanas.md](partidas-humanas.md) para las condiciones de pruebas reales.

## Simular con las físicas reales

Requisitos: Flutter3.35.7/Dart3.9.2 y Python3. No necesita emulador ni Android.
Desde raíz, `flutter pub get`, después:

```sh
tool/run_balance.sh docs/balance/BAL-TOOLS/scenarios/baseline.json /tmp/bal-run-a
python3 tool/balance_compare.py /tmp/bal-run-a
```

El runner es un test-host Flutter que ejecuta `GameSession`, Board y las mismas
transiciones/contabilidad. No representa dedos humanos ni renderiza. JSON de
escenarios permite cambiar fichero de CSV **solo para ese proceso**, dotaciones
iniciales `normal_levels`, `p02`, `e03`, `starting_coins` (string),
`purchase_priority`, `days` y `quota_curve` (lista de strings). Nunca escribe balance.csv
ni preferencias del jugador. Los niveles iniciales son dotaciones experimentales;
las compras posteriores sí usan requisitos, precios y monedero reales.

Estrategias v1:

- `idle`: ningún input. Mide capacidad pasiva, no incapacidad de un jugador.
- `hand_seek`: selecciona mano, elige primera bola viva (orden de Board), touch en
  su posición, drag hacia agujero a240 unidades/s en pasos1/60s. Suelta al llegar o
  cada120 frames. Conoce posiciones exactas y puede comportarse peor/mejor que
  una persona; no es un modelo de experiencia humana.
- `abilities`: activa las habilidades ya disponibles cuando están cargadas; no
  usa mano ni poderes bloqueados. Son intentos/activaciones reales de Board.

Las cartas se eligen por primera opción ofrecida, sin reroll. Al terminar un día,
compra cada familia por orden de prioridad hasta bloqueo y pasa a la siguiente.
Puede morir por cuota. No prestigia automáticamente ni inventa habilidades.

Semillas: `seeds` fija el evento de sesión, derivaciones E03/gravedad/agujero negro;
Board/Launcher conservan semilla real `día*7919`. Sensores desactivados, pasos fijos
1/60s y cortes reales de jornada. RNG cosmético/tiempos de pared no entran en el
fingerprint. Se exportan estados inicial/final y config efectiva. `SOURCE_COMMIT`
proviene de Git, con sufijo `-dirty` si hay cambios locales. En builds manuales
sin define aparece unknown, nunca se adivina un commit.

Repetir misma versión, configuración, semillas y estrategia reproduce JSON y
`deterministic_sha256`. No se promete igualdad entre plataformas o motores futuros.
Curva B tiene solo10 objetivos: el experimento para al acabarla, sin inventar
continuación. La curva vigente del juego sigue25,50,100,500,1000,10000,…/4 jornadas.

## Comparación y regresiones

```sh
tool/run_balance.sh docs/balance/BAL-TOOLS/scenarios/baseline.json /tmp/bal-run-b
python3 tool/balance_compare.py /tmp/bal-run-a /tmp/bal-run-b --out /tmp/bal-diff
python3 -m unittest discover -s test/tool -v
flutter test test/features/balance_lab_test.dart test/features/balance_simulator_test.dart
```

Genera comparison.json/csv/md: diferencias exactas y porcentuales, tasas ponderadas
por bolas, medias/desviación poblacional por sesión y desglose JSON por escenario.
No promediar porcentajes de días con producciones distintas. Falta de medición y
denominador0 producen null, no0%. Solo compara el esquema soportado y no mezcla
tipos humanos/DEBUG/bot. Cambiar escenario/semilla exige `--allow-config-change` y
queda etiquetado como experimento; no es una regresión estricta.

Para comparar versiones, ejecutar cada checkout con escenario copiado idéntico y
salidas separadas. Conservar JSON/CSV/config y SHA de fuentes; no sobrescribir una
referencia histórica. Si cambian campos/esquema, migrar con contrato documentado o
rechazar. Advertencias indican truncamiento/cobertura/config/horizonte distinto.
En humanos, verificar además mismo dispositivo, build, ayuda y protocolo: la
herramienta no puede certificar esa comparabilidad.

La CI sigue siendo manual. Los tests deterministas y el validador comprueban
coherencia; **no fallan por tasas o precios distintos intencionadamente**. Después
de una actualización importante: ejecutar escenarios, comparar, revisar resultados
con AG01, justificar cambios esperados y conservar la referencia anterior antes de
aprobar una nueva. La referencia humana final de06 espera a04.

## Coste técnico

```sh
dart compile exe tool/benchmark_balance.dart -o /tmp/bal-benchmark
/tmp/bal-benchmark > /tmp/bal-overhead.json
```

Siete repeticiones alternando observer on/off,120 pasos de calentamiento y600
medidos, carga de180 bolas iniciales. Ejecutar sin otros builds/tests CPU a la vez.
Resultados de Linux AOT no son Android ni GPU. Ver muestras/dispersión y tamaños,
no solo un porcentaje aislado. El objetivo provisional no es gate de tiempo en CI.
