# Relevo de contexto — Feed the Hole

**Actualizado: 21/10/2026 · Último APK entregado: 0.11.0+19, revisión `571d001`.**

Este es el punto de entrada para continuar en un chat nuevo. El objetivo es mejorar la diversión y progresión de un incremental móvil con físicas, manteniendo una participación manual importante. El usuario prefiere avances concretos y documentación que sirva de fuente de verdad; no necesita un repaso de commits.

## Leer primero

1. [Estado actual](estado-actual.md): reglas implementadas, UI, debug, último APK y límites de verificación.
2. [Cambios futuros](cambios-futuros-arbol-mejoras.md): detalle de cada propuesta, dependencias y preguntas abiertas.
3. [Árbol vigente](arbol-de-mejoras.md) y [balance.csv](balance.csv): mapa actual y fuente de cifras/requisitos.

## Estado que hay que conservar

- **Agujero arriba, generador abajo y emisión hacia arriba.** Último cambio solicitado; ya entregado en APK.
- Ajuste posterior al APK de `046ebb0`: agujero en (180, 50), generador en (180, 480), sin leyenda del jardín en el tablero ni «Tu jardín te espera» en pausa. Se ha seguido la última indicación del usuario de subir el agujero y bajar el generador; comprobar las posiciones jugando en móvil.
- **15 s de producción + 5 s de recogida final**; una sola barra que cambia de verde a naranja en el mismo sitio, con segundos pequeños encima a la derecha y sin nombres de fase. Durante recogida se congelan bolas, escoba y robot. No hay temporizador en compras.
- Generación base 1,5 bolas/s; límite de 200 bolas. Mano base de una bola, capacidad mejorable hasta seis y fuerza de agarre mejorable. Escoba física desbloqueable, anchura/V y robot que empuja bolas.
- Capturar produce monedas físicas. El dinero depende de recogerlas; pendientes y reserva se pierden al acabar. La mano ocupada bloquea cobro e imán de monedas.
- Solo monedas de **1/10/50/100/500**, mismo tamaño, color propio y sin valor escrito. UI con icono, sin prefijo dólar. Resumen por denominaciones, sin antigua barra verde.
- Recompensa global actual **1 → 2/3/5/8/13**; todavía no existen tiers individuales. Doradas con probabilidad 1 % y recompensa ×10.
- Racha comprable tras Mano I por 40: ventana 1 s, quinta captura ×2, décima ×3, sin retroactividad. También cuentan capturas asistidas provisionalmente. Indicador desde la primera captura, multiplicador y barra temporal; no explicar umbrales en UI.
- Árbol de 69 nodos y 26 tipos, descubrimiento progresivo y seis colores por categoría. Primera mejora de mano cuesta 13. Área manual precede a Imán, que cuesta 300 tras Área III.
- Árbol sin título, botón visible de atrás ni botones de zoom; ficha solo al tocar, cantidades en verde y compra manteniendo el botón 1 s. Resultados → Tienda → Comenzar día. No mostrar números de día al jugador.
- **Debug:** botón DEBUG, arriba a la izquierda del árbol. Sustituye la pulsación de 3 s porque el usuario reportó que no funcionaba en móvil. Mapa completo/compras gratis/comprar todo o Vista del jugador; reinicio y monedas de prueba. Progreso temporal, sin sobrescribir la partida normal. Para ver el inicio como jugador, reiniciar prueba y activar esa vista.

Incluido en el APK de `4d815d9`: informes temporales de las últimas
20 jornadas debug con emisiones, capturas/doradas, pico de combo y monedas
generadas/cobradas/perdidas; se pueden copiar desde el panel. La petición inicial fue recorrer las mejoras futuras y añadir
las nuevas bolas como mejoras probables desde debug; después el usuario priorizó
Racha comprable, dos especiales recargables y control de escoba con dos puntos. Se ha propuesto aislar
prototipos configurables en debug, probar ambas variantes de bomba y una tabla
provisional de tiers 1/2/3/5/8. **Son propuestas pendientes de respuesta, no
reglas aprobadas.** También sigue pendiente la interacción dorada → tier máximo.

Incluidos en el APK: dos especiales comprables —Captura total y Aceleración—,
con carga automática durante producción y mejoras de recarga, potencia y duración.
Las cifras son **provisionales de prueba**, no un balance definitivo; ver estado
actual y CSV. Escoba con dos dedos: uno traslada, dos orientan; soltar uno conserva
el otro agarre. Guardado v7 / balance v13, con balances anteriores congelados para jornadas
antiguas. Verificación CI de la entrega: 262 pruebas y análisis
sin avisos, incluidos gestos de dos dedos, habilidades, guardado y pantalla pequeña.

