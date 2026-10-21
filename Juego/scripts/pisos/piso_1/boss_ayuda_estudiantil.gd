extends Node3D
signal died(enemy)
## Boss local: detección con línea de visión y persecución directa con colisiones.
## No requiere cambios en player.gd ni en GameplayManager.
const Humanoid = preload("res://scripts/juego/humanoid.gd")
const SportsProjectile = preload("res://scripts/juego/proyectil_deportivo.gd")
const THROW_ITEMS := ["bate", "raqueta", "pelota", "baseball", "tenis", "futbol", "rugby", "disco"]

@export_range(1.0, 30.0) var detection_range: float = 10.0
@export_range(0.1, 10.0) var chase_speed: float = 2.6
@export_range(0.5, 3.0) var attack_range: float = 1.6
@export_range(0.0, 100.0) var attack_damage: float = 10.0
@export_range(0.2, 5.0) var attack_cooldown: float = 1.2
@export var max_health: float = 200.0
@export var throw_cooldown: float = 2.4
@export var throw_damage: float = 12.0
@export var throw_speed: float = 12.0
@export var max_sports_equipment: int = 12

var health: float
var dead: bool = false
var target: Node3D
var _mover: CharacterBody3D
var _visual: Humanoid
var _attack_timer: float = 0.0
var _health_label: Label3D
var _health_fill: MeshInstance3D
var _throw_timer := 1.0
var _throw_pending := false
var _next_sport := 0

func _build_health_display() -> void:
	_health_label = Label3D.new()
	_health_label.name = "NombreYVida"
	_health_label.position.y = 3.5
	_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_health_label.font_size = 40
	_health_label.pixel_size = 0.004
	add_child(_health_label)
	for is_fill in [false, true]:
		var bar := MeshInstance3D.new()
		bar.name = "VidaBoss" if is_fill else "FondoVidaBoss"
		bar.position = Vector3(0, 3.05, 0.01 if is_fill else 0.0)
		var quad := QuadMesh.new()
		quad.size = Vector2(2.0 if is_fill else 2.1, 0.16 if is_fill else 0.22)
		bar.mesh = quad
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.albedo_color = Color(0.85, 0.1, 0.12) if is_fill else Color(0.08, 0.08, 0.08)
		bar.material_override = material
		add_child(bar)
		if is_fill:
			_health_fill = bar
	_update_health_display()

func _update_health_display() -> void:
	_health_label.text = "Encargado Punto Estudiantil\n%d / %d" % [ceili(health), ceili(max_health)]
	var quad := _health_fill.mesh as QuadMesh
	quad.size.x = maxf(0.001, 2.0 * health / maxf(max_health, 1.0))
	quad.center_offset.x = -(2.0 - quad.size.x) * 0.5


func _ready() -> void:
	health = max_health
	_build_health_display()
	add_to_group("enemy")
	_mover = CharacterBody3D.new()
	_mover.name = "CuerpoBoss"
	add_child(_mover)
	_mover.top_level = true
	_mover.global_transform = global_transform
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.7
	collision.shape = capsule
	collision.position.y = 1.35
	_mover.add_child(collision)
	_visual = Humanoid.new()
	_visual.name = "VisualBoss"
	_visual.scale = Vector3.ONE * 1.5
	_visual.shirt_color = Color(0.35, 0.12, 0.48)
	_visual.angry = true
	_visual.punch_time = 0.7
	_mover.add_child(_visual)
	_visual.punch_landed.connect(_on_punch_landed)

func _physics_process(delta: float) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_throw_timer = maxf(0.0, _throw_timer - delta)
	_mover.velocity.x = 0.0
	_mover.velocity.z = 0.0
	if not _mover.is_on_floor():
		_mover.velocity.y -= 14.0 * delta
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node3D
	if not dead and _can_detect_target():
		var offset := target.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > 0.001:
			_visual.rotation.y = atan2(-offset.x, -offset.z)
		if distance <= attack_range:
			if not _visual.is_punching() and _attack_timer <= 0.0 and _visual.start_punch():
				_throw_pending = false
				_attack_timer = attack_cooldown
		elif distance >= 3.0 and _throw_timer <= 0.0 and not _visual.is_punching() and _can_spawn_equipment():
			if _visual.start_punch():
				_throw_pending = true
				_throw_timer = throw_cooldown
		elif not _visual.is_punching():
			if distance > 6.0 or distance < 3.0 or not _can_spawn_equipment():
				var direction := offset.normalized()
				_mover.velocity.x = direction.x * chase_speed
				_mover.velocity.z = direction.z * chase_speed
	_mover.move_and_slide()
	global_position = _mover.global_position
	_visual.animate(delta, _mover.velocity, _mover.is_on_floor(), false)

func _can_detect_target() -> bool:
	if not is_instance_valid(target) or target.get("dead") == true:
		return false
	if global_position.distance_to(target.global_position) > detection_range:
		return false
	return _has_line_of_sight()

func _has_line_of_sight() -> bool:
	var eye := _mover.global_position + Vector3.UP * 1.6
	var target_height: float = 0.7 if target.get("crouching") == true else 1.1
	var destination := target.global_position + Vector3.UP * target_height
	var query := PhysicsRayQueryParameters3D.create(eye, destination)
	query.exclude = [_mover.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target

func _on_punch_landed(_side: int) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	if _throw_pending:
		_throw_pending = false
		_throw_equipment()
		return
	if dead or not _can_detect_target():
		return
	var offset := target.global_position - global_position
	# Distancia 3D: no atacar a un jugador en otro piso o fuera del alcance.
	if offset.length() > attack_range:
		return
	offset.y = 0.0
	if target.has_method("take_hit"):
		target.call("take_hit", offset.normalized(), attack_damage)

func _can_spawn_equipment() -> bool:
	return get_tree().get_nodes_in_group("sports_equipment").size() < max_sports_equipment

func _throw_equipment() -> void:
	if dead or not _can_detect_target() or not _can_spawn_equipment():
		return
	var projectile := SportsProjectile.new()
	projectile.sport = THROW_ITEMS[_next_sport % THROW_ITEMS.size()]
	_next_sport += 1
	projectile.damage = throw_damage
	projectile.shooter = _mover
	get_parent().add_child(projectile)
	var direction := target.global_position - global_position
	direction.y = 0
	var origin := global_position + Vector3.UP * 1.8 + direction.normalized() * 0.7
	var destination := target.global_position + Vector3.UP * (0.7 if target.get("crouching") == true else 1.2)
	projectile.launch(origin, destination, throw_speed)

func take_hit(_direction: Vector3, damage: float) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	if dead:
		return
	health = maxf(0.0, health - maxf(0.0, damage))
	_visual.hurt()
	_update_health_display()
	if health <= 0.0:
		dead = true
		remove_from_group("enemy")
		_mover.collision_layer = 0
		_visual.die()
		died.emit(self)
