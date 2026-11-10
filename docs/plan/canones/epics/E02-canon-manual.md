---
id: E02
title: Cañón principal manual
depends_on: [E01]
requirements: [RF-01, RF-02, RF-03, RF-04, RF-05, RF-08, RF-09, RF-15, RF-17, RF-18, RF-19, RF-21, RF-22, RF-24, RF-25, RF-26, RF-27]
---

# E02 · Cañón principal manual

## Objetivo

El generador antiguo desaparece. G1 oscila y dispara bolas con fuerza cuando el jugador lo toca. Las mejoras «Generador rápido» y «Doble emisión» desaparecen del árbol.

## Alcance

- Incluido: modelo `Cannon`, integración en `Board`, guardado del estado del cañón, toque prioritario, obstáculo, dibujo, textos de ayuda y retirada de las mejoras antiguas.
- No incluido: disparo automático y puntería (E03) ni cañones 2–4 (E04).

## Diseño

Ver `../02-architecture.md`: «Contrato de `cannon.dart`», «API de `Board`», «Toque», «Cambios de física» y «Balance». Durante este epic `Board.cannons` contiene solo G1 y `cannonAutomatic` devuelve siempre `false`, porque la clave `g1_automatic` no existe todavía.

## Tareas

| ID | Título | Depende de | Tamaño |
| --- | --- | --- | --- |
| E02-T01 | Modelo de dominio `Cannon` | E01-T02 | S |
| E02-T02 | Integrar G1 en `Board` y sustituir el generador | E02-T01 | L |
| E02-T03 | Retirar Generador rápido y Doble emisión | E02-T02 | M |
| E02-T04 | Toque prioritario y cuerpo sólido del cañón | E02-T02 | M |
| E02-T05 | Dibujo del cañón y textos de ayuda | E02-T04 | M |

## Definición de terminado del epic

- [ ] Las cinco tareas en `done`.
- [ ] En `flutter run -d chrome`: al comenzar el día, G1 oscila, tocarlo dispara, las bolas rebotan y una bola llevada al hoyo genera monedas.
- [ ] PR 2 (`feat/canones-e02-canon-manual` → `main`) en verde.
