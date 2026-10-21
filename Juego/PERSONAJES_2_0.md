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

## Ampliación de ropa y bosses de acción — 16-10-2026

Esta sección actualiza el estado anterior; no se importaron modelos humanos reales. La estructura y API body, WeaponSocket, ItemSocket y BackpackSocket se conservan. Player sigue separado del rig: movimiento, cápsula, cámara, vida, inventario y misiones no se reprograman al instalar un modelo compatible.

Cambios de proporción concretos: el refuerzo del torso pasa de radio superior 0,175/ancho ×1,12 a 0,16/×1,04; ojos de radio 0,014 a 0,011 y pupilas de 0,007 a 0,0055. Se conservan longitud de piernas/brazos, altura, pivotes y cápsula para no desajustar puertas/escaleras/asientos/alcance. Palmas aplanadas, transiciones, respiración, mirada, parpadeo y balanceo de mochila anteriores se reutilizan. El resultado sigue siendo estilizado, no anatomía fotorealista.

Ropa modular: TOP, BOTTOM, SHOES, BACKPACK, HEAD_ACCESSORY y ACCESSORY. TOP conserva Polera/Polerón como índices 0/1 y añade Camisa, Sweater, Chaqueta, uniforme clínico ficticio y Overol. bottom_style añade casual/jeans/formal/trabajo; shoe_style zapatillas/zapatos/botas; backpack_color permite elegir color. Prendas de manga larga se distribuyen sobre hombros y codos articulados; cuello, solapas, costuras, bolsillos y accesorios se construyen sobre el rig existente. Se usa el cache _mat por color/roughness; cambiar ropa retira los extras anteriores y conserva sockets/arma. Las categorías se registran en module_parts y visual_module. Las categorías cosméticas no cambian estadísticas.

Cabellos existentes compatibles: SHORT_1, SHORT_2, MEDIUM_1, LONG_1 y CURLY_1, además de sin cabello; se mantienen los índices históricos (incluido Sin cabello = 2). Rizado añade volúmenes pequeños. Son aproximaciones procedurales. Menú existente: preview, rotar, zoom, confirmar/equipar y quitar accesorios/mochila/cosmético; ahora también tipos de ropa/calzado, color de mochila y accesorio de cabeza. La ropa elegida por el jugador nunca cambia al desbloquear un premio.

Perfiles estables: estudiantes con ropa casual/jeans y combinaciones por ID; profesores con camisa/sweater/chaqueta y zapatos; funcionarios con ropa de oficina y credencial; técnico con mochila/dispositivo; presets ficticios de Salud y taller preparados para sus sectores oficiales. No se agregan nuevos NPC de Salud/taller en pisos incompatibles. Los presets guardados de NPC se migran una sola vez a wardrobe_version 2, preservando piel, cabello y colores, y se guardan en npc_visuals. Los bosses nuevos también usan esa persistencia.

Inglés: ropa académica, audífonos y tablet. Lenguaje: prenda académica y libro. Ética: colores sobrios y carpeta/escritura. Director: chaqueta, credencial, tablet y escala visual 1,2, con cápsula previa intacta. Cada profesor tiene escala 1,15. Chef/Punto/Bibliotecaria/Redes conservan sus rasgos existentes. Premios nuevos desbloquean audífonos, bolso del escritor e insignia; Director añade dispositivo cosmético. Son opciones del menú, nunca equipamiento automático.

Animación: se conservan IDLE/WALK/RUN/CROUCH/CROUCH_WALK/JUMP/FALL/LAND, ataques, lanzamiento, esquiva, hit/muerte, interacción/recogida, celular/computador, sentarse y diálogo. Se añaden estados BOSS_IDLE/INTRO/MELEE/RANGED/SPECIAL/PHASE/HIT/DEATH, TALK y CROSS_ARMS. Block/Parry son soporte visual, no nuevas mecánicas. Los golpes direccionales reutilizan react_to_hit; un GLB puede mapear HIT_FRONT/LEFT/RIGHT/HEAVY y si falta el clip se mantiene HIT procedural. Se conserva la emisión de punch_landed del host: los clips importados no deben duplicar daño.

