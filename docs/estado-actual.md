# Estado actual de Incremental Hole Game / Jardín Mecánico

Actualizado: **20/10/2026**. Referencia: **0.6.0+13**, último APK entregado al usuario. Este documento describe lo que existe; las propuestas pendientes están en [cambios futuros](cambios-futuros-arbol-mejoras.md). Para continuar en otro chat, empieza por el [relevo de contexto](relevo-contexto.md).

## Juego y dirección

Juego incremental móvil con físicas arcade. El jugador manipula bolas para meterlas en un agujero, recoge las monedas físicas que producen y compra mejoras permanentes entre jornadas. La automatización debe ayudar a agrupar y dirigir bolas, manteniendo una ventaja clara para quien juega activamente.

Los cuatro ejes de progresión son generar más bolas, capturar una proporción mayor, aumentar el valor de las capturas y recoger mejor las monedas. El sistema de tiers individuales y la fábrica configurable son dirección futura, todavía no sistemas implementados.

## Jornada y tablero vigentes

- Arena lógica de 360 × 560. **Agujero arriba** en (180, 60) y **generador abajo** en (180, 412), con salida y velocidad inicial de las bolas hacia arriba. Es el último cambio pedido y entregado.
- Base de **15 s de producción y 5 s de recogida final**, con barras independientes. Las mejoras de duración dan 18/21/24/27/30 s de producción; la recogida permanece en 5 s.
- Emisión inicial de **1,5 bolas/s**: primera bola tras aproximadamente ⅔ s. Generador y Doble emisión aumentan la producción.
- Durante producción se controlan bolas y se recogen monedas. Durante recogida final se congelan bolas, escoba y robot; se permite cobrar monedas. La cabecera y el contador permanecen legibles sin oscurecer.
- Al terminar, lo pendiente se pierde. El tablero siguiente empieza vacío y conserva saldo y mejoras.
- Límite de **200 bolas**, **1000 monedas visibles** y reserva por denominación para monedas pendientes de emitir. La reserva no se cobra automáticamente.
- Pausa y segundo plano detienen la simulación. No hay ingresos por tiempo con el juego cerrado.

## Mano, escoba y robot

- Mano base de una bola. Mano I cuesta **13** y permite dos; los cinco niveles alcanzan 2/3/4/5/6 bolas.
- La primera bola se agarra manualmente. Solo una mano ya ocupada atrae bolas adicionales cercanas, hasta su capacidad. Conservan movimiento físico, retraso e inercia y pueden soltarse con tirones fuertes.
- Fuerza de agarre I–V acelera la aproximación y refuerza la sujeción de las bolas adicionales. No aumenta capacidad ni recoge monedas.
- La escoba se desbloquea tras Mano II. Es un objeto físico que se puede agarrar; Anchura y V modifican esa misma herramienta. Empuja bolas y no cobra monedas.
- Un robot desbloqueable empuja bolas hacia el agujero; su velocidad se mejora. No recoge monedas.
- **Mientras haya alguna bola agarrada, se bloquean tanto el cobro como la atracción de monedas.**

## Monedas, recompensa y combos

- Capturar genera monedas físicas; recogerlas permite contabilizar el ingreso. La jornada se liquida una sola vez, sin cobrar automáticamente lo pendiente.
- Bola normal base: **1**. La rama global Valor sigue vigente: **2/3/5/8/13** por captura normal, antes de dorada y combo.
- Doradas: **1 %** de las emisiones; recompensa **×10** del valor normal vigente. Actualmente no hay tiers individuales.
- Denominaciones únicas: **1 / 10 / 50 / 100 / 500**. Colores: dorado / verde esmeralda / azul / violeta / coral. Todas tienen las mismas dimensiones y no muestran cifras ni símbolos en su cara. La UI usa icono de moneda sin prefijo dólar.
- Toque para cobrar; Barrido permite arrastrar. Área mejora la recogida manual sin exigir Barrido ni Imán. **Imán cuesta 300 y requiere Área III**; Atracción amplía su alcance.
- Resumen diario con recuento por denominación, de mayor a menor. La antigua barra verde cobrado/generado está eliminada.
- Combos desde el inicio: ventana inclusiva de **1 s**; capturas 1–4 **×1**, 5–9 **×2**, desde la décima **×3**. La quinta y décima usan ya su nuevo multiplicador. No se modifican premios anteriores.
- Se combinan Valor × dorada × combo. Toda recompensa sigue requiriendo recoger sus monedas. Todas las capturas, incluidas las asistidas, cuentan provisionalmente.
- La racha termina al superar la ventana o entrar en recogida final. Pausar y restaurar no consumen tiempo. La UI muestra COMBO ×2/×3; se quiere que el jugador descubra los umbrales, sin explicar la fórmula en pantalla.

## Árbol e interfaz

