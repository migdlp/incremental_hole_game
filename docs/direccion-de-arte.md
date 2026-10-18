# Dirección de arte y experiencia

Estado: propuesta visual para prototipo, pendiente de revisión. No se han producido todavía ilustraciones ni recursos definitivos.

## Concepto

Un pequeño jardín mecánico visto desde arriba: piedritas redondeadas, un hoyo con profundidad suave y un robot de taller que ayuda a recoger. Estética 2D limpia y amable, con volúmenes sugeridos por sombras sencillas. Evitar texturas de ruido y detalles pequeños que dificulten leer grupos de objetos.

La metáfora del día y la noche se expresa en iluminación y pantalla: tablero cálido durante la jornada, taller azul oscuro para comprar. Las monedas mantienen el mismo aspecto reconocible en ambas situaciones. El cambio es breve y no consume tiempo de juego.

## Paleta inicial

| Uso | Color |
| --- | --- |
| Suelo diurno | Arena `#F1E5CD` |
| Piedras | Pizarra `#697583` con borde oscuro |
| Hoyo y contornos | Azul tinta `#172333` |
| Monedas | Oro `#F5B83D` con detalle interior oscuro |
| Pala y acciones disponibles | Verde azulado `#247D73` |
| Fondo nocturno | Azul profundo `#111C2E` |
| Superficies nocturnas | Azul grisáceo `#23334B` |
| Texto principal nocturno | Marfil `#F8F3E8` |
| Aviso de cierre | Terracota `#AA432E` |

Son colores de exploración, no combinaciones de contraste garantizado. Comprobar contraste de textos y botones en el diseño; objetivo de texto normal 4,5:1. No usar oro sobre arena para etiquetas pequeñas sin fondo oscuro.

## Formas y jerarquía

- Bolas: discos mate con una sombra y una marca discreta. Un solo tipo en el MVP.
- Monedas: borde doble y brillo corto; se distinguen de bolas por silueta interior además de color.
- Pilas: dos o tres discos desplazados y una etiqueta de valor estable.
- Hoyo: anillos concéntricos oscuros y borde de suelo; el radio de captura debe coincidir visualmente con su abertura.
- Pala: aro semitransparente con centro despejado. El jugador ve qué está empujando.
- Robot: cuerpo compacto, dirección visible y pieza frontal que indica por dónde empuja. Sin animaciones complejas de extremidades.
- Generador: tolva sencilla con salida identificable y pequeño movimiento al emitir.

Escala de partida para 360 unidades de ancho: bola de radio 6 y hoyo de captura de radio 22. El control actual es mano con indicador de agarre y escoba recta/V, con frente base de 80 unidades y grosor 7; la clave histórica `paddle_radius` ya no representa un empujador circular. Ajustar la presentación tras prueba táctil. Las zonas táctiles de menús tendrán al menos 48 × 48 píxeles lógicos; no confundir el tamaño visible de una moneda con su área de recogida.

## Pantallas

### Jornada

Franja superior: «Día 3», tiempo restante, dinero recogido y pausa. El tablero ocupa el resto de la zona segura. El saldo ahorrado queda en la noche para evitar confundirlo con la puntuación diaria. Durante el cierre, el temporizador cambia de etiqueta y aparece una señal visual breve; no depender exclusivamente del sonido o del color.

### Noche

Orden de lectura: resultado del día → saldo disponible → árbol → comenzar siguiente día. Mostrar ingreso principal grande, récord y diferencia anterior en segundo plano. «Sin recoger: 12» comunica la pérdida sin una animación de castigo prolongada.

Árbol compacto con tres columnas de ramas y conexiones visibles. En teléfonos estrechos, scroll vertical con nombres de rama persistentes; evitar exigir zoom o desplazamientos en dos ejes. Seleccionar un nodo abre su detalle debajo o en un panel inferior. El botón de compra muestra precio y el inicio del día sigue accesible.

Estados de nodo mediante icono y texto: candado/requisito, disponible/precio, sin saldo/cantidad que falta, completado/marca. No depender solo de diferencias de color. Confirmación inmediata tras comprar y saldo actualizado.

### Pausa

Continuar y volumen de efectos. No añadir reinicio de progreso dentro del flujo principal. Al volver desde segundo plano, mostrar esta pantalla antes de reanudar.

## Movimiento y sonido

| Evento | Respuesta |
| --- | --- |
| Bola entra | Reducción y hundimiento de unos 150 ms, pulso del borde |
| Sale moneda | Arco corto de unos 200 ms; disponible al aterrizar |
| Recogida | Destello pequeño y actualización inmediata del contador |
| Compra | Nodo se ilumina y muestra su nuevo nivel |
| Cierre próximo | Aviso de texto y señal sonora breve |
| Fin del día | Transición de iluminación de unos 400 ms con interacción ya detenida |

Duraciones provisionales. Agrupar respuestas cuando entran muchas bolas: no reproducir un sonido ni una etiqueta flotante por cada objeto sin límite. Propuesta inicial: máximo cuatro voces de efectos simultáneas; priorizar cierre y compra. Incluir silencio total. Sin música ni vibraciones obligatorias en el MVP; evitar destellos rápidos y sacudidas de cámara.

## Recursos de la primera entrega

Primero dibujar primitivas desde código: bolas, hoyo, mano/escobas, monedas y robot. Crear dos bocetos de pantalla —jornada y noche— antes de producir un atlas definitivo. Recursos finales mínimos: generador, robot, moneda/pila y iconos para los once tipos de mejora actuales; cuatro efectos sonoros reutilizables. Los iconos llevan nombre visible, no sustituyen la explicación.

Usar tipografía del sistema al inicio. Si se incorpora otra, empaquetarla y registrar su licencia. Guardar origen y licencia de todo recurso externo. No añadir dependencia de descarga de fuentes ni imágenes en ejecución.

La revisión visual se hace en móvil: distinguir monedas entre muchas bolas, leer el tiempo con una mano, identificar lo que se puede comprar y comprender que el dinero pendiente desaparece.
