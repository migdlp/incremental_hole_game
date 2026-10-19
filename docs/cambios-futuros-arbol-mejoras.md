# Cambios futuros: árbol de mejoras

> **Entrega Android — 19 de octubre de 2026:** PR #15 integrada en `main`, commit `27b3950146389f2db3f63cf708ffb289ed908859`. Versión **0.3.1+6**. [Pipeline 39181076818](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818) correcta: formato, análisis, 88 pruebas, compilación Android y firma verificada. [Descargar APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39181076818/artifacts/12155843676), disponible hasta el 2 de noviembre de 2026. Descomprimir e instalar `jardin-mecanico-debug.apk`. La prueba en Android físico y el ajuste de balance siguen pendientes. Las notas de preparación inferiores conservan el estado anterior a esta entrega.


**Referencia viva v0.7 · Implementación de CF-01 a CF-04 en 0.3.1+6, preparada para revisión.**

El usuario autorizó implementar este mapa el 19 de octubre de 2026. El [árbol actual](arbol-de-mejoras.md) documenta su ejecución y [balance.csv](balance.csv) contiene los costes y efectos. Las dos instrucciones más recientes prevalecen sobre el boceto original: Mano I permite llevar **dos** bolas (no tres), cada nivel añade una y la escoba solo aparece tras comprar su desbloqueo. El resto del mapa se implementa con sus cinco niveles, colores y requisitos cruzados.

El mapa de ramificaciones se conserva. Esta revisión implementa CF-01 a CF-04 y la aclaración de monedas sin cifras: base de $1, recogida final de 3 s, estadísticas → árbol → comenzar día y nodos apagados/blancos/coloreados según estado. Los precios y las mejoras de Valor existentes se conservan; su ajuste de ritmo sigue pendiente de sesiones reales. No hay nuevas probabilidades ni desbloqueos de denominaciones inventados.

## Aclaración de representación — 19 de octubre de 2026

Petición posterior del usuario: ninguna moneda muestra su valor sobre la cara, ni siquiera la de $1. La moneda normal sigue siendo amarilla/dorada. El saldo, los precios y las estadísticas sí muestran importes en dólares del juego.

Se autoriza implementar CF-01 a CF-04, conservando el mapa y las compras existentes. El resultado se registra con sus comprobaciones antes de darlo por entregado.

## Cambios añadidos — 19 de octubre de 2026

**Requisitos implementados en esta revisión; pendientes de revisión táctil en Android y de integración de la rama.** La numeración identifica cambios, no un orden de prioridad. Estas reglas sustituyen cualquier cifra o presentación contradictoria de propuestas anteriores. Se conservan las decisiones vigentes sobre mano y escoba de la nota inicial.

### CF-01 · Valor base y denominaciones de monedas

- [x] Una bola capturada en el hoyo genera **$1 de valor base**, representado por una moneda normal de un dólar.
- [x] Mostrar el dinero en dólares del juego, distinguiendo el importe de la cantidad de monedas físicas.
- [x] Usar únicamente denominaciones de **$1, $10, $50, $100 y $500**. No habrá moneda de $25.
- [x] Cada denominación tendrá un color propio. Las monedas no llevarán números, cantidades, símbolos de moneda ni texto dibujados sobre ellas; se identificarán visualmente por su color. El saldo y las estadísticas sí mostrarán importes.

| Denominación | Apariencia | Color HEX | Decisión |
| --- | --- | --- | --- |
| **$1** | 🟡 Dorada; moneda normal | `#EAB308` | Dorado indicado por el usuario. |
| **$10** | 🟢 Verde esmeralda | `#10B981` | Paleta propuesta. |
| **$50** | 🔵 Azul | `#3B82F6` | Paleta propuesta. |
| **$100** | 🟣 Violeta | `#A855F7` | Paleta propuesta. |
| **$500** | 🔴 Rojo coral | `#F43F5E` | Paleta propuesta. |

El color de una moneda representa su denominación; el color de un nodo del árbol representa el tipo de mejora. Son dos leyendas independientes.

