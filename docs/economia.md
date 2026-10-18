# Economía inicial y balance

Estado de `0.2.1+3`: valores implementados para probar; precios y ritmo de compras todavía provisionales. Fuente editable del balance actual: [balance.csv](balance.csv).

## Lectura de la tabla

`level=0` indica base. En una mejora, `level` es el nivel comprado y `cost` su precio incremental. `effect_value` es el valor absoluto resultante; `requires` usa `id:nivel`. `cap` es descriptivo, no un validador adicional del cargador. El parser admite nueve columnas simples, sin comas entrecomilladas. Ver [catálogo](implementacion.md#balance-y-mejoras).

Duración de producción y cierre se suman para obtener el contador visible. `paddle_radius` conserva su clave histórica, pero el frente completo de escoba mide cuatro veces su valor; no es el radio de recogida de monedas.

## Jornada y generación actuales

| Nivel | Producción | Cierre | Contador total | Intervalo del generador |
| --- | --- | --- | --- | --- |
| Base | 10 s | 5 s | **15 s** | **3 s** |
| Mejora 1 | 15 s | 5 s | 20 s | 2,6 s |
| Mejora 2 | 20 s | 5 s | 25 s | 2,2 s |
| Mejora 3 | 25 s | 5 s | 30 s | 1,8 s |

Duración y generador son mejoras independientes; cada columna muestra sus propios niveles. Duración requiere generador nivel 1. La frecuencia de emisión es cuatro veces menor que antes en todos los niveles; antes los intervalos eran 0,75/0,65/0,55/0,45 s.

La primera bola llega tras acumular el intervalo, no inmediatamente. Una salida bloqueada o el límite de población pierde ese intento, sin cola. En cierre no hay producción. El día base sin bloqueos intenta emitir a los 3, 6 y 9 s: **tres bolas**, frente al máximo teórico anterior de 80 en 60 s. Cada bola vale 2 monedas, por lo que se generan como máximo 6 si entran las tres; solo se ingresan al recogerlas.

## Mejoras

| ID | Compra | Costes por nivel | Efecto y requisito del CSV |
| --- | --- | --- | --- |
| `broom` | Escoba recta | 20 | Frente 80; sin requisito |
| `paddle` | Anchura | 20 / 70 / 160 | Frentes 96 / 112 / 128; requiere escoba; afecta también a la V |
| `broom_v` | Escoba en V | 80 | Reúne por contacto; requiere anchura 1 |
| `sweep` | Barrido de monedas | 20 | Desbloquea recogida por recorrido; sin requisito |
| `collection` | Radio de recogida | 25 / 80 / 180 | Radios 24 / 30 / 36; base 18; no desbloquea barrido |
| `magnet` | Imán | 120 | Radio 65 mientras se toca; requiere recogida 1, independiente de barrido |
| `generator` | Generación | 30 / 100 / 220 | Intervalos 2,6 / 2,2 / 1,8 s |
| `reward` | Recompensa | 40 / 140 / 300 | Valores 3 / 4 / 5 por bola; base 2 |
| `duration` | Duración | 60 / 160 / 320 | Producción 15 / 20 / 25 s; requiere generador 1 |
| `robot` | Robot | 160 | Un robot; requiere anchura 1; no recoge monedas |
| `robot_speed` | Velocidad del robot | 80 / 200 / 400 | 55 / 70 / 85 u/s; requiere robot; base 45 |

Escoba, V, barrido, imán y robot son desbloqueos únicos; las otras mejoras tienen tres niveles. La mano inicial no cuesta dinero. Comprar una herramienta la selecciona; se puede volver a otras ya compradas. Los efectos de compra comienzan el día siguiente. La recompensa aumenta valor, no necesariamente número de objetos físicos.

Los requisitos de la tabla son los de sesión/CSV. El [árbol progresivo](arbol-de-mejoras.md) añade padres de descubrimiento: inicialmente solo se ve generador 1; escoba, barrido y radio se revelan tras comprarlo, y recompensa tras generador 2. Esto no modifica compras históricas ni concede padres gratis.

## Ritmo pendiente de ajuste

Con seis monedas máximas por día base y la primera compra visible de treinta (generador 1), no se puede comprar el primer día. Ahorrando y cobrando las tres bolas cada día se llega a treinta en la quinta jornada; una compra de veinte llegaría en la cuarta por aritmética, pero no es la raíz disponible en la UI. Esto es un límite aritmético, no una prueba de comodidad o accesibilidad.

La hipótesis anterior de compra inicial inmediata y robot en 3–5 días queda pendiente de redefinición tras este cambio; no describe un ritmo verificado ni un requisito que la entrega cumpla. Se mantuvieron los precios anteriores por petición de trabajar primero los controles y después el balance. No se compensa con ingresos ocultos. Próximo trabajo: acordar precios y revisar progreso con el árbol implementado.

## Registro de sesiones

Anotar niveles, bolas emitidas/capturadas, valor generado/recogido/perdido, compras, duración y comodidad. Métricas: captura/producción, recogida/valor generado, ingreso/segundo, días hasta primera compra y robot, bloqueos y saturación. Si un denominador es cero, indicar «sin datos». No hace falta telemetría externa.

## Ajuste del MVP

Comparar base, cada rama y máximos, usando una misma semilla cuando ayude. Cambiar pocos parámetros por prueba. No exigir récord cada día ni convertir duración en compra obligatoria. Los precios permanecen provisionales hasta observar sesiones.

El valor perdido incluye pilas y monedas en aterrizaje que no se cobraron al cierre. Bolas y monedas desaparecen de noche; ahorro y compras permanecen. Las jornadas antiguas guardadas terminan con su balance anterior; el siguiente día adopta estos valores. Ver [compatibilidad](persistencia.md#compatibilidad-entre-versiones).
