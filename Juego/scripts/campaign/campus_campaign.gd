extends Node3D
signal gameplay_event(kind: String, id: String, amount: int)
var live: Node
var final_area: Node3D
var save_blocked_reason := ""
var last_save_succeeded := false
var save_failure_notified := false
## Orquesta sistemas existentes. No reconstruye ni mueve piezas del edificio.
@export_range(1,10) var implementation_phase := 10
@export var persist := true
@export var save_path := "user://campus_campaign_v1.json"
var player: CharacterBody3D
var manager: Node
var ui: CanvasLayer
var active_duel: Node
var ready_for_play := false
var data: Dictionary = {"version":1,"academics":{},"phone":{},"appearance":{},"npc_visuals":{},"cosmetics":{},"stationery":{},"events":{},"inventory":{},"position":[0,0.2,0],"health":100.0,"floor":"1","bosses":{},"quests":{},"collected":{},"remaining_quantity":{},"secrets":{},"cards":{},"unlocks":{},"credits":0,"xp":0,"upgrades":{},"stats":{},"achievements":{},"notes":{},"computers":{},"checkpoint":{"position":[0,0.1,0],"health":100},"tutorial":false}
var events: Dictionary = {}
var quests: Node
var quest_ui: Node
var inventory_snapshot: Dictionary = {}
var defaults: Dictionary = {}
var loaded_save := false
var autosave_t := 0.0
var floor_current := ""
var audio: Node
var polish: Node
var last_level := 0
var booting := true
var guidance: Node
var restarting := false
var appearance_menu: Node
var pending_appearance: Dictionary = {}
var phone: Node
var academics: Node
var academic_expansion: Node

func show_personalization(new_run: bool = false) -> void:
	appearance_menu.open(new_run)

func refresh_visual_rewards() -> void:
	preload("res://scripts/juego/character_appearance.gd").unlock_from_progress(data.bosses,data.cosmetics)
	# Keep previously unlocked cosmetics; new unlock requires the actual finale.
	if data.get("campaign_completed",false) or data.bosses.get("nexo",false):
		data.cosmetics["nexo_jacket"] = true

func _ready() -> void:
	add_to_group("campus_campaign")
	call_deferred("_boot")

