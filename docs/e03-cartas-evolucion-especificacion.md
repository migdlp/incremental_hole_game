# E03 — Sistema de cartas de evolución permanente

**Proyecto:** Feed the Hole  
**ID:** E03  
**Título:** Cartas de evolución permanente: selección por cuota y 12 habilidades de 5 niveles  
**Estado:** Ready for Development  
**Prioridad:** Media  
**Dificultad:** Alta  
**Destino:** Codex

---

## 1. Objetivo

Implementar un sistema de elecciones de habilidades mediante cartas cada vez que el jugador complete una cuota de alimentación del agujero.

- Cada cuota completada concede **una elección** entre **hasta 3 cartas distintas**, elegidas aleatoriamente del catálogo elegible.
- Al seleccionar una carta, la habilidad correspondiente se adquiere o sube **exactamente un nivel**, con un máximo de **5 niveles por habilidad**.
- Los niveles de las habilidades son **permanentes**, incluso tras morir o prestigiar. En cambio, sus contadores de activación, efectos activos y recargas son propios de cada partida.
- Existen exactamente **12 habilidades** para esta primera versión, repartidas entre agujero, física, producción y economía.
- E03 es **independiente de P02**: no utiliza estrellas, no cuesta monedas y no reemplaza las cuatro habilidades de la tienda de prestigio.

La especificación describe el **balance inicial aprobado**. Un eventual ajuste posterior de valores pertenece a BAL01 y no bloquea la implementación.

## 2. Activación y secuencia de elección

### RF-01 — Una elección por cuota completada

La elección se obtiene **cada vez** que se supera una cuota, incluso si es una cuota que el jugador ya había completado en una partida anterior (por ejemplo, la cuota de 100 bolas tras prestigiar).

No conceder elecciones por capturas aisladas, por terminar una jornada sin completar cuota ni por entrar en la tienda P02.

### RF-02 — Pausa y orden de operaciones

Al completar una o varias cuotas:

1. Contabilizar las capturas válidas y los excedentes según AJ-005B.
2. Registrar **todas** las cuotas completadas en ese evento, aplicando por separado el crecimiento de AJ-005A, las recompensas de P01 y, cuando corresponda, las tiradas de Lluvia astral (P02).
3. Registrar **una elección de E03 pendiente por cada cuota** completada.
4. Pausar **producción, física y temporizadores de gameplay** y abrir el selector de cartas.
5. Resolver una elección cada vez, sin reanudar la partida entre elecciones consecutivas.
6. Reanudar el gameplay cuando no queden elecciones pendientes, **salvo que la jornada ya haya terminado**, en cuyo caso continuar con el cierre de jornada correspondiente.

No interrumpir una operación de captura o reparto de excedentes a mitad del procesamiento para abrir cartas. Las burbujas físicas de P01 pueden estar ya generadas al mostrarse el selector, pero permanecen congeladas mientras el juego está pausado.

### RF-03 — Sorteo de opciones

- Cada selección muestra **3 habilidades distintas** entre las que estén por debajo del nivel 5.
- No pueden aparecer dos cartas de la misma habilidad en una misma selección.
- Las habilidades al nivel 5 **no** participan en el sorteo.
- Cuando queden solo 2 habilidades elegibles, se muestran 2 cartas; si queda 1, se muestra 1.
- Cuando todas las habilidades alcancen el nivel 5, **no se abre el selector**, y las elecciones que corresponderían a cuotas posteriores se consumen sin premio sustitutorio. Las cuotas siguen entregando sus demás efectos y recompensas.
- El sorteo se hace de nuevo para cada elección consecutiva, después de aplicar el nivel seleccionado en la elección anterior.
- Como balance inicial, seleccionar aleatoriamente entre las habilidades elegibles sin pesos diferenciados; no introducir rarezas o probabilidades especiales no definidas.

### RF-04 — Selección inmediata

- Tocar una carta **confirma y aplica inmediatamente** la elección; no hay botón de confirmación.
- Una selección solo puede resolver **una** carta, aunque se produzcan toques repetidos o casi simultáneos.
- Guardar la actualización antes de permitir otra elección o reanudar la partida.
- No existe opción de descartar, vender, intercambiar o deshacer una carta.

### RF-05 — Presentación funcional

