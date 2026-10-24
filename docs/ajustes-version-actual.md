# Ajustes de la versión actual — Feed the Hole

## AJ-005A · Crecimiento por cuota (0.17.0+27)

Cada cuota completada aumenta el **área de captura un 16 %**, una sola vez:
radio = radio base × √(1,16^cuotas). El dibujo y la captura usan el mismo radio.
Se aplica en la jornada actual y persiste entre jornadas y reinicios; se pierde
al terminar la partida normal, como el resto de su progresión temporal.
No depende de compras, no añade nodos y conserva el centro al 22 % de altura.
JSON v13 registra número de crecimientos y última cuota aplicada. Los guardados
anteriores conservan su progreso y empiezan a crecer con la siguiente cuota;
las cuotas ya completadas no se vuelven a premiar. Balance v19 sin cambios.
Los tiempos y la estética de monedas de 0.16.2 se conservan.
**Decisión consultada aún abierta:** tamaño al llegar a los bordes. No se añade
un tope de balance sin aprobación; se mantiene el crecimiento solicitado del 16 %.

Validado: formato, análisis y **369 pruebas**, compilación Android y firma.
Código compilado `9615d08`; [APK 0.17.0+27 y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/40111416219/artifacts/12566373126). Prueba táctil en Android físico pendiente.

## Tiempos de monedas · 0.16.2+26

Se conserva el dibujo, el salto de salida y el recorrido de las monedas.
Tras aterrizar quedan inmóviles **1 segundo** y después vuelan al monedero
con un inicio más lento y aceleración progresiva, manteniendo el final suave.
El cobro visual espera también esa pausa; importes, liquidación al cerrar,
restauración y ausencia de física/interacción permanecen iguales.
Incluye la corrección del hoyo al 22 % de altura descrita debajo.

Validado: formato, análisis y **360 pruebas**, compilación Android y firma.
Código compilado `e409af8`; [APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39861748135/artifacts/12462915831). Sin prueba táctil en Android físico.

## Corrección posterior · 0.16.1+25

El usuario sustituye la posición aproximada del 75 % por el **22 % de la altura**.
Centro vigente (180,123.2), horizontal conservada. Balance v19 con v18 congelado;
la siguiente jornada aplica la posición nueva. El apartado de AJ-004 de 0.16.0
inferior conserva la explicación de esa entrega anterior. AJ-005A define posteriormente el crecimiento por cuotas.

Se continúa desde 0.15.0+23 y sus sistemas P01/C01/S03. No se recuperan versiones
antiguas ni se añaden mecánicas de otros documentos.

| ID | Estado | Resultado |
| --- | --- | --- |
| AJ-001 | Implementado | Fuerza alta base, sin rama ni niveles; capacidad conservada |
| AJ-002 | Implementado | Monedas acuñadas con canto, cara plana y grabado |
| AJ-003 | Implementado | Icono y saldo sobre tablero sin recuadro |
| AJ-004 | Implementado y corregido | Centro vigente al 22 % de altura del tablero |
| AJ-005A | Implementado | +16 % de área por cuota, persistente y sin duplicados |

## Agarre y compatibilidad

La rama de cinco niveles de Fuerza de agarre desaparece del catálogo, mapa y
compras DEBUG. La fuerza inicial es ×4, sin compras, con capacidad independiente
de 1–6 bolas. Se mantiene la física de seguimiento y lanzamiento, límites de
velocidad y liberación excepcional por estiramiento extremo. Las pruebas incluyen
seis bolas, cambios rápidos de dirección y distintas tasas de fotogramas.

Las compras antiguas de fuerza se retiran y su coste histórico se devuelve una
única vez: 25/50/90/160/280 monedas por nivel adquirido. No se retiran otras compras,
ni estrellas, ni burbujas pendientes. La devolución no modifica ingresos de
capturas ni alimentación. La autorización anterior de borrar sin reembolso
Barrido/Área/Imán/Atracción se mantiene para esas cuatro ramas.

Guardado JSON v12 y balance v18, con v17 congelado. Las jornadas ya empezadas
conservan hasta el cierre su configuración anterior, incluidos agarre y posición
del hoyo; la siguiente jornada aplica los ajustes actuales. El archivo de compras
retiradas permite restaurarlas sin repetir devoluciones. No cambia el paquete
Android ni el almacenamiento permanente de prestigio.

## Monedas y contador

El render usa un disco achatado, canto estriado, borde y grabado central; ya no
usa la esfera con brillo de las bolas normales. La misma cara se usa en el icono
y las monedas en vuelo. Se reutilizan Paint y el trazado del grabado.

Se conservan denominaciones, importes, multiplicadores, retraso de salida,
trayectorias, límites del pool, agrupación, cobro automático y guardado C01.
El contador conserva posición, pulso e icono con cantidad, sin decoración de fondo.
No se reintroducen monedas físicas ni recogida manual.

## Posición del hoyo

Centro nuevo: **(180, 414.4)** en tablero 360 × 560: 74 % desde arriba, aproximadamente tres cuartos; el margen evita solapar el anillo con la boquilla del generador.
`hole_y_ratio` en `balance.csv` permite afinar la posición entre 20 % y 75 %
sin invadir el generador actual. No se mueve el generador ni cambia su frecuencia.
El radio de captura sigue siendo 22; AJ-005 todavía no cambia su tamaño.

Captura directa y barrida, atracción ordinaria, Agujero negro, robot, render,
anillo de cuota, monedas y expulsión/reexpulsión de estrellas comparten la
posición física de la jornada. No se calcula una posición distinta para el dibujo.
Las jornadas históricas conservan (180, 50) hasta su cierre.

**Efecto observado y comunicado:** la salida del generador está cerca del nuevo
hoyo y las bolas emitidas pueden entrar solas rápidamente. Se conserva esta
consecuencia geométrica de la posición solicitada, sin reajustar por cuenta propia
la generación, cuotas o balance para compensarla. Requiere prueba del usuario.
Las pruebas de contabilidad aíslan capturas explícitas; las pruebas de generación
y física siguen usando el balance real y comprueban emisiones aunque ya se capturen.

## Aclaración recibida: AJ-005A

El usuario vincula el crecimiento a cada cuota de alimentación completada.
Esto sustituye la propuesta previa de hacerlo depender de compras del árbol.
La fórmula aumenta el área, no el radio, un 16 % sobre el área anterior.
Se registra una sola vez por período incluso con Captura total, exceso de
alimentación, pausa o restauraciones repetidas. DEBUG conserva su aislamiento.
El límite al alcanzar los bordes se ha consultado; sigue sin resolverse.

## Entrega y límites de validación

Código compilado: `9615d08`, publicado en `build/apk-0.6.0+13` sin force push.
El commit `046ebb0` continúa en su historial.
[Pipeline correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/40111416219):
formato, análisis sin avisos, **369 pruebas**, compilación Android, nombre,
paquete `com.migdlp.incremental_hole_game` y firma v2 del binario verificados.
[APK 0.17.0+27 y SHA-256 en ZIP](https://github.com/migdlp/incremental_hole_game/actions/runs/40111416219/artifacts/12566373126).

AJ-005A ya concreta el desencadenante; queda por decidir el límite en bordes. No se ha validado el tacto ni el rendimiento
en un teléfono físico. Sigue pendiente la firma compatible con APK anteriores;
la pipeline estándar verifica esta APK, sin certificar actualización sobre ellas.
No desinstalar una aplicación anterior para resolver la firma si se necesita
conservar su progreso. Documentos históricos mantienen sus cifras originales.
