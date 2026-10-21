# S03 — Prestigio y metaprogresión

Estado: infraestructura implementada en 0.14.0+22. Integración final de recompensas,
catálogo, efectos permanentes y balance pendiente de P01, P02 y BAL01.

## Decisiones confirmadas en esta tarea

El usuario autorizó activar la derrota **también en juego normal**, manteniendo
las cuotas provisionales 10/20/30… cada cinco jornadas. Esta autorización sustituye
la restricción anterior de S01 de no aplicar pérdidas antes de BAL01.

Pidió el nodo en normal y DEBUG, algo más grande y girado 45°. Es un rombo dorado,
siempre descubierto aunque esté lejos de la cámara inicial, cerca del final del
mapa. No se bloquea artificialmente por ser la primera partida. Sus requisitos
de compra son los únicos que impiden adquirirlo. Debe explorarse el árbol para verlo.

Para hacer el prototipo revisable se centraliza en [balance.csv](balance.csv):
precio 10.000, Generador V + Valor V + Duración V. Posición de prueba (48,48),
vecina al extremo avanzado de Generación. **Coste, dependencias y posición siguen
abiertos para BAL01**, no son balance aprobado. No se altera el resto del catálogo.

## Ciclo y reinicio

`MetaProgress` separa estados `playing`, `defeat` y `shop` de la simulación diaria.
Al finalizar la quinta jornada, incumplir la cuota termina la partida. Cumplir
antes mantiene el mismo período; no da estrellas ni premios adicionales en S03.
La pantalla DERROTA solo ofrece Continuar, sin resumen de ingresos o capturas.
Continuar abre la tienda, incluso con cero estrellas y ninguna mejora permanente.

Comprar Prestigio solicita confirmación explícita: cancela sin gastar nada;
confirmar paga el coste y termina inmediatamente, abriendo la tienda sin DERROTA.
No queda una habilidad comprada ni un botón de activación posterior. Al iniciar
otra partida vuelve a estar sin comprar. Punteros repetidos, confirmaciones
obsoletas y acciones fuera de fase no pueden reiniciar dos veces.

Al terminar se limpian día, saldo normal, resultados/record de esa partida,
mejoras normales y compatibilidad histórica del árbol, herramientas, generadores,
poses, bolas, recompensas de monedas, alimentación y cuotas. No hay juego activo
por detrás de derrota o tienda. Nueva partida comienza en día 1, limpia.
Preferencias de sonido, vibración y feedback visual se conservan.

Se conservan estrellas cobradas, mapa de compras permanentes, descubrimientos,
indicador de primera derrota y extensiones de datos permanentes. Los objetos P01
pendientes se guardan como estado opaco sin convertirlos, descartarlos ni volver
a generarlos. S03 no decide su comportamiento físico entre partidas.

## Tienda y límites de esta entrega

Pantalla provisional de Prestigio con saldo de estrellas y Nueva partida. Solo
se alcanza tras derrota o compra confirmada; no tiene entrada durante una partida.
No se inventa un catálogo, narrativa, secretos, denominaciones ni efectos P02.
Las compras permanentes ya presentes en datos se conservan íntegramente; sus
efectos jugables deben definirse e integrarse en P02. Por tanto S03 por sí solo
**todavía no acelera una nueva partida ni genera estrellas**.

`firstDefeatSeen` conserva el estado necesario para una futura primera escena;
no se añade animación narrativa definitiva. No hay segundo prestigio ni herramientas nuevas.

## Persistencia y protección frente a restauraciones antiguas

JSON v10 incluye `meta` separado del progreso normal: revisión monotónica,
identificador de partida, última partida terminada, fase, motivo, estrellas,
compras, descubrimientos, primera derrota, objetos P01 pendientes y extensiones.
Se valida antes de aplicar cambios. Balance v16 añade la acción del nodo y v15
queda congelado para jornadas antiguas; paquete y archivos existentes se mantienen.

Las transiciones de prestigio incrementan revisión. Se escribe primero un
checkpoint completo independiente y duradero; después el archivo normal. En
Android `prestige.json` y `prestige.backup.json` contienen **ambas la revisión
nueva**, usando temporal + flush + rename. Web usa dos claves independientes.
El checkpoint completo permite recuperar derrota, tienda o nueva partida aunque
falle el archivo normal. Las escrituras siguen serializadas y coalescidas.

Continuar y Nueva partida quedan deshabilitados hasta completar el checkpoint;
si hay un fallo se muestra el error de guardado y se permite Reintentar. La misma
transición no se repite al reintentar. Un cierre durante un guardado no confirmado
puede recuperar la última transición completada; nunca se afirma que se haya
confirmado una transición cuya escritura falló.

Al cargar se consulta primero el checkpoint. Se rechazan revisiones anteriores
y datos permanentes distintos para la misma revisión. La recuperación normal
no puede revivir una partida cerrada usando `progress.backup.json` antiguo. Si
hay un checkpoint de revisión mayor legible pero su instantánea es inválida, no
se rebaja a una revisión inferior. Si ambas copias de prestigio son ilegibles se
bloquea la carga; no se ofrece crear un perfil vacío sobre sus datos permanentes.

La protección cubre las restauraciones internas y las copias normales mientras
exista el checkpoint. Un juego local sin servidor no puede detectar que alguien
haya borrado o sustituido externamente **todos** sus archivos por un conjunto
antiguo coherente; no se introduce una cuenta o servicio externo en S03.

Migración v1–v9: perfil permanente inicial vacío, saldo y compras actuales
conservados. Los períodos antiguos que ya vencieron en modo de previsualización
no causan derrota retroactiva; la regla se aplica a nuevas finalizaciones. C01
sigue liquidando monedas pendientes sin duplicados y S01 conserva sus contadores.

## DEBUG

- Tienda → DEBUG → **Probar derrota y prestigio** activa el ciclo completo temporal.
- Alimentación y cuotas → Simular jornada sin capturas permite llegar al quinto
  vencimiento. Al terminar se cierran tanto el panel como el árbol para ver DERROTA.
- El nodo Prestigio aparece como rombo grande también en el mapa completo. Su
  compra gratis exige la misma confirmación; abre la tienda de prueba.
- Comprar todo excluye este nodo para no terminar una prueba de herramientas.
- Salir de DEBUG restaura también metaprogresión, fase y revisión originales.
  No escribe checkpoints ni modifica estrellas o compras reales.

## Verificación y pendientes

Pruebas de quinto vencimiento, cuota cumplida, reinicio e idempotencia, confirmación
normal/DEBUG, rombo a 45°, cierre de rutas, conservación de campos permanentes y
P01 opaco, migración, revisiones antiguas, caída de guardado normal y permanente,
dos copias nativas, recuperación en proceso nuevo y corrupción sin resurrección.

Pendientes: P01 (obtención, tipos, burbujas y política física pendiente), P02
(catálogo, efectos, interfaz final, narrativa y secretos), BAL01 (cuotas,
recompensas, nodo y ritmo de metaprogresión). Probar en Android físico y mantener
pendiente la medición de rendimiento de C01; no certificar APK actualizable con
la firma anterior sin comprobarla.