Mostrar una ventana/modal encima del tablero con juego pausado. Cada carta incluye únicamente:

- Nombre de la habilidad.
- Descripción breve de su comportamiento.
- Nivel actual y nivel al que pasará al elegirla (por ejemplo, «Nivel 2 → 3»; para habilidades nuevas, «Nivel 0 → 1»).

**No mostrar cifras detalladas de bonificaciones, cálculos, tablas de niveles ni porcentajes exactos en las cartas.** Los valores deben aplicarse correctamente en la lógica interna. El diseño gráfico definitivo pertenece a AJ-008; en E03 basta con una interfaz clara y funcional.

### RF-06 — Partida terminada al mismo tiempo

Si se alcanza una cuota mediante capturas válidas del último instante de una jornada:

- Procesar primero cuotas, recompensas y elecciones pendientes.
- Mostrar las cartas con el gameplay pausado.
- Al concluir las elecciones, **no reabrir la ventana de capturas** ni conceder tiempo extra.
- Continuar hacia el resumen normal o la derrota, según las reglas de S03/AJ-005B. Una cuota completada a tiempo evita la derrota de esa cuota.

Si hay derrota por no completar la cuota en la cuarta jornada, no se genera una elección inexistente, y se muestra directamente DERROTA sin resumen.

## 3. Catálogo y parámetros de balance aprobados

Todos los efectos se aplican al **nivel actual permanente** de la habilidad. Solo hay 5 niveles. Una subida añade **un nivel**, no toda la progresión de golpe.

### E03-01 — Remolino (agujero)

**Activación:** capturar al menos **10 bolas en una ventana móvil de 3 segundos** de producción activa.  
**Efecto:** atraer físicamente hacia el agujero a las bolas situadas dentro de su alcance, durante **2 segundos**.  
**Recarga:** **10 segundos**, una vez concluida la activación.  
**Fuerza de atracción:** constante, con magnitud inicial equivalente al **40 % de la gravedad normal**; los niveles solo modifican el alcance.

| Nivel | Alcance desde el agujero |
|---|---|
| 1 | 1,5 × radio actual |
| 2 | 1,75 × radio actual |
| 3 | 2 × radio actual |
| 4 | 2,25 × radio actual |
| 5 | 2,5 × radio actual |

La fuerza debe aplicarse a las bolas físicas hacia el centro del agujero, sin teletransportarlas ni considerarlas capturadas automáticamente. No afecta a monedas visuales ni burbujas de estrellas de P01.

### E03-02 — Hambre insaciable (agujero)

**Activación:** cada **25 capturas válidas** contabilizadas para esta habilidad fuera de su recarga.  
**Efecto:** aumentar temporalmente el **radio** del agujero durante **4 segundos**.  
**Recarga:** **12 segundos** tras acabar el efecto.

| Nivel | Radio temporal adicional |
|---|---|
| 1 | +4 % |
| 2 | +6 % |
| 3 | +8 % |
| 4 | +10 % |
| 5 | +12 % |

Calcular el radio efectivo multiplicando el **radio base actual** (incluidos los crecimientos permanentes de cuota de AJ-005A) por `1 + bonus_temporal`. Si se completa otra cuota y el agujero crece mientras el efecto está activo, conservar el aumento permanente y aplicar sobre él el modificador temporal. Al expirar, **retirar solo el modificador temporal**, sin encoger indebidamente el agujero.

### E03-03 — Latido (agujero)

**Activación:** cada **20 segundos de producción activa**.  
**Efecto:** pulso instantáneo que impulsa las bolas dentro de un alcance de **3 veces el radio actual del agujero** hacia su centro.

| Nivel | Magnitud de impulso respecto a la velocidad estándar de lanzamiento |
|---|---|
| 1 | 5 % |
| 2 | 10 % |
| 3 | 15 % |
| 4 | 20 % |
| 5 | 25 % |

No teletransportar bolas. No impulsar monedas ni burbujas físicas de estrellas. El contador de tiempo continúa entre jornadas de una misma partida y se reinicia al empezar una partida nueva.

### E03-04 — Rebote dirigido (física)

**Activación:** al producirse un rebote válido de una bola contra una pared del tablero.  
**Efecto:** sortear una probabilidad de dirigir parcialmente el rebote hacia el agujero.

