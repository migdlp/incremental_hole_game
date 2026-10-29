# Evidencias técnicas; ninguna partida humana

- `synthetic-reference-e9ae413.zip`:21 sesiones,63 archivos (JSON/CSV/resumen),
  siete escenarios y semillas42/79/2026, ejecutando GameSession desde el commit
  e9ae413494fab80f3f8599e0b384679e50dae5ad,0.24.0+38.
- `reference-manifest.json`:identidades y SHA-256 de todos los archivos y del ZIP.
- `reference-validation.json`:invariantes validadas;141 jornadas y4.497 emisiones,
  2.421 capturas,36 cuotas y15 derrotas sintéticas, no estadísticas humanas.
- `repeat-comparison.json`:segunda ejecución idéntica en los63 archivos;
  diferencias0/null, desglose por escenario. Es control de repetibilidad, no una
  mejora de balance entre versiones.
- `new-hand-42.csv`:ejemplo legible sin descomprimir, normalizado a LF;
  el ZIP conserva CSV original CRLF y sus hashes.
- `physics-parity-176502d.json`:seis fingerprints idénticos con la base de producto
  previa176502d. Código/comando en tool/balance_physics_fingerprint.dart.
- `overhead-linux-aot.json`:medición aislada, siete repeticiones, sin render/Android;
  procedía del árbol de implementación antes del commit. No atribuirle un commit
  limpio no registrado. `overhead-concurrent-preliminary.json` tuvo interferencia
  del batch y se conserva solo para documentar la limitación.

Para validar o comparar los originales:

```sh
unzip docs/balance/BAL-TOOLS/results/synthetic-reference-e9ae413.zip -d /tmp/bal-reference
python3 tool/balance_compare.py /tmp/bal-reference
python3 tool/balance_compare.py /tmp/bal-reference /tmp/otra-version --out /tmp/bal-comparison
```

No sobrescribir este ZIP al cambiar juego/escenario; generar otro con commit y
manifest nuevos. Para comparaciones de balance cambiar de versión de código;
el test de repetición solo comprueba determinismo. Referencia humana pendiente04.

- `export-restore-new-run-e9ae413.zip` y `export-continuity-validation.json`:
  cinco jornadas reales de GameSession automatizado, restauración en jornada2,
  derrota y continuación a segunda partida. CSV validado por lector independiente;
  dos exportaciones no alteran estado jugable. Comando:
  `flutter test tool/balance_export_smoke.dart --dart-define=SOURCE_COMMIT=<commit>`.
- El ZIP `synthetic-reference-c573321.zip` y su manifiesto `historical-reference-c573321-manifest.json`
  se conservan como evidencia histórica de desarrollo. La referencia normativa es
  e9ae413: incluye campos de trazabilidad CSV y copia de snapshots E03. En la
  revisión inicial algunas listas de ventanas E03 podían cambiar tras observarse;
  no usar sus snapshots históricos E03 para inferir efectos temporales.

- `historical-comparison-c573321-e9ae413.json/csv/md`:dos commits compatibles,
  mismos21 experimentos. Indicadores observados idénticos. No compara ventanas E03
  de la primera revisión, cuya limitación se documenta arriba.
- `scenarios/controlled-curves.json` (en carpeta hermana):experimento pareado de
  tres semillas con misma interacción, compras y horizonte; solo cambia curva de
  cuotas. Es hipótesis sintética, no autoriza valores en el juego ni sustituye04.
