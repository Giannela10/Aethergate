extends "res://scripts/juego/enemy.gd"
## Personaje ficticio. Toda la lógica específica queda en el Piso 8.
const DigitalError = preload("res://scripts/pisos/piso_8/proyectil_error_sistema.gd")
const Virus = preload("res://scripts/pisos/piso_8/virus_director.gd")
@export var boss_max_health := 700.0
@export var visual_scale := 1.4
@export var reward_path: NodePath = NodePath("../CredencialDirector")
var phase := 1
var security_activated := false
var minions: Array[Node3D] = []
var projectiles: Array[Node3D] = []
var digital_cd := 2.0
var digital_pending := false
var blue_cd := 5.0
var blue_charge := 0.0
var blue_marker: MeshInstance3D
var name_label: Label3D
var effects: Array[Node3D] = []
var firewall_cd := 7.0
var denied_cd := 10.0

func _create_visual() -> Humanoid:
	return preload("res://scripts/juego/student_visual.gd").new()

func _ready() -> void:
	super._ready()
	health = boss_max_health
	body.name = "VisualDirectorFicticio"
	body.scale = Vector3.ONE * 1.2 # Solo visual: cápsula y alcance anteriores intactos.
	body.rotation.y = PI/2
	idle_yaw = body.rotation.y
	for mesh in body.find_children("*","MeshInstance3D",true,false):
		var mat := (mesh as MeshInstance3D).material_override as StandardMaterial3D
		if mat and mat.albedo_color.is_equal_approx(Color("a83232")):
			mat.albedo_color = Color("153759")
	for child in get_children():
		if child is CollisionShape3D:
			child.shape.height = 1.8 * visual_scale
			child.shape.radius = 0.3 * visual_scale
			child.position.y = 0.9 * visual_scale
	_visual_part(body.chest,"CorbataDigital",Vector3(0,0,-0.19),Vector3(0.065,0.30,0.035),Color("10dae3"))
	_visual_part(body.chest,"CredencialAcademica",Vector3(-0.12,-0.04,-0.19),Vector3(0.13,0.15,0.025),Color("d4faff"))
	_visual_part(body.head_pivot,"VisorTecnologico",Vector3(0,0.11,-0.11),Vector3(0.19,0.045,0.035),Color("08e2ff"))
	bar_root.position.y = 3.0
	bar_root.scale = Vector3(3,1.5,1)
	alert_label.position.y = 3.9
	name_label = Label3D.new()
	name_label.name = "NombreVidaYModo"
	name_label.position.y = 3.5
	name_label.font_size = 40
	name_label.pixel_size = 0.004
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_label)
	blue_marker = MeshInstance3D.new()
	blue_marker.name = "AreaPantallazoAzul"
	var disc := CylinderMesh.new()
	disc.top_radius = 6.0
	disc.bottom_radius = 6.0
	disc.height = 0.035
	disc.radial_segments = 64
	blue_marker.mesh = disc
	var blue := StandardMaterial3D.new()
	blue.albedo_color = Color(0.03,0.24,1.0,0.40)
	blue.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blue.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blue_marker.material_override = blue
	blue_marker.position.y = 0.06
	blue_marker.visible = false
	add_child(blue_marker)
	_update_bar()
	var presets = preload("res://scripts/juego/character_visual_presets.gd")
	var campaign := get_tree().get_first_node_in_group("campus_campaign")
	var preset: Dictionary = presets.create("director","DIRECTOR")
	if campaign:
		if not campaign.data.npc_visuals.get("director") is Dictionary: campaign.data.npc_visuals.director = preset
		preset = campaign.data.npc_visuals.director
	presets.apply(body,preset)

func combat_active() -> bool:
	var duel := get_node_or_null("BossDuelController")
	return not dead and duel != null and duel.allows_damage()

func has_clear_line(a: Vector3, b: Vector3) -> bool:
	return _line_of_sight(a,b)

func hit_player(damage: float) -> void:
	if combat_active() and _target_available(): target.take_hit(global_position.direction_to(target.global_position),damage)

func clear_director_effects() -> void:
	for effect in effects:
		if is_instance_valid(effect): effect.queue_free()
	effects.clear(); firewall_cd = 7; denied_cd = 10