func _boot() -> void:
	manager = get_parent().get_node_or_null("GameplayManager")
	if manager == null:
		return
	player = manager.player
	defaults = preload("res://scripts/live/save_migration.gd").migrate(data)
	data["save_version"] = 2
	data["campus_live"] = {}
	if persist and FileAccess.file_exists(save_path):
		var loaded = preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(save_path)
		if loaded is Dictionary and preload("res://scripts/live/save_migration.gd").supported(loaded):
			loaded_save = true
			for key in data:
				if loaded.has(key):
					if typeof(loaded[key]) == typeof(data[key]):
						data[key] = loaded[key]
					elif data[key] is int and (loaded[key] is float or loaded[key] is int):
						data[key] = int(loaded[key])
			for key in loaded:
				if not data.has(key): data[key] = loaded[key]
		elif not loaded.is_empty():
			persist = false
			player.persist_inventory = false
			player.inventory.persist = false
			save_blocked_reason = "Guardado de una versión posterior: escritura desactivada para conservarlo."
	data = preload("res://scripts/live/save_migration.gd").migrate(data)
	for pair in [["pc5","ENGLISH_PREPARED"],["pc6","LECTURA_PREPARADA"],["pc7","REFLEXION_PREVIA"],["pc8","NEXO_INFORMATION"]]:
		data.unlocks[pair[1]] = data.computers.get(pair[0],false)
	var appearance_profile = preload("res://scripts/juego/character_appearance.gd")
	refresh_visual_rewards()
	appearance_profile.unlock_from_progress(data.bosses,data.cosmetics)
	data.appearance = appearance_profile.normalize(data.appearance,data.cosmetics)
	player.body.apply_appearance(data.appearance)
	appearance_menu = preload("res://scripts/campaign/appearance_menu.gd").new()
	appearance_menu.campaign = self
	appearance_menu.name = "Personalizacion"
	add_child(appearance_menu)
	events = data.events
	var legacy_registry := get_parent().get_node_or_null("Piso8/EncuentroDirectorInformatica/CredencialDirector")
	if not loaded_save and legacy_registry and legacy_registry.acquired:
		data.bosses["director"] = true
		events["boss:director"] = 1
	if loaded_save and implementation_phase >= 6:
		if not data.inventory.is_empty():
			player.inventory.restore_snapshot(data.inventory)
		if data.stationery is Dictionary and not data.stationery.is_empty():
			player.stationery_notes = str(data.stationery.get("notes",""))
			player.stationery_inventory = data.stationery.get("items",{}).duplicate()
			player.equip_stationery(str(data.stationery.get("equipped","")))
	ui = load("res://scripts/campaign/campaign_ui.gd").new()
	ui.name = "CampaignUI"
	ui.campaign = self
	add_child(ui)
	academics = preload("res://scripts/campaign/academic_schedule.gd").new()
	academics.name = "HorarioAcademico"
	academics.campaign = self
	add_child(academics)
	phone = preload("res://scripts/campaign/student_phone.gd").new()
	phone.name = "CelularEstudiante"
	phone.campaign = self
	add_child(phone)
	var interaction = load("res://scripts/campaign/interaction_controller.gd").new()
	interaction.name = "InteractionController"
	interaction.campaign = self
	player.add_child(interaction)
	if implementation_phase >= 2:
		load("res://scripts/campaign/campus_content.gd").weapons(self)
	if implementation_phase >= 3:
		quests = load("res://scripts/campaign/quest_manager.gd").new()
		quests.campaign = self
		add_child(quests)
		quest_ui = load("res://scripts/campaign/quest_ui.gd").new()
		quest_ui.campaign = self
		add_child(quest_ui)
		_capture_inventory()
		player.inventory.changed.connect(_inventory_changed)
		manager.minigame.finished.connect(_computer_finished)
	if implementation_phase >= 4:
		load("res://scripts/campaign/campus_content.gd").npcs_and_computers(self)
	if implementation_phase >= 5:
		setup_access()
	if implementation_phase >= 6:
		setup_checkpoints()
		player.died.connect(_on_player_died)
		if loaded_save:
			if implementation_phase >= 9:
				apply_upgrades()
			restore_player(data.position,float(data.health))
	if implementation_phase >= 7:
		load("res://scripts/campaign/campus_content.gd").collectibles(self)
	if implementation_phase >= 8:
		var combat = load("res://scripts/campaign/player_combat.gd").new()
		combat.name = "CombatExtensions"
		player.add_child(combat)
	if implementation_phase >= 9:
		load("res://scripts/campaign/campus_content.gd").progression_content(self)
		grant_reward({"credits":30},"welcome")
		apply_upgrades()
		player.weapon_broke.connect(_weapon_broken)
	if implementation_phase >= 10:
		audio = get_node_or_null("ZoneAudio")
		if audio == null:
			audio = load("res://scripts/campaign/campus_audio.gd").new()
			audio.campaign = self
			add_child(audio)
		polish = load("res://scripts/campaign/campus_polish.gd").new()
		polish.campaign = self
		add_child(polish)
	await get_tree().physics_frame
	stabilize_content()
	load("res://scripts/campaign/furniture_pickup.gd").setup(self)
	var seating = preload("res://scripts/juego/player_seating.gd").new()
	seating.name = "SeatController"
	player.add_child(seating)
	preload("res://scripts/campaign/seat_interactable.gd").setup(self)
	preload("res://scripts/campaign/appearance_station.gd").setup(self)
	var upper_bosses = preload("res://scripts/campaign/upper_campus_bosses.gd").new()
	upper_bosses.name = "UpperCampusBosses"; upper_bosses.campaign = self
	add_child(upper_bosses)
	await upper_bosses.setup()
	academic_expansion = preload("res://scripts/campaign/academic_expansion.gd").new()
	academic_expansion.name = "AcademicExpansion"
	academic_expansion.campaign = self
	add_child(academic_expansion)
	await academic_expansion.setup()
	gameplay_event.connect(academic_expansion.on_event)
	academic_expansion.setup_director_tasks()
	guidance = load("res://scripts/campaign/mission_guidance.gd").new()
	guidance.name = "GuiaObjetivo"
	guidance.campaign = self
	add_child(guidance)
	booting = false
	ready_for_play = true
	live = preload("res://scripts/live/campus_live.gd").new()
	live.name = "CampusVivo"
	live.campaign = self
	add_child(live)
	final_area = preload("res://scripts/pisos/piso_menos_1/nexo_final_area.gd").new()
	final_area.name = "NexoFinalArea"
	final_area.campaign = self
	final_area.position = Vector3(48,load("res://scripts/campaign/campus_content.gd").HEIGHTS[8]+0.04,-100)
	get_parent().get_node("PisoMenos1").add_child(final_area)
	phone.restore_known_contacts()
	academic_expansion.recover_rewards()
	var education_gate := preload("res://scripts/education/academic_floor_gate.gd").new()
	education_gate.name = "AcademicFloorGate"
	education_gate.campaign = self
	add_child(education_gate)
	if persist and not get_window().close_requested.is_connected(save_game):
		get_window().close_requested.connect(save_game)
	if implementation_phase >= 6 and persist:
		if get_tree().get_meta("campaign_new_game",false):
			get_tree().remove_meta("campaign_new_game")
		else:
			if get_tree().has_meta("education_entry"):
				var entry := str(get_tree().get_meta("education_entry"))
				get_tree().remove_meta("education_entry")
				if entry == "new": call_deferred("_confirm_new_game")
			else:
				call_deferred("show_start_menu")

