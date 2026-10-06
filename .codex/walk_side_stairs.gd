extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	scene.set_script(null)
	root.add_child(scene)
	var actor := CharacterBody3D.new()
	actor.floor_snap_length = 0.5
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 2.7
	capsule.radius = 0.45
	collider.shape = capsule
	collider.position.y = 1.35
	actor.add_child(collider)
	root.add_child(actor)
	await physics_frame
	await physics_frame
	var failures: Array = []
	var passed := 0
	for stair in scene.find_children("Escalera lado*", "Node3D", true, false):
		var steps: Array[MeshInstance3D] = []
		for child in stair.get_children():
			if child is MeshInstance3D and (str(child.name).begins_with("Escalera Norte") or str(child.name).begins_with("Escalera Sur")): steps.append(child)
		if steps.is_empty(): continue
		steps.sort_custom(func(a,b): return a.global_position.y<b.global_position.y)
		var first: AABB = steps.front().global_transform*steps.front().get_aabb()
		var last: AABB = steps.back().global_transform*steps.back().get_aabb()
		var landing: AABB = steps[9].global_transform*steps[9].get_aabb()
		var route: Array[Vector3] = [
			Vector3(first.get_center().x,first.end.y+0.1,first.get_center().z),
			Vector3(first.get_center().x,landing.end.y+0.1,-159.6),
			Vector3(last.get_center().x,landing.end.y+0.1,-159.6),
			Vector3(last.get_center().x,last.end.y+0.1,-139.5)]
		for reverse in [false,true]:
			var points: Array[Vector3] = route.duplicate()
			if reverse: points.reverse()
			actor.global_position = points.front()
			actor.velocity = Vector3.ZERO
			var success := true
			for target in points:
				var reached := false
				var stalled := 0
				for frame in range(1200):
					await physics_frame
					var delta := Vector3(target.x-actor.global_position.x,0,target.z-actor.global_position.z)
					if delta.length()<0.15:
						reached = true
						break
					var old := actor.global_position
					var direction := delta.normalized()*minf(5.5,delta.length()*60)
					actor.velocity.x = direction.x
					actor.velocity.z = direction.z
					actor.velocity.y = -1 if actor.is_on_floor() else actor.velocity.y-14.0/60
					actor.move_and_slide()
					stalled = stalled+1 if Vector2(actor.global_position.x-old.x,actor.global_position.z-old.z).length()<0.002 else 0
					if stalled>60: break
				if not reached:
					var blockers: Array = []
					for i in actor.get_slide_collision_count(): blockers.append(str(actor.get_slide_collision(i).get_collider().get_path()))
					failures.append({"stair":str(stair.get_path()),"reverse":reverse,"position":str(actor.global_position),"target":str(target),"blockers":blockers})
					success = false
					break
			if success: passed+=1
	print("SIDE_WALK_CHECK passed=",passed," failures=",JSON.stringify(failures))
	quit()
