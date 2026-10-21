# Guía de DuocGames

Consulta [ERRORES.md](ERRORES.md) para las correcciones de la captura del depurador y la explicación de mensajes pendientes.

## Abrir y jugar

1. Abre `project.godot` con la versión utilizada por el proyecto: Godot 4.7.2. Espera la importación y presiona F5.
2. Elige Continuar para usar el progreso guardado o Nueva partida para reiniciar. Nueva partida conserva una copia `.bak` de la campaña anterior.

Al confirmar **Comenzar nueva partida**, se crea un guardado limpio y se recarga el campus después de terminar la acción del botón. Se reinician misiones, jefes, inventario, apuntes, XP, mejoras y accesos; se vuelve a la entrada con vida inicial y los 30 créditos de bienvenida. La partida saliente no puede sobrescribir el reinicio al cerrarse. Si falla el respaldo o la escritura, aparece un aviso y no se recarga la escena. La prueba `tests/nueva_partida.gd` comprueba el botón completo usando un guardado y una escena temporales dentro de tests.
3. Pulsa Esc → Guía de juego para consultar el recorrido sin salir del juego. M muestra las tareas y sus cantidades; Tab muestra los pisos.

La primera misión, **Primer día**, se activa automáticamente. El HUD muestra su nombre y el paso pendiente. Sigue el **marcador amarillo «! MISIÓN PRINCIPAL»**, que indica piso y distancia: comienza con el **Encargado Punto Estudiantil**, al fondo del pasillo del piso 1, lado izquierdo. Los bosses tienen nombre visible antes del duelo. Acércate hasta ver **[E] Hablar**; puedes hablar y elegir Ahora no, y ese paso cuenta. El marcador cambia al siguiente objetivo pendiente. El computador inicial está cerca de la entrada principal y el Chef está en el casino.

Muévete con WASD, corre con Shift, salta con Espacio e interactúa con E cuando aparezca el aviso. I abre inventario; J o clic ataca, mantener clic carga ataque, Alt esquiva, Q lanza objetos compatibles y U abre mejoras. Consulta Esc → Controles para el resto.

## Centros de vida

Hay **12 centros de vida gratuitos y reutilizables**: uno en cada piso (incluido el subterráneo), más centros junto a Punto Estudiantil, casino y biblioteca. Busca la **cruz verde** y el letrero **CENTRO DE VIDA**. Acércate y pulsa **E** para recuperar toda tu salud y guardar allí un punto de reaparición con vida completa. Durante un duelo con un jefe no se pueden usar. Los botiquines y alimentos siguen disponibles en la mochila.

## Sillas y más armas

Hay 51 armas distribuidas por los pisos, incluidas un palo, una silla y una escoba cerca de la entrada. Además puedes recoger sillas sueltas del mobiliario, incluidas las del casino: acércate hasta ver **[E] Tomar silla y equipar**. La silla se equipa directamente; usa J o clic para golpear y G para soltarla. Tiene durabilidad y se rompe al agotarse. Las armas recogidas quedan en la mochila (I).

Recoger una silla retira su modelo y su colisión del escenario. La partida recuerda esa recogida para que no reaparezca duplicada al cargar; Nueva partida restaura el mobiliario. Las butacas fijas del auditorio y los bancos no se convierten en armas.

## Qué hay que hacer

| Etapa | Acción necesaria |
| --- | --- |
| Piso 1 | Habla con Punto Estudiantil, recoge un objeto, completa el computador inicial cerca de la entrada y vence al Encargado y al Chef del casino. Acércate con E y acepta cada duelo. |
| Piso 2 | Recoge tres libros de biblioteca y supera las preguntas de la Bibliotecaria. |
| Pisos 3, 4 y 5 | Completa el computador de cada piso. Habla con el Profesor del 3 y acepta Documentos importantes; entrega sus documentos al Funcionario del 5 para conseguir TarjetaAcceso. |
| Piso 6 | Completa el computador de seguridad. |
| Piso 7 | Abre la sala restringida con TarjetaAcceso y completa el computador. |
| Piso 8 | Completa el computador y vence al Director para recibir su credencial. |
| Subterráneo | Encuentra el archivo secreto para completar la última misión principal. |

Los destinos del ascensor se desbloquean por etapas. Dentro de la cabina pulsa E para elegir. Las escaleras permiten explorar pisos antes de desbloquearlos. Puedes completar secundarias, reunir veinte tarjetas y buscar apuntes y secretos. Si una misión no avanza, consulta M: algunos objetivos necesitan hablar o abrir una puerta además de completar el computador.

