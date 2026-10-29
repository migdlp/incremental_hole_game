# Entrega BAL-TOOLS — 29/10/2026

Rama de trabajo `feat/bal-tools`, base de producto176502d (0.23.1+37),
build instrumentada0.24.0+38. Balance20 y formato de guardado17 conservados.
La referencia AUD01 es histórica de0.23.0+36; no se ha usado como HEAD actual.

## Implementación

- 01: contrato normativo `contrato-v1.md`; inventario previo conservado como
  borrador, con campos no medidos explicitados. Retención500d/2.000eventos/4MiB.
- 02: contadores en fábricas/capturas confirmadas de Board; sidecar acotado de
  origen/edad. Transacciones de economía, cuotas, P01/P02/E03 y final de partida
  en GameSession, incluyendo día final antes del borrado por derrota. Historial
  opcional guardado y caché JSON; no se consumen draws ni se escribe por frame.
- 03: sección desplegable en DEBUG, compartir/descargar JSON/CSV/texto y copiar
  JSON. El nuevo control conserva la posición de los botones DEBUG existentes.
  Las partidas normales previas conservan su etiqueta al abrir el exportador.
- 04: protocolo/plantilla listos, **sin sesiones humanas ni dispositivo Android
  disponible en el entorno cloud**. No se declaran esas pruebas completadas.
- 05: runner headless de GameSession; inputs documentados, semillas, dotaciones
  P02/E03, compras reales y curvas experimentales aisladas. Curva B no cambia
  gameplay y se detiene tras sus10 objetivos. No hay prestigio automático.
- 06: validador/comparador stdlib Python, JSON/CSV/Markdown, escenarios históricos
  preservables y tests en la CI manual. Implementación técnica disponible;
  aceptación final espera referencias humanas de04. Los cambios de balance
  intencionados no disparan un gate basado en tasas o importes aprobados.

## Verificación

Validación local: análisis sin incidencias, compilación web correcta y suite
completa500 pruebas verdes; nueve pruebas específicas finales verifican también
recuperación de métricas activas dañadas y hash. Seis escenarios contra176502d
coinciden byte a byte en fingerprints jugables: generaciones, recompensas, RNG,
controles, P02 y E03 (`tool/balance_physics_fingerprint.dart`).
Referencias generadas en el commit limpio
`c5733216a887eb6da3fbb0121d0bd94fc72fb33b`:21 sesiones/141 jornadas;
63 archivos idénticos en dos ejecuciones completas; validador sin incidencias y
comparador con diferencias cero y sin advertencias. ZIP, manifiesto SHA-256,
CSV y resultados en [results/](results/README.md). Dos pruebas Chromium pasaron
(hash VM/web y cuotas de500 dígitos). Comandos reproducibles en uso.md. Comparar estado de
Board con observer activado/desactivado incluye RNG, recompensas y serialización
jugable; el campo de métricas se excluye de esa igualdad.

Se encontraron dos fallos de interfaz en la primera suite completa: el panel
nuevo desplazaba el cierre de DEBUG. Se corrigió usando sección desplegable tras
los controles existentes; la repetición específica pasó19 pruebas. Esa ejecución
inicial fallida no se presenta como validación verde.

El primer benchmark tuvo carga concurrente; conservarlo como evidencia preliminar
no concluyente. La repetición aislada reportó+2,91% de mediana y−1,37% en p95
(medianas de siete repeticiones). El objetivo provisional <2%/<5% **no se puede
certificar con esos resultados**; el signo negativo en p95 refleja dispersión,
no una mejora causada por instrumentación. Falta medir en Android real. El
benchmark mide Board AOT, no coste de guardar historial/render/compartir.

## Límites de aceptación

- No existe línea base humana ni medición Android física;04 permanece pendiente.
- La hoja Android se valida por compilación e integración del plugin, pero la
  elección de destino/compartir en dispositivo debe cubrirse en04.
- Tiempos de pared por pantalla, contexto térmico y GPU físico no se inventan.
- Cohortes legacy parciales y métricas dañadas se recuperan sin invalidar juego;
  desconocido no se convierte en producción histórica ficticia.
- Los días DEBUG son sandbox, no se escriben en el save normal; exportarlos antes
  de salir/cerrar. La sesión normal sí persiste entre jornadas/tienda/restauración.
- No cambios de curva/precios/valores P02/E03, nuevos poderes, ventilador/embudo,
  narrativa, estrellas ni correcciones AUD-F01/AUD-F03.
