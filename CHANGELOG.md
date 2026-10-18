# Historial de cambios

Se registran entregas y cambios observables. `0.2.1+3` es la versión actual declarada del paquete; no hay una release de tienda o etiqueta de distribución certificada por este archivo.

## Documentación actualizada — 2026-10-18

- Inicio rápido, diseño y arquitectura real alineados con mano y escobas recta/V, pulsación inicial y barrido comprado.
- Economía de 15 s totales, intervalos cuatro veces mayores, once mejoras y límites del ritmo de compras provisional.
- Guardado v3, compatibilidad v1/v2, herramienta y versión de balance por jornada.
- APK más reciente, 41 pruebas y límites de validación identificados; historia original conservada. No modifica código ni balance.

## 0.2.1+3 — 2026-10-18

- [PR #10](https://github.com/migdlp/incremental_hole_game/pull/10), `1d71843`: día base de 10 s de producción + 5 s de cierre; intervalo base 3 s y mejoras cuatro veces más lentas que antes.
- Duración mejorable a 20/25/30 s totales; precios conservados y todavía provisionales.
- Guardado v3 mantiene la jornada anterior hasta terminar y aplica el balance nuevo al día siguiente.
- 41 pruebas y [pipeline Android correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402); [APK actual](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402/artifacts/12141030218).

## 0.2.0+2 — 2026-10-18

- [PR #8](https://github.com/migdlp/incremental_hole_game/pull/8), `1a8fed7`: agarre individual, colocación suave y lanzamiento por velocidad final.
- Escoba recta perpendicular al movimiento con giro suave, anchura mejorable y V que reúne por contacto; selector de herramientas compradas.
- Monedas por pulsación inicial y barrido mediante compra; limpieza nocturna incluida la bola agarrada.
- Guardado v2 con elección de herramienta y migración v1; once tipos de mejora con costes provisionales.
- 36 pruebas y [pipeline Android correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/39136783858); prueba de navegador, sin aceptación en móvil físico.

## Diseño de herramientas y recogida — 2026-10-17

- Lluvia de ideas de herramientas para agrupar, transportar y lanzar bolas; son candidatas, sin implementación ni precios aprobados.
- Cambio confirmado y pendiente: monedas por pulsación al inicio; recoger arrastrando requiere comprar la mejora de barrido.
- Plan, PRD y diseño actualizados; el prototipo aún permite barrido desde el inicio. Sin cambios de código ni de balance.

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
