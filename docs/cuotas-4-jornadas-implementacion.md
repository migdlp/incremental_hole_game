# Cuotas de cuatro jornadas — integración S03 / AJ-005B

Versión **0.22.0+35**. [Especificación aprobada](s03-aj005b-cuotas-4-jornadas.md).
Esta actualización sustituye la regla anterior sin vencimiento. Las cuotas siguen
siendo infinitas: 100, 1000, 10000… bolas; los objetivos, progreso y excedentes
conservan BigInt y sus cadenas decimales exactas en JSON.

## Comportamiento

Cada bola capturada alimenta una sola unidad, con independencia de dinero, dorada,
combo u origen. Cada cuota completa traslada el excedente, crece el área un 16 %
y genera sus recompensas P01/P02 una vez. La siguiente comienza inmediatamente;
`quotaStartDay` se fija a la jornada en curso incluso en su último instante válido.
Completar varias cuotas produce todos los eventos en orden y conserva la jornada
actual como inicio de la última cuota activa.

La jornada relativa es `día - quotaStartDay + 1`. La cuarta es válida hasta el
cierre. `_step` procesa capturas, alimentación, cuotas, crecimiento, Lluvia astral
y roturas/cobros ya ocurridos antes de `finishDay`. No se simulan segundos extra
ni se espera a bolas que aún están fuera del hoyo. Si la cuota final vence,
`_endRun(voluntary: false)` ejecuta el reinicio protegido existente y presenta
DERROTA directamente, con un mensaje corto. No se crea un resultado de jornada
ni se ejecuta su animación. Repetir el cierre no vuelve a terminar la partida.

DERROTA → Continuar → la misma tienda P02. Estrellas cobradas y compras permanentes
se conservan; burbujas sin romper, dinero, herramientas, cuotas, crecimiento y
contadores temporales se eliminan conforme a S03. No hay estrellas de consolación.
Prestigio voluntario y sus condiciones/coste quedan intactos. Catálogo P02 intacto:
Herencia 2, Eco 6, Fiebre dorada 8 y Lluvia astral 12 estrellas.

## Jornadas e interfaz

La jornada actual ya no se incrementa al cerrar. `Progress.finish` guarda el
resultado; `startDay` avanza a la siguiente antes de comenzar producción. El cierre
se registra con `dayClosed` para no consumir días por pantallas, pausas, compras,
restauraciones ni reabrir la aplicación. El árbol normal se habilita tras cerrar
el primer día aunque el contador actual siga siendo 1, y permanece bloqueado antes.

Solo AJ-008A muestra el plazo: `Jornada X de 4` y las jornadas **futuras** restantes
(3, 2 o 1). Se toman de la cuota activa final y del día del resultado. Cuando se
completa una cuota, se muestran objetivo/progreso de la nueva, con jornada 1/4,
no el plazo anterior. Ningún contador de vencimiento se añade al gameplay, al HUD,
a la tienda normal ni a su resumen compacto. Pausa y temporizador no se rediseñan.

## Guardado y migración

JSON raíz **v15**, balance **v20** sin cambios. Reglas de alimentación
`balls-four-days-v2` con `quotaStartDay` y `dayClosed`. Se validan tipos, límites de
jornada, fecha de inicio y coherencia con producción/cierre antes de mutar la
sesión. Se rechaza un guardado nuevo que pretenda conservar activa una jornada
cerrada y vencida. El checkpoint de prestigio también reconoce v15; su revisión
impide restaurar la partida anterior después de una muerte aunque falle el archivo
normal o solo queden copias antiguas.

Los guardados v1–v14 siguen admitidos. Para cuotas por bolas v14 se conservan puntos,
objetivo, cuotas completadas, crecimiento, burbujas y recursos. Sin fecha histórica
de inicio se abre un plazo seguro tomando como día 1 el día activo o el último
recién cerrado. Si se migra entre jornadas, quedan **tres futuras** a partir de ese
cierre; no hay muerte retroactiva ni concesiones de cuotas antiguas. El antiguo
puntero al día siguiente se convierte al día realmente cerrado. También se cubren
los períodos monetarios antiguos que ya apuntaban al siguiente período con cero
días consumidos. Su progreso monetario no se convierte en bolas: se conserva la
migración segura de AJ-005B y no se vuelven a conceder premios históricos.

## Archivos y pruebas

Validación local: **457 pruebas correctas**, formato y análisis sin incidencias.

- `feeding_progress.dart`: fecha por cuota, cierre y validación/migración.
- `game_session.dart`: secuencia de cierre/derrota, avance de día, restauración,
  acceso inicial a compras y adaptación del reinicio de cuotas DEBUG.
- `progress.dart`: día actual separado del cierre.
- `results_data.dart`, `results_overlay.dart`: plazo solo en el resultado.
- `prestige_screen.dart`: mensaje mínimo de cuota incumplida.
- `four_day_quotas_test.dart`: 16 pruebas nuevas de integración, borde temporal,
  migración, interfaz, cantidades enormes y checkpoint ante fallo de disco.
- Pruebas históricas ajustadas a cuatro jornadas y al avance al comenzar, sin
  eliminar comprobaciones de economía, crecimiento o persistencia. Las pruebas
  de muchos ciclos contables/informes DEBUG desactivan explícitamente cuotas en
  sus fixtures para aislar esa responsabilidad; supervivencia se prueba aparte.

La validación incluye completar en días 1/2/3/4; 99 frente a 100 al cierre; captura
en los últimos 5 ms válidos; bola móvil fuera al agotarse; 90+30 y 1200 en los tests
existentes; tres cuotas simultáneas al cierre; crecimientos/restauración; pausa;
derrota y tienda con cero estrellas; pérdida de pendientes; conservación de P02;
resumen de cuota nueva; y ausencia del plazo en gameplay. Las pruebas de Lluvia
astral siguen verificando tiradas por cuota sin duplicar estrellas.

Pendiente la prueba del flujo en Android físico y el balance de dificultad BAL01.
Las limitaciones de saturación extrema y salida bloqueada de Fiebre dorada de P02
no se modifican en esta tarea. La pipeline debe validar formato, análisis, pruebas,
compilación y firma; comparación entre APKs solo si se solicita su entrada opcional.