func save_game() -> void:
	if player == null or not persist or booting:
		return
	data.events = events
	data.stationery = {"notes":player.stationery_notes,"items":player.stationery_inventory,"equipped":player.equipped_stationery}
	data.inventory = player.inventory.snapshot_data()
	var seating := player.get_node_or_null("SeatController")
	var save_position: Vector3 = seating.save_position() if seating else player.global_position
	data.position = [save_position.x,save_position.y,save_position.z]
	data.health = player.health
	var error := _write_save_payload(save_payload())
	last_save_succeeded = error == OK
	if error != OK:
		_report_save_failure(error)
		return
	save_failure_notified = false
	if player.persist_inventory:
		player.inventory.save_data()
		player.save_stationery()

func _write_save_payload(payload: Dictionary) -> Error:
	var temporary := save_path + ".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	# Reutilizar el respaldo de Nueva partida. Nunca borrar el destino antes
	# del reemplazo: si falla, quedan el original, el respaldo y el temporal.
	if FileAccess.file_exists(save_path):
		error = DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path),ProjectSettings.globalize_path(save_path+".bak"))
		if error != OK:
			return error
	return _replace_save_file(temporary,save_path)

func _replace_save_file(temporary: String, destination: String) -> Error:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(destination))

func _report_save_failure(error: Error) -> void:
	push_error("No se pudo guardar la campaña en %s: %s. Se conservan los archivos recuperables." % [save_path,error_string(error)])
	if not save_failure_notified and is_instance_valid(ui):
		ui.notify("No se pudo guardar la partida.")
		save_failure_notified = true

func save_payload() -> Dictionary:
	# A loaded duel always resumes neutral. Persist its approach and resources,
	# never a half-finished fight; the live retry snapshot remains temporary.
	if live != null and not live.retry.snapshot.is_empty():
		var retry = live.retry
		var fighting: bool = is_instance_valid(active_duel) and active_duel == retry.duel and active_duel.state in [active_duel.DuelState.INTRO,active_duel.DuelState.COMBAT]
		if fighting or (player.dead and retry.can_retry()):
			var payload: Dictionary = retry.snapshot.get("campaign_data",data).duplicate(true)
			payload.inventory = retry.snapshot.inventory.duplicate(true)
			payload.position = retry.snapshot.position.duplicate()
			payload.health = retry.snapshot.health
			payload.checkpoint = data.checkpoint.duplicate(true)
			return payload
	return data

func event(kind: String, id: String, amount: int = 1) -> void:
	var key := kind+":"+id
	events[key] = int(events.get(key,0))+amount
	if kind == "collect":
		data.stats.items_collected = int(data.stats.get("items_collected",0))+amount
	if kind == "secret":
		data.secrets[id] = true
	if kind == "card" and not data.cards.has(id):
		data.cards[id] = true
		grant_reward({"credits":5,"xp":10},"card:"+id)
		if data.cards.size() >= 20:
			grant_reward({"items":{"ExtintorDorado":1},"credits":200,"xp":300},"all_cards")
			ui.notify("¡20 tarjetas! Recompensa: Extintor Dorado")
	if quests:
		quests.refresh()
	refresh_visual_rewards()
	if phone:
		phone.on_event(kind,id)
	gameplay_event.emit(kind,id,amount)

func boss_won(controller: Node) -> void:
	if data.bosses.get(controller.boss_id,false):
		return
	data.bosses[controller.boss_id] = true
	if preload("res://scripts/juego/character_appearance.gd").unlock_from_progress(data.bosses,data.cosmetics):
		ui.notify("Cosmético desbloqueado · Pausa → PERSONALIZACIÓN")
	if not controller.reward.is_empty():
		give_reward_item(controller.reward,1)
	grant_reward({"credits":75,"xp":150},"boss:"+controller.boss_id)
	if controller.boss_id == "chef":
		give_reward_item("LlaveCasino",1)
	if controller.boss_id == "director":
		give_reward_item("TecladoAdministrador",1)
	event("boss",controller.boss_id)
	player.body.set_expression("RELIEVED")
	active_duel = null
	apply_upgrades()
	player.heal(player.max_health)
	ui.notify("BOSS DERROTADO · VIDA COMPLETA\n%s · Recompensa: %s" % [controller.boss_name,controller.reward])
	save_game()
