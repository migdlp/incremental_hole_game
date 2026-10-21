# E01 — Habilidad especial: Gravedad

Prototipo **0.9.0+17**, pendiente de calibración y comprobación en Android físico.
Evento aleatorio de producción, sin compra, requisito ni botón de activación.
No modifica las 65 mejoras existentes ni añade otras herramientas o eventos.

## Aparición y activación

Cada jornada compatible tiene un único sorteo con probabilidad configurable
**5 %**, desde la primera. Si sale, se programa una aparición en un momento
aleatorio de esa producción. El objeto deriva lentamente y permanece hasta
romperse o empezar la recogida final. No reaparece durante esa jornada ni pasa
a la siguiente. Sin sensor compatible no se sortea ni se muestra en juego normal.

Al aparecer se eligen **3–6 pulsaciones** para romperlo. Cada toque completo muestra
destello y grietas de daño; arrastrar, cancelar o mantener un segundo dedo no
produce golpes adicionales. La última pulsación elimina el objeto y activa el
efecto una sola vez. Un anuncio «HABILIDAD ESPECIAL: GRAVEDAD» y un flash breve
sobre el tablero duran aproximadamente un segundo de simulación. Son feedback
propio del evento; no dependen del ajuste de círculos de pulsación.

El objeto no colisiona ni recibe daño de bolas en este prototipo. **Sigue abierta**
la posibilidad de que las colisiones lo dañen; no se ha elegido una regla final.
Tocar el objeto no mueve herramientas ni recoge monedas que coincidan con él.

## Sensor y física

Android usa `TYPE_GRAVITY` y, si no entrega una lectura válida, prueba
`TYPE_ACCELEROMETER`. La sonda exige registrar el sensor y recibir datos finitos;
no basta con que su nombre figure en el dispositivo. Cada candidato tiene una
ventana de 900 ms. El acelerómetro alternativo se filtra con constante de 0,25 s
para aproximar gravedad y reducir la respuesta a sacudidas. No se añaden paquetes
Flutter, permisos de sensores de alta frecuencia ni requisitos que excluyan
instalar la app en teléfonos sin sensores.

El puente remite ejes y rotación de pantalla. Dart proyecta al tablero vertical,
con x hacia la derecha e y hacia abajo: inclinación hacia el lado físicamente
bajo produce fuerza hacia ese lado. Se contemplan las cuatro rotaciones de la
pantalla, también para dispositivos cuya orientación natural es horizontal.
El muestreo se solicita a frecuencia de juego de Android; si transcurre un
segundo sin una lectura válida, se anula la entrada y se pierde disponibilidad.
Una lectura nueva puede recuperarla. Pausa, recogida y segundo plano cancelan
la suscripción; reanudar comienza sin una lectura antigua pendiente.

La fuerza se suaviza y limita antes de integrarse en los subpasos existentes del
tablero. Afecta a bolas normales y doradas y a escoba/bate libres. Las bolas
agarradas no reciben la fuerza; agarrar una herramienta suspende su aceleración
y elimina su velocidad libre. Al soltarla vuelve a acelerarse gradualmente.
Las monedas no reciben fuerza. Se mantienen colisiones, capturas, probabilidades
de doradas, valores, tiers y contabilidad existentes.

Las herramientas libres conservan orientación, chocan contra los límites del
tablero y transmiten su movimiento mediante las colisiones existentes. La gravedad
no añade activaciones especiales por contacto. Actualmente no existen ventilador
ni nuevos tipos de bola especial; no se implementan como parte de E01.

El límite de velocidad de bolas y herramientas libres sigue siendo 380 u/s.
Activar/desactivar no asigna una velocidad nueva a las bolas. Al acabarse la
fuerza conservan su inercia, con amortiguación; las herramientas libres también
frenan gradualmente. Durante recogida final quedan totalmente congeladas.
No hay indicador permanente de dirección ni contador adicional en el tablero.

## Tiempo y guardado

La activación dura **como máximo 10 segundos de producción**, o el tiempo que
quede hasta recogida si es menor. No prolonga la jornada. El tiempo del anuncio,
daño y habilidad usa la misma simulación: pausa y segundo plano no lo consumen;
el regreso conserva exactamente el resto y requiere reanudar la jornada pausada.

JSON sigue en **v7**, balance vigente **v11**. El CSV v10 está congelado para
reanudar jornadas antiguas con sus ajustes, sin introducir el evento a mitad.
Al comenzar otra jornada se usa el balance vigente.

