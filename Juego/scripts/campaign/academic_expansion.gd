class_name AcademicExpansion
extends Node
const Data = preload("res://scripts/campaign/academic_expansion_data.gd")
var campaign: Node
var actors: Dictionary = {}
var failures: Array[String] = []
var stage_limit := 7
var ready_for_play := false
var task_nodes: Array[Node3D] = []
var network_step := 0
var calculator_tick := 0.0
var calculator_label: Label3D
var state: Dictionary
func _ready() -> void:
	state = campaign.data.academic_expansion
func setup() -> void:
	for id in Data.BOSSES:
		var row: Dictionary = Data.BOSSES[id]
		if row.floor == 4 and stage_limit < 5: continue
		if row.floor == 7 and stage_limit < 7: continue
		var config = load("res://scripts/campaign/academic_boss_config.gd").new()
		config.boss_id = id; config.display_name = row.name; config.floor_number = row.floor
		config.role = row.role; config.max_health = row.hp; config.reward = ""
		config.computer_id = "pc3" if row.floor == 3 else ("pc4" if row.floor == 4 else "pc6")
		config.preparation_flag = "PREPARED:"+id
		var placement := find_arena(row.floor,row.seeds)
		if placement.is_empty():
			failures.append("Sin arena segura: "+id)
			push_error(failures.back())
			continue
		var actor = load("res://scripts/campaign/academic_action_boss.gd").new()
		actor.config = config; actor.name = id
		var floor_node = campaign.get_parent().get_node("Piso"+str(row.floor))
		actor.position = floor_node.to_local(placement.position)
		floor_node.add_child(actor)
		actor.objective_positions.assign(placement.points)
		actor.placement_valid = true
		actor.set_meta("placement_validated",true)
		actor.duel.intro_text = "Vamos a ver cómo reaccionas bajo presión. Un desafío ficticio de acción y movimiento."
		actors[id] = actor
	# Existing actors retain IDs, controller specialization, resource configs and rewards.
	for actor in campaign.get_node("UpperCampusBosses").actors.values():
		var points := arena_points(actor.home)
		actor.objective_positions.assign(points)
		if points.size() < 4:
			failures.append("Faltan objetivos seguros: "+actor.config.boss_id)
			actor.placement_valid = false
		actors[actor.config.boss_id] = actor
	ready_for_play = true