**Implementado para las pilas:** cada importe se descompone en denominaciones válidas de mayor a menor. Por ejemplo, $61 se representa como $50 + $10 + $1; no se dibuja una moneda de $61. Las agrupaciones conservan el total y se cobran una sola vez, con hasta tres capas visuales por denominación para limitar el dibujo. Las denominaciones mayores aparecen al acumular suficiente valor en una pila, sin añadir premios aleatorios.

**Pendiente de diseñar juntos:** desbloqueos especiales de denominaciones, si se desean, y progresión final de Valor. No se presupone que cada bola vaya a generar una moneda de $500 ni se fijan probabilidades. El cambio a $1 obliga a recalcular el ritmo de ingresos y los precios futuros; no se mantienen como balance aprobado las cifras basadas en dos monedas por bola.

### CF-02 · Recogida final inicial de tres segundos

- [x] La fase nocturna de recogida de monedas empieza con **3 segundos de duración base**.
- [x] Tres segundos sustituye a la cifra de dos segundos mencionada y corregida en la petición, y a los cinco segundos de propuestas anteriores.
- [x] Esta duración corresponde solo a la fase de recogida final, no al tiempo de producción ni al tiempo para consultar estadísticas o comprar mejoras.

Se conserva el comportamiento previsto de recogida final con el resto del tablero detenido. Con una base de 10 segundos de producción, el ciclo activo inicial es de **13 segundos en total**. No se define todavía una mejora para ampliar la recogida; si se añade, partirá de esos tres segundos.

### CF-03 · Estadísticas → árbol independiente → siguiente día

- [x] El pop-up de estadísticas tendrá **un único botón: «Ir al árbol de mejoras»**.
- [x] El árbol de mejoras será una **pantalla independiente**.
- [x] Esa pantalla tendrá el botón **«Comenzar día»**, que inicia directamente el siguiente día.
- [x] El pop-up de estadísticas dejará de ofrecer «Comenzar día»; el recorrido ya no obliga a regresar al resumen para iniciarlo.

```text
DÍA EN JUEGO
     ↓
RECOGIDA FINAL · 3 s de base
     ↓
POP-UP DE ESTADÍSTICAS
[Ir al árbol de mejoras]
     ↓
PANTALLA DEL ÁRBOL
[Comenzar día]
     ↓
SIGUIENTE DÍA
```

### CF-04 · Estilo visual del árbol según estado

- [x] Rediseñar el estilo del árbol para distinguir los tipos de mejora y el estado de cada nodo.
- [x] **Comprada:** mostrar el icono y el color de su tipo o grupo.
- [x] **Sin comprar y no disponible para compra:** mostrar el nodo apagado, con icono y contorno atenuados.
- [x] **Sin comprar y comprable:** iluminar el nodo con una luz blanca suave, como una activación parcial. Exige requisitos cumplidos y dinero suficiente.
- [x] Mantener visibles las conexiones necesarias para entender las ramificaciones, respetando el descubrimiento progresivo.

| Estado | Icono y presentación |
| --- | --- |
| Comprada | Icono visible con el color de su tipo; marca de compra complementaria. |
| Sin comprar, bloqueada o sin dinero | Apagada, gris y con poco brillo; el motivo se indica al consultar. |
| Comprable | Icono y borde en blanco suave, con resplandor moderado; aún no usa la presentación de comprada. |

Los tipos mantienen la paleta del apartado «Tipos y colores». El brillo blanco indica que puedes comprar; el color de categoría identifica lo que ya has adquirido.

### Comprobaciones de la implementación

- Una captura sin mejoras genera exactamente $1; recogerla aumenta el saldo una sola vez en $1.
- Solo aparecen denominaciones permitidas y cada una conserva su importe al agrupar o cobrar.
- Una partida nueva dispone de tres segundos de recogida final, sin cambiar por error la duración de producción.
- El pop-up tiene una única acción y el recorrido estadísticas → árbol → comenzar día funciona sin regresar al pop-up.
- Los estados comprado, apagado y comprable se distinguen; al comprar se pasa de blanco suave al icono con el color del tipo.

## Objetivo

Empezar manipulando pocas bolas y recogiendo monedas a mano. Las mejoras aumentan la producción, el valor y la capacidad de manejar y cobrar lo producido. Escobas, imán y robot cambian la manera de jugar y abren especializaciones.

