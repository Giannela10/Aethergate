extends Node
var hub: Node
var catalog: Array[Resource] = []
var active: Node3D
var current: Resource
var remaining := 0.0
var actors: Array[Dictionary] = []
var last_id := ""
var caption: Label3D
var situation: Node3D
var tick := 0.0
var presentation: RefCounted
var active_anchor: Node3D
func _ready() -> void:
	catalog = preload("res://scripts/live/event_catalog.gd").build()
	for resource in hub.config.event_resources:
		if resource.get_script() == preload("res://scripts/live/event_data.gd"):
			var replaced := false
			for index in catalog.size():
				if catalog[index].event_id == resource.event_id:
					catalog[index] = resource
					replaced = true
					break
			if not replaced: catalog.append(resource)
	hub.director.opportunity.connect(consider)
func eligible(event: Resource) -> bool:
	if not event.floors.has(hub.floor_id()): return false
	if event.unique and hub.state.once.get(event.event_id,false): return false
	if event.event_id == "pausa_positiva" and hub.state.reward_spent >= hub.config.reward_budget: return false
	if event.nexo and hub.campus_state.phase == 4: return false
	if hub.campus_state.phase < event.minimum_anomaly: return false
	var minute := int(hub.campaign.academics.current_time().minute)
	if minute < event.minute_start or minute >= event.minute_end: return false
	var flags = hub.campaign.data.get("decision_flags",{})
	for key in event.required_flags:
		if not flags is Dictionary or flags.get(key) != event.required_flags[key]: return false
	return true
func find_anchor(kind: String) -> Node3D:
	var c = hub.campaign
	var candidates: Array = []
	if kind in ["casino","biblioteca"]:
		for node in get_tree().get_nodes_in_group("campus_area"):
			if node.marker_id == kind: candidates.append(node)
	elif kind == "computer": candidates = get_tree().get_nodes_in_group("computer")
	elif kind == "vendor":
		for node in c.get_children():
			if node.get("prices") is Dictionary: candidates.append(node)
	elif kind == "elevator":
		for node in get_tree().get_nodes_in_group("campus_interactable"):
			if node.get_script() == preload("res://scripts/campaign/elevator_interaction.gd") and int(node.get("landing")) >= 0: candidates.append(node)
	elif kind == "teachers":
		candidates = c.get_parent().find_children("ProfesoresCoordDocente","Node3D",true,false)
	elif kind == "workshop":
		var checkpoint: Node3D = c.get_node_or_null("CheckpointSubterráneo")
		if checkpoint != null: candidates.append(checkpoint)
	elif kind == "academic": candidates = c.academics.points.values()
	else:
		for node in c.get_children():
			if node.get_script() == preload("res://scripts/campaign/npc.gd"): candidates.append(node)
	var best: Node3D
	var distance := 25.0
	for node in candidates:
		if not node is Node3D or hub.campaign.phone._floor_for(node) != hub.floor_id(): continue
		var d: float = node.global_position.distance_to(c.player.global_position)
		if d < distance and c.player._can_reach(node):
			distance = d; best = node
	return best
func consider() -> void:
	if not hub.director.can_offer() or active != null: return
	var candidates: Array[Resource] = []
	for event in catalog:
		if eligible(event) and event.event_id != last_id and (not event.rare or hub.rng.randf() < hub.config.rare_probability):
			candidates.append(event)
	candidates.shuffle()
	for event in candidates:
		if start(event): return
