# Árbol de mejoras progresivo

Código posterior a **0.6.0+13**, 20/10/2026; el APK enlazado en estado actual aún no incluye estos cambios. El [CSV](balance.csv) es la fuente de costes, efectos y requisitos. El [estado actual](estado-actual.md) describe el juego entregado y [cambios futuros](cambios-futuros-arbol-mejoras.md) recoge solo lo pendiente.

**Debug:** pulsar el botón DEBUG, arriba a la izquierda, para ver el mapa completo, comprar gratis o alternar la Vista del jugador. El progreso de prueba es temporal. [Instrucciones](modo-debug.md).

## Mapa actual

Veintidós tipos y **59 nodos**, uno por nivel comprable. Cada nivel requiere el anterior. Las seis ramas iniciales se pueden desarrollar conjuntamente.

```text
🟣 MANO I · 13 monedas · 2 bolas
│
├─ 🟣 FUERZA DE AGARRE I → II → III → IV → V
│
├─ 🟢 GENERADOR I
│  ├─ ACELERACIÓN · 100 → POTENCIA / DURACIÓN I–II / RECARGA I–II
│  └─ Generador II
│     ├─ Generador III → IV → V
│     │  └─ 🟢 DOBLE EMISIÓN (+ Anchura III)
│     └─ 🟠 DÍA MÁS LARGO I → II → III → IV → V
│
├─ 🟡 VALOR I → II → III → IV → V
│
├─ 🟡 RACHA · 40 monedas
│  └─ CAPTURA TOTAL · 120 → RECARGA I → II
│
├─ 🔵 BARRIDO DE MONEDAS (opcional)
│
├─ 🔵 ÁREA I → II → III
│                 ├─ Área IV → V
│                 └─ IMÁN · 300 monedas → ATRACCIÓN I → II → III
│
└─ 🟣 MANO II · 3 bolas
   ├─ Mano III → IV → V · 4 → 5 → 6 bolas
   └─ DESBLOQUEAR ESCOBA · 20 monedas
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
2. Una partida nueva muestra únicamente Mano I. Al comprarla se abren Generador I, Valor I, Racha, Barrido, Área I, Fuerza I y Mano II.
3. Pulsar un nodo consulta su efecto y coste; mantener pulsado un segundo en el botón de compra de la ficha compra una sola vez. El nodo solo consulta, incluso al mantenerlo pulsado.
4. Soltar antes, arrastrar, añadir otro dedo o pasar a segundo plano cancela la compra sin gastar.
5. «Comenzar día» está fijo en la pantalla del árbol: cancela cualquier compra incompleta, inicia directamente la jornada y cierra esa pantalla. Atrás puede volver al resumen, que no permite empezar el día. La bienvenida de una partida nueva conserva su inicio directo.

El catálogo y la sesión comprueban los mismos requisitos que el árbol, incluidos los dos cruces. Las condiciones repetidas que ya se cumplen por un antecesor no se dibujan como conexiones duplicadas.

## Balance y compatibilidad

Base: 1,5 emisiones/s, valor normal 1 por bola, 15 segundos de producción y 5 de recogida final. Día más largo I–V aumenta la producción a 18/21/24/27/30 segundos; el cierre sigue en 5. Mano I cuesta 13 monedas; Valor sigue 2/3/5/8/13 y el imán cuesta 300 tras Área III; los precios y multiplicadores del mapa siguen pendientes de ajuste jugando. Los cinco niveles de mano alcanzan seis bolas, conforme a la última instrucción de aumentar la capacidad de una en una.

El guardado JSON v7 conserva compras, saldo y jornadas activas de versiones anteriores. Las jornadas con balance 1–7 mantienen su configuración hasta terminar; la siguiente jornada usa balance 8. Los balances históricos están congelados. El imán comprado antes del cambio conserva su acceso sin regalar Área II/III; las nuevas compras requieren Área III. Las pilas antiguas se descomponen en monedas válidas sin alterar su importe pendiente. Ver [persistencia](persistencia.md).

## Verificación

Las pruebas cubren recorrido de compra y restauración, requisitos cruzados, alcance, emisión doble, tablero de 200 bolas, colores, pantalla pequeña y cancelación de compra. La entrega 0.6.0+13 pasa 135 pruebas, análisis, formato, compilación Android y firma con Flutter 3.35.7 / Dart 3.9.2. Las pruebas de debug incluyen presencia y encuadre de los 49 nodos y compra de un nodo profundo. Las pruebas de pantalla pequeña incluyen 320 × 568. No hay aceptación táctil ni medición de FPS en Android físico en esta entrega.

La evidencia histórica del árbol anterior sigue en [validación](validacion-prototipo.md) y [CI](ci.md); sus APK no contienen automáticamente este mapa nuevo.

Los cambios pendientes se consultan en [cambios futuros](cambios-futuros-arbol-mejoras.md). La paleta de monedas, las denominaciones y el valor base se explican en [economía](economia.md).

## Fuerza de agarre de la mano

`hand_grip` requiere Mano I y se amplía hasta cinco niveles. Aumenta la rapidez con la que las bolas adicionales se acercan y la resistencia de su sujeción; la primera se sigue agarrando a mano, la capacidad y el alcance no cambian. Se distingue del imán de monedas. Los costes y factores están en el CSV. El agarre conserva movimiento físico, inercia al soltar y cancelación segura al pausar o entrar en recogida final.

## Racha y especiales (balance de prueba)

Racha deja de ser gratuita. Conserva ventana y multiplicadores, con indicador
desde la primera captura. Captura total requiere Racha; Aceleración requiere
Generador I. El CSV define los costes, recargas y mejoras. La recarga de Captura
total baja de 12 a 10/8 s; Aceleración pasa de ×2 a ×3, dura 4 → 5/6 s y carga en
10 → 8/6 s. Estas cifras son provisionales para probar. No cambian saldo ni
compras anteriores. Las jornadas antiguas se completan con su configuración.
