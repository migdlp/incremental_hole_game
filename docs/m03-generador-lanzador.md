# M03 — Generador lanzador

Prototipo **0.11.0+19**, con física y economía provisionales para DEBUG y pruebas
Android. Un solo lanzador adicional, independiente del generador original; no
introduce otras herramientas, bolas, retroceso ni mejoras de potencia.

## Compra y funcionamiento

Rama de Producción: **Generador lanzador** y **Frecuencia del lanzador I–III**.
Para el prototipo, desbloqueo tras Generador II por 120 monedas; frecuencia por
100/180/300, intervalos 2,4 → 1,8 → 1,2 → 0,8 s. **Estos requisitos, precios y
niveles son valores de prueba, no balance definitivo.** El árbol pasa a 69 nodos
y 26 definiciones. La rama principal conserva cadencia y mejoras propias.

Ambos generadores producen simultáneamente. El lanzador dispara a **280 u/s**,
sin mejoras de fuerza, desde la boca en su orientación actual. Usa bolas normales
y doradas con la probabilidad vigente (1 % dorada), mismas recompensas y física.
Los futuros tipos especiales deberán usar el mismo catálogo que el emisor
principal cuando existan; actualmente no hay otros tipos implementados.
Su RNG es independiente del emisor original y de E01/E02. La Aceleración existente
sigue afectando al generador principal; no se añade una sinergia nueva en M03.

Comienza en (285, 510), apuntando diagonalmente hacia la pared derecha, para
probar rebotes sin una captura directa automática inicial. Se permite apuntar
al agujero y girar 360°. Cada disparo correcto produce destello en la boca y
clic provisional sujeto a Sonido. No hay traslación, giro ni animación de retroceso.
Las emisiones fallidas no suenan como disparos ni se acumulan.

## Control y límites

Un dedo sobre el cuerpo/cañón traslada conservando orientación. Dos dedos usan
el mismo `TwoPointGrip` de escoba/bate para trasladar y girar. Puede seguir
disparando agarrado. Levantar uno conserva el otro agarre; al soltar los dos
mantiene pose, sin inercia de lanzamiento. Pausa/cancelación liberan los dedos.

Solo puede ocupar la franja **y = 420–560**, el 25 % inferior. Se limita el cuerpo
circular completo y el cañón, según su ángulo, también contra paredes laterales
y fondo. Al intentar rebasar el límite se muestra una línea roja breve en esa
zona. La colisión usa la misma geometría que el dibujo: cuerpo de radio 18 y
cañón de longitud 30/radio 7. El usuario no tiene que vencer la resistencia física
para moverlo. Las monedas conservan su comportamiento.

## Presión física

Las bolas libres colisionan contra cuerpo y cañón. Cada contacto transmite una
presión proporcional a penetración/velocidad de aproximación, saturada por bola.
Se suman las fuerzas **vectorialmente** y se suavizan; no se cuentan bolas
cercanas ni se almacenan impulsos que crezcan indefinidamente por fotograma.

El umbral está por encima de tres esfuerzos máximos por contacto. Por ello una,
dos o tres bolas no lo desplazan, incluso con impactos rápidos. Una presión
sostenida suficiente puede vencer la resistencia, producir aceleración pequeña
y desplazarlo lentamente, limitada a 12 u/s. La presión opuesta puede cancelarse.
Si la fuerza actual deja de superar el umbral, se detiene; no conserva deriva
por impactos anteriores. Solo el control del jugador cambia la orientación.
Las colisiones no permiten salir de la franja. La calibración de una acumulación
real con el bate, paredes y emisión simultánea sigue pendiente de prueba en móvil.

## Salida obstruida

Se comprueba espacio de salida, recorrido inmediato de la boca, paredes, bolas
y herramientas físicas antes de crear cada bola. Si hay bolas bloqueando, el
intento les aplica un impulso limitado para desplazarlas físicamente; no empuja
bolas agarradas. Si no hay espacio, **no nace una bola superpuesta**, no atraviesa
el sólido y el intento se consume. Liberar la salida no descarga intentos antiguos.
El límite de población es compartido (200); velocidades finales siguen limitadas
por el tablero (380 u/s). El emisor principal evita emitir dentro del nuevo cuerpo.

## Producción y guardado

Solo emite en producción; recogida congela pose, disparos y simulación. Pausa y
segundo plano congelan reloj y física. El guardado conserva pose, velocidad libre,
presión filtrada, reloj parcial, RNG, intentos y disparos correctos; restaurar no
vuelve a emitir el último disparo ni reproduce su sonido. La jornada abre pausada.
`launcherPose` conserva posición/orientación entre jornadas y reinicios. Al
soltar el lanzador se guarda inmediatamente la pose, sin esperar al autoguardado.

JSON sigue en **v7**, balance vigente **v13** con CSV v12 congelado. Guardados
anteriores sin pose reciben el valor inicial; una jornada v12 se reanuda con sus
reglas, sin introducir el lanzador a mitad. Se conservan saldo, compras, paquete
Android y claves de archivos existentes. DEBUG restaura también la pose original
al salir y no escribe compras ni jornadas de prueba en la partida normal.

## Parámetros de prueba

Todos están en [balance.csv](balance.csv), sin valores definitivos de balance.

| Parámetro | Inicial |
| --- | ---: |
| Desbloqueo / requisito | 120 / Generador II |
| Frecuencia I–III | 100 / 180 / 300 |
| Intervalos | 2,4 / 1,8 / 1,2 / 0,8 s |
| `launcher_speed` | 280 u/s |
| `launcher_body_radius` | 18 u |
| `launcher_barrel_length` / `launcher_barrel_radius` | 30 / 7 u |
| `launcher_pressure_threshold` | 400 |
| `launcher_contact_pressure_limit` | 120 |
| `launcher_pressure_stiffness` | 3000 |
| `launcher_pressure_response` | 12/s |
| `launcher_mass` / `launcher_damping` | 12 / 8/s |
| `launcher_pressure_speed` | 12 u/s |
| `launcher_restitution` | 0,4 |
| `launcher_obstruction_force` | 100 u/s |
| `launcher_move_speed` / `launcher_angular_speed` | 900 u/s / 4 rad/s |

El catálogo rechaza umbral ≤3 esfuerzos máximos, velocidad de salida superior al
límite del tablero, intervalos inferiores a 0,25 s, mejoras que no aumenten
frecuencia y geometría que no quepa en la franja con orientación libre.

## Probar en DEBUG

1. **Tienda → DEBUG**, cerrar panel y comprar Generador lanzador (o su frecuencia
   más alta); compras gratis en mapa completo incluyen requisitos temporales.
2. Comenzar día de prueba. Ambos emisores deben funcionar juntos. Trasladar con
   un dedo y girar con dos, también durante disparos. Probar cuatro paredes con M01.
3. Intentar sacar cuerpo/cañón de la franja: se detiene y aparece línea roja.
4. Bloquear salida con bolas o bate/escoba; liberar y comprobar que no hay ráfaga
   acumulada. Presionar una acumulación contra el cuerpo y comprobar movimiento lento.
5. Terminar jornada y comprobar pose en la siguiente; pausar/reanudar sin disparos
   duplicados. **Salir de depuración** recupera compras, monedas y pose reales.

Pendientes: calibración económica/física, legibilidad y tacto, audio/aspecto final
y rendimiento en Android físico. Las pruebas automáticas no sustituyen esa validación.
