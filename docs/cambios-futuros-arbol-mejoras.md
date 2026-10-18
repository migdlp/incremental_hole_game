# Cambios futuros: árbol de mejoras

**Referencia viva v0.4 · Cambios futuros · Diseño en revisión, no implementado.**

Este documento es la referencia de trabajo para diseñar juntos el árbol futuro de Incremental Hole Game. El [árbol actual](arbol-de-mejoras.md) documenta lo implementado; este archivo reúne únicamente lo que queremos explorar o cambiar. Registrar una propuesta aquí no autoriza implementarla ni significa que su balance esté aprobado.

El [seguimiento general](plan-cambios-agarre-escoba.md) conserva las prioridades. Los precios actuales siguen teniendo como única fuente editable [balance.csv](balance.csv); las cifras de este documento son hipótesis de diseño futuro.

## Objetivo

Empezar manipulando pocas bolas y recogiendo monedas a mano. Las mejoras aumentan la producción, el valor y la capacidad de manejar y cobrar lo producido. Escobas, imán y robot cambian la manera de jugar y abren especializaciones.

Tomamos «llevar 2 bolas más» como primera mejora propuesta: capacidad inicial de una bola, primera compra de tres bolas. Es una mecánica nueva que habrá que implementar; no existe en el código actual.

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
Puedes llevar 3 bolas (+2)
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
   Puedes llevar 5 bolas
   ├─ Mano III → IV → V
   │  7 → 9 → 11 bolas
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

1. Sin mejoras: mano de una bola, 1,5 bolas/s, 2 monedas por captura, 10 s de producción y 5 s de recogida.
2. Primera compra: Mano I por 20 monedas. Poder transportar tres bolas cambia el control antes de aumentar la carga del tablero.
3. Se abren cuatro decisiones: producir más, ganar más por captura, recoger deslizando o ampliar la mano.
4. Mano II abre las mejoras de anchura de la escoba, que ya está disponible desde el inicio; Generador II abre el tiempo de producción. Valor I está disponible pronto y no obliga a invertir primero en varios niveles de producción.
5. Anchura I abre la escoba en V; Anchura II y Barrido permiten llegar al robot.
6. Generador III y Anchura III abren Doble emisión: salto de producción tras invertir en control.

La mano recoge hasta su capacidad cerca del punto de agarre y mantiene el grupo durante el arrastre. El lanzamiento libera las bolas con la velocidad del gesto. La escoba empuja grupos sin usar la capacidad de mano. Radio de recogida se refiere siempre a monedas, no a bolas.

La escoba está disponible desde el inicio como objeto físico y la mano siempre puede agarrarla. La V transforma esa misma escoba; no añade otra herramienta ni un selector separado. Esto respeta la dirección ya registrada en el seguimiento general.

La mejora pendiente de mano para recoger dos monedas cercanas es una mecánica de recolección distinta de transportar más bolas. Sigue pendiente en el seguimiento y aún debe decidirse dónde conectarla en este mapa; no se considera sustituida por Mano I.

## Costes y crecimiento propuestos

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
| Barrido | 25 | Mano I |
| Escoba en V | 160 | Anchura I |
| Imán | 180 | Radio I |
| Robot ayudante | 300 | Anchura II + Barrido |
| Doble emisión | 500 | Generador III + Anchura III |
| Atracción I / II / III | 80 / 130 / 220 | Imán; después, nivel anterior |

Atracción usa la misma fórmula, con precio inicial 80. Los precios son por nodo, no acumulados.

## Efectos por nivel

| Línea | Progresión propuesta |
| --- | --- |
| Mano | Capacidad = 1 + 2n: 3, 5, 7, 9, 11 bolas. |
| Generador | Frecuencia = 1,5 × 1,25^n bolas/s antes de Doble emisión: 1,88; 2,34; 2,93; 3,66; 4,58. |
| Valor | Monedas por bola = redondear(2 × 1,4^n): 3, 4, 5, 8, 11. |
| Radio | 18 + 6n: 24, 30, 36, 42, 48 unidades lógicas. |
| Anchura | 80 + 16n: 96, 112, 128, 144, 160 unidades lógicas. |
| Día más largo | Producción = 10 + 3n: 13, 16, 19, 22, 25 s. Mantiene 5 s de recogida. |
| Velocidad del robot | 45 × 1,15^n: aproximadamente 52, 60, 68, 79, 91 unidades/s. |
| Imán | Desbloquea atracción alrededor del dedo activo, con radio 65 unidades. |
| Atracción | Radio del imán = 65 + 10n: 75, 85, 95 unidades. |

