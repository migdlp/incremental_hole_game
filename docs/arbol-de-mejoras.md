# Árbol de mejoras progresivo

Referencia implementada en **0.3.1+6**, a partir del [referencia de cambios futuros v0.7](cambios-futuros-arbol-mejoras.md), autorizado el 19 de octubre de 2026. El [CSV](balance.csv) es la fuente de costes, efectos y requisitos de compra.

## Mapa actual

Catorce tipos y **44 nodos**, uno por nivel comprable. Cada nivel requiere el anterior. Las cuatro ramas iniciales se pueden desarrollar conjuntamente.

```text
🟣 MANO I · 20 dólares · 2 bolas
│
├─ 🟢 GENERADOR I
│  └─ Generador II
│     ├─ Generador III → IV → V
│     │  └─ 🟢 DOBLE EMISIÓN (+ Anchura III)
│     └─ 🟠 DÍA MÁS LARGO I → II → III → IV → V
│
├─ 🟡 VALOR I → II → III → IV → V
│
├─ 🔵 BARRIDO DE MONEDAS
│  └─ RADIO I
│     ├─ Radio II → III → IV → V
│     └─ IMÁN → ATRACCIÓN I → II → III
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

La mano inicial lleva una bola. Siempre se agarra la primera manualmente; solo una mano que ya sostiene alguna atrae otras a menos de 36 unidades de la primera sostenida, hasta llenar la capacidad. El grupo sigue al dedo y comparte el lanzamiento o la suelta. Pausa y cierre cancelan todos los agarres sin lanzarlos. Esta mecánica no recoge monedas.

La escoba no se dibuja, no se puede agarrar y no colisiona hasta comprar su desbloqueo. Después es un objeto físico que conserva posición y orientación. Anchura y V modifican esa misma escoba. La V no añade otro selector.

Doble emisión intenta crear dos bolas separadas en cada emisión; mantiene el intervalo y respeta obstáculos de salida y el límite técnico de 200 bolas. El robot empuja bolas; no cobra monedas. Imán y Atracción actúan sobre monedas alrededor del dedo activo; no son el imán de bolas de la mano.

## Colores y estados

| Tipo | Color |
| --- | --- |
| Generación | Verde `#22C55E` |
| Valor | Amarillo `#EAB308` |
| Recogida de monedas | Azul `#3B82F6` |
| Control de bolas | Violeta `#A855F7` |
| Tiempo | Naranja `#F97316` |
| Automatización | Coral `#F43F5E` |

Los nodos comprados muestran su icono y color de tipo, con marca de compra. Los no comprados se apagan en gris; si tienen requisitos cumplidos y saldo suficiente, se iluminan en blanco suave. La selección engrosa el borde sin colorear una compra pendiente. Las conexiones adquiridas usan el color del destino y las pendientes son grises. Se conservan arrastre, pellizco y controles de zoom, sin textos de ayuda ni contador de compras sobre el mapa.

## Recorrido e interacción

1. El pop-up de estadísticas tiene un solo botón: «Ir al árbol de mejoras», que abre su pantalla independiente.
2. Una partida nueva muestra únicamente Mano I. Al comprarla se abren Generador I, Valor I, Barrido y Mano II.
3. Pulsar un nodo consulta su efecto y coste; mantener pulsado tres segundos en el nodo seleccionado o en la ficha compra una sola vez.
4. Soltar antes, arrastrar, añadir otro dedo o pasar a segundo plano cancela la compra sin gastar.
5. «Comenzar día» está fijo en la pantalla del árbol: cancela cualquier compra incompleta, inicia directamente la jornada y cierra esa pantalla. Atrás puede volver al resumen, que no permite empezar el día. La bienvenida de una partida nueva conserva su inicio directo.

El catálogo y la sesión comprueban los mismos requisitos que el árbol, incluidos los dos cruces. Las condiciones repetidas que ya se cumplen por un antecesor no se dibujan como conexiones duplicadas.

## Balance y compatibilidad

Base: 1,5 emisiones/s, $1 por bola, diez segundos de producción y tres de recogida final. Mano I cuesta 20 dólares; los precios y multiplicadores del mapa siguen pendientes de ajuste jugando. Los cinco niveles de mano alcanzan seis bolas, conforme a la última instrucción de aumentar la capacidad de una en una.

El guardado v4 acepta v1/v2/v3. Conserva compras, saldo y jornadas activas: estas últimas usan el balance histórico hasta terminar; la siguiente jornada usa balance 5. Una jornada activa de balance 4 conserva su valor de dos monedas y su cierre de cinco segundos hasta terminar; se restaura desde la copia congelada de ese balance. Se registran los niveles heredados sin regalar sus nuevos requisitos. Las compras nuevas exigen el mapa actual. Los antecesores de compras antiguas siguen visibles aunque estén pendientes.

## Verificación

Las pruebas cubren recorrido de compra y restauración, requisitos cruzados, alcance, emisión doble, tablero de 200 bolas, colores, pantalla pequeña y cancelación de compra. En esta revisión pasan 88 pruebas, análisis sin incidencias, formato y compilación web con Flutter 3.35.7 / Dart 3.9.2. Las pruebas de pantalla pequeña incluyen 320 × 568. No hay aceptación táctil ni medición de FPS en Android físico en esta entrega.

La evidencia histórica del árbol anterior sigue en [validación](validacion-prototipo.md) y [CI](ci.md); sus APK no contienen automáticamente este mapa nuevo.

CF-01 a CF-04 y las monedas sin cifras se implementan en esta revisión. El historial de decisiones sigue en [cambios futuros](cambios-futuros-arbol-mejoras.md). La paleta de monedas, sus pilas y el valor base se explican en [economía](economia.md).
