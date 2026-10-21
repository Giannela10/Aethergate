class_name ProfesorRedesBoss
extends "res://scripts/juego/enemy.gd"
## Profesor ficticio: no representa a ninguna persona real.
const Duel = preload("res://scripts/pisos/piso_3/profesor_redes_duel.gd")
const Packet = preload("res://scripts/pisos/piso_3/network_data_packet.gd")
const Zone = preload("res://scripts/pisos/piso_3/network_interference_zone.gd")
const Slow = preload("res://scripts/pisos/piso_3/network_slow_status.gd")
@export var boss_max_health := 550.0
@export var visual_scale := 1.3
var phase := 0
var routers: Array[Node3D] = []
var minions: Array[Node3D] = []
var projectiles: Array[Node3D] = []
var effects: Array[Node3D] = []
var network_started := false
var reconnect_used := false
var reconnect_time := 0.0
var packet_cd := 2.5
var pulse_cd := 5.0
var zone_cd := 6.0
var connection_cd := 5.0
var connection_charge := 0.0
var packet_pending := false
var warning_disc: MeshInstance3D
var _slow_effect: Node

func _ready() -> void:
	var duel := Duel.new()
	duel.name = "BossDuelController"
	duel.boss_name = "Profesor de Redes y Telecomunicaciones"
	duel.boss_id = "profesor_redes"
	duel.max_health = boss_max_health
	duel.reward = "RouterPortatil"
	duel.subtitle = "PISO 3 · INFORMÁTICA Y TELECOMUNICACIONES"
	duel.intro_text = "Una red mal configurada puede dejar fuera a todo el sistema.\n¿Quieres intentar resolverla?"
	add_child(duel)
	super._ready()
	health = boss_max_health
	body.scale = Vector3.ONE*visual_scale
	body.rotation.y = PI
	idle_yaw = body.rotation.y
	body.angry = false
	for mesh in body.find_children("*","MeshInstance3D",true,false):
		var old := mesh.material_override as StandardMaterial3D
		if old and old.albedo_color.is_equal_approx(Color("a83232")):
			var material := old.duplicate() as StandardMaterial3D
			material.albedo_color = Color("24364a")
			mesh.material_override = material
	for child in get_children():
		if child is CollisionShape3D:
			child.shape.height = 1.8*visual_scale
			child.shape.radius = 0.3*visual_scale
			child.position.y = 0.9*visual_scale
	_add_detail(body.chest,Vector3(-0.12,0,-0.19),Vector3(0.13,0.19,0.03),Color("49dcb9"))
	_add_detail(body.chest,Vector3(0,0.02,0.2),Vector3(0.32,0.42,0.13),Color("121a2c"))
	_add_detail(body.hand_l,Vector3(0,-0.05,-0.1),Vector3(0.24,0.04,0.32),Color("3ebdb8"))
	remove_from_group("enemy")
	set_physics_process(false)

func _add_detail(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)

func combat_active() -> bool:
	var duel := get_node_or_null("BossDuelController")
	return network_started and not dead and duel != null and duel.allows_damage()

func begin_network() -> void:
	if dead or not get_node("BossDuelController").allows_damage():
		return
	network_started = true
	phase = 1
	reconnect_used = false
	reconnect_time = 4.0
	for router in routers:
		router.set_active(true)
	body.angry = true
	alert(target.global_position)

func active_routers() -> int:
	var count := 0
	for router in routers:
		if router.state == router.RouterState.ACTIVE:
			count += 1
	return count

func damage_factor() -> float:
	return [1.0,0.75,0.5,0.3][clampi(active_routers(),0,3)]

func inside_arena(pos: Vector3) -> bool:
	return Rect2(home.x-9.0,home.z-4.0,14.0,9.5).has_point(Vector2(pos.x,pos.z)) and absf(pos.y-home.y) < 2.0

func _target_available() -> bool:
	return is_instance_valid(target) and target.get("dead") != true and inside_arena(target.global_position)

