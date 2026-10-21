# M01 — Paredes rebotadoras

Especificación funcional implementada. Pendiente únicamente de balance: precios,
requisitos finales y calibración de multiplicadores. Referencia de código:
`0.7.0+15`, guardado v7 y balance v9.

## Física y compras

Las cuatro paredes tienen rebote base ×0,40. La mejora `walls`, Paredes
rebotadoras, tiene tres compras sucesivas: I ×1,10, II ×1,35 y III ×1,60.
La potencia afecta a la componente normal de la velocidad; la tangencial se
conserva. En una esquina se resuelven las dos normales y se limita la velocidad
del vector una vez, sin aplicar dos veces el multiplicador a todo el vector.

`wall_restitution` y `ball_speed_limit` viven en `balance.csv`. El límite inicial
es 380 u/s y también se aplica tras impulsos, movimientos de agarre y restauración.
La resolución usa pasos de como máximo 1/240 s. Solo se refleja una componente
que llega hacia la pared: un contacto estacionario o que se separa no crea
impulsos. No hay activación manual, ni disparos adicionales de habilidades.

Bolas normales y doradas usan el mismo solver. Las futuras bolas especiales deben
usar esa misma ruta; M01 no implementa tipos nuevos ni reglas de sus habilidades.
Las monedas no pasan por el rebote. Las restricciones del agarre siguen controlando
las bolas sujetas. Durante recogida se conserva la congelación de las bolas.
La captura comprueba el recorrido y se procesa en cada subpaso para que una bola
rápida no cruce el hoyo y escape antes de terminar el frame.

**Balance provisional de prueba, no aprobado:** precios 40/100/220 y requisito
Mano I para los tres niveles. Los niveles II y III requieren también la compra
anterior. No modificar ni presentar estas cifras como balance final sin jugar y
validarlas con el usuario. La nueva rama es de Control y puede comprarse gratis
con sus requisitos mediante DEBUG; la tienda completa tiene 62 nodos y 23 tipos.

## Guardado y compatibilidad

Los niveles se guardan mediante el mapa de compras existente, sin reiniciar saldo,
compras ni progreso. Comprar durante una jornada sigue bloqueado. La configuración
se toma al comenzar la siguiente jornada y queda fijada para ella.

El balance v8 se congela en `balance_v8.dart`. Las jornadas v1–v8 ya guardadas
se reanudan con sus ajustes anteriores; sin campos de paredes utilizan ×0,40 y
380 u/s. Al comenzar otra jornada se usa balance v9. El esquema JSON sigue siendo
v7: no cambian los archivos ni las migraciones anteriores.

## Efectos y rendimiento

Las paredes mejoradas muestran una línea elástica. Cada impacto genera una
hendidura y una onda que viaja simétricamente por ambos lados del contacto,
con intensidad proporcional a la velocidad normal de llegada. La geometría
física no se deforma. Los efectos duran 0,45 s, no se guardan y se limitan a 32
impactos activos, incluso con 200 bolas.

`GardenGame.wallEffectsEnabled` permite reducir la animación sin tocar la física;
no es un botón de activación de las paredes. El feedback de paredes es
independiente de la preferencia de círculos de pulsación. La renderización no
avanza la simulación ni consume eventos físicos.

## Verificación

`rebounding_walls_test.dart` cubre cuatro paredes y potencias, doradas, velocidad
normal/tangencial, esquinas, límite configurable, ausencia de impulsos por reposo,
capturas rápidas tras rebote, monedas y recogida congelada, persistencia de los
niveles y partidas v8. Incluye estrés con 200 bolas, límite/caducidad de impactos
y comparación de imágenes con ondas activadas/reducidas sin modificar el tablero.

La suite general comprueba además controles, guardado, economía y el encuadre y
conexiones de los 62 nodos. Pendiente de comprobar tacto, legibilidad de las ondas
y rendimiento en un teléfono físico. Las mediciones locales no certifican FPS de
Android ni el balance de precios.

Medición local de referencia: carga sintética de 200 bolas, velocidades
reinyectadas hacia paredes para sostener los impactos, 120 frames de calentamiento
y 600 medidos: media aproximada de 1,34 ms por frame de física, búfer 32/32.
No incluye renderizado ni certifica rendimiento Android. Repetir desde la raíz:
`dart run tool/benchmark_rebounding_walls.dart`.
