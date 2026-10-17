# Economía inicial y balance

Estado: hipótesis para empezar a medir; los precios no están validados. Fuente editable: [balance.csv](balance.csv).

## Lectura de la tabla

`level=0` indica configuración base. Para una mejora, `level` es el nivel que se compra y `cost` su precio incremental, no acumulado. `effect_value` es el valor absoluto resultante. `requires` usa `id:nivel`; vacío significa disponible desde la primera noche. `cap` describe el máximo previsto de esa propiedad; el cargador actual no valida esa columna por separado. Los límites efectivos resultan de los valores base y niveles disponibles. Ver [catálogo implementado](implementacion.md#balance-y-mejoras).

Unidades: segundos, unidades lógicas del tablero, unidades/segundo y monedas enteras. La duración base de producción no incluye los 5 segundos de cierre. El radio de pala y el radio de recogida son propiedades distintas.

El saldo comienza en cero. El primer intento de emisión llega al acumular el intervalo de generación, aproximadamente a los 0,75 s con la configuración base; no hay una bola inicial inmediata. Si la salida está bloqueada, espera al siguiente intento. El cierre no genera bolas. A intervalo base de 0,75 s hay hasta 80 emisiones en 60 s si no hay bloqueos. Cada bola vale inicialmente 2 monedas: techo teórico de 160, sin asumir que el jugador lo consiga.

La primera ampliación de pala cuesta 20, equivalente a recoger diez recompensas iniciales. Eso permite comprobar si la primera compra es alcanzable con rendimiento modesto. No garantizarla mediante ingresos ocultos: ajustar precio o generación si las pruebas muestran que no lo es.

## Mejoras

Para los ocho tipos implementados, las ramas y requisitos son: pala y radio de recogida; generador y recompensa; duración tras generador 1; imán tras recogida 1; robot tras pala 1; velocidad tras robot.

La recompensa progresa de 2 a 3, 4 y 5 monedas por bola. Se entrega como valor de una moneda física, no como cinco objetos. El día puede llegar hasta 75 s de producción más cierre. El imán tiene alcance fijo al desbloquearse. El catálogo actual tiene ocho tipos. Está confirmado añadir recogida por barrido, con precio, identificador y dependencias por definir: al inicio solo se recogerá pulsando. No se modifica el CSV durante este brainstorming; ver [plan de cambios](plan-siguiente-iteracion.md).

El robot cuesta 160 después del requisito de pala. El objetivo de conseguirlo en 3–5 días supone partidas de rendimiento modesto y algunas compras; no debe bloquear ahorrar para obtenerlo antes. El objetivo se valida observando sesiones, no solo con la aritmética de precios.

## Registro de sesiones

Para cada jornada anotar: niveles, bolas emitidas/capturadas, valor generado/recogido/perdido, compras, duración y comentarios de comodidad. Registrar manualmente o en logs locales de desarrollo; no hace falta un servicio de analítica.

Métricas útiles:

- Eficiencia de captura = bolas capturadas / emitidas.
- Eficiencia de recogida = valor recogido / generado.
- Ingreso por segundo = ingreso / duración jugada.
- Días hasta primera compra y primer robot.
- Tiempo en el límite de población y número de bloqueos del robot.

Si el denominador es cero, mostrar «sin datos». El valor perdido incluye toda recompensa generada que no llegó a recogerse antes del cierre, incluidas monedas aún en animación.

## Ajuste del MVP

Probar primero sin mejoras, después cada rama y finalmente todas al máximo. Comparar sesiones con la misma semilla cuando sirva para aislar un cambio. Cambiar pocos parámetros cada vez y conservar los resultados anteriores.

Buscar una primera compra visible, opciones razonables entre ramas y crecimiento sin saturación permanente. No exigir que cada jornada supere a la anterior. Alargar el día no debe convertirse en la única compra útil. Si producción supera recogida de forma frustrante, ajustar radios, imán o emisiones antes de añadir nuevos sistemas.

Las variables de renderizado pueden ajustarse para mejorar rendimiento sin alterar las recompensas. Reducir población de bolas sí cambia la producción y exige volver a revisar balance.
