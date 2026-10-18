# Plan de cambios — antecedente de la siguiente iteración

**Archivo histórico del 17 de octubre.** El orden y seguimiento vigente están en [agarre, escobas y balance](plan-cambios-agarre-escoba.md); el comportamiento entregado se describe en [estado actual](estado-actual.md). Las tareas y casillas de este documento conservan su estado de planificación original, no indican que esos cambios sigan sin implementar.

Fecha: 17 de octubre de 2026. Estado: planificado. Base revisada: prototipo `0.1.0+1`, código en `main` hasta `c41ca10`.

## Objetivo

Consolidar y verificar una regla acordada: **al pasar del día a la noche desaparecen todas las bolas y monedas que sigan en el tablero. El día siguiente siempre empieza sin bolas ni monedas.**

El dinero ya recogido y no gastado, las mejoras y el progreso se conservan. Las bolas retiradas no generan recompensas; las monedas pendientes no se suman al saldo y su valor se muestra como perdido en el resultado.

Además, implementar la segunda regla confirmada: **al inicio las monedas se recogen pulsando; recogerlas arrastrando por encima requiere comprar la mejora de recogida por barrido**. El toque permanece disponible tras la compra. Las [ideas de herramientas para bolas](ideas-herramientas-bolas.md) son brainstorming y no se implementan por incluirlas en ese documento.

## Situación actual

| Elemento | Comportamiento observado | Trabajo de esta iteración |
| --- | --- | --- |
| [GameSession.finishDay](../lib/app/game_session.dart) | Calcula el resultado, banca solo lo recogido y elimina `board` y `cycle` | Mantener este cierre único; comprobar que ningún cambio conserva objetos físicos |
| [GameSession.startDay](../lib/app/game_session.dart) | Construye un `Board` nuevo y reinicia la contabilidad diaria | Verificar explícitamente que empieza con ambas listas vacías |
| [Board](../lib/features/board/domain/board.dart) | Inicializa `balls` y `coins` vacías; genera bolas después del intervalo | No introducir bolas o monedas heredadas ni una recompensa por limpieza |
| [Prueba de diez ciclos](../test/features/game_rules_test.dart) | Comprueba monedas vacías, ingreso, pérdida de pendientes y cierre repetido | Ampliar cobertura explícita de bolas, estado nocturno y restauración |
| Documentación de producto | La retirada de bolas figuraba como propuesta | Formalizarla como regla acordada y enlazar este plan |

La lógica principal de limpieza ya existe. No se planifica reescribirla si cumple estos criterios; primero se refuerza su evidencia y se corrige únicamente lo que falle.

## Cambio confirmado: pulsación y mejora de barrido

**Situación actual:** el prototipo recoge por toque y arrastre desde el inicio. No existe un desbloqueo de barrido en los ocho tipos del catálogo. El comportamiento nuevo está pendiente, no entregado con este plan.

**Comportamiento objetivo:**

- Sin barrido comprado, pulsar una moneda o pila cobra su valor una sola vez. Arrastrar por encima para empujar bolas no cobra monedas.
- Con barrido comprado, se conserva el toque y se añade la recogida a lo largo de todo el recorrido del dedo, aunque no haya un evento justo sobre la moneda.
- Comprar la mejora descuenta el precio definido y la habilita para el siguiente día; el desbloqueo persiste entre jornadas y al reabrir.
- Barrido, radio e imán son capacidades distintas. Aumentar radio no debe desbloquear barrido por accidente. El imán mantiene su función de atracción/cobro si está comprado; hay que definir y comunicar sus requisitos sin concederlo con barrido ni desactivar silenciosamente compras existentes.

**Decisiones pendientes antes de implementar:** precio, identificador, posición en el árbol y dependencias respecto a radio/imán; criterio de gesto que distingue toque de arrastre; política explícita para partidas antiguas. No se inventan valores de balance aquí. Si el catálogo o la instantánea cambian, revisar la validación del guardado actual y su versión: no perder progreso ni asumir que una partida antigua ya compró el nuevo desbloqueo.

## Comprobación de partida realizada

Al redactar este plan se ejecutó la prueba existente `ten complete cycles bank once, discard pending and begin clean`: una prueba superada. Comprueba monedas vacías al iniciar cada ciclo, pérdida de pendientes, saldo y cierre repetido. La cobertura explícita adicional de bolas y reapertura nocturna sigue planificada; no se da por realizada por ese resultado.

## Cambios y orden de trabajo

