# DuocGames

Consulta la [guía de juego y desarrollo](GUIA.md) para saber cómo avanzar, ejecutar las comprobaciones y priorizar el trabajo pendiente. Dentro del juego: **Esc → Guía de juego**. Los detalles de implementación están en [CAMPANA.md](CAMPANA.md) e [INVENTARIO.md](INVENTARIO.md).

Juego 3D de exploración del campus en Godot 4.7.2. Incluye biblioteca con preguntas de literatura, combate en Punto Estudiantil, papelería con inventario y apuntes, y ascensores que conectan el −1 con los pisos 1–8.

El piso **−1** se alcanza por la escalera central, la escalera de emergencia o cualquiera de los tres ascensores. La emergencia conecta **−1 y 1–8**, con descansos de giro, pasamanos y una puerta abatible automática en cada nivel. La abertura protegida del primer piso permite mirar hacia el −1. Dentro del ascensor, **0** selecciona el −1 y **1–8** selecciona los demás pisos; **E** lo llama desde cada nivel.

Abre `project.godot` con Godot y presiona **F6 con Main.tscn abierto**, o **F5** para ejecutar el proyecto.

El renderizador predeterminado es **Compatibility (OpenGL)** para ampliar el soporte de computadores. Reinicia el editor y vuelve a exportar para aplicar el cambio a una distribución. Consulta [RENDIMIENTO.md](RENDIMIENTO.md) para ver las mediciones de consumo y las optimizaciones pendientes.

| Control | Acción |
| --- | --- |
| WASD / flechas | Moverse |
| Shift / Espacio | Correr / saltar |
| C o Ctrl | Agacharse |
| Ratón / rueda | Cámara / zoom |
| E | Interactuar o recoger |
| J o clic izquierdo | Golpear |
| G / Q | Soltar / lanzar implemento deportivo |
| I / F | Inventario / usar artículo equipado |
| 1–8 dentro del ascensor | Elegir piso |
| 0 dentro del ascensor | Bajar al piso −1 |
| Esc | Cerrar ventana o liberar/capturar el ratón |
| R | Reiniciar (con las ventanas cerradas) |

La campaña guarda inventario, apuntes, misiones, bosses, recogibles y checkpoints automáticamente. El menú inicial permite continuar o comenzar una nueva partida. Se conserva la carpeta de guardado anterior aunque la ventana ahora se llama DuocGames. Consulta los límites del guardado en CAMPANA.md.

Con la campaña activa, **Esc** abre pausa, **M** las misiones, **Tab** el mapa, **B** el registro y **U** las mejoras. **Alt** permite esquivar. Dentro del ascensor, **E** abre destinos; los pisos se habilitan al avanzar. La tabla siguiente incluye también controles del modo anterior sin campaña.

Los computadores de minijuegos se habilitan con `populate_entrance` en `GameplayManager`; también activa enemigos y armas de la zona inicial. Está desactivado en el campus actual.

Pruebas desde una terminal con `godot` disponible:

```powershell
godot --headless --path . --script res://tests/gameplay_regression.gd --log-file ./tests/gameplay_regression.log
godot --headless --path . --script res://tests/organizacion_pisos.gd --log-file ./tests/organizacion_pisos.log
godot --headless --path . res://LibraryAccessCheck.tscn --fixed-fps 60 --quit-after 5000 --log-file ./tests/library_access.log
godot --headless --path . res://AuditorioAccessCheck.tscn --fixed-fps 60 --quit-after 1000 --log-file ./tests/auditorio_access.log
godot --headless --path . res://tests/BasementAccessCheck.tscn --fixed-fps 60 --log-file ./tests/basement_access.log
godot --headless --path . res://tests/ElevatorBasementCheck.tscn --fixed-fps 60 --log-file ./tests/elevator_basement.log
```

En Windows, si el ejecutable gráfico devuelve el control antes de terminar, espera a que el proceso cierre y consulta los archivos `.log`. No ejecutes estas escenas simultáneamente con una sesión MCP que necesites controlar: comparten el registro de ejecución del complemento.

Consulta [REVISION.md](REVISION.md) para ver correcciones, límites de la revisión y mejoras pendientes.

La geometría está guardada en `Main.tscn`, ordenada bajo `PisoMenos1`, `Piso1`, …, `Piso8`. Cada piso contiene sus losas, estructura, escaleras, barandas, iluminación, vestíbulo y puertas fijas de ascensor. En el Inspector de cada piso aparecen su número, etiqueta, altura y descripción del contenido. Los tramos de escaleras pertenecen al piso desde el que comienzan.

Los scripts exclusivos de un piso están en `scripts/pisos/piso_1`, `piso_2`, etc. Cada una de las nueve carpetas tiene una ficha `INFORMACION.md`. La lógica general del jugador está en `scripts/juego`; ascensores y puertas reutilizables en `scripts/compartidos`; exterior en `scripts/exterior`. Consulta [scripts/pisos/README.md](scripts/pisos/README.md) para editar y encontrar cada elemento.

`SistemasCompartidos` contiene las cabinas y pozos de ascensor y la estructura continua de emergencia. `Exterior` contiene entrada, patio y terreno. `HerramientasEdicion` conserva las utilidades manuales; no reconstruyen el campus al ejecutar el juego. `InformacionPisos` permite actualizar las fichas desde el Inspector.

La prueba BasementAccessCheck verifica 20 recorridos, la abertura y las nueve puertas usando una cápsula del tamaño del jugador.

ElevatorBasementCheck verifica los tres ascensores: llamada con E desde el −1, entrada, subida con pasajero, descenso con 0 y salida. El tercer recorrido sube hasta el piso 8 antes de regresar al −1.
