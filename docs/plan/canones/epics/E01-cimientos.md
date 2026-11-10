---
id: E01
title: Cimientos — guardado v6 y física configurable
depends_on: []
requirements: [RF-06, RF-07, RF-16]
---

# E01 · Cimientos: guardado v6 y física configurable

## Objetivo

Quitar el código de migración, que frena cada cambio, y preparar la física para disparos rápidos. El juego se ve y se juega igual que hoy, salvo que las bolas libres muy rápidas ya no caen en el hoyo.

## Alcance

- Incluido: guardado v6 sin migraciones, borrado de los balances congelados y parámetros `max_ball_speed`, `wall_restitution` y `hole_capture_speed`.
- No incluido: cañón (E02) ni cambios en el árbol.

## Diseño

Ver `../02-architecture.md`, secciones «Guardado (versión 6)», «Cambios de física en `Board.update`» y ADR-01/ADR-02.

## Tareas

| ID | Título | Depende de | Tamaño |
| --- | --- | --- | --- |
| E01-T01 | Guardado v6 sin migraciones | — | M |
| E01-T02 | Física configurable y captura por velocidad | E01-T01 | M |

## Definición de terminado del epic

- [ ] Las dos tareas en `done`.
- [ ] PR 1 (`feat/canones-e01-cimientos` → `main`) abierta con formato, análisis y pruebas en verde.
