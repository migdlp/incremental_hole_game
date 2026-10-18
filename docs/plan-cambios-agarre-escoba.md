# Plan de cambios: agarre, escoba y progresión de control

Fecha: 18 de octubre de 2026. Base revisada: `main`, commit `1bf1efa`, prototipo `0.1.0+1`.

Estado actual: `0.2.1+3` entregado con APK; pendiente validación en Android físico y OK de jugabilidad. Los resultados y límites se registran al final de este archivo. Recoge las indicaciones del usuario y sustituye el orden de trabajo del [plan anterior](plan-siguiente-iteracion.md) para esta tanda. La documentación general se ha actualizado por petición del usuario el 18 de octubre; esto no sustituye la aceptación de jugabilidad ni el balance final.

## Forma de trabajar

1. Implementar los bloques en el orden de este archivo, con cambios pequeños y revisables.
2. Registrar aquí lo implementado, sus pruebas y lo pendiente. No marcar un bloque como verificado solo porque compila.
3. Revisar la sensación de juego antes de construir la siguiente herramienta sobre unas físicas que todavía no funcionan bien.
4. Distinguir implementación, verificación y OK del usuario. Ningún resultado automático equivale al OK de jugabilidad.
5. Cuando estén terminados los cambios acordados y tengamos el OK del usuario, actualizar conjuntamente README, PRD, diseño, implementación, estado actual y demás documentación afectada. Hasta entonces, mantener el seguimiento en este archivo.

La creación inicial de este archivo fue solo planificación. Esta tanda implementa los bloques 1–5; mantiene el árbol visual y el balance definitivo para más adelante. La documentación general se actualizará tras el OK acordado.

## Decisiones acordadas

- El control inicial será **agarrar y arrastrar una sola pelota**, sin recoger grupos.
- Dejar una pelota con cuidado debe producir muy poco movimiento residual. Lanzarla con un gesto rápido debe darle inercia en esa dirección.
- El siguiente método será una **escoba recta**, con un frente parecido a una raya que barre grupos. Sustituye como objetivo de control al empujador circular actual, que dispersa como una bola de billar.
- La escoba tendrá una mejora de anchura o longitud del frente, para abarcar más bolas; después vendrá la **escoba en V**, que las reúne.
- Empezar por estas tres formas: agarre individual, escoba recta y escoba en V. Ampliar la escoba recta es una mejora intermedia, no una cuarta herramienta independiente.
- La aspiradora queda aparcada. Otros métodos se documentan como posibilidades futuras, sin incorporarlos a esta implementación.
- El rediseño del árbol de habilidades se abordará más adelante, cuando el usuario explique la dirección que quiere. No se considera satisfactorio el diseño plano actual.
- El balance de precios y economía se revisará después de validar agarre y barrido. No se fijan precios definitivos durante la prueba de físicas.
- Se mantiene la recogida de monedas por pulsación al inicio y la mejora comprable para recogerlas al arrastrar.
- Al pasar a la noche desaparecen las bolas y monedas pendientes; cada día nuevo comienza vacío. Se conservan ahorro y mejoras compradas.

## Punto de partida histórico, antes de esta implementación

| Área | Estado actual | Cambio necesario |
| --- | --- | --- |
| [Simulación del tablero](../lib/features/board/domain/board.dart) | Pala circular; separa bolas radialmente y añade impulso al contacto. No hay agarre individual | Introducir estado de agarre y herramientas con geometría propia; evitar impulsos gratuitos al soltar con cuidado |
| Entrada y presentación | La sesión conecta el puntero con pala y recogida de monedas | Distinguir agarrar, barrer y pulsar monedas; representar la herramienta y la bola agarrada de forma coherente |
| Física | Ya hay velocidades, rozamiento, colisiones, límites y captura por el hoyo | Mantener esas reglas y comprobar que los nuevos controles no crean energía, saltos o duplicados |
| Monedas | Se cobran por toque y recorrido desde el primer día | Restringir el recorrido a un desbloqueo comprado |
| Noche | Se descarta el tablero; el nuevo día crea otro vacío | Reforzar pruebas e incluir cualquier bola agarrada y estado de herramienta |
| Tienda | Catálogo de ocho tipos presentado como lista | Integración funcional mínima de herramientas cuando proceda; rediseño visual y balance posterior |

