extends Node
var hub: Node
var tick := 0.0
var previous_objective := ""
var quest_states := {}
var marker_labels: Array[Label3D] = []
const DESTINATIONS := {"Entrada":["1","CheckpointEntrada"],"Biblioteca":["2","CheckpointBiblioteca"],"Piso 3":["3","CentroVida_Piso3"],"Piso 4":["4","CheckpointPiso4"],"Acceso a terraza":["5","CentroVida_Piso5"],"Piso 8":["8","CheckpointPiso8"],"Talleres":["-1","CheckpointSubterráneo"]}
func _ready() -> void:
	previous_objective = hub.campaign.quests.objective_text()
	for id in hub.campaign.quests.definitions: quest_states[id] = hub.campaign.quests.state(id)
func log_entry(title: String, category: String = "event") -> void:
	hub.state.journal.append({"time":hub.campaign.academics.clock_text(),"title":title,"kind":category})
	while hub.state.journal.size() > hub.config.journal_limit: hub.state.journal.pop_front()
func on_event(kind: String, id: String) -> void:
	if kind in ["boss","computer","deliver","secret","card","story"]:
		log_entry({"boss":"Desafío superado: ","computer":"Computador completado: ","deliver":"Entrega completada: ","secret":"Descubrimiento: ","card":"Tarjeta encontrada: ","story":"Acontecimiento: "}[kind]+id,kind)
func record_dialogue(title: String, text: String) -> void:
	if text.is_empty(): return
	var camera = hub.campaign.ui.dialogue_camera
	if camera == null or not is_instance_valid(camera.speaker): return
	var actor = camera.speaker
	var name_value = actor.get("npc_name")
	var controller = actor.get_node_or_null("BossDuelController")
	if controller != null: name_value = controller.boss_name
	if str(name_value).to_lower() != title.to_lower() and not hub.campaign.player.get_meta("important_scene",false): return
	if not hub.state.dialogues.is_empty() and hub.state.dialogues.back().get("text") == text: return
	hub.state.dialogues.append({"time":hub.campaign.academics.clock_text(),"name":title,"text":text.left(4000)})
	while hub.state.dialogues.size() > 20: hub.state.dialogues.pop_front()
func show_journal(dialogue: bool = false) -> void:
	var text := ""
	var entries: Array = hub.state.dialogues if dialogue else hub.state.journal
	for index in range(entries.size()-1,-1,-1):
		var entry: Dictionary = entries[index]
		text += str(entry.get("time",""))+" · "+str(entry.get("name",entry.get("title","")))+"\n"+str(entry.get("text",""))+"\n"
	hub.campaign.ui.dialog("HISTORIAL DE DIÁLOGO" if dialogue else "ACTIVIDAD RECIENTE",text if not text.is_empty() else "Todavía no hay entradas.",["Volver al celular"],[hub.campaign.phone.open],true)
	hub.campaign.ui.page = "phone:history"
	hub.campaign.phone.view.present()
func toggle_contact(id: String) -> void:
	if hub.state.contact_favorites.has(id): hub.state.contact_favorites.erase(id)
	else: hub.state.contact_favorites[id] = true
	hub.campaign.save_game()
	hub.campaign.phone.show_contact(id)
func show_map() -> void:
	var c = hub.campaign
	var text: String = "Piso actual: "+hub.floor_id()+"\n"
	if hub.campaign.quests.state("nexo_final") == 1:
		text += "\nProyecto NEXO · zona aproximada: bahía industrial del sector este del −1.\n"
	for floor_name in ["1","2","3","4","5","6","7","8","-1"]:
		var discovered: bool = hub.state.discoveries.get("floor:"+floor_name,false)
		text += "PISO "+floor_name+" · "+(str(hub.moments.FLOORS.get(floor_name,"Campus")) if discovered else "Área por explorar")+"\n"
	for marker in hub.state.markers: text += "★ "+str(marker.get("text","Volver aquí"))+" · Piso "+str(marker.get("floor",""))+"\n"
	if c.academic_expansion != null: text += c.academic_expansion.map_notes()
	if c.quests != null: text += "\n"+c.quests.objective_text()
	var choices: Array = ["Marcar mi ubicación","Borrar marcadores"]
	var callbacks: Array = [marker_menu,clear_markers]
	if hub.completed():
		for destination in DESTINATIONS:
			if hub.state.discoveries.get("floor:"+DESTINATIONS[destination][0],false):
				if destination == "Acceso a terraza" and not hub.state.discoveries.get("area:terraza",false): continue
				choices.append("Viajar: "+destination)
				callbacks.append(travel.bind(destination))
	choices.append("Cerrar"); callbacks.append(c.ui.close_modal)
	c.ui.dialog("MAPA DEL CAMPUS",text,choices,callbacks,true)
	c.ui.page = "live_map"
