# Evidencias técnicas; ninguna partida humana

- `synthetic-reference-c573321.zip`:21 sesiones,63 archivos (JSON/CSV/resumen),
  siete escenarios y semillas42/79/2026, ejecutando GameSession desde el commit
  c5733216a887eb6da3fbb0121d0bd94fc72fb33b,0.24.0+38.
- `reference-manifest.json`:identidades y SHA-256 de todos los archivos y del ZIP.
- `reference-validation.json`:invariantes validadas;141 jornadas y4.497 emisiones,
  2.421 capturas,36 cuotas y15 derrotas sintéticas, no estadísticas humanas.
- `repeat-comparison.json`:segunda ejecución idéntica en los63 archivos;
  diferencias0/null, desglose por escenario. Es control de repetibilidad, no una
  mejora de balance entre versiones.
- `new-hand-42.csv`:ejemplo legible sin descomprimir.
- `physics-parity-176502d.json`:seis fingerprints idénticos con la base de producto
  previa176502d. Código/comando en tool/balance_physics_fingerprint.dart.
- `overhead-linux-aot.json`:medición aislada, siete repeticiones, sin render/Android;
  procedía del árbol de implementación antes del commit. No atribuirle un commit
  limpio no registrado. `overhead-concurrent-preliminary.json` tuvo interferencia
  del batch y se conserva solo para documentar la limitación.

Para validar o comparar los originales:

```sh
unzip docs/balance/BAL-TOOLS/results/synthetic-reference-c573321.zip -d /tmp/bal-reference
python3 tool/balance_compare.py /tmp/bal-reference
python3 tool/balance_compare.py /tmp/bal-reference /tmp/otra-version --out /tmp/bal-comparison
```

No sobrescribir este ZIP al cambiar juego/escenario; generar otro con commit y
manifest nuevos. Para comparaciones de balance cambiar de versión de código;
el test de repetición solo comprueba determinismo. Referencia humana pendiente04.
