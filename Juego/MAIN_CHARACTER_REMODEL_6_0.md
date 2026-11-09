# DUOCGAMES — protagonista 6.0

**IMPLEMENTADO e integrado. Aceptación visual profesional: NO ALCANZADA.** El personaje mejora geometría, rostro, cabello, manos y prendas, pero sigue siendo procedural y estilizado. No se presenta como un humano semirrealista profesional con skinning ni se aprueba toda la lista del encargo.

## Respaldo y auditoría

Rama local `recovery/main-character-6-0`, commit `b2deacc8ec569103e00901ddd5302a041fec180d`. Checkpoint selectivo de fuentes actuales sobre HEAD, creado con índice separado, sin sustituir el índice del usuario. Sin push. Copias adicionales en `../recovery/main_character_6_0/`, incluido appearance_menu.gd. Para recuperar únicamente el visual anterior, restituir el preload de player.gd a student_visual.gd. No hacer reset completo: había muchos cambios anteriores ajenos a esta tarea.

Escena real: `Main.tscn` → gameplay_manager.gd → CharacterBody3D Player creado dinámicamente con `scripts/juego/player.gd`. `Character.tscn` existe, pero no es este protagonista. Player crea CharacterVisual con escala **1.5**, cápsula **2.7** de altura y **0.45** de radio. Cámara: pivote **1.4**, FOV **60**, distancia inicial **5**. Estas medidas y el controlador se conservaron.

Jerarquía visual: Model/fall_pivot → hips → spine → Torso; cuello → Head; brazos con hombro, codo y mano; piernas con cadera, rodilla y tobillo. Los MeshInstance3D se generan por script. WeaponSocket e ItemSocket permanecen en mano derecha; BackpackSocket en torso; HairSocket y HeadAccessorySocket en cabeza. Se conservaron identidad, padres y transformaciones de enganche.

Rig real: transformaciones procedurales de articulaciones. ImportedModel contiene un Skeleton3D de reserva sin huesos; AnimationPlayer contiene clips de reserva sin pistas y AnimationTree está inactivo. No son un esqueleto humano funcional. No se encontraron modelos GLB, GLTF, FBX, OBJ o BLEND reutilizables en Juego.

Personalización: CharacterAppearance normaliza índices y restricciones; ProceduralAppearanceAdapter recolorea y genera prendas. CampusCampaign conserva appearance y el guardado existente. No se cambió su lógica.

## Escena y scripts modificados

- Nuevo `scripts/juego/main_character_visual_6.gd`, derivado de StudentVisual.
- `scripts/juego/player.gd`: solo cambia el preload visual respecto al checkpoint de esta intervención.
- `scripts/campaign/appearance_menu.gd`: vista previa con el mismo modelo y valores cosméticos iniciales de nueva partida. Confirmación, desbloqueos y escritura del guardado permanecen iguales.
- `Main.tscn`, humanoid.gd, student_visual.gd, adaptador compartido, perfiles compartidos y NPC no fueron modificados durante esta intervención. Se conservaron cambios previos ya existentes en el árbol de trabajo.

## Mallas, cuerpo, rostro y cabello — IMPLEMENTADO

Cráneo de anillos con 40 segmentos, mandíbula y mentón progresivos; desplazamiento de vértices para mejillas, cuencas y frente, con normales recalculadas. Torso y abdomen contorneados, transición hacia cuello y hombros con manga propia. Brazos, antebrazos, muslos y pantorrillas con radios variables. Palmas aplanadas, cuatro dedos y pulgar segmentado; cierre visual ligero al equipar/golpear. Zapatillas con cubierta, suela elíptica, lengüeta y cordones simplificados.

Ojos con iris, pupilas y reflejo pequeño; bordes de párpados, cejas segmentadas, puente/punta de nariz, labios y orejas con relieve interior. Componentes oculares conectados al parpadeo existente. Boca con origen local para evitar desplazamientos al expresar sorpresa. Expresiones ligeras existentes: neutral, alegría, sorpresa, concentración, dolor y victoria. No hay blend shapes ni sincronización labial de conversación.

Cabello: base y 22 mechones combinados en una malla, sin simulación. Se conservan los índices y colores existentes. Corto, medio y largo cambian longitud de mechones; se respeta sin cabello. El rizado sigue siendo aproximado.

## Ropa, mochila y materiales — IMPLEMENTADO

Polerón seleccionable con capucha plegada posterior, bolsillo delantero, cordones y mangas/puños. Jeans con volumen variable y costuras/pocket indicados por geometría ligera. Mochila con compartimento contorneado, bolsillo frontal conservado, tirantes alrededor de hombros y recorrido de cierre. Conserva BackpackSocket e identificador Mochila.

Nueva partida propone top=1, bottom_style=1, pants=5, shoes=5, backpack=1 y backpack_color=5. Todas las selecciones siguen disponibles. Las partidas existentes conservan su elección. Las comparaciones usan el perfil anterior de polera para separar mejora geométrica de cambio de atuendo.

StandardMaterial3D PBR compatibles con el renderer actual: piel rugosa .82–.84, cabello .77, tela/denim .90–.95 y suela .96, especular moderado heredado. Se reutiliza Surface6.fabric(), textura procedural de rugosidad. No se importaron texturas ni assets externos: no hay licencias externas nuevas que atribuir. La luz frontal del campus todavía aplana el relieve de nariz y rostro.

## Rig y animaciones

Se conservan animador, poses, señales y tiempos de ataque del sistema existente. Se añade cierre visual de dedos, sin alterar sockets, daño o alcance. Quieto, caminar, correr, salto y agachado se ejercitaron mediante animate() y se capturaron poses. Esto no demuestra ausencia de deslizamiento durante un recorrido real.

