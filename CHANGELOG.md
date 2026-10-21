# Historial de cambios

Se registran entregas y cambios observables. La versión actual del paquete se declara en `pubspec.yaml`; no hay una release de tienda o etiqueta de distribución certificada por este archivo.

## 0.10.0+18 — E02: Agujero negro

- Apariciones periódicas independientes, varios objetos simultáneos sin sensores,
  3–6 toques y succión ampliada hasta 10 s sin cambiar captura ni recompensas.
- Activación repetida restablece tiempo sin acumular radio/potencia; ondas bajo
  bolas/herramientas, daño progresivo y sonido sujeto a ajustes.
- Pausa/restauración conservan objetos y efecto sin duplicar activaciones.
  Recogida elimina ambos; monedas, herramientas y agarres protegidos.
- DEBUG fuerza 1–3 objetos sin sobrescribir la partida; JSON v7 / balance v12,
  v11 congelado. Parámetros físicos, intervalo y presentación provisionales.

## 0.9.0+17 — E01: Gravedad

- Evento aleatorio de producción, 5 % por jornada compatible, un objeto como
  máximo y 3–6 toques para activar hasta 10 s de gravedad por inclinación.
- Sensor de gravedad Android con acelerómetro filtrado alternativo y comprobación
  real de lecturas. Muestreo suspendido en pausa, segundo plano y recogida.
- Fuerza gradual en bolas y herramientas libres, agarres y monedas protegidos;
  anuncio de activación, daño visible y límites físicos conservados.
- Estado del evento y velocidades libres guardados, RNG separado de las bolas,
  balance v11 con v10 congelado y forzado/simulación temporal desde DEBUG.
- Física/aspecto provisionales; daño por bolas y otros eventos simultáneos siguen abiertos.

## 0.8.0+16 — M02: Bate de béisbol

- Bate físico independiente, desbloqueable con tres niveles de potencia activa;
  costes y parámetros configurables y provisionales.
- Control rígido de uno/dos dedos compartido con la escoba. Impulso por velocidad
  relativa y giro, rebote pasivo constante, contactos persistentes sin bonificación
  repetida y límite final de velocidad compartido con paredes.
- Feedback visual opcional, clic de impacto y vibración breve con preferencia
  persistente y agrupación de impactos.
- Pose y compras guardadas; balance v10 con v9 congelado. DEBUG aislado del progreso.

## 0.7.0+15 — M01: Paredes rebotadoras

- Tres niveles de potencia de rebote, automáticos y persistentes, configurables
  en CSV. Multiplicadores, precios y requisitos provisionales de prueba.
- Límites de velocidad, resolución convencional de esquinas y captura de bolas
  rápidas por recorrido/subpasos. Monedas y recogida final conservadas.
- Líneas elásticas y ondas por impacto, con efectos transitorios acotados.
- Balance v9; las jornadas anteriores conservan sus ajustes v8 congelados.

## 0.6.0+14 — G01: Feed the Hole

- Nuevo nombre visible en Android, interfaz y web: Feed the Hole.
- Documentación vigente y PRD actualizados; referencias históricas conservadas.
- Mismo identificador Android, repositorio, almacenamiento y migraciones.
- Sin cambios de mecánicas, iconos ni gráficos.

## 0.6.0+13

- Agujero arriba y generador abajo, intercambiando sus posiciones. El generador emite hacia arriba y su salida visual sigue esa dirección.

## 0.6.0+12

- Jornada base de 20 segundos: 15 para generar bolas y 5 para recoger monedas.
- Las mejoras de duración progresan ahora de 18 a 30 segundos de producción.
- Las jornadas guardadas con balance v1–v6 conservan su configuración hasta finalizar; el nuevo balance se aplica al comenzar otra jornada.
- El modo debug del árbol cuenta con pruebas para ambas vistas, compras y pantalla móvil.
- Verificación local: 135 pruebas y análisis estático correctos. El APK requiere la pipeline Android porque este entorno no tiene Android SDK.

## Combos y planificación del brainstorm — 2026-10-19 · 0.6.0+11 (sin entrega APK registrada)

