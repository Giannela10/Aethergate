# PERSONAJES 2.0

Esta etapa amplía los personajes existentes. El aspecto sigue siendo procedural y estilizado: no se ha importado ni generado un modelo humano externo. No cambia el daño, estadísticas, recorridos, misiones, distribución del edificio ni las colisiones del jugador.

## 1. Protagonista

Se conserva su altura y el rig articulado para no desajustar cápsula, escaleras, asientos y alcance. Las palmas son menos esféricas; la velocidad visual se suaviza al arrancar/parar, conservando la respuesta física. Hay parpadeo, mirada limitada, respiración existente, idles ocasionales, postura de equipamiento y balanceo muy ligero de mochila. Las proporciones previas de cabeza, torso, piernas y pies se conservan: el cambio no sustituye su geometría completa por anatomía realista.

## 2. CharacterVisual

El único nodo visual del Player ahora se llama CharacterVisual; player.body conserva su API anterior. CollisionShape3D, CameraPivot, InteractionArea, inventario y CombatExtensions permanecen separados. Dentro siguen los pivotes articulados de Model, Head, Torso y extremidades. WeaponSocket e ItemSocket siguen la mano y BackpackSocket el torso. No hay un segundo Player.

module_parts y el metadato visual_module clasifican BODY, HEAD, HAIR, TOP, BOTTOM, SHOES, ACCESSORY y BACKPACK sin romper la jerarquía que mueve brazos y piernas. Los accesorios cosméticos se añaden sobre esos pivotes.

## 3. Reemplazar por GLB/GLTF

Importar el archivo a Godot y crear una escena adaptadora con origen en los pies, dirección frontal -Z y escala ajustada al visual actual. Necesita Skeleton3D con huesos, MeshInstance3D con skin y AnimationPlayer como descendientes. Añadir dos Marker3D o BoneAttachment3D de mano; opcionalmente otro para la mochila.

Después de que el Player esté listo:

```gdscript
var clips := {
    "IDLE": "Idle",
    "WALK": "Walk",
    "RUN": "Run",
    "JUMP": "Jump",
    "FALL": "Fall",
    "LAND": "Land",
    "ATTACK_LIGHT": "Attack",
    "DEATH": "Death"
}
var bindings := {
    "weapon_socket": "Rig/Skeleton3D/RightHandAttachment",
    "item_socket": "Rig/Skeleton3D/LeftHandAttachment",
    "backpack_socket": "Rig/Skeleton3D/BackAttachment"
}
var accepted := player.body.install_imported_visual(
    preload("res://characters/student_adapter.tscn"), clips, bindings)
```

La ruta del ejemplo todavía no existe: debe apuntar al asset que se incorpore. Los nombres de clips y sockets deben coincidir con ese archivo. Se rechazan modelos sin esqueleto con huesos, locomoción mínima o sockets de manos. Se conserva el fallback y el arma cuando la validación falla.

La escena importada recibe un AnimationTree real con BlendSpace1D de locomoción (0 / 2.5 / 5.5), transiciones de 0.12 s y estados con clips disponibles. Cuando falta un clip se muestra el visual procedural durante ese estado. Su reloj de golpes continúa emitiendo punch_landed una sola vez: las animaciones importadas no deben añadir llamadas que dupliquen daño.

El adaptador mueve los mismos sockets hacia los marcadores importados y los restaura al volver al fallback. Para retirar el modelo: player.body.imported_visual.clear(). La escena importada puede implementar apply_appearance(profile), set_expression(name), set_gaze(yaw, pitch) y set_blink(closed). Esos hooks deben adaptarse a sus materiales, huesos y BlendShapes; no hay un estándar universal de nombres faciales.

## 4. Animaciones que funcionan

Locomoción procedural existente: reposo, caminar, correr, agacharse, salto, caída, amortiguación de aterrizaje, golpes, equipamiento, impacto y caída controlada de muerte. Se mantienen las poses de recoger, puertas, botones, computador, lectura, conversación y sentarse. El lanzamiento reutiliza el gesto existente y expone THROW. Se detectan ATTACK_HEAVY y DODGE desde CombatExtensions.

Hay gestos breves al conversar y tres variaciones de idle: mirar alrededor, revisar teléfono y ajustar tirante. Se interrumpen por movimiento, arma equipada, combate cercano, daño, diálogo, asiento o una escena marcada important_scene. No se inicia un gesto nuevo con cada línea.

El árbol anterior de reserva permanece inactivo con estados y clips sin pistas, explícitamente identificados como reserva. Conserva los aliases Idle/Walk/Run/Attack/Hurt/Death para compatibilidad.

## 5. Estados preparados y assets pendientes

