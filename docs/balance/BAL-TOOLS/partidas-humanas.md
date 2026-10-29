# BAL-TOOLS-04 — Protocolo humano y Android

Estado: preparado, **sin sesiones humanas realizadas en el entorno cloud**.
Los ejemplos de `results/` son bots/mediciones técnicas; no sirven de línea base humana.

## Recogida inicial

Build instrumentada 0.24.0+38. Conservar el APK, commit y configuración con cada
exportación. En Android real, empezar cada escenario desde una partida de prueba
independiente; no borrar la partida habitual para hacer una prueba. Usar dispositivo
secundario/perfil Android separado o guardar primero su copia local por un método
verificado. DEBUG sirve para preparar dotaciones experimentales, pero esas partidas
se etiquetan `human_debug`, nunca como capacidad ordinaria de un principiante.

Cobertura exploratoria mínima: una sesión verificable por condición de abajo,
hasta derrota o 12 jornadas. Anotar abandonos, cartas y motivos, incluso resultados
malos. Objetivo posterior: al menos 3 repeticiones por condición; acordar con AG01
muestra y orden antes de sacar conclusiones estadísticas. No esperar que todas las
personas sigan exactamente la estrategia de un bot.

| Condición | Preparación / conducta |
|---|---|
| Nueva sin permanentes | Sin P02/E03 ni mejoras normales previas |
| Principiante | Persona sin práctica; instrucciones básicas, sin intervención DEBUG |
| Intermedio | Persona que conoce controles/árbol; declarar experiencia |
| Experimentado | Persona con práctica; declarar experiencia |
| Generación | Compras orientadas a producción; registrar compras realmente disponibles |
| Captura | Compras de control/captura; sin poderes no desbloqueados |
| Economía | Prioridad a valor/combos; compras sujetas al juego normal |
| Mixta | Elección libre, registrar cambios de criterio |
| Permanentes | Repetir con H01/H02/H04/H13 cuando estén disponibles; anotar dotación y procedencia |

Se pueden cubrir dos condiciones en una sesión si se declara explícitamente, pero
no presentarla como dos observaciones independientes. Contrabalancear el orden de
estrategias cuando sea posible para reducir el efecto de aprendizaje.

## Por sesión

1. Completar `session-conditions.template.json` con un ID arbitrario, sin nombre,
   correo, identificadores Android ni ubicación.
2. Registrar modelo Android/OS, Hz, modo debug/profile/release, batería/ahorro,
   temperatura percibida, orientación, familiaridad, ayuda y pausas. No inventar
   precisión térmica ni GPU física; usar null cuando no se mida.
3. Jugar de forma normal. No activar DEBUG durante la medición; después de la
   jornada abrir árbol → DEBUG → Laboratorio de balance, exportar session.json,
   days.csv y summary.txt. Abrir el exportador conserva los días `human_normal`.
4. Compartir mediante hoja Android; exportar antes de salir del sandbox si se
   jugaron pruebas DEBUG. Volver a exportar después de una restauración para
   comprobar continuidad y que no aparecen premios duplicados.
5. Ejecutar `python3 tool/balance_compare.py session.json`; guardar salida junto
   a las condiciones. No editar los resultados para forzar coherencia.
6. Registrar saturación/atascos, fluidez percibida, fallos de compartir y si hubo
   restricciones de segundo plano. FrameTiming no identifica causas ni coste GPU.

El almacenamiento conserva 500 días/2.000 eventos, con retención por bytes
indicada en la exportación. Exportar al terminar cada sesión.

## Cierre de la tarea

Adjuntar archivos humanos originales, condiciones, validación, resumen por
estrategia y Android utilizado. Revisar con AG01 las diferencias de captura real,
saturación y coste. No cerrar esta tarea con los bots o un benchmark Linux.
Sin dispositivo/testers, la recogida queda pendiente y bloquea la referencia humana
exigida para la aceptación completa de BAL-TOOLS-06.
