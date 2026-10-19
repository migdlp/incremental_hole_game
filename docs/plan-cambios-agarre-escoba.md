# Plan de cambios: agarre, escoba y progresión de control

> **Entrega CF-09 a CF-15 — 19 de octubre de 2026:** [PR #18](https://github.com/migdlp/incremental_hole_game/pull/18) integrada en `main`, código `34ea6d66e884903e6fd4d47c02883e3f31b48f74`. **[Descargar APK 0.5.0+10 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39292311120/artifacts/12206371751)**, disponible hasta el 2 de noviembre de 2026. [Pipeline 39292311120](https://github.com/migdlp/incremental_hole_game/actions/runs/39292311120) correcta: formato, análisis, **116 pruebas**, compilación Android y firma v2 verificada. Descomprimir e instalar `jardin-mecanico-debug.apk`. No incluye las ideas de bolas duplicadoras/bomba. Validación en Android físico y ajuste de precios jugando pendientes.

## Tanda vigente — CF-09 a CF-15 · 0.5.0+10

Implementados UI sin `$`, monedas individuales y tamaño uniforme, resumen por denominaciones, tiempos separados, recogida con mano vacía, área antes del imán y balance inicial/Valor revisados. 116 pruebas correctas; ver requisitos y decisiones en la [referencia viva](cambios-futuros-arbol-mejoras.md). Las bolas duplicadoras y bomba se conservan como ideas sin implementar. Integrado mediante PR #18 y entregado en el APK 0.5.0+10, con evidencia en el bloque inicial.

> **Entrega CF-06 a CF-08 — 19 de octubre de 2026:** [PR #17](https://github.com/migdlp/incremental_hole_game/pull/17) integrada en `main`, código `1cd7b8761a9e1e4eea19761385086e92ec470438`. **APK 0.4.0+9:** [descargar APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39223285776/artifacts/12173036451), disponible hasta el 2 de noviembre de 2026. [Pipeline 39223285776](https://github.com/migdlp/incremental_hole_game/actions/runs/39223285776) correcta: formato, análisis, **107 pruebas**, compilación Android y firma v2 verificada. Incluye estadísticas visuales, árbol compacto de ocho direcciones y cinco niveles de fuerza de agarre. Descomprimir e instalar `jardin-mecanico-debug.apk`. Validación en Android físico y ajuste definitivo de precios pendientes.

## Próximas mejoras registradas — 19 de octubre de 2026

- **CF-06, implementado en esta tanda:** estadísticas mucho más visuales y minimalistas, con menos texto y sin información irrelevante.
- **CF-07, implementado en esta tanda:** árbol con nodos bastante más cerca que en CF-05 y colocación únicamente en las ocho direcciones cardinales y diagonales. El reparto de ramas hacia ciertos lados queda para más adelante.
- **CF-08, implementado en esta tanda:** fuerza de agarre de mano en cinco niveles, para atraer y sujetar antes las bolas adicionales, sin aumentar su capacidad ni alcance.

Autorización más reciente: implementar toda la lista vigente CF-06 a CF-08 y entregar el APK. Se han completado los tres bloques; 107 pruebas locales correctas. La aceptación en Android físico y los ajustes de precios siguen sujetos a prueba real.

La especificación se mantiene en una única referencia: [Próximas mejoras](cambios-futuros-arbol-mejoras.md#próximas-mejoras--19-de-octubre-de-2026). Se confirma que mano con peso (`9c79dd3`), cabecera visible y bolas doradas (`8f92527`) ya están en `main`, junto con CF-05. CF-06 a CF-08 están integrados y entregados en el APK 0.4.0+9 enlazado al principio de este documento.

> **Entrega CF-05 — 19 de octubre de 2026:** PR #16 integrada en `main`, commit `91b10cb0d5ff57ee0c69e02e17c1145d48d53c4d`. [APK 0.3.3+8 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39182903655/artifacts/12156897149), disponible hasta el 2 de noviembre de 2026. [Pipeline 39182903655](https://github.com/migdlp/incremental_hole_game/actions/runs/39182903655) correcta sobre ese commit: formato, análisis, **101 pruebas**, compilación Android y firma v2 verificadas. Incluye el árbol compacto, ficha al seleccionar y compra de 1 s, junto con los cambios que ya había en `main`. Las notas de preparación inferiores son históricas. Prueba en Android físico pendiente.


## Revisión CF-05 — árbol compacto, en rama

Implementada por petición del usuario: [CF-05](cambios-futuros-arbol-mejoras.md#cf-05--árbol-compacto-y-ficha-bajo-demanda--19-de-octubre-de-2026). Se conserva la información, el balance y los nodos. Pantalla sin título, atrás ni controles de zoom; ficha tras seleccionar, cantidades en verde, compra desde botón en 1 s y conexiones rectas con nodos más cercanos. Pendiente de integración; no modifica los APK históricos enlazados debajo.


> **Entrega Android — 19 de octubre de 2026:** PR #15 integrada en `main`, commit `27b3950146389f2db3f63cf708ffb289ed908859`. Versión **0.3.1+6**. [Pipeline 39181076818](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818) correcta: formato, análisis, 88 pruebas, compilación Android y firma verificada. [Descargar APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818/artifacts/12155843676), disponible hasta el 2 de noviembre de 2026. Descomprimir e instalar `jardin-mecanico-debug.apk`. La prueba en Android físico y el ajuste de balance siguen pendientes. Las notas de preparación inferiores conservan el estado anterior a esta entrega.


## Implementación CF-01 a CF-04 — 19 de octubre de 2026

El usuario autoriza implementar estos cambios y aclara que ninguna moneda debe mostrar cifras, cantidades ni símbolos sobre su cara. La revisión 0.3.1+6 prepara monedas por color con base de $1, recogida final de 3 s, estadísticas con una sola salida al árbol y el botón «Comenzar día» en esa pantalla, además de estados apagado/blanco/color en los nodos. Conserva el mapa, las compras, el agarre múltiple y el desbloqueo de escoba ya implementados.

La referencia detallada sigue en [CF-01 a CF-04](cambios-futuros-arbol-mejoras.md). Los precios y los efectos de Valor comprados se mantienen; su balance sigue provisional. Esquema JSON v4, balance nuevo 5 y jornadas históricas 1–4 conservadas. Preparado en rama para revisión; no se declara APK ni prueba física en Android.


> Actualización vigente — 19 de octubre: se implementa el [mapa futuro v0.6](cambios-futuros-arbol-mejoras.md) en 0.3.0+5: 44 nodos, cuatro ramas, cinco niveles, seis colores, Doble emisión y alcance del imán. Mano inicial de una bola, mejoras a 2/3/4/5/6 y escoba solo tras comprarla. Guardado/balance v4 conserva las compras y jornadas antiguas. Esta nota sustituye estados anteriores que la contradigan; ver [árbol actual](arbol-de-mejoras.md) y [historial](../CHANGELOG.md).

Fecha: 18 de octubre de 2026. Base revisada: `main`, commit `1bf1efa`, prototipo `0.1.0+1`.

Estado actual: `0.2.1+3` entregado con APK; pendiente validación en Android físico y OK de jugabilidad. Los resultados y límites se registran al final de este archivo. Recoge las indicaciones del usuario y sustituye el orden de trabajo del [plan anterior](plan-siguiente-iteracion.md) para esta tanda. La documentación general se ha actualizado por petición del usuario el 18 de octubre; esto no sustituye la aceptación de jugabilidad ni el balance final.

## Cambios futuros añadidos — 19 de octubre de 2026

Los requisitos nuevos se mantienen en una única referencia: [CF-01 a CF-04 del MD de cambios futuros](cambios-futuros-arbol-mejoras.md#cambios-añadidos--19-de-octubre-de-2026).

1. **CF-01:** valor base de $1 por bola y monedas de $1, $10, $50, $100 y $500, con color por denominación; sin moneda de $25.
2. **CF-02:** recogida final con duración inicial de **3 segundos**, sustituyendo los cinco segundos anteriores como objetivo futuro.
3. **CF-03:** estadísticas con un único botón para ir al árbol; pantalla de árbol independiente con «Comenzar día».
4. **CF-04:** nodos comprados con icono y color de tipo; no comprados apagados; comprables iluminados en blanco suave.

Estado: requisitos documentados y pendientes de implementar; su numeración no asigna prioridad. Los registros de entregas anteriores se conservan como historia, sin atribuirles estos cambios. La nota vigente sobre capacidad de mano y desbloqueo de escoba se mantiene.

## Referencias vivas del árbol — actualización de diseño

Por indicación del usuario, el árbol de mejoras queda como trabajo futuro y lo iremos editando conforme se añadan ideas y se acuerden cambios.

- **Lo que existe:** [Árbol actual](arbol-de-mejoras.md), contrastado con el modelo del árbol y el CSV.
- **Lo que estamos diseñando:** [Cambios futuros del árbol](cambios-futuros-arbol-mejoras.md), referencia principal y editable de nodos, conexiones, colores y progresión propuesta.
- **Balance ejecutado por el juego:** [balance.csv](balance.csv). El documento futuro no sustituye sus valores.

Estado: diseño en revisión, sin implementar y sin prioridad adicional asignada. Los colores por tipo y la intención de progresión creciente son dirección de diseño; los costes, multiplicadores, capacidad de bolas, raíz del árbol y requisitos concretos siguen siendo propuestas. La escoba inicial y la transformación de esa misma escoba en V se conservan como dirección ya acordada. La mejora de recoger dos monedas continúa pendiente y es distinta del agarre de varias bolas.

Esta actualización documenta el estado actual y la propuesta futura; no publica cambios de jugabilidad ni un APK. Cuando se implemente un nodo, se actualizará la referencia actual con su evidencia y se marcará aquí su estado real, sin mantener dos diseños futuros divergentes.

## Hoja de ruta vigente — cambios pendientes del 18 de octubre de 2026

**Actualización de entrega — 18 de octubre de 2026:** implementación publicada en `main`, commit `f7bcdef7b80b917102e78545b9729513e927a1e7`. APK de prueba generado localmente con Flutter 3.35.7 y firma verificada: `build/app/outputs/flutter-apk/app-debug.apk` (140 MiB), SHA-256 `cd006dc4316a21c77d0d6deb6a4bf07812b79d54b6a9a0f97930cfa71ccb2b88`. Las 63 pruebas, el análisis y el formato pasan. GitHub Actions no se ejecutó porque GitHub CLI no tiene sesión iniciada. Siguen pendientes la instalación en Android físico y el OK de jugabilidad. Esta actualización sustituye el estado de publicación pendiente de las notas locales que siguen, conservadas como registro de implementación.

**Esta sección distingue requisitos pendientes de implementación local verificada.** Los dos cambios muy importantes ya están implementados localmente; no se declara nueva entrega Android ni publicación del código. Cuando contradiga objetivos anteriores, prevalece como dirección vigente; los registros históricos se conservan sin atribuirles cambios posteriores.

Este documento será el seguimiento vivo de los cambios futuros y se actualizará conforme se acuerden prioridades y se observe cada resultado. El usuario ha autorizado publicar y mantener este seguimiento en GitHub; cada publicación se confirmará con su commit, sin dar por entregadas las funciones pendientes.

### Prioridades confirmadas y pendientes

| Prioridad | Cambios | Estado |
| --- | --- | --- |
| **Muy importante, al mismo nivel** | Mano siempre activa y escoba como objeto disponible desde el inicio; cierre con cinco segundos de recogida, tablero oscurecido y objetos congelados | Implementados y verificados localmente; prueba física y OK de jugabilidad pendientes |
| **Por acordar** | Mejora de escoba en V, mejora de mano para dos monedas, acceso al árbol desde el resultado y simplificación visual del árbol | Pendientes de comparar con el usuario; sin orden relativo asignado |
| **Baja, más a futuro** | Experiencia sensorial: satisfacción, vibración háptica y sonidos coordinados | Pendiente de implementar; posterior a las prioridades muy importantes |

Las secciones siguientes agrupan los cambios por área. Su orden no fija la prioridad entre áreas ni entre elementos cuya importancia siga pendiente. Las siguientes comparaciones se harán con el usuario, una cada vez, sin inventar un orden.

### Gameplay — mano activa y escoba física

**Prioridad: muy importante.**

- [x] Mantener siempre la mano como control activo: permite agarrar y arrastrar bolas o coger la escoba para barrerlas.
- [x] Hacer que la escoba aparezca como un objeto más del tablero, comparable a una bola en su disponibilidad para agarrarlo y arrastrarlo, no como un modo que sustituya a la mano.
- [x] Disponer de la escoba desde el inicio. La esquina superior derecha es una ubicación sugerida, no una posición definitiva acordada.

Implementado localmente: escoba física inicial arriba a la derecha, mano disponible en cada gesto y selector eliminado. Al soltar, conserva posición y orientación; sigue colisionando con bolas. Los guardados antiguos reciben una posición segura y los nuevos conservan la pose sin restaurar un agarre. Se conserva la V ya comprada como geometría de esa escoba, sin concederla a quien no la tenga ni rediseñar su progresión. Catálogo, identificadores, costes y requisitos históricos se mantienen para no incluir aquí el cambio de progresión pendiente.

### Mejoras y habilidades — escoba y mano

**Prioridad relativa: pendiente de acordar.**

- [ ] Convertir la escoba en V en una mejora que transforma o reemplaza la misma escoba. No será una herramienta independiente en un selector separado de la mano o de la escoba recta.
- [ ] Añadir una mejora de mano para recoger dos monedas a la vez: recoger la primera atrae la siguiente moneda cercana, con un efecto parecido a un pequeño imán que simule el agarre múltiple.

La mejora de mano no implica recogida automática general. Quedan por concretar costes, alcance y detalles de progresión; no se asignan valores ni se cambia aquí el balance existente.

### Flujo de pantallas — recogida final y resultado

**Recogida final: muy importante, al mismo nivel que la mano activa y la escoba física.**

- [x] Al terminar el día, ofrecer cinco segundos finales dedicados exclusivamente a recoger monedas.
- [x] Oscurecer toda la pantalla salvo las monedas, que seguirán brillando para concentrar la atención en su recogida.
- [x] Congelar las bolas y la escoba durante esos cinco segundos y bloquear su movimiento o arrastre. La única interacción jugable permitida será recoger monedas.
- [x] Al agotar los cinco segundos, abrir el pop-up existente de fin del día, conservando el resto de su funcionamiento salvo el cambio de botón indicado debajo.

**Acceso desde el resultado: prioridad relativa pendiente de acordar.**

- [ ] Dejar en el pop-up de fin del día únicamente el botón para ir al árbol de mejoras. No permitir comenzar el siguiente día desde ese pop-up.

El balance histórico ya registra una fase final de cinco segundos dentro del contador total. Este requisito pide su presentación oscurecida y su restricción a monedas; no autoriza por sí solo otros cinco segundos adicionales al balance ni un cambio en la duración de producción.

### Estilos — árbol de mejoras más minimalista

**Prioridad relativa: pendiente de acordar.**

- [ ] Eliminar el texto de ayuda «arrastra para explorar y pellizca para acercarte»; quitar la explicación visible no implica eliminar esos gestos.
- [ ] Eliminar el contador del total de mejoras adquiridas.
- [ ] Eliminar el texto que indica que las mejoras se aplican el próximo día; esto no cambia por sí solo cuándo se aplican.
- [ ] Revisar más adelante los estilos del árbol para hacerlo más minimalista. La dirección visual concreta queda pendiente de definición con el usuario, sin un rediseño inventado en este plan.

### Experiencia sensorial — satisfacción y sonido

**Prioridad: baja, más a futuro.**

- [ ] Hacer satisfactoria la entrada de una bola en el agujero y la aparición de una moneda, con respuesta háptica y sonidos gratificantes.
- [ ] Cuidar las secuencias rápidas de monedas al enviar muchas bolas: un «tin, tin, tin» reconocible, con ritmo y capas de sonido que tengan sentido al solaparse.
- [ ] Evitar una mezcla extraña, áspera o excesivamente saturada. Se permite cierta densidad intencional para reforzar la recompensa, sin perder claridad.

### Próximo paso del plan vigente

Probar jugando los dos cambios prioritarios y recoger el OK del usuario. Continuar comparando las prioridades aún no acordadas, sin implementarlas hasta su autorización, y mantener este seguimiento actualizado. La implementación local de esta tanda no se presenta como una nueva publicación de código o APK.

### Implementación local de las prioridades muy importantes — 18 de octubre de 2026

- **Controles:** mano y escoba física conviven sin modo permanente. El agarre conserva su desplazamiento respecto al dedo; soltar no elimina ni reinicia la escoba. Se reutilizan segmentos y colisiones, también con V previamente comprada. No se implementan nuevas mejoras de mano ni cambios de progresión de V.
- **Cierre:** se reutilizan los cinco segundos existentes, sin ampliar el día. Al cruzar el límite de producción se cancela cualquier agarre sin lanzar ni cobrar una pulsación incompleta. Bolas, escoba y robot quedan congelados; no hay nuevas emisiones ni capturas. Solo siguen las monedas y sus capacidades de recogida ya compradas, incluido el aterrizaje de monedas emitidas antes del cierre.
- **Presentación y continuidad:** tablero y cabecera se oscurecen; las monedas se dibujan después de la capa oscura y conservan su brillo. Pausar sigue accesible. Reabrir en cierre conserva tiempo y congelación, inicialmente en pausa. Al agotar el tiempo se mantiene el resultado existente y la liquidación única. Sus botones NO se cambian en esta tanda.
- **Entorno aislado:** Flutter `3.35.7` / Dart `3.9.2`, versión que fija CI, instalado aparte con SHA-256 oficial verificado. No se modifica el SDK global ni el lockfile. Una prueba con SDK estable más nuevo se descartó porque la instalación con lock estricto exigía cambiar dependencias.
- **Pruebas observadas:** base de 51 pruebas correctas; cuatro fallos funcionales nuevos antes de implementar, después corregidos. Regresiones posteriores observaron fallo y corrección de la protección de emisiones en cierre, del oscurecimiento de cabecera y del seguimiento del dedo por el imán comprado durante el cierre. Esta última regresión fue detectada por verificación independiente: se actualiza solo el cursor de recogida, sin reactivar objetos. Resultado final: **63 pruebas correctas**, análisis sin incidencias, formato correcto, `git diff --check` correcto y compilación web correcta.
- **Cobertura nueva:** disponibilidad inicial, agarrar/soltar y volver a mano, colisiones de escoba aparcada, pose guardada y valores antiguos/incorrectos, límite exacto de cierre, agarres cancelados, robot y bolas congelados, recogida con/sin barrido, pausa/restauración, cobro único y píxeles renderizados (monedas con el mismo color y resto oscurecido). La entrada de puntero se prueba en widgets, incluida la V comprada y el botón de pausa durante el cierre.
- **Publicación y APK solicitados:** el usuario autorizó publicar el código y ejecutar la pipeline, pero el acceso del navegador a `github.com` fue rechazado por la restricción de origen. No se usa otro canal para eludirla: publicación de esta implementación pendiente, pipeline NO ejecutada y APK nuevo NO generado. Se conserva la publicación documental anterior, sin atribuirle este código.
- **Límites:** sin prueba de jugabilidad en navegador ni Android físico en esta tanda, sin medición de rendimiento en dispositivo y sin OK del usuario. La comprobación visual automatizada de píxeles no equivale a una sesión manual. No hay nueva publicación de código, commit de implementación, APK ni ejecución remota. La publicación de estas notas se confirmará por separado.

## Plan y entregas anteriores — registro histórico

Los apartados siguientes documentan decisiones y entregas anteriores. Su orden de ejecución y sus objetivos se interpretan como históricos cuando la hoja de ruta vigente los sustituya.

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
