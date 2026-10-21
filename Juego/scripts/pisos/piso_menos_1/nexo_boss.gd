extends CharacterBody3D
signal died(actor)
var area: Node3D
var config: Resource
var health := 0.0 # Assigned only from config.max_health in _ready.
var dead := false
var phase := 1
var target: CharacterBody3D
var minions: Array[Node3D] = [] # Existing digital projectile contract.
var projectiles: Array[Node3D] = []
var zones: Array[Node3D] = []
var duel: Node3D
var shell: MeshInstance3D
var status: Label3D
var glow: OmniLight3D
var warning_disc: MeshInstance3D
var attack_cd := 2.0
var charge := 0.0
var pending := ""
var last_attack := ""
var cooldowns := {}
var router_assist := false
var running := false
var visual_t := 0.0
func _ready() -> void:
	config = area.config
	health = config.max_health
	collision_layer = 1; collision_mask = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.62; capsule.height = 2.5
	collision.shape = capsule; collision.position.y = 1.25; add_child(collision)
	shell = MeshInstance3D.new()
	var shape := SphereMesh.new(); shape.radius = 0.7; shape.height = 1.4
	shell.mesh = shape; shell.position.y = 1.45; shell.material_override = area.cyan
	add_child(shell)
	for angle in 3:
		var ring := MeshInstance3D.new(); var torus := TorusMesh.new()
		torus.inner_radius = 0.8; torus.outer_radius = 0.87
		ring.mesh = torus; ring.position.y = 1.45; ring.rotation = Vector3(angle*0.8,angle*1.2,0.7)
		ring.material_override = area.cyan; add_child(ring)
	glow = OmniLight3D.new(); glow.position.y = 2; glow.omni_range = 7; glow.light_energy = 1.1; glow.shadow_enabled = false; add_child(glow)
	status = area.label(self,"NEXO\nNÚCLEO DEL SISTEMA",Vector3(0,3,0))
	duel = preload("res://scripts/pisos/piso_menos_1/nexo_duel.gd").new()
	duel.name = "BossDuelController"; duel.boss_id = "nexo"; duel.boss_name = "NEXO"; duel.subtitle = "NÚCLEO DEL SISTEMA"; duel.max_health = config.max_health
	duel.intro_text = "Conexión no autorizada detectada.\nEl sistema no puede permitir la interrupción del protocolo."
	add_child(duel)
	var effects = preload("res://scripts/inventory/item_effect_receiver.gd").new()
	effects.name = "ItemEffects"; effects.weaknesses = {"USBInfectado":1.5}; effects.stun_seconds = 2.0; effects.cancel_methods = PackedStringArray(["cancel_attack"])
	add_child(effects); add_to_group("technological")
func combat_active() -> bool: return running and not dead and duel != null and duel.allows_damage()
func inside_arena(point: Vector3) -> bool:
	return absf(point.y-area.global_position.y) < 3 and Vector2(point.x-area.global_position.x,point.z-area.global_position.z).length() <= 10.5
