# BAL-TOOLS — Laboratorio permanente de balance

Implementación autorizada el29/10/2026. Build preparada **0.24.0+38**,
balance v20 y guardado compatible v17; cuotas/economía/físicas conservadas.

- [Contrato implementado v1 e inventario](contrato-v1.md).
- [Exportación, simulación y comparación](uso.md).
- [Protocolo humano Android](partidas-humanas.md).
- [Escenarios reproducibles](scenarios/baseline.json).
- [Evidencias y estado de entrega](entrega.md).

## Tareas y dependencias

| ID | Fase | Entrega / estado |
|---|---|---|
| [01 #21](https://github.com/migdlp/incremental_hole_game/issues/21) | A | Contrato cerrado; esquema, unidades, fuentes, cobertura y retención definidos |
| [02 #22](https://github.com/migdlp/incremental_hole_game/issues/22) | A | Instrumentación local en Board/GameSession; validación y restauración |
| [03 #23](https://github.com/migdlp/incremental_hole_game/issues/23) | A | JSON/CSV/resumen desde DEBUG; compartir/descargar y copia local |
| [04 #24](https://github.com/migdlp/incremental_hole_game/issues/24) | B | Protocolo preparado; **recogida humana Android pendiente** |
| [05 #25](https://github.com/migdlp/incremental_hole_game/issues/25) | B | Runner reproducible de GameSession, siete escenarios/tres semillas |
| [06 #26](https://github.com/migdlp/incremental_hole_game/issues/26) | C | Comparador/validador y CI manual implementados; **referencia humana de04 pendiente** |

El bloque A se ha implementado en orden contrato→instrumentación→exportación.
BAL01 puede iniciar la recogida con la build instrumentada. Esto no certifica
balance ni cierra04/06: los datos incluidos son sintéticos, etiquetados como tales.
Los tests y builds concretos, commit de fuente y limitaciones constan en entrega.
No cerrar04 con un bot ni06 solo con referencias sintéticas.

## Disponibilidad para AG01

[APK de pruebas0.24.0+38](https://github.com/migdlp/incremental_hole_game/actions/runs/40798127327/artifacts/12864484189) disponible;
la exportación del laboratorio está preparada para comenzar mediciones reales de
BAL01. Compartir los archivos desde DEBUG al terminar cada sesión, con la plantilla
de condiciones. Los primeros ejemplos proceden del runner automático y sirven
para revisar el formato, no para proponer cuotas definitivas. Revisar los datos
humanos antes de decidir precios, estrellas o progresión.

## Base histórica verificada antes de implementar

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
