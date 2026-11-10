# Riesgos, supuestos y preguntas abiertas

## Riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación | Tarea |
| --- | --- | --- | --- | --- | --- |
| R-01 | Al quitar la emisión automática fallan muchas pruebas existentes | Alta | Medio | E02-T02 es de tamaño L e incluye adaptarlas, con reglas concretas para crear bolas | E02-T02 |
| R-02 | La captura por velocidad hace que la atracción no meta bolas que antes entraban | Media | Medio | Pruebas dedicadas y umbral en el CSV para ajustarlo sin tocar código | E01-T02 |
| R-03 | Un tablero con 4 cañones automáticos se llena de bolas (límite 200) y todos quedan bloqueados | Media | Bajo | El bloqueo no gasta recarga y se ve en gris. El robot y la mano siguen vaciando | E02-T02 |
| R-04 | El árbol de 74 nodos resulta grande en móvil | Media | Medio | Lienzo con arrastre y zoom ya existente. Las ramas nuevas quedan agrupadas arriba | E03-T02, E04-T02 |
| R-05 | Con un disparo por segundo, la primera jornada rinde menos que con 1,5 bolas/s | Alta | Bajo | Invariantes de E05-T01 y ajuste posterior jugando el APK | E05-T01 |
| R-06 | Flutter no está instalado en la sesión del ejecutor | Media | Alto | `AGENT_BRIEF.md` incluye la instalación verificada del SDK 3.35.7 | Todas |

## Supuestos

| ID | Supuesto | Si resulta falso… |
| --- | --- | --- |
| SUPUESTO-1 | Los precios de las mejoras de cañón (`02-architecture.md`, «Balance») son provisionales y se ajustan jugando | Se cambian en `docs/balance.csv` y en las pruebas de E05-T01, sin tocar código |
| SUPUESTO-2 | «Puntería I» de cada cañón exige su automático (G1) o su desbloqueo (G2–G4), para que el árbol sea lineal | Se cambia la columna `requires`. La ruta del árbol puede necesitar revisión |
| SUPUESTO-3 | Disparar no reproduce ningún sonido | Tarea nueva de audio que reutilice el clic del sistema de `game_app.dart` |
| SUPUESTO-4 | El cuerpo del cañón no colisiona con la escoba ni con el robot | Tarea nueva que añada el obstáculo a `_contactBroom` y al robot |
| SUPUESTO-5 | La posición inicial de la escoba (300, 100) y la del robot (295, 360) no necesitan moverse | Si estorban a G1 o a G3, se ajustan en una tarea de pulido |

## Preguntas abiertas

| ID | Pregunta | Propuesta por defecto | Bloquea | Responsable |
| --- | --- | --- | --- | --- |
| PA-1 | ¿Se ajusta el precio de Mano I (13) ahora que la primera jornada da como máximo unas 10 monedas? | Mantener 13 (2 jornadas perfectas) y revisar con el APK | Nada | Usuario |