func arena_points(center: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var seat = campaign.player.get_node("SeatController")
	for offset in [Vector3(-4,0,0),Vector3(4,0,0),Vector3(-2,0,-2),Vector3(2,0,2),Vector3(-6,0,0),Vector3(6,0,0),Vector3(0,0,-3),Vector3(0,0,3)]:
		var safe = seat.safe_position(center+offset)
		if safe == null or absf(safe.y-center.y) > 0.5: continue
		if points.any(func(p): return p.distance_to(safe) < 2): continue
		var ray := PhysicsRayQueryParameters3D.create(center+Vector3.UP,safe+Vector3.UP,1,[campaign.player.get_rid()])
		if not campaign.player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		points.append(safe)
		if points.size() == 4: break
	return points
func find_arena(floor_number: int, seeds: Array) -> Dictionary:
	var height: float = load("res://scripts/campaign/campus_content.gd").HEIGHTS[floor_number-1]
	for seed in seeds:
		var p = campaign.player.get_node("SeatController").safe_position(Vector3(seed[0],height+0.12,seed[1]))
		if p == null or absf(p.y-height) > 0.5: continue
		var overlap := false
		for duel in get_tree().get_nodes_in_group("boss_duel"):
			if duel.actor.global_position.distance_to(p) < 16: overlap = true
		if overlap: continue
		var points := arena_points(p)
		if points.size() >= 4: return {"position":p,"points":points}
	return {}
func boss_missing(id: String, visit: bool = false) -> String:
	if id == "coordinador_profesores":
		if visit:
			campaign.quests.start_quest("ubicar_profesores")
			campaign.event("talk",id)
		var missing := coordinator_missing()
		if not missing.is_empty(): return "Antes del duelo, ubica a estos docentes:\n"+missing
		if visit:
			state.flags["coordinator_returned"] = true
			campaign.event("academic_return","coordinador")
		if not state.flags.get("coordinator_returned",false): return "Regresa al coordinador de la Sala de Profesores."
	if id == "director" and visit:
		for task in ["director_task_network","director_task_antivirus","director_task_config"]: campaign.quests.start_quest(task)
	if id == "director" and not campaign.data.bosses.get("director",false) and director_count() < 3:
		return "Pruebas del Director: %d/3\nRevisa los puntos informáticos señalizados del piso 8: conexión, antivirus y configuración." % director_count()
	return ""
func setup_director_tasks() -> void:
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		if duel.boss_id == "director":
			duel.boss_name = "Director de Carrera de Ingeniería Informática"
			duel.identity_label.text = duel.boss_name+"\n[E] Hablar y aceptar desafío"
	var height: float = load("res://scripts/campaign/campus_content.gd").HEIGHTS[7]
	var seats = campaign.player.get_node("SeatController")
	for i in 5:
		var position_value = seats.safe_position(Vector3(-25-i*7,height+0.12,-133))
		if position_value == null:
			failures.append("Punto Director sin espacio: "+str(i))
			continue
		var point: Node3D
		if i == 1:
			point = load("res://scripts/juego/computer.gd").new()
			point.name = "director_antivirus"
			point.game_id = 1
			point.set_meta("campaign_id","director_antivirus")
			point.set_meta("floor",8)
		else:
			point = load("res://scripts/campaign/director_task_point.gd").new()
			point.expansion = self
			point.task_id = "director_task_network" if i == 0 else "director_task_config"
			point.index = maxi(0,i-2)
			point.name = "DirectorConnection" if i == 0 else "DirectorPC0"+str(i-1)
		campaign.add_child(point)
		point.global_position = position_value
		task_nodes.append(point)
		if i == 1 and state.flags.get("director_task_antivirus",false): point.set_done()
	campaign.manager.task_count = get_tree().get_nodes_in_group("computer").size()
	campaign.manager.tasks_done = get_tree().get_nodes_in_group("computer").filter(func(pc): return pc.done).size()
	campaign.manager._update_counters()
func open_task(id: String, index: int = 0) -> void:
	if state.flags.get(id,false): return
	campaign.quests.start_quest(id)
	if id == "director_task_network":
		var steps: Array = ["Revisar equipo","Revisar cable","Revisar adaptador","Reiniciar conexión"]
		var hint := "\nLlave de datos: sigue equipo → cable → adaptador → conexión." if campaign.player.inventory.has_item("LlaveDeDatos",1) else ""
		campaign.ui.dialog("PC SIN CONEXIÓN","Paso %d/4: %s.%s" % [network_step+1,steps[network_step],hint],[steps[network_step],"Volver"],[network_next,campaign.ui.close_modal],true)
	elif id == "director_task_config":
		var hint := "\nLlave de datos: compara las tres etiquetas de red." if campaign.player.inventory.has_item("LlaveDeDatos",1) else ""
		campaign.ui.dialog("CONFIGURACIÓN DE RED","PC01: Red A\nPC02: Red A\nPC03: Red B\nEquipo revisado: PC0%d. Identifica y corrige el diferente.%s" % [index+1,hint],["Corregir este equipo","Volver"],[select_config.bind(index),campaign.ui.close_modal],true)
func network_next() -> void:
	network_step += 1
	if network_step >= 4:
		complete_task("director_task_network")
		network_step = 0
		campaign.ui.close_modal()
	else: open_task("director_task_network")
func select_config(index: int) -> void:
	campaign.ui.close_modal()
	if index == 2: complete_task("director_task_config")
	else: campaign.ui.notify("Este equipo coincide con la red de referencia. Compara los otros equipos.")
func complete_task(id: String) -> void:
	if state.flags.get(id,false): return
	state.flags[id] = true
	for point in task_nodes:
		if point.get("task_id") == id: point.set_done()
	campaign.event("academic_task",id)
	campaign.ui.notify("Pruebas del Director: %d/3" % director_count())
	if director_count() == 3: campaign.ui.notify("Prueba informática completada.")
	campaign.save_game()
func coordinator_missing() -> String:
	var missing: Array[String] = []
	for id in ["profesor_algoritmos","profesor_ingles","profesor_matematicas"]:
		if not state.seen.get(id,false):
			missing.append({"profesor_algoritmos":"Algoritmos · piso 3 · sector de Informática","profesor_ingles":"Inglés · piso 6 · formación general","profesor_matematicas":"Matemáticas · piso 7 · formación general"}[id])
	return "\n".join(missing)
func director_count() -> int:
	var count := 0
	for id in ["director_task_network","director_task_antivirus","director_task_config"]:
		if state.flags.get(id,false): count += 1
	return count
func on_event(kind: String, id: String, _amount: int) -> void:
	if kind == "talk" and actors.has(id):
		state.seen[id] = true
		if campaign.quests != null: campaign.quests.refresh()
	if kind == "boss" and Data.REWARDS.has(id): grant_academic_reward(id)
	if kind == "computer" and id == "director_antivirus": complete_task("director_task_antivirus")
func grant_academic_reward(id: String) -> void:
	if not Data.REWARDS.has(id): return
	campaign.grant_reward({"items":{Data.REWARDS[id][0]:1}},"academic_reward:"+id)
func recover_rewards() -> void:
	for id in Data.REWARDS:
		if campaign.data.bosses.get(id,false): grant_academic_reward(id)
func _process(delta: float) -> void:
	calculator_tick -= delta
	if calculator_tick > 0: return
	calculator_tick = 0.25
	var duel = campaign.active_duel
	var enabled: bool = Data.reward_owned(campaign.player,"CalculadoraAvanzada") and is_instance_valid(duel) and duel.state == 3
	if not enabled:
		if is_instance_valid(calculator_label): calculator_label.hide()
		return
	if not is_instance_valid(calculator_label):
		calculator_label = Label3D.new()
		calculator_label.position.y = 3.5
		calculator_label.font_size = 30
		calculator_label.pixel_size = 0.005
		calculator_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		campaign.player.add_child(calculator_label)
	var charge_value = duel.actor.get("charge")
	if charge_value == null: charge_value = duel.actor.get("blue_charge")
	calculator_label.visible = charge_value != null and float(charge_value) > 0
	calculator_label.text = "Preparación: %.1f s" % float(charge_value) if calculator_label.visible else ""
func map_notes() -> String:
	var text := ""
	var searching: bool = campaign.quests != null and campaign.quests.state("ubicar_profesores") == 1
	if searching:
		text += "\nUBICAR PROFESORES · habla, no necesitas vencerlos\n"+coordinator_missing()+"\n"
	if not campaign.player.inventory.has_item("MapaDocente",1): return text
	text += "\nMAPA DOCENTE · ubicaciones aproximadas conocidas\n"
	for id in actors:
		if not state.seen.get(id,false) and not campaign.phone.state.contacts.has(id): continue
		var actor = actors[id]
		text += actor.config.display_name+" · Piso "+str(actor.config.floor_number)+" · "+str(Data.BOSSES.get(id,{}).get("sector","formación general"))+"\n"
	return text