## M01 implementado en la última entrega

Cuatro paredes con rebote base ×0,40 y mejora permanente I/II/III ×1,10/1,35/1,60; velocidad máxima 380 u/s. Línea elástica y ondas al impactar, sin cambiar monedas ni congelación final. Compras persistentes, aplicadas desde la jornada siguiente; jornadas v8 conservadas. Para probar: Tienda → DEBUG → comprar Paredes rebotadoras con requisitos → Comenzar día de prueba.

Multiplicadores, límite y costes 40/100/220 con Mano I son **provisionales**, pendientes de validación de balance. [Implementación y pruebas](m01-paredes-rebotadoras.md). Sigue pendiente la compatibilidad de firma con APK anteriores descrita en [G01](g01-feed-the-hole.md); la pipeline estándar verifica la firma de esta APK, sin acreditar actualización sobre la anterior. No desinstalar para resolverlo si se quiere conservar su progreso.

## M02 · prototipo entregado

APK 0.8.0+16 entregado por la pipeline habitual. Bate físico aparte de la escoba, tres niveles de
potencia activa y control de uno/dos dedos compartido. Velocidad relativa y giro,
rebote pasivo constante, contacto persistente sin bonificaciones repetidas y cap
380 u/s. Monedas y activación de especiales conservadas. Compra y pose persistentes,
recogida congelada y DEBUG aislado. Nueva preferencia Vibración; destellos y sonido
respetan ajustes, con respuesta agrupada. JSON v7, balance v10 con v9 congelado.
Precios 60/120/240, Mano I y potencia ×1/×1,35/×1,70 son **provisionales**.
[Estado M02 y guía de prueba](m02-bate-beisbol.md). No implementar otras piezas
ni nuevas bolas como parte de esta tarea.

## M03 · Generador lanzador

Prototipo 0.11.0+19: nuevo emisor de Producción, independiente del principal,
frecuencia propia y potencia fija. Un/dos dedos, disparo agarrado, franja inferior
completa y línea roja. Presión vectorial de contactos, tres esfuerzos máximos
insuficientes, desplazamiento lento sin giro/recoil; obstrucciones consumen
intento sin bolas superpuestas ni ráfagas. Pose entre días/reinicios, reloj/RNG
guardados y DEBUG aislado. JSON v7 / balance v13 con v12 congelado, 69 nodos y
26 tipos. Generador II, costes, 280 u/s, intervalos y resistencia son **provisionales**.
No añadir otros cañones, bolas ni mejoras de fuerza. [Guía y valores](m03-generador-lanzador.md).

## E02 · Agujero negro

Prototipo 0.10.0+18: comprobaciones independientes 5 % cada 3 s, varios objetos
sin sensores, 3–6 pulsaciones y succión ampliada sobre bolas libres. Captura,
monedas y herramientas conservadas. Duración hasta 10 s, otra activación
restablece tiempo sin acumular potencia. **Usuario decidió retirar también los
objetos sin romper al terminar producción**, como Gravedad. Pausa/restore sin
repetir activación, JSON v7 / balance v12 con v11 congelado. DEBUG fuerza 1–3
objetos temporales. Intervalo/radio/fuerza/curva/deriva/audio/estética siguen
provisionales. [Guía, parámetros y pruebas](e02-agujero-negro.md).

## E01 · Gravedad entregada

APK 0.9.0+17 generado por la pipeline habitual. 5 % por jornada compatible, máximo un objeto,
3–6 pulsaciones y hasta 10 s de producción inclinando el móvil. La detección Android
exige una lectura real (gravedad, o acelerómetro filtrado); sin sensores no
aparece en juego normal. Bolas y escoba/bate libres reciben fuerza gradual;
agarres y monedas no. Se conservan estado y tiempo al pausar/restaurar, sin nuevo
sorteo ni activación; cierre limpia todo. RNG separado del emisor de bolas.
JSON v7 / balance v11 con v10 congelado. DEBUG → Gravedad permite forzar y simular
sin alterar guardado real. Apariencia y física provisionales; discutir daño por
bolas, otros eventos simultáneos y balance futuro antes de cerrar esas reglas.
[Implementación y protocolo de prueba](e01-gravedad.md).

## Próximas mejoras y decisiones abiertas

