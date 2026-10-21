# E02 — Habilidad especial: Agujero negro

Prototipo **0.10.0+18**, con parámetros provisionales pendientes de calibración
jugando en Android. Evento sin compra ni requisito de sensores; no añade tipos
de bola, herramientas ni mejoras al árbol.

## Aparición y activación

Durante producción se realiza un sorteo independiente del **5 % cada 3 s**.
El primer sorteo llega tras el intervalo; no se sortea por fotograma ni justo en
el límite con recogida. Pueden aparecer varios objetos, incluso coexistir.
Cada uno deriva lentamente y requiere **3–6 toques completos**, elegidos al nacer.
Arrastrar, cancelar o apoyar un segundo dedo no añade pulsaciones. Si se solapan,
se atiende primero al que se dibuja encima. No recoge monedas bajo el objeto.

Los toques muestran grietas y destellos progresivos. El último elimina ese objeto
y activa inmediatamente un único efecto, con anuncio «HABILIDAD ESPECIAL:
AGUJERO NEGRO», flash de un segundo y clic del sistema sujeto a Sonido. El clic
es un recurso provisional, no el diseño sonoro final. Restaurar, reanudar o quitar
silencio no reproduce activaciones antiguas. Los destellos de daño son propios
del evento, independientes de los círculos opcionales de pulsación.

## Atracción

Amplía el alcance de atracción del hoyo, sin aumentar tamaño físico ni radio de
captura (**22 u**). La aceleración aumenta gradualmente al acercarse al centro:
`420 × (1 − distancia / 180)²`, dentro de 180 u. En el alcance normal se conserva
como mínimo la atracción existente, sin sumarla dos veces. No asigna velocidades
nuevas: conserva inercia, colisiones, rebotes y límite técnico **380 u/s**.

Solo afecta a bolas libres normales y doradas; la misma ruta física sirve para
futuros tipos de bola, sin inventar habilidades nuevas. Las agarradas permanecen
bajo control. No ejerce fuerza sobre monedas, escoba, bate ni otras herramientas.
No modifica valor, emisión, premios ni captura. Gravedad conserva su propio estado
y fuerza: E02 no lo reinicia ni altera su sensor. Si coinciden anuncios se muestran
ambos; el flash no suma intensidad. No se definen aquí reglas para futuros eventos.

Tres ondas de succión suaves se dibujan **antes de bolas y herramientas**. El
renderizado no avanza la física. Los destellos simultáneos están limitados a 24 y
caducan a los 0,2 s; no se limita el número de objetos mediante un tope de diseño.
El tiempo de producción y el intervalo acotan sus apariciones.

## Tiempo, limpieza y guardado

La duración es **10 s como máximo**. Otra activación restablece 10 s restantes,
sin acumular potencia ni radio. Se corta al terminar producción, aunque quede
reloj disponible. Por decisión del usuario, **también se retiran todos los objetos
sin romper al comenzar recogida**, igual que Gravedad. No se trasladan al día siguiente.
Pausa y segundo plano congelan sorteos, deriva, daños y duración.

JSON sigue en **v7**, balance vigente **v12**. Se congela el CSV v11 para que las
jornadas antiguas terminen con su configuración, sin introducir E02 a mitad.
`board.blackHole` guarda RNG independiente, comprobaciones consumidas, contador de
identidades, activaciones, tiempo simulado, duración y anuncio restantes, cierre
y lista de objetos con pose, velocidad, resistencia y golpes recibidos. Los
impactos efímeros no se recuperan. Se guarda tras cada toque y se valida antes de
reemplazar la sesión. Restaurar no vuelve a sortear, activar ni cobrar; abre pausado
sin dedos activos. Paquete Android, claves de guardado, saldo y compras se conservan.

## DEBUG y prueba manual

1. Abrir **Tienda → DEBUG → Agujero negro**.
2. Elegir **1, 2 o 3 objetos de prueba**; volver a la tienda y comenzar el día de
   prueba. Aparecen desde el inicio, sin sensores. La selección se consume una vez;
   las apariciones aleatorias siguen funcionando durante esa prueba.
3. Romper uno con 3–6 toques. Colocar bolas dentro/fuera del alcance, comprobar
   atracción progresiva, inercia y que monedas/herramientas no se mueven por succión.
4. Romper otro antes de agotar el efecto: vuelve a 10 s sin más fuerza. Pausar,
   reanudar y comprobar que al empezar recogida desaparecen objetos y efecto.
5. **Salir de depuración** restaura la partida normal. Pruebas, semillas, compras
   y jornadas de DEBUG no sobrescriben su progreso.

## Parámetros de prueba, no balance aprobado

| Parámetro CSV | Inicial |
| --- | ---: |
| `black_hole_probability` | 0,05 por comprobación |
| `black_hole_interval` | 3 s |
| `black_hole_duration` | 10 s |
| `black_hole_radius` | 180 u |
| `black_hole_acceleration` | 420 u/s² |
| `black_hole_curve` | 2 |
| `black_hole_object_speed` | 8 u/s |

La validación del catálogo admite desactivar la probabilidad con cero, exige
intervalo mínimo técnico 0,25 s, duración ≤10 s y radio superior al alcance normal.
Intervalo, fuerza/curva, radio, deriva, sonido y aspecto definitivos siguen abiertos.
No se ha medido rendimiento ni control en un Android físico.
