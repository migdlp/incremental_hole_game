# AUD01 — Auditoría técnica del juego, árbol completo de mejoras y sistemas económicos

**Proyecto:** Feed the Hole  
**Responsable:** Agente desarrollador / Codex  
**Estado:** Ready for Development (tarea de auditoría documental; no implementar cambios)  
**Prioridad:** Alta  
**Dependencia de salida:** BAL01 — análisis de economía y balance del Game Designer.

## 1. Objetivo

Inspeccionar el **repositorio y el comportamiento realmente implementado** de Feed the Hole y entregar un inventario técnico verificable de **todas las mejoras, habilidades, reglas, fórmulas, costes, límites y flujos económicos**. La entrega debe permitir que un Game Designer calcule cuánto se produce, cuánto se captura, cuánto se cobra, qué se puede comprar, cuándo se pierde y cómo evoluciona una partida.

**No programar ni corregir funcionalidades.** Si se detectan divergencias entre lo definido y el código, registrarlas claramente. No presentar reglas previstas como si ya existieran en el juego.

## 2. Contexto funcional que hay que contrastar

El proyecto es un videojuego móvil vertical con físicas, un generador de bolas, un agujero que las absorbe, jornadas de producción, monedas, mejoras normales, cuotas, derrota, estrellas, prestigio y progresión permanente.

Estas reglas forman parte del diseño aprobado y deben verificarse contra el estado real del repositorio:

- Las cuotas requieren **100, 1.000, 10.000, 100.000… bolas capturadas**; cada objetivo es diez veces el anterior. Una bola válida cuenta **+1** aunque valga muchas monedas.
- Cada cuota dispone de **4 jornadas**, contando como primera la jornada en la que se activa, incluso si empezó a mitad de esa jornada. Al completarse se pasa inmediatamente a la siguiente y se conservan los excedentes.
- Si concluye la cuarta jornada sin completar la cuota activa, hay **derrota directa, sin resumen normal**; las capturas válidas del cierre se procesan antes de decidirla y no hay tiempo extra.
- El plazo solo se muestra en el **resumen** de jornada, no durante la partida.
- Completar una cuota aumenta el **área del agujero un 16 %** (radio × √1,16), y puede generar burbujas físicas de estrellas (P01).
- El árbol de mejoras normales no es accesible **antes de finalizar la primera jornada de cada nueva partida**.
- El prestigio puede proceder de derrota o de un nodo voluntario del árbol normal (S03). Las estrellas recogidas y habilidades permanentes se conservan; las burbujas sin romper se pierden.
- P02 define cuatro habilidades permanentes compradas con estrellas: **Herencia** (2 estrellas, 100 monedas iniciales), **Eco de producción** (6, 5 bolas adicionales cada 20 ciclos del generador principal), **Fiebre dorada** (8, una bola dorada extra por jornada), **Lluvia astral** (12, 50 % de duplicar las burbujas físicas por cuota).
- E03 define doce cartas con cinco niveles cada una, progreso permanente y **una elección por cuota completada**; los niveles máximos se excluyen de los sorteos. Las cuotas repetidas tras prestigiar también otorgan elecciones.
- AJ-009 diferencia el **saldo monetario** de la **representación visual de las monedas recogidas durante la jornada**. No confundir sprites con ingresos reales.

**Regla del árbol que el usuario quiere documentar y comprobar:** cada nodo debe tener **entre 0 y 4 nodos vecinos distintos, nunca más de 4**. Tratarlo como requisito de diseño a contrastar con el código, **no como hecho ya verificado**.

S03, AJ-008A y C01 han sido marcadas como definidas por el usuario. **Eso no prueba que estén implementadas**: registrar su grado real de integración. Si no se dispone de la especificación completa de alguna, declarar esa limitación y extraer las reglas directamente de las fuentes disponibles, sin inventarlas.

## 3. Inventario exhaustivo del árbol normal

Recorrer todas las definiciones de datos, nodos visibles u ocultos, generadores del árbol, lógica de desbloqueo, pantalla y guardado. Incluir también nodos especiales, inaccesibles temporalmente, obsoletos y de prestigio, distinguiendo su estado.

Para **cada nodo**, documentar al menos:

| Campo | Información requerida |
|---|---|
| `id` | Identificador estable, único |
| Nombre | Texto visible al jugador |
| Estado | Implementado / parcial / definido no implementado / deshabilitado / obsoleto |
| Categoría | Producción, física, economía, prestigio, etc. |
| Descripción | Qué hace exactamente |
| Máximo nivel | Nivel inicial, máximo y efectos por nivel |
| Coste | Fórmula o tabla de compra por nivel; moneda empleada |
| Desbloqueo | Requisitos, dependencias, días, permisos, condiciones del nodo |
| Vecinos | IDs de todos los nodos conectados |
| Posición | Posición/coordenadas, si se usan para dibujar el árbol |
| Persistencia | Se pierde al morir/prestigiar o permanece |
| Efecto | Variables que modifica y momento de aplicación |
| Acumulación | Cómo interactúa con nodos y habilidades semejantes |
| Código | Ruta de archivo y clase/función/constante que lo respalda |

