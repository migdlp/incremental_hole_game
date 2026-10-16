# Plan de implementación del MVP

Estado: backlog inicial sin fechas comprometidas. El [PRD](PRD-game-incremental.md) define el alcance. Las partes siguientes son incrementos revisables de un mismo MVP.

## 0. Preparación

- Localizar el repositorio de Game Incremental y leer sus instrucciones antes de modificarlo.
- Crear la rama nueva solicitada conservando el historial. La sustitución de la aplicación anterior se hará dentro de esa rama.
- Crear el proyecto Flutter, fijar SDK y dependencias compatibles, verificar build Android.
- Incorporar esta documentación y enlazarla desde el README del proyecto.
- Configurar formato, análisis y pruebas en CI cuando esté disponible el acceso al repositorio.

Estado actual: repositorio `migdlp/incremental_hole_game` localizado y documentación preparada para su publicación en `main`. La aplicación y la rama de desarrollo todavía no se han creado. No interpretar esta lista como trabajo ya realizado.

## 1. Prototipo de interacción

Dependencia: preparación. Objetivo: comprobar el gesto antes de dedicar tiempo a recursos definitivos.

- Tablero lógico adaptable a pantalla vertical y dibujo mediante primitivas.
- Pala con entrada de un dedo, bolas con rozamiento y colisiones, hoyo y generador.
- Monedas con valor, aterrizaje y recogida mediante toque o arrastre.
- Agrupación de monedas y límites iniciales; controles internos para generar carga de prueba.
- Bocetos de jornada y noche según la dirección visual, sin exigir arte final.

Entrega: prototipo ejecutable y notas de prueba. Salida: empujar diez bolas juntas, recoger con gesto rápido, respetar el valor al fusionar y realizar un primer perfil en móvil. Si las colisiones no son estables, comparar una prueba pequeña con Forge2D antes de ampliar el juego.

## 2. Ciclo completo

Dependencia: interacción aceptable.

- Máquina de estados con producción, cierre, pausa, liquidación y noche.
- Temporizador y aviso; tablero limpio al iniciar la nueva jornada como base propuesta.
- Ingreso diario separado del saldo bancado, resultado, récord y pérdida explícita de pendientes.
- Comenzar siguiente día, también sin comprar nada.
- Guardado mínimo consistente del cierre para no construir la economía sobre un saldo provisional.

Entrega: ciclo jugable repetible. Salida: el día termina una vez; toda moneda no recogida se pierde y el ahorro se mantiene. Probar recogida justo en el límite, cierre repetido y entrada en segundo plano.

## 3. Progresión

Dependencia: ciclo y economía consistentes.

- Catálogo tipado a partir del balance; validación de IDs, requisitos y niveles.
- Árbol con tres ramas, ocho tipos de mejora y estados comprensibles.
- Aplicación de las estadísticas al empezar cada jornada.
- Robot básico con búsqueda, empuje y recuperación de bloqueos.
- Imán ligado al dedo y mejoras numéricas con límites.
- Persistencia de compras.

Entrega: ciclo con decisiones y automatización inicial. Salida: verificar cada mejora y jugar hasta desbloquear robot, comparar ramas y comprobar que no hay compras con saldo negativo o requisito incumplido.

## 4. MVP verificable

Dependencia: progresión completa.

- Instantáneas completas, puntos de control, restauración y recuperación de archivos.
- Tutorial breve, volumen y respuesta audiovisual limitada.
- Aplicar la dirección visual validada, zonas táctiles y contraste.
- Sesiones de balance y perfil con todas las mejoras.
- Completar pruebas automáticas de los riesgos económicos y prueba integrada del ciclo.
- Generar build Android instalable, instrucciones de ejecución y limitaciones conocidas.

Entrega: primer MVP con las cuatro partes terminadas. Salida: diez ciclos consecutivos, reapertura durante jornada y noche, compras persistentes, conservación del valor y carga máxima en dispositivo de referencia.

## Registro de validación

Cada entrega debe registrar versión/commit, dispositivo y sistema, comportamiento esperado, resultado observado y problemas pendientes. Separar errores reproducibles de preferencias sobre sensaciones. Las pruebas de experiencia deben observar si el jugador entiende qué hacer sin explicaciones adicionales.

No cerrar el MVP con fallos que dupliquen o pierdan saldo recogido fuera de las limitaciones documentadas de cierre abrupto. Una frecuencia de fotogramas insuficiente requiere ajustar y medir de nuevo, sin afirmar rendimiento a partir del emulador.

## Fuera del plan inicial

Los candidatos posteriores están en el PRD: mejores bolas, robots de dinero y especiales, burbujas, nuevos tableros y progresión a largo plazo. No introducirlos para compensar una interacción todavía incómoda.

## Siguiente paso ejecutable

Resolver el acceso al repositorio y preparar la rama; después construir la parte 1. Android vertical y Flame son la base de trabajo propuesta. La elección de un móvil de referencia debe quedar registrada antes de aprobar rendimiento, y la apariencia final se revisará con los primeros bocetos.