La primera compra permite llevar dos bolas. La primera se agarra manualmente y, mientras se lleva alguna, las siguientes se atraen al acercarse hasta llenar la capacidad comprada.

## Tipos y colores

| Tipo | Color | Incluye |
| --- | --- | --- |
| GEN · Generación de monedas | 🟢 Verde · `#22C55E` | Más bolas por segundo y, más adelante, por emisión. Las bolas generan monedas al entrar en el hoyo. |
| VAL · Valor de monedas | 🟡 Dorado · `#EAB308` | Más monedas por bola capturada. |
| REC · Recolección de monedas | 🔵 Azul · `#3B82F6` | Barrido, radio e imán. |
| CON · Control de bolas | 🟣 Violeta · `#A855F7` | Capacidad de mano, escobas y anchura. |
| TIE · Tiempo de producción | 🟠 Naranja · `#F97316` | Días con más tiempo para producir. |
| AUT · Automatización | 🔴 Coral · `#F43F5E` | Robot y velocidad. |

Cada subrama hereda el color de su tipo, aunque nazca de otro tipo. El color identifica el efecto. Un candado indica bloqueo, una marca indica compra y el brillo indica disponibilidad, para no sustituir el color de categoría por el estado.

## Mapa para móvil

Cada flecha exige comprar el nivel anterior. Las bifurcaciones permiten avanzar por todos los caminos; no hay elecciones excluyentes. Una conexión indica acceso, no una compra gratuita.

```text
🟣 MANO I · 20 monedas
Puedes llevar 2 bolas (+1)
│
├─ 🟢 GENERADOR I
│  Produce un 25 % más rápido
│  └─ Generador II
│     ├─ Generador III → IV → V
│     │  └─ 🟢 DOBLE EMISIÓN
│     │     2 bolas por emisión
│     └─ 🟠 DÍA MÁS LARGO I
│        └─ II → III → IV → V
│
├─ 🟡 VALOR I
│  3 monedas por bola
│  └─ Valor II → III → IV → V
│
├─ 🔵 BARRIDO DE MONEDAS
│  Recoger deslizando el dedo
│  └─ 🔵 RADIO I
│     ├─ Radio II → III → IV → V
│     └─ 🔵 IMÁN
│        └─ ATRACCIÓN I → II → III
│
└─ 🟣 MANO II · 30 monedas
   Puedes llevar 3 bolas
   ├─ Mano III → IV → V
   │  4 → 5 → 6 bolas
   └─ 🟣 DESBLOQUEAR ESCOBA · 20 monedas
      └─ 🟣 ANCHURA I
         ├─ Anchura II
         │  ├─ Anchura III → IV → V
         │  └─ 🔴 ROBOT AYUDANTE
         │     └─ VELOCIDAD I
         │        └─ II → III → IV → V
         └─ 🟣 TRANSFORMAR ESCOBA EN V
```

**Requisitos adicionales:** Doble emisión requiere también Anchura III, para que la mejora de producción tenga una herramienta de control disponible. Robot requiere también Barrido de monedas, para haber introducido la recogida por deslizamiento antes de automatizar el empuje. Comprar el robot no automatiza la recogida de monedas.

Estas dos conexiones adicionales forman parte del mapa aunque no se repitan como líneas cruzadas en la versión estrecha para móvil. Doble emisión cambia todas las emisiones a dos bolas; no se suma con otra mejora de cantidad.

## Primeros pasos del jugador

1. Sin mejoras: mano de una bola, 1,5 bolas/s, $1 por captura, 10 s de producción y 3 s de recogida final.
2. Primera compra: Mano I por 20 monedas. Poder transportar dos bolas cambia el control antes de aumentar la carga del tablero.
3. Se abren cuatro decisiones: producir más, ganar más por captura, recoger deslizando o ampliar la mano.
4. Mano II abre la compra de la escoba; esta compra abre las mejoras de anchura; Generador II abre el tiempo de producción. Valor I está disponible pronto y no obliga a invertir primero en varios niveles de producción.
5. Anchura I abre la escoba en V; Anchura II y Barrido permiten llegar al robot.
6. Generador III y Anchura III abren Doble emisión: salto de producción tras invertir en control.

