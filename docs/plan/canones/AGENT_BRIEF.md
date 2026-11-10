# Instrucciones para el agente ejecutor

## Tu trabajo

Implementar las tareas de `tasks/` de una en una, en el orden de `README.md`, sin tomar decisiones de producto ni de arquitectura: ya están tomadas en `02-architecture.md`.

## Ramas y PR

- Cada epic es **una PR** contra `main`, con la rama indicada en `02-architecture.md` («Entregas y ramas»). Ejemplo: E01 → `feat/canones-e01-cimientos`.
- Crea la rama del epic desde `main` actualizado, **después** de que la PR del epic anterior esté fusionada. Si no lo está, para y avisa.
- Un commit por tarea, con el mensaje `<ID>: <título>` (p. ej. `E02-T03: Retirar Generador rápido y Doble emisión`).
- **No lances la pipeline de APK** hasta E05-T03. El usuario quiere un único APK al final.

## Antes de cada tarea

1. Comprueba que todas sus `depends_on` tienen `status: done`.
2. Lee la tarea entera y los archivos de código que menciona.
3. Cambia su `status` a `in_progress`.

## Durante

- Toca solo los archivos de «Archivos». Si necesitas otro, para y repórtalo.
- Convenciones del proyecto:
  - Dart 3.9 con `flutter_lints` (`analysis_options.yaml`). Código y comentarios nuevos en inglés. Textos de UI y documentación en español.
  - Dominio puro en `lib/features/<área>/domain/`, sin importar Flutter. Presentación en `presentation/` y `lib/app/`.
  - Valores de juego en `docs/balance.csv`. Toda clave base nueva se añade también a la lista de bases obligatorias de `UpgradeCatalog.fromCsv`.
  - Pruebas en `test/features/*_test.dart` con `package:flutter_test`, `testCatalog()` y `MemoryStore` de `test/test_support.dart`.
  - Coordenadas lógicas del tablero 360 × 560, con la Y hacia abajo.
- No añadas dependencias ni refactorices fuera del alcance.
- Si algo contradice el código real o es ambiguo, **no improvises**: pon `status: blocked`, añade una sección «Bloqueo» con lo que encontraste y las opciones que ves, y para.

## Al terminar

1. Ejecuta todos los comandos de «Verificación». Deben pasar.
2. Marca cada criterio de aceptación.
3. Cambia `status` a `done` y añade «Notas de implementación» (2–5 líneas: qué hiciste y cualquier desviación justificada).
4. Haz commit con `<ID>: <título>`.
5. Al terminar la última tarea del epic: `git push -u origin <rama>` y abre la PR con título `Cañones E0N: <título del epic>` y, en la descripción, la lista de tareas y el número de pruebas.

## Comandos del proyecto

- Dependencias: `flutter pub get`
- Formato: `dart format --output=none --set-exit-if-changed lib test`
- Análisis: `flutter analyze`
- Pruebas: `flutter test`
- Web local: `flutter build web --no-web-resources-cdn && python3 -m http.server 8123 --directory build/web`

## Entorno

Flutter **3.35.7** (Dart 3.9.2), fijado en `.fvmrc`. Si `flutter` no está en el `PATH`:

```bash
cd "$HOME"
curl -fL -o flutter.tar.xz \
  https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.7-stable.tar.xz
echo "146df531f9ac6a11a918013c1a70faafc053d4811c8cb69a413fd70748d51c3d  flutter.tar.xz" | sha256sum -c -
tar -xf flutter.tar.xz
export PATH="$HOME/flutter/bin:$PATH"
git config --global --add safe.directory "$HOME/flutter"
flutter --version   # debe mostrar 3.35.7
```

El checksum es el mismo que usa `.github/workflows/flutter-manual.yml`. Si no coincide, no sigas. No hace falta el SDK de Android: basta con las pruebas y el build web.
