# Documentación de Game Incremental

Versión inicial · 15 de octubre de 2026

Esta documentación acompaña la primera implementación jugable del prototipo. Ver [ejecución y alcance](../README.md) y [registro de validación](validacion-prototipo.md). La validación final del MVP en móvil sigue pendiente.

## Orden de lectura

1. [PRD y alcance](PRD-game-incremental.md): producto, reglas y exclusiones.
2. [Diseño de juego](diseno-de-juego.md): interacción, ciclo y comportamiento de objetos.
3. [Arquitectura y stack](arquitectura.md): módulos funcionales, propiedad de datos, dependencias, guardado y rendimiento.
4. [Dirección de arte y experiencia](direccion-de-arte.md): propuesta visual, pantallas y recursos.
5. [Economía y balance](economia.md): parámetros y criterios de ajuste; [tabla editable](balance.csv).
6. [Plan de implementación](plan-de-implementacion.md): entregas, dependencias y validación.

## Cómo interpretar las decisiones

- **Regla acordada:** parte del producto ya definido en el PRD.
- **Base de implementación:** elección recomendada para poder construir el prototipo; se puede revisar con evidencia.
- **Hipótesis:** requiere una prueba de interacción, balance o rendimiento.

Si hay contradicciones, prevalecen las reglas acordadas del PRD. Los cambios de alcance deben reflejarse primero allí y después en los documentos relacionados. Los números del balance viven en `balance.csv`; los documentos explican su significado.

## Base propuesta para empezar

Android en vertical, Flutter + Flame, un tablero, controles con un dedo y persistencia local. Estilo 2D cenital de objetos redondeados, con un taller nocturno para las mejoras. No se necesita backend.

La estructura será modular desde el MVP: tablero, ciclo diario, economía, mejoras, automatización y progreso. Una sola aplicación y paquete Dart, con reglas independientes de Flutter/Flame, coordinación explícita y catálogos con IDs estables. Las capas y abstracciones se crean cuando se necesitan, sin implementar contenido futuro.

## Decisiones que se revisarán

| Decisión | Base actual | Cuándo revisarla |
| --- | --- | --- |
| Plataforma | Android vertical; web solo como apoyo si resulta útil | Antes de preparar la entrega instalable |
| Motor | Flame sin Forge2D | Al probar empuje de grupos |
| Duración | 60 s de producción + 5 s de cierre | Al completar varios ciclos |
| Objetos entre días | Tablero limpio, sin monedas ni bolas heredadas | Al probar el cierre |
| Arte | Jardín mecánico sencillo, vista cenital | Tras revisar los primeros bocetos |
| Rendimiento | 60 FPS; dispositivo físico por elegir | Antes de aprobar el ensayo de carga |

No hacen falta más sistemas de juego para iniciar. Sí hace falta medir el prototipo antes de fijar el balance y producir arte definitivo.