func grant_reward(reward: Dictionary, source: String) -> void:
	if data.unlocks.get("reward:"+source,false):
		return
	data.unlocks["reward:"+source] = true
	data.credits += int(reward.get("credits",0))
	data.xp += int(reward.get("xp",0))
	for item in reward.get("items",{}):
		give_reward_item(item,int(reward.items[item]))
	if source.begins_with("quest:") and source.trim_prefix("quest:") in ["llaves","cargador","documentos","implementos","infectado","casino"] and player.inventory.has_item("InsigniaDeOratoria",1):
		grant_reward({"items":{"Comida":1}},"oratoria:"+source)
	if reward.has("unlock"):
		data.unlocks[str(reward.unlock)] = true

func _capture_inventory() -> void:
	inventory_snapshot.clear()
	for entry in player.inventory.entries:
		inventory_snapshot[entry.item_id] = int(inventory_snapshot.get(entry.item_id,0))+int(entry.quantity)

func _inventory_changed() -> void:
	if live != null and live.restoring_inventory:
		_capture_inventory()
		return
	var before := inventory_snapshot.duplicate()
	_capture_inventory()
	for id in inventory_snapshot:
		var added := int(inventory_snapshot[id])-int(before.get(id,0))
		if added > 0:
			event("collect",id,added)
	save_game()

func _computer_finished(success: bool) -> void:
	# El gestor original limpia la referencia antes de emitir al siguiente receptor.
	if not success:
		return
	for pc in get_tree().get_nodes_in_group("computer"):
		var id := str(pc.get_meta("campaign_id",pc.get_path()))
		if pc.done and not data.computers.get(id,false):
			data.computers[id] = true
			var preparation := {"pc5":"ENGLISH_PREPARED","pc6":"LECTURA_PREPARADA","pc7":"REFLEXION_PREVIA","pc8":"NEXO_INFORMATION"}
			if preparation.has(id): data.unlocks[preparation[id]] = true
			event("computer",id)
			grant_reward({"credits":20,"xp":25},"computer:"+id)
			if id == "pc_secreto":
				grant_reward({"items":{"USBMaestro":1},"unlock":"archivo_digital"},"secret_computer")
				event("secret","computador_subterraneo")
				ui.notify("Archivo secreto desbloqueado: USB Maestro")
	save_game()

func _process(_delta: float) -> void:
	if not ready_for_play:
		return
	update_status(_delta)

func _input(event_input: InputEvent) -> void:
	if not ready_for_play or not event_input is InputEventKey or not event_input.pressed or event_input.echo:
		return
	var key: int = event_input.physical_keycode if event_input.physical_keycode != 0 else event_input.keycode
	if key == KEY_P:
		if not phone.toggle():
			return
	elif key == KEY_ESCAPE:
		if ui.modal:
			if player.dead:
				return
			var duel = active_duel
			if duel and duel.state == duel.DuelState.DIALOGUE:
				duel.decline()
			else:
				ui.close_modal()
		elif not player.busy and not player.dead:
			show_pause()
		else:
			return
	elif key == KEY_M and ui.modal and ui.page == "quests":
		ui.close_modal()
	elif key == KEY_M and not player.busy and not player.dead and quest_ui:
		quest_ui.show_quests()
	elif key == KEY_TAB and not player.busy and not player.dead:
		show_map()
	elif key == KEY_B and not player.busy and not player.dead:
		show_codex()
	elif key == KEY_U and not player.busy and not player.dead:
		show_upgrades()
	elif key == KEY_F and not player.busy and not player.dead and player.equipped_stationery.is_empty() and not player.stationery_notes.is_empty():
		player.body.play_context_action("read")
		ui.dialog("APUNTES",player.stationery_notes,["Cerrar"],[ui.close_modal],true)
	else:
		return
	get_viewport().set_input_as_handled()

func floor_unlocked(floor_name: String) -> bool:
	return floor_name == "1" or bool(data.unlocks.get(floor_name,false)) or implementation_phase < 5

func setup_access() -> void:
	for row in [[7,"Sala805","TarjetaAcceso","acceso7"],[8,"Sala805","TarjetaAcceso","direccion"],[8,"Sala806","CredencialDirector","especial8"]]:
		var door := get_parent().get_node_or_null("Piso%d/PasilloReferencia/%s/PuertaSala" % [row[0],row[1]])
		if door == null:
			continue
		var gate = load("res://scripts/campaign/locked_access.gd").new()
		gate.name = "CampaignAccess"
		gate.required_id = row[2]
		gate.access_id = row[3]
		door.add_child(gate)
	for elevator in get_parent().get_node("SistemasCompartidos/AscensoresEstudiantiles").get_children():
		if not elevator.has_method("request_floor"):
			continue
		for i in 9:
			var call_button = load("res://scripts/campaign/elevator_interaction.gd").new()
			call_button.name = "CampaignCall%d" % i
			call_button.elevator = elevator
			call_button.landing = i
			elevator.add_child(call_button)
			call_button.position = Vector3(0,elevator.LEVELS[i],9)
		var inside_button = load("res://scripts/campaign/elevator_interaction.gd").new()
		inside_button.name = "CampaignFloorMenu"
		inside_button.elevator = elevator
		elevator.cabin.add_child(inside_button)
		inside_button.position = Vector3(0,0.2,0)