| Tema | Qué se quiere | Qué falta antes de programar |
| --- | --- | --- |
| CF-16 · Tiers individuales | Valor propio por bola y reemplazo de Valor I–V | Número, valores, colores, probabilidades, nueva rama y migración de compras |
| CF-17 · Potenciadora | Elevar tiers por contacto estratégico | Depende de CF-16; cargas, consumo, contactos, objetivos y límites |
| CF-18 · Combos | Revisar la implementación y posibles mejoras | Probar ventana/multiplicadores; confirmar capturas asistidas y posibles ampliaciones del árbol; desbloqueo por compra ya implementado |
| CF-19 · Tres habilidades aleatorias | Elegir una tras noches/hitos, además del árbol | Frecuencia, catálogo, rarezas, duración, acumulación y guardado |
| CF-20 · Pinball | Flippers manuales y bumpers físicos | Controles móviles, colocación, fuerza, tamaño y límites de contacto |
| CF-21 · Fábrica configurable | Barreras, deflectores, aros, núcleos, aspas, cañones o ráfagas | Elegir piezas y concretar controles, anclajes, capacidades, requisitos y economía |
| CF-22 · Duplicadora | Crear una copia al contactar con otra bola | Objetivos, estados copiados, cargas/cadenas, recompensa y límite de 200 |
| CF-23 · Bomba o impulso | Cuenta atrás roja 3, 2, 1 tras colisión | **Elegir** destrucción o impulso; radio, efectos, cadenas y guardado |
| CF-24 · Controles | Lanzamiento mejorable, abanico, tirachinas o escoba cargada | Diferencia respecto al gesto actual, gestos, límites y comodidad |

**Reglas futuras de doradas que sí están acordadas:** ×10 del valor de su tier; el tier máximo no puede ser dorado ni generarse dorado. **No se ha decidido** qué sucede cuando una bola ya dorada intenta evolucionar al tier máximo. Discutirlo; no escoger automáticamente entre bloquear la evolución, quitar el dorado u otra solución.

La duplicadora y la bomba/impulso siguen siendo ideas para planificar. El usuario pidió inicialmente no implementar esas bolas todavía; la petición posterior de implementar lo posible no cerró sus reglas pendientes. No presentarlas como hechas ni inventar reglas definitivas.

Los combos ya existen: su pendiente es revisar balance y evolución, no implementarlos de nuevo. Los cambios de UI/monedas/agarre/timers/debug y las posiciones del tablero ya están hechos: no volver a listarlos como pendientes.

## Qué conviene resolver a continuación

Sugerencia, no nueva decisión del usuario: comprobar el último APK en móvil y observar el ritmo con el agujero arriba; después concretar CF-16 antes de CF-17. Registrar capturas, monedas cobradas/perdidas y días entre compras antes de reajustar economía. Los mecanismos y habilidades necesitan diseño separado para no complicar los controles.

No se ha registrado aceptación física del último APK. El usuario reportó antes que el «modo dibujo» no funcionaba, tratado aquí como debug del árbol. Las pruebas automáticas pasan, pero no consta reproducción ni confirmación manual de que el último APK resuelva ese reporte.

## Última entrega y comprobaciones

