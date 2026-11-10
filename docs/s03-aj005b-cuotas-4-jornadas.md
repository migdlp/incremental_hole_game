# S03 / AJ-005B — Cuotas de 4 jornadas, derrota y acceso al prestigio

**Proyecto:** Feed the Hole  
**Estado:** Ready for Development  
**Prioridad:** Alta  
**Dificultad:** Alta  
**Tipo:** Modificación de progresión, supervivencia y prestigio  
**Destino:** Codex

---

## 1. Objetivo

Añadir un plazo máximo de **cuatro jornadas por cada cuota de alimentación**. Para completar una cuota, el jugador debe introducir en el agujero el número requerido de **bolas**, no su valor en monedas.

- Si completa la cuota, el agujero crece un **16 % de área**, se entregan las recompensas correspondientes y se activa **inmediatamente** la cuota siguiente, diez veces mayor.
- La jornada en curso cuenta como la **primera de las cuatro jornadas** de la nueva cuota, incluso si esta se activa al final de la jornada.
- Si la cuarta jornada de una cuota termina sin completarla, el jugador **muere**: aparece directamente **DERROTA**, sin resumen de jornada, y desde ahí accede a la tienda de prestigio P02.
- El número de jornadas disponibles y consumidas se muestra **únicamente en la pantalla de resumen de fin de jornada**. No se muestra durante el gameplay.

Esta especificación **actualiza AJ-005B y S03**: sustituye la versión anterior de cuotas sin vencimiento y restablece la derrota por incumplimiento. No cambia el catálogo ni los precios de P02.

## 2. Progresión de cuotas

| Cuota | Bolas necesarias |
|---|---:|
| 1 | 100 |
| 2 | 1.000 |
| 3 | 10.000 |
| 4 | 100.000 |
| 5 | 1.000.000 |
| 6 | 10.000.000 |
| 7 | 100.000.000 |
| 8 | 1.000.000.000 |
| Siguientes | Objetivo anterior × 10 |

Fórmula: `cuota(n) = 100 × 10^(n - 1)`, con `n >= 1`.

No establecer un número máximo de cuotas por diseño. Utilizar una representación numérica segura para cantidades grandes, sin desbordamiento ni pérdida de precisión en comparaciones, guardado y cálculo de excedentes.

### RF-01 — Qué cuenta como alimentación

- Cada **bola válidamente capturada** aporta exactamente **+1** al progreso de la cuota.
- No influye su tier, valor monetario, variante dorada, multiplicadores, generador de origen o tipo especial, si es una bola capturable.
- Una bola normal de valor 1 y una dorada de valor 500 aportan ambas **una bola**.
- Las monedas visuales, las burbujas de estrellas y las recompensas monetarias **no** alimentan el agujero.
- Alimentar el agujero **no descuenta monedas** del saldo económico.
- Una misma bola solo puede contabilizarse una vez, incluso con capturas masivas, animaciones retrasadas o restauraciones.

## 3. Plazo de cuatro jornadas

### RF-02 — Plazo independiente de cada cuota

La primera cuota comienza en la **jornada 1** de cada nueva partida y vence al **terminar la jornada 4** si sigue incompleta.

El plazo pertenece a la **cuota activa**, no es una cuenta atrás global de cuatro días para toda la partida. No se consume tiempo por pausar, cerrar la aplicación, visitar pantallas o comprar mejoras: solo cuenta el avance real de jornadas.

### RF-03 — Cambio inmediato de cuota

Cuando se alcanza el objetivo de alimentación:

1. Marcar la cuota como completada exactamente una vez.
2. Aplicar su crecimiento de área del 16 %.
3. Generar las recompensas previstas por P01 y, si corresponde, P02 / Lluvia astral.
4. Activar la siguiente cuota (objetivo ×10).
5. Registrar **la jornada actual** como jornada de inicio de esa nueva cuota.
6. Seguir aceptando capturas válidas sin interrupción ni espera al resumen.