## Bloques de implementación

| Bloque | Trabajo | Dependencia | Implementado | Verificado | OK usuario |
| --- | --- | --- | --- | --- | --- |
| 1 | Agarre de una bola y física de soltar/lanzar | Ninguna | Sí | Pruebas y navegador; Android físico pendiente | Pendiente |
| 2 | Escoba recta y ampliación de anchura | Física del bloque 1 validada | Sí | Pruebas; sensación en Android pendiente | Pendiente |
| 3 | Escoba en V | Barrido recto estable | Sí | Pruebas; sensación en Android pendiente | Pendiente |
| 4 | Monedas: pulsación y desbloqueo de barrido | Gestos de herramientas definidos | Sí | Pruebas y recogida por toque en navegador | Pendiente |
| 5 | Limpieza nocturna y persistencia completas | Revisión desde bloque 1; cierre tras 4 | Sí | Diez ciclos, noche, pausa, carga y migración en pruebas | Pendiente |
| 6 | Revisión integrada y APK manual | Bloques 1–5 | Sí | Pipeline correcta, firma verificada y APK publicado | Pendiente |
| Posterior | Árbol de habilidades progresivo | Entrega posterior PR #12 | Implementado en `1720fba` | Pruebas propias y CI; revisar registro actual | Aceptación táctil pendiente |
| Posterior | Balance de precios y ritmo de progreso | Controles validados; coordinar con árbol | No iniciado | Pendiente | Pendiente |
| Documentación | Actualizar documentación general | Autorizado expresamente por el usuario el 18 de octubre | Sí | Referencias, valores y enlaces comprobados | Solicitud recibida; no equivale al OK físico del MVP |

El detalle del árbol y del balance se añadirá cuando se acuerde. No son requisitos para empezar el agarre ni autorizan un rediseño anticipado. Si se incorporan a esta tanda, su finalización forma parte del cierre documental.

### Bloque 1: agarre individual y lanzamiento

- Seleccionar una pelota al tocarla y conservar su identidad durante el arrastre. No agarrar otra accidentalmente al cruzarla ni permitir un segundo agarre simultáneo.
- Mantener una relación estable entre dedo y pelota, sin salto inicial ni empuje circular invisible sobre las demás.
- Obtener la velocidad de salida de un tramo reciente del movimiento y del tiempo transcurrido, con filtrado y límite razonables. No usar el desplazamiento total como fuerza ni depender de cuántos eventos envíe la pantalla.
- Si el gesto termina despacio o se detiene antes de soltar, la pelota queda casi quieta. Si termina rápido, conserva velocidad y dirección y luego frena por rozamiento.
- Resolver choques, bordes y entrada en el hoyo durante el agarre. Si se captura, liberar la referencia y producir una sola recompensa.
- Pausar, cancelar el puntero o perder foco no debe interpretarse como un lanzamiento fuerte. Reanudar o restaurar no mantiene un dedo inexistente.

Aceptación pendiente:

- [x] Un gesto mueve solo una pelota agarrada; las demás responden únicamente a contactos físicos válidos.
- [x] En una zona plana, sin contactos y lejos del hoyo, colocar despacio o parar y soltar no produce un disparo artificial.
- [x] Un lanzamiento rápido recorre más que uno suave en condiciones equivalentes y sigue la dirección final del gesto.
- [x] Gesto equivalente con distinta frecuencia de eventos produce resultados comparables; velocidad y posiciones permanecen finitas.
- [ ] No atraviesa paredes o bolas por saltos del puntero, ni se duplica al capturar, pausar o restaurar.

Los valores de suavizado, límites y tolerancias se medirán y anotarán al implementar; no se dan aquí por calibrados. La sensación se comprobará también jugando.

### Bloque 2: escoba recta y mayor anchura