La mano recoge hasta su capacidad cerca del punto de agarre y mantiene el grupo durante el arrastre. El lanzamiento libera las bolas con la velocidad del gesto. La escoba empuja grupos sin usar la capacidad de mano. Radio de recogida se refiere siempre a monedas, no a bolas.

La escoba aparece como objeto físico únicamente después de comprar su desbloqueo. Una vez comprada, la mano siempre puede agarrarla. La V transforma esa misma escoba; no añade otra herramienta ni un selector separado. Esto aplica la corrección más reciente del usuario.

La mejora pendiente de mano para recoger dos monedas cercanas es una mecánica de recolección distinta de transportar más bolas. Sigue pendiente en el seguimiento y aún debe decidirse dónde conectarla en este mapa; no se considera sustituida por Mano I.

## Costes del mapa implementado — pendientes de revisión con CF-01

Los precios son una primera hipótesis de balance, no cifras ya probadas jugando.

Para una línea de niveles:

**Coste del nivel n = precio inicial × 1,65^(n−1), redondeado a la decena más cercana.**

Se redondea al final, no a partir del precio ya redondeado del nivel anterior. Los desbloqueos de mecánicas tienen precio propio.

| Línea | I | II | III | IV | V |
| --- | --- | --- | --- | --- | --- |
| Mano | 20 | 30 | 50 | 90 | 150 |
| Generador | 30 | 50 | 80 | 130 | 220 |
| Valor | 40 | 70 | 110 | 180 | 300 |
| Radio de recogida | 30 | 50 | 80 | 130 | 220 |
| Anchura de escoba | 40 | 70 | 110 | 180 | 300 |
| Día más largo | 80 | 130 | 220 | 360 | 590 |
| Velocidad del robot | 100 | 170 | 270 | 450 | 740 |

| Desbloqueo | Coste | Requisitos |
| --- | --- | --- |
| Desbloquear escoba | 20 | Mano II |
| Barrido | 25 | Mano I |
| Escoba en V | 160 | Anchura I |
| Imán | 180 | Radio I |
| Robot ayudante | 300 | Anchura II + Barrido |
| Doble emisión | 500 | Generador III + Anchura III |
| Atracción I / II / III | 80 / 130 / 220 | Imán; después, nivel anterior |

Atracción usa la misma fórmula, con precio inicial 80. Los precios son por nodo, no acumulados.

## Efectos actuales del mapa

| Línea | Progresión propuesta |
| --- | --- |
| Mano | Capacidad = 1 + n: 2, 3, 4, 5, 6 bolas. |
| Generador | Frecuencia = 1,5 × 1,25^n bolas/s antes de Doble emisión: 1,88; 2,34; 2,93; 3,66; 4,58. |
| Valor | Base $1; niveles comprados conservados: $3, $4, $5, $8 y $11 por captura. Balance definitivo pendiente. |
| Radio | 18 + 6n: 24, 30, 36, 42, 48 unidades lógicas. |
| Anchura | 80 + 16n: 96, 112, 128, 144, 160 unidades lógicas. |
| Día más largo | Producción = 10 + 3n: 13, 16, 19, 22, 25 s. Mantiene 3 s de recogida final. |
| Velocidad del robot | 45 × 1,15^n: aproximadamente 52, 60, 68, 79, 91 unidades/s. |
| Imán | Desbloquea atracción alrededor del dedo activo, con radio 65 unidades. |
| Atracción | Radio del imán = 65 + 10n: 75, 85, 95 unidades. |

Los valores sustituyen a los del nivel anterior. La mano, la anchura, el radio y el tiempo crecen de forma moderada: su límite es el espacio y la interacción. La producción y el valor aportan el crecimiento exponencial.

Los cinco niveles dibujados son el alcance inicial de esta revisión. Las ramas pueden recibir nuevos niveles y bifurcaciones; todavía no se define un bucle infinito ni un sistema de prestigio.

## Cómo comprobar que la progresión funciona

Ingreso teórico por día:

**Bolas/s × bolas por emisión × segundos de producción × monedas por bola × proporción capturada × proporción cobrada.**

