# APK y validación en GitHub Actions

Abrir **Actions → Flutter - APK de prueba → Run workflow**, seleccionar `main` y confirmar **Run workflow**. También se ejecuta al subir cambios a `main` y al abrir o actualizar un PR hacia esa rama.

La pipeline instala Java 21, herramientas Android y Flutter 3.35.7, verifica el SHA-256 del SDK y resuelve las dependencias con el lockfile. Después comprueba formato, analiza el código, ejecuta las pruebas y compila `flutter build apk --debug --no-pub`. Si una comprobación falla, no publica un APK como si hubiera pasado.

## Descargar e instalar

1. Entrar en una ejecución completada correctamente.
2. Bajar hasta **Artifacts**.
3. Descargar `incremental-hole-game-debug-N`, donde N es el número de ejecución.
4. Descomprimir el ZIP y abrir `app-debug.apk` en un teléfono Android.
5. Si Android lo solicita, permitir instalar desde la aplicación utilizada para abrirlo.

El ZIP incluye el SHA-256 del APK. Los artefactos y registros se conservan 14 días; debes iniciar sesión en GitHub para descargarlos. Si una ejecución falla antes de compilar, solo puede haber registros, no APK.

La compilación usa firma de depuración y sirve para probar el prototipo. No requiere secretos de firma ni publica en Google Play. No equivale a una prueba de interacción o rendimiento en un teléfono físico. Los APK de distintas máquinas pueden usar claves debug diferentes; si Android rechaza actualizar una instalación anterior por la firma, desinstalarla elimina también sus datos locales.

El archivo de workflow es `.github/workflows/flutter-manual.yml`. La descarga del SDK y el trabajo completo tienen límites de tiempo para evitar ejecuciones indefinidas. Los logs se publican también cuando falla una comprobación.
