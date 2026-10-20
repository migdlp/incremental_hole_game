# Relevo de contexto — Incremental Hole Game / Jardín Mecánico

**Actualizado: 20/10/2026 · Último APK entregado: 0.6.0+13.**

Este es el punto de entrada para continuar en un chat nuevo. El objetivo es mejorar la diversión y progresión de un incremental móvil con físicas, manteniendo una participación manual importante. El usuario prefiere avances concretos y documentación que sirva de fuente de verdad; no necesita un repaso de commits.

## Leer primero

1. [Estado actual](estado-actual.md): reglas implementadas, UI, debug, último APK y límites de verificación.
2. [Cambios futuros](cambios-futuros-arbol-mejoras.md): detalle de cada propuesta, dependencias y preguntas abiertas.
3. [Árbol vigente](arbol-de-mejoras.md) y [balance.csv](balance.csv): mapa actual y fuente de cifras/requisitos.

## Estado que hay que conservar

- **Agujero arriba, generador abajo y emisión hacia arriba.** Último cambio solicitado; ya entregado en APK.
- **15 s de producción + 5 s de recogida final**; barras independientes. Durante recogida se congelan bolas, escoba y robot. No hay temporizador en compras.
- Generación base 1,5 bolas/s; límite de 200 bolas. Mano base de una bola, capacidad mejorable hasta seis y fuerza de agarre mejorable. Escoba física desbloqueable, anchura/V y robot que empuja bolas.
- Capturar produce monedas físicas. El dinero depende de recogerlas; pendientes y reserva se pierden al acabar. La mano ocupada bloquea cobro e imán de monedas.
- Solo monedas de **1/10/50/100/500**, mismo tamaño, color propio y sin valor escrito. UI con icono, sin prefijo dólar. Resumen por denominaciones, sin antigua barra verde.
- Recompensa global actual **1 → 2/3/5/8/13**; todavía no existen tiers individuales. Doradas con probabilidad 1 % y recompensa ×10.
- Racha comprable tras Mano I por 40 (código posterior al último APK): ventana 1 s, quinta captura ×2, décima ×3, sin retroactividad. También cuentan capturas asistidas provisionalmente. Indicador desde la primera captura, multiplicador y barra temporal; no explicar umbrales en UI.
- Árbol de 59 nodos y 22 tipos, descubrimiento progresivo y seis colores por categoría. Primera mejora de mano cuesta 13. Área manual precede a Imán, que cuesta 300 tras Área III.
- Árbol sin título, botón visible de atrás ni botones de zoom; ficha solo al tocar, cantidades en verde y compra manteniendo el botón 1 s. Resultados → árbol → comenzar día.
- **Debug:** mantener saldo del árbol 3 s. Mapa completo/compras gratis/comprar todo o Vista del jugador; reinicio y monedas de prueba. Progreso temporal, sin sobrescribir la partida normal. Para ver el inicio como jugador, reiniciar prueba y activar esa vista.

Avance de código posterior al APK 0.6.0+13: informes temporales de las últimas
20 jornadas debug con emisiones, capturas/doradas, pico de combo y monedas
generadas/cobradas/perdidas; se pueden copiar desde el panel. No hay nuevo APK
de este avance. La petición inicial fue recorrer las mejoras futuras y añadir
las nuevas bolas como mejoras probables desde debug; después el usuario priorizó
Racha comprable, dos especiales recargables y control de escoba con dos puntos. Se ha propuesto aislar
prototipos configurables en debug, probar ambas variantes de bomba y una tabla
provisional de tiers 1/2/3/5/8. **Son propuestas pendientes de respuesta, no
reglas aprobadas.** También sigue pendiente la interacción dorada → tier máximo.

Código posterior al APK: dos especiales comprables —Captura total y Aceleración—,
con carga automática durante producción y mejoras de recarga, potencia y duración.
Las cifras son **provisionales de prueba**, no un balance definitivo; ver estado
actual y CSV. Escoba con dos dedos: uno traslada, dos orientan; soltar uno conserva
el otro agarre. Guardado v7 / balance v8, con balance v7 congelado para jornadas
antiguas. No hay nuevo APK de estos cambios aún. Verificación local: 151 pruebas y análisis
sin avisos, incluidos gestos de dos dedos, habilidades, guardado y pantalla pequeña.

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

[Descargar APK 0.6.0+13 (ZIP con APK y SHA-256)](https://github.com/migdlp/incremental_hole_game/actions/runs/39403619439/artifacts/12256028572). Descomprimir e instalar `jardin-mecanico-debug.apk`. Retención limitada de GitHub; regenerar si caduca.

135 pruebas, formato, análisis, compilación Android y firma correctos en la [pipeline de entrega](https://github.com/migdlp/incremental_hole_game/actions/runs/39403619439). Sin prueba en teléfono físico. El último código entregado está en `build/apk-0.6.0+13`; no asumir que `main` lo contiene. La pipeline Android es manual; el entorno local usado no tiene Android SDK.

## Cómo trabajar al retomar

- Distinguir siempre implementación vigente, dirección de diseño y reglas pendientes. Leer este documento no es una orden de implementar todo el brainstorm.
- Atender la siguiente petición concreta del usuario. Ante una decisión expresamente abierta, proponer reglas y discutirla antes de fijarla.
- Usar `balance.csv` para cifras/requisitos. Respetar compras y guardados; no borrar progreso para adaptar la economía.
- Mantener física y participación manual: las máquinas ayudan, no convierten el juego en totalmente pasivo. El dinero sigue pasando por captura y recogida.
- Al terminar una tarea, quitarla de cambios futuros y actualizar estado/contexto. No acumular listas de cambios ya hechos entre los pendientes.
- Documentos históricos pueden contener tiempos, versiones y reglas reemplazados. Las referencias vigentes son estado actual, cambios futuros, CSV y código.

## Mensaje para pegar en un chat nuevo

```text
Continúa el proyecto Incremental Hole Game / Jardín Mecánico del repo
migdlp/incremental_hole_game. Lee primero docs/relevo-contexto.md,
docs/estado-actual.md y docs/cambios-futuros-arbol-mejoras.md.
Me interesa especialmente el estado jugable y las mejoras futuras,
no reconstruir el historial de commits. El último APK es 0.6.0+13:
agujero arriba, generador abajo, ciclo 15+5, combos y debug del árbol.
No des por implementados los tiers ni las bolas especiales, ni cierres
las decisiones abiertas sin discutirlas. Después continúa con mi
siguiente petición concreta.
```