AnimationTree del fallback contiene reservas sin pistas y permanece inactivo; el movimiento real procedural sigue en humanoid/student_visual. Un GLB válido activa el adaptador existente con BlendSpace1D (0/2,5/5,5) y crossfade 0,12 s; JUMP→FALL→LAND tiene transiciones directas de 0,1 s cuando existen esos clips. Si falta un clip para la acción actual se muestra de nuevo el rig procedural y se restauran los sockets. No se afirma que existan animaciones humanas capturadas.

LOD: animaciones secundarias, parpadeo/mirada e idles se limitan cerca; distancia media usa actualizaciones visuales básicas; lejos/u otro piso se reduce el tick visual y se ocultan props secundarios. No se detienen misiones ni temporización de ataques. Los idles quedan bloqueados durante combate/duelos, interacción importante, daño, armas en guardia o movimiento. Se reutiliza DialogueCameraController con comprobación de obstáculos y restauración de cámara/mirada; los diálogos ambientales pequeños siguen sin cámara especial.

### GLB/GLTF: flujo de integración

1. Añadir localmente un GLB/GLTF con licencia adecuada; no se descarga automáticamente. Origen en pies, frente −Z, escala compatible, sin colisiones de gameplay ni root motion que mueva al Player.
2. Verificar MeshInstance3D con skin, Skeleton3D con huesos y AnimationPlayer. Los Skeleton3D de reserva actuales no tienen huesos funcionales.
3. Crear sockets de manos y espalda con BoneAttachment3D/Marker3D; pasar los paths relativos mediante bindings al adaptador existente. IDLE/WALK/RUN y sockets de arma/objeto son obligatorios; el modelo se rechaza sin perder el fallback si faltan.
4. Usar install_imported_visual(packed_scene, clips, bindings), como en el ejemplo anterior. Mapear también estados de boss y hits direccionales si hay clips reales. El modelo puede ofrecer apply_appearance(profile), set_gaze, set_blink y set_expression.
5. Probar armas, teléfono, mochila, agacharse, saltar, caída, muerte y reintento. Mantener desactivados ragdoll/Foot IK hasta validar el esqueleto concreto.

Para realismo superior faltan: mallas humanas anatómicas riggeadas, cabello con geometría/texturas adecuadas, prendas skinned compatibles con el mismo esqueleto, zapatos/mochilas/accesorios ajustados, materiales PBR de piel/tela/cabello y clips humanos reales (locomoción, agacharse, saltar/caer/aterrizar, combate/lanzamiento/esquiva, impactos/muerte, sentarse, hablar, trabajar y poses/ataques de boss). Opcionalmente blend shapes faciales. Nada de esto se inventa como asset existente.

Bosses/configuración/progresión/ventajas y límites: BOSSES_SUPERIORES_2_0.md. Playtest humano pendiente en PLAYTEST_1_0.md.
### Validación de esta ampliación

Godot 4.7.2, mediante godot-mcp-toolkit y ejecutable del editor (sin depender de PATH). Preview de nueve roles: sin fallos. Suite nueva UpperCampusCheck: 104 comprobaciones, sin fallos; nueve muestras transitables por arena, neutralidad/aceptación, fases 60/30, proyectiles/zonas con límites y sin daño anticipado, ventajas, elección física A/B, reintento real, premios únicos, guardado/carga, identidad/ropa, LOD y compatibilidad de etapas completadas.

Regresiones aprobadas y verificadas por marcador final del log: personajes (70), personalización, campaña, inventario, gameplay, Director, Chef 350, Campus Vivo (52), balance (20), nueva partida, NEXO (111), interacciones (60), recogidas parciales/guardado previo (74) y carga de 236 scripts/recursos. Logs tests/upper_*.log; los errores deliberados de fixture de escritura no se confunden con errores de partida. No basta el código de salida del ejecutable gráfico de Windows.

