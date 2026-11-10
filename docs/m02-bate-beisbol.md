# M02 — Bate de béisbol

Prototipo jugable de **0.8.0+16**, pendiente de calibración y prueba en Android
físico. No añade otras herramientas de pinball ni nuevas bolas especiales.

## Compra y control

Bate de béisbol I desbloquea un objeto físico independiente de la escoba; II y III
solo aumentan su potencia activa. Se compra entre jornadas y la compra persiste.
Para probarlo sin gastar progreso real: **Tienda → DEBUG → Bate de béisbol I →
mantener la compra un segundo → Comenzar día**. DEBUG adquiere también requisitos.
Después de una jornada de prueba se pueden comprar II y III; comprar todo permite
probar directamente el máximo. Reiniciar la prueba permite comparar desde I.

Un dedo sobre el bate lo agarra y traslada sin cambiar su orientación. Un segundo
dedo sobre otro punto del bate permite trasladar y girar. Soltar cualquiera de
los dos conserva el agarre restante sin saltos; soltar ambos deja el bate en su
posición y orientación. Los dos contactos no estiran la herramienta. La mano y
la escoba siguen disponibles tocando los objetos correspondientes; no se añade
un modo obligatorio ni botones para golpear.

El control rígido se comparte con la escoba mediante `TwoPointGrip`. Se mantienen
los nombres internos de las entradas de segundo puntero para no duplicar controles.
El bate se mueve dentro del tablero, con límites calculados según su orientación
para acercarse a las cuatro paredes y con el mismo control en los tres niveles.
Durante recogida final queda congelado y se sueltan ambos agarres. Pausa,
cancelación y segundo plano cancelan también los agarres.

## Física

Se usa una cápsula fija: segmento de 72 u y radio de 6 u en este prototipo. La
apariencia distingue empuñadura, cinta y cuerpo de madera; no hay mejoras de tamaño.
El movimiento se integra en los subpasos físicos existentes de hasta 1/240 s.

La velocidad superficial en el contacto es la traslación real del bate más
`ω × brazo`, por lo que los extremos aportan mayor velocidad durante el giro.
Solo hay impulso cuando existe aproximación en la normal. La tangente no recibe
una bonificación artificial. En un impacto nuevo:

```text
aproximación = max(0, velocidad_superficie_normal − velocidad_bola_normal)
impulso = (1 + restitución_pasiva) × aproximación
        + max(0, velocidad_superficie_normal) × ganancia_manual × potencia
```

Una bola contra el bate quieto rebota con restitución 0,40, idéntica en I–III.
La velocidad del bate tiene mayor peso en el impulso adicional que la velocidad
de la propia bola. Un contacto persistente solo resuelve penetración y velocidad
relativa, sin repetir ni el rebote aumentado ni la bonificación manual. La bola
debe separarse de la cápsula, con una pequeña tolerancia de 0,75 u, para armar un
nuevo impacto. Un contacto quieto sin impacto no consume la bonificación: empezar
a mover el bate contra esa bola permite su primer golpe. No hay un enfriamiento global que impida golpear varias bolas.

Los resultados se limitan a `ball_speed_limit`, inicialmente **380 u/s**; se
combinan con la restitución comprada de las paredes. Se mantienen las colisiones
bola–bola y capturas por el hoyo. Todas las bolas existentes usan esta misma
respuesta (incluidas doradas), sin modificar su recompensa ni activar especiales
al tocar el bate. Actualmente no hay nuevos tipos de bola especial: M02 no inventa
reglas para ellos. Las habilidades comprables existentes conservan sus cargas y
activaciones. Las monedas no reciben fuerzas del bate; agarrarlo tampoco activa
el barrido ni el imán de monedas.

## Balance provisional

La fuente editable es [balance.csv](balance.csv). **No son valores aprobados:**