La nueva cuota empieza ese mismo día. Por ejemplo, si la cuota 1 se completa durante la jornada 3, la cuota 2 dispone de las jornadas **3, 4, 5 y 6**. La jornada 6 es su última oportunidad.

Si se completa una cuota en el último instante válido de su cuarta jornada, se evita la derrota. La siguiente cuota comienza en esa misma jornada como **día 1 de 4**.

### RF-04 — Varias cuotas en una misma jornada

Se permite completar una o varias cuotas en una misma jornada. Cada cuota debe procesarse individualmente: crecimiento, recompensa, registro de finalización y comienzo de la siguiente. La **última cuota desbloqueada** tendrá como jornada inicial la jornada actual.

Ejemplo: si en la jornada 2 se completan las cuotas 1, 2 y 3, la cuota 4 comienza en la jornada 2 y vence al terminar la jornada 5.

## 4. Progreso acumulado y excedentes

### RF-05 — Persistencia entre jornadas

El progreso de bolas capturadas para la cuota actual se conserva entre jornadas; no se pone a cero hasta completar esa cuota.

Ejemplo: para una cuota de 1.000, capturar 200, 300 y 250 bolas en tres jornadas deja **750/1.000**.

### RF-06 — Excedentes al completar cuotas

Las capturas que excedan el objetivo se trasladan íntegramente a la siguiente cuota, incluso cuando permiten completar más de una.

Ejemplos:

- Progreso **90/100** + 30 bolas → cuota 1 completada; cuota 2 con **20/1.000**.
- Progreso **0/100** + 1.200 bolas → cuota 1 completada (100), cuota 2 completada (1.000) y cuota 3 con **100/10.000**.

Procesar los objetivos en orden y emitir una sola vez cada evento de finalización. No perder bolas ni contabilizarlas por duplicado.

## 5. Crecimiento del agujero (AJ-005A)

### RF-07 — Aumento de área inmediato

Cada cuota completada aumenta el **área** del agujero un **16 % respecto a su área anterior**:

- `área_nueva = área_anterior × 1,16`
- Si es circular, `radio_nuevo = radio_anterior × sqrt(1,16)`.

Actualizar tamaño visual y zona física de captura. El aumento es persistente dentro de la partida y se aplica **exactamente una vez por cuota**.

Si se completan varias cuotas a la vez, aplicar todos los aumentos multiplicativamente. No introducir límites de crecimiento nuevos en esta tarea; respetar la geometría y los límites físicos ya existentes.

## 6. Cierre de jornada y derrota

### RF-08 — Orden obligatorio de operaciones al agotarse el tiempo

Cuando el temporizador normal llega a cero:

1. Cerrar la ventana válida de capturas de la jornada.
2. Finalizar el procesamiento de las capturas **ya confirmadas durante la ventana válida** y cualquier evento correspondiente al instante válido de cierre.
3. Aplicar su alimentación, excedentes, cuotas completadas, crecimientos y recompensas.
4. Determinar la **cuota activa final** y su jornada de inicio.
5. Comprobar si esa cuota sigue incompleta y acaba de finalizar su **cuarta jornada**.
6. Si incumple, registrar DERROTA y mostrarla directamente; si no, entrar en el flujo normal de resumen de jornada.

**No conceder segundos extra.** Las bolas que todavía se mueven fuera del agujero al terminar el tiempo **no cuentan**. No esperar a que caigan ni permitir capturas nuevas fuera de la fase válida para evitar la muerte.

No evaluar la derrota antes de procesar una cuota que se haya completado válidamente en el último instante.

### RF-09 — Condición de derrota

La derrota ocurre **solo al cerrar la cuarta jornada de la cuota activa sin alcanzar su objetivo**. Nunca se produce a mitad de jornada por incumplimiento.

Ejemplo: terminar el día 4 de una cuota de 1.000 con **999/1.000**, aunque sigan moviéndose bolas en el tablero, da lugar a **DERROTA**.

