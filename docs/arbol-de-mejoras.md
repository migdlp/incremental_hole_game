# Árbol de mejoras progresivo

> **Modo de depuración:** mantén el saldo pulsado 3 s para ver el árbol completo, comprar nodos gratis con sus requisitos y alternar la Vista del jugador. Las pruebas son temporales y no sustituyen el progreso guardado. [Instrucciones](modo-debug.md).

> **Revisión de código 0.6.0+11:** combos disponibles desde el inicio en las nuevas jornadas. Esta revisión no cambia nodos, costes ni requisitos. La sustitución de Valor por tiers individuales y las posibles mejoras del combo siguen pendientes en [cambios futuros](cambios-futuros-arbol-mejoras.md). Última entrega APK documentada: 0.5.0+10.

> **Entrega CF-09 a CF-15 — 19 de octubre de 2026:** [PR #18](https://github.com/migdlp/incremental_hole_game/pull/18) integrada en `main`, código `34ea6d66e884903e6fd4d47c02883e3f31b48f74`. **[Descargar APK 0.5.0+10 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39292311120/artifacts/12206371751)**, disponible hasta el 2 de noviembre de 2026. [Pipeline 39292311120](https://github.com/migdlp/incremental_hole_game/actions/runs/39292311120) correcta: formato, análisis, **116 pruebas**, compilación Android y firma v2 verificada. Descomprimir e instalar `jardin-mecanico-debug.apk`. No incluye las ideas de bolas duplicadoras/bomba. Validación en Android físico y ajuste de precios jugando pendientes.

> **Referencia actualizada a 0.5.0+10:** CF-09 a CF-15 implementados: Mano I de 13, Área manual desde Mano I e Imán de 300 tras Área III. Guardado v5 y balance 6; los precios en la UI usan icono de moneda.

> **Tanda anterior 0.4.0+9:** CF-06 a CF-08 implementados. El árbol usa una cuadrícula de 64 unidades y objetivos de 64 × 64, con posiciones/conexiones en ocho direcciones y rutas que evitan otros nodos. Se conservan los 44 nodos previos y se añaden cinco niveles de fuerza de mano. Ver [próximas mejoras](cambios-futuros-arbol-mejoras.md). Las notas de preparación anteriores se conservan como historia.


> **Entrega CF-05 — 19 de octubre de 2026:** PR #16 integrada en `main`, commit `91b10cb0d5ff57ee0c69e02e17c1145d48d53c4d`. [APK 0.3.3+8 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39182903655/artifacts/12156897149), disponible hasta el 2 de noviembre de 2026. [Pipeline 39182903655](https://github.com/migdlp/incremental_hole_game/actions/runs/39182903655) correcta sobre ese commit: formato, análisis, **101 pruebas**, compilación Android y firma v2 verificadas. Incluye el árbol compacto, ficha al seleccionar y compra de 1 s, junto con los cambios que ya había en `main`. Las notas de preparación inferiores son históricas. Prueba en Android físico pendiente.


> **Revisión de interfaz CF-05 preparada para integrar:** cabecera solo con saldo, sin título, atrás ni barra de zoom. Sin ficha hasta tocar un nodo, resumen con cantidades en verde y compra exclusivamente desde el botón manteniendo 1 s. Mapa compacto y conexiones de tramos rectos; ramas y balance conservados. Ver [referencia CF-05](cambios-futuros-arbol-mejoras.md#cf-05--árbol-compacto-y-ficha-bajo-demanda--19-de-octubre-de-2026).


Referencia actual del código **0.5.0+10**, a partir del [referencia de cambios futuros v0.7](cambios-futuros-arbol-mejoras.md), autorizado el 19 de octubre de 2026. El [CSV](balance.csv) es la fuente de costes, efectos y requisitos de compra.

## Mapa actual

Quince tipos y **49 nodos**, uno por nivel comprable. Cada nivel requiere el anterior. Las seis ramas iniciales se pueden desarrollar conjuntamente.

```text
🟣 MANO I · 13 dólares · 2 bolas
│
├─ 🟣 FUERZA DE AGARRE I → II → III → IV → V
│
├─ 🟢 GENERADOR I
│  └─ Generador II
│     ├─ Generador III → IV → V
│     │  └─ 🟢 DOBLE EMISIÓN (+ Anchura III)
│     └─ 🟠 DÍA MÁS LARGO I → II → III → IV → V
│
├─ 🟡 VALOR I → II → III → IV → V
│
├─ 🔵 BARRIDO DE MONEDAS (opcional)
│
├─ 🔵 ÁREA I → II → III
│                 ├─ Área IV → V
│                 └─ IMÁN · 300 dólares → ATRACCIÓN I → II → III
│
└─ 🟣 MANO II · 3 bolas
   ├─ Mano III → IV → V · 4 → 5 → 6 bolas
   └─ DESBLOQUEAR ESCOBA · 20 dólares
      └─ ANCHURA I
         ├─ Anchura II
         │  ├─ Anchura III → IV → V
         │  └─ 🔴 ROBOT (+ Barrido)
         │     └─ VELOCIDAD I → II → III → IV → V
         └─ ESCOBA EN V
```

La mano inicial lleva una bola. Siempre se agarra la primera manualmente; solo una mano que ya sostiene alguna atrae otras a menos de 36 unidades de la primera sostenida, hasta llenar la capacidad. La primera bola sigue el agarre manual. Las adicionales se acercan con fuerza limitada e inercia, tardan unas décimas en acomodarse y siguen al dedo con retraso. Un tirón fuerte puede romper ese agarre; las bolas sueltas conservan su velocidad y no se reenganchan hasta un gesto nuevo. Al levantar el dedo, cada bola adicional conserva su propia inercia. Pausa y cierre cancelan todos los agarres sin lanzarlos. Esta mecánica no recoge monedas.

La escoba no se dibuja, no se puede agarrar y no colisiona hasta comprar su desbloqueo. Después es un objeto físico que conserva posición y orientación. Anchura y V modifican esa misma escoba. La V no añade otro selector.

Doble emisión intenta crear dos bolas separadas en cada emisión; mantiene el intervalo y respeta obstáculos de salida y el límite técnico de 200 bolas. El robot empuja bolas; no cobra monedas. Imán y Atracción actúan sobre monedas alrededor del dedo activo solo con la mano vacía; no son el imán de bolas de la mano.

## Colores y estados

| Tipo | Color |
| --- | --- |
| Generación | Verde `#22C55E` |
| Valor | Amarillo `#EAB308` |
| Recogida de monedas | Azul `#3B82F6` |
| Control de bolas | Violeta `#A855F7` |
| Tiempo | Naranja `#F97316` |
| Automatización | Coral `#F43F5E` |

Los nodos comprados muestran su icono y color de tipo, con marca de compra. Los no comprados se apagan en gris; si tienen requisitos cumplidos y saldo suficiente, se iluminan en blanco suave. La selección engrosa el borde sin colorear una compra pendiente. Las conexiones adquiridas usan el color del destino y las pendientes son grises. Se conservan arrastre y pellizco; se retiran los botones de zoom/centrado, el título y el botón visible de atrás. No aparece ficha hasta seleccionar una mejora. La ficha muestra una frase con la cantidad mejorada en verde, precio y compra de un segundo; el desglose anterior sigue disponible al mantener pulsado el resumen. El mapa usa un lienzo de 864 × 864 y cuadrícula de 64 y conexiones rectas, con pasillos para los requisitos cruzados.

## Recorrido e interacción

1. El pop-up de estadísticas tiene un solo botón: «Ir al árbol de mejoras», que abre su pantalla independiente.
2. Una partida nueva muestra únicamente Mano I. Al comprarla se abren Generador I, Valor I, Barrido, Área I, Fuerza I y Mano II.
3. Pulsar un nodo consulta su efecto y coste; mantener pulsado un segundo en el botón de compra de la ficha compra una sola vez. El nodo solo consulta, incluso al mantenerlo pulsado.
4. Soltar antes, arrastrar, añadir otro dedo o pasar a segundo plano cancela la compra sin gastar.
5. «Comenzar día» está fijo en la pantalla del árbol: cancela cualquier compra incompleta, inicia directamente la jornada y cierra esa pantalla. Atrás puede volver al resumen, que no permite empezar el día. La bienvenida de una partida nueva conserva su inicio directo.

El catálogo y la sesión comprueban los mismos requisitos que el árbol, incluidos los dos cruces. Las condiciones repetidas que ya se cumplen por un antecesor no se dibujan como conexiones duplicadas.

## Balance y compatibilidad

Base: 1,5 emisiones/s, $1 por bola, diez segundos de producción y tres de recogida final. Mano I cuesta 13 dólares; Valor sigue 2/3/5/8/13 y el imán cuesta 300 tras Área III; los precios y multiplicadores del mapa siguen pendientes de ajuste jugando. Los cinco niveles de mano alcanzan seis bolas, conforme a la última instrucción de aumentar la capacidad de una en una.

El guardado v5 acepta v1–v4. Conserva compras, saldo y jornadas activas con balance 1–5 hasta terminar; la siguiente jornada usa balance 6. Se congelan los balances históricos, incluido el 5. El imán comprado antes del cambio conserva su acceso sin regalar Área II/III; las nuevas compras requieren Área III. Las pilas antiguas se descomponen en monedas válidas sin alterar su importe pendiente. Ver [persistencia](persistencia.md).

## Verificación

Las pruebas cubren recorrido de compra y restauración, requisitos cruzados, alcance, emisión doble, tablero de 200 bolas, colores, pantalla pequeña y cancelación de compra. En esta revisión pasan 116 pruebas, análisis sin incidencias, formato y compilación web con Flutter 3.35.7 / Dart 3.9.2. Las pruebas de pantalla pequeña incluyen 320 × 568. No hay aceptación táctil ni medición de FPS en Android físico en esta entrega.

La evidencia histórica del árbol anterior sigue en [validación](validacion-prototipo.md) y [CI](ci.md); sus APK no contienen automáticamente este mapa nuevo.

CF-01 a CF-04 y las monedas sin cifras se implementan en esta revisión. Los cambios pendientes se consultan en [cambios futuros](cambios-futuros-arbol-mejoras.md). La paleta de monedas, las denominaciones y el valor base se explican en [economía](economia.md).

## Fuerza de agarre de la mano

`hand_grip` requiere Mano I y se amplía hasta cinco niveles. Aumenta la rapidez con la que las bolas adicionales se acercan y la resistencia de su sujeción; la primera se sigue agarrando a mano, la capacidad y el alcance no cambian. Se distingue del imán de monedas. Los costes y factores están en el CSV. El agarre conserva movimiento físico, inercia al soltar y cancelación segura al pausar o entrar en recogida final.