1. **Regla y alcance — documentado en esta planificación.** Alinear PRD y diseño: limpieza obligatoria de bolas y monedas al terminar toda la jornada, incluidos los segundos finales de recogida.
2. **Pruebas de regresión — pendiente.** Añadir o ampliar casos que dejen bolas sin capturar y monedas sin recoger antes del cierre. Comprobar estado nocturno, siguiente día y conservación del ahorro/mejoras.
3. **Persistencia entre jornadas — pendiente.** Guardar después del cierre, cargar una sesión nueva y comprobar que no se recupera el tablero anterior. Repetir con compras nocturnas y luego iniciar el día siguiente.
4. **Corrección condicionada a resultados — pendiente de verificar.** Si una prueba detecta arrastre de objetos, corregir la coordinación de cierre/arranque o la instantánea. No cambiar fricción, balance, recompensa ni generación para resolver una limpieza de estado.
5. **Entrada y desbloqueo de barrido — pendiente.** Definir las decisiones anteriores; separar pulsación de arrastre en la entrada y la simulación. Revisar tanto la recogida por segmento como la recogida durante la actualización: mantener el dedo o moverlo no debe seguir cobrando por una vía indirecta sin la mejora. Añadir el desbloqueo al catálogo/CSV, su efecto y explicación en tienda y los mensajes iniciales/tras compra.
6. **Guardado y pruebas de monedas — pendiente.** Persistir el desbloqueo y aplicar una política compatible para guardados existentes. Probar toque/arrastre antes y después, compra, restauración, radio e imán sin cobros dobles. Actualizar documentación de implementación cuando exista el cambio.
7. **Validación manual y entrega — pendiente.** Revisar la transición en navegador y Android físico, registrar resultado/commit y ejecutar la pipeline manual de APK cuando se entregue código de esta iteración.

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

- [ ] Sin barrido, pulsar una moneda/pila cobra todo su valor una vez; arrastrar desde fuera cruzándola no cobra.
- [ ] Arrastrar desde una moneda no se interpreta también como una pulsación de recogida; mantener el dedo no repite cobros.
- [ ] Con barrido comprado, toque y recorrido entre eventos recogen sin saltarse monedas ni duplicar ingresos.
- [ ] La tienda explica el cambio de gesto, respeta precio/requisitos definidos y no permite comprar dos veces el desbloqueo.
- [ ] Compra y efecto persisten tras noche, nuevo día y reapertura; la carga de una partida anterior sigue la política acordada sin perder progreso.
- [ ] Radio e imán respetan sus capacidades y requisitos propios; barrido no concede atracción automática.
- [ ] Los mensajes iniciales enseñan a pulsar; tras desbloquear barrido explican que arrastrar también sirve.

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
| Sin barrido | Pulsar una pila; luego cruzar otra arrastrando desde fuera y desde encima | Solo cobra la pulsación; ni segmento ni actualización conceden el barrido gratis |
| Con barrido | Comprar, comenzar el día y cruzar monedas separadas con eventos de puntero distantes | Cobra cada moneda una vez a lo largo del segmento; pulsar sigue funcionando |
| Recarga y guardado anterior | Reabrir tras comprar y cargar además una instantánea anterior al cambio | Desbloqueo conservado; partida antigua tratada según política documentada |
| Radio e imán | Probar sus combinaciones con/sin barrido según las dependencias definidas | No hay desbloqueos implícitos ni pérdida de funciones compradas |

## Pausa y recuperación de errores

Reanudar una jornada interrumpida antes de terminar conserva sus objetos guardados: sigue siendo el mismo día. La regla de tablero vacío se aplica al **nuevo día después de la noche**. Recuperar una copia de seguridad antigua puede retroceder a una jornada anterior al cierre; es una recuperación de progreso, no un arranque de día nuevo. Ver [persistencia](persistencia.md).

## Fuera de esta iteración

No se añaden recompensas por limpieza, almacenamiento de objetos entre días, nuevos tipos de bola, nuevas monedas ni progreso por tiempo cerrado. Audio, presentación del árbol y el resto de tareas del MVP siguen registrados en [estado actual](estado-actual.md); este plan prioriza la transición limpia y la progresión de toque a barrido, con sus pruebas. No incluye implementar mano, aspiradora, aspas u otras herramientas mientras sigan siendo candidatas sin seleccionar.

## Condición para cerrar la iteración

Completar los criterios anteriores con pruebas de regresión, análisis y formato correctos; registrar el resultado manual y la ejecución de la pipeline de APK. Si falta un dispositivo físico, mantener esa validación marcada como pendiente en lugar de declararla superada.