Medición orientativa headless: frame 120 a 5133 ms, 377,69 MiB de memoria estática, 45120 nodos; no es FPS gráfico ni comparación controlada con versiones anteriores. Una muestra estabilizada de la fixture renderizada en Piso 5 dio 19 FPS, 58,14 ms de proceso/2,81 ms de física y ~2132 MiB tras dos cargas de Main. Esa muestra no certifica rendimiento general ni 60 FPS: hace falta profiler/recorrido humano con hardware, resolución/calidad y memoria GPU controlados. La muestra de 1 FPS registrada justo al recargar corresponde al pico de carga, no al combate jugable.

Capturas MCP revisaron variantes de ropa y presentación neutral de Inglés. La apariencia continúa procedural/estilizada; no se afirma realismo fotográfico. Quedan manuales todos los casos añadidos al checklist: caminar/saltar/escaleras/armas, ropa y apariencia al cargar, NPC sentados, cámara, combate real con/sin preparación, rutas/puertas/arenas, muerte/reintento mediante UI, lectura de telegraphs, dificultad y FPS. Ninguna casilla humana se marca PASS.
## OPTIMIZACIÓN + PERSONAJES REALISTAS 3.0 — 16-10-2026

Diagnóstico y datos crudos en PERFORMANCE_PROFILE.md y reports/performance_*.json. En la misma fixture renderizada (dos cargas de Main, cámara frente al profesor de Inglés), el coste demostrado más grande corresponde a sombras: alcance de LuzExterior reducido de 100 m a 40/30/20 m según ALTO/MEDIO/BAJO, manteniendo sombras cercanas. No se certifica 60 FPS en todo el juego ni se atribuye el problema a IA sin medición.

FloorActivityManager clasifica visuales registrados cada 0,35 s: LOD0 completo; LOD1 a intervalos de 0,12 s; LOD2 a 0,5 s; SLEEP sin rig secundario ni AnimationTree importado. Piso actual FULL, vecino REDUCED, más de 18 m verticales SLEEP; distancia también limita. El protagonista, intro/combate, daño/impactos y caída de muerte tienen excepciones. Los enemigos normales de otros pisos omiten percepción/movimiento; no se detienen misiones, horarios, guardado ni interacción. Al volver se recalcula LOD inmediatamente. No había NavigationAgent3D que desactivar.

Geometría procedural idéntica comparte Mesh; materiales permanecen por actor para no propagar flash de daño/personalización. Expresiones y apertura de ojos solo escriben cambios; blink usa Timer pausado por LOD. HUD de objetivo se compone una vez y solo se asigna si cambia. Se conservan el escaneo contextual, las sillas recogibles y sus colisiones.

GLB conserva install_imported_visual(scene, clips, bindings): valida asset/rig/clips/sockets antes de reemplazar, acepta aliases de clips, bindings por rutas o huesos con BoneAttachment3D, HairSocket/HeadAccessorySocket, caché de sockets, blendshapes opcionales y hooks de mirada/parpadeo. Sin clip/modelo válido usa fallback procedural visible. Perfiles internos preparados: student_male/student_female, professor, staff, health, workshop, boss_english, boss_language, boss_ethics, director; no imponen género ni cambian apariencia ya guardada. CHARACTER_HIGH/MEDIUM/LOW se corresponden con ajustes existentes; materiales PBR reales requieren assets adecuados, no se inventan.

MODELO HUMANO EXTERNO NECESARIO. Sin GLB/GLTF/FBX humano encontrado; no se descarga nada. Consultar HUMAN_MODEL_IMPORT.md. Las pruebas sintéticas validan contrato, no realismo humano. Ropa skinned y retargeting se preparan en una escena importada mediante el flujo documentado, sin simulación compleja.

No se agregan bosses/misiones ni se cambia balance: Chef 350, Inglés 450, Lenguaje 500, Ética 550, Director 700 HP; daño, economía y recompensas se conservan. Se mantienen caps existentes de proyectiles/zonas y dos virus. Una protección explícita evita Firewall duplicado. FIX demostrado: una zona sin objetivo vivo ya no conserva su callback indefinidamente; expira y detiene procesamiento antes de liberarse.