func marker_menu() -> void:
	hub.campaign.ui.dialog("MARCADOR","Escribe una nota para esta ubicación.",["Guardar","Volver"],[add_marker.bind("Volver aquí"),show_map],true)
	var input := LineEdit.new()
	input.name = "MarkerNote"; input.max_length = 80; input.placeholder_text = "Volver aquí"
	hub.campaign.ui.column.add_child(input)
	hub.campaign.ui.page = "marker"
func add_marker(fallback: String = "Volver aquí") -> void:
	var input := hub.campaign.ui.column.get_node_or_null("MarkerNote") as LineEdit
	var text := input.text.strip_edges() if input != null else fallback
	if text.is_empty(): text = fallback
	var position: Vector3 = hub.campaign.player.global_position
	hub.state.markers.append({"text":text.left(80),"floor":hub.floor_id(),"position":[position.x,position.y,position.z]})
	while hub.state.markers.size() > 3: hub.state.markers.pop_front()
	hub.campaign.save_game()
	show_map()
func clear_markers() -> void:
	hub.state.markers.clear(); hub.campaign.save_game(); show_map()
func travel(destination: String) -> bool:
	if not DESTINATIONS.has(destination) or not hub.completed(): return false
	var c = hub.campaign
	if c.player.dead or c.active_duel != null or c.manager.minigame.active or hub.director.in_combat() or hub.director.combat_remaining > 0: return false
	if c.ui.modal and c.ui.page not in ["live_map","phone:map"]: return false
	var seat = c.player.get_node("SeatController")
	if is_instance_valid(seat.seat): c.ui.notify("Levántate antes de viajar"); return false
	var row: Array = DESTINATIONS[destination]
	if not hub.state.discoveries.get("floor:"+row[0],false): return false
	if destination == "Acceso a terraza" and not hub.state.discoveries.get("area:terraza",false): return false
	var target := c.get_node_or_null(NodePath(row[1])) as Node3D
	if target == null: return false
	var safe = null
	for offset in [Vector3.ZERO,Vector3(1.5,0,0),Vector3(-1.5,0,0),Vector3(0,0,1.5)]:
		safe = seat.safe_position(target.global_position+offset)
		if safe != null: break
	if safe == null:
		c.ui.notify("No hay espacio seguro de llegada")
		return false
	c.ui.close_modal()
	c.restore_player([safe.x,safe.y,safe.z],c.player.health)
	c.save_game()
	return true
func confirm_discard(callback: Callable, action: String = "soltar") -> void:
	var c = hub.campaign
	c.ui.dialog("ARMA ESPECIAL","¿Quieres "+action+" esta arma especial?",["Conservar","Confirmar"],[c.ui.close_modal,func(): c.ui.close_modal(); callback.call()],true)
func _process(delta: float) -> void:
	tick += delta
	if tick < 2: return
	tick = 0
	var c = hub.campaign
	var objective: String = c.quests.objective_text()
	if objective != previous_objective:
		previous_objective = objective
		log_entry("Misión actualizada: "+objective,"quest")
		if not hub.director.locked() and c.ui.toast_t <= 0: c.ui.notify("MISIÓN ACTUALIZADA\n"+objective,4)
	for id in c.quests.definitions:
		var status: int = c.quests.state(id)
		if quest_states.get(id,status) != status:
			log_entry(c.quests.definitions[id].title+" · "+["Disponible","Activa","Completada","Fallida"][clampi(status,0,3)],"quest")
		quest_states[id] = status