- Combos desde el inicio: ventana inclusiva de 1 s; ×2 desde la quinta captura y ×3 desde la décima. Feedback visual sin publicar la fórmula en la UI. Cuentan provisionalmente todas las capturas, incluidas las asistidas.
- Recompensas ordenadas por captura combinan Valor vigente, dorada y combo; se generan como monedas que hay que recoger. Las rachas no modifican premios pasados y terminan al cerrar producción.
- JSON v6 persiste racha, ventana y bonificación acumulada. Pausa y recarga no consumen ni reinician tiempo; las jornadas v1–v5 mantienen sus reglas hasta terminar.
- Tiers, potenciadora, cartas, mecanismos de fábrica, pinball, duplicadora, bomba/impulso y controles quedan descritos con decisiones abiertas en cambios futuros. El árbol y balance vigentes no cambian.
- Modo de depuración temporal: acceso desde el saldo del árbol tras 3 s, mapa completo o vista del jugador, compra gratuita de cualquier nodo con sus requisitos, compra total, monedas de prueba y reinicio. Se pueden jugar jornadas de prueba; salir o reabrir recupera el progreso normal.
- 134 pruebas correctas; aceptación táctil y balance jugando pendientes.

## UI, monedas y economía CF-09 a CF-15 — 2026-10-19 · 0.5.0+10

- Todos los importes de la UI se muestran con icono de moneda y sin `$`. Las cinco denominaciones tienen la misma geometría, sin cifras sobre su cara.
- Las recompensas se dividen en monedas individuales de 1/10/50/100/500, sin fusionar sus valores por proximidad. Reserva acotada por denominación al llenarse el límite visible; sin pérdida de dinero.
- Resumen sin barra verde, con recuentos reales de monedas recogidas por denominación de mayor a menor. Barras independientes de día y recogida, contador separado por fase.
- Ningún cobro ni atracción con bolas agarradas. Área manual disponible tras Mano I; Imán exige Área III y cuesta 300. Las compras antiguas se conservan.
- Mano I cuesta 13 y Valor progresa 2/3/5/8/13 mediante ×1,65 redondeado por nivel. JSON v5 y balance 6, con balance 5 congelado y migración de las pilas antiguas sin alterar importes.
- 116 pruebas correctas y análisis sin incidencias. Las ideas de bolas duplicadoras y bomba continúan pendientes de planificación.

## Próximas mejoras CF-06 a CF-08 — 2026-10-19 · 0.4.0+9

- Estadísticas visuales y minimalistas: dinero ganado destacado, bolas al hoyo y dinero sin recoger, barra del importe cobrado y una sola acción para ir al árbol.
- Árbol más cercano, con cuadrícula y objetivos de 64 unidades. Posiciones y segmentos únicamente en las ocho direcciones, con rutas que evitan los nodos. Se mantienen compra de un segundo, ficha bajo demanda, colores y progreso.
- Cinco niveles nuevos de fuerza de agarre, separados de la capacidad y del imán de monedas. Las bolas adicionales responden antes y resisten mejor los tirones, manteniendo física e inercia.
- Quince tipos y 49 nodos; los 44 previos se conservan. Sin compras nuevas, las jornadas antiguas mantienen su configuración. Esquema v4 y balance 5 sin cambios.
- 107 pruebas locales correctas; revisión visual de la ficha y del resumen. Android físico y balance final pendientes. La entrega del APK se registra tras la pipeline.

## Entrega del árbol compacto — 2026-10-19 · 0.3.3+8

