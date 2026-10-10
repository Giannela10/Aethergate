extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var space = scene.get_world_3d().direct_space_state
	for n in scene.find_children("Torniquete*","Node3D",true,false):
		if n.get_script() == null or n.get_script().resource_path != "res://scripts/exterior/Torniquete.gd": continue
		var p: Vector3 = n.global_position+n.global_basis.x*n.arm_length*0.5+n.global_basis.z
		var hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*3,p-Vector3.UP*8))
		print("GATE ",str(scene.get_path_to(n))," pos=",n.global_position," ground=",hit.get("position")," ground_body=",str(hit.get("collider")))
	print("REAR_WALL ",scene.get_node("Piso1/Wall_Back2").global_transform*scene.get_node("Piso1/Wall_Back2").get_aabb())
	quit()