| Nivel | Probabilidad por choque con pared |
|---|---|
| 1 | 10 % |
| 2 | 20 % |
| 3 | 30 % |
| 4 | 40 % |
| 5 | 50 % |

En los rebotes exitosos, ajustar **un 25 % de la dirección del movimiento resultante** hacia el agujero y normalizar el vector para preservar la magnitud de velocidad del rebote. No garantizar la captura. Solo afecta a bolas; no modifica la física de P01.

### E03-05 — Bola ariete (física/producción)

**Activación:** tras un número determinado de **ciclos normales** del generador principal.  
**Efecto:** generar **1 bola adicional** con **3 veces la masa** normal de su tier, pero con tamaño y valor económico normales según las características vigentes del generador.

| Nivel | Aparece una bola ariete cada... |
|---|---|
| 1 | 50 ciclos |
| 2 | 45 ciclos |
| 3 | 40 ciclos |
| 4 | 35 ciclos |
| 5 | 30 ciclos |

La bola ariete participa en la física, empuja a otras bolas, puede ser capturada y cuenta **+1** para las cuotas. Su masa no multiplica las monedas. Se origina en el generador principal; el disparo adicional **no cuenta como ciclo normal**.

### E03-06 — Gravedad traviesa (física)

**Activación:** cada **30 segundos de producción activa**.  
**Efecto:** durante **2 segundos** aplicar a todas las bolas una atracción gravitatoria adicional dirigida hacia el centro del agujero.

| Nivel | Aceleración adicional respecto a la gravedad normal |
|---|---|
| 1 | 5 % |
| 2 | 10 % |
| 3 | 15 % |
| 4 | 20 % |
| 5 | 25 % |

**No inclinar aleatoriamente la gravedad global:** la habilidad debe favorecer siempre la aproximación al agujero. No modificar la gravedad permanente ni afectar a burbujas de P01 o monedas visuales. Puede coexistir con Remolino y Latido, sumando fuerzas de manera estable y sin capturas automáticas.

### E03-07 — Disparo frenético (producción)

**Efecto pasivo:** aumentar los **ciclos normales por segundo** del generador principal mientras produce.

| Nivel | Velocidad adicional |
|---|---|
| 1 | +4 % |
| 2 | +8 % |
| 3 | +12 % |
| 4 | +16 % |
| 5 | +20 % |

Aplica inmediatamente al subir de nivel. No afecta a generadores secundarios ni al lanzador adicional M03.

### E03-08 — Último esfuerzo (producción)

**Efecto pasivo condicionado:** acelerar el generador principal durante el **último 25 % del intervalo de producción de cada jornada**.

| Nivel | Velocidad adicional en ese tramo |
|---|---|
| 1 | +10 % |
| 2 | +15 % |
| 3 | +20 % |
| 4 | +25 % |
| 5 | +30 % |

Combinar con Disparo frenético **sumando puntos porcentuales** sobre la velocidad que resulte de las mejoras normales del generador, no multiplicando las bonificaciones E03 entre sí.

Ejemplo con ambas al nivel 5: `velocidad_normal_mejorada × (1 + 0,20 + 0,30) = velocidad_normal_mejorada × 1,50` durante el tramo final; fuera de él, solo +20 %.

### E03-09 — Doble ración (producción)

**Activación:** cada cierto número de **ciclos normales** del generador principal.  
**Efecto:** producir **1 bola adicional** siguiendo características y probabilidades actuales del generador.

| Nivel | Bola adicional cada... |
|---|---|
| 1 | 40 ciclos |
| 2 | 35 ciclos |
| 3 | 30 ciclos |
| 4 | 25 ciclos |
| 5 | 20 ciclos |

La bola adicional puede ser normal, dorada o de un tipo especial si así lo determinan las probabilidades vigentes. Cuenta +1 para las cuotas cuando se capture y genera las monedas correspondientes. **No incrementa los contadores de ciclos**, evitando recursividad.

### E03-10 — Racha millonaria (economía)

**Activación:** capturar **10 bolas en una ventana móvil de 3 segundos**.  
**Efecto:** multiplicar las **monedas** de las capturas por **×2** o **×3**, según el nivel, durante el tiempo indicado.  
**Recarga:** **10 segundos tras finalizar el efecto**; durante ella las capturas no preparan otra activación.