func has_clear_line(origin: Vector3, destination: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(origin,destination)
	ray.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or (is_instance_valid(target) and hit.get("collider") == target)

func _vision_amount() -> float:
	return 1.0 if _target_available() and has_clear_line(global_position+Vector3.UP*1.6,target.global_position+Vector3.UP*1.2) else 0.0

func _do_patrol(delta: float) -> Vector3:
	var offset := home-global_position
	offset.y = 0
	return _steer(offset.normalized(),1.6,delta) if offset.length() > 0.35 else Vector3.ZERO

func _do_search(delta: float) -> Vector3:
	return _do_patrol(delta)

func _steer(direction: Vector3, speed: float, delta: float) -> Vector3:
	for angle in [0.0,0.6,-0.6,1.1,-1.1]:
		var step := direction.rotated(Vector3.UP,angle)*maxf(0.65,speed*delta)
		var future := global_position+step
		if not inside_arena(future) or test_move(global_transform,step):
			continue
		var ray := PhysicsRayQueryParameters3D.create(future+Vector3.UP*0.6,future+Vector3.DOWN*0.7)
		ray.exclude = [get_rid()]
		var floor_hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not floor_hit.is_empty() and floor_hit.normal.y > 0.9 and absf(floor_hit.position.y-home.y) < 0.6:
			return step.normalized()*speed
	return Vector3.ZERO

func _do_chase(delta: float, vis: float) -> Vector3:
	if not _target_available():
		return _do_patrol(delta)
	if connection_charge > 0 or stun_t > 0 or body.is_punching():
		return Vector3.ZERO
	var offset := target.global_position-global_position
	offset.y = 0
	if offset.length() < 0.01:
		return Vector3.ZERO
	_face(offset.normalized(),8,delta)
	if vis > 0 and attack_cd <= 0:
		if offset.length() < 2.0 and body.start_punch():
			packet_pending = false
			attack_cd = 1.2
			return Vector3.ZERO
		if offset.length() >= 3.0 and packet_cd <= 0 and body.start_punch():
			packet_pending = true
			packet_cd = [3.2,2.5,1.4][phase-1]
			attack_cd = 0.9
			return Vector3.ZERO
	return _steer(offset.normalized(),[2.2,2.6,3.1][phase-1],delta)

func _process(delta: float) -> void:
	# La IA neutral está detenida; no usar is_on_floor() sin pasos de física.
	var fighting := combat_active()
	body.animate(delta,velocity if fighting else Vector3.ZERO,is_on_floor() if fighting else true,false)

func _physics_process(delta: float) -> void:
	if not combat_active():
		return
	packet_cd = maxf(0,packet_cd-delta)
	pulse_cd = maxf(0,pulse_cd-delta)
	zone_cd = maxf(0,zone_cd-delta)
	connection_cd = maxf(0,connection_cd-delta)
	reconnect_time = maxf(0,reconnect_time-delta)
	if phase == 2 and not reconnect_used and reconnect_time <= 0:
		try_reconnect()
		reconnect_time = 4.0
	if connection_charge > 0:
		connection_charge = maxf(0,connection_charge-delta)
		if connection_charge <= 0:
			resolve_connection_loss()
	if _target_available() and _vision_amount() > 0:
		var distance := global_position.distance_to(target.global_position)
		if pulse_cd <= 0 and distance < 3.2:
			pulse_cd = 7.0
			network_pulse()
		if phase >= 2 and zone_cd <= 0:
			zone_cd = 8.0
			create_interference()
		if phase == 3 and connection_cd <= 0 and connection_charge <= 0:
			start_connection_loss()
	super._physics_process(delta)

func _on_punch_landed(_side: int) -> void:
	if not combat_active() or not _target_available() or _vision_amount() <= 0:
		packet_pending = false
		return
	if packet_pending:
		packet_pending = false
		var shot := Packet.new()
		shot.shooter = self
		shot.damage = [12.0,15.0,18.0][phase-1]
		get_parent().add_child(shot)
		shot.launch(global_position+Vector3.UP*1.6+body.forward()*0.7,target.global_position+Vector3.UP,9.0)
		projectiles = projectiles.filter(func(p): return is_instance_valid(p))
		projectiles.append(shot)
	elif global_position.distance_to(target.global_position) < 2.5:
		target.take_hit(global_position.direction_to(target.global_position),[16.0,18.0,22.0][phase-1])

func _disc(radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.04
	disc.radial_segments = 48
	mesh.mesh = disc
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = material
	get_parent().add_child(mesh)
	mesh.global_position = global_position+Vector3.UP*0.06
	effects = effects.filter(func(p): return is_instance_valid(p))
	effects.append(mesh)
	return mesh

func network_pulse() -> void:
	if not combat_active():
		return
	var ring := _disc(3.2,Color(0.1,0.9,0.8,0.25))
	var tween := ring.create_tween()
	tween.tween_property(ring,"scale",Vector3(1.15,1,1.15),0.4)
	tween.tween_callback(ring.queue_free)
	if _target_available() and global_position.distance_to(target.global_position) < 3.2 and _vision_amount() > 0:
		target.take_hit(global_position.direction_to(target.global_position)*0.5,[8.0,10.0,12.0][phase-1])

func create_interference() -> void:
	if not combat_active() or not _target_available():
		return
	var zone := Zone.new()
	zone.boss = self
	get_parent().add_child(zone)
	zone.global_position = Vector3(target.global_position.x,home.y+0.08,target.global_position.z)
	effects = effects.filter(func(p): return is_instance_valid(p))
	effects.append(zone)
	_message("INTERFERENCIA · sal de la zona violeta")

func apply_network_slow(player: Node3D, duration: float, multiplier: float) -> void:
	if not combat_active() or player.get("dead") == true:
		return
	if not is_instance_valid(_slow_effect) or _slow_effect.is_queued_for_deletion():
		_slow_effect = Slow.new()
		_slow_effect.name = "InterferenciaRedesPiso3"
		_slow_effect.source_boss = self
		player.add_child(_slow_effect)
	_slow_effect.apply_status("RALENTIZADO",duration,multiplier)

func start_connection_loss() -> void:
	if not combat_active() or phase != 3:
		return
	connection_charge = 1.2
	connection_cd = 9.0
	packet_pending = false
	warning_disc = _disc(6.0,Color(1,0.25,0.12,0.35))
	_message("PÉRDIDA DE CONEXIÓN · ¡sal del círculo naranja!",2.0)

func resolve_connection_loss() -> void:
	if is_instance_valid(warning_disc):
		warning_disc.queue_free()
	connection_charge = 0
	if not combat_active():
		return
	var ring := _disc(6.0,Color(1,0.65,0.15,0.3))
	var tween := ring.create_tween()
	tween.tween_property(ring,"scale",Vector3(1.15,1,1.15),0.5)
	tween.tween_callback(ring.queue_free)
	if _target_available() and global_position.distance_to(target.global_position) <= 6.0 and _vision_amount() > 0:
		var health_before: float = target.health
		target.take_hit(global_position.direction_to(target.global_position)*0.5,20.0)
		if target.health < health_before:
			apply_network_slow(target,3.0,0.65)

func router_disconnected(router: Node3D) -> void:
	if not combat_active():
		return
	_message("Router desconectado\nProfesor de Redes: Has perdido una conexión...")
	var campaign: Node = get_node("BossDuelController").campaign
	campaign.event("router","profesor_redes:"+str(router.name))
	campaign.save_game()

func try_reconnect() -> bool:
	if phase != 2 or reconnect_used or not combat_active():
		return false
	for router in routers:
		if router.state == router.RouterState.DISABLED:
			router.set_active(true)
			reconnect_used = true
			_message("Router reconectado")
			return true
	return false

func take_hit(direction: Vector3, damage: float) -> void:
	if not combat_active():
		return
	super.take_hit(direction,maxf(0,damage)*damage_factor())
	if dead:
		return
	var next_phase := 3 if health < boss_max_health*0.30 else (2 if health <= boss_max_health*0.65 else 1)
	if next_phase > phase:
		phase = next_phase
		_message("PROTOCOLO DE EMERGENCIA" if phase == 3 else "RED RECONFIGURADA")
		reconnect_time = 4.0
		if phase == 3:
			connection_cd = minf(connection_cd,2.0)
	body.punch_time = [0.7,0.62,0.5][phase-1]
	_update_bar()

func _update_bar() -> void:
	if is_instance_valid(bar_fg):
		var width := maxf(BAR_W*clampf(health/boss_max_health,0,1),0.001)
		var quad := bar_fg.mesh as QuadMesh
		quad.size = Vector2(width,0.09)
		quad.center_offset = Vector3(-(BAR_W-width)*0.5,0,0)

func clear_network_effects() -> void:
	network_started = false
	packet_pending = false
	connection_charge = 0
	for node in projectiles+effects:
		if is_instance_valid(node):
			node.queue_free()
	projectiles.clear()
	effects.clear()
	if is_instance_valid(_slow_effect):
		_slow_effect.clear_slow()
	for router in routers:
		router.set_active(false)

func reset_network() -> void:
	clear_network_effects()
	phase = 0
	reconnect_used = false
	packet_cd = 2.5
	pulse_cd = 5.0
	zone_cd = 6.0
	connection_cd = 5.0
	body.angry = false
	velocity = Vector3.ZERO

func _die() -> void:
	clear_network_effects()
	super._die()

func _message(text: String, seconds: float = 3.0) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel and is_instance_valid(duel.campaign):
		duel.campaign.ui.notify(text,seconds)

func _exit_tree() -> void:
	if is_instance_valid(_slow_effect):
		_slow_effect.clear_slow()
