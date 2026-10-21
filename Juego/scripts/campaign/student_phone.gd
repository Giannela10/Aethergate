class_name StudentPhone
extends Node
## Acceso a sistemas existentes. No contiene misiones, mapas ni recompensas propios.
const MAX_MESSAGES := 200
var campaign: Node
var state: Dictionary
var notification_pending := false
var notification_timer := 0.0
var view: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	state = campaign.data.phone
	for key in ["contacts","received"]:
		if not state.get(key) is Dictionary:
			state[key] = {}
	if not state.get("messages") is Array:
		state.messages = []
	var cleaned: Array = []
	for message in state.messages:
		if message is Dictionary and message.get("id") is String and message.get("sender") is String and message.get("text") is String:
			message["read"] = message.get("read",false) == true
			cleaned.append(message)
	state.messages = cleaned.slice(maxi(0,cleaned.size()-MAX_MESSAGES))
	for id in state.contacts.keys():
		if not state.contacts[id] is Dictionary:
			state.contacts.erase(id)
	notification_pending = unread_count() > 0
	view = preload("res://scripts/campaign/phone_view.gd").new()
	view.campaign = campaign
	view.name = "PhoneView"
	add_child(view)

func toggle() -> bool:
	if campaign.ui.modal and campaign.ui.page.begins_with("phone:"):
		campaign.ui.close_modal()
		return true
	if not campaign.player.busy and not campaign.player.dead and campaign.active_duel == null and not campaign.manager.minigame.active:
		open()
		return true
	return false

func open() -> void:
	if campaign.player.dead or campaign.active_duel != null or campaign.manager.minigame.active:
		return
	campaign.ui.dialog("CELULAR DEL ESTUDIANTE","Campus · "+str(unread_count())+" mensajes sin leer",
		["MAPA","MISIONES","MENSAJES","CONTACTOS","NEXO","COLECCIONABLES","ESTADÍSTICAS","AJUSTES","Cerrar"],
		[app.bind("map"),app.bind("quests"),messages,contacts,app.bind("nexo"),app.bind("collectibles"),app.bind("stats"),app.bind("settings"),campaign.ui.close_modal],true)
	campaign.ui.page = "phone:home"
	if campaign.live != null:
		for entry in [["ACTIVIDAD RECIENTE",false],["HISTORIAL DE DIÁLOGO",true]]:
			var button := Button.new()
			button.text = entry[0]
			button.pressed.connect(campaign.live.qol.show_journal.bind(entry[1]))
			campaign.ui.column.add_child(button)
	campaign.player.body.show_phone(true)
	view.home()

func app(id: String) -> void:
	match id:
		"schedule":
			campaign.academics.show_schedule()
			return
		"map": campaign.show_map()
		"quests":
			if campaign.quest_ui:
				campaign.quest_ui.show_quests()
			else:
				open()
				return
		"settings": campaign.show_options()
		"nexo","collectibles","stats":
			# El registro actual ya contiene apuntes, coleccionables y estadísticas.
			campaign.show_codex()
	campaign.ui.page = "phone:"+id
	var back := Button.new()
	back.text = "Volver al celular"
	back.pressed.connect(open)
	campaign.ui.column.add_child(back)
	view.present()

func unread_count() -> int:
	var total := 0
	for message in state.messages:
		if not message.read:
			total += 1
	return total

func messages() -> void:
	var choices: Array = []
	var actions: Array = []
	for index in range(state.messages.size()-1,-1,-1):
		var message: Dictionary = state.messages[index]
		var contact: Dictionary = state.contacts.get(message.sender,{})
		choices.append(("* " if not message.read else "")+str(contact.get("name",message.sender))+" · "+message.text.left(48))
		actions.append(read_message.bind(str(message.id)))
	choices.append("Volver al celular")
	actions.append(open)
	campaign.ui.dialog("MENSAJES","Sin mensajes todavía." if state.messages.is_empty() else "Selecciona un mensaje. * indica sin leer.",choices,actions,true)
	campaign.ui.page = "phone:messages"
	view.present()

func read_message(id: String) -> void:
	for message in state.messages:
		if message.id == id:
			message.read = true
			var sender: Dictionary = state.contacts.get(message.sender,{})
			campaign.ui.dialog(str(sender.get("name",message.sender)),message.text,["Volver a mensajes"],[messages],true)
			campaign.ui.page = "phone:message"
			view.present()
			campaign.save_game()
			return

func contacts() -> void:
	var choices: Array = []
	var actions: Array = []
	for id in state.contacts:
		choices.append(str(state.contacts[id].get("name",id)))
		actions.append(show_contact.bind(str(id)))
	choices.append("Volver al celular")
	actions.append(open)
	campaign.ui.dialog("CONTACTOS","Solo aparecen personas que ya conociste.",choices,actions,true)
	campaign.ui.page = "phone:contacts"
	view.present()

