# Cuotas — Progresión inicial actualizada

Regla vigente desde el 27 de octubre de 2026. Sustituye únicamente los objetivos
de alimentación; conserva las cuatro jornadas por cuota, captura por bolas,
excedentes, crecimiento, P01/P02 y cartas E03 de la versión actual.

| Cuota | Bolas |
| --- | ---: |
| 1 | 25 |
| 2 | 50 |
| 3 | 100 |
| 4 | 500 |
| 5 | 1.000 |
| 6 | 10.000 |
| 7 | 100.000 |
| 8 | 1.000.000 |
| siguientes | ×10 por cuota |

`FeedingProgress.quotaAt(n)` centraliza esta curva. Los cinco primeros valores
son explícitos; a partir del sexto se usa `1000 × 10^(n−5)`, con BigInt y sin
límite de cuotas de diseño. Ejemplo de excedentes: 125 capturas desde cero
completan 25 y 50, y dejan 50/100 en la tercera cuota. Cada cuota completada
mantiene su evento de crecimiento, estrella y elección de evolución.

## Persistencia y migración

JSON raíz v17; `feeding.curve` distingue `opening-25-v1`, los objetivos DEBUG
personalizados `decimal-v1` y la actualización pendiente `upgrade-from-100`.
Se conservan el nivel, cuotas completadas, crecimiento y capturas de la cuota
activa. Las cantidades continúan siendo cadenas decimales BigInt.

Los guardados de bolas v14–v16 con la curva anterior de 100 ×10 se validan primero
con sus objetivos originales. Al reanudar producción, dentro de la misma
transacción de captura, se activa el objetivo nuevo del nivel actual. Se procesa
todo progreso que ya lo alcance, con excedentes y los eventos normales; guardar
y restaurar otra vez no duplica premios. Mientras la partida está pausada o entre
jornadas se conserva la actualización pendiente, también si se vuelve a guardar.
No se reinicia el plazo salvo que se complete una cuota, como en las reglas
vigentes de cuatro jornadas.

Ejemplo: partida antigua con 90/100 en cuota 1. Al reanudar completa 25 y 50,
y queda en cuota 3 con 15/100, dos crecimientos y dos eventos P01/E03. No se
reinterpreta todo el historial de capturas ni se recompensan cuotas ya completadas.
Una partida antigua en cuota 3 con 80/10.000 pasa a 80/100 sin otro crecimiento.

Los guardados monetarios v1–v13 mantienen su migración segura: no se convierte
dinero en bolas; sus cuotas liquidadas y crecimientos se conservan y se aplica el
objetivo nuevo correspondiente. Los objetivos DEBUG expresamente personalizados
conservan su progresión ×10 y su aislamiento respecto a la partida real.

## Comprobación

Pruebas de todos los objetivos iniciales, continuidad ×10, excedentes, números de
500 dígitos en VM/Chromium, migración en pausa y producción, recompensa única de
estrellas/cartas, crecimiento persistente y conservación de economía. La nueva
curva no cambia precios, duración de jornada, vencimientos ni parámetros de E03.