El sorteo tiene RNG independiente del generador de bolas. La sesión guarda
`eventRandom`; una partida anterior sin ese campo recibe una semilla nueva sin
cambiar ahorro, compras ni jornada guardada. Cada tablero v11 guarda `gravity`
(fase, RNG, momento de aparición, tiempo simulado, pose/deriva del objeto,
resistencia/daño, duración restante, anuncio y fuerza filtrada) y velocidades
libres de escoba/bate. Restaurar valida todo antes de aplicar la sesión: no vuelve
a sortear, no reinicia pulsaciones ni activa de nuevo el anuncio. El guardado tras
cada toque incluye el daño o la activación inmediatamente. La jornada se reabre
pausada y sin dedos activos.

Al empezar recogida se eliminan objeto, fuerza y anuncio y se congelan herramientas.
Al terminar el día se descarta el tablero. No se conserva el objeto ni la activación
para otra jornada. Si se restaura en un dispositivo sin sensor, se conserva el
estado temporal, pero no se muestra el objeto ni se aplica fuerza; el tiempo de
producción sigue siendo el límite, sin conceder tiempo adicional.

## DEBUG y prueba en teléfono

1. Abrir **Tienda → DEBUG → Gravedad**.
2. Dejar **Sensor real** para comprobar el teléfono. Si se detecta compatible,
   activar **Forzar Gravedad en la próxima jornada**.
3. Volver a la tienda y comenzar la jornada de prueba: aparece un objeto desde
   el inicio. Romperlo con 3–6 toques e inclinar el móvil hacia los cuatro lados.
4. Para probar sin hardware, seleccionar **Simular: reposo/izquierda/derecha/arriba/
   abajo** y activar el mismo interruptor. Es una excepción explícita de DEBUG,
   nunca habilita sensores ficticios en la partida normal.
5. Comprar escoba y bate en la prueba para comprobar que se mueven libres,
   permanecen controlables al agarrarlos y vuelven a recibir fuerza al soltarlos.
6. Pausar, bloquear/reabrir la app y comprobar la conservación del tiempo. Repetir
   una activación cercana al final de producción y comprobar que termina al recoger.

El interruptor de forzar se consume al iniciar esa jornada. Las opciones de
inclinación/forzado son temporales y se restablecen al reiniciar o salir de DEBUG.
No se guardan compras, eventos, reinicios ni semillas de las pruebas en la partida
normal; la instantánea original se restaura al salir.

## Parámetros provisionales y decisiones abiertas

La fuente editable es [balance.csv](balance.csv). Probabilidad inicial 0,05;
duración máxima 10 s; deriva del objeto 8 u/s; aceleración máxima 180 u/s²;
respuesta de inclinación 6/s; amortiguación adicional de bolas 0,15/s y de
herramientas libres 2,4/s. Rebote de herramientas contra límites 0,35, constante
del prototipo, independiente de la mejora de paredes que sigue afectando a bolas.
La probabilidad admite 0 para desactivar apariciones en calibración y está limitada
a 1; la duración no admite superar 10 s.

Estos valores físicos y la apariencia del objeto son **provisionales**. Quedan
abiertos daño por colisión con bolas, reglas para otros eventos aleatorios
simultáneos y balance cuando exista un catálogo mayor de eventos. Captura total y
Turbo comprables conservan sus reglas actuales; no se inventan prioridades entre
futuros eventos aleatorios que todavía no existen.

## Verificación

211 pruebas locales superadas: 22 del evento y 6 del adaptador de movimiento,
además de la suite existente. Cubren probabilidad, aparición única, pulsaciones,
gestos reales simultáneos, fuerzas graduales, agarres, monedas, velocidades,
límites, 200 bolas, duración, cierre, pausa/segundo plano, guardados antes/después
de aparecer/activar, migración v10, entradas inválidas, aislamiento DEBUG, ejes,
lecturas inválidas, pérdida/recuperación de sensores y presentación en pantalla
pequeña. La copia congelada del balance anterior se contrasta con el CSV entregado.

La compilación Android verifica el puente Kotlin, pero no acredita la respuesta
de un sensor físico. Siguen pendientes sentido real de inclinación, comodidad,
fuerza, aspecto, batería y rendimiento en un teléfono. No declarar aceptación
física por pasar pruebas automáticas o generar una imagen. La firma compatible
con APK anteriores sigue pendiente según [G01](g01-feed-the-hole.md).