- [PR #16](https://github.com/migdlp/incremental_hole_game/pull/16) integrada en `main`, commit `91b10cb0d5ff57ee0c69e02e17c1145d48d53c4d`. El APK incluye también los cambios ya presentes en `main`.
- [Pipeline manual 39182903655](https://github.com/migdlp/incremental_hole_game/actions/runs/39182903655) correcta: formato, análisis, 101 pruebas, compilación del APK y firma v2 verificada.
- [Descargar APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39182903655/artifacts/12156897149), disponible hasta el 2 de noviembre de 2026. Descomprimir e instalar `jardin-mecanico-debug.apk`.
- El artefacto corresponde al commit de código indicado, anterior a este registro documental. Prueba física en Android y ajuste final de sensación pendientes.

## Cabecera visible y bolas doradas — 2026-10-19 · 0.3.3+8

- El tiempo y toda la cabecera permanecen sin oscurecer durante la recogida final. El tablero conserva su capa oscura, las monedas su brillo y la pausa sigue accesible.
- Cada bola emitida por el generador tiene una probabilidad independiente del 1 % de ser dorada, también con Doble emisión. Se distingue por cuerpo dorado, borde ámbar y reflejo claro.
- Capturar una dorada produce diez veces el valor de una normal: con la base de $1 genera una moneda de $10. Las mejoras de valor también se multiplican por diez; las capturas mixtas se contabilizan por su tipo y no vuelven a pagarse.
- El guardado conserva el tipo de las bolas, las capturas doradas y la secuencia aleatoria. Los campos nuevos son opcionales al leer partidas anteriores; se valida el dinero generado con el total normal y dorado.
- Validación local: 99 pruebas correctas, análisis sin incidencias, formato y compilación web correctos. Prueba de sensación y presentación en Android físico pendiente.

## Árbol compacto y compra de un segundo — 2026-10-19 · En rama

- Cabecera solo con saldo: se retiran título, botón de atrás y controles de zoom/centrado. Se mantienen arrastre, pellizco y «Comenzar día».
- Ficha oculta al abrir; tocar un nodo muestra un resumen breve con la cantidad mejorada en verde. Precio, requisitos y estado se conservan; el resumen mantiene la información contextual de valores y porcentaje.
- Compra únicamente desde el botón, manteniendo 1 s. Nodos para consultar; interrupciones, movimientos y varios dedos cancelan sin gastar.
- Mapa de 880 × 1120 y separación vertical de 96; conexiones con tramos rectos y pasillos para requisitos cruzados. Se conserva el grafo y el balance.
- 95 pruebas correctas, incluida pantalla de 320 × 568 con texto al 150 %. Sin APK nuevo ni prueba en Android físico en esta revisión.

## Mano con peso e inercia — 2026-10-19 · 0.3.2+7

- Las bolas adicionales atraídas por la mano usan una fuerza limitada y amortiguada: se acercan durante unas décimas y siguen el arrastre con retraso. La primera bola sigue siendo un agarre manual.
- Un tirón que estira demasiado el agarre suelta la bola adicional con su velocidad física; no vuelve a engancharse durante ese mismo gesto. Al soltar normalmente, las bolas adicionales conservan su propia inercia en lugar de recibir instantáneamente la velocidad del dedo.
- Pausa y cierre siguen cancelando los agarres sin lanzar; el guardado no restaura agarres ni velocidades artificiales. Se conserva la capacidad comprada y el alcance de detección; este cambio afecta a la fuerza del imán de bolas, no al imán de monedas.
- Verificación local: 93 pruebas correctas, incluidas aproximación gradual, arrastre suave, pérdida por tirón, no reenganche, reutilización de plazas y estabilidad a 30/60/120 FPS simulados. Compilación web correcta. Ajuste inicial de sensación pendiente de probar en Android físico.

## Entrega Android — 2026-10-19 · 0.3.1+6

- [PR #15](https://github.com/migdlp/incremental_hole_game/pull/15) integrada en `main`: `27b3950146389f2db3f63cf708ffb289ed908859`.
- [Pipeline manual 39181076818](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818) correcta: formato, análisis, 88 pruebas, compilación del APK y verificación de firma v2.
- [APK y SHA-256 en ZIP](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818/artifacts/12155843676); artefacto disponible hasta el 2 de noviembre de 2026. Descomprimir e instalar `jardin-mecanico-debug.apk`.
- El APK corresponde al commit de código indicado, anterior a este registro documental. Validación física de Android y balance final pendientes.

## CF-01 a CF-04 — 2026-10-19 · 0.3.1+6 · Preparado para revisión

- Captura base de $1; denominaciones $1/$10/$50/$100/$500 con colores y sin cifras ni símbolos sobre las monedas. Las pilas representan denominaciones válidas conservando todo el importe; saldo y estadísticas muestran dólares.
- Recogida final base de 3 segundos, manteniendo 10 de producción, congelación de objetos y oscurecimiento. Ciclo activo inicial de 13 segundos.
- El pop-up de estadísticas solo ofrece «Ir al árbol de mejoras». El árbol independiente incorpora «Comenzar día», que cancela compras incompletas e inicia directamente la jornada.
- Nodos adquiridos con icono y color del tipo; comprables iluminados en blanco suave; restantes apagados. Se conserva descubrimiento, zoom, controles y compra por pulsación de tres segundos.
- Esquema JSON v4 sin cambios; balance 5 para jornadas nuevas y copia congelada del balance 4 para partidas interrumpidas. Las versiones 1–3 conservan su compatibilidad y no se pierden compras ni ahorro.
- Precios y recompensas mejoradas conservados; ajuste final de balance pendiente. No hay nuevo APK ni validación en Android físico en esta revisión.
- Verificación local con Flutter 3.35.7 / Dart 3.9.2: 88 pruebas correctas, análisis sin incidencias, formato y enlaces relativos correctos; compilación web correcta. Incluye compatibilidad de jornadas de balance 4 y estados/navegación en 320 × 568.

## Árbol del mapa futuro — 2026-10-19 · 0.3.0+5

- Mapa de cuatro ramas desde Mano I: Generador, Valor, Barrido y Mano II. Catorce tipos, 44 nodos, cinco niveles por línea y seis colores por efecto, con marcas de compra y candados.
- Se mantienen las últimas reglas: mano inicial de una bola, mejoras a 2/3/4/5/6, atracción solo con una bola agarrada y escoba física bloqueada hasta comprarla. Mano II abre el nodo de escoba y este abre Anchura I.
- Requisitos y costes del mapa en el CSV, tanto para la sesión como para la interfaz. Robot requiere Anchura II y Barrido; Doble emisión requiere Generador III y Anchura III.
- Doble emisión crea dos bolas separadas por emisión, respetando bloqueo del generador y límite de bolas. Alcance del imán añade radios de 75/85/95 para monedas.
- Balance y guardado v4. Las partidas v1/v2/v3 conservan sus compras sin regalar requisitos nuevos; sus jornadas activas conservan valores históricos hasta terminar. Las compras nuevas siguen los requisitos nuevos.
- Validación local: 82 pruebas correctas con Flutter 3.35.7 / Dart 3.9.2, análisis sin incidencias y formato correcto. La comprobación de saturación no equivale a una medición de FPS en Android.

## Capacidad de mano y desbloqueo de escoba — 2026-10-18 · `7b1c61e`

- Primera mejora visible del árbol: llevar dos bolas. Rama de capacidad de 2, 3, 4 y 5 bolas, con costes provisionales de 10, 40, 100 y 220 monedas en el CSV.
- La primera bola se agarra manualmente; solo mientras se lleva alguna se atraen bolas cercanas hasta el límite comprado. El grupo acompaña al dedo y se lanza o se suelta junto; pausa y cierre cancelan todos los agarres.
- Escoba invisible, no agarrable y sin colisiones hasta comprar «Escoba recta». Conserva su pose y las mejoras de anchura/V tras desbloquearla.
- Guardados v1/v2/v3 anteriores sin capacidad se restauran con una bola; una selección gratuita de escoba vuelve a mano sin perder progreso. Las compras existentes conservan su visibilidad en el árbol.
- Validación local con Flutter 3.35.7 / Dart 3.9.2: suite de 72 pruebas correcta y dos regresiones adicionales de pausa/renderizado correctas; análisis sin incidencias, formato y compilación web correctos. Publicada en `main` como `7b1c61e`; sin validación en Android físico.

## Resultados modales y generador inicial — 2026-10-18 · 0.2.2+4

- Generación inicial de 1,5 bolas/s (intervalo ⅔ s); los niveles del generador conservan sus aumentos relativos de velocidad y sus precios.
- Resumen y acceso al árbol en un pop-up sobre el tablero congelado. El árbol mantiene su pantalla independiente; volver muestra el mismo resumen. El fondo, su foco y sus controles están bloqueados y Atrás no cierra el pop-up.
- El motor se detiene durante los resultados. Comenzar el siguiente día cierra el pop-up y reanuda el mismo visor con tablero vacío, ahorro y mejoras conservados.
- Balance nuevo `3`; las jornadas ya guardadas con balance `1` o `2` conservan su cadencia hasta terminar. El esquema JSON sigue siendo v3.
- El fondo del cierre es solo presentación y no se guarda como jornada activa; al restaurar una noche se reconstruye vacío detrás del pop-up.
- Verificación local: análisis sin incidencias, 51 pruebas correctas y revisión visual de resumen/pantalla del árbol en 360 × 640. Android físico pendiente.

## Documentación actualizada — 2026-10-18

- Inicio rápido, diseño y arquitectura real alineados con mano y escobas recta/V, pulsación inicial y barrido comprado.
- Economía de 15 s totales, intervalos cuatro veces mayores, once mejoras y límites del ritmo de compras provisional.
- Guardado v3, compatibilidad v1/v2, herramienta y versión de balance por jornada.
- APK más reciente con árbol, 48 pruebas y límites de validación identificados; historia original conservada. No modifica código ni balance.

## 0.2.1+3 — 2026-10-18

- [PR #10](https://github.com/migdlp/incremental_hole_game/pull/10), `1d71843`: día base de 10 s de producción + 5 s de cierre; intervalo base 3 s y mejoras cuatro veces más lentas que antes.
- Duración mejorable a 20/25/30 s totales; precios conservados y todavía provisionales.
- Guardado v3 mantiene la jornada anterior hasta terminar y aplica el balance nuevo al día siguiente.
- 41 pruebas y [pipeline Android correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402); [APK del balance anterior al árbol](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402/artifacts/12141030218).

## 0.2.0+2 — 2026-10-18

- [PR #8](https://github.com/migdlp/incremental_hole_game/pull/8), `1a8fed7`: agarre individual, colocación suave y lanzamiento por velocidad final.
- Escoba recta perpendicular al movimiento con giro suave, anchura mejorable y V que reúne por contacto; selector de herramientas compradas.
- Monedas por pulsación inicial y barrido mediante compra; limpieza nocturna incluida la bola agarrada.
- Guardado v2 con elección de herramienta y migración v1; once tipos de mejora con costes provisionales.
- 36 pruebas y [pipeline Android correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/39136783858); prueba de navegador, sin aceptación en móvil físico.

## Árbol de mejoras progresivo — 2026-10-18

- [PR #12](https://github.com/migdlp/incremental_hole_game/pull/12), `1720fba`; misma versión `0.2.1+3`, [CI correcta con 48 pruebas](https://github.com/migdlp/incremental_hole_game/actions/runs/39141075339) y [APK con árbol](https://github.com/migdlp/incremental_hole_game/actions/runs/39141075339/artifacts/12142120297).

- El taller abre un tablero de nodos y conexiones con arrastre, zoom con dos dedos y controles para acercar, alejar y centrar la selección.
- Una partida nueva muestra solo la primera mejora del generador; comprar revela los siguientes niveles y caminos de control/producción. Las compras anteriores se conservan y muestran sus conexiones.
- Ficha sin nombres de fantasía: descripción del efecto, cambio porcentual respecto al nivel anterior, valores y coste en monedas.
- Nodos asequibles iluminados, sin saldo oscurecidos y adquiridos con marca verde. Mantener pulsado tres segundos en un nodo seleccionado o en su ficha completa la compra; soltar, arrastrar, usar otro dedo o pasar a segundo plano la cancela.
- Precios, efectos, IDs y formato del guardado sin cambios. El mapa añade requisitos de descubrimiento en la interfaz; la sesión conserva los requisitos históricos del CSV para cargar partidas previas.
- Pruebas de descubrimiento, alcance de todos los niveles, compatibilidad, compra/cancelación, saldo y pantalla móvil. La comprobación física en Android sigue pendiente.

## Diseño de herramientas y recogida — 2026-10-17

- Lluvia de ideas de herramientas para agrupar, transportar y lanzar bolas; son candidatas, sin implementación ni precios aprobados.
- Cambio confirmado y pendiente: monedas por pulsación al inicio; recoger arrastrando requiere comprar la mejora de barrido.
- Plan, PRD y diseño actualizados; el prototipo aún permite barrido desde el inicio. Sin cambios de código ni de balance.

## Plan de siguiente iteración — 2026-10-17

- Regla confirmada: bolas y monedas pendientes desaparecen al entrar en la noche; cada día nuevo empieza sin objetos heredados.
- Plan de regresión para cierre, dinero perdido, conservación de ahorro/mejoras y reapertura nocturna.
- La coordinación actual ya crea y descarta tableros; esta actualización documenta el alcance y las comprobaciones pendientes, sin cambiar código.

## Documentación del estado actual — 2026-10-17

- Índice por tareas, inventario de funciones entregadas y pendientes con evidencias.
- Explicación de módulos, bucle, física, economía, robot y presentación existentes.
- Referencia JSON v1, cola de escrituras, recuperación y límites de durabilidad.
- Guía de desarrollo, decisiones retrospectivas y criterios para mantener la documentación.
- Corrección de la descripción de la primera emisión y de la garantía implícita de pérdida máxima de cinco segundos. No cambia el comportamiento del juego.

## APK manual — 2026-10-17

- [PR #3](https://github.com/migdlp/incremental_hole_game/pull/3), fusionada como `44d0aeb`.
- Activación solo manual, herramientas Android/JDK completas, lockfile, formato, análisis y pruebas.
- Compilación debug, comprobación de firma, APK y SHA-256 descargables durante 14 días.
- [Ejecución correcta en main](https://github.com/migdlp/incremental_hole_game/actions/runs/39020361800).

## Prototipo 0.1.0+1 — 2026-10-17

- [PR #2](https://github.com/migdlp/incremental_hole_game/pull/2), fusionada como `70556fb`.
- Tablero Flame, empuje, captura, monedas físicas y ciclo de día/noche.
- Ocho mejoras, robot, imán, resultados y progreso local recuperable.
- Pausa por ciclo de vida y opción de silencio; gráficos de primitivas.
- 17 pruebas y compilaciones web/Android verificadas; aceptación en teléfono pendiente.

La documentación inicial del producto precede al código: [PR #1](https://github.com/migdlp/incremental_hole_game/pull/1). Sus propuestas no deben interpretarse como funciones entregadas automáticamente.