| Nivel | Duración | Multiplicador de monedas |
|---|---|---|
| 1 | 3 segundos | ×2 |
| 2 | 6 segundos | ×2 |
| 3 | 7 segundos | ×2 |
| 4 | 8 segundos | ×3 |
| 5 | 10 segundos | ×3 |

Reglas obligatorias:

- **La décima bola que activa la racha YA recibe** el multiplicador.
- Mostrar un pequeño indicador **«×2» o «×3» junto al agujero** mientras el efecto esté activo; no añadir un contador fijo al HUD.
- Procesar capturas simultáneas **individualmente y en un orden estable**. Ejemplo: si faltan dos capturas para activar la racha y llegan diez en el mismo instante, las dos primeras completan el requisito; la segunda de ellas y las ocho restantes reciben el multiplicador.
- **Nunca conceder fracciones de monedas.** Los multiplicadores son enteros.
- Durante la recarga, las capturas no se acumulan hacia la siguiente activación; después se inicia una ventana de capturas nueva.
- Si la habilidad sube de nivel mientras una racha está activa, esa activación conserva sus parámetros anteriores; el nivel nuevo se aplica desde la siguiente activación.
- Multiplica las monedas ganadas, **no** la cantidad de bolas que cuenta para las cuotas ni las estrellas de P01.

### E03-11 — Toque de Midas (economía)

**Efecto pasivo:** aumentar la probabilidad **natural** del generador principal de producir bolas doradas, en **puntos porcentuales absolutos**.

| Nivel | Probabilidad dorada adicional |
|---|---|
| 1 | +0,5 puntos porcentuales |
| 2 | +1 punto porcentual |
| 3 | +1,5 puntos porcentuales |
| 4 | +2 puntos porcentuales |
| 5 | +2,5 puntos porcentuales |

Sumar a la probabilidad actual, con límite máximo del 100 %. No modificar la bola dorada diaria **garantizada** por Fiebre dorada de P02. No añadir por sí mismo un nuevo ciclo ni una bola garantizada.

### E03-12 — Golpe de suerte (economía)

**Activación:** tirada independiente por cada bola capturada.  
**Efecto:** si tiene éxito, añadir una recompensa monetaria extra **igual al valor monetario base de esa captura**, de modo que se duplica su valor antes de otras bonificaciones económicas.

| Nivel | Probabilidad por captura |
|---|---|
| 1 | 1 % |
| 2 | 2 % |
| 3 | 3 % |
| 4 | 4 % |
| 5 | 5 % |

No generar bolas adicionales, estrellas ni unidades de alimentación extra. La recompensa se calcula con monedas enteras.

## 4. Interacciones entre habilidades y sistemas

### RF-07 — Contadores de producción

- Cada **ciclo normal real** del generador principal cuenta como una unidad en los contadores independientes de **Bola ariete, Doble ración y Eco de producción (P02)**.
- Los tres efectos pueden dispararse en el mismo ciclo: producir todas las bolas correspondientes, sin cancelar ninguna.
- Las bolas adicionales de estos efectos y la bola dorada diaria garantizada de Fiebre dorada (P02) **no generan ciclos** ni activaciones recursivas.
- Las bolas adicionales respetan física, alimentación, economía y variantes aplicables, según el efecto que las genera.
- No aplicar estos efectos al lanzador secundario u otros generadores no principales.

### RF-08 — Velocidad del generador

Disparo frenético y Último esfuerzo se suman sobre la velocidad actual debida a las mejoras **normales**. No multiplicar entre sí sus bonificaciones porcentuales. La mayor velocidad genera más ciclos reales y, por tanto, puede acelerar legítimamente el progreso de los contadores por ciclos.

### RF-09 — Fuerzas físicas

Remolino, Latido y Gravedad traviesa pueden coincidir. Sus fuerzas/impulsos se combinan mediante la física sin teletransporte ni concesión de capturas automáticas. No aplicarlos a monedas visuales ni burbujas físicas de estrellas.

Rebote dirigido se evalúa en los choques con paredes de bolas, de manera independiente.

### RF-10 — Tamaño del agujero

