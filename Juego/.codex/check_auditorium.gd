extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	var actor := CharacterBody3D.new()
	actor.floor_snap_length = 0.5
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 2.7
	col.shape = shape
	col.position.y = 1.35
	actor.add_child(col)
	root.add_child(actor)
	await physics_frame
	await physics_frame
	var failures: Array = []
	var passed := 0
	for z in [-118.5,-90.5,-104.5]:
		for reverse in [false,true]:
			var points := [Vector3(72,12.15,z),Vector3(65.5,12.15,z),Vector3(34 if z < -97.55 else 45,9.8,z)] if z != -104.5 else [Vector3(65.5,12.15,z),Vector3(34 if z < -97.55 else 45,9.8,z)]
			if reverse: points.reverse()
			actor.global_position = points[0]
			actor.velocity = Vector3.ZERO
			var success := true
			for target in points:
				var reached := false
				var stalled := 0
				for frame in range(2400):
					await physics_frame
					var delta: Vector3 = target-actor.global_position
					delta.y = 0
					if delta.length()<0.15:
						reached = true
						break
					var old := actor.global_position
					var velocity := delta.normalized()*minf(2.5,delta.length()*60)
					actor.velocity.x = velocity.x
					actor.velocity.z = velocity.z
					actor.velocity.y = 0 if actor.is_on_floor() else actor.velocity.y-14.0/60
					actor.move_and_slide()
					stalled = stalled+1 if Vector2(actor.global_position.x-old.x,actor.global_position.z-old.z).length()<0.002 else 0
					if stalled>90: break
				if not reached:
					var blockers: Array = []
					for i in actor.get_slide_collision_count(): blockers.append(str(actor.get_slide_collision(i).get_collider().get_path()))
					failures.append({"z":z,"reverse":reverse,"position":str(actor.global_position),"blockers":blockers})
					success = false
					break
			if success: passed+=1
	print("AUDITORIUM_WALK paths=",passed," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
