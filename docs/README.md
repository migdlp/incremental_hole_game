# Documentación de Feed the Hole

- [AJ-001 a AJ-005 · Ajustes actuales, compatibilidad y aclaración pendiente](ajustes-version-actual.md).

- [P01 · Estrellas, burbujas físicas, persistencia y parámetros DEBUG](p01-estrellas-burbujas.md).

- [S03 · Derrota, prestigio, checkpoints y dependencias P01/P02/BAL01](s03-prestigio-metaprogresion.md).

- [C01 · Cobro automático, persistencia, DEBUG y medición pendiente](c01-cobro-automatico.md).

Referencias de relevo actualizadas el **21/10/2026** para el último APK **0.15.0+23**. Empieza por [relevo de contexto](relevo-contexto.md), [estado actual](estado-actual.md) y [cambios futuros](cambios-futuros-arbol-mejoras.md). Los planes y evidencias de entregas anteriores se conservan como historia; sus cifras pueden estar reemplazadas.

[G01 — cambio de nombre a Feed the Hole y bloqueo de firma](g01-feed-the-hole.md).

[M01 — paredes rebotadoras, balance provisional y pruebas](m01-paredes-rebotadoras.md).

[M02 — bate de béisbol, controles y física configurable](m02-bate-beisbol.md).

[E01 — Gravedad: sensores, evento temporal y pruebas](e01-gravedad.md).

## Empieza por tu tarea

| Quiero… | Leer |
| --- | --- |
| Continuar en otro chat o dar relevo | [Relevo de contexto](relevo-contexto.md) |
| Inspeccionar el árbol completo y probar mejoras gratis | [Modo de depuración](modo-debug.md) |
| Dar contexto rápido y pedir ideas | [Resumen para compartir](contexto-proyecto-para-ideas.md) |
| Saber qué está terminado y qué falta | [Estado actual](estado-actual.md) |
| Preparar los cambios de la siguiente iteración | [Cambios futuros y decisiones abiertas](cambios-futuros-arbol-mejoras.md) |
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

Para incorporarse al desarrollo: relevo → estado actual → cambios futuros; después consultar las referencias técnicas que requiera la tarea. Para probar el APK, basta con la guía de CI y los escenarios manuales de la guía de desarrollo.

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

- [E02 · Agujero negro: prototipo y guía de prueba](e02-agujero-negro.md).

- [M03 · Generador lanzador: prototipo y guía física](m03-generador-lanzador.md).

- [S01 · Alimentación y cuotas: integración, DEBUG y dependencias](s01-alimentacion-cuotas.md).