### RF-10 — Pantalla directa de derrota

En caso de derrota:

- Omitir por completo el **resumen normal de fin de jornada**, incluidos sus bloques de monedas y bolas.
- Mostrar directamente una pantalla mínima con **DERROTA**, un mensaje corto de cuota incumplida y un botón para continuar a la tienda de prestigio.
- Terminar definitivamente la partida actual. No permitir reintentar la misma jornada, continuarla ni comprar mejoras normales después de morir.
- No añadir estadísticas extensas ni rediseño gráfico complejo: eso pertenece a tareas de interfaz.

## 7. Acceso a prestigio y compatibilidad con P02 / S03

### RF-11 — Entrada por derrota

Flujo obligatorio:

`Fin de cuarta jornada sin cumplir cuota → DERROTA → Tienda de prestigio P02 → Nueva partida`

La derrota **restablece una segunda vía de entrada** a la tienda, además del prestigio voluntario.

### RF-12 — Progreso conservado y reiniciado

**Conservar entre partidas:**

- Estrellas de prestigio ya obtenidas al romper burbujas.
- Habilidades permanentes de P02 ya compradas.
- Cualquier otro recurso expresamente definido como permanente.

**Reiniciar para la siguiente partida:**

- Jornada (comienza en 1).
- Cuota (vuelve a la 1, de 100 bolas) y su progreso (0).
- Jornada de inicio del plazo (1).
- Crecimiento del agujero propio de la partida.
- Monedas normales y árbol de mejoras normales.
- Contadores temporales de habilidades.
- Objetos físicos y animaciones temporales de la partida anterior.

Las burbujas de estrella **no rotas** se pierden al terminar la partida, incluso si fueron duplicadas por Lluvia astral. No se convierten automáticamente en estrellas.

### RF-13 — Derrota sin estrellas

Se puede acceder a la tienda con **cero estrellas**, examinar las habilidades y comenzar otra partida sin comprar. **No regalar estrellas** por morir o prestigiar.

### RF-14 — Prestigio voluntario

Mantener el prestigio voluntario mediante el nodo especial del árbol normal, con confirmación y reinicio conforme a S03.

**El coste y las condiciones exactas del nodo** siguen pendientes de S03 / BAL01; no inventarlos aquí ni modificar por esta tarea el mecanismo de acceso voluntario ya existente. No exigir esperar a una derrota si el nodo puede utilizarse válidamente.

### RF-15 — Tienda P02 sin cambios de catálogo

Mantener exactamente estas habilidades y precios:

| Habilidad | Efecto | Precio |
|---|---|---:|
| Herencia | 100 monedas iniciales por nueva partida, gastables tras el día 1 | 2 estrellas |
| Eco de producción | 5 bolas extra cada 20 ciclos del generador principal | 6 estrellas |
| Fiebre dorada | 1 bola dorada adicional por jornada | 8 estrellas |
| Lluvia astral | 50 % de probabilidad de duplicar las burbujas físicas de cada cuota | 12 estrellas |

No crear una segunda tienda ni alterar sus reglas de compra, permanencia o persistencia. P02 debe poder abrirse desde **derrota** o **prestigio voluntario**.

## 8. Visualización del plazo: solo resumen

### RF-16 — Prohibición durante gameplay

**No mostrar** durante el gameplay:

- Día X/4 o jornadas restantes de la cuota.
- Cuenta atrás de vencimiento.
- Avisos permanentes de que quedan pocos días.

Puede mantenerse el indicador normal de progreso de **bolas** del agujero si ya existe. El temporizador habitual de producción permanece sin cambios.

### RF-17 — Información en el resumen normal

En las jornadas que terminan **sin derrota**, el resumen debe mostrar:

- Número de la **cuota activa al cerrar la jornada**.
- Progreso actual / objetivo total en **bolas**.
- Barra o indicador visual de progreso, coherente con AJ-008A.
- **Jornada X de 4** de esa cuota.
- **Jornadas futuras restantes** después de la jornada recién cerrada.