IDLE, WALK, RUN, CROUCH, CROUCH_WALK, JUMP, FALL, LAND, ATTACK_LIGHT, ATTACK_HEAVY, THROW, DODGE, BLOCK, PARRY, HIT, DEATH, INTERACT, PICKUP, USE_COMPUTER, PHONE y SIT están declarados.

BLOCK/PARRY no incorporan nuevas mecánicas ni animaciones inventadas. Para tener clips humanos reales hacen falta animaciones de esos estados sobre un rig compatible; el dodge actual conserva su movimiento físico y no simula una voltereta inexistente.

Foot IK y ragdoll permanecen desactivados. El Skeleton3D vacío que ya existía en ImportedModel es solo una reserva, no un esqueleto skinned compatible. No se activan físicas de huesos ni se cambian las colisiones para simularlos.

## 6. Variaciones de NPC

character_visual_presets.gd produce perfiles deterministas desde un ID y rol. Los ocho NPC de campaña usan npc_visuals[ID] dentro del mismo guardado v1. Cargar una partida reutiliza el perfil guardado; las partidas antiguas generan el campo visual nuevo. Cambiar el catálogo no vuelve a sortear los NPC ya guardados.

La papelería tiene un perfil fijo por ID. Los guardias conservan su uniforme y patrullas, con tonos de piel/cabello deterministas según su ruta estable. Las máquinas expendedoras siguen siendo máquinas.

No se encontró un sistema de NPC dinámicos ni NPCActivityPoint ni Rival en los scripts actuales. No se han creado sustitutos. set_visual_activity(action, prop) y contextual_pose permiten conectar futuros propietarios de rutinas a este visual sin reemplazar la lógica.

## 7. Presets de ropa

ESTUDIANTE, PROFESOR, FUNCIONARIO, TECNICO, GUARDIA, VENDEDOR, ENFERMERIA, ODONTOLOGIA, TALLER, INGLES, LENGUAJE y ETICA. Los presets sanitarios/académicos/industriales quedan disponibles como datos; no se han añadido personajes a sectores que no los tenían.

Piel, cabello, superior, pantalón, zapatos, mochila, accesorio y ancho de torso/cadera admiten variantes. Hay corto, largo, sin cabello, corto lateral, medio y rizado simplificados. Los índices anteriores no cambian.

La distribución del campus sigue AGENTS.md: informática/telecomunicaciones en 3; salud en el norte de 4 y profesores en el otro sector; generales en 5–8; taller industrial en -1. El Director permanece en 8.

## 8. Bosses

El pase se integra en BossDuelController y conserva la secuencia NEUTRAL → DIALOGUE → INTRO → COMBAT. Punto Estudiantil tiene detalles deportivos, credencial y balón visual neutral; Chef conserva uniforme/gorro/delantal y sostiene una bandeja neutral; Bibliotecaria conserva moño/falda/lentes/libro y pose de lectura; Director conserva traje/credencial/visor y revisa una carpeta; Redes conserva tablet y detalles tecnológicos.

Los props neutrales incompatibles se ocultan al combatir. Se exponen BOSS_IDLE, BOSS_INTRO, BOSS_ATTACK, BOSS_SPECIAL, BOSS_HIT, BOSS_PHASE_CHANGE y BOSS_DEATH; la especial no gana un clip real sin asset. Las reacciones y muertes procedurales existentes continúan.

No se han creado bosses de Programación, Inglés, Lenguaje, Ética, Soldadura, Automotriz ni NEXO: no están implementados como actores en esta versión. Hay datos/hooks para incorporarlos después. Tampoco se inventaron sus duelos o mecánicas. Los tamaños actuales se conservan porque están coordinados con sus colisiones; un visual procedural normal ya usa escala 1.5, de modo que ese valor no significa un gigante frente al jugador.

## 9. Expresiones y mirada

LookAtController trabaja sobre Head y limita yaw a 50° y pitch a 22°. Descarta objetivos muy por detrás y vuelve suavemente a neutral. En conversaciones importantes ambos actores reciben el objetivo; al cerrar se libera.

NEUTRAL, HAPPY, ANGRY, WORRIED, SURPRISED y TIRED, más RELIEVED y ALERT, se conservan como estados. El fallback usa variaciones pequeñas de cejas, boca y apertura de ojos. El parpadeo dura 0.16 s con pausas aleatorias de aproximadamente 2.8–6.5 s; se reduce a corta distancia. Un GLB puede implementar los hooks faciales.

## 10. Cámara de diálogo

DialogueCameraController ofrece NORMAL, CLOSE_UP, TWO_SHOT y BOSS_DIALOGUE. Los NPC con misión y los bosses solicitan encuadre; conversaciones ambientales cortas no lo hacen. La cámara interpola durante 0.25 s hacia una aproximación discreta.