func has_clear_line(a: Vector3,b: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(a,b,1,[get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or hit.get("collider") == target
func valid_target() -> bool:
	return is_instance_valid(target) and not target.dead and inside_arena(target.global_position)
func prepare_core() -> void:
	router_assist = area.campaign.player.inventory.has_item("RouterPortatil")
	area.set_checkpoint()
func begin_core() -> void:
	running = true; target = area.campaign.player; attack_cd = 2.2
func reset_core() -> void:
	running = false; dead = false; phase = 1; health = config.max_health
	attack_cd = 2.2; cooldowns.clear(); last_attack = ""
	cancel_attack(); clear_threats()
	for terminal in area.terminals: terminal.link = false; terminal.refresh()
	area.set_lighting(false)
func active_links() -> int:
	var count := 0
	for terminal in area.terminals:
		if terminal.link: count += 1
	return count
func damage_factor() -> float:
	return 1.0-active_links()*(config.assisted_protection if router_assist else config.link_protection)
func link_disabled() -> void:
	area.campaign.ui.notify("NÚCLEO EXPUESTO" if active_links() == 0 else "Enlaces activos: %d/3" % active_links(),4)
func set_phase(value: int) -> void:
	if value <= phase: return
	phase = value; cancel_attack(); attack_cd = 2.0
	if phase == 2: area.campaign.ui.notify("NEXO ESTÁ ANALIZANDO TUS DATOS",4,0)
	if phase == 3:
		for terminal in area.terminals: terminal.link = true; terminal.refresh()
		area.campaign.ui.notify("SISTEMA CRÍTICO\nDesactiva los tres enlaces",5,0)
		area.set_lighting(true,true)
func take_hit(_direction: Vector3,damage: float) -> void:
	if not combat_active() or damage <= 0: return
	var next_health: float = maxf(0,health-damage*damage_factor())
	if next_health <= config.max_health*config.phase_three: set_phase(3)
	elif next_health <= config.max_health*config.phase_two: set_phase(2)
	health = maxf(1,next_health) if phase == 3 and active_links() > 0 else next_health
	if health <= 0:
		dead = true; running = false; clear_threats(); cancel_attack(); died.emit(self)
func choose_attack() -> String:
	var pool: Array[String] = ["packet","packet","pulse","zone"]
	if phase >= 2: pool.append_array(["fan","interference"])
	if phase == 3: pool.append("deletion")
	pool = pool.filter(func(id): return float(cooldowns.get(id,0)) <= 0 and id != last_attack)
	return pool.pick_random() if not pool.is_empty() else ""
func start_attack(id: String) -> bool:
	projectiles = projectiles.filter(is_instance_valid); zones = zones.filter(is_instance_valid)
	if not combat_active() or not valid_target() or not pending.is_empty(): return false
	if id not in ["packet","pulse","zone","fan","interference","deletion"] or float(cooldowns.get(id,0)) > 0: return false
	if id in ["fan","interference"] and phase < 2 or id == "deletion" and phase < 3: return false
	if id in ["packet","fan"] and projectiles.size() >= config.maximum_projectiles: return false
	if id in ["zone","interference"] and zones.size() >= config.maximum_zones: return false
	pending = id; last_attack = id
	charge = config.deletion_warning if id == "deletion" else config.telegraph_time
	cooldowns[id] = {"packet":4.0,"pulse":7.0,"zone":9.0,"fan":8.0,"interference":10.0,"deletion":13.0}.get(id,8.0)
	var titles := {"packet":"PAQUETE CORRUPTO","pulse":"PULSO DEL SISTEMA · ALÉJATE","zone":"ZONA DE ERROR","fan":"PATRÓN DE REDES","interference":"INTERFERENCIA","deletion":"PROTOCOLO DE BORRADO · SAL DEL ANILLO"}
	area.warning.text = titles.get(id,id)
	if id in ["pulse","deletion"]:
		warning_disc = area.disc(area,6.5 if id == "deletion" else 3.5,Color(1,0.25,0.05,0.30))
	area.campaign.live.reactive.discovery_sound()
	return true
func resolve_attack() -> void:
	var id := pending
	cancel_attack()
	if not combat_active() or not valid_target(): return
	match id:
		"packet","fan":
			for offset in ([0.0] if id == "packet" else [-0.8,0.8]):
				projectiles = projectiles.filter(is_instance_valid)
				if projectiles.size() >= config.maximum_projectiles: break
				var shot = preload("res://scripts/pisos/piso_3/network_data_packet.gd").new()
				shot.shooter = self; shot.damage = config.packet_damage
				area.add_child(shot); projectiles.append(shot)
				shot.launch(global_position+Vector3.UP*1.3,target.global_position+Vector3(offset,1.1,0),8.0)
		"pulse","deletion":
			var distance := Vector2(target.global_position.x-global_position.x,target.global_position.z-global_position.z).length()
			if distance < (6.5 if id == "deletion" else 3.5) and has_clear_line(global_position+Vector3.UP,target.global_position+Vector3.UP):
				target.take_hit(global_position.direction_to(target.global_position),config.deletion_damage if id == "deletion" else config.pulse_damage)
		"zone","interference":
			if zones.filter(is_instance_valid).size() >= config.maximum_zones: return
			var zone = preload("res://scripts/pisos/piso_menos_1/nexo_zone.gd").new()
			zone.boss = self; area.add_child(zone); zone.global_position = Vector3(target.global_position.x,area.global_position.y+0.05,target.global_position.z)
			zones.append(zone)
func cancel_attack() -> void:
	charge = 0; pending = ""
	if is_instance_valid(warning_disc): warning_disc.queue_free()
	if is_instance_valid(area.warning): area.warning.text = ""
func clear_threats() -> void:
	for node in projectiles+zones:
		if is_instance_valid(node): node.queue_free()
	projectiles.clear(); zones.clear()
func shutdown() -> void:
	dead = true; running = false; clear_threats(); cancel_attack()
	for terminal in area.terminals: terminal.link = false; terminal.refresh()
	area.set_lighting(false)
	var tween := create_tween()
	tween.tween_property(shell,"scale",Vector3.ONE*0.35,1.2)
	shell.material_override = area.green
func _physics_process(delta: float) -> void:
	if not combat_active(): return
	for id in cooldowns: cooldowns[id] = maxf(0,float(cooldowns[id])-delta)
	if not valid_target(): cancel_attack(); return
	if charge > 0:
		charge = maxf(0,charge-delta)
		if charge <= 0: resolve_attack()
		return
	attack_cd = maxf(0,attack_cd-delta)
	if attack_cd <= 0:
		var id := choose_attack()
		if not id.is_empty(): start_attack(id)
		attack_cd = config.attack_gaps[phase-1]+randf_range(0,0.4)
func _process(delta: float) -> void:
	if not is_instance_valid(area.campaign.player) or area.campaign.player.global_position.distance_to(global_position) > 35: return
	visual_t += delta; shell.rotation.y += delta*0.4
	if not dead: shell.position.y = 1.45+sin(visual_t*1.5)*0.08
	status.text = "NEXO\nSISTEMAS RESTAURADOS" if dead else ("NEXO · SISTEMA CRÍTICO\nENLACES ACTIVOS: %d/3" % active_links() if phase == 3 and active_links() > 0 else "NEXO\nNÚCLEO EXPUESTO" if phase == 3 else "NEXO\nANALIZANDO DATOS" if phase == 2 else "NEXO\nSISTEMA ACTIVO")
