extends CharacterBody3D
## Proyectil local: movimiento barrido como proyectil_deportivo.gd.
## Impacta una vez, no deja objetos ni modifica el inventario.
var shooter: PhysicsBody3D
var damage := 14.0
var age := 0.0
var model: MeshInstance3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.20
	collision.shape = shape
	add_child(collision)
	if is_instance_valid(shooter):
		add_collision_exception_with(shooter)
	model = MeshInstance3D.new()
	model.name = "BandejaMetalica"
	var tray := BoxMesh.new()
	tray.size = Vector3(0.75, 0.07, 0.48)
	model.mesh = tray
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.72, 0.76, 0.80)
	steel.metallic = 0.8
	steel.roughness = 0.3
	model.material_override = steel
	add_child(model)

func launch(origin: Vector3, destination: Vector3, speed: float = 11.0) -> void:
	global_position = origin
	var flight_time := clampf(origin.distance_to(destination) / speed, 0.25, 1.5)
	velocity = (destination - origin) / flight_time + Vector3.UP * 9.8 * flight_time / 2.0

func _physics_process(delta: float) -> void:
	# Una bandeja deja de hacer daño en cuanto muere el chef.
	if not is_instance_valid(shooter) or shooter.get("dead") == true:
		queue_free()
		return
	age += delta
	velocity.y -= 9.8 * delta
	model.rotate_y(delta * 9.0)
	var hit := move_and_collide(velocity * delta)
	if hit:
		var victim := hit.get_collider() as Node
		if victim and victim.is_in_group("player") and victim.has_method("take_hit"):
			victim.call("take_hit", velocity.normalized(), damage)
		queue_free()
	elif age >= 4.0:
		queue_free()