func setup_checkpoints() -> void:
	var content = load("res://scripts/campaign/campus_content.gd")
	for row in [["Entrada",0,0,-4],["Biblioteca",1,-40,-114],["Casino",0,-40,-102],["Piso4",3,20,-143],["Piso8",7,25,-131],["Subterráneo",8,25,-143]]:
		var checkpoint = load("res://scripts/campaign/checkpoint.gd").new()
		checkpoint.name = "Checkpoint"+row[0]
		checkpoint.checkpoint_id = row[0]
		add_child(checkpoint)
		checkpoint.global_position = content.point(row[1],row[2],row[3])

func restore_player(position_value: Array, health_value: float) -> void:
	if position_value.size() != 3:
		return
	player.dead = false
	player.busy = false
	player.velocity = Vector3.ZERO
	player.stun_t = 0
	player.punch_cd = 0
	player.global_position = Vector3(float(position_value[0]),float(position_value[1])+0.15,float(position_value[2]))
	player.health = clampf(health_value,1,player.max_health)
	player.body.dead = false
	player.body.death_t = 0
	player.body.fall_pivot.rotation = Vector3.ZERO
	player.body.fall_pivot.position = Vector3.ZERO
	player.body.hurt_t = 0
	player.body.punch_p[0] = -1
	player.body.punch_p[1] = -1
	player.health_changed.emit(player.health,player.max_health)
	manager.cam_pivot = player.global_position+Vector3.UP*1.4
	manager.msg_label.hide()

func _on_player_died() -> void:
	if live != null: live.retry.on_death()
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		if duel.state in [duel.DuelState.COMBAT,duel.DuelState.INTRO,duel.DuelState.DIALOGUE]:
			duel.reset_duel()
	call_deferred("_death_menu")

func _death_menu() -> void:
	manager.msg_label.hide()
	if live != null and live.retry.can_retry():
		var final_duel: bool = live.retry.duel.boss_id == "nexo"
		ui.dialog("NEXO · REINTENTAR" if final_duel else "HAS CAÍDO","Puedes restaurar vida, consumibles, arma y durabilidad al estado previo al duelo.",["REINTENTAR NEXO" if final_duel else "REINTENTAR BOSS","Reintentar desde checkpoint","Volver al menú"],[live.retry.retry_boss,respawn,_death_to_menu],true)
		return
	ui.dialog("HAS CAÍDO","Conservas todos tus objetos y el progreso conseguido.",["Reintentar desde checkpoint","Volver al menú"],[respawn,_death_to_menu],true)

func respawn() -> void:
	ui.close_modal()
	restore_player(data.checkpoint.position,float(data.checkpoint.health))
	if live != null:
		live.retry.failed = false
		live.retry.snapshot.clear()
		live.retry.duel = null
	save_game()

func _death_to_menu() -> void:
	respawn()
	show_start_menu()

func show_start_menu() -> void:
	if get_tree().get_meta("education_enabled",false):
		save_game()
		ui.close_modal()
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/education/StudentMainMenu.tscn")
		return
	manager.cam.global_position = player.global_position+Vector3(0,3,5)
	manager.cam.look_at(player.global_position+Vector3.UP*1.4)
	ui.dialog("DUOCGAMES","Explora el campus, completa misiones y supera los duelos.",["Continuar","Nueva partida"],[ui.close_modal,_confirm_new_game],true)
	if not save_blocked_reason.is_empty(): ui.notify(save_blocked_reason,12)

func _confirm_new_game() -> void:
	ui.dialog("NUEVA PARTIDA","Reinicia progreso e inventario de esta partida. Se conservará una copia de la campaña anterior.",["Comenzar nueva partida","Cancelar"],[show_personalization.bind(true),show_start_menu],true)

func new_game() -> void:
	if restarting:
		return
	restarting = true
	# Recargar después de que el botón termine de emitir su señal.
	call_deferred("_restart_game")

