# APK manual de Flutter

En GitHub, abrir **Actions → Flutter - APK manual → Run workflow**, seleccionar la rama y ejecutar. Solo se activa manualmente mediante `workflow_dispatch`; no se dispara con pushes ni pull requests.

La pipeline prepara JDK Temurin 21 completo, Android SDK Platforms 35/36, Build Tools 35.0.0, NDK 27.0.12077973 y CMake 3.22.1. Instala Flutter 3.35.7 estable con Dart 3.9.2 y comprueba el SHA-256 oficial del SDK.

Después ejecuta doctor, resolución de dependencias, comprobación de formato, análisis, pruebas y `flutter build apk --debug --no-pub` sobre la aplicación del repositorio. Si falta la aplicación, falla expresamente. Un fallo de análisis, pruebas o compilación impide generar el artefacto del APK.

Cuando termina correctamente, el resumen de la ejecución enlaza el artefacto **jardin-mecanico-debug-apk**. También se encuentra al final de la página de la ejecución, en **Artifacts**. Contiene:

- `jardin-mecanico-debug.apk`, con firma comprobada mediante `apksigner`.
- `jardin-mecanico-debug.apk.sha256`, para comprobar la integridad de la descarga.

Los registros se guardan en **flutter-validation-logs**, incluso cuando falla la ejecución. Ambos artefactos se conservan 14 días. Es necesario iniciar sesión en GitHub para descargar los artefactos.

Este APK usa la firma de depuración para probar el prototipo. La pipeline no publica aplicaciones ni ejecuta pruebas en un teléfono físico. Una compilación correcta no certifica interacción, balance ni rendimiento en móvil.
