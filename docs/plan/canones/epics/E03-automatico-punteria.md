---
id: E03
title: Automático y puntería del cañón 1
depends_on: [E02]
requirements: [RF-10, RF-11, RF-12, RF-20, RF-23, RF-28]
---

# E03 · Automático y puntería del cañón 1

## Objetivo

El jugador puede comprar que G1 dispare solo, que lo haga más a menudo y que su arco se estreche. El árbol amplía su lienzo para hacer sitio a las ramas de cañones.

## Alcance

- Incluido: lógica de disparo automático con recarga compartida, filas del CSV de G1, nodos del árbol de G1, lienzo de 864 × 1120 y requisito definitivo de «Día más largo».
- No incluido: cañones 2–4 (E04).

## Diseño

Ver `../02-architecture.md`: «API de `Board`» (bucle automático), «Balance» (filas `g1_*`) y «Árbol». El indicador visual de automático ya lo dibuja E02-T05 a partir de `cannonAutomatic`.

## Tareas

| ID | Título | Depende de | Tamaño |
| --- | --- | --- | --- |
| E03-T01 | Disparo automático con recarga compartida | E02-T05 | M |
| E03-T02 | Mejoras de G1 en balance y árbol | E03-T01, E02-T03 | M |

## Definición de terminado del epic

- [ ] Las dos tareas en `done`.
- [ ] Manual: comprar «Cañón 1 · Automático» (con un guardado de prueba con saldo) y ver que G1 dispara solo con el anillo ámbar.
- [ ] PR 3 (`feat/canones-e03-automatico` → `main`) en verde.