func _restart_game() -> void:
	var fresh := defaults.duplicate(true)
	# La aparición inicial del gestor está a 2 m; 0.2 m puede quedar dentro del suelo.
	fresh.appearance = preload("res://scripts/juego/character_appearance.gd").normalize(pending_appearance,{})
	fresh.position = [0,2,0]
	fresh.checkpoint = {"position":[0,2,0],"health":100}
	fresh.inventory = {"version":1,"entries":[],"quick":["","","",""],"serial":0,"equipped":""}
	fresh.stationery = {"items":{},"notes":"","equipped":""}
	# No usar save_game(): capturaría el jugador y los objetivos anteriores.
	if persist:
		var write_error := _write_save_payload(fresh)
		last_save_succeeded = write_error == OK
		if write_error != OK:
			restarting = false
			_report_save_failure(write_error)
			return
		save_failure_notified = false
	ui.close_modal()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Evitar que la escena saliente sobrescriba la partida recién creada.
	booting = true
	player.persist_inventory = false
	player.inventory.persist = false
	get_tree().set_meta("campaign_new_game",true)
	var reload_error := get_tree().reload_current_scene()
	if reload_error != OK:
		booting = false
		restarting = false
		get_tree().remove_meta("campaign_new_game")
		ui.notify("No se pudo reiniciar la escena: "+error_string(reload_error))
func enemy_defeated(enemy: Node) -> void:
	if enemy.has_meta("campaign_rewarded"):
		return
	enemy.set_meta("campaign_rewarded",true)
	data.stats.enemies = int(data.stats.get("enemies",0))+1
	data.credits += 5
	data.xp += 10
	event("enemy",str(enemy.name))
	if not enemy.died.is_connected(manager._on_enemy_died):
		manager.kills += 1
	manager._update_counters()
	save_game()

func _weapon_broken(_title: String) -> void:
	data.stats.weapons_broken = int(data.stats.get("weapons_broken",0))+1

func apply_upgrades() -> void:
	var level := 1+int(data.xp/150)
	player.max_health = 100+(level-1)*5+int(data.upgrades.get("Vida",0))*20
	player.health = minf(player.health,player.max_health)
	player.progression_damage = 1.0+int(data.upgrades.get("Fuerza",0))*0.05
	player.progression_speed = 1.0+int(data.upgrades.get("Velocidad",0))*0.05
	var combat := player.get_node_or_null("CombatExtensions")
	if combat:
		combat.max_stamina = 100+int(data.upgrades.get("Resistencia",0))*20
	player.inventory.max_entries = 64+int(data.upgrades.get("Mochila",0))*16
	player.health_changed.emit(player.health,player.max_health)

func show_upgrades() -> void:
	var choices: Array = []
	var callbacks: Array = []
	for id in ["Vida","Resistencia","Mochila","Fuerza","Velocidad"]:
		var price := 60+int(data.upgrades.get(id,0))*40
		choices.append("%s · nivel %d · %d créditos" % [id,int(data.upgrades.get(id,0)),price])
		callbacks.append(_buy_upgrade.bind(id,price))
	choices.append("Cerrar")
	callbacks.append(ui.close_modal)
	ui.dialog("MEJORAS","Nivel %d · XP %d · Créditos %d" % [1+int(data.xp/150),data.xp,data.credits],choices,callbacks,true)

func _buy_upgrade(id: String, price: int) -> void:
	if data.credits < price:
		ui.notify("Créditos insuficientes.")
		return
	if int(data.upgrades.get(id,0)) >= 5:
		ui.notify("Mejora al máximo.")
		return
	data.credits -= price
	data.upgrades[id] = int(data.upgrades.get(id,0))+1
	apply_upgrades()
	save_game()
	show_upgrades()
func update_status(delta: float) -> void:
	if not get_tree().paused and not player.dead:
		data.stats.time_played = float(data.stats.get("time_played",0))+delta
	var heights = load("res://scripts/campaign/campus_content.gd").HEIGHTS
	var nearest := 0
	for i in heights.size():
		if absf(player.global_position.y-heights[i]) < absf(player.global_position.y-heights[nearest]):
			nearest = i
	var number := str(nearest+1) if nearest<8 else "S"
	if floor_current != number:
		floor_current = number
		data.floor = number
		event("floor",number)
		if live == null: ui.notify("PISO "+number+" · "+floor_title(number))
	if quests:
		var objective_value: String = "OBJETIVO ACTUAL\n"+quests.objective_text()
		if guidance: objective_value += "\n"+guidance.hint
		objective_value += "\nPISO %s · Nivel %d · Créditos %d · Tarjetas %d/20" % [number,1+int(data.xp/150),data.credits,data.cards.size()]
		if ui.objective.text != objective_value: ui.objective.text = objective_value
	var level := 1+int(data.xp/150)
	if implementation_phase >= 9 and level != last_level:
		last_level = level
		apply_upgrades()
	autosave_t += delta
	if autosave_t >= 30 and not player.dead and not ui.modal and not is_instance_valid(active_duel):
		autosave_t = 0
		check_achievements()
		save_game()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_signal("died") and not enemy.has_node("BossDuelController") and not enemy.died.is_connected(enemy_defeated):
			enemy.died.connect(enemy_defeated)
	for group in ["computer","weapon_pickup","inventory_pickup","stationery_vendor"]:
		for node in get_tree().get_nodes_in_group(group):
			for property in ["prompt","label"]:
				var label = node.get(property)
				if label is Label3D:
					label.hide()
	for elevator in get_parent().get_node("SistemasCompartidos/AscensoresEstudiantiles").get_children():
		var hint = elevator.get("_ui")
		if hint is Label:
			hint.hide()

