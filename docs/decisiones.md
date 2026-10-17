# Registro de decisiones técnicas

Registrado el 17 de octubre de 2026 a partir del PRD, la propuesta de arquitectura, el código y las PR fusionadas. Es un registro retrospectivo: no supone que se hayan comparado todas las alternativas con pruebas o que el MVP esté aceptado. Formato breve inspirado en [Architectural Decision Records](https://adr.github.io/): contexto, decisión, consecuencias y condición de revisión.

## ADR-001 — Flutter, Flame y física de círculos propia

**Estado:** aplicado en el prototipo; sensación y rendimiento pendientes de validación física.

**Contexto:** se necesita una aplicación Android vertical con menús, un tablero cenital y un gesto de empuje. La propuesta original recomienda evaluar el movimiento antes de añadir un motor de física adicional.

**Decisión observada:** Flutter presenta las pantallas; `GardenGame` usa el bucle y lienzo de Flame. `Board` simula círculos y colisiones con rejilla espacial en Dart puro. No se incorpora Forge2D ni un componente Flame por cada objeto.

**Consecuencias:** las reglas se prueban sin montar una escena y la presentación queda separada. Rozamiento, colisiones, subpasos, atascos y límites son responsabilidad del proyecto; no se ha demostrado que esta simulación sea suficiente para toda carga o sensación deseada.

**Revisar cuando:** la prueba con grupos o el perfil físico muestre inestabilidad o coste excesivo. El plan contempla comparar una prueba acotada con Forge2D antes de ampliar sistemas.

**Evidencia:** [arquitectura objetivo](arquitectura.md), [Board](../lib/features/board/domain/board.dart), [GardenGame](../lib/features/board/presentation/garden_game.dart), [PR #2](https://github.com/migdlp/incremental_hole_game/pull/2).

## ADR-002 — Una aplicación modular y coordinación explícita

**Estado:** aplicado; la separación actual es menor que la estructura objetivo completa.

**Contexto:** las capturas, compras y cierres cruzan varios sistemas y deben evitar duplicar dinero. El proyecto todavía no necesita servicios independientes ni un framework de estado adicional.

**Decisión observada:** módulos de dominio para tablero, reloj, economía, mejoras, automatización y progreso; `GameSession` coordina comandos y usa `ChangeNotifier` para la UI. `SaveStore` es un puerto pequeño sustituible por memoria en pruebas. `Board` consulta directamente al controlador puro `Robot`.

**Consecuencias:** las colaboraciones se siguen mediante llamadas y las pruebas ejercitan invariantes. La sesión también compone mapas de serialización; no existen capas de aplicación por cada módulo, eventos con ID/tipo ni modelos separados para todas las instantáneas. Debe evitarse que crezca acumulando mecánicas ajenas.

**Revisar cuando:** aumenten comportamientos o coordinaciones reales, aparezcan dependencias circulares o la navegación/estado resulte difícil de mantener. No separar paquetes o introducir un bus solo por crecimiento previsto.

**Evidencia:** [mapa implementado](implementacion.md), [GameSession](../lib/app/game_session.dart), [pruebas](../test/features/game_rules_test.dart).

## ADR-003 — Ingreso diario separado, cierre compuesto y guardado recuperable

**Estado:** aplicado; recuperación física en Android pendiente.

**Contexto:** una bola genera monedas que aún deben recogerse. Reabrir una partida no puede combinar un saldo nuevo con un día antiguo y volver a cobrarlo.

**Decisión observada:** `generated`, `collected` y `balance` tienen funciones separadas. El cierre actualiza resultado/saldo/día, retira la jornada y encola una instantánea JSON v1 completa. Las escrituras se serializan y mantienen una copia anterior válida. Web usa preferencias; Android usa archivos y temporales.

**Consecuencias:** el flujo normal y la recuperación de copias mantienen consistente el cobro. No hay transacción entre dos claves web ni garantía de durabilidad universal. Fallos de escritura o recuperación de una copia pueden retroceder más que el intervalo nominal de cinco segundos. No hay sincronización ni recompensas por tiempo cerrado.

**Revisar cuando:** se cambie el esquema, se altere el balance con partidas existentes o un ensayo de interrupción revele una inconsistencia. Definir y probar migración antes de introducir otra versión.

**Evidencia:** [referencia de persistencia](persistencia.md), [Economy](../lib/features/economy/domain/economy.dart), [adaptadores](../lib/persistence/), [pruebas de recuperación](../test/features/game_rules_test.dart).

## ADR-004 — Balance único y entrega Android manual reproducible

**Estado:** aplicado y verificado en CI; instalación física pendiente.

**Contexto:** hacen falta precios trazables, SDK compatible y un APK descargable bajo demanda. El usuario pidió ejecución manual y fusión de los cambios en `main`.

**Decisión observada:** se empaqueta `docs/balance.csv` como fuente de configuración; Flutter 3.35.7 se selecciona en `.fvmrc` y CI, con dependencias resueltas en `pubspec.lock`. El workflow solo tiene `workflow_dispatch`, valida SDK/lockfile/código y sube un APK debug con firma comprobada y SHA-256.

**Consecuencias:** una ejecución identifica commit y artefactos. No hay automatización en cada PR o push; hay que iniciarla expresamente. No es firma para tiendas ni una estrategia de continuidad del certificado debug entre runners. La igualdad estricta de configuración guardada obliga a revisar compatibilidad al cambiar balance.

**Revisar cuando:** se prepare distribución de producción, cambie el SDK, se necesiten otros destinos o el usuario cambie el criterio de activación. Actualizar versión, hash, lockfile, documentación y evidencia conjuntamente.

**Evidencia:** [CSV](balance.csv), [workflow](../.github/workflows/flutter-manual.yml), [PR #3](https://github.com/migdlp/incremental_hole_game/pull/3), [ejecución manual correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/39020361800).
