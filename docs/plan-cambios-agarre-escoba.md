# Plan de cambios: agarre, escoba y progresión de control

Fecha: 18 de octubre de 2026. Base revisada: `main`, commit `1bf1efa`, prototipo `0.1.0+1`.

Estado: planificación registrada; los cambios de este archivo no están implementados ni aprobados como entrega final. Recoge las indicaciones del usuario y sustituye el orden de trabajo del [plan anterior](plan-siguiente-iteracion.md) para esta tanda. El resto de la documentación describe la entrega anterior o propuestas previas hasta el cierre acordado.

## Forma de trabajar

1. Implementar los bloques en el orden de este archivo, con cambios pequeños y revisables.
2. Registrar aquí lo implementado, sus pruebas y lo pendiente. No marcar un bloque como verificado solo porque compila.
3. Revisar la sensación de juego antes de construir la siguiente herramienta sobre unas físicas que todavía no funcionan bien.
4. Distinguir implementación, verificación y OK del usuario. Ningún resultado automático equivale al OK de jugabilidad.
5. Cuando estén terminados los cambios acordados y tengamos el OK del usuario, actualizar conjuntamente README, PRD, diseño, implementación, estado actual y demás documentación afectada. Hasta entonces, mantener el seguimiento en este archivo.

Esta entrega crea únicamente el plan: no modifica juego, precios, árbol ni documentación general.

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

## Punto de partida observado

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
| 1 | Agarre de una bola y física de soltar/lanzar | Ninguna | Pendiente | Pendiente | Pendiente |
| 2 | Escoba recta y ampliación de anchura | Física del bloque 1 validada | Pendiente | Pendiente | Pendiente |
| 3 | Escoba en V | Barrido recto estable | Pendiente | Pendiente | Pendiente |
| 4 | Monedas: pulsación y desbloqueo de barrido | Gestos de herramientas definidos | Pendiente | Pendiente | Pendiente |
| 5 | Limpieza nocturna y persistencia completas | Revisión desde bloque 1; cierre tras 4 | Refuerzo pendiente | Pendiente | Pendiente |
| 6 | Revisión integrada y APK manual | Bloques 1–5 | Pendiente | Pendiente | Pendiente |
| Posterior | Rediseño del árbol de habilidades | Indicaciones del usuario | No iniciado | Pendiente | Pendiente |
| Posterior | Balance de precios y ritmo de progreso | Controles validados; coordinar con árbol | No iniciado | Pendiente | Pendiente |
| Cierre | Actualizar documentación general | Todo el alcance acordado terminado y OK explícito | Pendiente | Pendiente | Pendiente |

El detalle del árbol y del balance se añadirá cuando se acuerde. No son requisitos para empezar el agarre ni autorizan un rediseño anticipado. Si se incorporan a esta tanda, su finalización forma parte del cierre documental.

### Bloque 1: agarre individual y lanzamiento

- Seleccionar una pelota al tocarla y conservar su identidad durante el arrastre. No agarrar otra accidentalmente al cruzarla ni permitir un segundo agarre simultáneo.
- Mantener una relación estable entre dedo y pelota, sin salto inicial ni empuje circular invisible sobre las demás.
- Obtener la velocidad de salida de un tramo reciente del movimiento y del tiempo transcurrido, con filtrado y límite razonables. No usar el desplazamiento total como fuerza ni depender de cuántos eventos envíe la pantalla.
- Si el gesto termina despacio o se detiene antes de soltar, la pelota queda casi quieta. Si termina rápido, conserva velocidad y dirección y luego frena por rozamiento.
- Resolver choques, bordes y entrada en el hoyo durante el agarre. Si se captura, liberar la referencia y producir una sola recompensa.
- Pausar, cancelar el puntero o perder foco no debe interpretarse como un lanzamiento fuerte. Reanudar o restaurar no mantiene un dedo inexistente.

Aceptación pendiente:

- [ ] Un gesto mueve solo una pelota agarrada; las demás responden únicamente a contactos físicos válidos.
- [ ] En una zona plana, sin contactos y lejos del hoyo, colocar despacio o parar y soltar no produce un disparo artificial.
- [ ] Un lanzamiento rápido recorre más que uno suave en condiciones equivalentes y sigue la dirección final del gesto.
- [ ] Gesto equivalente con distinta frecuencia de eventos produce resultados comparables; velocidad y posiciones permanecen finitas.
- [ ] No atraviesa paredes o bolas por saltos del puntero, ni se duplica al capturar, pausar o restaurar.

Los valores de suavizado, límites y tolerancias se medirán y anotarán al implementar; no se dan aquí por calibrados. La sensación se comprobará también jugando.

### Bloque 2: escoba recta y mayor anchura

