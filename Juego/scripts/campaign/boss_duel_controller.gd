extends Node3D
var interaction_range := 4.5
var neutral_visual_tick := 0.0
enum DuelState { NEUTRAL, DIALOGUE, INTRO, COMBAT, DEFEATED }
enum DuelType { COMBAT, QUIZ, MINIGAME, FUTURE_TYPE }
@export var boss_name := "Boss"
@export_multiline var intro_text := "¿Estás preparado para demostrar lo que has aprendido?"
@export var subtitle := ""
@export var duel_type: DuelType = DuelType.COMBAT
@export var max_health := 200.0
@export var reward := ""
@export var boss_id := ""
@export var intro_duration := 2.0
@export var music: AudioStream
@export var defeated := false
@export var special_rules: Dictionary = {}
var state := DuelState.NEUTRAL
var actor: Node3D
var campaign: Node
var music_player: AudioStreamPlayer
var initialized := false
var spawn_position := Vector3.ZERO
var identity_label: Label3D
var visual_pass := preload("res://scripts/campaign/boss_visual_pass.gd").new()

func _ready() -> void:
	actor = get_parent()
	actor.set_physics_process(false)
	spawn_position = actor.global_position
	add_to_group("campus_interactable")
	add_to_group("boss_duel")
	identity_label = Label3D.new()
	identity_label.name = "IdentificacionBoss"
	identity_label.text = boss_name + "\n[E] Hablar y aceptar desafío"
	identity_label.position.y = 4.0
	identity_label.font_size = 40
	identity_label.pixel_size = 0.006
	identity_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	identity_label.modulate = Color("ffdb75")
	add_child(identity_label)
	call_deferred("_initialize")

func interaction_target() -> Node3D:
	# El cuerpo con colisión pertenece al actor, no a este controlador hijo.
	return actor

func _initialize() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	if campaign == null or not campaign.ready_for_play:
		call_deferred("_wait_campaign")
		return
	initialized = true
	visual_pass.setup(actor,boss_id)
	defeated = defeated or bool(campaign.data.bosses.get(boss_id,false))
	state = DuelState.DEFEATED if defeated else DuelState.NEUTRAL
	actor.set_physics_process(false)
	actor.remove_from_group("enemy")
	if actor.has_signal("died"):
		actor.died.connect(_on_actor_died)
	music_player = AudioStreamPlayer.new()
	music_player.name = "BossMusic"
	music_player.stream = music
	add_child(music_player)
	_hide_old_bars()
	if defeated:
		_show_defeated(true)

func _wait_campaign() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		_initialize()

func allows_damage() -> bool:
	return state == DuelState.COMBAT and duel_type == DuelType.COMBAT and not defeated

func interaction_text(_player: Node) -> String:
	if defeated and boss_id == "director" and campaign.data.get("campaign_completed",false): return "[E] Hablar con el Director"
	return "" if state != DuelState.NEUTRAL else "[E] Hablar con "+boss_name

func interact(candidate: CharacterBody3D) -> void:
	if defeated and boss_id == "director" and campaign.data.get("campaign_completed",false) and not candidate.dead and not candidate.busy:
		campaign.ui.begin_character_dialogue(actor,true)
		campaign.ui.dialog(boss_name,"Así que realmente estaba ahí abajo.",["Hasta luego"],[campaign.ui.close_modal],true)
		return
	if not initialized or state != DuelState.NEUTRAL or candidate.dead or candidate.busy or is_instance_valid(campaign.active_duel):
		return
	if campaign.get("academic_expansion") != null:
		var missing: String = campaign.academic_expansion.boss_missing(boss_id,true)
		if not missing.is_empty():
			campaign.ui.begin_character_dialogue(actor,true)
			campaign.ui.dialog(boss_name,missing,["Ahora no"],[campaign.ui.close_modal],true)
			return
	campaign.ui.begin_character_dialogue(actor,true)
	state = DuelState.DIALOGUE
	campaign.active_duel = self
	campaign.event("talk",boss_id)
	campaign.ui.dialog(boss_name,intro_text+"\n\nSi cierras el juego durante el duelo, continuarás desde el estado previo al desafío.",["Iniciar duelo","Ahora no"],[accept,decline])

func decline() -> void:
	if state != DuelState.DIALOGUE:
		return
	state = DuelState.NEUTRAL
	campaign.active_duel = null
	campaign.ui.close_modal()

func accept() -> void:
	if state != DuelState.DIALOGUE:
		return
	if campaign.get("academic_expansion") != null:
		var missing: String = campaign.academic_expansion.boss_missing(boss_id)
		if not missing.is_empty():
			decline()
			campaign.ui.notify(missing)
			return
	if campaign.live != null: campaign.live.retry.capture(self)
	if duel_type in [DuelType.MINIGAME,DuelType.FUTURE_TYPE] and not special_rules.has("start_method"):
		campaign.ui.notify("Este tipo de duelo está preparado para un desafío futuro.")
		decline()
		return
	campaign.ui.close_modal()
	state = DuelState.INTRO
	campaign.active_duel = self
	campaign.player.busy = true
	campaign.event("duel_started",boss_id)
	await campaign.ui.show_intro(boss_name,subtitle,intro_duration)
	if not is_inside_tree() or campaign.player.dead or state != DuelState.INTRO:
		return
	state = DuelState.COMBAT
	campaign.player.busy = false
	if music_player.stream:
		music_player.play()
	if campaign.has_method("duck_ambient"):
		campaign.duck_ambient(true)
	if duel_type == DuelType.QUIZ:
		actor.interact(campaign.player)
	elif duel_type == DuelType.COMBAT:
		actor.set_physics_process(true)
		actor.add_to_group("enemy")
		actor.set("target",campaign.player)
		if actor.has_method("alert"):
			actor.alert(campaign.player.global_position)
	else:
		actor.call(special_rules.start_method,campaign.player)