El bonus temporal de Hambre insaciable es **multiplicativo sobre el radio base actual del agujero**, que ya incorpora los crecimientos permanentes por cuota. Nunca sustituir ni sobrescribir el radio base, para no perder crecimientos cuando el bonus desaparezca.

### RF-11 — Economía y enteros

Para una captura que pueda verse afectada por ambas habilidades económicas:

1. Calcular el valor monetario base de la bola con la economía normal.
2. Resolver **Golpe de suerte** y, si se activa, añadir otra cantidad igual al valor base.
3. Si Racha millonaria está activa (incluida la captura que la activa), aplicar el multiplicador entero ×2 o ×3 al subtotal.
4. Registrar el total final de **monedas enteras** en el saldo y reflejarlo correctamente en la economía y la visualización de AJ-009.

Ejemplo: valor base 7 monedas, Golpe de suerte se activa, Racha ×3 activa: `(7 + 7) × 3 = 42 monedas`. La captura cuenta **una sola bola** para cuota.

No introducir redondeos por monedas fraccionarias ni bonificaciones monetarias porcentuales en Racha millonaria.

### RF-12 — Compatibilidad con P02 y P01

- Los niveles de E03 no cuestan estrellas ni sustituyen habilidades de P02.
- Eco de producción coexiste con Bola ariete y Doble ración.
- Fiebre dorada coexiste con Toque de Midas sin que este altere la bola diaria garantizada.
- Lluvia astral se evalúa por cada cuota completada, con independencia de la concesión de una carta E03.
- Las burbujas de P01 conservan su física y reglas propias; las fuerzas nuevas de E03 no deben alterarlas.

## 5. Temporizadores, niveles y cambios de jornada

### RF-13 — Tiempo efectivo

Los temporizadores de activación, ventanas de 3 segundos, duraciones y recargas avanzan **solo durante producción activa**. No avanzan durante:

- Pausa manual.
- Selector de cartas.
- Resúmenes de jornada.
- Tienda de mejoras.
- Transiciones fuera del gameplay.
- Tiempo real con la aplicación cerrada.

### RF-14 — Enfriamientos

Para Remolino, Hambre insaciable y Racha millonaria:

- No acumular nuevas capturas de activación durante el efecto ni durante el enfriamiento.
- Al finalizar el enfriamiento, comenzar un seguimiento nuevo.
- Una captura masiva no puede disparar múltiples activaciones del mismo efecto en el mismo instante.
- No reactivar un efecto mientras ya esté activo.

### RF-15 — Cierre de jornada

Cuando termina la fase de producción:

- **Cancelar los efectos temporales que todavía estén activos**; no trasladar el efecto físico o multiplicador a la jornada siguiente.
- Conservar **los contadores acumulados** y **las recargas pendientes** entre jornadas de una misma partida.
- Si un efecto temporal se cancela anticipadamente por cierre de jornada, comenzar/mantener la recarga correspondiente para que no pueda reactivarse gratuitamente al inicio del día siguiente.
- Las ventanas de rachas basadas en los últimos 3 segundos no pueden incorporar capturas de jornadas distintas.

### RF-16 — Subida de nivel con efecto activo

- Para habilidades **pasivas** (por ejemplo, Disparo frenético o Toque de Midas), aplicar el nivel nuevo inmediatamente tras elegir.
- Si una habilidad está ejecutando un **efecto temporal**, mantener los parámetros con los que empezó la activación hasta que concluya; aplicar el nuevo nivel en la siguiente activación.
- Los contadores basados en ciclos (Bola ariete y Doble ración) **conservan el avance acumulado** al subir de nivel. Evaluar el umbral nuevo en el siguiente ciclo normal; permitir **como máximo una activación inmediata** por ese cambio, ajustando correctamente el remanente para no duplicar disparos.
- Los niveles y los parámetros efectivos de activaciones vigentes deben ser consistentes al guardar y restaurar.

### RF-17 — Reinicio de partida

Al morir o prestigiar:

- **Conservar** permanentemente los niveles de las 12 habilidades.
- **Reiniciar** contadores de ciclos y capturas, ventanas de racha, temporizadores, efectos activos y recargas de la partida anterior.
- Aplicar los niveles conservados desde el comienzo de la siguiente partida, respetando las reglas generales del gameplay.

