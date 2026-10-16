extends "res://scripts/juego/enemy.gd"
## Boss exclusivo del casino. Conserva impactos, física, animación y died de enemy.gd.
const Tray = preload("res://scripts/pisos/piso_1/bandeja_chef_casino.gd")
@export var boss_max_health := 350.0
@export_range(1.3, 1.5) var visual_scale := 1.4
var phase := 1
var tray_cd := 2.0
var tray_pending := false
var boss_label: Label3D

func _ready() -> void:
	super._ready()
	health = boss_max_health
	body.name = "VisualChef"
	body.scale = Vector3.ONE * visual_scale
	body.rotation.y = PI / 2.0
	idle_yaw = body.rotation.y
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		var m := (mesh as MeshInstance3D).material_override as StandardMaterial3D
		if m and m.albedo_color.is_equal_approx(Color("a83232")):
			m.albedo_color = Color("f3f0e7")
	# Ajustar solo la cápsula de este enemigo, sin escalar el cuerpo físico.
	for child in get_children():
		if child is CollisionShape3D:
			var capsule := child.shape as CapsuleShape3D
			capsule.height = 1.8 * visual_scale
			capsule.radius = 0.3 * visual_scale
			child.position.y = capsule.height / 2.0
	_add_chef_mesh(body.head_pivot, "GorroChef", Vector3(0,0.35,0), Vector3(0.38,0.42,0.34), Color("fff9e9"))
	_add_chef_mesh(body.head_pivot, "BandaGorro", Vector3(0,0.16,0), Vector3(0.34,0.10,0.31), Color.WHITE)
	_add_chef_mesh(body.chest, "Delantal", Vector3(0,-0.12,-0.16), Vector3(0.37,0.55,0.035), Color("292c31"))
	_add_chef_mesh(body.chest, "PanueloRojo", Vector3(0,0.07,-0.19), Vector3(0.12,0.11,0.035), Color("b9232d"))
	bar_root.position.y = 3.05
	bar_root.scale = Vector3(2.2,1.3,1)
	alert_label.position.y = 3.85
	boss_label = Label3D.new()
	boss_label.name = "NombreYFase"
	boss_label.position.y = 3.45
	boss_label.font_size = 40
	boss_label.pixel_size = 0.004
	boss_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(boss_label)
	_update_bar()

func _add_chef_mesh(parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)

func _inside_casino(pos: Vector3) -> bool:
	return pos.x >= -83.0 and pos.x <= -34.0 and pos.z >= -121.0 and pos.z <= -79.5 and absf(pos.y - home.y) <= 2.5

func _vision_amount() -> float:
	if not is_instance_valid(target) or target.get("dead") == true or not _inside_casino(target.global_position):
		return 0.0
	# Detecta al jugador solo dentro del comedor y sin atravesar muros.
	if _line_of_sight(global_position + Vector3.UP * 2.0, target.global_position + Vector3.UP):
		return 1.0
	return 0.0

func _do_patrol(delta: float) -> Vector3:
	# Espera en su puesto; vuelve a él después de perder al jugador.
	var offset := home - global_position
	offset.y = 0
	if offset.length() < 0.3 or stun_t > 0:
		return Vector3.ZERO
	_face(offset.normalized(), 5.0, delta)
	return _avoid_tables(offset.normalized(), 1.6, delta)

func _do_search(delta: float) -> Vector3:
	state = State.PATROL
	suspicion = 0.0
	return _do_patrol(delta)

func _do_chase(delta: float, vis: float) -> Vector3:
	if not is_instance_valid(target) or target.get("dead") == true or not _inside_casino(target.global_position):
		state = State.PATROL
		suspicion = 0.0
		tray_pending = false
		return Vector3.ZERO
	if vis > 0:
		last_seen = target.global_position
		lost_t = 0
	else:
		lost_t += delta
		if lost_t > 4.0:
			state = State.SEARCH
			return Vector3.ZERO
	var offset := last_seen - global_position
	offset.y = 0
	var distance := offset.length()
	if distance < 0.01:
		return Vector3.ZERO
	var direction := offset / distance
	_face(direction, 8.0, delta)
	if stun_t > 0 or body.is_punching():
		return Vector3.ZERO
	if vis > 0 and distance <= 2.0:
		if attack_cd <= 0 and body.start_punch():
			tray_pending = false
			attack_cd = [1.35,1.0,0.75][phase-1]
		return Vector3.ZERO
	if phase >= 2 and vis > 0 and distance >= 4.0 and distance <= 18.0 and tray_cd <= 0 and attack_cd <= 0:
		if body.start_punch():
			tray_pending = true
			tray_cd = 3.5 if phase == 2 else 2.5
			attack_cd = 0.9
			return Vector3.ZERO
	var speed: float = [2.2,2.7,3.2][phase-1]
	return _avoid_tables(direction, speed, delta)