En la tabla de Generador, «bolas/s» equivale a emisiones/s antes de Doble emisión. Esta mejora duplica las bolas por emisión sin cambiar el intervalo. Los dos últimos factores de la fórmula están entre 0 y 1: producir más no equivale automáticamente a cobrar más.

Con CF-01 implementado en esta revisión, la referencia inicial es **1,5 bolas/s × 10 s × $1 = $15 por día**, antes de pérdidas. La recogida final base dura tres segundos. Las jornadas antiguas conservan su configuración hasta terminar; no se modifica retroactivamente su ingreso.

Las estimaciones antiguas de 30, 56, 278 y 557 monedas por jornada no fijan el nuevo balance. Se recalcularán cuando se defina la mejora de Valor y el acceso a las denominaciones superiores.

Objetivos para el primer ensayo:
- Mano I alcanzable en aproximadamente 1–2 jornadas de aprendizaje.
- Primeras compras pequeñas cada 1–3 jornadas con una recogida razonable.
- Desbloqueos de mecánicas más espaciados, con un objetivo inicial de 3–6 jornadas de ahorro.
- Evitar que subir generación empeore sistemáticamente lo que se cobra por saturación del tablero.
- Comparar generación, valor y recogida para que ninguna sea siempre la mejor compra.

Se ajustarán costes, multiplicadores y requisitos después de medir ingresos reales y tiempo entre compras. La fórmula de precios por sí sola no garantiza estos ritmos.

## Pendiente de validar o ampliar

- Medir costes, ingresos reales y tiempo entre compras jugando en móvil.
- Situar la mejora de recoger dos monedas: es una mecánica distinta de llevar varias bolas y sigue pendiente.
- Ensayar sensación de control y rendimiento en Android físico. La prueba de saturación con 200 bolas comprueba límites y estabilidad numérica, no certifica FPS.
- Añadir futuras ramas o niveles solo con una nueva decisión de diseño.

Los guardados antiguos conservan las compras sin añadir mejoras gratis. Las jornadas activas usan sus valores históricos hasta terminar; las nuevas usan el CSV del mapa. Las compras posteriores sí exigen los requisitos nuevos.

## Ficha para añadir nodos juntos

| Campo | Qué definimos |
| --- | --- |
| ID | Identificador estable, por ejemplo `hand:1`. |
| Nombre | Texto visible. |
| Tipo y color | Efecto principal y color heredado. |
| Efecto | Fórmula o desbloqueo concreto. |
| Coste | Precio de esa compra. |
| Padres | Todos los requisitos, incluidos los de otra rama. |
| Desbloquea | Siguientes nodos. |
| Rango máximo | Nivel final de esta revisión. |

## Historial

- **v0.1:** propuesta inicial sin verificar.
- **v0.2:** referencia del árbol real del código, conservada en documento separado.
- **v0.3:** propuesta con capacidad de mano, seis tipos con color, especializaciones, cinco niveles y crecimiento multiplicativo.
- **v0.4:** se establece como referencia viva de cambios futuros; respeta escoba inicial y transformación en V, distingue mejora de dos monedas de capacidad de bolas y conserva el árbol actual por separado. Balance y detalles pendientes de revisión.

- **v0.5 · 2026-10-19:** CF-01 valor base de $1 y denominaciones con colores; CF-02 recogida final base de 3 s; CF-03 estadísticas → árbol → comenzar día; CF-04 iconos y colores de mejoras compradas, apagadas o iluminadas en blanco al poder comprarlas. Requisitos registrados y pendientes.
- **v0.6:** mapa implementado por petición del usuario, con Mano I de dos bolas, capacidad +1 por nivel y escoba comprada. Doble emisión, alcance, cinco niveles, colores por tipo y migración forman parte de 0.3.0+5. CF-01 a CF-04 se conservan pendientes.

- **v0.7 · 2026-10-19:** monedas sin cifras ni símbolos, CF-01 a CF-04 implementados para revisión; esquema JSON v4 conservado y balance 5 para jornadas nuevas. Balance 4 congelado para recuperar jornadas interrumpidas. No se genera APK ni se acredita prueba en Android físico en esta revisión.
