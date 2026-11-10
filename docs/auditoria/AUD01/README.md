# AUD01 — Árbol, mecánicas y economía

Auditoría documental de Feed the Hole **0.23.0+36**, realizada el **27/10/2026** sobre el commit `0778d139d4a85124e0af2a9f89d595dc19159430`.

> **Alcance temporal:** este informe conserva la revisión de la versión 0.23.0+36. La rama recibió después cambios de cuotas (25, 50, 100, 500, 1000…) en 0.23.1+37. Esos cambios posteriores no están auditados aquí. El verificador y los hashes corresponden al commit auditado y deben ejecutarse sobre una copia de ese commit.

**[Abrir la auditoría completa en un único Markdown](AUD01_completo.md)**

Para descargar desde GitHub, abre el archivo y utiliza **Download raw file / Descargar archivo**. Si la aplicación móvil no ofrece esa opción, abre el enlace en el navegador e inicia sesión con la cuenta que tenga acceso al repositorio.

## Informes

- [Informe técnico y árbol completo](AUD01_informe_tecnico.md).
- [Inventario de habilidades](AUD01_habilidades.md).
- [Economía y producción](AUD01_economia.md).
- [Desconocidos, discrepancias y riesgos](AUD01_desconocidos_y_riesgos.md).
- [Encargo original](AUD01_especificacion.md).

## Datos y evidencias

- [Nodos actuales e históricos (CSV)](AUD01_nodos.csv).
- [Conexiones y requisitos (CSV)](AUD01_conexiones.csv).
- [Constantes base (CSV)](AUD01_constantes.csv).
- [Grafo Mermaid](AUD01_arbol.mmd).
- [Verificación del grafo (JSON)](AUD01_grafo_verificacion.json).
- [Hashes de las fuentes (CSV)](AUD01_fuentes_sha256.csv).
- [Verificador de extracción estática](AUD01_verificar.py) y [resultado](AUD01_verificacion.txt).

La auditoría detecta un incumplimiento del máximo de cuatro vecinos: `hand:1` tiene seis. Se registran también diferencias de integración y mediciones pendientes. **No se ha modificado el juego ni se han corregido los hallazgos.**
