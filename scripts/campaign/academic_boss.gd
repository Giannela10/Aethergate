extends "res://scripts/juego/enemy.gd"
## Combate de asignaturas generales; extiende IA, daño, armas y muerte existentes.
const Shot = preload("res://scripts/campaign/academic_boss_projectile.gd")
const Zone = preload("res://scripts/campaign/academic_boss_zone.gd")
var config: Resource
var duel: Node
var boss_max_health := 450.0
var phase := 1
var running := false
var prepared := false
var placement_valid := false
var projectiles: Array[Node3D] = []
var effects: Array[Node3D] = []
var minions: Array[Node3D] = []
var attack_timer := 2.0
var last_attack := ""
var current_attack := ""
var charge := 0.0
var aim := Vector3.FORWARD
var aim_point := Vector3.ZERO
var choice := ""
var choice_started := false
var choices_remaining := 0.0
var _slow_effect: Node
var civilians: Array[Dictionary] = []
var visual_tick := 0.0

func _create_visual() -> Humanoid:
	return preload("res://scripts/juego/student_visual.gd").new()

func _ready() -> void:
	boss_max_health = config.max_health
	super._ready()
	health = boss_max_health
	body.name = "CharacterVisual"
	body.scale = Vector3.ONE*1.15
	var presets = preload("res://scripts/juego/character_visual_presets.gd")
	var campaign := get_tree().get_first_node_in_group("campus_campaign")
	if not campaign.data.npc_visuals.get(config.boss_id) is Dictionary:
		campaign.data.npc_visuals[config.boss_id] = presets.create(config.boss_id,config.role)
	presets.apply(body,campaign.data.npc_visuals[config.boss_id])
	duel = preload("res://scripts/campaign/academic_boss_duel.gd").new()
	duel.name = "BossDuelController"; duel.boss_id = config.boss_id; duel.boss_name = config.display_name
	duel.subtitle = config.subtitle; duel.max_health = boss_max_health; duel.reward = config.reward
	duel.intro_text = "Un duelo de acción: esquiva las señales y busca una apertura.\nEl computador de este piso es preparación opcional; puedes combatir sin completarlo."
	add_child(duel)
	remove_from_group("enemy"); set_physics_process(false)

func combat_active() -> bool:
	return running and not dead and duel != null and duel.allows_damage()

func inside_arena(point: Vector3) -> bool:
	return absf(point.y-home.y) < 2.5 and Rect2(home.x-11,home.z-4.7,22,9.4).has_point(Vector2(point.x,point.z))