- Representar y simular un frente alargado con grosor: el dibujo debe coincidir con la colisión.
- Barrer un grupo en la dirección del movimiento, sin usar como sustituto un círculo mayor ni dispersar radialmente desde su centro.
- Probar el frente perpendicular al movimiento con orientación estable; decidir mediante prueba si ese seguimiento resulta cómodo y cómo evita giros bruscos al parar o retroceder.
- Aumentar la anchura permite abarcar más bolas de verdad. Mantener grosor, impulso y control comprensibles, sin multiplicar fuerza automáticamente por ensanchar.
- Definir el acceso a la escoba como avance respecto al agarre; usar configuración de desarrollo para comparar variantes antes de fijar precios. La solución de prueba no se entrega como un atajo gratuito en la partida normal.

Aceptación pendiente:

- [x] Un grupo situado frente a la escoba avanza con el barrido sin el efecto de billar del empujador circular.
- [x] Una versión más ancha alcanza bolas que la estrecha deja fuera, con geometría visible fiel.
- [ ] Esquinas, extremos y cambios de dirección no provocan teletransporte, vibración continua o bolas atrapadas permanentemente.

### Bloque 3: escoba en V

- Dos brazos forman una V orientada para conducir bolas hacia el centro durante el barrido.
- Mantener choques físicos, sin atraer bolas a distancia ni convertirla en una aspiradora.
- Comprobar la unión central y extremos: agrupar debe facilitar transportar, no bloquear las bolas entre segmentos.

Aceptación pendiente:

- [x] Bolas que encuentra cada brazo se reúnen durante un barrido controlado.
- [x] Se pueden llevar y liberar grupos cerca del hoyo sin atasco permanente ni recompensas por estar dentro de la V.
- [x] La mejora se distingue de una escoba recta simplemente más ancha.

### Bloque 4: monedas por pulsación y mejora de barrido

- Al inicio, pulsar recoge una moneda o pila; cruzarla arrastrando una pelota o una escoba no cobra.
- Tras comprar barrido, pasar por encima cobra a lo largo del segmento completo entre eventos. Pulsar sigue funcionando.
- Distinguir pulsación de arrastre, incluso al iniciar el gesto encima de una moneda; evitar que la actualización de simulación cobre por otra vía sin desbloqueo.
- Barrido es distinto de radio e imán. Definir requisitos y compatibilidad con compras existentes al integrar, sin conceder funciones implícitas.
- Persistir la compra. El precio provisional de integración, si hace falta, se identificará como provisional para el balance posterior.

Aceptación pendiente:

- [x] Sin mejora, solo pulsa y cobra; con mejora, también barre y cobra; nunca se suma dos veces una moneda.
- [x] Tienda y mensajes explican el cambio; compra y efecto sobreviven a noches y reaperturas.
- [ ] El gesto de recoger monedas no provoca un lanzamiento involuntario de una pelota.

### Bloque 5: noche, pausa y guardado

- Revisar esta integración desde el primer bloque, no dejar estados de agarre inválidos hasta el final.
- Eliminar al terminar la jornada todas las bolas y monedas, incluidas pilas, aterrizajes y la pelota agarrada. No recompensar bolas retiradas ni cobrar monedas pendientes.
- Nuevo día con listas vacías, sin agarre ni gesto anterior; las emisiones normales ocurren después. Conservar ahorro, herramientas y mejoras compradas.
- Mantener ingreso liquidado una vez, pérdida de monedas pendientes y guardado nocturno sin tablero activo.
- Definir compatibilidad con guardados anteriores antes de cambiar catálogo o esquema. No invalidar progreso antiguo silenciosamente.
- Reanudar la misma jornada conserva sus objetos guardados; no equivale a empezar otro día. Soltar el estado de entrada con seguridad al restaurar.

Aceptación pendiente:

- [x] Cerrar agarrando una pelota y con monedas pendientes deja la noche y el siguiente día limpios.
- [x] Reabrir de noche no recupera objetos descartados; ahorro y desbloqueos siguen correctos.
- [x] Diez ciclos y un cierre repetido no duplican ingresos ni arrastran objetos.
- [x] Cargar un guardado anterior aplica la política de compatibilidad registrada y conserva el progreso que corresponda.

### Bloque 6: revisión integrada

