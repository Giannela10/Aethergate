extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	scene.set_script(null)
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.7
	var failures: Dictionary = {}
	var checked := 0
	for stair in scene.find_children("Escalera*", "Node3D", true, false):
		for step in stair.get_children():
			if not step is MeshInstance3D: continue
			var title := str(step.name)
			if not (title.begins_with("Step") or title.begins_with("Escalera Norte") or title.begins_with("Escalera Sur")): continue
			var b: AABB = step.global_transform * step.get_aabb()
			for z in [b.position.z+1.0, b.get_center().z, b.end.z-1.0]:
				var p := Vector3(b.get_center().x, b.end.y+0.45, z)
				var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p-Vector3.UP*1.5))
				checked += 1
				if ground.is_empty():
					failures[str(step.get_path())+str(z)] = "sin suelo"
					continue
				var q := PhysicsShapeQueryParameters3D.new()
				q.shape = capsule
				q.transform.origin = Vector3(p.x, ground.position.y+1.4, p.z)
				q.exclude = [ground.rid]
				for hit in space.intersect_shape(q):
					failures[str(hit.collider.get_path())] = str(step.get_path())
	print("ACCESS_CHECK ", checked, " ", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