Antes de activarla se comprueba el recorrido con una esfera de 0.25 m, el espacio de llegada y la visibilidad del encuadre. Si no cabe, sigue la cámara normal. No mueve físicamente al jugador. Cerrar diálogo o declinar duelo restaura la cámara anterior. Los nombres/textos/opciones siguen en CampaignUI. portrait en NPC queda preparado para un recurso futuro; no se generan retratos.

## 11. Cosméticos

Se reutilizan CharacterAppearance, AppearanceMenu y los desbloqueos existentes. CHEF SET corresponde al delantal existente; LIBRARY SET al polerón de biblioteca; WORKSHOP SET a chaqueta/casco/guantes de taller; TECH SET, SPORT SET y NEXO JACKET añaden detalles visuales.

Punto desbloquea SPORT SET; Redes TECH SET; las recompensas anteriores se conservan. NEXO JACKET se desbloquea con bosses.nexo en una futura integración o al completar el objetivo postgame que actualmente cierra esta campaña. Nunca se equipa automáticamente.

El menú muestra el modelo, rotación, zoom, opciones bloqueadas y un botón para quitar accesorios/mochila/cosmético. Confirmar equipa y guarda; cancelar conserva la selección. Espejo y armario personal están junto a la entrada del piso 1, en (6, 0.1, -4) y (7, 0.1, -4), sin colisiones nuevas. Abren el mismo menú y rechazan uso con combate cercano.

## 12. Optimización

Los materiales de personalización se reutilizan por color/roughness mediante la caché del humanoide; no se duplica un material por cada malla al recolorear. Se conservan los destellos de impacto.

Mismo piso y menos de 16 m: animación secundaria y sombras. Distancia media hasta 35 m: NPC de campaña a intervalos de 0.15 s, sin mirada/parpadeo secundario ni sombras. Otro piso o más lejos: no se anima su rig; comprobación a intervalos de 0.8 s. Los nombres aparecen cerca y los indicadores !/? se consultan desde misiones e inventario existentes. En enemigos no se detiene el reloj de golpes, IA o misiones por aplicar LOD.

No es LOD de polígonos con modelos alternativos: para eso harían falta meshes externos con niveles de detalle.

## 13. Validación y revisión manual

Se ejecutó el proyecto entre etapas mediante godot-mcp-toolkit. La nueva prueba tests/personajes2.gd comprueba reemplazo, fallback, sockets, mirada, expresiones, props, recompensa, cámara libre/bloqueada y conservación de colisión/vida/inventario. Se ejecutan además las regresiones anteriores de personalización, gameplay, inventario, interacciones, celular y campaña.

Resultado final: diez suites sin fallos: personajes2 (59 comprobaciones), personalizacion, gameplay_regression, inventory_regression, contextual_interactions (60), student_phone (31), campaign_regression, revision_scripts (192 scripts/recursos), chef_supremo_casino y director_informatica_boss. Se mantuvieron los aliases antiguos de clips requeridos por inventario.

La regresión detectó que faltaba duel_type = QUIZ en el controlador de la Bibliotecaria en Main.tscn. Se restauró esa propiedad, sin cambiar preguntas, estadísticas ni recompensas. La prueba de campaña se aproxima por el frente del mesón.

Revisar dentro del juego: caminar/correr/frenar, agacharse bajo techos, saltar/aterrizar y escaleras; recoger/equipar/guardar/lanzar; armas grandes y mochila; celular sentado/de pie; hablar/cancelar/iniciar duelo junto a paredes; leer con Bibliotecaria; vencer y recargar un boss; rotar/zoom/equipar/quitar/cancelar cosméticos; guardado/carga y FPS recorriendo pisos.

La revisión manual de clipping, composición de cámara y calidad de las poses sigue siendo necesaria. No se recorrió una partida completa ni se midió rendimiento en un equipo objetivo.

## 14. Recursos útiles después

Un estudiante humano GLB/GLTF con skin y esqueleto válido; clips compatibles de locomoción/combat/interacción/trabajo; ropa modular TOP/BOTTOM/SHOES y cinco peinados reales; sockets de manos/espalda; BlendShapes faciales (o un script adaptador) para expresión/parpadeo; props con pivotes de agarre; variantes de silueta para los bosses que existan; meshes con LOD y licencias de uso adecuadas.

Para IK o ragdoll: rig con nombres/rest poses documentados, cadenas de piernas verificadas y configuración de físicas probada por modelo. Las muertes de bosses deben seguir controladas. No se requieren vídeos externos ni assets de marcas reales.