func _director_zone(text: String, point: Vector3, radius: float, length: float = 0.0) -> void:
	effects = effects.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	if effects.size() >= 2 or not inside_arena(point): return
	if text.begins_with("FIREWALL") and effects.any(func(effect): return effect.caption.begins_with("FIREWALL")): return
	var zone = preload("res://scripts/campaign/academic_boss_zone.gd").new()
	zone.boss = self; zone.caption = text; zone.radius = radius; zone.length = length; zone.direction = body.forward(); zone.warning = 1.8; zone.lifetime = 0.25; zone.damage = 18.0
	get_parent().add_child(zone); zone.global_position = Vector3(point.x,home.y+0.06,point.z); effects.append(zone)
	body.request_visual_state("BOSS_SPECIAL",1.2)

func _visual_part(parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)

func inside_arena(pos: Vector3) -> bool:
	# Ala oriental del pasillo sur. Nunca persigue ni ataca en otros pisos.
	return pos.x >= 35.0 and pos.x <= 81.0 and pos.z >= -136.8 and pos.z <= -125.0 and absf(pos.y-home.y) <= 2.5

func _target_available() -> bool:
	return is_instance_valid(target) and target.get("dead") != true and inside_arena(target.global_position)

func _vision_amount() -> float:
	if not _target_available():
		return 0.0
	return 1.0 if _line_of_sight(global_position+Vector3.UP*2,target.global_position+Vector3.UP) else 0.0

func _do_patrol(delta: float) -> Vector3:
	var offset := home-global_position
	offset.y = 0
	if offset.length() < 0.3 or stun_t > 0:
		return Vector3.ZERO
	_face(offset.normalized(),5,delta)
	return _steer(offset.normalized(),1.6,delta)

func _do_search(delta: float) -> Vector3:
	state = State.PATROL
	suspicion = 0
	return _do_patrol(delta)

func _do_chase(delta: float, vis: float) -> Vector3:
	if not _target_available():
		state = State.PATROL
		suspicion = 0
		digital_pending = false
		return Vector3.ZERO
	if blue_charge > 0:
		return Vector3.ZERO
	if vis > 0:
		last_seen = target.global_position
		lost_t = 0
	else:
		lost_t += delta
		if lost_t > 4:
			state = State.SEARCH
			return Vector3.ZERO
	var offset := last_seen-global_position
	offset.y = 0
	var distance := offset.length()
	if distance < 0.01:
		return Vector3.ZERO
	var direction := offset / distance
	_face(direction,8,delta)
	if stun_t > 0 or body.is_punching():
		return Vector3.ZERO
	if phase == 3 and vis > 0 and distance <= 9 and blue_cd <= 0:
		_start_blue_screen()
		return Vector3.ZERO
	if distance <= 2.0 and vis > 0:
		if attack_cd <= 0 and body.start_punch():
			digital_pending = false
			attack_cd = [1.3,1.1,0.8][phase-1]
		return Vector3.ZERO
	if distance >= 4.0 and distance <= 22.0 and vis > 0 and digital_cd <= 0 and attack_cd <= 0:
		if body.start_punch():
			digital_pending = true
			digital_cd = [3.0,2.6,2.1][phase-1]
			attack_cd = 0.8
			return Vector3.ZERO
	var speed: float = [2.6,3.0,3.6][phase-1]
	return _steer(direction,speed,delta)

func _steer(direction: Vector3, speed: float, delta: float) -> Vector3:
	for angle in [0.0,0.7,-0.7,1.3,-1.3]:
		var candidate := direction.rotated(Vector3.UP,angle)
		if inside_arena(global_position+candidate*0.8) and not test_move(global_transform,candidate*maxf(0.7,speed*delta)):
			return candidate*speed
	return Vector3.ZERO

func _physics_process(delta: float) -> void:
	if combat_active() and _target_available() and blue_charge <= 0:
		firewall_cd -= delta; denied_cd -= delta
		if phase == 2 and firewall_cd <= 0:
			_director_zone("FIREWALL · sal de la línea",global_position,0.8,7.0); firewall_cd = 9.0
		elif phase == 3 and denied_cd <= 0:
			_director_zone("ACCESO DENEGADO",target.global_position,1.5); denied_cd = 11.0
	if not dead:
		digital_cd = maxf(0,digital_cd-delta)
		blue_cd = maxf(0,blue_cd-delta)
		if blue_charge > 0:
			if not _target_available():
				_cancel_blue_screen()
			else:
				blue_charge = maxf(0,blue_charge-delta)
				if blue_charge <= 0:
					_resolve_blue_screen()
	super._physics_process(delta)

