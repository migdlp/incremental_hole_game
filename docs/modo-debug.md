# Modo de depuración

Disponible en el código de la revisión 0.6.0+11. Es una sesión de pruebas temporal para inspeccionar el árbol y probar mejoras sin alterar el progreso guardado.

## Acceso desde el móvil

1. Abre la tienda entre jornadas.
2. Pulsa el botón **DEBUG**, arriba a la izquierda.
3. Se activa la prueba y aparece el panel «Depuración». Mientras esté activa, el botón **DEBUG** del árbol vuelve a abrir este panel.

El botón está siempre visible en el árbol. El saldo de monedas ya no activa el modo.

## Ver el árbol completo o la vista del jugador

- **Vista del jugador desactivada:** muestra los 65 nodos y sus conexiones. Al entrar o volver a esta vista, el mapa se encuadra completo; puedes acercarte y arrastrarlo para inspeccionar las ramas. Cualquier nodo pendiente se puede comprar gratis desde su ficha, manteniendo el botón un segundo. Se adquieren también sus niveles anteriores y requisitos, incluidos los cruces entre ramas, para que la configuración sea válida al jugar.
- **Vista del jugador activada:** usa exactamente el descubrimiento normal: nodos comprados y siguientes nodos accesibles. Conserva precios, requisitos y colores/estados de disponibilidad normales. Las compras realizadas en esta vista descuentan el saldo de prueba, como en una partida normal.

Las dos vistas comparten las mismas compras de prueba. Si compras todo, la vista del jugador mostrará todo porque ya lo tienes adquirido. Para comprobar el inicio, pulsa «Reiniciar prueba desde cero» y activa «Vista del jugador».

Cambiar de vista no compra ni elimina mejoras. Si una ficha seleccionada deja de ser visible se cierra; cualquier compra mantenida en curso se cancela.

## Herramientas del panel

- **Comprar todo:** adquiere gratuitamente todos los niveles de todas las ramas.
- **Añadir 1000 monedas de prueba:** permite inspeccionar qué nodos estarían disponibles para un jugador con saldo suficiente.
- **Reiniciar prueba desde cero:** vacía las mejoras y el saldo de prueba; vuelve al día 1. No borra la partida normal.
- **Volver al árbol:** cierra el panel conservando la prueba.
- **Salir de depuración:** descarta la prueba y recupera el punto de partida normal.

### Informes de jornadas de prueba (código posterior al APK 0.6.0+13)

Tras terminar una jornada, el panel muestra bolas emitidas y capturadas,
capturas doradas, multiplicador máximo de combo y monedas generadas, cobradas
y perdidas. «Copiar jornadas de prueba» copia los últimos 20 informes para
comparar configuraciones. «Emitidas» cuenta solo las emisiones que han podido
crear una bola, sin contar intentos bloqueados por espacio o por el límite.

Los informes solo existen en memoria durante debug. Reiniciar la prueba o salir
los elimina; una partida normal no registra informes. No alteran el guardado,
las recompensas ni los umbrales del combo. Son observaciones para probar el
balance, no una aceptación del manejo en Android físico.

Puedes pulsar «Comenzar día» y jugar con las mejoras de prueba. Durante la jornada aparece **DEBUG · prueba temporal**, con el botón «Salir de debug». Las modificaciones de mejoras se realizan entre jornadas para conservar la configuración activa del día.

## Progreso y guardado

Entrar toma una instantánea del progreso normal y solicita su guardado. Las compras, monedas y jornadas de depuración permanecen en memoria y no se escriben en el guardado ni en su copia. Al salir se restaura la instantánea; al cerrar y reabrir la aplicación se carga la partida normal, sin activar depuración.

La prueba comienza con tu progreso actual. Reiniciar la prueba o comprar gratis no afecta a ese punto de partida. Este modo no añade campos al esquema JSON ni concede compras gratuitas fuera de la sesión de depuración.

## Probar racha, especiales y nueva escoba

En el árbol completo, comprar gratis Racha, Captura total o Aceleración adquiere
también sus requisitos. Sus ramas permiten probar recargas, potencia ×3 y duración.
«Comprar todo» incluye estas mejoras. El día empieza sin carga: observar los
botones «Captura» y «Turbo», esperar a «Lista» y pulsar durante producción. Las
monedas de Captura total se recogen normalmente. Racha muestra contador y barra.

Para la escoba, agarrar un extremo y después el otro con un segundo dedo. Mover
ambos para trasladarla y girarla. Soltar cualquiera mantiene el otro agarre; con
un solo dedo se traslada sin giro automático. Probar también escoba en V, pausa,
recogida final y salida de debug. Las nuevas reglas todavía requieren validación
en un móvil físico.

## Probar M02 · Bate de béisbol

En vista completa, seleccionar Bate de béisbol I y mantener su compra un segundo.
Se adquieren sus requisitos y aparece en la jornada de prueba como objeto aparte
de la escoba. Un dedo traslada y dos giran. Tras terminar la jornada, comprar II
o III para comparar fuerza; reiniciar prueba permite volver a I. Comprar todo
activa III y las paredes máximas. Salir descarta las compras y jornadas de prueba.
[Parámetros provisionales y casos de prueba](m02-bate-beisbol.md).

## Probar E01 · Gravedad

En Tienda → DEBUG, desplegar **Gravedad**. Elegir Sensor real y activar **Forzar
Gravedad en la próxima jornada** para probar el teléfono. Sin sensor compatible,
elegir una inclinación simulada habilita esa prueba solo en DEBUG. Al comenzar
aparece un objeto: romperlo con 3–6 toques para activar el efecto. Comprar escoba
y bate permite probar también sus movimientos libres y sus agarres.
El forzado se consume al comenzar; salir o reiniciar descarta la configuración.
[Casos de prueba, guardado y parámetros provisionales](e01-gravedad.md).

## Probar E02 · Agujero negro

En Tienda → DEBUG → **Agujero negro**, elegir 1–3 objetos al comenzar la próxima
prueba, volver a la tienda y comenzar día de prueba. No requiere sensores.
Romperlos con 3–6 toques; otra activación reinicia 10 s sin sumar fuerza.
Comprobar pausa y desaparición total al empezar recogida. Salir de depuración
restaura la partida real. [Guía detallada y balance provisional](e02-agujero-negro.md).
