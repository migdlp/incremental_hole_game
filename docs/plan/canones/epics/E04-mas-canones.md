---
id: E04
title: Cañones 2, 3 y 4
depends_on: [E03]
requirements: [RF-13, RF-14]
---

# E04 · Cañones 2, 3 y 4

## Objetivo

El jugador compra hasta tres cañones más en huecos fijos. Cada uno llega manual y tiene sus propias mejoras de Automático, Ritmo automático y Puntería.

## Alcance

- Incluido: creación de cañones según `gN_enabled`, guardado de N cañones, bases y mejoras G2–G4 en el CSV y nodos del árbol.
- No incluido: mover o colocar cañones a mano.

## Diseño

Ver `../02-architecture.md`: huecos en «Contrato de `cannon.dart`», filas `g2_*`–`g4_*` en «Balance» y rutas en «Árbol». El dibujo de E02-T05 ya recorre `board.cannons`, así que no hace falta trabajo visual.

## Tareas

| ID | Título | Depende de | Tamaño |
| --- | --- | --- | --- |
| E04-T01 | Tablero con cuatro huecos | E03-T02 | M |
| E04-T02 | Mejoras de G2–G4 en balance y árbol | E04-T01 | M |

## Definición de terminado del epic

- [ ] Las dos tareas en `done`.
- [ ] Manual en web, con un guardado de prueba con saldo alto: comprar Cañón 2, 3 y 4 y ver los cuatro cañones disparando hacia el interior.
- [ ] PR 4 (`feat/canones-e04-mas-canones` → `main`) en verde.
