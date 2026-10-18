# Plan de implementación del MVP

Plan general actualizado al 18 de octubre de 2026. Para implementación y pruebas ya realizadas, ver [estado actual](estado-actual.md) y [seguimiento de agarre, escobas y balance](plan-cambios-agarre-escoba.md). Las fases no acreditan por sí mismas aceptación del MVP.

Estado: backlog inicial sin fechas comprometidas. El [PRD](PRD-game-incremental.md) define el alcance. Las partes siguientes son incrementos revisables de un mismo MVP.

## 0. Preparación

- Leer las instrucciones del repositorio `migdlp/incremental_hole_game` antes de modificarlo.
- Crear la rama de desarrollo conservando el historial de documentación existente.
- Crear el proyecto Flutter, fijar SDK y dependencias compatibles, verificar build Android.
- Establecer la composición en `app/` y los módulos funcionales según [arquitectura](arquitectura.md), creando solo los necesarios para cada entrega. Mantener dominio en Dart puro, contratos públicos y propiedad única de datos.
- Incorporar esta documentación y enlazarla desde el README del proyecto.
- Configurar formato, análisis y pruebas en CI cuando esté disponible el acceso al repositorio.

Preparación completada. La entrega actual incluye mano/escobas, día corto, guardado v3 y árbol progresivo en `1720fba`. Ver [validación del prototipo](validacion-prototipo.md). Los criterios de sensación, balance y rendimiento en dispositivo físico siguen abiertos; las listas siguientes conservan el plan de aceptación, no certifican su cumplimiento.

## 1. Prototipo de interacción

Dependencia: preparación. Objetivo: comprobar el gesto antes de dedicar tiempo a recursos definitivos.

- Tablero lógico adaptable a pantalla vertical y dibujo mediante primitivas.
- Mano y escobas con entrada de un dedo, bolas con rozamiento y colisiones, hoyo y generador.
- Monedas con valor, aterrizaje, pulsación inicial y barrido mediante compra.
- Mantener movimiento y captura en el dominio de `board` y representación en su presentación Flame; emitir eventos explícitos hacia la sesión para contabilizar en `economy`.
- Agrupación de monedas y límites iniciales; controles internos para generar carga de prueba.
- Bocetos de jornada y noche según la dirección visual, sin exigir arte final.

Entrega: prototipo ejecutable y notas de prueba. Salida: empujar diez bolas juntas, recoger con gesto rápido, respetar el valor al fusionar y realizar un primer perfil en móvil. Si las colisiones no son estables, comparar una prueba pequeña con Forge2D antes de ampliar el juego.

## 2. Ciclo completo

Dependencia: interacción aceptable.

- Máquina de estados con producción, cierre, pausa, liquidación y noche.
- Temporizador y aviso; tablero limpio al iniciar toda nueva jornada como regla acordada.
- Ingreso diario separado del saldo bancado, resultado, récord y pérdida explícita de pendientes.
- Comenzar siguiente día, también sin comprar nada.
- Guardado mínimo consistente del cierre para no construir la economía sobre un saldo provisional.
- Incorporar `day_cycle` y `progression`; coordinar el cierre en `GameSession` sin que los módulos modifiquen directamente el estado de otros. Separar serialización y archivos de las reglas.

Entrega: ciclo jugable repetible. Salida: el día termina una vez; toda moneda no recogida se pierde y el ahorro se mantiene. Probar recogida justo en el límite, cierre repetido y entrada en segundo plano.

## 3. Progresión

Dependencia: ciclo y economía consistentes.

- Catálogo tipado a partir del balance; validación de IDs, requisitos y niveles.
- Árbol con tres ramas, once tipos de mejora y estados comprensibles.
- Aplicación de las estadísticas al empezar cada jornada.
- Robot básico con búsqueda, empuje y recuperación de bloqueos.
- Imán ligado al dedo y mejoras numéricas con límites.
- Persistencia de compras.
- Añadir `upgrades` y `automation` mediante sus contratos: compra consistente entre coste y nivel, robot que devuelve órdenes al tablero y catálogos con IDs estables.

Entrega: ciclo con decisiones y automatización inicial. Salida: verificar cada mejora y jugar hasta desbloquear robot, comparar ramas y comprobar que no hay compras con saldo negativo o requisito incumplido.

## 4. MVP verificable

Dependencia: progresión completa.

- Instantáneas completas, puntos de control, restauración y recuperación de archivos.
- Tutorial breve, volumen y respuesta audiovisual limitada.
- Aplicar la dirección visual validada, zonas táctiles y contraste.
- Sesiones de balance y perfil con todas las mejoras.
- Completar pruebas automáticas de los riesgos económicos y prueba integrada del ciclo.
- Revisar dependencias entre módulos y ausencia de Flutter/Flame en dominio; validar compatibilidad de partidas e IDs al cambiar contenido. No extraer paquetes ni introducir frameworks solo por previsión.
- Generar build Android instalable, instrucciones de ejecución y limitaciones conocidas.

Entrega: primer MVP con las cuatro partes terminadas. Salida: diez ciclos consecutivos, reapertura durante jornada y noche, compras persistentes, conservación del valor y carga máxima en dispositivo de referencia.

## Registro de validación

Cada entrega debe registrar versión/commit, dispositivo y sistema, comportamiento esperado, resultado observado y problemas pendientes. Separar errores reproducibles de preferencias sobre sensaciones. Las pruebas de experiencia deben observar si el jugador entiende qué hacer sin explicaciones adicionales.

No cerrar el MVP con fallos que dupliquen o pierdan saldo recogido fuera de las limitaciones documentadas de cierre abrupto. Una frecuencia de fotogramas insuficiente requiere ajustar y medir de nuevo, sin afirmar rendimiento a partir del emulador.

## Fuera del plan inicial

Los candidatos posteriores están en el PRD: mejores bolas, robots de dinero y especiales, burbujas, nuevos tableros y progresión a largo plazo. No introducirlos para compensar una interacción todavía incómoda.

## Siguiente paso ejecutable

Probar el APK 0.2.1+3 en Android físico, revisar agarre, inercia, recta/V y monedas, validar el árbol progresivo y acordar precios, y medir tres jornadas de carga máxima. Registrar el dispositivo antes de aprobar rendimiento. Ajustar balance y presentación a partir de esas pruebas, sin dar por aceptado el MVP por pasar pruebas automáticas.
