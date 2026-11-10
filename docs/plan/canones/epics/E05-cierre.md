---
id: E05
title: Cierre — balance, documentación y APK
depends_on: [E04]
requirements: [RNF-03, RNF-04]
---

# E05 · Cierre: balance, documentación y APK

## Objetivo

Verificar que el balance inicial es alcanzable, dejar la documentación del repositorio alineada con el juego nuevo y publicar un único APK de prueba.

## Alcance

- Incluido: pruebas de invariantes de balance, documentación, versión 0.6.0+11 y pipeline manual sobre `main`.
- No incluido: ajuste fino de precios jugando en Android físico (lo hace el usuario con el APK).

## Tareas

| ID | Título | Depende de | Tamaño |
| --- | --- | --- | --- |
| E05-T01 | Pruebas de invariantes de balance | E04-T02 | S |
| E05-T02 | Documentación y versión 0.6.0+11 | E05-T01 | M |
| E05-T03 | Generar el APK con la pipeline manual | E05-T02 | S |

## Definición de terminado del epic

- [ ] PR 5 fusionada en `main`.
- [ ] Enlace al APK en `README.md` y `CHANGELOG.md`.
