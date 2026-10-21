# Guía para crear contenido

## Antes de añadir una instancia

Reutilizar los sistemas existentes. Ejecutar QA, comprobar dependencias y elegir un ID permanente. No cambiar IDs publicados: aparecen en guardados, recompensas y objetivos.

Distribución obligatoria: entrada/casino/Punto en 1; biblioteca/estudio/auditorio en 2; Informática y Telecomunicaciones en 3; salud al norte de 4 y profesores en el sector docente; formación general en 5–8; talleres industriales en -1. El Director de Informática permanece en 8. No deducir una facultad por nombres antiguos de nodos.

Los helpers de scripts/live/content_helpers.gd crean instancias mediante los componentes actuales. No generan automáticamente archivos, campañas, NPC permanentes ni nuevas geometrías al arrancar. Requieren una campaña inicializada. Para edición permanente, crear una escena/recurso en el editor y registrar explícitamente su instanciación; no confundir una instancia de prueba con una escena guardada.

## IDs y validación

Usar nombres estables como npc_apoyo_biblioteca, evento_lectura_01 o boss_nuevo. El registro separa namespaces boss/item/quest/npc/event. Rechaza IDs vacíos, rutas y separadores; informa duplicados. Los helpers comprueban colisiones antes de crear.

QA está disponible en Opciones → Gráficos, ventana, idioma y desarrollo → Herramientas de balance y QA. El reporte local contiene balance y QA; por defecto se guarda en user://campus_balance_report.json. También puede llamarse:

```gdscript
var report = campaign.live.diagnostics.qa.run(campaign)
print(report)
```

QA detecta referencias ausentes, prerequisitos cíclicos, NPC de entrega faltantes, ítems/recompensas inexistentes e IDs duplicados. Las rutas entre puertas, escaleras y objetivos se revisan manualmente: el reporte no demuestra transitabilidad completa ni modifica geometría.

## Crear un NPC

Usar scripts/campaign/npc.gd para NPC de misión existentes y scripts/live/npc_data.gd como datos de autoría. Mantener quest_id enlazado a una definición válida. Su perfil visual se guarda en campaign.data.npc_visuals[npc_id]; no volver a sortear personajes importantes.

```gdscript
var data = preload("res://scripts/live/npc_data.gd").new()
data.npc_id = "npc_apoyo_biblioteca"
data.display_name = "Estudiante"
data.floor = "2"
data.role = "ESTUDIANTE"
data.dialogue = "Podemos estudiar aquí."
var npc = preload("res://scripts/live/content_helpers.gd").create_npc(
    campaign, data, posicion_validada)
```

PROFESOR en piso 4 requiere sector teachers; ENFERMERIA/ODONTOLOGIA requieren piso 4 y sector health; TECNICO corresponde a 3 y TALLER a -1. Los helpers comprueban el piso de la posición, pero no conocen todas las divisiones interiores: validar el sector físicamente.

Para rutinas ya existentes, mantener su propietario. Los eventos solo solicitan presentación mediante set_visual_activity(action, prop); no sustituir navegación ni lógica de misión por el sistema ambiental.

## Crear un boss

Partir de una escena de actor ya compatible, con su BossDuelController. Crear BossData mediante scripts/live/boss_data.gd con boss_id, actor_scene, floor, sector y theme. El helper create_boss(parent, data, posicion_validada) valida ID, temática y presencia del controlador.

Las estadísticas actuales siguen en las propiedades exportadas y scripts del actor. No se han migrado masivamente. Editarlas conscientemente en el actor; el reporte de balance no las cambia.

El actor debe respetar allows_damage(), emitir died una sola vez y usar NEUTRAL → DIALOGUE → INTRO → COMBAT → DEFEATED. Conservar windups, cooldowns y zonas de advertencia. Su escena debe limpiar proyectiles e invocaciones al reiniciar. Probar dos muertes/reintentos, victoria y carga sin duplicar recompensa.

El snapshot pre-duelo lo captura el controlador común al aceptar. No añadir otro inventario ni otro mecanismo de premios.

## Crear un arma

WeaponData ya está representado por scripts/inventory/inventory_item.gd y el catálogo existente. Crear InventoryItem con category ARMA y un weapon_kind/weapon_sport compatible o weapon_data admitido por la fábrica actual. Registrar el recurso mediante ItemCatalog.register_item; revisar antes que su id no exista.

Mantener damage, durability, swing/reach y rareza según la implementación correspondiente. Los modelos especiales pueden usar su script actual. Reutilizar create_weapon y los sockets de CharacterVisual; no añadir daño desde pistas de animación.

El comparador usa los valores de la instancia real. El proyecto no tiene un peso físico universal de armas: aparece sin dato, evitando inventar un modificador de balance.

## Crear una misión

QuestData ya existe como scripts/campaign/quest.gd, un Resource. Configurar quest_id, title, prerequisite, requirements y reward. Integrar con QuestManager; create_quest(campaign, resource) valida el ID y el prerequisito.

