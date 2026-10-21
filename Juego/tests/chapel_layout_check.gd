extends SceneTree
## Physical clearance of the existing entrance, rear aisle and altar approach.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var campus = load("res://Main.tscn").instantiate()
	# Remove runtime behaviours only in this disposable test instance. Disabling
	# process_mode would also remove collision bodies from the physics space.
	for node in campus.find_children("*", "", true, false):
		if node.get_script() != null:
			node.set_script(null)
	if campus.get_script() != null:
		campus.set_script(null)
	root.add_child(campus)
	await physics_frame
	await physics_frame
	var chapel = campus.get_node("Piso1/PasilloDerechoYCapilla/Capilla")
	assert(chapel.get_node("CruzVertical").position.x > chapel.get_node("MesaAltar").position.x)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	# Body-sized sweeps, not just visibility rays. Floor clearance is checked below.
	var route: Array[Vector3] = [
		Vector3(63.8,1.3,-141.5), Vector3(63.8,1.3,-147.8),
		Vector3(55.05,1.3,-147.8), Vector3(55.05,1.3,-160.2),
		Vector3(65,1.3,-160.2), Vector3(65,1.3,-149.2),
		Vector3(63.8,1.3,-147.8), Vector3(63.8,1.3,-141.5)]
	var space = root.world_3d.direct_space_state
	for i in range(route.size()-1):
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY, route[i])
		query.motion = route[i+1]-route[i]
		query.collision_mask = 1
		var sweep = space.cast_motion(query)
		if sweep[0] < 0.999:
			failures.append("Blocked route %d: %s -> %s (fraction %.3f)" % [i,route[i],route[i+1],sweep[0]])
		for step in range(11):
			var p = route[i].lerp(route[i+1],step/10.0)
			var ray = PhysicsRayQueryParameters3D.create(p,p-Vector3(0,2,0),1)
			if space.intersect_ray(ray).is_empty():
				failures.append("Missing floor at %s" % p)
	# Cross each gap between rows with a capsule slightly larger than the player.
	for x in [57.5,59.9,62.3]:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY,Vector3(x,1.3,-147.8))
		query.motion = Vector3(0,0,-12.4)
		query.collision_mask = 1
		if space.cast_motion(query)[0] < .999:
			failures.append("Blocked between benches at x=%.1f" % x)
	for failure in failures:
		push_error(failure)
	print("CHAPEL_LAYOUT_CHECK routes=10 floor_samples=77 failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
