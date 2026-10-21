# Piso −1: reconstrucción visual 2026

## Resultado y alcance

Se agregó una primera reconstrucción procedural dentro de `Main.tscn`, bajo `PisoMenos1/ReconstruccionVisual2026/AmbientacionIndustrial2026`. El generador reutiliza materiales y módulos y solo elimina/recrea su propio nodo de ambientación cuando se invoca `rebuild_all()`. La losa original conserva su geometría y colisión; únicamente se le asigna un shader visual de hormigón. No se añadieron scripts de gameplay, NPC ni misiones.

La distribución se tomó de la orientación observada en `Main.tscn`: puertas de ascensor hacia `+Z`; al salir mirando en esa dirección, la izquierda del jugador es `+X` y la derecha `−X`. La huella aproximada del nivel es 169 × 86 m. La llegada de escalera central y emergencia se mantienen.

## Elementos incorporados

- **Zona central:** dos mesas de ping-pong con red y patas, cuatro mesas de estudiantes, tres tramos de casilleros azul/amarillo (58 puertas aproximadas en total) y letrero direccional. Se conservó la escalera funcional existente.
- **Derecha:** local pequeño tipo cafetería con frente translúcido, mesón, vitrinas, máquina de café y dos máquinas expendedoras cercanas.
- **Pasillo/salas:** cuatro espacios técnicos simplificados con mobiliario visible, divisiones y puertas de vidrio hacia el corredor, rótulos y una franja amarilla de orientación. La señalética sigue en iteración visual.
- **Mecánica automotriz:** dos vehículos simplificados, puestos delimitados, tres bancos didácticos, motores/componentes, mangueras de extracción segmentadas y dos carros de herramientas.
- **Soldadura/estructuras:** pórtico de acero, mesas, perfiles, contenedor, cilindros decorativos y ducto/campanas de extracción.
- **Maquinaria:** una grúa horquilla y un minicargador estáticos, más dos carros con piezas automotrices.
- **Rampa:** tramo de 46 m y 8 m de ancho, desde `(-36, −12.058, −80)` a `(-36, 0, −34)`, con losa inclinada, muros, reja, líneas de borde y luminarias. Llega a la superficie exterior que ya existía.
- **Instalaciones visibles:** vigas, conductos, bandejas, tuberías de color y tirantes bajo el forjado. Los módulos son geometría compartida procedural; no son activos fotográficos.

El grupo visual declara 11 zonas, cuatro salas, dos vehículos, dos mesas de ping-pong y tres filas de lockers. Usa meshes/materiales reutilizados y MultiMesh para repetidos seleccionados. La mayoría de los props no proyecta sombras; las luminarias de ambiente añadidas tienen sombras apagadas. No se creó una población nueva de NPC.

## Compatibilidad protegida

Se inspeccionó la colocación existente y se reservó el entorno de `NexoFinalArea`, que la campaña instancia alrededor de `(48, −12.018, −100)`. No se movió NEXO, los ascensores, escaleras, misiones, checkpoints, puertas de progresión, inventario ni guardado. La nueva geometría industrial se distribuye alrededor de esa zona. El cambio visual del material de la losa no reemplaza su cuerpo ni su forma de colisión.

## Validación ejecutada

Usando godot-mcp-toolkit:

- `script_check` pasó para `reconstruccion_visual_2026.gd` y `arquitectura_fotos_preview.gd`.
- El generador devolvió `status=built`; la escena `Main.tscn` se guardó con el resultado.
- `audit_layout()` confirmó `PisoMenos1`, orientación, huella, escaleras, vestíbulo de ascensores y que la ambientación fue creada.
- `check_basement_route()` pasó 12 consultas de espacio para una cápsula de jugador: llegada, centro, Mecánica, ping-pong, lockers, local, corredor, frente de salas, soldadura, base/mitad de rampa y exterior. Es una prueba de despeje en puntos, no un recorrido continuo con controles.
- No se midió FPS de forma representativa ni se recorrió manualmente la ruta, ascensores, escaleras o misión final de NEXO. El archivo de ruta automática queda en `reports/piso_menos1_ruta_visual.json`.

## Capturas MCP

Las capturas son vistas del preview de Godot a resolución 1152 × 648; muestran la geometría actual, que es una **aproximación procedural** y no una réplica idéntica de fotografías.

| Vista | Captura |
|---|---|
| Salida de ascensor, centro | [elevators_center](piso_menos1_capturas/piso_menos1_elevators_center.png) |
| Salida de ascensor, izquierda | [elevators_left](piso_menos1_capturas/piso_menos1_elevators_left.png) |
| Mecánica automotriz | [automotive](piso_menos1_capturas/piso_menos1_automotive.png) |
| Taller automotriz, segunda vista | [automotive_workshop](piso_menos1_capturas/piso_menos1_automotive_workshop.png) |
| Ping-pong y casilleros | [pingpong_lockers](piso_menos1_capturas/piso_menos1_pingpong_lockers.png) |
| Negocio/cafetería | [business](piso_menos1_capturas/piso_menos1_business.png) |
| Pasillo y salas | [corridor](piso_menos1_capturas/piso_menos1_corridor.png) |
| Soldadura/estructuras | [welding](piso_menos1_capturas/piso_menos1_welding.png) |
| Maquinaria | [machinery](piso_menos1_capturas/piso_menos1_machinery.png) |
| Base de rampa | [ramp_base](piso_menos1_capturas/piso_menos1_ramp_base.png) |
| Mitad de rampa | [ramp_middle](piso_menos1_capturas/piso_menos1_ramp_middle.png) |
| Salida exterior mirando hacia abajo | [ramp_exit](piso_menos1_capturas/piso_menos1_ramp_exit.png) |

## Revisión manual recomendada

1. Entrar al juego y recorrer con el personaje el giro izquierda/centro/derecha y el corredor completo; la prueba automática solo revisó posiciones discretas.
2. Comprobar la apertura real de salas, transparencias, rótulos y cámara desde altura normal. Las tomas actuales muestran bloques y materiales básicos; conviene ajustar escala, materiales y colocación frente a las fotos originales.
3. Subir y bajar la rampa, revisar que el empalme con terreno exterior se vea natural y probar el retorno al edificio.
4. Usar ascensores y ambas escaleras; verificar NEXO, checkpoint y sus misiones en una partida con progreso válido.
5. Medir FPS en la máquina objetivo, especialmente con la escena completa cargada.

