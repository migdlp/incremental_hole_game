# Ideas: recoger y lanzar bolas

Fecha: 17 de octubre de 2026. Estado: **brainstorming**, sin implementación ni selección definitiva de herramientas. La aspiradora con capacidad ampliable, la mano y las aspas parten de ideas del usuario; las demás son propuestas para comparar. El prototipo actual utiliza una pala que empuja.

## Qué debe mejorar la progresión

Cada avance debe aliviar una dificultad reconocible: reunir bolas dispersas, transportarlas sin perderlas o dirigirlas al hoyo. Conviene cambiar lo que permite hacer una herramienta, además de aumentar su tamaño. Recoger una bola significa moverla o cargarla; solo introducirla en el hoyo produce una recompensa.

## Candidatas

| Herramienta | Gesto y comportamiento propuestos | Mejoras posibles | Límite o decisión interesante |
| --- | --- | --- | --- |
| Mano | Mantener para agarrar un grupo; arrastrar para transportarlo y soltar para lanzarlo | Alcance, bolas por agarre, ayuda de dirección | Elegir dónde agarrar y dónde soltar; probar una trayectoria visible |
| Aspiradora | Mantener para aspirar hacia un depósito; soltar para parar; pulsar una salida visible para descargar hacia el hoyo | **Capacidad máxima ampliable**, radio y velocidad de aspiración, descarga | Cuando se llena hay que descargar; mostrar ocupación y evitar aspirar indefinidamente |
| Aspas / ventilador | Orientar una corriente que empuja bolas hacia el hoyo | Anchura, fuerza, giro; automatización posterior | Ayuda sobre una zona, sin garantizar que toda bola entre |
| Recogedor / cazo | Barrer para cargar bolas por delante; inclinar o soltar cerca del hoyo para vaciar | Anchura de boca, capacidad y retención | Más fácil transportar grupos, pero puede llenarse |
| Pala en V | Arrastrar una pala que reúne bolas hacia su centro | Apertura y profundidad | Primera mejora sencilla: se escapan menos por los lados |
| Tirachinas / catapulta | Cargar un grupo, estirar hacia atrás y soltar para lanzarlo | Capacidad, ayuda de puntería y potencia | Un lanzamiento resuelve un grupo; debe ser fácil apuntar con un dedo |
| Cañón de aire | Apuntar y dar un soplido que desplaza un grupo sin almacenarlo | Apertura del cono, alcance y recarga | Elegir el ángulo y el momento; demasiada fuerza puede dispersar |
| Lazo | Dibujar un círculo para agrupar bolas y arrastrarlas juntas | Área máxima, capacidad y asistencia al cerrar el círculo | Mucho control, pero más gestos; comparar comodidad con la mano |
| Parachoques orientable | Colocarlo para que las bolas que choquen salgan dirigidas al hoyo | Tamaño, fuerza y orientación | Preparar una ruta y luego aprovecharla; depende de recibir bolas |
| Remolino | Mantener una zona que junta bolas; soltar para expulsarlas en una dirección | Radio, capacidad y tiempo activo | Combina agrupar y lanzar, con recarga o límite para no vaciar todo el tablero |
| Cinta transportadora | Colocar un tramo que lleve las bolas hasta una salida cercana al hoyo | Anchura, velocidad y longitud | Automatización avanzada; requiere alimentar la entrada y orientar la salida |

Los gestos son hipótesis para prototipar. En especial, probar la descarga de aspiradora con una mano antes de fijar botones o modos. No se fijan todavía capacidades, precios, requisitos ni duraciones.

## Progresión que probaría primero

**Pala → recogedor o mano → aspiradora → ayudas como aspas y cinta.** Es una propuesta, no una secuencia aprobada. La pala en V puede servir de primer alivio barato; la mano introduce transportar grupos y la aspiradora añade la satisfacción de llenar y vaciar un depósito. Aspas, parachoques y cinta pueden ser apoyos colocados en el tablero, sin obligar a sustituir siempre la herramienta manual.

Prototiparía mano y aspiradora por separado, manteniendo iguales producción y recompensa para comparar comodidad. Observar: gestos necesarios para llevar un grupo al hoyo, bolas que se escapan, errores de descarga, tiempo dedicado a apuntar y preferencia del jugador. Elegir primero una herramienta principal; no llenar la pantalla de controles para todas las candidatas.

## Reglas que deben respetar

- Ninguna herramienta da dinero por recoger o almacenar bolas: la recompensa ocurre al entrar en el hoyo.
- Al llegar la noche desaparecen también las bolas cargadas en manos, depósitos o transportadores. El día siguiente empieza vacío; se conservan herramientas compradas, niveles y ahorro.
- Si se implementa almacenamiento, contar también esas bolas al limitar población y guardarlas al pausar la misma jornada. Evitar duplicarlas al cargar, descargar o restaurar.
- Las herramientas de bolas no recogen monedas por defecto. Esa función requiere una decisión explícita; no debe anular la progresión de recogida de dinero.
- Las ayudas deben reducir esfuerzo repetitivo conservando decisiones sobre posición, recorrido o descarga. La automatización necesita pruebas de balance.

## Cambio confirmado: monedas

Al principio las monedas requieren **pulsar para recogerlas**. Comprar la mejora de **recogida por barrido** permite cobrarlas también arrastrando el dedo por encima; el toque sigue funcionando. Es distinta de aumentar radio y del imán. Su precio, requisitos y relación con esas mejoras quedan por definir.

Este cambio sí forma parte del [plan de la siguiente iteración](plan-siguiente-iteracion.md). El código actual aún permite barrer desde el inicio: esta documentación no implementa el nuevo bloqueo. Las herramientas de esta lluvia de ideas no se incorporan automáticamente al alcance de esa iteración.
