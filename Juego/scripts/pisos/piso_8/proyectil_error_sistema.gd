extends CharacterBody3D
## Proyectil digital con colisión barrida, igual al patrón de proyectil_deportivo.gd.
var shooter: PhysicsBody3D
var damage := 16.0
var age := 0.0
var model: MeshInstance3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.22
	collision.shape = sphere
	add_child(collision)
	if is_instance_valid(shooter):
		add_collision_exception_with(shooter)
		for minion in shooter.get("minions"):
			if is_instance_valid(minion):
				add_collision_exception_with(minion)
	model = MeshInstance3D.new()
	model.name = "ErrorDigital"
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * 0.38
	model.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("17cfea")
	mat.emission_enabled = true
	mat.emission = Color("1188ff")
	mat.emission_energy_multiplier = 2.0
	model.material_override = mat
	add_child(model)
	var label := Label3D.new()
	label.text = "ERROR"
	label.font_size = 32
	label.pixel_size = 0.006
	label.position.y = 0.4
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func launch(origin: Vector3, destination: Vector3, speed: float = 10.0) -> void:
	global_position = origin
	velocity = origin.direction_to(destination) * speed

func _physics_process(delta: float) -> void:
	if not is_instance_valid(shooter) or shooter.get("dead") == true:
		queue_free()
		return
	age += delta
	model.rotate_y(delta * 5)
	var hit := move_and_collide(velocity * delta)
	if hit:
		var victim := hit.get_collider() as Node
		if victim and victim.is_in_group("player") and victim.has_method("take_hit") and shooter.call("inside_arena",victim.global_position):
			_damage_victim(victim)
		queue_free()
	elif age >= 4.0 or not shooter.call("inside_arena",global_position):
		queue_free()

func _damage_victim(victim: Node) -> void:
	victim.call("take_hit",velocity.normalized(),damage)