- Representar y simular un frente alargado con grosor: el dibujo debe coincidir con la colisión.
- Barrer un grupo en la dirección del movimiento, sin usar como sustituto un círculo mayor ni dispersar radialmente desde su centro.
- Probar el frente perpendicular al movimiento con orientación estable; decidir mediante prueba si ese seguimiento resulta cómodo y cómo evita giros bruscos al parar o retroceder.
- Aumentar la anchura permite abarcar más bolas de verdad. Mantener grosor, impulso y control comprensibles, sin multiplicar fuerza automáticamente por ensanchar.
- Definir el acceso a la escoba como avance respecto al agarre; usar configuración de desarrollo para comparar variantes antes de fijar precios. La solución de prueba no se entrega como un atajo gratuito en la partida normal.

Aceptación pendiente:

- [ ] Un grupo situado frente a la escoba avanza con el barrido sin el efecto de billar del empujador circular.
- [ ] Una versión más ancha alcanza bolas que la estrecha deja fuera, con geometría visible fiel.
- [ ] Esquinas, extremos y cambios de dirección no provocan teletransporte, vibración continua o bolas atrapadas permanentemente.

### Bloque 3: escoba en V

- Dos brazos forman una V orientada para conducir bolas hacia el centro durante el barrido.
- Mantener choques físicos, sin atraer bolas a distancia ni convertirla en una aspiradora.
- Comprobar la unión central y extremos: agrupar debe facilitar transportar, no bloquear las bolas entre segmentos.

Aceptación pendiente:

- [ ] Bolas que encuentra cada brazo se reúnen durante un barrido controlado.
- [ ] Se pueden llevar y liberar grupos cerca del hoyo sin atasco permanente ni recompensas por estar dentro de la V.
- [ ] La mejora se distingue de una escoba recta simplemente más ancha.

### Bloque 4: monedas por pulsación y mejora de barrido

- Al inicio, pulsar recoge una moneda o pila; cruzarla arrastrando una pelota o una escoba no cobra.
- Tras comprar barrido, pasar por encima cobra a lo largo del segmento completo entre eventos. Pulsar sigue funcionando.
- Distinguir pulsación de arrastre, incluso al iniciar el gesto encima de una moneda; evitar que la actualización de simulación cobre por otra vía sin desbloqueo.
- Barrido es distinto de radio e imán. Definir requisitos y compatibilidad con compras existentes al integrar, sin conceder funciones implícitas.
- Persistir la compra. El precio provisional de integración, si hace falta, se identificará como provisional para el balance posterior.

Aceptación pendiente:

- [ ] Sin mejora, solo pulsa y cobra; con mejora, también barre y cobra; nunca se suma dos veces una moneda.
- [ ] Tienda y mensajes explican el cambio; compra y efecto sobreviven a noches y reaperturas.
- [ ] El gesto de recoger monedas no provoca un lanzamiento involuntario de una pelota.

### Bloque 5: noche, pausa y guardado

- Revisar esta integración desde el primer bloque, no dejar estados de agarre inválidos hasta el final.
- Eliminar al terminar la jornada todas las bolas y monedas, incluidas pilas, aterrizajes y la pelota agarrada. No recompensar bolas retiradas ni cobrar monedas pendientes.
- Nuevo día con listas vacías, sin agarre ni gesto anterior; las emisiones normales ocurren después. Conservar ahorro, herramientas y mejoras compradas.
- Mantener ingreso liquidado una vez, pérdida de monedas pendientes y guardado nocturno sin tablero activo.
- Definir compatibilidad con guardados anteriores antes de cambiar catálogo o esquema. No invalidar progreso antiguo silenciosamente.
- Reanudar la misma jornada conserva sus objetos guardados; no equivale a empezar otro día. Soltar el estado de entrada con seguridad al restaurar.

Aceptación pendiente:

- [ ] Cerrar agarrando una pelota y con monedas pendientes deja la noche y el siguiente día limpios.
- [ ] Reabrir de noche no recupera objetos descartados; ahorro y desbloqueos siguen correctos.
- [ ] Diez ciclos y un cierre repetido no duplican ingresos ni arrastran objetos.
- [ ] Cargar un guardado anterior aplica la política de compatibilidad registrada y conserva el progreso que corresponda.

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
| 2026-10-18 | Planificación | Orden acordado: agarre individual → escoba ampliable → V; monedas y noche conservadas; árbol y balance posteriores | Solo planificación; sin cambios de juego ni OK final |

Para cada implementación añadir commit, pruebas ejecutadas y resultado, revisión manual y pendientes. Registrar el OK del usuario únicamente cuando lo haya dado. Actualizar este plan durante el trabajo; actualizar la documentación general al cierre acordado.