Ejemplo ilustrativo:

> CUOTA 2  
> 650 / 1.000 bolas  
> Jornada 3 de 4  
> Queda 1 jornada

Como es una pantalla **posterior** al día jugado:

- Jornada 1 de 4 → quedan 3 futuras.
- Jornada 2 de 4 → quedan 2 futuras.
- Jornada 3 de 4 → queda 1 futura.
- Jornada 4 de 4 sin completar → **DERROTA**, sin resumen.

Si durante la jornada se completa una cuota, el resumen muestra **la nueva cuota**, cuya jornada actual es **1 de 4**. Si se completan varias, mostrar la **última cuota desbloqueada**. Evitar mostrar el plazo o progreso obsoletos de una cuota anterior.

El diseño visual detallado queda en **AJ-008A**.

## 9. Árbol de mejoras normales

Mantener la regla general confirmada en P02: **el árbol de mejoras normales no aparece ni puede abrirse antes de terminar la jornada 1 de cada partida**, tanto en la primera partida como en las posteriores a derrota o prestigio voluntario.

El nodo de prestigio voluntario está sujeto a esta misma restricción, además de sus requisitos propios pendientes.

## 10. Integración con P01 y Lluvia astral

- Cada cuota completada genera inmediatamente sus burbujas físicas de estrellas según P01.
- Si se posee **Lluvia astral**, ejecutar **una tirada independiente del 50 % por cuota completada**.
- Cuando se activa, duplicar **los objetos físicos burbuja**, no abonar directamente el doble de estrellas; cada copia conserva la denominación de su original.
- Las burbujas duplicadas aparecen inmediatamente y siguen todas las reglas de colisión, rotura, expulsión del agujero y persistencia de P01.
- Si se completan varias cuotas a la vez, procesar sus recompensas y tiradas por separado.
- Una burbuja, original o duplicada, solo entrega estrellas al romperse válidamente, exactamente una vez.
- Las burbujas no rotas se pierden al terminar la partida por derrota o prestigio voluntario.

No introducir límites que hagan desaparecer recompensas legítimas: si hay muchas burbujas, optimizar su física y renderizado preservando todas.

## 11. Persistencia y seguridad

### RF-18 — Datos a conservar

Guardar al menos:

- Identificador de cuota activa.
- Objetivo de la cuota.
- Progreso en bolas.
- Jornada de inicio de esa cuota.
- Jornada actual de la partida.
- Cuotas completadas y crecimientos aplicados (o datos equivalentes para prevenir duplicados).
- Estado de la partida y de su flujo de transición: activa, derrota, tienda, nueva partida.

Calcular el día relativo de cuota mediante:

`día_de_cuota = jornada_actual - jornada_de_inicio + 1`

Al comenzar una cuota, fijar `jornada_de_inicio = jornada_actual`. Solo aumentar `jornada_actual` al comenzar la jornada siguiente, sin consumir jornadas adicionales por pausas ni tiempo real fuera del juego.

### RF-19 — Operaciones consistentes

Guardar de forma consistente el cambio de cuota, los excedentes, el crecimiento y sus recompensas, evitando que cierres inesperados provoquen:

- Cuotas completadas dos veces.
- Crecimientos repetidos.
- Duplicación de burbujas o estrellas.
- Pérdida del excedente.
- Derrotas repetidas.
- Reanudación accidental de una partida ya terminada.

Si el juego se cierra durante el flujo **DERROTA → tienda**, restaurar la fase pendiente sin reiniciar dos veces ni perder progreso permanente.

### RF-20 — Migración de guardados anteriores

Examinar el formato de partida guardado antes de introducir el plazo. Conservar las cuotas completadas, los crecimientos ya concedidos y demás recursos.

