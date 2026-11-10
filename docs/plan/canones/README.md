# Plan: generadores-cañón

Estado: completado · Última actualización: 2026-11-10

## Resumen

El generador fijo que suelta bolas sin fuerza se sustituye por **cañones** que oscilan en un arco y disparan con fuerza. Al principio el jugador toca el cañón para disparar. Con mejoras, el cañón dispara solo y apunta mejor. Se pueden comprar hasta tres cañones más, en huecos fijos y con mejoras propias. Recoger y llevar bolas al hoyo se mantiene, y las bolas rápidas ya no caen al hoyo. El progreso guardado se reinicia: no hay jugadores reales y se borra el código de migración.

## Cómo usar este plan

- Personas: leer `00-overview.md` → `01-requirements.md` → `02-architecture.md` → `03-risks-open-questions.md`.
- Agente ejecutor: leer `AGENT_BRIEF.md` y después la siguiente tarea según el orden de ejecución.
- Hay una PR por epic, en orden. El APK se genera una sola vez, al final (E05-T03).

## Orden de ejecución

Generado con `python3 .claude/skills/project-planner/scripts/validate_plan.py docs/plan/canones`. Las tareas del mismo nivel pueden hacerse en cualquier orden.

| Nivel | Tareas | PR |
| --- | --- | --- |
| 1 | E01-T01 | 1 |
| 2 | E01-T02 | 1 |
| 3 | E02-T01 | 2 |
| 4 | E02-T02 | 2 |
| 5 | E02-T03, E02-T04 | 2 |
| 6 | E02-T05 | 2 |
| 7 | E03-T01 | 3 |
| 8 | E03-T02 | 3 |
| 9 | E04-T01 | 4 |
| 10 | E04-T02 | 4 |
| 11 | E05-T01 | 5 |
| 12 | E05-T02 | 5 |
| 13 | E05-T03 | APK y PR documental |

## Epics

| ID | Título | Tareas | Estado |
| --- | --- | --- | --- |
| [E01](epics/E01-cimientos.md) | Cimientos: guardado v6 y física configurable | 2 | Completado |
| [E02](epics/E02-canon-manual.md) | Cañón principal manual | 5 | Completado |
| [E03](epics/E03-automatico-punteria.md) | Automático y puntería del cañón 1 | 2 | Completado |
| [E04](epics/E04-mas-canones.md) | Cañones 2, 3 y 4 | 2 | Completado |
| [E05](epics/E05-cierre.md) | Cierre: balance, documentación y APK | 3 | Completado |

## Decisiones clave

- Disparo manual tocando el cañón. Las mejoras «Automático» y «Ritmo automático» lo automatizan y la recarga es compartida.
- Arco de 150°, barrido de ida y vuelta en 2 s, recarga de 1 s, disparo a 520 u/s y automático cada 1,5 s.
- El hoyo solo captura bolas libres a ≤ 140 u/s. Rebote en paredes de 0,55. El cuerpo del cañón es sólido.
- «Puntería» estrecha el arco. Se eliminan «Generador rápido» y «Doble emisión».
- Cuatro huecos fijos: G1 arriba, G2 a la izquierda (20, 150), G3 a la derecha (340, 150) y G4 abajo (180, 540). Mejoras por cañón.
- Guardado v6: las partidas antiguas se descartan sin aviso.

## Supuestos a revisar

- SUPUESTO-1: precios provisionales de las mejoras de cañón.
- SUPUESTO-2: Puntería I de cada cañón requiere su Automático (G1) o su desbloqueo (G2–G4).
- SUPUESTO-3: disparar no tiene sonido.
- SUPUESTO-4: la escoba y el robot no chocan con el cuerpo del cañón.
- SUPUESTO-5: la escoba y el robot mantienen sus posiciones iniciales.

## Preguntas abiertas que bloquean

Ninguna. PA-1 (precio de Mano I) se revisa jugando el APK.

## Historial

- 2026-11-10: versión inicial, tras tres rondas de entrevista con el usuario.
- 2026-11-10: bloqueo de E02-T03 resuelto con la opción 2. «Día más largo» requiere `reward:2` de forma temporal (E02-T03) y `g1_auto_speed:1` de forma definitiva (E03-T02). Se ha simulado la prueba de geometría del árbol en los tres estados intermedios y pasa. Corrección: `_collide` tenía dos `.limit(380)`, no cuatro. `isInterval` pasa a `effect.endsWith('_interval')` (E02-T03) y E03-T02 añade `_arc`. E03-T02 también actualiza el límite Y de `skill_tree_test.dart` (1056 → `canvasHeight - 48`).
- 2026-11-10: plan ejecutado. PR 1–4: #28, #29, #30 y #31, fusionadas en `main`; PR 5 (E05, documentación y versión 0.6.0+11) abierta con este cambio. El APK se registra en la PR documental de E05-T03. 169 pruebas.
