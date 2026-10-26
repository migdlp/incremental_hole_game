# E03 — Evolución permanente por cartas

Versión **0.23.0+36**. [Especificación aprobada](e03-cartas-evolucion-especificacion.md).
Catálogo de doce habilidades, cinco niveles, sin costes, rarezas, rerolls ni
relación con las cuatro compras de P02. Parámetros y tablas centralizados en
`EvolutionSkill.catalogue` bajo `lib/features/evolution/domain/evolution.dart`.

## Elecciones y persistencia

Cada cuota nueva de una partida registra una elección. Primero se procesan todas
las capturas/excedentes, crecimiento y premios P01/P02 del lote; después se bloquea
la simulación. Una marca de cuota por partida evita duplicados; al prestigiar se
reinicia y la primera cuota vuelve a dar carta. Al maximizar el catálogo, las
nuevas elecciones se consumen sin selector ni premio alternativo.

El sorteo es uniforme sin reemplazo sobre habilidades por debajo de cinco. Se
conservan las opciones concretas y su orden, el estado RNG, el número pendiente y
un serial de selección. Cada toque válido resuelve un solo serial: sube un nivel,
prepara la siguiente oferta elegible y guarda todo antes de habilitar otra acción.
No se reanuda entre selecciones consecutivas. La interfaz solo muestra nombre,
descripción sin números de balance y nivel actual → siguiente, sobre el tablero
congelado. Una sola opción requiere tocarla; no hay selector vacío.

Los niveles viven en `MetaProgress.evolutionLevels`, separados de `upgrades` P02.
Los ceros se representan implícitamente mediante ausencia de entrada. Todos los
cambios de metaprogresión conservan ese mapa. El estado de activaciones y elecciones
vive en `EvolutionRun`, compartido por los tableros de una misma partida y reiniciado
al morir/prestigiar. JSON raíz **v16**, balance **v20** conservado.

Se usa el checkpoint permanente existente para la elección completa: nivel,
siguiente oferta, tablero, alimentación y premios pertenecen al mismo snapshot.
Durante un fallo de escritura el gameplay sigue bloqueado y se permite reintentar
el guardado. Un proceso nuevo recupera la operación completa o la elección anterior
pendiente; nunca medio nivel. Los guardados v1–v15 sin E03 inicializan niveles cero
y marcan las cuotas históricas como procesadas, sin cartas retroactivas ni cambios
en monedas, estrellas, compras P02, cuota, plazo o crecimiento.

Al completar una cuota al agotarse la producción, se conserva el tablero congelado
y `closingPending` hasta resolver las cartas. Un snapshot con tiempo cero es válido
únicamente en esa transición. Al terminar la última elección se cierra la jornada,
sin simular más capturas ni tiempo extra. También se recupera un cierre interrumpido
después de guardar la última carta. E01/E02 terminan conforme al fin de producción.

## Doce habilidades

- Remolino: ventana móvil de capturas, alcance según nivel y aceleración constante
  del 40 % de `gravity_acceleration` hacia el hoyo.
- Hambre insaciable: modificador temporal del radio base actual. El crecimiento por
  cuota permanece independiente y no se revierte al expirar el bonus.
- Latido: contador de producción entre jornadas y pulso dirigido. La referencia de
  lanzamiento es la velocidad axial nominal del generador principal existente,
  85 unidades/s, centralizada y reutilizada por emisión y pulso.
- Rebote dirigido: tirada por contacto de pared nuevo, tras combinar normales;
  mezcla de dirección del 25 % y conservación de la magnitud del rebote.
- Bola ariete: adicional con masa tres, tamaño/valor normales; separación e impulso
  entre bolas ponderados por masa. Persistencia del atributo `heavy`.
- Gravedad traviesa: aceleración hacia el agujero, independiente del sensor y sin
  cambiar la gravedad global ni sus eventos.
- Disparo frenético y Último esfuerzo: bonificaciones aditivas del generador
  principal; se integra el tramo final cuando un paso cruza el 75 % de producción.
- Doble ración: adicional según contador independiente de ciclos normales.
- Racha millonaria: décima captura ya multiplicada; duración/valor se fijan con el
  nivel de activación. Indicador ×2/×3 junto al hoyo, sin HUD de recargas.
- Toque de Midas: puntos porcentuales sobre la probabilidad natural del principal,
  también en extras de esa factoría; no modifica lanzador ni dorada garantizada P02.
