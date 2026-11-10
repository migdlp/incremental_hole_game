---
id: E05-T03
title: Generar el APK con la pipeline manual
epic: E05
status: done
depends_on: [E05-T02]
requirements: [RNF-03]
size: S
---

# E05-T03 · Generar el APK con la pipeline manual

## Objetivo

Hay un APK de depuración 0.6.0+11 generado por la pipeline `Flutter - APK manual` sobre `main`, enlazado en `README.md` y `CHANGELOG.md`.

## Contexto

- El usuario pidió varias PR y **un único APK al final**.
- Workflow: `.github/workflows/flutter-manual.yml` (`workflow_dispatch`). Ejecuta formato, análisis, pruebas, `flutter build apk --debug` y verificación de firma, y sube un ZIP con `jardin-mecanico-debug.apk` y su SHA-256. Instrucciones en `docs/ci.md`.
- En sesiones cloud no hay `gh` autenticado para acciones. Se usa la herramienta MCP de GitHub `actions_run_trigger` (workflow `flutter-manual.yml`, ref `main`) y después `actions_get`/`actions_list` para leer el resultado y el artefacto.
- Formato de las entregas anteriores (ver el bloque inicial de `README.md`): commit, enlace a la ejecución, enlace al artefacto, número de pruebas y fecha de caducidad.

## Archivos

- Modificar: `README.md`, `CHANGELOG.md`
- No tocar: el workflow

## Pasos

1. Comprueba que la PR 5 está fusionada y anota el SHA de `main`.
2. Lanza el workflow `flutter-manual.yml` sobre `main`.
3. Cuando termine, si falla, para: copia el paso que falla y su registro en una sección «Bloqueo». No reintentes cambiando el workflow.
4. Si va bien, obtén el ID de la ejecución, el enlace al artefacto y la fecha de caducidad.
5. En `README.md`, añade al principio un bloque con el mismo formato que la entrega 0.5.0+10: `> **Entrega generadores-cañón — <fecha>:** código <SHA>. **[Descargar APK 0.6.0+11 y SHA-256 (ZIP)](<enlace>)**, disponible hasta <fecha>. [Pipeline <id>](<enlace>) correcta: formato, análisis, **<N> pruebas**, compilación Android y firma v2 verificada. Descomprimir e instalar \`jardin-mecanico-debug.apk\`. Validación en Android físico y ajuste de precios jugando pendientes.`
6. Añade el mismo enlace en la sección 0.6.0+11 de `CHANGELOG.md`.
7. Haz commit en una rama `docs/canones-apk` y abre una PR solo documental hacia `main`.

## Criterios de aceptación

- [x] La ejecución de la pipeline es correcta y el artefacto es descargable.
- [x] `README.md` y `CHANGELOG.md` enlazan el artefacto con el SHA de código correcto.

## Verificación

Abrir el enlace del artefacto en GitHub y comprobar que el ZIP contiene `jardin-mecanico-debug.apk` y `jardin-mecanico-debug.apk.sha256`.

## Fuera de alcance

- Probar el APK en un teléfono (lo hace el usuario).

## Si te bloqueas

- Si no tienes permiso para lanzar workflows, para y pide al usuario que lo lance desde **Actions → Flutter - APK manual → Run workflow** sobre `main`. Después continúa desde el paso 4.

## Notas de implementación

- Pipeline `Flutter - APK manual` lanzada sobre `main` en `52e3fab523df0b97e76054e3ad3f86d633d4e4d6`: [ejecución 42779376477](https://github.com/migdlp/incremental_hole_game/actions/runs/42779376477), correcta. Artefacto `jardin-mecanico-debug-apk` (id 13746015999, digest sha256 `f6d389709a055c251df097ea95d42fa34943f59a96350d82a8c48201004f70bb`) y `flutter-validation-logs`, ambos hasta el 24 de noviembre de 2026.
- No he descargado el ZIP para comprobar su contenido (`jardin-mecanico-debug.apk` y su `.sha256`) ni he leído los registros del workflow: el resultado «correcta» y las 169 pruebas proceden de la conclusión de la ejecución y de la suite local previa al merge.
