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

**Decisión observada:** `generated`, `collected` y `balance` tienen funciones separadas. El cierre actualiza resultado/saldo/día, retira la jornada y encola una instantánea JSON completa (v3 actual; v1 en la decisión inicial). Las escrituras se serializan y mantienen una copia anterior válida. Web usa preferencias; Android usa archivos y temporales.

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


## ADR-005 — Agarre individual y geometría de escobas compartida

**Estado:** implementado; sensación en teléfono pendiente.

**Contexto:** el círculo inicial dispersaba grupos radialmente y no ofrecía una progresión de transporte individual a barrido cómodo.

**Decisión:** mano inicial para una bola y lanzamiento por velocidad final del gesto; después escoba recta ampliable y V. El frente se orienta perpendicularmente al movimiento, con giro limitado y orientación retenida al parar. `broomSegments` sirve tanto para colisión como para dibujo. Se distinguen pulsación de moneda y arrastre, con barrido como compra independiente.

**Consecuencias:** forma visible y física coinciden; la inercia se prueba a distintas frecuencias de entrada. La simulación propia debe resolver extremos, giros y atascos; el navegador no sustituye la prueba táctil real. El selector permite volver a herramientas compradas sin rediseñar aún el árbol.

**Evidencia:** [tool.dart](../lib/features/board/domain/tool.dart), [Board](../lib/features/board/domain/board.dart), [pruebas de controles](../test/features/ball_controls_test.dart), [PR #8](https://github.com/migdlp/incremental_hole_game/pull/8).

## ADR-006 — Esquema v3 y balance identificado por jornada

**Estado:** aplicado; compatibilidad v1/v2 y reapertura comprobadas automáticamente.

**Contexto:** al cambiar de 60 + 5 s a 10 + 5 s y reducir frecuencia cuatro veces, comparar solo con el catálogo nuevo invalidaría una partida activa anterior.

**Decisión:** conservar valores históricos de duración/intervalo para validar y terminar esa jornada. Escribir v3 con herramienta y `run.balanceVersion`; restaurar v1/v2 con el balance anterior y abrir pausado. El siguiente día usa el balance actual. Las antiguas compras de anchura conservan escoba y no conceden barrido gratuito.

**Consecuencias:** no se pierde progreso ni se recorta una jornada guardada. Hay dos versiones de balance conocidas, no soporte de configuraciones arbitrarias; futuras modificaciones requieren extender la política y sus pruebas. La tabla editable de partidas nuevas sigue siendo el CSV.

**Evidencia:** [guardado](persistencia.md#compatibilidad-entre-versiones), [catálogo](../lib/features/upgrades/domain/catalog.dart), [pruebas de balance](../test/features/balance_test.dart), [PR #10](https://github.com/migdlp/incremental_hole_game/pull/10).


## ADR-007 — Descubrimiento del árbol separado del catálogo histórico

**Estado:** implementado en `1720fba`; aceptación táctil pendiente.

**Contexto:** se quiere revelar caminos progresivamente sin invalidar compras o guardados anteriores ni cambiar precios durante el rediseño.

**Decisión:** `SkillTree` crea un nodo por nivel y añade padres de descubrimiento a los requisitos existentes. La UI comprueba ambos antes de iniciar/completar la compra de tres segundos; la sesión conserva las condiciones históricas del CSV. Visibilidad derivada de niveles, sin nueva versión de guardado.

**Consecuencias:** una partida nueva ve solo generador 1 y la primera compra visible cuesta treinta, aunque otras mejoras del catálogo cuesten veinte. Las compras antiguas siguen activas y muestran sus antecesores sin concederlos. Futuros cambios deben distinguir requisito de compra del dominio y descubrimiento de UI; deben probarse alcance y ausencia de ciclos.

**Evidencia:** [árbol y recorrido](arbol-de-mejoras.md), [modelo](../lib/features/upgrades/domain/skill_tree.dart), [pruebas](../test/features/skill_tree_test.dart).