## 6. Persistencia, cierre de aplicación y operaciones seguras

### RF-18 — Datos permanentes

Persistir los niveles de las 12 habilidades (0–5), separadamente del estado temporal de partida y del progreso permanente de P02. Un jugador nuevo comienza con las doce habilidades en **nivel 0**.

### RF-19 — Datos temporales

Conservar durante una misma partida, incluso al pasar entre jornadas o cerrar/reabrir la aplicación:

- Contadores parciales de ciclos y capturas.
- Tiempo de producción acumulado aplicable a Latido y Gravedad traviesa.
- Recargas restantes y parámetros de activaciones vigentes.
- Datos necesarios para evitar reactivaciones duplicadas.
- Identificadores de cuotas procesadas y elecciones pendientes de E03.

Aplicar la lógica de cierre de jornada de RF-15 si se restaura el juego en un estado posterior al fin de la producción.

### RF-20 — Selección persistente y sin re-sorteos

Al crear una elección, guardar las cartas **concretas** ofrecidas y su orden, así como el número de elecciones restantes.

Si la aplicación se cierra durante una selección:

- Volver al mismo selector.
- Mostrar las mismas opciones.
- No sortear nuevas cartas gratuitamente.
- No perder ni duplicar elecciones.
- Mantener el tablero pausado.

La aceptación de una carta, la subida de nivel y el avance a la siguiente elección deben registrarse de manera **atómica/idempotente** para impedir dobles niveles por toques repetidos, cierres inesperados o restauraciones.

### RF-21 — Procesamiento seguro de cuotas

Una cuota completa debe generar **una sola** recompensa de E03. Ante eventos repetidos, reintentos de guardado o captura masiva, usar la identidad del evento/cuota para impedir elecciones, niveles, recompensas de P01 o crecimientos duplicados.

### RF-22 — Migración

Los guardados previos sin sistema E03 deben inicializar las 12 habilidades a nivel 0 **sin modificar** estrellas, habilidades P02, monedas, cuota actual o crecimientos ya obtenidos. No conceder cartas retroactivas por cuotas históricas, salvo que existiera una elección pendiente registrada en un nuevo guardado E03.

## 7. Interfaz y experiencia de usuario

- Selector modal sobre tablero congelado con título orientativo «¡ELIGE UNA MEJORA!».
- Hasta tres cartas visibles, sin repetidos, con **nombre, descripción y nivel actual → siguiente**; **sin cifras exactas de mejoras** en las cartas.
- Selección en **un solo toque**, sin confirmación adicional.
- Feedback visible de selección y avance a siguiente elección pendiente; impedir interacciones simultáneas.
- Si queda una sola carta elegible, mostrarla y exigir su selección para resolver la elección.
- Si no queda ninguna elegible, no abrir un selector vacío.
- Racha millonaria: mostrar «×2» o «×3» junto al agujero mientras está activa; ocultarlo al terminar o cerrar la jornada.
- No introducir un nuevo indicador permanente de enfriamientos ni un nuevo HUD extenso.
- Los detalles de estética, ilustraciones, animaciones elaboradas y diseño final de cartas quedan para AJ-008.

## 8. Casos límite que deben contemplarse

