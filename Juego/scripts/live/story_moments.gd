extends Node
const Moment = preload("res://scripts/live/story_moment.gd")
var hub: Node
var queue: Array[Resource] = []
var tick := 0.0
const FLOORS := {"1":"ENTRADA · PUNTO ESTUDIANTIL · CASINO","2":"BIBLIOTECA · ESTUDIO · AUDITORIO","3":"INFORMÁTICA Y TELECOMUNICACIONES","4":"SALUD · SECTOR DOCENTE","5":"FORMACIÓN GENERAL · TERRAZA","6":"FORMACIÓN GENERAL","7":"FORMACIÓN GENERAL","8":"FORMACIÓN GENERAL · DIRECCIÓN","-1":"TALLERES TÉCNICOS E INDUSTRIALES"}
func _ready() -> void:
	if not hub.campaign.loaded_save: offer("arrival","BIENVENIDO AL CAMPUS","Explora a tu ritmo.","1")
	for key in hub.campaign.events:
		if str(key).begins_with("floor:") and int(hub.campaign.events[key]) > 0:
			var floor_name := str(key).trim_prefix("floor:")
			if floor_name == "S": floor_name = "-1"
			hub.state.discoveries["floor:"+floor_name] = true
func offer(id: String, title: String, subtitle: String, floor_name: String = "") -> void:
	if hub.state.moments.get(id,false): return
	for item in queue:
		if item.moment_id == id: return
	var moment := Moment.new()
	moment.moment_id = id; moment.title = title; moment.subtitle = subtitle; moment.floor = floor_name
	if queue.size() < 16: queue.append(moment)
func discover(id: String, title: String, floor_name: String = "") -> void:
	if hub.state.discoveries.get(id,false): return
	hub.state.discoveries[id] = true
	offer("discover:"+id,title,"Área descubierta",floor_name)
	hub.campaign.save_game()
func on_event(kind: String, id: String) -> void:
	if kind == "floor":
		var floor_name := "-1" if id == "S" else id
		discover("floor:"+floor_name,"PISO "+floor_name+"\n"+str(FLOORS.get(floor_name,"CAMPUS")),floor_name)
		if floor_name == "8": offer("floor8","DIRECCIÓN","Has llegado al piso 8.","8")
		if floor_name == "-1": offer("basement","TALLERES","Zona técnica e industrial.","-1")
	elif kind == "area": discover("area:"+id,id.to_upper(),hub.floor_id())
	elif kind == "boss":
		offer("first_boss","PRIMER DESAFÍO SUPERADO","El campus toma nota de tu avance.",hub.floor_id())
		if id == "bibliotecaria": discover("area:biblioteca","BIBLIOTECA","2")
		if id == "chef": discover("area:casino","CASINO","1")
	elif kind == "story" and id.begins_with("nexo"): offer("nexo_discovery","SEÑALES INUSUALES","Algo está cambiando en las pantallas.",hub.floor_id())
	elif kind == "secret" and id in ["archivo_subterraneo","computador_subterraneo"]:
		offer("server","ARCHIVO DESCUBIERTO","Consulta el registro del campus.","-1")
	if hub.completed(): offer("ending","CAMPUS RESTABLECIDO","Puedes seguir explorando y visitar las áreas descubiertas.")
func _process(delta: float) -> void:
	tick += delta
	if tick < 1: return
	tick = 0
	var position: Vector3 = hub.campaign.player.global_position
	if hub.floor_id() == "5" and Rect2(-84,-121,168,30).has_point(Vector2(position.x,position.z)):
		discover("area:terraza","TERRAZA","5")
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		if duel.boss_id == "director" and duel.actor.global_position.distance_to(position) < 10:
			discover("area:direccion","DIRECCIÓN","8")
	if hub.director.locked() or hub.director.in_combat() or hub.director.combat_remaining > 0: return
	if hub.campaign.ui.toast_t > 0 or queue.is_empty(): return
	for index in queue.size():
		var moment := queue[index]
		if not moment.floor.is_empty() and moment.floor != hub.floor_id(): continue
		if hub.state.moments.get(moment.moment_id,false):
			queue.remove_at(index); return
		hub.state.moments[moment.moment_id] = true
		if hub.event_active(): hub.events.finish()
		queue.remove_at(index)
		hub.campaign.ui.notify(moment.title+"\n"+moment.subtitle,4)
		if hub.reactive != null: hub.reactive.discovery_sound()
		hub.director.activity()
		hub.campaign.save_game()
		if not moment.existing_handler.is_empty(): run_existing_handler(moment)
		return

func offer_resource(moment: Resource) -> bool:
	if moment.get_script() != Moment or moment.moment_id.is_empty() or hub.state.moments.get(moment.moment_id,false): return false
	for item in queue:
		if item.moment_id == moment.moment_id: return false
	queue.append(moment)
	return true

func run_existing_handler(moment: Resource) -> void:
	var handler := hub.campaign.get_node_or_null(moment.handler_node) as Node
	if handler == null or not handler.has_method(moment.existing_handler): return
	hub.director.acquire_story_lock("moment:"+moment.moment_id)
	await handler.call(moment.existing_handler,moment)
	if is_instance_valid(hub): hub.director.release_story_lock("moment:"+moment.moment_id)