func _on_punch_landed(_side: int) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	if dead or not _target_available() or _vision_amount() <= 0:
		digital_pending = false
		return
	if digital_pending:
		digital_pending = false
		var shot := DigitalError.new()
		shot.name = "ErrorDeSistema"
		shot.shooter = self
		shot.damage = [16.0,20.0,25.0][phase-1]
		get_parent().add_child(shot)
		shot.launch(global_position+Vector3.UP*1.9+body.forward()*0.65,target.global_position+Vector3.UP)
		projectiles = projectiles.filter(func(p): return is_instance_valid(p))
		projectiles.append(shot)
		return
	var offset := target.global_position-global_position
	offset.y = 0
	if offset.length() <= 2.4 and (offset.length() < 0.01 or body.forward().dot(offset.normalized()) > 0.3):
		if target.has_method("take_hit"):
			target.call("take_hit",offset.normalized(),[20.0,24.0,32.0][phase-1])

func _start_blue_screen() -> void:
	blue_charge = 1.2
	blue_cd = 7.0
	blue_marker.visible = true
	digital_pending = false
	_message("Pantallazo Azul: ¡sal del círculo azul!",2.0)

func _resolve_blue_screen() -> void:
	blue_marker.visible = false
	if dead or not _target_available():
		return
	var offset := target.global_position-global_position
	offset.y = 0
	# Daño de área anunciado, esquivable y bloqueado por paredes.
	if offset.length() <= 6.0 and _vision_amount() > 0 and target.has_method("take_hit"):
		target.call("take_hit",offset.normalized(),36.0)

func _cancel_blue_screen() -> void:
	blue_charge = 0
	blue_marker.visible = false

func _activate_security() -> void:
	if security_activated:
		return
	security_activated = true
	_message("El Director ha activado el sistema de seguridad",4.0)
	for offset in [Vector3(0,0,-2.0),Vector3(0,0,2.0)]:
		if minions.filter(func(v): return is_instance_valid(v) and not v.dead).size() >= 2: break
		var virus := Virus.new()
		virus.name = "VirusSeguridad%d" % (minions.size()+1)
		virus.director = self
		virus.position = get_parent().to_local(home+offset)
		get_parent().add_child(virus)
		var campaign := get_tree().get_first_node_in_group("campus_campaign")
		if campaign and campaign.data.computers.get("pc8",false): virus.health *= 0.8
		minions.append(virus)
		virus.target = target
		if _target_available():
			virus.alert(target.global_position)

func take_hit(direction: Vector3, damage: float) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	if dead:
		return
	super.take_hit(direction,maxf(0,damage))
	if dead:
		return
	if health <= boss_max_health*0.60:
		_activate_security()
	var next_phase := 3 if health <= boss_max_health*0.30 else (2 if health <= boss_max_health*0.60 else 1)
	if next_phase > phase:
		phase = next_phase
		body.punch_time = 0.58 if phase == 2 else 0.45
		if phase == 3:
			name_label.modulate = Color("39cfff")
			blue_cd = minf(blue_cd,1.5)
			_message("Modo Administrador activado",4.0)
	_update_bar()

func _update_bar() -> void:
	if not is_instance_valid(bar_fg):
		return
	var width := maxf(BAR_W*clampf(health/maxf(boss_max_health,1),0,1),0.001)
	var quad := bar_fg.mesh as QuadMesh
	quad.size = Vector2(width,0.09)
	quad.center_offset = Vector3(-(BAR_W-width)*0.5,0,0)
	if is_instance_valid(name_label):
		var mode := "Modo Administrador" if phase == 3 else "Fase %d" % phase
		name_label.text = "Director de Carrera de Informática\n%d / %d · %s" % [ceili(health),ceili(boss_max_health),mode]

func _die() -> void:
	if dead:
		return
	digital_pending = false
	clear_director_effects()
	_cancel_blue_screen()
	for virus in minions:
		if is_instance_valid(virus):
			virus.deactivate()
	for shot in projectiles:
		if is_instance_valid(shot):
			shot.queue_free()
	name_label.text = "Director de Carrera derrotado"
	super._die()
	call_deferred("_grant_reward")

func _grant_reward() -> void:
	var registry := get_node_or_null(reward_path)
	if registry:
		registry.call("grant_credential",get_tree().get_first_node_in_group("player"))
	_message("Director de Carrera derrotado\nRecompensa: CredencialDirector",7.0)

func _message(text: String, seconds: float) -> void:
	var scene := get_tree().current_scene
	var manager := scene.get_node_or_null("GameplayManager") if scene else null
	if manager and manager.has_method("_show_message"):
		manager.call("_show_message",text,seconds)
