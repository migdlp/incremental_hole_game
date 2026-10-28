# BAL-TOOLS — Preparación del laboratorio permanente de balance

Solicitud AG01 → Task Manager · 28/10/2026 · prioridad alta.
**Entrega actual: análisis y preparación de tickets. No instrumentación implementada.**
Ningún cambio en lib/, economía, física, RNG, catálogo, curva o CI.

## Base verificada

- Rama activa del producto: `build/apk-0.6.0+13`.
- HEAD de producto inspeccionado: `720c4a0fd4f0c1460fcf334c08fa5cddd8ee555b`.
- Juego actual: **0.23.1+37**, balance v20, guardado JSON v17.
- Código empaquetado: `77629ff2fc7e7dedbc20141dc95c9c2c85287f54`; el diff
  `77629ff..720c4a0` en `lib test pubspec.yaml docs/balance.csv` está vacío.
- [Pipeline 40469189020](https://github.com/migdlp/incremental_hole_game/actions/runs/40469189020)
  correcta, APK 0.23.1+37; 489 pruebas es evidencia de esa entrega anterior,
  no pruebas nuevas del laboratorio ni mediciones humanas.
- [AUD01 completo](../../auditoria/AUD01/AUD01_completo.md) publicado en `720c4a0`
  audita **0.23.0+36 / `0778d139d4a85124e0af2a9f89d595dc19159430`**. Sus
  193 comprobaciones son de extracción/documentación, no pruebas de partidas.
- Objetivos vigentes: 25 → 50 → 100 → 500 → 1.000 → 10.000 → ×10; cuatro jornadas
  por cuota y área ×1,16 provisionalmente conservadas. E03 Hambre es un
  modificador existente que se debe registrar, no eliminar.

Antes de implementar cada ticket, el desarrollador revalidará HEAD, cambios de
configuración y build. La identidad de la referencia anterior no se sustituye
por la del documento nuevo que la describe.

## Orden, estados y puerta de salida

| ID | Fase / prioridad | Dependencias | Estado inicial |
| --- | --- | --- | --- |
| [BAL-TOOLS-01](https://github.com/migdlp/incremental_hole_game/issues/21) | A · alta | AUD01 disponible | Ready for Development (análisis técnico) |
| [BAL-TOOLS-02](https://github.com/migdlp/incremental_hole_game/issues/22) | A · alta | 01 aceptada | Bloqueada por 01 |
| [BAL-TOOLS-03](https://github.com/migdlp/incremental_hole_game/issues/23) | A · alta | 02 aceptada | Bloqueada por 02 |
| [BAL-TOOLS-04](https://github.com/migdlp/incremental_hole_game/issues/24) | B · alta | 03 aceptada | Bloqueada por 03 y disponibilidad de testers/Android |
| [BAL-TOOLS-05](https://github.com/migdlp/incremental_hole_game/issues/25) | B · alta-media | 01, 02 y 03 aceptadas | Bloqueada por A |
| [BAL-TOOLS-06](https://github.com/migdlp/incremental_hole_game/issues/26) | C · media | 03 y 05; referencias reales de 04 | Bloqueada por B |

El bloque A es secuencial. 04 y 05 pueden avanzar en paralelo después de A.
La recogida humana no bloquea un simulador sintético; sus resultados no la
sustituyen. 06 requiere escenarios reproducibles y referencias reales.
Tickets publicados: #21–#26. Todos abiertos; los estados de preparación y bloqueo
son los de la tabla. No se ha declarado completada ninguna fase.

**Hito tras aceptar 03:** BAL01 puede empezar mediciones reales. 03 debe incluir
exportaciones de prueba etiquetadas y una guía; Task Manager notificará a AG01
con enlaces y limitaciones. Esto no declara terminadas 04/05/06, ni autoriza
recalibrar el juego. Ahora no existen exportaciones del laboratorio implementado.

## Requisitos mínimos e inventario para 01

[Contrato de métricas propuesto](metricas-propuesta.md): diccionario, fuentes,
estructura versionada, identidades/semillas, coherencia y plan de integración.
Es un borrador de entrada a 01; el desarrollador debe cerrar enums, esquema,
fixtures y presupuesto antes de darla por aceptada. No marcar 01 completada
solo porque el Task Manager haya redactado esta propuesta.

La captura se relacionará con emisiones **reales**, diferenciando solicitudes,
sondeos de salida, intentos fallidos, cuerpos, capturas, población restante y
retiradas. `DebugDayReport` es efímero/DEBUG y conserva 20 días; `spawned` no está
persistido; `Launcher.attempts/shots` sí tiene serialización. `DayResult.generated`
y `lost` son monedas. `normalFood/instantFood` también son importes monetarios.
Estas limitaciones fundamentan 02; no duplicar el panel ni convertirlos en bolas.

## Alcance mínimo de A

01 cierra el contrato y las invariantes. 02 instrumenta los puntos confirmados
sin logs por frame ni cambios en RNG y añade agregados/continuidad guardada.
03 exporta CSV por jornada, JSON completo y resumen comprensible desde DEBUG,
incluyendo partidas normales persistidas: **abrir DEBUG para exportar no convierte
los días normales previos en pruebas DEBUG**. Las acciones que sí alteren una
partida deben segmentarse/marcarse. El “exportador” nunca crea datos retrospectivos.

Todo indicador no medido se declara null con razón. El origen desconocido de una
bola legacy y el coste GPU sin medición física no se sustituyen por ceros.
La atribución causal de capturas a una herramienta no se deduce de estar seleccionada.

## Evidencias requeridas al desarrollador

Cada ticket exige en su entrega: commit/rama, versión/build y configuración,
esquema, semillas, escenarios, comandos ejecutados, resultado y limitaciones.
Debe adjuntar ejemplos reales de sus archivos, verificador de coherencia y
pruebas de restauración/transiciones relevantes. No basta una captura del panel.
01–03 no se cierran con un plan, pseudocódigo o archivos redactados a mano.
En 04 se necesitan sesiones humanas y Android; simulaciones e inyecciones no
cubren ese criterio. Registrar interrupciones/abandono, no solo supervivientes.

La persona responsable de implementación queda por asignar; AG01 es solicitante
y revisor de utilidad para BAL01, no un usuario de GitHub supuesto. Los tickets
se asignan a fases y roles sin inventar una identidad del desarrollador.

## Hipótesis, asuntos separados y límites

- Curva B `10,20,35,60,100,155,235,350,510,730,…`: **hipótesis experimental**.
  La continuación tras esos diez valores no está definida: escenarios con límite
  explícito o fórmula posterior aprobada; nunca inventar el resto ni activar en normal.
- Ventilador/embudo regulable, nuevos generadores, precios y prestaciones P02/E03,
  economía de estrellas y narrativa son propuestas futuras fuera de estos tickets.
  El laboratorio puede registrar o comparar lo existente, no implementar herramientas nuevas.
- **AUD-F01** (hand:1 con seis vecinos) y **AUD-F03** (H04 obstruida pese a garantía)
  quedan identificados como correcciones funcionales separadas, pendientes de su
  propio alcance/aprobación. No “arreglarlos” en instrumentación ni silenciar sus datos.
- AUD-F08: el límite histórico de ocho burbujas no es operativo con P02
  `populateImmediate`; medir población observada, no tratarlo como límite garantizado.
- AUD-F13: BigInt en cuotas no hace ilimitados todos los importes/IDs del juego;
  exportar exactitud y detectar errores no autoriza rediseñar la economía.
- Se conserva la CI manual existente. 06 puede integrarse como paso/opción de ese
  flujo; no habilitar disparos nuevos por push/PR sin otra decisión.
- Sin servidor ni telemetría remota, datos personales innecesarios o interfaz compleja.

## Revisión y aceptación

1. Task Manager comprueba dependencias/evidencias y que la implementación respete
   el contrato; AG01 comprueba que los resultados sirven para comparar balance.
2. Si falta evidencia, el ticket permanece abierto con el hueco explícito.
3. Se documentan diferencias de esquema, hardware y configuración antes de comparar.
4. Una regresión técnica puede fallar una comprobación determinista. Una hipótesis
   de balance divergente se informa; actualizar una referencia requiere motivo,
   revisión y conservar la anterior, no convertirla automáticamente en “correcta”.
