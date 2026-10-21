extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	var actor := CharacterBody3D.new()
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
	var terrace := scene.get_node("Piso 5/TerrazaPicnic") as Node3D
	var sample_x: Array[float] = []
	for center in terrace.get_meta("entradas_x"):
		for offset in [-2.0,0.0,2.0]: sample_x.append(float(center)+offset)
	for x in sample_x:
		for reverse in [false,true]:
			actor.global_position = Vector3(x,48.1,-79.0 if reverse else -125.0)
			actor.velocity = Vector3.ZERO
			var target := -125.0 if reverse else -79.0
			var direction := -1.0 if reverse else 1.0
			var reached := false
			var stalled := 0
			for frame in range(1800):
				await physics_frame
				var old := actor.global_position
				actor.velocity.z = direction*5.5
				actor.velocity.x = 0
				actor.velocity.y = -1 if actor.is_on_floor() else actor.velocity.y-14.0/60
				actor.move_and_slide()
				if (actor.global_position.z-target)*direction>-0.15:
					reached = true
					break
				stalled = stalled+1 if absf(actor.global_position.z-old.z)<0.002 else 0
				if stalled>60 or actor.global_position.y<45: break
			if reached: passed+=1
			else:
				var blockers: Array = []
				for i in actor.get_slide_collision_count(): blockers.append(str(actor.get_slide_collision(i).get_collider().get_path()))
				failures.append({"x":x,"reverse":reverse,"position":str(actor.global_position),"blockers":blockers})
	print("TERRACE_ACCESS passed=",passed," failures=",JSON.stringify(failures))
	var protection_failures: Array = []
	var protected := 0
	for well in terrace.get_node("BarandasVacios").get_children():
		var rail := well.get_node("VidrioFrente") as CSGBox3D
		var x := rail.global_position.x
		actor.global_position = Vector3(x,48.1,-108)
		actor.velocity = Vector3.ZERO
		for frame in range(180):
			await physics_frame
			actor.velocity = Vector3(0,-1,-5.5)
			actor.move_and_slide()
		if actor.global_position.z < -111 or actor.global_position.y < 47:
			protection_failures.append({"well":str(well.name),"position":str(actor.global_position)})
		else: protected+=1
		var p := Vector3(x,48.2,-116)
		var ray := PhysicsRayQueryParameters3D.create(p,p-Vector3.UP*2)
		ray.exclude = [actor.get_rid()]
		if not scene.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): protection_failures.append({"well":str(well.name),"issue":"floor still fills the void"})
	print("TERRACE_WELLS protected=",protected," failures=",JSON.stringify(protection_failures))
	var repairs = scene.get_node("ContinuidadPisos").holes(4)
	var refill_failures: Array = []
	for well in terrace.get_node("BarandasVacios").get_children():
		var area: Rect2 = well.get_meta("area_no_transitable")
		for patch in repairs:
			if area.intersection(patch).get_area()>0.01: refill_failures.append(str(well.name))
	print("TERRACE_REPAIR_EXCLUSIONS failures=",JSON.stringify(refill_failures))
	quit()