Para partidas antiguas sin jornada de inicio de cuota, aplicar una migración segura y documentada **sin derrota retroactiva**. No interpretar importes monetarios como número de bolas ni conceder recompensas históricas nuevamente.

## 12. Casos límite

| Caso | Resultado esperado |
|---|---|
| Completar cuota en jornada 1 | Siguiente cuota inmediata; esa misma jornada es su día 1 |
| Completar cuota en el cuarto día | Evita derrota; nueva cuota empieza el mismo día |
| Faltar una bola al cierre del cuarto día | DERROTA |
| Bolas aún moviéndose al agotarse el tiempo | No cuentan si no fueron capturadas válidamente |
| Captura confirmada en el último instante | Procesar antes de comprobar derrota |
| Varias cuotas completadas en una captura masiva | Aplicar todos los crecimientos/recompensas y trasladar excedentes |
| Pausar o cerrar la app | No consumir jornadas adicionales |
| Reabrir tras derrota | Recuperar DERROTA o acceso a P02; no gameplay activo |
| Morir con cero estrellas | Permitir tienda y nueva partida sin comprar |
| Morir con burbujas sin romper | Perder burbujas; conservar estrellas ya cobradas |
| Prestigio voluntario antes del vencimiento | Válido si cumple sus condiciones propias |
| Cantidades de cuota extremadamente grandes | Sin desbordamientos ni errores de precisión |
| Completaciones simultáneas al cierre | Procesar todas antes de evaluar derrota |
| Nueva partida | Cuota 1, 0/100 bolas, jornada 1, plazo iniciado y agujero de tamaño inicial |
| Resumen después de completar cuotas | Mostrar solo la nueva cuota activa y su plazo correcto |

## 13. Criterios de aceptación

### Alimentación, cuotas y crecimiento

1. La primera cuota requiere 100 bolas y cada cuota posterior ×10, sin máximo predefinido.
2. Cada bola válida capturada cuenta exactamente una vez, independientemente de su valor en monedas.
3. El progreso se conserva entre jornadas y los excedentes pasan a la cuota siguiente.
4. Al completar una cuota, la siguiente comienza inmediatamente.
5. Cada cuota tiene cuatro jornadas, contando como primera la jornada en la que se activa.
6. Se pueden completar varias cuotas durante una sola jornada.
7. Cada cuota completada aumenta inmediatamente el área del agujero un 16 %, sin duplicaciones.

### Derrota y prestigio

8. La derrota se evalúa únicamente al cerrar la cuarta jornada de la cuota activa.
9. No se concede tiempo extra por bolas aún moviéndose fuera del agujero.
10. Las capturas confirmadas durante la ventana válida de juego se resuelven antes de evaluar derrota.
11. Completar la cuota en el último instante válido evita la derrota y abre una cuota nueva ese mismo día.
12. Una derrota abre directamente DERROTA, sin resumen normal.
13. Desde DERROTA se accede a la misma tienda de prestigio P02.
14. Se conservan estrellas cobradas y habilidades permanentes; se pierden burbujas sin romper.
15. Se permite acceder a P02 con cero estrellas y continuar sin compras; no se conceden estrellas gratuitas.
16. Se mantiene el prestigio voluntario, sin inventar el coste de su nodo.

### Interfaz y persistencia

17. No se muestra el plazo de cuota durante el gameplay.
18. En resúmenes sin derrota se muestra únicamente el plazo de la **cuota activa**: jornada X/4 y jornadas futuras restantes.
19. El resumen refleja la última cuota desbloqueada si se completan una o varias durante esa jornada.
20. Pausar o cerrar la aplicación no consume jornadas.
21. Guardar y restaurar conserva cuota, progreso, plazo y crecimiento correctos.
22. No se duplican cuotas completadas, recompensas, crecimientos, estrellas ni derrotas.
23. No se puede reanudar como activa una partida ya perdida.
24. El árbol de mejoras normales sigue inaccesible hasta terminar la primera jornada de cada partida.

