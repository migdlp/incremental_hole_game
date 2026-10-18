# Documentación de Jardín mecánico

Actualizada el 18 de octubre de 2026. Describe `0.2.1+3`, con código en `main` hasta `1720fba`, incluido el árbol progresivo. La documentación distingue implementación, evidencias de prueba y objetivos pendientes.

## Empieza por tu tarea

| Quiero… | Leer |
| --- | --- |
| Saber qué está terminado y qué falta | [Estado actual](estado-actual.md) |
| Preparar los cambios de la siguiente iteración | [Seguimiento de agarre, escobas y balance](plan-cambios-agarre-escoba.md) |
| Explorar herramientas para recoger y lanzar bolas | [Ideas de herramientas](ideas-herramientas-bolas.md) |
| Ejecutar el proyecto y completar una primera partida | [Guía de desarrollo](guia-desarrollo.md) |
| Descargar o generar un APK | [Pipeline manual](ci.md) |
| Explorar el árbol implementado | [Árbol actual de mejoras](arbol-de-mejoras.md) |
| Editar juntos el diseño futuro del árbol | [Cambios futuros del árbol](cambios-futuros-arbol-mejoras.md) |
| Entender los módulos y el ciclo de ejecución | [Implementación actual](implementacion.md) |
| Entender el guardado y recuperar una partida | [Referencia de persistencia](persistencia.md) |
| Cambiar precios, requisitos o efectos | [Economía](economia.md), [CSV](balance.csv) y [catálogo implementado](implementacion.md#balance-y-mejoras) |
| Consultar pruebas y resultados observados | [Registro de validación](validacion-prototipo.md) |
| Entender por qué se eligió esta solución | [Decisiones técnicas](decisiones.md) |
| Actualizar esta documentación | [Guía para documentar](guia-documentacion.md) |
| Consultar la evolución de la entrega | [Historial de cambios](../CHANGELOG.md) |

Para incorporarse al desarrollo: estado actual → guía de desarrollo → implementación → persistencia → decisiones. Para probar el APK, basta con la guía de CI y los escenarios manuales de la guía de desarrollo.

## Producto y diseño objetivo

Estos documentos conservan requisitos, propuestas e hipótesis que no equivalen a funciones ya entregadas:

- [PRD y alcance](PRD-game-incremental.md): reglas acordadas y exclusiones.
- [Diseño de juego](diseno-de-juego.md): interacción y criterios de sensación.
- [Arquitectura objetivo](arquitectura.md): límites y dirección de crecimiento.
- [Dirección de arte](direccion-de-arte.md): presentación y recursos finales propuestos.
- [Plan de implementación](plan-de-implementacion.md): entregas y aceptación.
- [Seguimiento de cambios](plan-cambios-agarre-escoba.md): decisiones, implementación y evidencias de esta tanda. El [plan anterior](plan-siguiente-iteracion.md) se conserva como antecedente.

El PRD define lo que se quiere construir; [implementación](implementacion.md) y código describen lo que existe. Una diferencia debe registrarse en [estado actual](estado-actual.md), no resolverse atribuyendo al prototipo una función futura. Los valores editables viven únicamente en [balance.csv](balance.csv).

## Convenciones de estado

- **Implementado:** existe en el código; se enlaza su ubicación.
- **Verificado:** hay una prueba o ejecución identificable, con sus condiciones y límites.
- **Pendiente:** falta trabajo o evidencia de aceptación.
- **Fuera de alcance:** el PRD lo excluye de este MVP; no es una tarea pendiente de esta entrega.

La estructura adapta [Diátaxis](https://diataxis.fr/) a este repositorio: recorrido inicial, guías para tareas, referencia y explicación. Los criterios y las fuentes consultadas están en la [guía de documentación](guia-documentacion.md).
