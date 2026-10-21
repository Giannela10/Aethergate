extends CharacterBody3D
var lifetime := 0.0
var shooter: CharacterBody3D
func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_collision_exception_with(shooter)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.1
	collision.shape = shape
	add_child(collision)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	mesh.mesh = sphere
	add_child(mesh)
func _physics_process(delta: float) -> void:
	lifetime += delta
	velocity.y -= 9.8*delta
	var hit := move_and_collide(velocity*delta)
	if hit:
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy.has_method("alert") and enemy.global_position.distance_to(global_position)<9 and absf(enemy.global_position.y-global_position.y)<2.5 and not enemy.has_node("BossDuelController"):
				enemy.alert(global_position)
		var campaign := get_tree().get_first_node_in_group("campus_campaign")
		if campaign:
			campaign.ui.notify("El ruido ha distraído a los enemigos cercanos.")
		queue_free()
	elif lifetime>4:
		queue_free()