Ejecutar formato, `flutter analyze` y `flutter test`, con regresiones significativas de los comportamientos anteriores. Revisar manualmente agarre suave/fuerte, ambas escobas, monedas y varios días completos. Ejecutar la pipeline manual de APK para entregar el cambio jugable y registrar el commit y enlace de ejecución. Mantener pendiente la prueba en Android físico si no se dispone de dispositivo.

## Otros métodos de arrastre para más adelante

Estas opciones amplían el [brainstorming anterior](ideas-herramientas-bolas.md), sin comprometer implementación ni sustituir las tres formas elegidas:

| Método | Qué aporta respecto a la escoba | Qué habría que probar |
| --- | --- | --- |
| Rastrillo | Dientes que guían varias bolas en calles | Que los huecos no atasquen ni dejen escapar demasiadas |
| Recogedor con laterales | Retiene mejor un grupo al transportarlo | Vaciarlo con un gesto sencillo y capacidad visible |
| Escoba curva en U | Rodea más el grupo que una línea recta | Diferencia útil frente a la V, sin atraparlo para siempre |
| Rodillo o barra con guías | Empuja un frente con apoyos laterales | Que sea más cómodo que añadir anchura sin más |
| Doble escoba | Dos brazos ajustables que reúnen y empujan | Control con un dedo y ventaja clara frente a la V |
| Aspas o corriente de aire | Apoyo que desplaza bolas por una zona | Orientación, dispersión y equilibrio con el control manual |
| Cinta transportadora | Traslado continuo por una ruta | Entrada, salida y grado de automatización |

La aspiradora permanece como idea aparcada, sin prioridad para esta tanda.

## Registro de avance y decisiones

| Fecha | Bloque | Cambio o decisión | Evidencia / pendiente |
| --- | --- | --- | --- |
| 2026-10-18 | Planificación | Orden acordado: agarre individual → escoba ampliable → V; monedas y noche conservadas; árbol y balance posteriores | Plan inicial, sin OK final |
| 2026-10-18 | Bloques 1–5 | Implementados en `1a8fed7`, PR #8 integrada | 36 pruebas y navegador correctos; revisión en móvil y OK pendientes |
| 2026-10-18 | Bloque 6 | Pipeline manual 39136783858 completada; APK `0.2.0+2` publicado | Firma verificada; enlace en evidencia de entrega |

Para cada implementación añadir commit, pruebas ejecutadas y resultado, revisión manual y pendientes. Registrar el OK del usuario únicamente cuando lo haya dado. Actualizar este plan durante el trabajo; actualizar la documentación general al cierre acordado.

## Controles entregados en 0.2.0+2 — 18 de octubre de 2026

### Controles y decisiones de integración

- Mano inicial: selección de una bola dentro de su radio más 12 unidades de tolerancia, conservando el desplazamiento respecto al dedo. Un gesto iniciado en vacío no agarra bolas que cruza después. Pulsar una moneda tiene prioridad sobre agarrar una bola próxima.
- Lanzamiento: velocidad media del tramo final de 80 ms, limitada a 380 unidades/s; por debajo de 18 unidades/s se deja quieta. Parar antes de soltar elimina la inercia del movimiento anterior. La frecuencia de eventos no se usa como fuerza.
- Arrastre de mano limitado a 700 unidades/s y movimiento de escoba a 900. Física con pasos de hasta 1/240 s, fricción existente y sin impulso extra por mantener una escoba parada. Estas cifras son valores iniciales de implementación, sujetos a prueba de sensación.
- Escoba perpendicular al desplazamiento: ignorar cambios de dirección inferiores a 3 unidades, giro máximo de 3 radianes/s y orientación conservada al parar. Al tocar, se orienta hacia el hoyo. En la recta, invertir el movimiento no obliga a girar 180 grados una línea equivalente.
- Colisiones y dibujo comparten segmentos con grosor de 7 unidades. La V abre hacia el movimiento y reúne hacia su vértice posterior; no atrae a distancia. La rotación aporta velocidad de contacto limitada para evitar golpes exagerados.
- Selector Mano / Escoba / Escoba en V: muestra bloqueos, permite volver a herramientas compradas y conserva la elección. Comprar una herramienta la selecciona. Cambiarla cancela el gesto anterior con seguridad.
- Monedas: sin barrido, cobrar al levantar tras una pulsación con desplazamiento máximo de 8 unidades. Un arrastre que empieza encima tampoco cobra; cancelar o pausar no confirma la pulsación. Con barrido se comprueba todo el segmento. El imán sigue siendo una capacidad independiente y conserva sus requisitos actuales.