| Parámetro | Valor inicial de prueba |
| --- | --- |
| Precios I / II / III | 60 / 120 / 240 |
| Requisito de la rama | Mano I |
| Potencia activa I / II / III | ×1 / ×1,35 / ×1,70 |
| Ganancia manual | 1,10 |
| Restitución pasiva | 0,40, constante |
| Semilongitud / radio | 36 / 6 u, constantes |
| Velocidad máxima del bate / giro | 900 u/s / 3 rad/s, constantes |
| Límite final de bolas | 380 u/s, compartido con M01 |

La potencia multiplica exclusivamente la parte adicional causada por el
movimiento del bate. El nivel III es el máximo; el catálogo tiene 65 nodos y 24
tipos. Validar precios, dependencia, fuerza, tacto y sinergia con paredes jugando
antes de fijarlos. No variar longitud, rapidez de control ni cantidad de bolas
para diferenciar niveles.

## Feedback

Un impacto nuevo significativo produce un destello circular breve en el punto
de contacto, proporcional a su fuerza. Respeta **Feedback visual**, desactivado
por defecto. Hasta 24 destellos simultáneos, con caducidad de 0,16 s; no se guardan.

Se utiliza el clic del sistema como sonido de impacto de este prototipo,
sincronizado con el golpe y respetando **Sonidos del sistema**. Vibración breve
ligera/media según intensidad, controlada con la nueva opción **Vibración**
(activada inicialmente y persistente). Los impactos de cada frame se agrupan y
se limita la respuesta a una cada 120 ms de simulación. Los golpes silenciados o
suprimidos durante pausa no se reproducen después. Desactivar feedback no altera
la física, las capturas ni el valor de las bolas.

## Guardado y compatibilidad

JSON permanece en **v7**; balance vigente **v10**. Se congela v9 en
`balance_v9.dart`, sin cambiar las jornadas guardadas de balances 1–9. El siguiente
día usa el balance vigente. No se cambia identificador Android, archivos de
partida, saldo, compras existentes ni migraciones.

`levels.bat` guarda I–III. La jornada v10 guarda `batPosition` y `batAngle`, validados
antes de aplicar una restauración. Se reabre pausada, con esa pose y sin dedos
activos. El inicio de una jornada nueva coloca las herramientas en sus posiciones
iniciales, igual que la escoba. La preferencia booleana opcional `haptics` empieza
en `true` cuando falta en guardados antiguos. DEBUG sigue aislado del guardado real.

## Verificación y límites

Las pruebas cubren agarre, traslado, giro, relevo de ambos dedos y eventos táctiles
reales; golpe lento/rápido, potencia I–III, rebote pasivo, giro en extremos, impactos
simultáneos, contactos persistentes, separación y nuevo golpe, velocidad límite,
sinergia con paredes y transmisión posterior entre bolas. También monedas,
convivencia con mano/escoba, especiales sin activación directa, congelación final,
compras y pose persistentes, balance v9, entradas de pose inválidas, preferencias,
DEBUG, renderizado y estrés con 200 bolas.

Las pruebas automáticas y la imagen de revisión no certifican comodidad, audio,
háptica ni rendimiento en un teléfono. La firma de las APK anteriores sigue
pendiente según [G01](g01-feed-the-hole.md): una compilación válida no acredita
poder actualizar cualquier APK anterior conservando sus datos.

Verificación local de esta implementación: **181 pruebas** superadas; las 19 de
M02 y las cinco de control de escoba pasan tras la revisión de bordes/contacto. `flutter analyze` sin
avisos, formato correcto y revisión de la imagen del tablero.

## Entrega Android verificada

APK **0.8.0+16**, fuente `e9e9620`, publicada en `build/apk-0.6.0+13`.
[Pipeline correcta](https://github.com/migdlp/incremental_hole_game/actions/runs/39580911892): **183 pruebas**, formato, análisis, compilación
Android y firma correctos. [Descargar APK y SHA-256](https://github.com/migdlp/incremental_hole_game/actions/runs/39580911892/artifacts/12336244410).
El ZIP contiene `feed-the-hole-debug.apk`. Sin prueba en Android físico y sin
acreditar compatibilidad de firma con APK anteriores; no desinstalar la anterior
para resolver un conflicto si se quiere conservar su progreso.