func _process(delta: float) -> void:
	if initialized and state == DuelState.NEUTRAL:
		neutral_visual_tick -= delta
		if neutral_visual_tick > 0: return
		neutral_visual_tick = 0.15
	identity_label.visible = initialized and state in [DuelState.NEUTRAL,DuelState.DEFEATED]
	if initialized and is_instance_valid(campaign.player):
		var offset: Vector3 = campaign.player.global_position-actor.global_position
		identity_label.visible = identity_label.visible and absf(offset.y) < 4 and offset.length() < 9
	if not initialized:
		actor.set_physics_process(false)
		actor.remove_from_group("enemy")
		return
	_hide_old_bars()
	if state == DuelState.DEFEATED and duel_type != DuelType.QUIZ:
		var visual := _defeat_visual()
		if visual != null and visual.get("death_t") < 1.0:
			visual.animate(delta,Vector3.ZERO,true,false)
	if state != DuelState.COMBAT:
		actor.set_physics_process(false)
		actor.remove_from_group("enemy")
	elif duel_type == DuelType.QUIZ and actor.get("defeated") == true and actor.get("active") != true:
		_finish()
	if state == DuelState.COMBAT and campaign.player.dead:
		reset_duel()
	visual_pass.update(delta,state,int(actor.get("phase")) if actor.get("phase") != null else 0)

func _hide_old_bars() -> void:
	for key in ["bar_root","alert_label","boss_label","name_label","_health_label","_health_fill","world_health","world_fill","prompt"]:
		var node = actor.get(key)
		if node is Node3D:
			node.hide()
	var old := actor.get_node_or_null("FondoVidaBibliotecaria")
	if old:
		old.hide()

func _on_actor_died(_actor: Node) -> void:
	if state == DuelState.COMBAT:
		_finish()

func _finish() -> void:
	if defeated:
		return
	defeated = true
	state = DuelState.DEFEATED
	_show_defeated(false)
	music_player.stop()
	if campaign.has_method("duck_ambient"):
		campaign.duck_ambient(false)
	campaign.boss_won(self)

func _defeat_visual() -> Node3D:
	for property in ["body","_visual","visual"]:
		var visual = actor.get(property)
		if visual is Node3D and visual.has_method("die") and visual.has_method("animate"):
			return visual
	return null

func _show_defeated(restored: bool) -> void:
	actor.set_physics_process(false)
	actor.remove_from_group("enemy")
	actor.set("health",0.0)
	if actor.get("dead") != null:
		actor.set("dead",true)
	if actor.get("defeated") != null:
		actor.set("defeated",true)
	if actor is CharacterBody3D:
		actor.velocity = Vector3.ZERO
		actor.collision_layer = 0
	var mover = actor.get("_mover")
	if mover is CharacterBody3D:
		mover.velocity = Vector3.ZERO
		mover.collision_layer = 0
	var visual := _defeat_visual()
	if visual:
		visual.die()
		if restored:
			visual.animate(1.0,Vector3.ZERO,true,false)
	identity_label.text = boss_name+"\nDERROTADO"
	identity_label.position.y = 2.5

func reset_duel() -> void:
	if defeated:
		return
	if duel_type == DuelType.QUIZ and actor.get("active"):
		actor._close()
	state = DuelState.NEUTRAL
	campaign.active_duel = null
	actor.set_physics_process(false)
	actor.remove_from_group("enemy")
	actor.set("health",max_health)
	actor.global_position = spawn_position
	var mover = actor.get("_mover")
	if mover is CharacterBody3D:
		mover.global_position = spawn_position
		mover.velocity = Vector3.ZERO
	for key in ["digital_pending","tray_pending","_throw_pending"]:
		if actor.get(key) != null:
			actor.set(key,false)
	for node in get_tree().current_scene.find_children("*","CharacterBody3D",true,false):
		if node.get("shooter") == actor or (mover != null and node.get("shooter") == mover):
			node.queue_free()
	if actor.get("phase") != null:
		actor.set("phase",1)
	var body = actor.get("body") if actor.get("body") != null else actor.get("_visual")
	if is_instance_valid(body):
		body.punch_p[0] = -1
		body.punch_p[1] = -1
	if actor.has_method("_cancel_blue_screen"):
		actor._cancel_blue_screen()
	if actor.has_method("clear_director_effects"):
		actor.clear_director_effects()
	for key in ["minions","projectiles"]:
		var nodes = actor.get(key)
		if nodes is Array:
			for node in nodes:
				if is_instance_valid(node):
					node.queue_free()
			nodes.clear()
	if actor.get("security_activated") != null:
		actor.security_activated = false
	if music_player:
		music_player.stop()
	if campaign.has_method("duck_ambient"):
		campaign.duck_ambient(false)

func interaction_priority() -> int:
	return 0