func _avoid_tables(direction: Vector3, speed: float, delta: float) -> Vector3:
	# Conserva move_and_slide del enemigo y prueba desvíos ante mesas.
	for angle in [0.0,0.7,-0.7,1.3,-1.3]:
		var candidate := direction.rotated(Vector3.UP, angle)
		if _inside_casino(global_position + candidate * 0.8) and not test_move(global_transform, candidate * maxf(0.75, speed * delta)):
			return candidate * speed
	return Vector3.ZERO

func _physics_process(delta: float) -> void:
	tray_cd = maxf(0.0, tray_cd-delta)
	super._physics_process(delta)

func _on_punch_landed(_side: int) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	if dead or not is_instance_valid(target) or target.get("dead") == true or not _inside_casino(target.global_position):
		tray_pending = false
		return
	if not _line_of_sight(global_position + Vector3.UP * 2.0, target.global_position + Vector3.UP):
		tray_pending = false
		return
	var offset := target.global_position - global_position
	if tray_pending:
		tray_pending = false
		_throw_tray()
		return
	if absf(offset.y) > 2.5:
		return
	offset.y = 0
	if offset.length() <= 2.4 and (offset.length() < 0.01 or body.forward().dot(offset.normalized()) > 0.3):
		if target.has_method("take_hit"):
			target.call("take_hit", offset.normalized(), [18.0,22.0,26.0][phase-1])

func _throw_tray() -> void:
	var projectile := Tray.new()
	projectile.name = "BandejaChef"
	projectile.shooter = self
	projectile.damage = 14.0 if phase == 2 else 18.0
	get_parent().add_child(projectile)
	var origin := global_position + Vector3.UP * 1.9 + body.forward() * 0.65
	projectile.launch(origin, target.global_position + Vector3.UP, 11.0)

func take_hit(direction: Vector3, damage: float) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	if dead:
		return
	super.take_hit(direction, maxf(0.0,damage))
	if dead:
		return
	var next_phase := 3 if health <= boss_max_health * 0.30 else (2 if health <= boss_max_health * 0.60 else 1)
	if next_phase > phase:
		phase = next_phase
		body.punch_time = 0.58 if phase == 2 else 0.46
		tray_cd = minf(tray_cd,1.0)
		_message("Chef Supremo del Casino: fase %d" % phase, 3.0)
	_update_bar()

func _update_bar() -> void:
	if not is_instance_valid(bar_fg):
		return
	var width := maxf(BAR_W * clampf(health / maxf(boss_max_health,1.0),0,1),0.001)
	var quad := bar_fg.mesh as QuadMesh
	quad.size = Vector2(width,0.09)
	quad.center_offset = Vector3(-(BAR_W-width)*0.5,0,0)
	if is_instance_valid(boss_label):
		boss_label.text = "Chef Supremo del Casino\n%d / %d · Fase %d" % [ceili(health),ceili(boss_max_health),phase]

func _die() -> void:
	if dead:
		return
	tray_pending = false
	boss_label.text = "¡Chef Supremo derrotado!"
	super._die()
	# Después de died: el mensaje específico prevalece sobre el contador genérico.
	call_deferred("_reward_player")

func _reward_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("heal"):
		player.call("heal", float(player.get("max_health")))
	_message("¡Chef Supremo del Casino derrotado! Vida recuperada por completo.",7.0)

func _message(text: String, seconds: float) -> void:
	var manager := get_tree().current_scene.get_node_or_null("GameplayManager")
	if manager and manager.has_method("_show_message"):
		manager.call("_show_message",text,seconds)
