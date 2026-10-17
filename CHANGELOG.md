# Historial de cambios

Se registran entregas y cambios observables. `0.1.0+1` es la versión declarada del paquete; no hay una release de tienda o etiqueta de distribución certificada por este archivo.

## Plan de siguiente iteración — 2026-10-17

- Regla confirmada: bolas y monedas pendientes desaparecen al entrar en la noche; cada día nuevo empieza sin objetos heredados.
- Plan de regresión para cierre, dinero perdido, conservación de ahorro/mejoras y reapertura nocturna.
- La coordinación actual ya crea y descarta tableros; esta actualización documenta el alcance y las comprobaciones pendientes, sin cambiar código.

## Documentación del estado actual — 2026-10-17

- Índice por tareas, inventario de funciones entregadas y pendientes con evidencias.
- Explicación de módulos, bucle, física, economía, robot y presentación existentes.
- Referencia JSON v1, cola de escrituras, recuperación y límites de durabilidad.
- Guía de desarrollo, decisiones retrospectivas y criterios para mantener la documentación.
- Corrección de la descripción de la primera emisión y de la garantía implícita de pérdida máxima de cinco segundos. No cambia el comportamiento del juego.

## APK manual — 2026-10-17

- [PR #3](https://github.com/migdlp/incremental_hole_game/pull/3), fusionada como `44d0aeb`.
- Activación solo manual, herramientas Android/JDK completas, lockfile, formato, análisis y pruebas.
- Compilación debug, comprobación de firma, APK y SHA-256 descargables durante 14 días.
- [Ejecución correcta en main](https://github.com/migdlp/incremental_hole_game/actions/runs/39020361800).

## Prototipo 0.1.0+1 — 2026-10-17

- [PR #2](https://github.com/migdlp/incremental_hole_game/pull/2), fusionada como `70556fb`.
- Tablero Flame, empuje, captura, monedas físicas y ciclo de día/noche.
- Ocho mejoras, robot, imán, resultados y progreso local recuperable.
- Pausa por ciclo de vida y opción de silencio; gráficos de primitivas.
- 17 pruebas y compilaciones web/Android verificadas; aceptación en teléfono pendiente.

La documentación inicial del producto precede al código: [PR #1](https://github.com/migdlp/incremental_hole_game/pull/1). Sus propuestas no deben interpretarse como funciones entregadas automáticamente.