func has_clear_line(a: Vector3, b: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(a,b,1,[get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target

func prepare_duel() -> void:
	prepared = duel.campaign.data.computers.get(config.computer_id,false)
	duel.campaign.data.unlocks[config.preparation_flag] = prepared
	if prepared: duel.campaign.ui.notify("Preparación activa: "+config.preparation_flag)

func begin_academic_duel() -> void:
	running = true; attack_timer = 2.0; target = duel.campaign.player
	var events = duel.campaign.live.events if duel.campaign.live != null else null
	if events != null and is_instance_valid(events.active) and inside_arena(events.active.global_position): events.finish()
	_retreat_civilians()

func _process(delta: float) -> void:
	body.update_visual_lod(delta)
	visual_tick -= delta
	if not combat_active() and visual_tick > 0: return
	visual_tick = 0.0 if body.lod_level == 0 else (0.15 if body.lod_level == 1 else 0.8)
	body.animate(delta if body.lod_level == 0 else 0.15,velocity if combat_active() else Vector3.ZERO,true,false)

func _physics_process(delta: float) -> void:
	if not combat_active(): return
	if not is_instance_valid(target) or target.dead: return
	if choices_remaining > 0: choices_remaining = maxf(0,choices_remaining-delta)
	if charge > 0:
		charge -= delta
		if charge <= 0: resolve_attack()
	else:
		attack_timer -= delta
		if attack_timer <= 0 and inside_arena(target.global_position) and has_clear_line(global_position+Vector3.UP,target.global_position+Vector3.UP): select_attack()
	super._physics_process(delta)

func _do_patrol(_delta: float) -> Vector3: return Vector3.ZERO
func _do_search(_delta: float) -> Vector3: return Vector3.ZERO
func _do_chase(delta: float, _vis: float) -> Vector3:
	if not is_instance_valid(target) or not inside_arena(target.global_position): return Vector3.ZERO
	var offset := target.global_position-global_position; offset.y = 0
	if offset.length() > 0.01: _face(offset.normalized(),6,delta)
	if charge > 0 or stun_t > 0 or body.is_punching(): return Vector3.ZERO
	if offset.length() < 2.0 and attack_cd <= 0:
		body.start_punch(); attack_cd = 1.4
		body.request_visual_state("BOSS_MELEE",0.5)
		return Vector3.ZERO
	var speed := 2.5 if phase == 3 else 1.7
	if config.role == "ETICA" and phase == 3: speed = 2.0 if choice == "A" else 2.6
	if offset.length() < 3.5: return Vector3.ZERO
	for angle in [0.0,0.6,-0.6]:
		var step := offset.normalized().rotated(Vector3.UP,angle)*maxf(0.7,speed*delta)
		var future := global_position+step
		if not inside_arena(future) or test_move(global_transform,step): continue
		var ray := PhysicsRayQueryParameters3D.create(future+Vector3.UP*0.5,future+Vector3.DOWN*0.7,1,[get_rid()])
		var floor_hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not floor_hit.is_empty() and floor_hit.normal.y > 0.9 and absf(floor_hit.position.y-home.y) < 0.5: return step.normalized()*speed
	return Vector3.ZERO

func _on_punch_landed(_side: int) -> void:
	if combat_active() and is_instance_valid(target) and global_position.distance_to(target.global_position) < 2.5 and has_clear_line(global_position+Vector3.UP,target.global_position+Vector3.UP): hit_player(16.0)

func select_attack() -> void:
	var patterns: Array = ["WORD SHOT","LISTEN!","SPEAK UP"]
	if config.role == "LENGUAJE": patterns = ["HOJA CORTANTE","LIBRO PESADO","TORMENTA DE PÁGINAS"]
	if config.role == "ETICA": patterns = ["PRESIÓN","DUDA","DILEMA"]
	if phase >= 2:
		if config.role == "INGLES": patterns.append_array(["WORD RUSH","VOCABULARY STORM"])
		if config.role == "LENGUAJE": patterns.append_array(["TINTA","LÍNEA EDITORIAL"])
	patterns.erase(last_attack)
	start_attack(patterns.pick_random())

func start_attack(pattern: String) -> void:
	if not combat_active() or not is_instance_valid(target): return
	current_attack = pattern; last_attack = pattern
	charge = 1.2
	aim_point = Vector3(target.global_position.x,home.y+0.05,target.global_position.z)
	aim = global_position.direction_to(aim_point); aim.y = 0; aim = aim.normalized()
	body.request_visual_state("BOSS_SPECIAL",1.2)
	duel.campaign.ui.notify(pattern,1.4)
	match pattern:
		"LISTEN!","PRESIÓN","LÍNEA EDITORIAL": zone(pattern,global_position,1.2,1.2,0.3,18,"damage",9.0,aim)
		"SPEAK UP": zone(pattern,global_position,3.0,1.2,0.3,16)
		"VOCABULARY STORM":
			zone(pattern,aim_point,1.4,1.2,0.3,18)
			zone(pattern,aim_point+Vector3(3.8,0,0),1.1,1.6,0.3,18)
		"DILEMA":
			for side in [-1,1]: zone("DILEMA · deja libre el centro",global_position+Vector3(side*4,0,0),1.3,1.5,0.3,18,"damage",7.0,Vector3.FORWARD)

func resolve_attack() -> void:
	if not combat_active(): return
	body.request_visual_state("BOSS_RANGED",0.5)
	match current_attack:
		"WORD SHOT": shoot("WORD",aim,9.0,14)
		"HOJA CORTANTE": shoot("HOJA",aim,12.0,14)
		"LIBRO PESADO": shoot("LIBRO",aim,6.0,22)
		"DUDA": shoot("DUDA",aim,4.5,14,true)
		"WORD RUSH","TORMENTA DE PÁGINAS":
			# Dos abanicos laterales; conservar un hueco central navegable.
			for angle in [-0.48,-0.25,0.25,0.48]: shoot("WORD" if config.role == "INGLES" else "HOJA",aim.rotated(Vector3.UP,angle),8.0,12)
		"TINTA":
			zone("TINTA",aim_point,1.7,0.8,2.0 if prepared else 4.0,0,"slow")
			if phase == 3: zone("TINTA",aim_point+Vector3(4,0,0),1.2,1.1,2.0 if prepared else 4.0,0,"slow")
	attack_timer = 2.2 if phase == 3 else 3.3
	if prepared and current_attack == "WORD RUSH": attack_timer += 2.0
	if phase == 3 and config.role == "ETICA" and choice == "A": attack_timer += 0.4
	current_attack = ""; charge = 0

func shoot(word: String, direction: Vector3, speed: float, damage: float, tracking: bool = false) -> void:
	projectiles = projectiles.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	if projectiles.size() >= 6: return
	var shot := Shot.new(); shot.shooter = self; shot.word = word; shot.damage = damage; shot.homing = tracking
	get_parent().add_child(shot)
	var origin := global_position+Vector3.UP*1.25+direction*0.6
	shot.launch(origin,origin+direction*10,speed); projectiles.append(shot)

func zone(caption: String, point: Vector3, radius: float, warning: float, duration: float, damage: float, kind: String = "damage", length: float = 0.0, direction: Vector3 = Vector3.FORWARD, stance: String = "") -> Node3D:
	effects = effects.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	if effects.size() >= 5 or not inside_arena(point): return null
	var effect := Zone.new()
	effect.boss = self; effect.caption = caption; effect.radius = radius; effect.warning = warning; effect.lifetime = duration; effect.damage = damage; effect.kind = kind; effect.length = length; effect.direction = direction; effect.choice = stance
	if kind == "slow": effect.color = Color(0.12,0.06,0.3,0.6)
	if kind == "choice": effect.color = Color(0.2,0.8,0.55,0.4) if stance == "A" else Color(0.3,0.55,1,0.4)
	get_parent().add_child(effect); effect.global_position = point; effects.append(effect)
	return effect

func hit_player(damage: float) -> void:
	if damage <= 0: return # Visual decoys must not apply stun or push.
	if not combat_active() or not is_instance_valid(target) or not inside_arena(target.global_position): return
	var factor := 1.15 if choice == "A" else (0.8 if choice == "B" else 1.0)
	target.take_hit(global_position.direction_to(target.global_position),damage*factor)

func apply_ink(player: Node3D) -> void:
	if not combat_active() or player.dead: return
	if not is_instance_valid(_slow_effect) or _slow_effect.is_queued_for_deletion():
		_slow_effect = preload("res://scripts/pisos/piso_3/network_slow_status.gd").new()
		_slow_effect.source_boss = self; _slow_effect.name = "TintaAcademica"; player.add_child(_slow_effect)
	_slow_effect.apply_status("RALENTIZADO",0.45,0.85 if prepared else 0.65)

func choose_stance(value: String) -> void:
	if not combat_active() or not choice.is_empty() or choices_remaining <= 0 or value not in ["A","B"]: return
	choice = value
	duel.campaign.ui.notify("Elección "+value+": "+("+20% daño / −15% defensa" if value == "A" else "+20% defensa / −15% daño"),4)
	for effect in effects:
		if is_instance_valid(effect) and effect.kind == "choice": effect.queue_free()

func take_hit(direction: Vector3, damage: float) -> void:
	if not combat_active(): return
	var outgoing := 1.2 if choice == "A" else (0.85 if choice == "B" else 1.0)
	super.take_hit(direction,maxf(0,damage)*outgoing)
	if dead: return
	var next := 3 if health <= boss_max_health*0.30 else (2 if health <= boss_max_health*0.60 else 1)
	if next > phase:
		phase = next
		body.request_visual_state("BOSS_PHASE",0.7)
		var text := "SECOND PART" if config.role == "INGLES" else ("LAS PALABRAS TOMAN FORMA" if config.role == "LENGUAJE" else "TODA DECISIÓN TIENE CONSECUENCIAS")
		if phase == 3: text = "FINAL EXAM" if config.role == "INGLES" else ("BLOQUEO DEL ESCRITOR" if config.role == "LENGUAJE" else "CONSECUENCIA")
		duel.campaign.ui.notify(phase_title(text),3)
		if config.role == "ETICA" and not choice_started:
			for effect in effects:
				if is_instance_valid(effect): effect.queue_free()
			effects.clear()
			choice_started = true; choices_remaining = 10 if prepared else 6
			zone("A · daño +20% / defensa −15%",home+Vector3(-3,0,0),1.35,0,choices_remaining,0,"choice",0,Vector3.FORWARD,"A")
			zone("B · defensa +20% / daño −15%",home+Vector3(3,0,0),1.35,0,choices_remaining,0,"choice",0,Vector3.FORWARD,"B")

func phase_title(default_text: String) -> String:
	return default_text

func _update_bar() -> void:
	if is_instance_valid(bar_fg):
		var width := maxf(BAR_W*clampf(health/maxf(boss_max_health,1),0,1),0.001)
		(bar_fg.mesh as QuadMesh).size = Vector2(width,0.09)

func clear_academic_effects() -> void:
	running = false; charge = 0; current_attack = ""
	for node in projectiles+effects:
		if is_instance_valid(node): node.queue_free()
	projectiles.clear(); effects.clear()
	if is_instance_valid(_slow_effect): _slow_effect.clear_slow()
	for record in civilians:
		if is_instance_valid(record.node):
			if is_instance_valid(record.tween): record.tween.kill()
			record.node.global_position = record.position
			record.node.set_meta("duel_retreating",false)
	civilians.clear()

func reset_academic_duel() -> void:
	clear_academic_effects()
	dead = false; phase = 1; health = boss_max_health; attack_timer = 2; choice = ""; choice_started = false; choices_remaining = 0; last_attack = ""; velocity = Vector3.ZERO
	body.dead = false; body.death_t = 0; body.hurt_t = 0; stun_t = 0; collision_layer = 1
	body.fall_pivot.rotation = Vector3.ZERO; body.fall_pivot.position = Vector3.ZERO

func _die() -> void:
	clear_academic_effects()
	super._die()

func _retreat_civilians() -> void:
	for npc in duel.campaign.get_children():
		if npc.get_script() != preload("res://scripts/campaign/npc.gd") or not inside_arena(npc.global_position): continue
		for offset in [Vector3(-13,0,0),Vector3(13,0,0)]:
			var safe = duel.campaign.player.get_node("SeatController").safe_position(home+offset)
			if safe == null: continue
			var ray := PhysicsRayQueryParameters3D.create(npc.global_position+Vector3.UP,safe+Vector3.UP,1,[get_rid()])
			if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
			var tween: Tween = npc.create_tween()
			civilians.append({"node":npc,"position":npc.global_position,"tween":tween})
			npc.set_meta("duel_retreating",true)
			tween.tween_property(npc,"global_position",safe,1.2)
			tween.tween_callback(func(): if is_instance_valid(npc): npc.set_meta("duel_retreating",false))
			break