func floor_title(number: String) -> String:
	return preload("res://scripts/live/story_moments.gd").FLOORS.get("-1" if number == "S" else number,"CAMPUS")

func show_pause() -> void:
	ui.dialog("PAUSA","DuocGames",["Continuar","Guía de juego","Inventario","Misiones","Mejoras","Registro","Mapa","Opciones","Controles","PERSONALIZACIÓN","Volver al menú"],[ui.close_modal,show_guide,_open_inventory,quest_ui.show_quests,show_upgrades,show_codex,show_map,show_options,show_controls,show_personalization,show_start_menu],true)

func show_guide() -> void:
	var text: String = "AHORA: "+quests.objective_text() if quests else "Explora el campus."
	text += "\n\n1. PISO 1: recoge un objeto, habla con el Encargado de Punto Estudiantil y acepta su duelo. Completa el computador cercano a la entrada y vence también al Chef del casino. Los bosses se activan al aceptar el desafío con E."
	text += "\n\n2. PISO 2: busca tres libros en la biblioteca y supera las preguntas de la Bibliotecaria."
	text += "\n\n3. PISOS 3 A 6: completa los computadores de cada piso. Habla con el Profesor del piso 3, acepta Documentos importantes y entrega los documentos al Funcionario del piso 5: necesitas su TarjetaAcceso."
	text += "\n\n4. PISO 7: usa la tarjeta en la sala restringida y completa el computador. PISO 8: resuelve el computador y vence al Director para conseguir su credencial."
	text += "\n\n5. SUBTERRÁNEO: encuentra el archivo secreto para terminar la campaña. Puedes seguir buscando tarjetas, apuntes y misiones secundarias."
	text += "\n\nM muestra misiones y cantidades; Tab muestra los pisos. E interactúa cuando aparece el aviso. El ascensor desbloquea destinos al completar etapas; las escaleras permiten explorar antes. I abre la mochila, U permite comprar mejoras. Activa checkpoints fuera de duelos para reaparecer cerca si caes."
	ui.dialog("GUÍA DE JUEGO",text,["Ver misiones","Volver"],[quest_ui.show_quests,show_pause],true)

func _open_inventory() -> void:
	ui.close_modal()
	player.inventory_ui.open_inventory()

func show_controls() -> void:
	ui.dialog("CONTROLES","WASD mover · Shift correr · C agacharse · Espacio saltar\nE interacción · I inventario · 1–4 barra rápida · F apuntes\nJ / clic ataque · mantener clic ataque fuerte · Alt esquiva · Q lanzar\nP celular · M misiones · Tab mapa · B registro · U mejoras · Esc pausa",["Volver"],[show_pause],true)

func show_map() -> void:
	if live != null and live.qol != null:
		live.qol.show_map()
		return
	var text := "Piso actual: "+floor_current+"\nAscensores: núcleo central, Z=-148\nCheckpoint: "+str(data.checkpoint.get("id","Entrada"))+"\n\n"
	for number in ["S","1","2","3","4","5","6","7","8"]:
		text += "PISO %s · %s · %s\n" % [number,floor_title(number),"Ascensor disponible" if floor_unlocked(number) else "Ascensor bloqueado"]
	if quests:
		text += "\nObjetivo: "+quests.objective_text()
	ui.dialog("MAPA DEL CAMPUS",text,["Cerrar"],[ui.close_modal],true)

func show_codex() -> void:
	var text := "BOSSES\n"
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		text += duel.boss_name+" · "+("Derrotado" if data.bosses.get(duel.boss_id,false) else "Pendiente")+"\n"
	text += "\nOBJETOS Y ARMAS\n"
	for entry in player.inventory.entries:
		text += entry.item_id+" ×"+str(entry.quantity)+"\n"
	text += "\nCOLECCIONABLES: %d/20\nSECRETOS: %s\nLOGROS: %s\nESTADÍSTICAS: %s" % [data.cards.size(),str(data.secrets.keys()),str(data.achievements.keys()),str(data.stats)]
	for note in data.notes.values(): text += "\n\n"+str(note)
	ui.dialog("REGISTRO",text,["Cerrar"],[ui.close_modal],true)

