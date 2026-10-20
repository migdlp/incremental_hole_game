# Estado actual de Feed the Hole

Actualizado: **20/10/2026**. Referencia de APK entregado: **0.6.0+13**. La revisión `4d815d9` incorpora interfaz simplificada, feedback visual opcional desactivado por defecto, racha comprable, especiales, escoba de dos puntos y botón DEBUG. Este documento describe lo que existe; las propuestas pendientes están en [cambios futuros](cambios-futuros-arbol-mejoras.md). Para continuar en otro chat, empieza por el [relevo de contexto](relevo-contexto.md).

## Juego y dirección

Juego incremental móvil con físicas arcade. El jugador manipula bolas para meterlas en un agujero, recoge las monedas físicas que producen y compra mejoras permanentes entre jornadas. La automatización debe ayudar a agrupar y dirigir bolas, manteniendo una ventaja clara para quien juega activamente.

Los cuatro ejes de progresión son generar más bolas, capturar una proporción mayor, aumentar el valor de las capturas y recoger mejor las monedas. El sistema de tiers individuales y la fábrica configurable son dirección futura, todavía no sistemas implementados.

## Jornada y tablero vigentes

- Arena lógica de 360 × 560. **Agujero arriba** en (180, 50) y **generador abajo** en (180, 480), con salida y velocidad inicial de las bolas hacia arriba. Ajuste de posiciones en código posterior al APK del commit `046ebb0`; pendiente de comprobar en móvil. Se retira la leyenda del jardín del tablero y la frase «Tu jardín te espera» de la pausa.
- Base de **15 s de producción y 5 s de recogida final**, con una sola barra en el mismo sitio: verde durante producción y naranja durante recogida; contador pequeño encima y alineado a la derecha, sin rótulos de fase. Las mejoras de duración dan 18/21/24/27/30 s de producción; la recogida permanece en 5 s.
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
- La escoba muestra dos puntos de agarre. Un dedo traslada conservando orientación; dos dedos fijan traslado y giro, sin estirar la herramienta. Al levantar uno se conserva el otro agarre; pausa/cancelación/recogida liberan ambos. El giro mantiene límite físico de 3 rad/s. La V usa el mismo control.
- Un robot desbloqueable empuja bolas hacia el agujero; su velocidad se mejora. No recoge monedas.
- **Mientras haya alguna bola agarrada, se bloquean tanto el cobro como la atracción de monedas.**

## Monedas, recompensa y combos

- Capturar genera monedas físicas; recogerlas permite contabilizar el ingreso. La jornada se liquida una sola vez, sin cobrar automáticamente lo pendiente.
- Bola normal base: **1**. La rama global Valor sigue vigente: **2/3/5/8/13** por captura normal, antes de dorada y combo.
- Doradas: **1 %** de las emisiones; recompensa **×10** del valor normal vigente. Actualmente no hay tiers individuales.
- Denominaciones únicas: **1 / 10 / 50 / 100 / 500**. Colores: dorado / verde esmeralda / azul / violeta / coral. Todas tienen las mismas dimensiones y no muestran cifras ni símbolos en su cara. La UI usa icono de moneda sin prefijo dólar.
- Toque para cobrar; Barrido permite arrastrar. Área mejora la recogida manual sin exigir Barrido ni Imán. **Imán cuesta 300 y requiere Área III**; Atracción amplía su alcance.
- Resumen diario con recuento por denominación, de mayor a menor. La antigua barra verde cobrado/generado está eliminada.
- Racha comprable en el árbol (`combo`): requiere Mano I y cuesta **40**. Sin comprarla no hay racha ni multiplicadores. Una vez desbloqueada: ventana inclusiva de **1 s**; capturas 1–4 **×1**, 5–9 **×2**, desde la décima **×3**. La quinta y décima usan ya su nuevo multiplicador. No se modifican premios anteriores.
- Se combinan Valor × dorada × combo. Toda recompensa sigue requiriendo recoger sus monedas. Todas las capturas, incluidas las asistidas, cuentan provisionalmente.
- La racha termina al superar la ventana o entrar en recogida final. Pausar y restaurar no consumen tiempo. Un indicador muestra «Racha lista», contador desde la primera captura, multiplicador y barra de tiempo restante. No se explican los umbrales ni la fórmula en pantalla.

## Habilidades especiales comprables

**Balance provisional de prueba**, ajustable desde `balance.csv`:

