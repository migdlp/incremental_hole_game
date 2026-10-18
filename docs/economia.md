# Economía inicial y balance

Estado de `0.2.2+4`: valores implementados para probar; precios y ritmo de compras todavía provisionales. Fuente editable del balance actual: [balance.csv](balance.csv).

## Lectura de la tabla

`level=0` indica base. En una mejora, `level` es el nivel comprado y `cost` su precio incremental. `effect_value` es el valor absoluto resultante; `requires` usa `id:nivel`. `cap` es descriptivo, no un validador adicional del cargador. El parser admite nueve columnas simples, sin comas entrecomilladas. Ver [catálogo](implementacion.md#balance-y-mejoras).

Duración de producción y cierre se suman para obtener el contador visible. `paddle_radius` conserva su clave histórica, pero el frente completo de escoba mide cuatro veces su valor; no es el radio de recogida de monedas.

## Jornada y generación actuales

| Nivel | Producción | Cierre | Contador total | Intervalo del generador |
| --- | --- | --- | --- | --- |
| Base | 10 s | 5 s | **15 s** | **⅔ s (1,5 bolas/s)** |
| Mejora 1 | 15 s | 5 s | 20 s | ≈ 0,578 s |
| Mejora 2 | 20 s | 5 s | 25 s | ≈ 0,489 s |
| Mejora 3 | 25 s | 5 s | 30 s | 0,4 s |

Duración y generador son mejoras independientes; cada columna muestra sus propios niveles. Duración requiere generador nivel 1. La base emite 1,5 bolas por segundo. Los intervalos de los niveles se reducen en la misma proporción (2/9 del balance anterior de 3/2,6/2,2/1,8 s), conservando sus aumentos relativos de velocidad.

La primera bola llega tras acumular el intervalo, no inmediatamente. Una salida bloqueada o el límite de población pierde ese intento, sin cola. En cierre no hay producción. El día base sin bloqueos intenta emitir cada dos tercios de segundo: **quince bolas** durante los diez segundos de producción. Cada bola vale 2 monedas, hasta 30 si entran las quince; solo se ingresan al recogerlas. La comparación del reloj usa tolerancia numérica para no perder la emisión del límite por redondeo.

## Mejoras

| ID | Compra | Costes por nivel | Efecto y requisito del CSV |
| --- | --- | --- | --- |
| `broom` | Escoba recta | 20 | Frente 80; sin requisito |
| `paddle` | Anchura | 20 / 70 / 160 | Frentes 96 / 112 / 128; requiere escoba; afecta también a la V |
| `broom_v` | Escoba en V | 80 | Reúne por contacto; requiere anchura 1 |
| `sweep` | Barrido de monedas | 20 | Desbloquea recogida por recorrido; sin requisito |
| `collection` | Radio de recogida | 25 / 80 / 180 | Radios 24 / 30 / 36; base 18; no desbloquea barrido |
| `magnet` | Imán | 120 | Radio 65 mientras se toca; requiere recogida 1, independiente de barrido |
| `generator` | Generación | 30 / 100 / 220 | Intervalos ≈ 0,578 / 0,489 / 0,4 s |
| `reward` | Recompensa | 40 / 140 / 300 | Valores 3 / 4 / 5 por bola; base 2 |
| `duration` | Duración | 60 / 160 / 320 | Producción 15 / 20 / 25 s; requiere generador 1 |
| `robot` | Robot | 160 | Un robot; requiere anchura 1; no recoge monedas |
| `robot_speed` | Velocidad del robot | 80 / 200 / 400 | 55 / 70 / 85 u/s; requiere robot; base 45 |

Escoba, V, barrido, imán y robot son desbloqueos únicos; las otras mejoras tienen tres niveles. La mano inicial no cuesta dinero. Comprar una herramienta la selecciona; se puede volver a otras ya compradas. Los efectos de compra comienzan el día siguiente. La recompensa aumenta valor, no necesariamente número de objetos físicos.

Los requisitos de la tabla son los de sesión/CSV. El [árbol progresivo](arbol-de-mejoras.md) añade padres de descubrimiento: inicialmente solo se ve generador 1; escoba, barrido y radio se revelan tras comprarlo, y recompensa tras generador 2. Esto no modifica compras históricas ni concede padres gratis.

## Ritmo pendiente de ajuste

Con treinta monedas teóricas por día base y la primera compra visible de treinta (generador 1), la compra inicial puede llegar al terminar la primera jornada si se capturan y cobran todas las bolas sin bloqueos ni pérdidas. Esto es un límite aritmético, no una prueba de comodidad o accesibilidad.

Los precios no cambian en esta iteración y siguen pendientes de balance. El ritmo del robot en 3–5 días no está verificado y no se compensa con ingresos ocultos.

## Registro de sesiones

Anotar niveles, bolas emitidas/capturadas, valor generado/recogido/perdido, compras, duración y comodidad. Métricas: captura/producción, recogida/valor generado, ingreso/segundo, días hasta primera compra y robot, bloqueos y saturación. Si un denominador es cero, indicar «sin datos». No hace falta telemetría externa.

## Ajuste del MVP

Comparar base, cada rama y máximos, usando una misma semilla cuando ayude. Cambiar pocos parámetros por prueba. No exigir récord cada día ni convertir duración en compra obligatoria. Los precios permanecen provisionales hasta observar sesiones.

El valor perdido incluye pilas y monedas en aterrizaje que no se cobraron al cierre. Las bolas y monedas dejan de existir en la sesión activa al cerrar; el fondo conserva solo una imagen inmóvil del tablero mientras se consulta el pop-up. No se pueden recoger ni se guardan como jornada activa. Ahorro y compras permanecen. Las jornadas antiguas guardadas terminan con su balance anterior; el siguiente día adopta estos valores. Ver [compatibilidad](persistencia.md#compatibilidad-entre-versiones).