Los requisitos usan el bus existente: talk, collect, computer, boss, deliver, floor, secret y door, entre otros ya registrados. Cada objetivo debe tener un emisor y un destino real. Entregar recompensas por campaign.grant_reward(reward, source_id), con source_id estable e idempotente.

No usar un evento ambiental breve como requisito obligatorio del 100% de campaña: puede caducar o no generarse.

## Crear un ClassroomChallenge

Reutilizar AcademicSchedule, AcademicClassPoint y los minijuegos actuales. El reloj único sigue siendo campaign.academics.current_time(). No crear un segundo horario.

La definición académica existente enlaza id, minute, duration, room, floor, posición y site. Un desafío adicional debe llamar un minijuego/handler existente desde ese punto y registrar su resultado en el sistema académico, no desde un figurante ambiental.

EMPTY/CLASS/GROUP_WORK/EXAM/TECH_PROBLEM son estados de presentación en campus_live.classrooms y en el metadato classroom_state de los puntos. No sustituyen asistencia, evaluaciones o recompensas.

## Crear un evento ambiental

EventData es scripts/live/event_data.gd. Crear un recurso .tres y añadirlo a resources/live/campus_live.tres → event_resources. Un ID igual a un evento de catálogo reemplaza sus datos; uno nuevo lo añade.

Ejemplo editable real: resources/live/library_study.tres.

Campos: event_id, title, floors, anchor, sector, action, prop, duration, unique, rare, minimum_anomaly, nexo, ventana horaria, situation y required_flags. Los anchors disponibles son npc, computer, academic, casino, biblioteca, teachers, workshop, elevator y vendor.

Los anchors se resuelven sobre contenido existente, cerca del jugador y con línea de visión. Si no hay uno adecuado, no se genera el evento. Un evento docente usa el recinto de profesores del 4; no trasladar esa reunión al sector sanitario.

unique se guarda al iniciar correctamente. rare usa la probabilidad del director. required_flags consulta decision_flags existentes sin crear otra lógica de decisiones.

Los grupos visuales usan CharacterVisual y props de Personajes 2.0, con un máximo de tres figurantes sin IA de misión ni colisiones. Aprovechan sillas existentes cuando el espacio resulta válido. Se eliminan al caducar, cambiar de piso, entrar en combate o abrir un modal.

Las situaciones voluntarias se conectan a los casos existentes de AmbientSituation. No crear un QuestManager paralelo. Premiar con la función idempotente del evento; el presupuesto total de créditos ambientales es limitado.

## Crear un objeto/pickup

Registrar primero un InventoryItem válido. create_pickup(campaign, world_id, item_id, posicion_validada) utiliza WorldItem/WeaponPickup y el registro collected existente.

Usar un world_id distinto por fuente física y conservarlo al mover una fuente ya publicada. Los objetos clave se protegen; las armas especiales piden confirmación y los favoritos bloquean el descarte accidental. No duplicar una fuente al cargar.

## Crear un diálogo o StoryMoment

Usar CampaignUI.dialog(title, text, choices, callbacks). Todo diálogo importante conserva texto. begin_character_dialogue(actor) reutiliza mirada y cámara segura; close_modal restaura el estado. Las frases ambientales van en cartelas cercanas y no pausan al jugador.

StoryMoment es scripts/live/story_moment.gd. Se ofrece por campaign.live.moments.offer_resource(resource), con ID, título, subtítulo y piso. Se presenta una vez, cuando el director considera segura la zona.

Para enlazar una escena narrativa que ya existe, configurar handler_node relativo a CampusCampaign y existing_handler. El handler recibe el recurso y puede reutilizar cámara, UI y música existentes. Si es asíncrono, debe terminar cuando concluya la escena. El puente mantiene STORY_LOCK durante su ejecución y lo libera al terminar. No construir una segunda historia NEXO dentro del director.

Para secuencias externas al puente:

```gdscript
campaign.live.director.acquire_story_lock("mi_escena")
# Ejecutar y esperar a que concluya la escena existente.
campaign.live.director.release_story_lock("mi_escena")
```

## Configuración, traducción y pruebas

Pacing/eventos: resources/live/campus_live.tres. Gráficos, ventana, FPS e idioma: ajustes del juego, persistidos en user://campus_settings.cfg. La telemetría local es opt-in de desarrollo; no envía datos.

ES es el idioma inicial. campus_localization.gd registra ES/EN y traducciones parciales de interfaz. Añadir pares de mensajes y probar ambos idiomas; no asumir que todo el texto existente ya está traducido.

Ejecutar tests/campus_vivo.gd, las regresiones de campaña/inventario/celular/horario y revision_scripts. Después recorrer el sector, probar bloqueo de eventos, guardado/carga, cancelación, derrota/reintento y resolución. Validar composición, clipping y FPS con renderizado real.