[Descargar APK 0.11.0+19 (ZIP con APK y SHA-256)](https://github.com/migdlp/incremental_hole_game/actions/runs/39645255701/artifacts/12366918039). Descomprimir: contiene `feed-the-hole-debug.apk`. Retención limitada de GitHub; regenerar si caduca.

262 pruebas, formato, análisis, compilación Android y firma correctos en la [pipeline de entrega](https://github.com/migdlp/incremental_hole_game/actions/runs/39645255701). Sin prueba en teléfono físico. El último código entregado está en `build/apk-0.6.0+13`; no asumir que `main` lo contiene. La pipeline Android es manual; el entorno local usado no tiene Android SDK.

## Acceso a GitHub desde Codex Cloud (20/10/2026)

El commit `046ebb06aa28b4662f5ca1d8635f4bde0d9a4101` se publicó sin force push
en `build/apk-0.6.0+13`. Los primeros intentos desde el sandbox devolvían
`Failed to connect to proxy port 8080` y `gh auth status` indicaba token inválido.
La solución comprobada fue ejecutar los comandos de red con
`sandbox_permissions: "with_additional_permissions"` y
`additional_permissions: {"network": {"enabled": true}}` en `exec_command`.
Con esa configuración funcionaron `git ls-remote`, `git push`, `gh auth status`
y el lanzamiento del workflow manual. No hubo que cambiar el proxy, las
credenciales ni la política del environment. No interpretar esos errores desde
un comando sin acceso de red como prueba de credenciales caducadas.

Para el APK, usar `.github/workflows/flutter-manual.yml` sobre la rama publicada;
GitHub Actions instala Flutter y Android SDK. Flutter encontrado en `/tmp/flutter`
no estaba en el PATH de esta tarea y no había Android SDK local. No instalar un
SDK completo solo para suplir la pipeline. Conservar los commits y comprobar el
SHA remoto antes de publicar; no usar reset, clean ni force push para reparar
conectividad.

La [pipeline 39436411074](https://github.com/migdlp/incremental_hole_game/actions/runs/39436411074)
terminó correctamente sobre ese SHA: formato, análisis, pruebas, APK y firma v2.
[Descargar el APK y SHA-256 (ZIP)](https://github.com/migdlp/incremental_hole_game/actions/runs/39436411074/artifacts/12272966859).
La reparación de conectividad no necesitó cambios en el código ni en las
credenciales; `046ebb0` está publicado.

## Cómo trabajar al retomar

- Distinguir siempre implementación vigente, dirección de diseño y reglas pendientes. Leer este documento no es una orden de implementar todo el brainstorm.
- Atender la siguiente petición concreta del usuario. Ante una decisión expresamente abierta, proponer reglas y discutirla antes de fijarla.
- Usar `balance.csv` para cifras/requisitos. Respetar compras y guardados; no borrar progreso para adaptar la economía.
- Mantener física y participación manual: las máquinas ayudan, no convierten el juego en totalmente pasivo. El dinero sigue pasando por captura y recogida.
- Al terminar una tarea, quitarla de cambios futuros y actualizar estado/contexto. No acumular listas de cambios ya hechos entre los pendientes.
- Documentos históricos pueden contener tiempos, versiones y reglas reemplazados. Las referencias vigentes son estado actual, cambios futuros, CSV y código.

## Mensaje para pegar en un chat nuevo

```text
Continúa el proyecto Feed the Hole del repo
migdlp/incremental_hole_game. Lee primero docs/relevo-contexto.md,
docs/estado-actual.md y docs/cambios-futuros-arbol-mejoras.md.
Me interesa especialmente el estado jugable y las mejoras futuras,
no reconstruir el historial de commits. El último APK es 0.11.0+19:
agujero arriba, generador abajo, ciclo 15+5, generador lanzador, eventos Agujero negro y Gravedad por inclinación, paredes rebotadoras, bate de tres potencias, racha comprable, especiales, escoba de dos dedos y debug por botón.
No des por implementados los tiers ni las bolas especiales, ni cierres
las decisiones abiertas sin discutirlas. Después continúa con mi
siguiente petición concreta.
```

## Última simplificación de interfaz

El saldo total y la pausa negra están dentro del tablero. Se eliminan números
de día, instrucciones de juego y la leyenda del generador. La interfaz usa
Tienda y Comenzar día. Feedback visual en ajustes normales empieza desactivado,
se guarda y solo oculta/muestra las marcas de pulsación/área/agarre. La pausa
muestra Juego pausado con icono de pausa, ajustes y Continuar. Ver estado actual.

## G01 — Feed the Hole

La marca comercial pasa a Feed the Hole en el build 0.6.0+14. No renombrar
`GardenApp`, `GardenGame`, el paquete Dart, el repositorio ni el identificador
Android por motivos cosméticos. Se mantienen `progress.json`, su copia, el
guardado v7 y todas las migraciones. Iconos, gráficos y reglas se conservan.
La actualización sobre APK anteriores requiere además conservar la firma;
verificarla contra la entrega anterior antes de afirmar compatibilidad.

**Resultado G01:** código de marca publicado en `fd3d8f2`; el APK compila y su
nombre/paquete son correctos. La comparación con la última APK detectó firmas
diferentes y detuvo la publicación. Falta localizar y reutilizar el keystore
original para cumplir la actualización conservando datos.
[Diagnóstico y evidencia de G01](g01-feed-the-hole.md).

**Entrega posterior G01 (21/10/2026):** APK Feed the Hole `0.6.0+14` generada
con la pipeline habitual sobre `4f100fc`, a petición del usuario.
[Descarga](https://github.com/migdlp/incremental_hole_game/actions/runs/39557666293/artifacts/12326019753).
Pasaron formato, análisis, 154 pruebas, compilación y validación del nombre,
paquete y firma del binario. Se omitió la comparación de actualización con la
APK anterior: el conflicto de firma previamente confirmado sigue pendiente.
No presentar esta entrega como actualización que conserve el progreso instalado.

## M01 — paredes rebotadoras

Implementadas en 0.7.0+15: rebote base ×0,40 y rama Paredes rebotadoras I–III
(×1,10/×1,35/×1,60), con límite configurable inicial de 380 u/s. Precios
40/100/220 y Mano I son provisionales de prueba, no aprobados. Efectos elásticos
y ondas independientes de la física; monedas y recogida conservan sus reglas.
Guardado v7, balance v9 y balance v8 congelado para jornadas anteriores.
[Detalle y pruebas M01](m01-paredes-rebotadoras.md). No dar por implementadas
las otras piezas de pinball ni las nuevas bolas especiales.