**49 nodos en 15 tipos**, con seis categorías: Generación verde, Valor dorado, Recogida azul, Control violeta, Tiempo naranja y Automatización coral. Mapa y requisitos completos: [árbol vigente](arbol-de-mejoras.md). Precios y efectos exactos: [balance.csv](balance.csv).

- Pantalla independiente, sin título, botón visible de atrás ni botones de zoom. Navegación con arrastre y pellizco.
- Descubrimiento progresivo: comprados y siguientes nodos accesibles. La partida nueva comienza mostrando Mano I.
- Nodos comprados con icono y color de categoría; pendientes apagados, comprables con iluminación blanca suave. Conexiones de tramos rectos horizontales, verticales o diagonales.
- Sin ficha inicial. Tocar un nodo muestra una frase esquemática, cantidades destacadas en verde, coste y requisitos. La compra exige mantener su botón **1 s**; soltar antes, mover, interrumpir o usar otro dedo cancela.
- Resultados → botón único «Ir al árbol de mejoras» → pantalla del árbol → «Comenzar día». La bienvenida de una partida nueva conserva su inicio directo.

## Debug implementado

Acceso oculto: **mantener pulsado 3 s el saldo del árbol**, arriba a la derecha. No está en las opciones normales.

- Vista completa: encuadra los 49 nodos. Permite comprar gratis cualquier nodo y adquirir también sus requisitos, o comprar todo.
- Vista del jugador: descubrimiento y compras normales usando saldo y mejoras de prueba. Ambas vistas comparten esa configuración; para ver el principio hay que reiniciar la prueba desde cero.
- Añadir 1000 monedas de prueba, reiniciar, jugar jornadas de prueba y salir.
- La prueba es temporal: no sobrescribe el progreso normal. Salir o reabrir recupera la partida real. Durante una jornada de prueba se muestra DEBUG y un botón de salida.
- [Instrucciones detalladas](modo-debug.md).

## Entrega y comprobaciones

**[Descargar APK 0.6.0+13 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39403619439/artifacts/12256028572)**. Descomprimir e instalar `jardin-mecanico-debug.apk`; es un APK de depuración para pruebas, no una publicación en tienda. Los artefactos de GitHub tienen retención limitada y pueden requerir iniciar sesión.

[Pipeline de esa entrega](https://github.com/migdlp/incremental_hole_game/actions/runs/39403619439): formato, análisis, **135 pruebas**, compilación Android y verificación de firma correctos. Incluye los combos, debug, el ciclo 15+5 y las posiciones intercambiadas.

Las pruebas del debug comprueban acceso oculto, presencia y encuadre de los 49 nodos, compra de un nodo profundo, ambas vistas, restauración del progreso y pantalla pequeña. Las de juego cubren capturas, grupos, escoba, robot, monedas, ciclo y guardado. **No equivalen a una prueba en Android físico.** El usuario dijo que el «modo dibujo» no funcionaba en un APK anterior; se trató como el modo debug del árbol. No consta aún una confirmación manual del último APK.

Pendiente de validar en móvil: acceso debug con dedo, legibilidad del árbol y fichas, tacto y rendimiento con carga, guardado/segundo plano/cierre y diversión del nuevo tablero. Falta medir ingresos y jornadas entre compras para ajustar el balance.

## Persistencia y alcance técnico

Flutter/Dart con Flame, Android vertical y web de apoyo. Juego individual sin cuentas, backend ni dependencia de conexión.

Guardado JSON **v6** y balance vigente **v7** son números diferentes. Se conservan saldo y compras; las jornadas activas con balances 1–6 mantienen su configuración económica y tiempos hasta terminar. El siguiente día usa el balance actual. Los guardados anteriores a combos terminan esa jornada sin introducirlos a mitad. No reiniciar progreso para aplicar mejoras de diseño sin una migración acordada.

No hay tiers individuales, potenciadora, duplicadora, bomba, cartas, flippers, bumpers, fábrica configurable, prestigio ni progreso offline. Sus reglas pendientes están en [cambios futuros](cambios-futuros-arbol-mejoras.md).

## Orden de lectura y continuación

1. [Relevo](relevo-contexto.md) y este estado actual.
2. [Cambios futuros](cambios-futuros-arbol-mejoras.md): pendientes y decisiones abiertas, no lista de tareas ya terminadas.
3. [Árbol](arbol-de-mejoras.md), [economía](economia.md) y [balance.csv](balance.csv) para cambiar reglas concretas.
4. Documentos de implementación, persistencia e historial cuando la tarea lo requiera. Los planes antiguos contienen decisiones reemplazadas; no deben prevalecer sobre este estado y el código.

El último APK se construyó desde `build/apk-0.6.0+13`; no asumir que está integrado en `main`. Para este relevo importan el comportamiento vigente y las decisiones futuras, no reconstruir el historial de commits.