Los valores sustituyen a los del nivel anterior. La mano, la anchura, el radio y el tiempo crecen de forma moderada: su límite es el espacio y la interacción. La producción y el valor aportan el crecimiento exponencial.

Los cinco niveles dibujados son el alcance inicial de esta revisión. Las ramas pueden recibir nuevos niveles y bifurcaciones; todavía no se define un bucle infinito ni un sistema de prestigio.

## Cómo comprobar que la progresión funciona

Ingreso teórico por día:

**Bolas/s × bolas por emisión × segundos de producción × monedas por bola × proporción capturada × proporción cobrada.**

En la tabla de Generador, «bolas/s» equivale a emisiones/s antes de Doble emisión. Esta mejora duplica las bolas por emisión sin cambiar el intervalo. Los dos últimos factores de la fórmula están entre 0 y 1: producir más no equivale automáticamente a cobrar más.

Referencias máximas aproximadas, sin bloqueos ni pérdidas:

| Situación | Monedas por día |
| --- | --- |
| Inicio | 1,5 × 10 × 2 = 30 |
| Generador I + Valor I | 1,875 × 10 × 3 ≈ 56 |
| Generador III + Valor III + Día III | 2,93 × 19 × 5 ≈ 278 |
| Mismo caso + Doble emisión | ≈ 557 |

Son tasas medias teóricas; los días discretos y los límites del tablero pueden variar el total. No son predicciones de lo que cobrará un jugador.

Objetivos para el primer ensayo:
- Mano I alcanzable en aproximadamente 1–2 jornadas de aprendizaje.
- Primeras compras pequeñas cada 1–3 jornadas con una recogida razonable.
- Desbloqueos de mecánicas más espaciados, con un objetivo inicial de 3–6 jornadas de ahorro.
- Evitar que subir generación empeore sistemáticamente lo que se cobra por saturación del tablero.
- Comparar generación, valor y recogida para que ninguna sea siempre la mejor compra.

Se ajustarán costes, multiplicadores y requisitos después de medir ingresos reales y tiempo entre compras. La fórmula de precios por sí sola no garantiza estos ritmos.

## Decisiones abiertas

- Confirmar si Mano I será la primera compra y si dará exactamente dos bolas adicionales; procede del ejemplo conversado, no de una mecánica aprobada.
- Confirmar conexiones, cinco niveles iniciales y los dos requisitos cruzados.
- Situar la mejora de recoger dos monedas, sin confundirla con el agarre de bolas.
- Validar costes y multiplicadores con sesiones reales antes de fijarlos.
- Resolver la migración del nodo histórico de desbloqueo de escoba, ahora que la escoba física es inicial. Conservar compras y progreso.

## Cambios necesarios en el juego cuando aprobemos el diseño

- Añadir agarre múltiple, capacidad de mano y su lanzamiento.
- Añadir Doble emisión y niveles de alcance del imán.
- Ampliar de tres a cinco niveles las líneas indicadas.
- Actualizar valores, costes, requisitos y conexiones.
- Adaptar las posiciones del árbol: el código actual tiene coordenadas fijas para los niveles existentes.
- Mostrar color por tipo y estado mediante marcas, candados y brillo.
- Mantener coherencia entre requisitos de compra y árbol, preservando compras antiguas.
- Probar saturación: el tablero actual limita el número de bolas y necesita soportar la producción nueva.

No se implementará un límite duro sobre producción o valor sin mostrarlo al jugador. Si se alcanzan límites técnicos, habrá que revisar rendimiento o representar grupos de bolas antes de ampliar indefinidamente las ramas.

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