## 14. Pruebas obligatorias

Ejecutar pruebas de:

- Completar una cuota en las jornadas 1, 2, 3 y 4.
- Cerrar el cuarto día con 99/100 y con 100/100 ya confirmadas.
- Capturar la última bola durante el último instante válido.
- Finalizar el tiempo con bolas aún moviéndose por el tablero.
- Capturar 30 bolas desde 90/100 y 1.200 desde 0/100.
- Completar dos o tres cuotas en una jornada y justo al cierre.
- Aplicar varios crecimientos de área del 16 % y restaurarlos.
- Cerrar/reabrir en el tercer o cuarto día y durante DERROTA.
- Prestigiar con cero estrellas, con estrellas y con burbujas sin romper.
- Completar varias cuotas con Lluvia astral activa y verificar tiradas separadas.
- Mostrar resumen con nueva cuota y plazo correcto, sin contador durante gameplay.
- Abrir una nueva partida y comprobar cuota 1, día 1, reinicio temporal y conservación de mejoras permanentes.
- Migrar una partida anterior sin provocar derrota retroactiva o recompensas duplicadas.

Verificar regresiones entre **gameplay, cierre de jornada, resumen, DERROTA, tienda P02 y nueva partida**.

## 15. Dependencias

- **AJ-005A:** crecimiento del agujero en un 16 % de área por cuota.
- **AJ-005B:** cuotas infinitas por cantidad de bolas capturadas.
- **S03:** reinicio y prestigio voluntario.
- **P01:** burbujas físicas de estrellas y cobro por rotura.
- **P02:** tienda permanente de prestigio y habilidades ya definidas.
- **AJ-008A:** contenido y presentación del resumen de jornada.
- Temporizador, sistema de captura, eventos de fin de jornada y persistencia.
- **BAL01:** estudio de dificultad, producción y progresión.

## 16. Fuera de alcance

No implementar en esta tarea:

- Nuevas habilidades o precios de P02.
- Rediseño completo de DERROTA, resumen o tienda de prestigio.
- Nuevas causas de muerte ni segundas oportunidades.
- Cambios en duración normal de jornada.
- Cambios en economía monetaria o tipos de bolas.
- Coste y condiciones definitivas del nodo de prestigio voluntario (pendientes de S03/BAL01).
- Nuevas reglas de generación de estrellas distintas de P01 / P02.

## 17. Notas para Codex

1. Auditar la implementación actual de cuotas, captura de bolas, temporizador, cierre de jornada, prestigio y guardados.
2. Sustituir la lógica «sin límite de jornadas» por la jornada de inicio por cuota y el vencimiento al cerrar su cuarto día.
3. Mantener contabilidad independiente de bolas y dinero.
4. Procesar capturas, excedentes y cuotas múltiples antes de evaluar derrota.
5. Mantener el crecimiento AJ-005A y las recompensas P01 / Lluvia astral sin duplicaciones.
6. Incorporar la nueva vía de entrada a P02 desde DERROTA, reutilizando la tienda y persistencia existentes.
7. Mostrar el plazo solo en el resumen de jornada, sin añadir ningún contador al gameplay.
8. Implementar y probar transiciones/guardado consistentes, incluidas las partidas antiguas.
9. No cambiar el coste del prestigio voluntario ni el catálogo P02.

---

## Resultado esperado

El jugador debe alimentar el agujero con un objetivo de bolas que se multiplica por diez después de cada cuota. Tiene **cuatro jornadas por cuota**; si completa una, la siguiente se activa inmediatamente y la jornada actual ya cuenta como su primer día. Si termina el cuarto día sin conseguirlo, pasa **directamente a DERROTA** y desde ahí a la tienda de prestigio. La información del plazo solo se muestra en el **resumen normal de fin de jornada**. El progreso permanente sobrevive, mientras el progreso de la partida se reinicia.

**ESTADO FINAL: READY FOR DEVELOPMENT.**