func check_achievements() -> void:
	var checks := {"PRIMER DÍA":int(data.stats.get("time_played",0))>5,"LECTOR":data.bosses.get("bibliotecaria",false),"ADMINISTRADOR":data.bosses.get("director",false),"HACKER":data.computers.size()>=8,"EXPLORADOR":data.secrets.size()>=5}
	var weapons: Dictionary = {}
	for key in events:
		if str(key).begins_with("collect:"):
			var id := str(key).trim_prefix("collect:")
			var definition = load("res://scripts/inventory/item_catalog.gd").get_item(id)
			if definition and definition.category == 1:
				weapons[id] = true
	checks["ARSENAL"] = weapons.size()>=10
	for id in checks:
		if checks[id] and not data.achievements.get(id,false):
			data.achievements[id] = true
			ui.notify("Logro: "+id)

func show_options() -> void:
	if live != null and live.settings != null:
		var settings_button := Button.new()
		settings_button.text = "Gráficos, ventana, idioma y desarrollo"
		settings_button.pressed.connect(live.settings.show_options)
		call_deferred("_append_settings_button",settings_button)
	ui.dialog("OPCIONES","Números de daño y audio configurables. Los slots de audio están preparados para tus archivos.",["Alternar números de daño","Alternar sonido","Volver"],[_toggle_numbers,_toggle_sound,show_pause],true)

func _toggle_numbers() -> void:
	if polish:
		polish.show_damage_numbers = not polish.show_damage_numbers

func _append_settings_button(button: Button) -> void:
	if ui.modal: ui.column.add_child(button)
	else: button.queue_free()

func _toggle_sound() -> void:
	AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))

func duck_ambient(enabled: bool) -> void:
	if audio:
		audio.duck(enabled)

func throw_distraction() -> bool:
	var id := "Bebida" if player.inventory.has_item("Bebida") else "hoja_impresa"
	if not player.inventory.has_item(id):
		return false
	player.inventory.remove_items(id,1)
	var object = load("res://scripts/campaign/distraction.gd").new()
	object.shooter = player
	add_child(object)
	object.global_position = player.global_position+Vector3.UP*1.5+player.body.forward()*0.7
	object.velocity = player.body.forward()*8+Vector3.UP*2
	return true
func stabilize_content() -> void:
	var world := get_world_3d().direct_space_state
	var excluded: Array[RID] = [player.get_rid()]
	for actor in find_children("*","CharacterBody3D",true,false):
		excluded.append(actor.get_rid())
	var shape := CapsuleShape3D.new()
	shape.radius = 0.46
	shape.height = 2.7
	for node in get_children():
		if not node is Node3D or node is AudioStreamPlayer3D:
			continue
		if node.get_script() == null:
			continue
		if not (node.has_method("interaction_text") or node.has_method("collect") or node is CharacterBody3D or node.is_in_group("campus_checkpoint")):
			continue
		var origin: Vector3 = node.global_position
		var located := false
		for radius_index in range(0,7):
			if located:
				break
			for step in range(1 if radius_index == 0 else 12):
				var angle := step*TAU/12
				var point := origin+Vector3(sin(angle),0,cos(angle))*float(radius_index)
				var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP*1.2,point+Vector3.DOWN*0.6)
				ray.exclude = excluded
				var hit := world.intersect_ray(ray)
				if hit.is_empty() or hit.normal.y < 0.9 or absf(hit.position.y-origin.y)>0.5:
					continue
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = shape
				query.transform.origin = hit.position+Vector3.UP*1.42
				query.exclude = excluded
				query.margin = 0.001
				if not world.intersect_shape(query,1).is_empty():
					continue
				if node.has_method("placement_clear") and not node.placement_clear(world,hit.position,excluded):
					continue
				node.global_position = hit.position+Vector3.UP*0.10
				if node.has_method("ground_visuals"):
					node.ground_visuals(hit.position.y)
				if node is CharacterBody3D:
					node.home = node.global_position
					node.patrol_target = node.home
				node.set_meta("placement_validated",true)
				located = true
				break
		if not located:
			node.set_meta("placement_validated",false)
			push_warning("Revisar posición de contenido: "+str(node.name))
func give_reward_item(id: String, quantity: int) -> void:
	# Una recompensa nunca se pierde por falta de espacio.
	var previous_capacity: int = player.inventory.max_entries
	player.inventory.max_entries = 0
	player.receive_item(id,quantity)
	player.inventory.max_entries = previous_capacity
