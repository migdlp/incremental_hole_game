# APK manual de Flutter

En GitHub, abrir **Actions → Flutter - APK manual → Run workflow**, seleccionar la rama y ejecutar. Solo se activa manualmente mediante `workflow_dispatch`; no se dispara con pushes ni pull requests.

La pipeline prepara JDK Temurin 21 completo, Android SDK Platforms 35/36, Build Tools 35.0.0, NDK 27.0.12077973 y CMake 3.22.1. Instala Flutter 3.35.7 estable con Dart 3.9.2 y comprueba el SHA-256 oficial del SDK.

Después ejecuta doctor, resolución de dependencias, comprobación de formato, análisis, pruebas y `flutter build apk --debug --no-pub` sobre la aplicación del repositorio. Si falta la aplicación, falla expresamente. Un fallo de análisis, pruebas o compilación impide generar el artefacto del APK.

Cuando termina correctamente, el resumen de la ejecución enlaza el artefacto **jardin-mecanico-debug-apk**. También se encuentra al final de la página de la ejecución, en **Artifacts**. Contiene:

- `jardin-mecanico-debug.apk`, con firma comprobada mediante `apksigner`.
- `jardin-mecanico-debug.apk.sha256`, para comprobar la integridad de la descarga.

Los registros se guardan en **flutter-validation-logs**, incluso cuando falla la ejecución. Ambos artefactos se conservan 14 días. Es necesario iniciar sesión en GitHub para descargar los artefactos.

Este APK usa la firma de depuración para probar el prototipo. La pipeline no publica aplicaciones ni ejecuta pruebas en un teléfono físico. Una compilación correcta no certifica interacción, balance ni rendimiento en móvil.

## Ejecución por CLI y evidencia

Con GitHub CLI autenticado y permiso para ejecutar Actions en el repositorio:

```bash
gh workflow run flutter-manual.yml --repo migdlp/incremental_hole_game --ref main
gh run list --repo migdlp/incremental_hole_game --workflow flutter-manual.yml --event workflow_dispatch
```

Última entrega de código comprobada: **0.2.1+3**, commit `1d71843dd96fa32b745bc770bfc154c42720ab7a`, [ejecución 39138119402](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402). Terminó correctamente el 18 de octubre: formato, análisis, **41 pruebas**, APK y firma.

**[Descargar APK y SHA-256 actuales](https://github.com/migdlp/incremental_hole_game/actions/runs/39138119402/artifacts/12141030218)**. GitHub descarga un ZIP: extraer e instalar `jardin-mecanico-debug.apk`. Caduca el 1 de noviembre de 2026. Este es el build con día inicial de 15 segundos y generación base cada 3 s; el APK anterior `0.2.0+2` conserva el balance previo.

Antecedentes: [0.2.0+2 / 36 pruebas](https://github.com/migdlp/incremental_hole_game/actions/runs/39136783858) y [0.1.0+1 / 17 pruebas](https://github.com/migdlp/incremental_hole_game/actions/runs/39020361800). Consultar siempre commit y resultado de la ejecución descargada. La documentación puede tener commits posteriores sin cambiar el código del APK; una descarga caducada tampoco indica fallo de compilación.

El job usa Ubuntu 24.04 y tiene un límite de 40 minutos. Bash propaga errores de tuberías con `pipefail`; los registros se guardan con `tee`. Una nueva ejecución sobre la misma referencia cancela otra que siga en curso, según el grupo de concurrencia del workflow. La comparación de lockfile es estricta mediante `flutter pub get --enforce-lockfile`.

El certificado debug no se conserva mediante una configuración de firma propia entre runners. Para actualizar una app ya instalada, revisar [compatibilidad de firma](guia-desarrollo.md) antes de desinstalar y perder progreso. No hay firma de producción ni publicación en tiendas, aunque el esqueleto Android conserve una configuración `release` de plantilla basada en firma debug.
