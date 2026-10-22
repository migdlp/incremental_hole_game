# Ajustes de la versión actual — Feed the Hole

Se continúa desde 0.15.0+23 y sus sistemas P01/C01/S03. No se recuperan versiones
antiguas ni se añaden mecánicas de otros documentos.

| ID | Estado | Resultado |
| --- | --- | --- |
| AJ-001 | Implementado | Fuerza alta base, sin rama ni niveles; capacidad conservada |
| AJ-002 | Implementado | Monedas acuñadas con canto, cara plana y grabado |
| AJ-003 | Implementado | Icono y saldo sobre tablero sin recuadro |
| AJ-004 | Implementado | Centro aproximadamente al 75 % de altura útil del tablero |
| AJ-005 | Pendiente de aclaración | Falta identificar qué compras activan el crecimiento |

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

## Aclaración requerida para AJ-005

El catálogo actual no contiene mejoras de nivel o barrera del agujero. Se ha
preguntado qué compras deben hacerlo crecer: una nueva mejora de tamaño, cuotas
superadas u otra compra existente. Vincularlo a Valor, Duración o cuotas sin esa
respuesta cerraría una decisión de diseño que no está definida.

Una vez identificado el desencadenante, deberán probarse crecimiento visual y
radio real, límites y separación respecto al generador (actualmente solo quedan
65,6 unidades entre centros). No se introducen costes, requisitos ni porcentajes
finales mientras falte esa decisión.

## Entrega y límites de validación

Código compilado: `c61e070`, publicado en `build/apk-0.6.0+13` sin force push.
El commit `046ebb0` continúa en su historial.
[Pipeline correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/39737430503):
formato, análisis sin avisos, **359 pruebas**, compilación Android, nombre,
paquete `com.migdlp.incremental_hole_game` y firma v2 del binario verificados.
[APK 0.16.0+24 y SHA-256 en ZIP](https://github.com/migdlp/incremental_hole_game/actions/runs/39737430503/artifacts/12408450523).

AJ-005 sigue pendiente de respuesta. No se ha validado el tacto ni el rendimiento
en un teléfono físico. Sigue pendiente la firma compatible con APK anteriores;
la pipeline estándar verifica esta APK, sin certificar actualización sobre ellas.
No desinstalar una aplicación anterior para resolver la firma si se necesita
conservar su progreso. Documentos históricos mantienen sus cifras originales.