### Validación explícita de conexiones (regla de 0 a 4 vecinos)

1. Reconstruir el grafo completo a partir de la fuente real, no de una impresión visual.
2. Contar **vecinos distintos** de cada nodo; una conexión bidireccional entre A y B cuenta como **un vecino** para cada extremo.
3. Verificar que `0 <= número_de_vecinos_distintos <= 4` para cada nodo.
4. Informar de todos los nodos que superen cuatro vecinos, con sus conexiones y evidencia.
5. Identificar enlaces rotos, referencias inexistentes, IDs duplicados, conexiones asimétricas cuando deban ser bidireccionales, componentes aislados y requisitos de acceso imposibles.
6. Los nodos con cero vecinos **no infringen por sí mismos la regla numérica**; señalar aparte si generan problemas de accesibilidad o diseño.
7. Diferenciar **vecindad en el grafo** de **requisitos de compra/desbloqueo**; no asumir que son equivalentes.
8. **No modificar ni reconectar nodos** durante esta auditoría.

Generar una representación navegable o legible del árbol completo (por ejemplo, Mermaid, Graphviz o listado jerárquico acompañado de tabla de aristas), sin ocultar ramas.

## 4. Inventario de todas las habilidades y mecánicas

Cubrir tanto las mejoras normales del árbol como **habilidades ajenas al árbol**:

- **P02:** las cuatro habilidades de prestigio; niveles/compra, costes, disparadores, exclusiones, persistencia y fórmulas actuales; registrar diferencias con la especificación.
- **E03:** las doce cartas, niveles 0–5, parámetros por nivel, sistema de ofertas aleatorias, triggers, duraciones, enfriamientos y guardado. Incluir Remolino, Hambre insaciable, Latido, Rebote dirigido, Bola ariete, Gravedad traviesa, Disparo frenético, Último esfuerzo, Doble ración, Racha millonaria, Toque de Midas y Golpe de suerte.
- Otras mejoras, cartas, eventos, poderes, evoluciones, bolas especiales, gadgets y efectos existentes en el repositorio que no figuren en estos catálogos.
- Tiers/tipos de bola, variantes doradas, valores económicos, tamaño/masa, probabilidad de aparición, lógica de evolución y posibles restricciones.
- Generador principal y generadores secundarios, especialmente si sus ciclos computan de forma diferente.
- Mecanismos de físicas, agujero, obstáculos y herramientas que puedan afectar la tasa de captura.
- Cobro automático (C01), balances de monedas, gastos, reembolsos si existieran, y diferencias entre ganancias reales y presentación visual.
- Burbuja/cristal de estrellas P01, Lluvia astral, puntos de ruptura, recolección y pérdida al prestigiar.

Para cada habilidad/mecánica: **ID, nombre, propósito, estado real, efecto cuantitativo, activación, límites, costes, sinergias, ubicación exacta en el código**.

## 5. Extracción económica y de producción: indispensable para BAL01

### 5.1 Tiempo y producción

Documentar:

- Duración de jornada y de fase de producción **en segundos de juego activo**, pausas y fases intermedias.
- Cada cuánto dispara el generador principal: ciclos por segundo o intervalo, fórmula inicial, mejoras y límites.
- Cuántas bolas genera **cada ciclo**, separando base, adicionales, especiales y multiplicadores.
- Segundo generador y fuentes indirectas de bolas: frecuencia, probabilidades, condicionantes y si se mezclan con el principal.
- Aleatoriedad, distribución de tipos/tiers y condiciones de aparición de bolas doradas.
- Máximos de bolas simultáneas, colas de spawn, descartes y límites físicos o de rendimiento.
- Rutas del código que producen, modifican, capturan o eliminan bolas.

### 5.2 Captura real, no solo generación

Documentar el recorrido completo **generada → aparece en tablero → se mueve → es capturada / permanece / se pierde**:

- Momento exacto en que una bola se considera capturada y alimenta la cuota.
- Número de bolas generadas y capturadas por jornada, si hay telemetría o pruebas reproducibles.
- **Tasa de captura** = capturadas / generadas; separar por tipo/tier, tamaño del agujero y mejoras.
- Bolas que siguen en tablero al acabar la producción y reglas de transición.
- Posibles cuellos de botella: velocidad de generación, zona de absorción, obstáculos, dinámica física, límite de entidades.
- Efectos sobre captura por modificaciones del radio (+16 % de área por cuota), gravedad, rebotes, succión y masa.
- Diferenciar las bolas no capturadas de las descartadas por un límite técnico.

Si no existen métricas suficientes, especificar exactamente **qué instrumentación no invasiva** falta; proponerla como tarea separada. No inventar porcentajes de captura.

### 5.3 Dinero y gasto

Extraer:

