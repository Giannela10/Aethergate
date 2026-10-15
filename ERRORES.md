# Errores de la captura del 15 de octubre

## Corregidos

**Object is locked and can't be freed / Attempted to free a locked object.** Al pulsar un botón, su señal cambiaba el menú y el código intentaba destruir ese mismo botón antes de terminar la señal. Ahora los controles anteriores se separan del menú y se eliminan al terminar el ciclo. La prueba de campaña abre la guía y vuelve a pausa emitiendo las señales reales de los botones.

**Parse JSON failed**, en jugador, inventario y campaña. El lector anterior pedía al motor interpretar directamente un archivo vacío o inválido. Ahora se comprueba el resultado de lectura y análisis, se admite una marca BOM de UTF-8 y se conserva una copia `.invalid-….bak` si el contenido no es válido. Se muestra un aviso identificando el archivo y se usan valores iniciales para ese archivo. Esto permite continuar, pero no reconstruye progreso perdido en un archivo dañado. Los tres JSON actuales del usuario se comprobaron como válidos, sin modificarlos; no se pudo determinar qué contenido tenían cuando se tomó la captura.

También se corrigieron nombres locales que coincidían con `sign`, `floor`, `basis` y `tr`; variables sin uso identificadas; divisiones de enteros de minijuegos y tarjetas; tres mezclas de enteros/decimales en expresiones condicionales; y el tipo de restauración del modo del ratón del inventario. Se retiró `@tool` del recogible base: su lógica corresponde al juego y ya retornaba inmediatamente dentro del editor, mientras sus clases derivadas no eran herramientas.

## Qué significan las advertencias amarillas

| Mensaje | Significado |
| --- | --- |
| Same name as a built-in function / shadowing | Una variable tiene el nombre de una función o propiedad del motor. Puede funcionar, pero dificulta leer y mantener el código. |
| Declared but never used | Se calcula o declara algo que luego no se utiliza. Por sí solo no impide jugar. |
| Values of the ternary operator are not mutually compatible | Las dos alternativas de un `valor if condición else otro` tienen tipos distintos. Hay que revisar la línea concreta y unificar los tipos. |
| Integer division | Una división entre enteros descarta decimales. En el reparto de tarjetas y dificultad se hizo explícito el redondeo conservando el resultado esperado para valores positivos. |
| Integer used when an enum value is expected | Un número se asigna a una opción enumerada. Se añadió la conversión del modo del ratón. |
| Base class script has the tool annotation | Una clase base se ejecuta en el editor y una derivada no declara ese comportamiento. Se corrigió la jerarquía del recogible. |

No se confirmó un contador de cero advertencias del editor. Las entradas amarillas agrupadas en la captura no muestran todas sus rutas y líneas, y las pruebas de carga no enumeran todas las advertencias estáticas. Si aparecen otra vez después de una ejecución nueva, expandir la entrada permite ubicar exactamente la que falta.

## Mensajes del entorno que permanecen en las pruebas

- `Failed to read the root certificate store`: Godot no pudo leer el almacén de certificados de Windows en este entorno. No hizo fallar las pruebas locales del juego; puede afectar conexiones HTTPS. No se desactivó la validación de certificados.
- Avisos de escritura o bloqueo del registro `MCPRegistry`: el complemento de herramientas intenta registrar la instancia fuera de la carpeta del proyecto, donde la ejecución de pruebas tiene permisos restringidos. Afectan su registro/conexión de herramientas; las pruebas de jugabilidad pasaron.
- Si se detecta un guardado inválido, queda un aviso deliberado con su respaldo. No se silencia una posible pérdida de progreso.

Validación: 163 scripts/recursos cargados, regresión de campaña con navegación por botones, inventario, jugabilidad y lectura de guardados vacíos, truncados, con raíz incorrecta, válidos y con BOM. Resultados finales sin fallos en `tests/errores_captura_campaign_regression.log`, `tests/errores_captura_gameplay_regression.log` y `tests/errores_captura_final_*.log`.

Godot conserva mensajes de ejecuciones anteriores. Detén el juego, usa **Vaciar** en el depurador y vuelve a ejecutar para distinguir los mensajes nuevos. Si el editor mantiene scripts anteriores cargados, ciérralo y abre nuevamente el proyecto.