func show_contact(id: String) -> void:
	if not state.contacts.has(id):
		return
	var contact: Dictionary = state.contacts[id]
	var progress := "Conocido"
	var quest_id: String = contact.get("quest","")
	if not quest_id.is_empty() and campaign.quests:
		progress = "Encargo completado" if campaign.quests.state(quest_id) == 2 else ("Encargo activo" if campaign.quests.state(quest_id) == 1 else "Conocido")
	var latest := "Sin mensajes"
	for index in range(state.messages.size()-1,-1,-1):
		if state.messages[index].sender == id:
			latest = state.messages[index].text
			break
	var text := "Rol: %s\nPiso habitual: %s\nProgreso: %s\n\nÚltimo mensaje:\n%s" % [contact.get("role","Contacto del campus"),contact.get("floor","—"),progress,latest]
	if campaign.academic_expansion != null and campaign.player.inventory.has_item("MapaDocente",1) and campaign.academic_expansion.actors.has(id):
		text += "\nSector aproximado: "+str(preload("res://scripts/campaign/academic_expansion_data.gd").BOSSES.get(id,{}).get("sector","formación general"))
	campaign.ui.dialog(str(contact.get("name",id)),text,["Volver a contactos"],[contacts],true)
	campaign.ui.page = "phone:contact"
	if campaign.live != null:
		var favorite := Button.new()
		favorite.text = "★ Quitar favorito" if campaign.live.state.contact_favorites.get(id,false) else "☆ Marcar favorito"
		favorite.pressed.connect(campaign.live.qol.toggle_contact.bind(id))
		campaign.ui.column.add_child(favorite)
	view.present()

func register_contact(id: String, display_name: String, role: String, floor_name: String, quest: String = "") -> bool:
	if id.is_empty() or state.contacts.has(id):
		return false
	state.contacts[id] = {"name":display_name,"role":role,"floor":floor_name,"quest":quest}
	return true

func send_message(id: String, sender: String, text: String) -> bool:
	if id.is_empty() or text.is_empty() or not state.contacts.has(sender) or state.received.get(id,false):
		return false
	state.received[id] = true
	state.messages.append({"id":id,"sender":sender,"text":text,"read":false,"time":int(campaign.data.stats.get("time_played",0))})
	if state.messages.size() > MAX_MESSAGES:
		state.messages.pop_front()
	notification_pending = true
	campaign.save_game()
	return true

func on_event(kind: String, id: String) -> void:
	if kind != "talk":
		if kind in ["deliver","computer","boss","door"]:
			refresh_progress_messages()
		return
	var npc: Node = campaign.get_node_or_null(NodePath(id)) if not id.contains("/") and not id.contains(":") and not id.contains(".") else null
	if npc and npc.get_script() == preload("res://scripts/campaign/npc.gd"):
		var floor_name := _floor_for(npc)
		var role := "Estudiante"
		if id in ["Profesor","Funcionario","Tecnico","Auxiliar","MonitorDeportes","AyudanteCasino"]:
			role = id
		if register_contact(id,npc.npc_name,role,floor_name,npc.quest_id):
			send_message("welcome:"+id,id,"Ya tienes mi contacto. "+npc.dialogue)
		return
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		if duel.boss_id == id and register_contact(id,duel.boss_name,"Responsable de desafío",_floor_for(duel.get_parent())):
			send_message("welcome:"+id,id,"Ya tienes mi contacto. Puedes consultar tu progreso en el registro del campus.")
			return

func _floor_for(actor: Node3D) -> String:
	var heights: Array = preload("res://scripts/campaign/campus_content.gd").HEIGHTS
	var nearest := 0
	for index in heights.size():
		if absf(actor.global_position.y-float(heights[index])) < absf(actor.global_position.y-float(heights[nearest])):
			nearest = index
	return "-1" if nearest == 8 else str(nearest+1)

func restore_known_contacts() -> void:
	# Refresh known academic contact locations without resetting messages.
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		if state.contacts.has(duel.boss_id):
			state.contacts[duel.boss_id]["name"] = duel.boss_name
			state.contacts[duel.boss_id]["floor"] = _floor_for(duel.get_parent())
	for key in campaign.events.keys():
		if str(key).begins_with("talk:") and int(campaign.events[key]) > 0:
			on_event("talk",str(key).trim_prefix("talk:"))
	refresh_progress_messages()

func refresh_progress_messages() -> void:
	if not campaign.quests:
		return
	for id in state.contacts:
		var quest: String = str(state.contacts[id].get("quest",""))
		if not quest.is_empty() and campaign.quests.state(quest) == 2:
			var definition = campaign.quests.definitions.get(quest)
			if definition:
				send_message("quest:completed:"+quest+":"+str(id),str(id),"Gracias por tu ayuda con «"+definition.title+"». Tu progreso ya está registrado.")

func _process(delta: float) -> void:
	if not notification_pending or not campaign.ready_for_play or get_tree().paused:
		return
	notification_timer -= delta
	if notification_timer > 0:
		return
	notification_timer = 1.0
	if campaign.player.busy or campaign.player.dead or campaign.active_duel != null or campaign.ui.modal or campaign.manager.minigame.active:
		return
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node3D and enemy.get("dead") != true and enemy.global_position.distance_squared_to(campaign.player.global_position) < 144:
			return
	if campaign.ui.toast_t > 0:
		return
	campaign.ui.notify("NUEVO MENSAJE · P: celular")
	notification_pending = false