- Valor de monedas por bola, por tier y por tipo especial.
- Fórmulas de valor, bonus, probabilidades económicas y orden de aplicación.
- Multiplicadores de cartas E03, incluidos Racha millonaria (×2 en niveles 1–3, ×3 en niveles 4–5) y Golpe de suerte, si existen en código.
- Costes normales del árbol por nodo y nivel; curvas, precios iniciales, topes, inflación y condiciones.
- Herencia y cualquier otro ingreso inicial; distinguir saldo heredado de **ingreso ganado durante una jornada**.
- Disponibilidad real de compras (árbol bloqueado durante jornada 1 de cada partida).
- Fuentes y sumideros de monedas; uso y descuento en compras, ganancias diarias y posible almacenamiento.
- Coste y condiciones del **nodo de prestigio voluntario**: extraer valor y origen documentado; si no existe, marcarlo como no implementado/no localizable.

### 5.4 Estrellas, prestigio y cartas

Extraer:

- Número, denominación y probabilidades de burbujas de estrellas por cuota.
- Tasas de burbujas que se rompen realmente, si son medibles; estrellas recogidas ≠ estrellas potencialmente generadas.
- Balance del saldo permanente y costes P02: Herencia 2, Eco 6, Fiebre 8, Lluvia astral 12 estrellas.
- Eventos de Lluvia astral y tratamiento de cuotas múltiples.
- Cadencia de elecciones E03, persistencia de niveles y saturación del catálogo de 60 subidas posibles.
- Reinicios en derrota y prestigio voluntario; qué recursos se pierden y cuáles se mantienen.

## 6. Verificaciones y evidencias

Para cada número o regla entregada:

- Indicar **archivo, símbolo relevante y versión/commit** del repositorio, cuando sea posible.
- Marcar como `VERIFICADO EN CÓDIGO`, `OBSERVADO EN EJECUCIÓN`, `DEFINIDO PERO NO IMPLEMENTADO`, `INFERIDO` o `DESCONOCIDO`.
- Ante contradicción, mostrar **comportamiento actual**, **comportamiento definido** y **diferencia**, sin corregirla.
- Si es viable, ejecutar pruebas o escenarios reproducibles de solo lectura y registrar condiciones, semillas aleatorias y resultados.
- Separar los valores fijos de los que dependen de modificaciones, estado persistente o azar.
- No incluir secretos, tokens, credenciales ni datos privados en la entrega.

## 7. Entregables obligatorios

Guardar en Markdown y, para los inventarios extensos, también en formato procesable:

1. `AUD01_informe_tecnico.md`: resumen, arquitectura relevante, diagramas, fuentes de verdad y discrepancias.
2. `AUD01_nodos.csv`: **todos** los nodos con campos del apartado 3.
3. `AUD01_conexiones.csv`: pares origen-destino, naturaleza de la arista y fuentes.
4. `AUD01_habilidades.md` o `.csv`: árbol + P02 + E03 + resto de sistemas, con niveles y fórmulas.
5. `AUD01_economia.md`: generación, captura, monedas, costes, estrellas, cuotas y tiempo; tabla de constantes.
6. `AUD01_desconocidos_y_riesgos.md`: información faltante, divergencias, mediciones necesarias y su prioridad.

Si un formato no puede producirse por falta de acceso, indicar claramente qué datos faltan y por qué. **No simular una auditoría realizada.**

## 8. Criterios de aceptación

- [ ] Se han inventariado todos los nodos y aristas del árbol, incluidos los especiales y ocultos.
- [ ] Se ha validado y reportado **para cada nodo** el número de vecinos distintos, especialmente los que excedan cuatro.
- [ ] Se han documentado costes, niveles, desbloqueos, efectos y persistencia por nodo.
- [ ] Se han inventariado todas las habilidades fuera del árbol y se ha contrastado P02 y E03 con el código.
- [ ] Se han documentado fórmulas de producción y **de captura real** o, si falta medición, la instrumentación necesaria.
- [ ] Se han identificado todas las fuentes y sumideros económicos conocidos.
- [ ] Se han documentado reglas de cuotas, cuatro jornadas, recompensas, derrota y prestigio.
- [ ] Las cifras tienen evidencia y distingue implementación de especificación.
- [ ] Se han señalado las incógnitas y posibles contradicciones sin inventar respuestas.
- [ ] Los entregables permiten alimentar BAL01 sin depender de una explicación oral adicional.
- [ ] No se ha modificado el gameplay, el balance ni la topología del árbol.

## 9. Dependencias y fuera de alcance

**Depende de:** acceso al repositorio actual y, si existe, a una compilación ejecutable o tests. Consultar las especificaciones aprobadas del proyecto cuando estén disponibles.

**Fuera de alcance:** implementar habilidades, rediseñar pantallas, modificar costes, arreglar nodos, reestructurar el árbol, cambiar probabilidades, introducir telemetría persistente o decidir el balance final. Los problemas detectados deben convertirse en propuestas o tareas nuevas para validación del usuario.
