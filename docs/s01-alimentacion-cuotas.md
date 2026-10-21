# S01 — Sistema de alimentación y cuotas

**S03 sustituye la previsualización sin derrota:** el usuario autorizó perder
la partida al incumplir las cuotas provisionales actuales, también en normal.
[Prestigio y migración](s03-prestigio-metaprogresion.md).

**Actualización C01:** alimentación y cuotas conservadas; el dinero se cobra
automáticamente y no hay fase de recogida. JSON vigente v9 / balance v15. Los
detalles v8 de esta entrega describen su contrato histórico. [C01](c01-cobro-automatico.md).

Estado: prototipo jugable 0.12.0+20. Pendientes BAL01, S03 y validación física.

## Reglas confirmadas por el usuario

Cada captura alimenta con toda su recompensa, incluidos racha y dorada ×10.
**Captura total sigue la misma regla**, por decisión expresa del usuario.
No hace falta recoger las monedas y alimentar no descuenta dinero.
Anillo alrededor del hoyo y resumen entre jornadas; períodos de cinco jornadas,
sin premios ni cierre anticipado al cumplir. Al empezar el siguiente período
se reinicia la alimentación y aumenta la cuota.

El usuario aprobó **cuotas provisionales también en juego normal**: objetivo
inicial 10 y aumento 10 por período, centralizados en `balance.csv`. Son valores
para probar, pendientes de BAL01, no balance definitivo. Incumplir se informa,
pero no causa derrota ni pérdidas hasta integrar S03 y validar BAL01.
DEBUG permite simular un fallo reversible sin modificar la partida real.
JSON v8 / balance v14, con v13 congelado y sin inventar capturas históricas.

## Contabilidad y presentación

El valor usa la rama global Valor mientras no existan tiers individuales.
Al incorporar tiers se usará su recompensa. La captura calcula la recompensa
una sola vez: el mismo resultado alimenta y genera monedas físicas, cuyo cobro
sigue siendo independiente. Se distinguen capturas normales e instantáneas para
validar el guardado; ambas cuentan íntegramente, sin interruptor de política.

El anillo circular se dibuja bajo bolas y herramientas, sin cambiar captura,
colisiones ni entrada táctil. El resumen de resultados y Tienda muestra puntos,
objetivo y jornadas restantes del período, sin mostrar el número global de día.

La alimentación se acumula cinco jornadas. Cumplir pronto mantiene el período;
no otorga premio adicional. No hay arrastre de excedente al siguiente período,
deudas ni prórrogas. El objetivo siguiente usa el paso configurable provisional.
La pausa y recogida final no generan nuevas capturas ni alimentación.

## Persistencia y migración

JSON v8 conserva período, jornadas completadas, objetivo, paso y contadores
normales/instantáneos del período y jornada. Balance v14 añade contadores al
tablero. Su suma debe coincidir con
`ball_value × (captured + 9 × goldenCaptured + combo.bonusUnits)` y con los
contadores de jornada de la sesión. Se valida antes de aplicar una restauración;
restaurar nunca vuelve a acreditar capturas.

Los guardados v1–v7 no reciben alimentación histórica inventada. Una jornada
antigua activa termina con su balance original y comienza S01 en la siguiente
jornada completa. Balance v13 queda congelado. Se conservan compras, saldo,
opciones, nombres internos, paquete Android y archivos existentes.

## Probar en DEBUG

1. Tienda → DEBUG → Alimentación y cuotas.
2. Activar **Simular fallo de cuota** y elegir objetivo. Cambiarlo reinicia solo
   el período temporal. Sin armar esta opción, no se bloquea por incumplimiento.
3. Capturar bolas, también doradas o con Captura total, y comprobar el anillo
   sin recoger monedas: se incluye toda la racha.
4. **Simular jornada sin capturas** permite llegar al quinto vencimiento.
5. Un fallo armado bloquea solo la prueba. **Reiniciar período de prueba**
   permite continuar; salir de DEBUG recupera exactamente la partida real.

## Parámetros provisionales y pendientes

`feeding_quota_initial = 10` y `feeding_quota_step = 10` en
[balance.csv](balance.csv) se muestran también en juego normal por petición del
usuario. No representan una curva validada por BAL01. S03 debe implementar
la derrota, reinicio y prestigio antes de aplicar pérdidas reales; S02 añadirá
personalidad y expresiones. No inventar esas decisiones ni balance definitivo.

## Verificación

Pruebas de recompensa completa y combo/dorada, Captura total, independencia del
cobro, cuota anticipada/vencida, cinco jornadas, reinicio sin premios, migración,
restauración idempotente, corrupción, DEBUG aislado, pausa/recogida, anillo y UI
pequeña. La calibración y sensaciones en Android físico siguen pendientes.