| Mejora | Requisito | Coste | Efecto |
| --- | --- | --- | --- |
| Captura total | Racha | 120 | Captura todas las bolas presentes al activar. |
| Recarga de captura I / II | Captura total | 160 / 280 | Carga de 12 → 10 → 8 s. |
| Aceleración especial | Generador I | 100 | Generación ×2 durante 4 s. |
| Potencia de aceleración | Aceleración | 220 | Generación ×3 mientras está activa. |
| Duración I / II | Aceleración | 140 / 240 | Duración de 4 → 5 → 6 s. |
| Recarga de aceleración I / II | Aceleración | 140 / 240 | Carga de 10 → 8 → 6 s. |

Los botones «Captura» y «Turbo» muestran carga/lista y duración activa. Se empieza
cada día sin carga; solo carga el tiempo de producción simulado. La aceleración
recarga después de terminar su efecto. No se pueden activar en pausa ni en
recogida final. Captura total sin bolas conserva la carga. Solo captura las bolas
presentes al pulsar, no futuras emisiones; genera monedas físicas y usa los combos
si se han comprado. No cobra dinero directamente. La aceleración respeta el
límite de 200 bolas y los obstáculos de salida. Las jornadas debug permiten
comprarlas y probarlas sin escribir progreso real. No son las tres habilidades
aleatorias propuestas en CF-19, que siguen pendientes.

## Árbol e interfaz

**59 nodos en 22 tipos**, con seis categorías: Generación verde, Valor dorado, Recogida azul, Control violeta, Tiempo naranja y Automatización coral. Mapa y requisitos completos: [árbol vigente](arbol-de-mejoras.md). Precios y efectos exactos: [balance.csv](balance.csv).

- Pantalla independiente, sin título, botón visible de atrás ni botones de zoom. Navegación con arrastre y pellizco.
- Descubrimiento progresivo: comprados y siguientes nodos accesibles. La partida nueva comienza mostrando Mano I.
- Nodos comprados con icono y color de categoría; pendientes apagados, comprables con iluminación blanca suave. Conexiones de tramos rectos horizontales, verticales o diagonales.
- Sin ficha inicial. Tocar un nodo muestra una frase esquemática, cantidades destacadas en verde, coste y requisitos. La compra exige mantener su botón **1 s**; soltar antes, mover, interrumpir o usar otro dedo cancela.
- Resultados → botón único «Tienda» → tienda → «Comenzar día». La bienvenida de una partida nueva conserva su inicio directo.

## Debug implementado

Acceso directo: botón **DEBUG**, arriba a la izquierda del árbol. Un toque abre el panel; el saldo ya no requiere ni reconoce una pulsación mantenida para entrar.

- Vista completa: encuadra los 59 nodos. Permite comprar gratis cualquier nodo y adquirir también sus requisitos, o comprar todo.
- Vista del jugador: descubrimiento y compras normales usando saldo y mejoras de prueba. Ambas vistas comparten esa configuración; para ver el principio hay que reiniciar la prueba desde cero.
- Añadir 1000 monedas de prueba, reiniciar, jugar jornadas de prueba y salir.
- La prueba es temporal: no sobrescribe el progreso normal. Salir o reabrir recupera la partida real. Durante una jornada de prueba se muestra DEBUG y un botón de salida.
- [Instrucciones detalladas](modo-debug.md).

**Incluido en el último APK:** el panel debug muestra el informe
de la última jornada y permite copiar los últimos 20: emisiones efectivas,
capturas, doradas, pico de combo y monedas generadas/cobradas/perdidas. Estos
datos son temporales y se descartan al reiniciar la prueba o salir. Incluido en el APK de la revisión `4d815d9` enlazado abajo. Las nuevas bolas aún no se
han implementado: está pendiente discutir las reglas del prototipo.

## Entrega y comprobaciones

**[Descargar APK 0.6.0+13 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39458229638/artifacts/12281513638)**. Descomprimir e instalar `jardin-mecanico-debug.apk`; es un APK de depuración para pruebas, no una publicación en tienda. Los artefactos de GitHub tienen retención limitada y pueden requerir iniciar sesión.