1. **Una cuota repetida después de prestigiar:** vuelve a conceder una elección.
2. **Dos o más cuotas completadas de golpe:** primero procesar todas sus recompensas y crecimientos; luego realizar exactamente una elección por cuota, consecutivamente.
3. **Subida al nivel 5 en primera elección:** esa habilidad desaparece de las siguientes elecciones pendientes.
4. **Menos de tres cartas elegibles:** mostrar solo las restantes.
5. **Todo al nivel 5:** omitir selector, sin recompensa sustitutoria, sin bloquear progresión de cuotas.
6. **Toques múltiples en una carta:** una sola subida de nivel.
7. **Cierre de aplicación en selector:** restaurar exactamente las opciones y elecciones restantes.
8. **Cierre durante la actualización de nivel:** no consumir elección sin habilidad ni adquirir nivel dos veces.
9. **Cumplimiento de cuota en último instante válido de producción:** seleccionar cartas antes de resumen; no extender la jornada.
10. **Derrota por cuota incumplida:** no conceder carta si la cuota no se completó; mantener niveles anteriores.
11. **Racha con muchas capturas simultáneas:** procesar cada captura en orden estable; la décima y posteriores de la ráfaga reciben el bonus.
12. **Racha durante recarga:** ignorar capturas para su reactivación.
13. **Fin de jornada con efecto temporal:** detener efecto, conservar/activar recarga y mantener contadores compatibles.
14. **Hambre insaciable + crecimiento de cuota:** no perder el crecimiento permanente cuando termina la expansión temporal.
15. **Varios efectos del generador en un mismo ciclo:** generar todos sus extras; los extras no cuentan como ciclos.
16. **Golpe de suerte con Racha:** resolver en orden y conceder solo monedas enteras.
17. **Bola ariete o extra dorada:** cuenta una única bola para la alimentación tras ser capturada, independientemente de su valor.
18. **Pausa prolongada, cierre o reapertura:** no consumir temporizadores de producción, efecto ni recarga.
19. **Valores físicos extremos al acumular poderes:** evitar inestabilidad, NaN y duplicidades, sin eliminar recompensas válidas arbitrariamente.
20. **Subida de una carta pasiva durante producción:** usar inmediatamente el nuevo nivel después de confirmar la elección.

## 9. Criterios de aceptación

### Sistema de cartas

- [ ] Cada cuota completada concede una elección, también después de prestigiar o morir.
- [ ] Cada elección ofrece tres habilidades distintas al azar si existen al menos tres elegibles.
- [ ] Las habilidades al nivel 5 no aparecen y nunca superan ese nivel.
- [ ] Si quedan dos o una, se muestran solo esas; con cero, el selector se omite.
- [ ] Tocar una carta incrementa un solo nivel sin confirmación adicional ni dobles selecciones.
- [ ] Las cartas muestran nombre, descripción y nivel, sin parámetros numéricos detallados.
- [ ] Varias cuotas simultáneas producen elecciones consecutivas tras procesar todas las recompensas y crecimientos.
- [ ] El gameplay permanece pausado durante toda la secuencia.

### Habilidades

- [ ] Las doce habilidades están implementadas conforme a sus cinco tablas de niveles.
- [ ] Remolino, Hambre insaciable y Latido actúan según sus activadores, intensidades, duraciones y alcances.
- [ ] Rebote dirigido respeta sus probabilidades; Bola ariete mantiene triple masa sin multiplicar ingresos; Gravedad traviesa atrae hacia el agujero.
- [ ] Disparo frenético y Último esfuerzo se suman correctamente; Doble ración genera extras sin aumentar ciclos.
- [ ] Racha millonaria respeta **3/6/7/8/10 s** y **×2/×2/×2/×3/×3**, incluyendo la captura activadora.
- [ ] El indicador ×2 o ×3 aparece únicamente mientras la racha funciona.
- [ ] Toque de Midas aumenta solo las probabilidades naturales de bolas doradas.
- [ ] Golpe de suerte duplica ocasionalmente el valor base conforme al nivel.
- [ ] Las bonificaciones económicas generan exclusivamente monedas enteras.
- [ ] La activación simultánea con P02 no produce ciclos recursivos ni duplicación de cuotas.

### Temporizadores y persistencia

- [ ] Los temporizadores avanzan solo durante producción activa.
- [ ] Las capturas durante enfriamiento no preparan nuevas activaciones.
- [ ] Los efectos temporales terminan al cerrar jornada; los contadores y recargas se mantienen correctamente entre jornadas.
- [ ] Los parámetros de un efecto en marcha no cambian al subir su nivel; los pasivos sí cambian inmediatamente.
- [ ] Los contadores de ciclos se conservan al subir nivel y no producen ráfagas duplicadas.
- [ ] Los 12 niveles sobreviven a muerte, prestigio y cierre/reapertura.
- [ ] Los contadores y recargas propios de un run se reinician al iniciar otro.
- [ ] Un selector pendiente reaparece con las mismas opciones tras restaurar una partida.
- [ ] Nunca se duplica una recompensa de carta ni se pierde una selección ya generada.

## 10. Pruebas recomendadas

