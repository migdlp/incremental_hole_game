# Plan de cambios — siguiente iteración

Fecha: 17 de octubre de 2026. Estado: planificado. Base revisada: prototipo `0.1.0+1`, código en `main` hasta `c41ca10`.

## Objetivo

Consolidar y verificar una regla acordada: **al pasar del día a la noche desaparecen todas las bolas y monedas que sigan en el tablero. El día siguiente siempre empieza sin bolas ni monedas.**

El dinero ya recogido y no gastado, las mejoras y el progreso se conservan. Las bolas retiradas no generan recompensas; las monedas pendientes no se suman al saldo y su valor se muestra como perdido en el resultado.

## Situación actual

| Elemento | Comportamiento observado | Trabajo de esta iteración |
| --- | --- | --- |
| [GameSession.finishDay](../lib/app/game_session.dart) | Calcula el resultado, banca solo lo recogido y elimina `board` y `cycle` | Mantener este cierre único; comprobar que ningún cambio conserva objetos físicos |
| [GameSession.startDay](../lib/app/game_session.dart) | Construye un `Board` nuevo y reinicia la contabilidad diaria | Verificar explícitamente que empieza con ambas listas vacías |
| [Board](../lib/features/board/domain/board.dart) | Inicializa `balls` y `coins` vacías; genera bolas después del intervalo | No introducir bolas o monedas heredadas ni una recompensa por limpieza |
| [Prueba de diez ciclos](../test/features/game_rules_test.dart) | Comprueba monedas vacías, ingreso, pérdida de pendientes y cierre repetido | Ampliar cobertura explícita de bolas, estado nocturno y restauración |
| Documentación de producto | La retirada de bolas figuraba como propuesta | Formalizarla como regla acordada y enlazar este plan |

La lógica principal ya existe. No se planifica reescribirla si cumple estos criterios; primero se refuerza su evidencia y se corrige únicamente lo que falle.

## Comprobación de partida realizada

Al redactar este plan se ejecutó la prueba existente `ten complete cycles bank once, discard pending and begin clean`: una prueba superada. Comprueba monedas vacías al iniciar cada ciclo, pérdida de pendientes, saldo y cierre repetido. La cobertura explícita adicional de bolas y reapertura nocturna sigue planificada; no se da por realizada por ese resultado.

## Cambios y orden de trabajo

1. **Regla y alcance — documentado en esta planificación.** Alinear PRD y diseño: limpieza obligatoria de bolas y monedas al terminar toda la jornada, incluidos los segundos finales de recogida.
2. **Pruebas de regresión — pendiente.** Añadir o ampliar casos que dejen bolas sin capturar y monedas sin recoger antes del cierre. Comprobar estado nocturno, siguiente día y conservación del ahorro/mejoras.
3. **Persistencia entre jornadas — pendiente.** Guardar después del cierre, cargar una sesión nueva y comprobar que no se recupera el tablero anterior. Repetir con compras nocturnas y luego iniciar el día siguiente.
4. **Corrección condicionada a resultados — pendiente de verificar.** Si una prueba detecta arrastre de objetos, corregir la coordinación de cierre/arranque o la instantánea. No cambiar fricción, balance, recompensa ni generación para resolver una limpieza de estado.
5. **Validación manual y entrega — pendiente.** Revisar la transición en navegador y Android físico, registrar resultado/commit y ejecutar la pipeline manual de APK cuando se entregue código de esta iteración.

## Criterios de aceptación

- [ ] Durante los segundos finales de recogida, el tablero sigue activo y las monedas aún pueden cobrarse.
- [ ] Al agotarse todo el tiempo, la noche no conserva bolas, monedas, pilas ni monedas en aterrizaje del día terminado.
- [ ] Las bolas que no entraron al hoyo desaparecen sin generar dinero.
- [ ] Las monedas pendientes desaparecen sin cobrarse; `lost = generated - collected` conserva su valor en el resumen.
- [ ] El ingreso recogido se banca una sola vez; saldo no gastado y niveles de mejoras permanecen.
- [ ] La instantánea nocturna tiene `run = null` y no contiene un tablero activo de la jornada anterior.
- [ ] Reabrir desde ese guardado nocturno mantiene la noche y no resucita objetos descartados.
- [ ] Iniciar el siguiente día deja `balls` y `coins` vacías antes de que se produzca una nueva emisión normal.
- [ ] La regla se mantiene durante diez ciclos consecutivos y con las mejoras de producción/automatización activas.
- [ ] Cerrar dos veces la misma jornada no vuelve a sumar ingresos ni recrea objetos.

Las casillas son objetivos de verificación de la siguiente iteración; no afirman que todas estas comprobaciones específicas ya se hayan ejecutado.

## Escenarios para las pruebas

| Escenario | Preparación | Resultado esperado |
| --- | --- | --- |
| Bolas sobrantes | Dejar bolas lejos del hoyo y agotar el tiempo | Se retira el tablero; siguiente día sin bolas heredadas |
| Monedas y pilas pendientes | Capturar bolas, dejar parte de las monedas sin recoger | Solo se banca lo cobrado; el resto figura como perdido |
| Moneda en aterrizaje | Capturar una bola inmediatamente antes del final | La recompensa no cobrada también se descarta |
| Reapertura nocturna | Cerrar, esperar a que termine el guardado y cargarlo en otra sesión | `run = null`; nuevo tablero limpio al comenzar |
| Ahorro y mejoras | Conservar saldo, comprar de noche y empezar otro día | Saldo/niveles correctos y cero objetos físicos heredados |
| Robot e imán | Activarlos y alcanzar el final con objetos pendientes | Se detienen con la jornada; no conceden cobros después del límite |

## Pausa y recuperación de errores

Reanudar una jornada interrumpida antes de terminar conserva sus objetos guardados: sigue siendo el mismo día. La regla de tablero vacío se aplica al **nuevo día después de la noche**. Recuperar una copia de seguridad antigua puede retroceder a una jornada anterior al cierre; es una recuperación de progreso, no un arranque de día nuevo. Ver [persistencia](persistencia.md).

## Fuera de esta iteración

No se añaden recompensas por limpieza, almacenamiento de objetos entre días, nuevos tipos de bola, nuevas monedas ni progreso por tiempo cerrado. Audio, presentación del árbol y el resto de tareas del MVP siguen registrados en [estado actual](estado-actual.md); este plan prioriza la transición limpia y su verificación.

## Condición para cerrar la iteración

Completar los criterios anteriores con pruebas de regresión, análisis y formato correctos; registrar el resultado manual y la ejecución de la pipeline de APK. Si falta un dispositivo físico, mantener esa validación marcada como pendiente en lugar de declararla superada.