**NO IMPLEMENTADO:** skinning continuo, pesos de piel/ropa, IK de pies, dedos articulados individualmente, nuevas animaciones de interacción o conversación sincronizada. Las articulaciones siguen siendo piezas móviles; puede haber transiciones visibles en rodillas/codos y ajustes pendientes con algunas prendas o armas.

## Evidencia y pruebas

[Comparador antes/después](reports/main_character_6_0/comparison.html). Carpeta `reports/main_character_6_0/`:

- before_/after_: front, back, left, right, face, game_camera, walking_campus.
- after_hoodie_hair_0/1/4: polerón y tres longitudes de cabello.
- after_motion_walk/run/jump/crouch y after_expression_*: poses y expresiones.
- after_equipped: arma real recogida de weapon_pickup y equipada por el inventario existente.
- after_zone_entrance/corridor/library/computer_lab/exterior: Main en cinco posiciones verificadas con SeatController.safe_position. Son traslados de diagnóstico, no recorridos completos caminados.
- after_personalization: interfaz de apariencia con la vista previa nueva.
- main_direct: arranque directo de Main con menú inicial; el menú tapa al jugador, por lo que esta captura sola no demuestra su aspecto. Una consulta MCP al jugador devolvió `res://scripts/juego/main_character_visual_6.gd`.

Comparativas generadas por `tests/MainCharacterRemodel60.tscn`, que instancia Main sin persistencia de campaña/inventario, con actores detenidos y poses controladas. Baseline usa StudentVisual original sin modificar. Se obtuvieron capturas antes de editar producción y luego se repitieron con poses iguales. Se corrigieron un error del contador diagnóstico de vértices y una cámara de biblioteca tapada por una pared; no se aprobaron esas versiones defectuosas.

**VERIFICADO FUNCIONALMENTE:** script_check MCP válido; Main instanciado y arranque directo; sockets idénticos tras cambios; reaplicar perfiles sin acumular mallas; recogida/equipamiento real; un único punch_landed; archivo user:// aislado de apariencia guardado/cargado con igualdad de perfil. `functional.json` registra los resultados. La batería adicional `main_character_regression_6.gd` ejercitó roundtrip, sockets, expresiones, ausencia de colisiones cosméticas, LOD y ataque: `regression.log` registra failures vacío.

`source_audit.json` confirma Main y fuentes compartidas idénticos al checkpoint y que player solo cambia el preload visual. El arranque directo tuvo una llamada MCP inicial transitoria GAME_NOT_RUNNING; las siguientes consultas y captura funcionaron. El log del juego no mostró un error de script asociado. No se inició una campaña nueva ni se confirmó apariencia en esa prueba directa.

**VERIFICADO VISUALMENTE:** inspección de PNG de frontal, perfil derecho, rostro, polerón/cabello corto, biblioteca, laboratorio, pasillo, exterior y equipamiento. Los otros ángulos/poses existen, pero no equivalen a revisión exhaustiva de todos los fotogramas. **PENDIENTE MANUAL:** flujo completo de guardado de campaña, todo el catálogo de armas, sentarse/levantarse y demás interacciones en una partida completa.

## Rendimiento

[Comparación numérica](reports/main_character_6_0/performance_comparison.json): 90 intervalos frame_post_draw, misma cámara/perfil/pose, semilla 600, Main con actores congelados, GTX 1050 y Compatibility.

| Medida | Antes | Después |
|---|---:|---:|
| Vértices visibles del jugador | 12 721 | 17 638 |
| Superficies visibles del jugador | 59 | 66 |
| Draw calls de toda la vista | 179 | 200 |

Intervalos medidos próximos a 13.33 ms con límite de 75 Hz. Los FPS del monitor incluyen carga/historial y varían entre ejecuciones; se conservan sin presentarlos como mejora o regresión demostrada. No es un benchmark de partida completa ni permite determinar margen de GPU. El conteo depende del atuendo. **PENDIENTE MANUAL:** recorrido con físicas/combate, sin límite de FPS, y perfil de CPU/GPU.

## Criterios pendientes y limitaciones reales

| Criterio | Estado |
|---|---|
| Cambio geométrico, rostro, cabello, manos y prendas | IMPLEMENTADO / revisión visual parcial |
| Cámara, escala física y sockets conservados | VERIFICADO FUNCIONALMENTE en pruebas descritas |
| Arma equipada | VERIFICADO FUNCIONALMENTE; ajuste fino de todo el catálogo PENDIENTE MANUAL |
| Personalización, preview y atuendo inicial | IMPLEMENTADO; diagnóstico de menú registrado |
| Apariencia guardada/cargada | VERIFICADO en archivo aislado; flujo completo de campaña PENDIENTE MANUAL |
| Main ejecuta el visual nuevo | VERIFICADO FUNCIONALMENTE |
| Capturas antes/después | IMPLEMENTADO |
| Deformación natural continua | NO IMPLEMENTADO; rig procedural conservado |
| Cero deslizamiento de pies y todas las interacciones | PENDIENTE MANUAL |
| Humano semirrealista profesional | NO ALCANZADO |
| Ausencia de regresiones en todo el juego | PENDIENTE MANUAL; pruebas ejecutadas sin fallos funcionales detectados |

Para alcanzar calidad profesional falta un humano con topología facial/corporal, UV, materiales de piel/tela, ropa ajustada, Skeleton3D con pesos, retargeting de locomoción/combate e IK de apoyo. No se descargaron recursos de procedencia o licencia dudosas ni se reemplazó al jugador por una figura estática.

No se modificaron campaña, misiones, login, Supabase, roles, inventario funcional, estadísticas, economía, recompensas, persistencia funcional ni NPC. El menú cosmético está bajo scripts/campaign por la estructura del proyecto; sus cambios nuevos se limitan a presentación y valores de apariencia iniciales.