[Pipeline de esa entrega](https://github.com/migdlp/incremental_hole_game/actions/runs/39458229638): formato, análisis, **154 pruebas**, compilación Android y verificación de firma correctos. Código compilado: `4d815d9`. Incluye Racha comprable, especiales, escoba de dos dedos, informes de prueba, botón DEBUG y el ajuste de posiciones.

Las pruebas del debug de esa entrega comprobaron acceso por botón, presencia y encuadre de los 59 nodos, compra de un nodo profundo, ambas vistas, restauración del progreso y pantalla pequeña. Las de juego cubren capturas, grupos, escoba, robot, monedas, ciclo y guardado. **No equivalen a una prueba en Android físico.** El usuario dijo que el «modo dibujo» no funcionaba en un APK anterior; se trató como el modo debug del árbol. No consta aún una confirmación manual del último APK.

La revisión entregada pasa 154 pruebas automáticas, además de análisis sin avisos.
Incluyen compra y persistencia de Racha, cargas/activaciones de especiales,
compatibilidad con jornadas anteriores, eventos reales de dos dedos y pantalla
de 320 × 568 con texto al 150 %. La pausa permite desplazar su panel si el
espacio es reducido. La pipeline genera el APK, pero no sustituye la prueba física.

Pendiente de validar en móvil: acceso debug con dedo, legibilidad del árbol y fichas, tacto y rendimiento con carga, guardado/segundo plano/cierre y diversión del nuevo tablero. Falta medir ingresos y jornadas entre compras para ajustar el balance.

## Persistencia y alcance técnico

Flutter/Dart con Flame, Android vertical y web de apoyo. Juego individual sin cuentas, backend ni dependencia de conexión.

Guardado JSON **v7** y balance vigente **v8** son números diferentes. Se conservan saldo y compras; las jornadas activas con balances 1–7 mantienen su configuración económica y tiempos hasta terminar. El siguiente día usa el balance actual. Los guardados anteriores a combos terminan esa jornada sin introducirlos a mitad. Una jornada antigua con racha gratuita conserva su comportamiento hasta terminar; en la siguiente jornada se requiere comprar Racha. No se eliminan ni regalan compras para aplicar el cambio. Las cargas y activaciones pendientes de las especiales se guardan; una pausa o reapertura no concede tiempo ni ejecuta dos veces Captura total. No reiniciar progreso para aplicar mejoras de diseño sin una migración acordada.

No hay tiers individuales, potenciadora, duplicadora, bomba, cartas, flippers, bumpers, fábrica configurable, prestigio ni progreso offline. Sus reglas pendientes están en [cambios futuros](cambios-futuros-arbol-mejoras.md).

## Orden de lectura y continuación

1. [Relevo](relevo-contexto.md) y este estado actual.
2. [Cambios futuros](cambios-futuros-arbol-mejoras.md): pendientes y decisiones abiertas, no lista de tareas ya terminadas.
3. [Árbol](arbol-de-mejoras.md), [economía](economia.md) y [balance.csv](balance.csv) para cambiar reglas concretas.
4. Documentos de implementación, persistencia e historial cuando la tarea lo requiera. Los planes antiguos contienen decisiones reemplazadas; no deben prevalecer sobre este estado y el código.

El último APK se construyó desde `build/apk-0.6.0+13`; no asumir que está integrado en `main`. Para este relevo importan el comportamiento vigente y las decisiones futuras, no reconstruir el historial de commits.

## Simplificación de gameplay incluida en `4d815d9`

No se muestra el número de día en gameplay, resultados ni al comenzar. El saldo
total (saldo guardado más lo recogido durante producción/recogida) y la pausa
negra se superponen dentro del tablero; al terminar no se suman dos veces los
ingresos. Se retiran instrucciones de agarre/cobro, nombres de fases y la
leyenda GENERADOR. El tablero conserva proporciones y gana espacio al compactar
la cabecera. La racha conserva su indicador dentro del tablero.

Los ajustes normales incluyen Sonidos del sistema y Feedback visual. Este último
empieza desactivado y se guarda. Solo controla círculos de pulsación, alcance del
imán y marcas/líneas de agarre; no cambia la física, el alcance ni los controles.
La pausa muestra icono de pausa, Juego pausado, ajustes y Continuar.

## G01 — identidad comercial

El nombre comercial pasa a Feed the Hole en `0.6.0+14`: Android, pantalla de
bienvenida, título de aplicación, errores de inicio y manifiesto/título web.
El package ID, repositorio, nombres internos, rutas de guardado y migraciones
se mantienen. La renombración no toca compras, progreso, físicas ni balance.
Se conserva el historial anterior. La aceptación de actualización requiere
comparar firma y paquete con la APK anterior y comprobarla en un dispositivo.

**Resultado G01:** código de marca publicado en `fd3d8f2`; el APK compila y su
nombre/paquete son correctos. La comparación con la última APK detectó firmas
diferentes y detuvo la publicación. Falta localizar y reutilizar el keystore
original para cumplir la actualización conservando datos.
[Diagnóstico y evidencia de G01](g01-feed-the-hole.md).
