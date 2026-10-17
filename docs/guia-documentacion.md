# Cómo documentamos este proyecto

Objetivo: que otra persona pueda ejecutar el prototipo, localizar una regla, entender una decisión y comprobar una afirmación sin reconstruir la conversación de desarrollo. La documentación vive junto al código en Markdown y se revisa con sus cambios.

## Referencias consultadas

Consultadas el 17 de octubre de 2026; se adaptan sus ideas, no se copia una plantilla completa:

- [Diátaxis](https://diataxis.fr/) distingue necesidades de aprendizaje, ejecución de tareas, referencia y comprensión. Aquí se traduce en un recorrido de primera partida, guías operativas, referencia técnica y explicación de decisiones. Un índice por tareas evita obligar a leer todo para descargar un APK.
- [arc42, introducción y objetivos](https://docs.arc42.org/section-1/) recomienda conectar arquitectura con requisitos y objetivos de calidad concretos, manteniendo breves las repeticiones. La explicación implementada enlaza producto, módulos, flujos, límites y evidencia; el objetivo de rendimiento no se presenta como resultado medido.
- [Architectural Decision Records](https://adr.github.io/) propone registrar decisiones significativas y sus razones/consecuencias. El registro local utiliza entradas pequeñas con estado, contexto, decisión observada, consecuencias, evidencia y condición de revisión.

Estas fuentes orientan cómo escribir. Los hechos del juego proceden de los archivos del repositorio y de ejecuciones identificadas; no de esas guías externas.

## Dónde poner cada información

| Información | Lugar principal |
| --- | --- |
| Resumen y primeros comandos | [README](../README.md) |
| Navegación por necesidad | [Índice](README.md) |
| Funciones entregadas y tareas pendientes | [Estado actual](estado-actual.md) |
| Procedimientos y problemas de preparación | [Guía de desarrollo](guia-desarrollo.md) |
| Clases, dependencias y flujos reales | [Implementación](implementacion.md) |
| Esquema, escritura y recuperación | [Persistencia](persistencia.md) |
| Por qué y cuándo revisar una decisión | [Decisiones](decisiones.md) |
| Ejecución manual, descarga y retención del APK | [CI](ci.md) |
| Resultado medido y sus condiciones | [Validación](validacion-prototipo.md) |
| Reglas acordadas y evolución deseada | PRD y documentos de diseño enlazados en el índice |
| Valores numéricos editables | [balance.csv](balance.csv), sin otra tabla editable paralela |
| Resumen de entregas | [CHANGELOG](../CHANGELOG.md) |

## Criterios de escritura

1. Empezar por el propósito y el resultado que necesita el lector. Dar requisitos, pasos y resultado esperado en los procedimientos.
2. Usar nombres de clases y rutas reales, enlazados de forma relativa. Explicar el contrato y sus motivos; no copiar funciones enteras en prosa.
3. Separar «implementado», «verificado», «pendiente» y «fuera de alcance». Una intención del PRD o un build correcto no es una prueba de experiencia.
4. Registrar fecha, versión/commit, entorno y enlace cuando se afirme una verificación. Mantener las evidencias históricas con su fecha, sin convertirlas en garantías para commits posteriores.
5. Expresar límites concretos. Por ejemplo, un punto de control cada cinco segundos no equivale a un máximo universal de pérdida.
6. Mantener una ubicación principal por dato. Los precios se consultan en el CSV; las guías lo enlazan. Los IDs y el esquema requieren especial cuidado al cambiar partidas guardadas.
7. Usar diagramas pequeños cuando aclaren llamadas o transiciones. Un diagrama de la implementación debe reflejar dependencias actuales, no sustituirlas por una arquitectura ideal.
8. No publicar credenciales, datos privados ni rutas del entorno cloud como si fueran requisitos de todos los clones.

## Revisión al cambiar código

- Si cambia una regla: revisar implementación, estado y pruebas relacionadas.
- Si cambian datos/serialización: revisar economía o persistencia, compatibilidad y ejemplos JSON.
- Si cambia SDK/entrega: revisar `.fvmrc`, lockfile, workflow, guía de desarrollo y CI.
- Si aparece una decisión significativa: añadir o sustituir una entrada del registro, explicando consecuencias y motivo.
- Si se cierra un pendiente: enlazar la evidencia que lo permite. No marcar «validado en móvil» por usar un viewport pequeño de navegador.
- Revisar enlaces relativos, imágenes y comandos desde la raíz del repositorio; comprobar que el diff no mezcla cambios de comportamiento con una actualización documental inadvertida.

Las correcciones documentales no exigen recompilar un APK si no cambian código ni configuración. Sí exigen contrastar hechos y verificar enlaces, ejemplos y navegación. El workflow permanece manual; actualizar un documento no lo dispara.
