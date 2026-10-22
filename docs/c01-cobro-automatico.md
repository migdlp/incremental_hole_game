# C01 — Cobro automático y animación de monedas

## Ajuste de tiempos · 0.16.2+26

Por indicación del usuario se mantiene toda la estética, el salto y el recorrido.
Después del salto, la moneda permanece quieta un segundo. A continuación recorre
la misma curva hacia el monedero, con arranque lento y aceleración, conservando
el cierre suave. Su recepción económica incluye ese segundo; pausa, liquidación
y restauración siguen garantizando el cobro exacto. Las monedas siguen siendo
decorativas, sin colisiones ni fuerzas. Validado con 360 pruebas y pipeline Android;
la percepción final debe comprobarse en móvil.

Estado: implementación 0.13.0+21. Rendimiento de Android físico pendiente de
medición; ningún presupuesto visual se considera definitivo.

## Reglas y decisiones confirmadas

- Recompensa calculada una única vez por captura: valor global actual, dorada ×10
  y racha. Captura total usa exactamente el mismo cálculo. No se añaden tiers.
- La alimentación se acredita al capturar, independientemente de la presentación.
- El dinero se garantiza en el registro económico. La recepción programada en el
  monedero actualiza el saldo visible; no interviene ningún gesto de recogida.
- Producción base 15 s. Se elimina la fase exclusiva de recogida y el cierre
  liquida íntegramente lo pendiente antes de crear resultados.
- Usuario autorizó borrar Barrido, Área, Imán y Atracción sin reembolsos.
  Se conservan saldo y todas las demás compras, cuotas, herramientas y progreso.
- Usuario confirmó Robot con solo Escoba ancha II, sin rediseñar la rama libre.

## Animaciones y presupuesto provisional

Pool preasignado de monedas reutilizables, dibujadas en Flame sin física ni
hitboxes. Aproximadamente 1 s de espera, expulsión en arco con dirección y altura
variables, y vuelo curvo polinómico tipo S con aceleración y llegada suavizadas.
Duración, desplazamiento y curvatura varían determinísticamente por ID. El destino
se obtiene de la posición real del icono del monedero, incluidas pantallas pequeñas.
No se evalúa trigonometría por fotograma para estas curvas. Pintura reutilizada;
el contador pulsa y el sonido de recepción respeta silencio y límite de frecuencia.

Una moneda suele representar toda una captura; su color refleja un rango de las
antiguas denominaciones, sin cifras. No se crean monedas por cada unidad monetaria.
Cuando se llena el presupuesto se agrupan monedas todavía esperando o se omite
presentación; no se acumulan animaciones para reproducirlas posteriormente.

`reward_delay = 1 s`, `reward_visual_limit = 24` y `reward_ledger_limit = 128`
en [balance.csv](balance.csv) son ajustes de prototipo. El límite de presentación
se reduce con frames lentos y se recupera progresivamente. No hay partículas
secundarias que priorizar sobre estas animaciones. El pool puede simplificarse
sin alterar cobro, alimentación, captura o control.

## Contabilidad y restauración

`RewardDelivery` es independiente del pool. Cada captura recibe un ID creciente.
Los registros pendientes conservan rangos de IDs inclusivos sin solapamientos,
importe y fecha de recepción en tiempo simulado. Al llenar el presupuesto de
registros se agrupa un rango consecutivo sin perder su importe, manteniendo
memoria acotada. El número de monedas dibujadas nunca determina el ingreso.

Durante la jornada: generado = recibido + pendiente. El saldo visible suma
saldo bancado y recibido de la jornada. Al cerrar, pendiente pasa a recibido y
se banca exactamente una vez. Pausa y segundo plano congelan el tiempo simulado
y las animaciones. No hay ingresos nuevos mientras la aplicación está cerrada.

JSON v9 incluye el registro pendiente y su próximo ID. Se validan tipos, rangos,
IDs, importes, tiempos y conciliación antes de modificar la sesión. Al restaurar,
se abona directamente el pendiente y no se repite su animación. Guardar otra vez
conserva ese estado liquidado; restaurar repetidamente no añade dinero extra.
Cada frame con capturas solicita un guardado completo atómico; se conserva una
única escritura en curso y como máximo una instantánea posterior, que incluye
todas las capturas anteriores. No hay una cola creciente de escrituras. La
garantía de recuperación alcanza las capturas
incluidas en el último guardado atómico completado; un cierre forzoso puede
retroceder al último guardado completado, sin inventar capturas que nunca se guardaron. Un error de disco conserva la
partida en memoria y se informa, sin afirmar que ya se haya guardado.

Guardados v1–v8: las monedas físicas y reservas pendientes se liquidan por su
importe exacto. Una jornada antigua mantiene su balance físico congelado, pero
usa cobro automático y solo su tiempo restante de producción. Si ya estaba en
recogida, se cierra inmediatamente con liquidación. Las compras retiradas se
validan antes de descartarlas; un archivo temporal de sus niveles en una jornada
histórica permite reconstruir sus ajustes congelados hasta finalizarla. No
aparecen en el catálogo ni se pueden comprar, y no se reembolsan. Balance v14
queda congelado. Se conservan paquete Android y archivo de guardado.

## DEBUG y medición Android pendiente

Tienda → DEBUG → **Monedas automáticas · rendimiento** permite elegir adaptativo,
sin animaciones o presupuestos de prueba, y copiar la medición. Los cambios son
temporales. Comprar Captura total y sus requisitos para comparar capturas masivas;
los ingresos deben ser idénticos con presupuestos 0, 1 o 24.

Instrumentación acotada a 240 muestras: p95 de build, raster y total de Flutter,
y frames por encima de 16,67 ms; además pico, agrupadas y omitidas del pool.
Raster es una medida del hilo rasterizador, **no tiempo GPU físico directo**.
El debug APK tiene sobrecoste: no usarlo para certificar 60 FPS.

Medición por realizar en un Android de referencia todavía no especificado:

1. Ejecutar `flutter run --profile -d <dispositivo>` y abrir DevTools.
2. Registrar modelo, Android, temperatura, frecuencia de pantalla y configuración.
3. Comparar presupuestos 0/8/16/24, una bola, producción máxima y Captura total con
   200 bolas; repetir varias jornadas tras calentamiento y sin instrumentación extra.
4. Capturar timeline CPU, build/raster, frames perdidos y picos; usar herramientas
   Android para GPU cuando haga falta. En memoria registrar heap, GC y asignaciones.
5. Medir también partida normal con guardado activo: DEBUG aísla el progreso y
   no reproduce su coste de E/S. Exportar trazas y memoria; elegir presupuesto solo con esos resultados.

No hay dispositivo Android físico accesible desde esta tarea. No se certifican
60 FPS, consumo de memoria real ni satisfacción visual/táctil sin esa prueba.
Los precios y cuota de S01 también requieren revisar balance al eliminar pérdidas
por monedas; BAL01 sigue pendiente.