Activa checkpoints acercándote fuera de los duelos. Al caer puedes reaparecer sin perder la mochila. El juego guarda por acciones importantes y periódicamente fuera de combate y menús; no garantiza conservar cada instante de un combate. Con la carpeta personalizada configurada en este proyecto, los datos están en `%APPDATA%\Piso y Personaje Basico`. También puedes abrirla desde el editor mediante la opción de abrir la carpeta de datos del usuario. No borres esa carpeta para solucionar fallos: respáldala primero.

Vencer a cualquier jefe recupera toda tu vida, incluido el aumento de vida máxima que pueda dar la recompensa de XP. El jefe termina su animación de caída y queda derrotado en el suelo; al continuar una partida conserva esa pose y no vuelve a entregar recompensas.

## Revisar cambios

Ejecuta desde la carpeta del proyecto, con el ejecutable de Godot disponible como `godot`:

```powershell
godot --headless --path . --script res://tests/revision_scripts.gd --log-file ./tests/revision_scripts.log
godot --headless --path . --script res://tests/campaign_regression.gd --log-file ./tests/revision_actual_campana.log
godot --headless --path . --script res://tests/gameplay_regression.gd --log-file ./tests/revision_actual_gameplay.log
godot --headless --path . --script res://tests/inventory_regression.gd --log-file ./tests/revision_actual_inventario.log
godot --headless --path . --script res://tests/organizacion_pisos.gd --log-file ./tests/revision_actual_pisos.log
```

En Windows usa un ejecutable que espere al cierre; con el ejecutable gráfico puedes usar `Start-Process -WindowStyle Hidden -Wait`. Espera que termine cada prueba antes de iniciar la siguiente y revisa sus líneas finales `RESULT`, `CAMPAIGN_REGRESSION` o `SCRIPT_REVIEW`: deben indicar cero fallos. Los registros antiguos pueden contener errores ya corregidos.

La revisión de scripts carga código propio y recursos de texto; excluye complementos de terceros y pruebas. No ejecuta las herramientas que reconstruyen geometría. Las pruebas de campaña y de inventario aíslan el guardado del jugador; no uses otros generadores o pruebas de recorridos sin revisar sus efectos.

## Correcciones de esta revisión

- El funcionario ya no marca como entregados los documentos que debe proporcionar el profesor. Se cubre la visita al funcionario antes de visitar al profesor.
- La prioridad de un objeto al interactuar ya no se hereda al siguiente candidato del mismo grupo.
- Las tarjetas 19 y 20 se separaron de las posiciones de 17 y 18 en el subterráneo.
- La carga de campaña restaura el artículo de papelería equipado y sus apuntes aunque no haya snapshot de inventario.
- Se retiraron cinco referencias de edición a nodos ausentes, sin recrear paredes ni luces.
- Se añadió la guía al menú de pausa y se corrigió la descripción antigua del guardado en README.

## Trabajo pendiente, en orden

Validación automatizada de esta revisión: carga de 162 scripts/recursos propios, campaña, jugabilidad, inventario y organización de los nueve pisos con 596 rutas sin fallos en sus resultados. Registros: `tests/revision_final_*.log`. El entorno emitió errores al leer certificados de Windows y avisos de escritura del registro MCP fuera del proyecto; esos mensajes permanecen separados de los resultados de jugabilidad. No se validó una partida completa con revisión visual ni una exportación.

1. Recorrer manualmente una partida completa: verificar interacción mirando a los objetos, entrega de documentos, cuatro bosses, guardado/carga y acceso al archivo. Las pruebas automatizadas no sustituyen comprobar cada habitación y ruta con el jugador.
2. Comprobar las rutas físicas de cada piso y los tres ascensores con campaña activa, especialmente muebles cerca del contenido ajustado al suelo.
3. Endurecer la recuperación de guardados: validar campos internos del JSON, recuperar una copia válida ante corrupción y mostrar errores de escritura o renombrado. La escritura temporal actual no comprueba todos esos errores.
4. Revisar el complemento inactivo `addons/godot_ai`: el editor registró una llamada a `resolved_ws_port_for_existing_server` que no existe en su resolvedor. No habilitarlo sin reparar o actualizar una versión completa compatible. El complemento activo es `godot_mcp_toolkit`.
5. Añadir audio real, ajustar combate y comprobar rendimiento y presentación en equipos objetivo. Consultar RENDIMIENTO.md.
6. Preparar exportación, revisar complementos incluidos y probar el ejecutable fuera del editor. No se validó una distribución final.

REVISION.md conserva hallazgos de una revisión anterior: sus pendientes de campaña, pausa y misiones ya tienen implementación en CAMPANA.md. Usa este documento para el estado de esta revisión.
