# Validación manual de Flutter

En GitHub, abrir **Actions → Flutter - validación manual → Run workflow**. Solo se ejecuta manualmente; no se activa con pushes ni pull requests.

La pipeline instala Flutter 3.35.7 estable (Dart 3.9.2 incluido), comprueba el SHA-256 oficial y ejecuta `flutter doctor -v`, `flutter pub get`, `flutter analyze` y `flutter test`. Guarda los registros durante 14 días.

Mientras no exista `pubspec.yaml` en la raíz del repositorio, genera una aplicación temporal para comprobar el entorno. El resumen de la ejecución lo indica expresamente: una ejecución correcta no significa que el juego esté implementado o probado. Cuando exista la aplicación en la raíz, los mismos pasos se ejecutarán sobre su código y dependencias.

Esta pipeline no genera APK, no publica aplicaciones y no realiza pruebas en dispositivos Android.
