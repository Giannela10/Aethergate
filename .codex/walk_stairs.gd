extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	scene.set_script(null)
	root.add_child(scene)
	var actor := CharacterBody3D.new()
	actor.set_script(load("res://tests/access_probe.gd"))
	actor.floor_snap_length = 0.5
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 2.7
	collider.shape = shape
	collider.position.y = 1.35
	actor.add_child(collider)
	root.add_child(actor)
	await physics_frame
	await physics_frame
	var failures: Array = []
	var passed := 0
	for stair in scene.find_children("Escalera*", "Node3D", true, false):
		var steps: Array[MeshInstance3D] = []
		for step in stair.get_children():
			if step is MeshInstance3D and str(step.name).begins_with("Step"): steps.append(step)
		if steps.is_empty(): continue
		steps.sort_custom(func(a,b): return a.global_position.x < b.global_position.x)
		var first: AABB = steps.front().global_transform * steps.front().get_aabb()
		var last: AABB = steps.back().global_transform * steps.back().get_aabb()
		for offset in [-3.5, 0.0, 3.5]:
			for direction in [1.0, -1.0]:
				var start := first if direction > 0 else last
				actor.global_position = Vector3(start.get_center().x, start.end.y+0.1, start.get_center().z+offset)
				actor.velocity = Vector3.ZERO
				for frame in range(20):
					await physics_frame
					actor.velocity = Vector3(0,-2,0)
					actor.move_and_slide()
				var target: float = last.get_center().x if direction > 0 else first.get_center().x
				var reached := false
				var stalled := 0
				for frame in range(1200):
					await physics_frame
					var old_x := actor.global_position.x
					actor.velocity.x = 5.5 * direction
					actor.velocity.z = 0
					actor.velocity.y = -1 if actor.is_on_floor() else actor.velocity.y-14.0/60.0
					actor.move_and_slide()
					if (actor.global_position.x-target)*direction >= -0.15:
						reached = true
						break
					stalled = stalled+1 if absf(actor.global_position.x-old_x)<0.002 else 0
					if stalled>60: break
				if reached: passed += 1
				else: failures.append({"stair": str(stair.get_path()), "offset": offset, "direction": direction, "position": str(actor.global_position)})
	print("WALK_CHECK passed=", passed, " failures=", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