### Progresión provisional para poder probar

| Compra | Coste provisional | Requisito | Efecto |
| --- | --- | --- | --- |
| Escoba recta (`broom`) | 20 | Ninguno | Desbloquea frente de anchura 80 |
| Anchura (`paddle`) | 20 / 70 / 160 | Escoba recta | Anchuras 96 / 112 / 128; también afectan a la V |
| Escoba en V (`broom_v`) | 80 | Anchura nivel 1 | Desbloquea dos brazos que reúnen bolas |
| Barrido de monedas (`sweep`) | 20 | Ninguno | Permite recoger arrastrando; pulsar sigue disponible |

Se conservan el resto de precios y efectos. `paddle_radius` se mantiene como clave interna por compatibilidad; el frente completo mide cuatro veces ese valor y la tienda muestra la anchura resultante. Estos importes permiten probar la progresión; no equivalen al balance definitivo ni al rediseño del árbol.

### Guardado y cierre

- Instantánea versión 2 con herramienta seleccionada; compras y ahorro persistentes.
- Migración de versión 1: conserva progreso, resultados, objetos de la misma jornada y compras anteriores. Quien compró anchura recibe el acceso a escoba necesario para conservar esa compra. Sin anchura previa empieza con mano. El barrido nuevo no se concede gratis.
- Durante una jornada antigua se validan los valores originales antes de migrar; la restauración queda pausada. La migración se comunica en pantalla nocturna.
- Una bola agarrada se guarda como bola normal en su posición y sin velocidad de lanzamiento; no se restaura un dedo inexistente. Pausa, cancelación y cierre cancelan el agarre sin lanzar ni cobrar pulsaciones pendientes.
- Noche sin tablero activo; al empezar otro día, listas de bolas/monedas vacías y ningún gesto heredado. Las monedas no cobradas se pierden y las bolas retiradas no generan recompensa.

### Evidencia y límites de esta entrega

