---
id: E05-T02
title: Documentación y versión 0.6.0+11
epic: E05
status: todo
depends_on: [E05-T01]
requirements: [RNF-03]
size: M
---

# E05-T02 · Documentación y versión 0.6.0+11

## Objetivo

La documentación del repositorio describe el juego con cañones y la versión del paquete es `0.6.0+11`.

## Contexto

- Versión actual: `version: 0.5.0+10` en `pubspec.yaml`.
- Documentos con descripciones del generador antiguo, el balance y el guardado: `README.md`, `CHANGELOG.md`, `docs/estado-actual.md`, `docs/implementacion.md`, `docs/persistencia.md`, `docs/economia.md` y `docs/arbol-de-mejoras.md`.
- Convenciones en `docs/guia-documentacion.md`: distinguir «Implementado», «Verificado» y «Pendiente», y no atribuir funciones futuras.
- Hechos a documentar:
  - Cañones G1–G4 en huecos fijos, con arco de 150°, barrido de 2 s, recarga de 1 s y disparo a 520 u/s.
  - Captura solo a ≤ 140 u/s salvo bolas agarradas. Rebote 0,55 y velocidad máxima de 600.
  - Mejoras por cañón: Automático, Ritmo automático y Puntería, con 28 tipos y 74 nodos.
  - Generador rápido y Doble emisión eliminados.
  - Guardado v6 sin migraciones: las partidas anteriores se descartan.
  - Precios provisionales.

## Archivos

- Modificar: `pubspec.yaml`, `README.md`, `CHANGELOG.md`, `docs/estado-actual.md`, `docs/implementacion.md`, `docs/persistencia.md`, `docs/economia.md`, `docs/arbol-de-mejoras.md`
- Modificar: `docs/plan/canones/README.md` (estado de las tareas)
- No tocar: `lib/` y `test/`

## Pasos

1. `pubspec.yaml`: `version: 0.6.0+11`.
2. `CHANGELOG.md`: nueva sección al principio, `## Generadores-cañón — <fecha de hoy> · 0.6.0+11`, con 5–7 viñetas de los hechos anteriores y el número real de pruebas que da `flutter test`.
3. `README.md`: en «Lo que ya funciona», sustituye la viñeta del generador y los 1,5 bolas/s por los cañones. En «Ejecutar» y «Validar» no cambies nada. Quita las menciones a compatibilidad v1–v5.
4. `docs/persistencia.md`: formato v6, campos `cannonClock` y `cannons`, y el hecho de que se ignoran las versiones anteriores. Elimina las secciones de migración.
5. `docs/implementacion.md`, `docs/estado-actual.md`, `docs/economia.md` y `docs/arbol-de-mejoras.md`: sustituye las descripciones del generador y de sus mejoras por los cañones, siguiendo `docs/plan/canones/02-architecture.md`. Marca la validación en Android físico como «Pendiente».
6. `docs/plan/canones/README.md`: pon `Estado: completado` y añade al «Historial» la fecha y los PR.

## Criterios de aceptación

- [ ] `grep -rn "1,5 bolas\|Doble emisión\|Generador rápido\|JSON v5" README.md docs/*.md` no devuelve nada fuera de `CHANGELOG.md`, de los planes históricos (`docs/plan-*.md`) ni de `docs/cambios-futuros-arbol-mejoras.md`.
- [ ] `pubspec.yaml` tiene `0.6.0+11`.

## Verificación

```bash
grep -n "^version:" pubspec.yaml
flutter test
```

## Fuera de alcance

- Reescribir documentos históricos (`docs/plan-*.md`, `docs/cambios-futuros-arbol-mejoras.md` y `docs/PRD-game-incremental.md`).

## Si te bloqueas

- Si un documento mezcla hechos históricos y actuales, añade una nota al principio («Actualización 0.6.0+11:» seguida del cambio) en lugar de reescribir el historial.