- Completar una cuota por primera vez y completarla de nuevo después de prestigiar.
- Completar simultáneamente 2–3 cuotas y comprobar tres elecciones distintas, secuenciales.
- Llevar una habilidad de nivel 4 a 5 y verificar su exclusión del sorteo siguiente.
- Maximizar las 12 habilidades y comprobar ausencia de selectores vacíos.
- Restaurar una selección tras cerrar aplicación; repetir toques rápidos; interrumpir un guardado.
- Capturar 10 bolas en 3 s, verificar que la décima cobra bonus, probar ráfagas simultáneas y recargas.
- Comprobar la duración y multiplicador de Racha en los cinco niveles y el texto ×2/×3.
- Coincidencia de Golpe de suerte + Racha con valor base impar, comprobando enteros.
- Subir Hambre insaciable con el efecto activo, completar una cuota que agrande el agujero y validar el radio resultante al concluir.
- Coincidencia de Remolino + Latido + Gravedad traviesa sin afectar P01.
- Coincidencia de Bola ariete + Doble ración + Eco P02 en el mismo ciclo.
- Comprobar que Fiebre dorada P02 y Toque de Midas no se sustituyen mutuamente.
- Pausar y reanudar varias veces durante efectos y recargas; cambiar de jornada; reiniciar por derrota o prestigio.
- Completar cuota en el último instante válido de la cuarta jornada y verificar que no se produce derrota errónea.
- Ejecutar pruebas de rendimiento con alta concentración de bolas y efectos físicos simultáneos.

## 11. Dependencias

- **AJ-005B / S03:** cuotas, excedentes, cuatro jornadas y derrota.
- **AJ-005A:** crecimiento del agujero tras completar cuotas.
- **P01:** burbujas de estrellas y sus reglas físicas.
- **P02:** tienda permanente, Eco de producción, Fiebre dorada y Lluvia astral.
- **Sistema de generador principal:** ciclos, velocidad, tipos y probabilidades de bola.
- **Motor físico:** gravedad, colisiones, impulso, masa y tamaño efectivo del agujero.
- **Sistema económico y AJ-009:** monetización de capturas y visualización fiel de monedas ganadas.
- **Guardado/restauración:** estado permanente y temporal y elecciones pendientes.
- **AJ-008:** rediseño estético posterior del selector.
- **BAL01:** revisión futura del balance; no bloquea E03.

## 12. Fuera de alcance

- Añadir habilidades 13 o posteriores, rarezas, árboles o categorías desbloqueables.
- Dar a una habilidad más de cinco niveles o introducir niveles infinitos.
- Convertir las cartas E03 en compras con monedas o estrellas.
- Añadir rerolls, rechazos de carta, reembolsos o confirmaciones extra.
- Conceder recompensas alternativas cuando todas estén maximizadas.
- Modificar los precios o funcionamiento base de las cuatro habilidades de P02.
- Cambiar los objetivos de cuotas, el plazo de cuatro jornadas o el crecimiento del 16 %.
- Rediseñar íntegramente las pantallas, el HUD o las ilustraciones de las cartas.
- Implementar B02/B03 u otras bolas especiales no incluidas en el catálogo.
- Realizar un reequilibrio general de economía y progresión, reservado a BAL01.

## 13. Notas de implementación para Codex

1. Auditar primero los sistemas existentes de cuotas, generadores, física, economía, pausa, guardado, P01 y P02; reutilizar su lógica.
2. Centralizar el **catálogo declarativo de 12 habilidades** y parámetros por nivel, sin dispersar valores fijos por el código.
3. Separar el **progreso permanente** (niveles) del **estado del run** (contadores, cooldowns, efectos, cola de elecciones).
4. Tratar la recompensa de una cuota y la elección de carta como eventos persistentes e idempotentes.
5. Guardar las opciones concretas del selector para evitar rerolls por cerrar/reabrir.
6. Usar tiempo simulado de **producción activa** para efectos y recargas; nunca el reloj real de la aplicación.
7. Evitar que efectos adicionales disparen recursivamente otros contadores de ciclos.
8. Mantener la lógica monetaria entera y consistente con el saldo y las monedas visuales.
9. Ejecutar pruebas unitarias de progresión de niveles, activadores y probabilidades; pruebas de integración con cuotas y P02; y pruebas de rendimiento de física.

---

**ESTADO FINAL: READY FOR DEVELOPMENT.**