func start(event: Resource) -> bool:
	if active != null or not hub.director.can_offer() or not eligible(event): return false
	var anchor := find_anchor(event.anchor)
	if anchor == null: return false
	active = Node3D.new()
	active.name = "SituacionAmbiental"
	hub.campaign.add_child(active)
	active.global_position = anchor.global_position
	active_anchor = anchor
	current = event
	hub.director.since_activity = 0
	hub.state.cooldown = hub.config.minimum_gap
	remaining = event.duration
	last_id = event.event_id
	caption = Label3D.new()
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.font_size = 24
	caption.pixel_size = 0.003
	caption.position.y = 2.9
	caption.text = event.title+"\n"+hub.campus_state.ambient_line()
	if event.anchor == "vendor": anchor.set_meta("live_discount",0.8)
	active.add_child(caption)
	# Borrow only idle presentation, never relocate or replace mission actors.
	for node in hub.campaign.get_children():
		if not node is Node3D or node.get("model") == null or not node.model.has_method("set_visual_activity"): continue
		if node.global_position.distance_to(anchor.global_position) > 12 or hub.campaign.phone._floor_for(node) != hub.floor_id(): continue
		var activity = node.model.activity_visual
		actors.append({"node":node,"action":activity.action,"prop":activity.prop_kind})
		node.model.set_visual_activity(event.action,event.prop)
		if actors.size() >= 3: break
	if event.unique: hub.state.once[event.event_id] = true
	if event.event_id in ["biblioteca_estudio","casino_almuerzo","evaluacion","trabajo_grupo","docentes_reunion","discusion_docente","entrada","ascensor_espera","taller_inspeccion","profesor_salida"]:
		presentation = preload("res://scripts/live/ambient_presentation.gd").new(hub)
		presentation.populate(active,event)
	if not event.situation.is_empty():
		situation = preload("res://scripts/live/ambient_situation.gd").new()
		situation.hub = hub; situation.source = anchor; situation.kind = event.situation
		situation.token = event.event_id+":"+str(hub.campaign.academics.current_time().day)
		active.add_child(situation)
		situation.position = Vector3(1,0,0)
	if hub.reactive != null and event.nexo: hub.reactive.pulse(4.0)
	hub.campaign.save_game()
	return true
func reward_once(id: String) -> bool:
	if hub.state.reward_spent+3 > hub.config.reward_budget: return false
	var source := "live:"+id
	if hub.campaign.data.unlocks.get("reward:"+source,false): return false
	hub.state.reward_spent += 3
	hub.campaign.grant_reward({"credits":3,"xp":5},source)
	hub.campaign.ui.notify("Gracias por ayudar · +3 créditos · +5 XP")
	hub.campaign.save_game()
	return true
func finish() -> void:
	if current != null and current.nexo and hub.reactive != null:
		hub.reactive.pulse_remaining = 0
		hub.reactive.restore_lights()
	if current != null and current.anchor == "vendor":
		if is_instance_valid(active_anchor): active_anchor.remove_meta("live_discount")
	if presentation != null: presentation.clear(); presentation = null
	for record in actors:
		if is_instance_valid(record.node): record.node.model.set_visual_activity(record.action,record.prop)
	actors.clear()
	if is_instance_valid(active): active.queue_free()
	active = null; current = null; situation = null
	active_anchor = null
	hub.director.event_finished()
	if hub.reactive != null: hub.reactive.refresh()
func _process(delta: float) -> void:
	if active == null: return
	if current.nexo and hub.campus_state.phase == 4:
		finish()
		return
	if hub.director.locked() or hub.director.in_combat():
		finish()
		return
	remaining -= delta
	if presentation != null: presentation.update(delta)
	tick += delta
	if tick > 0.5:
		tick = 0
		var offset: Vector3 = active.global_position-hub.campaign.player.global_position
		caption.visible = absf(offset.y)<4 and offset.length()<14
		if current != null: caption.text = current.title+"\n"+hub.campus_state.ambient_line()
		var minute := int(hub.campaign.academics.current_time().minute)
		if minute < current.minute_start or minute >= current.minute_end:
			finish()
			return
	if remaining <= 0 or active.global_position.distance_to(hub.campaign.player.global_position) > 45 or hub.campaign.phone._floor_for(active) != hub.floor_id(): finish()
func _exit_tree() -> void:
	if is_instance_valid(active_anchor) and active_anchor.has_meta("live_discount"): active_anchor.remove_meta("live_discount")
	for record in actors:
		if is_instance_valid(record.node): record.node.model.set_visual_activity(record.action,record.prop)
	if is_instance_valid(active): active.queue_free()
