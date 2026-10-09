extends CharacterBody3D
## Colisión barrida: golpea una sola vez y deja un arma recogible al aterrizar.
const Equipment = preload("res://scripts/juego/implemento_deportivo.gd")
const GRAVITY := 9.8
var sport := "bate"
var damage := 12.0
var shooter: PhysicsBody3D
var equipment
var age := 0.0
var hit_target := false
var targets_enemies := false
var landed := false

func _ready() -> void:
	add_to_group("sports_projectile")
	collision_layer = 0
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.18
	collision.shape = shape
	add_child(collision)
	if is_instance_valid(shooter):
		add_collision_exception_with(shooter)
	if not is_instance_valid(equipment):
		equipment = Equipment.new()
		equipment.sport = sport
	add_child(equipment)
	equipment.pick_up()

func launch(origin: Vector3, destination: Vector3, speed: float) -> void:
	global_position = origin
	var flight_time := clampf(origin.distance_to(destination) / maxf(speed, 1), 0.25, 1.2)
	velocity = (destination - origin) / flight_time + Vector3.UP * GRAVITY * flight_time / 2

func _physics_process(delta: float) -> void:
	if landed:
		return
	age += delta
	velocity.y -= GRAVITY * delta
	equipment.model.rotate_z(delta * 7)
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		var victim := collider as Node
		if targets_enemies:
			while victim and not victim.is_in_group("enemy"):
				victim = victim.get_parent()
		elif victim and not victim.is_in_group("player"):
			victim = null
		if victim and not hit_target:
			hit_target = true
			if victim.has_method("take_hit"):
				var direction := velocity.normalized()
				direction.y = 0
				victim.call("take_hit", direction, damage)
			if collider is PhysicsBody3D:
				add_collision_exception_with(collider)
		if collision.get_normal().y > 0.55:
			_land(collision.get_position())
		else:
			velocity = velocity.bounce(collision.get_normal()) * 0.3
			velocity.y = minf(velocity.y, 1.0)
	if age > 6 and not landed:
		# Evitar proyectiles eternos y objetos recogibles suspendidos en el aire.
		var query := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 6)
		if is_instance_valid(shooter): query.exclude = [shooter.get_rid()]
		var floor_hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not floor_hit.is_empty() and floor_hit.normal.y > 0.55:
			_land(floor_hit.position)
		else:
			queue_free()

func _land(point: Vector3) -> void:
	if landed:
		return
	landed = true
	equipment.reparent(get_parent())
	equipment.global_position = point + Vector3.UP * 0.025
	equipment.rotation = Vector3.ZERO
	equipment.put_down()
	queue_free()