- `flutter doctor -v`: SDK Flutter/Dart, Android y Chrome correctos. Faltan herramientas de escritorio Linux y Android Studio; no impiden el destino Android configurado.
- `flutter pub get --enforce-lockfile`: correcto, sin actualizar dependencias.
- Formato y `flutter analyze --no-pub`: correctos.
- `flutter test --no-pub`: 36 pruebas superadas (32 de dominio/sesión y 4 de widgets). Cubren colocación suave, pausa antes de soltar, lanzamiento a 30/60/120 Hz de eventos, orientación, grupos, anchura, V, entrada real de puntero en widgets, monedas, guardado v1/v2 y diez ciclos limpios.
- Compilación web correcta. Navegador Chromium a 390×844, con generación normal y puntero: 2 bolas capturadas, 4 monedas recogidas por pulsación y recarga pausada conservando ingreso, sin errores JavaScript. Cambio entre herramientas compradas y persistencia del barrido también comprobados, sin errores JavaScript; esta parte usa un guardado aislado de prueba, no se presenta como progreso obtenido jugando.
- Pendientes: sensación con dedo en Android físico, medición de rendimiento en dispositivo, OK del usuario, diseño definitivo del árbol y balance. Las casillas marcadas cuentan con evidencia automática o de navegador; las restantes requieren revisión adicional. Esto no sustituye el OK del usuario ni la prueba física en Android.
- Pipeline manual [39136783858](https://github.com/migdlp/incremental_hole_game/actions/runs/39136783858): completada correctamente sobre `main`, commit `1a8fed78ced1e92b2d16b46bb3d7b1a78b8493d5` ([PR #8 integrada](https://github.com/migdlp/incremental_hole_game/pull/8)). Formato, análisis, 36 pruebas, compilación Android y verificación de firma correctos.
- [Descargar APK y SHA-256](https://github.com/migdlp/incremental_hole_game/actions/runs/39136783858/artifacts/12140570505): artefacto `jardin-mecanico-debug-apk`, ZIP con `jardin-mecanico-debug.apk` y su suma. Versión `0.2.0+2`, APK de depuración para pruebas. Caduca el 1 de noviembre de 2026; puede regenerarse con la pipeline manual.
- Se registra el resultado en un cambio posterior de este archivo; el APK corresponde al commit de código indicado, no a ese registro documental posterior.


## Ajuste de balance solicitado — día inicial de 15 segundos

Estado: implementado para probar en `0.2.1+3`; balance definitivo y OK pendientes.

- El contador inicial dura **15 segundos en total**: 10 de producción y 5 de recogida final. Las mejoras de duración pasan a 15/20/25 segundos de producción, es decir, 20/25/30 totales. Conservan incrementos de 5 segundos y sus precios anteriores.
- El intervalo inicial entre bolas pasa de 0,75 a **3 segundos**. Los niveles de generador pasan de 0,65/0,55/0,45 a **2,6/2,2/1,8 segundos**. La frecuencia baja cuatro veces en todos los niveles.
- Con ambos cambios, una jornada base sin bloqueos produce 3 bolas, frente al máximo teórico anterior de 80. Su valor sigue siendo 2 monedas: 6 monedas generadas si se capturan las tres. El ingreso real exige recogerlas. No se reajustan precios de compras en esta tanda.
- Guardado versión 3 con versión de balance por jornada. Una jornada ya guardada con v1/v2 termina con duración, objetos e intervalo anteriores; puede pausarse y reabrirse otra vez sin perderlos. El nuevo balance se aplica al siguiente día. No se reinician ahorro, niveles ni herramientas.
- Validación local: análisis y 41 pruebas correctos. Cinco pruebas específicas comprueban contador total, cierre sin producción, primera emisión, reducción a todos los niveles y compatibilidad de una jornada antigua a través de varias reaperturas. Las pruebas anteriores de controles y monedas siguen pasando.
- Se mantiene el acuerdo de actualizar la documentación general después del OK; esta sección registra únicamente esta implementación y sus evidencias.
- Entrega Android: [PR #10 integrada](https://github.com/migdlp/incremental_hole_game/pull/10), código en `1d71843dd96fa32b745bc770bfc154c42720ab7a`. [Pipeline manual 39138119402](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402) completada correctamente: análisis, 41 pruebas, compilación y firma.
- [Descargar APK 0.2.1+3 y SHA-256](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402/artifacts/12141030218). Artefacto ZIP de pruebas disponible hasta el 1 de noviembre de 2026; descomprimir e instalar `jardin-mecanico-debug.apk`. El APK anterior 0.2.0+2 no incluye este balance.


## Actualización documental autorizada — 18 de octubre de 2026

El usuario pidió actualizar la documentación general después de las entregas 0.2.0+2 y 0.2.1+3. Se alinean README, índice, PRD, diseño, implementación, economía, guardado v3, guías y evidencias de APK. Se conserva la historia de las pruebas y se distingue la revisión de navegador de controles del nuevo balance probado por CI. La entrega posterior del árbol se registra debajo. Precios, pruebas Android físicas y aceptación de jugabilidad siguen pendientes; esta actualización no los declara terminados.


## Entrega posterior incluida en documentación

Al actualizar se incorporó `1720fba` (PR #12), que implementa el árbol progresivo con zoom, descubrimiento y compra cancelable de tres segundos. Se conserva el código de esa entrega y sus notas; ver [árbol](arbol-de-mejoras.md). El número de paquete sigue siendo 0.2.1+3: identificar cada APK por commit y ejecución, no solo por versión. Las decisiones iniciales de este plan se conservan como historia; ya no describen el árbol como una tarea sin iniciar.

La entrega del árbol quedó comprobada en [CI 39141075339](https://github.com/migdlp/incremental_hole_game/actions/runs/39141075339), sobre `1720fba`: 48 pruebas, APK y firma correctos. [Descargar APK con árbol](https://github.com/migdlp/incremental_hole_game/actions/runs/39141075339/artifacts/12142120297); este build conserva la versión `0.2.1+3`, por lo que hay que distinguirlo del build anterior por commit.