- Golpe de suerte: tirada por captura; duplica su valor normal antes de Racha.

Capturas simultáneas se procesan individualmente en orden estable de la lista
persistida de bolas. El valor normal incluye dorada y combo existentes; luego se
aplican suerte y Racha con enteros. `evolutionBonus` conserva el incremento real
para validar la contabilidad al restaurar. No se vuelven a pagar las animaciones.
AJ-009 y resultados reciben los importes finales, mientras la alimentación sigue
contando exactamente una bola y P01 conserva sus propias recompensas.

Los tres contadores de extras (ariete, ración y Eco) avanzan solo por ciclos normales.
Pueden coincidir; sus adicionales no se cuentan como ciclos. Se reutiliza la salida
segura y el límite de población; los extras bloqueados quedan pendientes entre
jornadas. Subir nivel conserva el contador y evalúa el nuevo umbral en el siguiente
ciclo, con una activación máxima por ciclo y remanente conservado.

Todas las fuerzas nuevas se aplican exclusivamente a bolas libres. No atraen
burbujas de P01, monedas ni herramientas. Se mantiene el límite técnico existente.
No se crean cuerpos físicos para efectos, ni se conceden capturas automáticas.

## Tiempo, pausa y cierre

El tiempo procede de los pasos de producción del tablero, nunca del reloj real.
El selector, pausa, segundo plano y pantallas entre jornadas detienen efectos,
recargas, ventanas, producción, física y animaciones del tablero. Al cerrar se
cancelan los efectos activos; comienzan/conservan sus recargas. Los contadores
parciales y tiempos periódicos continúan entre jornadas; las ventanas móviles se
vacían para no juntar capturas de días distintos. Los niveles activos de cada
activación se guardan separados del nivel permanente; los pasivos usan el nuevo
nivel inmediatamente al reanudar tras el guardado.

El feedback único de captura/cuota confirmado puede escucharse al abrir cartas;
los bucles de gameplay se detienen y no se reproducen eventos antiguos al restaurar.
DEBUG conserva su aislamiento: elegir cartas no escribe el guardado normal y salir
recupera exactamente su estado previo.

## Validación y herramientas

**486 pruebas correctas** en GitHub Actions, análisis sin incidencias. Nuevas pruebas
`evolution_test.dart`, `evolution_physics_test.dart`, `evolution_persistence_test.dart`:
catálogo/cap, ofertas, seriales, restauración, activadores, ventanas, recargas,
contador entre jornadas, física, masa, probabilidades, economía impar/entera,
prestigio/derrota, cierre al último instante y fallo de disco.

Las pruebas previas de cuotas, monedas y estrellas ahora resuelven la interacción
obligatoria de cartas antes de continuar. Los casos de último instante avanzan
los relojes reales de simulación, sin alterar solo el temporizador de jornada.
Los tests dedicados a E03 siguen comprobando explícitamente la congelación pendiente.

La instancia no conserva el Flutter temporal de la tarea anterior. La revisión
automática rechazó reinstalarlo localmente por la instrucción de compilar con Actions.
Se añadió a `flutter-manual.yml` un modo opcional `validation_only` que omite Android,
formatea/corrige únicamente llaves de estilo en el runner y exporta el parche para
revisarlo/aplicarlo al repo, además de analizar, probar y medir la simulación. La
compilación de entrega usa el modo normal, sin reformatear automáticamente su fuente.

Medidas AOT: [JSON completo](performance/e03-evolution.json),
`tool/benchmark_evolution.dart`. 600 muestras tras 60 pasos de calentamiento.
Con 200 bolas iniciales: p95 0,924 ms sin E03 / 0,946 ms con todo al máximo; picos
1,008 / 1,037 ms. Con 500: p95 2,424 / 2,746 ms, picos 2,546 / 2,881 ms. Todas las
velocidades resultan finitas y limitadas. El número final de bolas difiere porque
los efectos favorecen capturas; no es un ensayo de población constante. RSS del
proceso AOT con 500 máximas: 11,64 MB, no memoria total de la app.

Son tiempos de simulación en Actions; no incluyen GPU, renderizado, audio Android
ni las monedas visuales Flutter. No certifican 60 FPS en teléfono. Quedan validación
artística/táctil y rendimiento en Android físico. No se modifica BAL01 ni se amplía
el alcance con otras bolas, habilidades o mejoras de P02.
