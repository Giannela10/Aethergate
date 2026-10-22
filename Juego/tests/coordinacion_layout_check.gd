extends SceneTree
## Checks the actual scene furniture counts and body clearance at unchanged doors.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var campus = load("res://Main.tscn").instantiate()
	for node in campus.find_children("*", "", true, false):
		if node.get_script() != null:
			node.set_script(null)
	campus.set_script(null)
	root.add_child(campus)
	await physics_frame
	await physics_frame
	var office = campus.get_node("Piso1/InteriorCoordinacion")
	var desks := 0
	for child in office.get_children():
		if child.has_node("TableroMadera"):
			desks += 1
	if desks != 8:
		failures.append("Expected eight existing desks, got %d" % desks)
	var capsule := CapsuleShape3D.new()
	capsule.radius = .45
	capsule.height = 1.8
	var routes: Array = [
		[Vector3(71,1.3,-124),Vector3(71,1.3,-111)],
		[Vector3(71,1.3,-111),Vector3(70.2,1.3,-107)],
		[Vector3(70.2,1.3,-107),Vector3(70.2,1.3,-101.7)],
		# The meeting-room glass now begins east of the open-office aisle.
		# Its separate entrance and internal paths are covered by meeting_check.
		[Vector3(35.5,1.3,-101.7),Vector3(70.2,1.3,-101.7)],
		[Vector3(70.2,1.3,-101.7),Vector3(36.2,1.3,-101.7)],
		[Vector3(36.2,1.3,-101.7),Vector3(36.2,1.3,-110.7)],
		[Vector3(80.4,1.3,-119.3),Vector3(80.4,1.3,-112)],
	]
	# Walk between the current desk/chair groups, never through their centers.
	for x in [48.0,58.0,69.0,70.2]:
		routes.append([Vector3(x,1.3,-101.7),Vector3(x,1.3,-94.5)])
	var space = root.world_3d.direct_space_state
	for i in range(routes.size()):
		var start: Vector3 = routes[i][0]
		var end: Vector3 = routes[i][1]
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY,start)
		query.motion = end-start
		query.collision_mask = 1
		var sweep = space.cast_motion(query)
		if sweep[0] < .999:
			failures.append("Blocked route %d: %s -> %s" % [i,start,end])
			query.transform.origin = start.lerp(end,minf(sweep[1]+.02,1.0))
			query.motion = Vector3.ZERO
			for hit in space.intersect_shape(query):
				print("ROUTE_BLOCKER ",i," ",hit.collider.get_path()," world=",hit.collider.global_position," probe=",query.transform.origin," fraction=",sweep)
		for sample in range(11):
			var p = start.lerp(end,sample/10.0)
			var ray = PhysicsRayQueryParameters3D.create(p,p-Vector3(0,2,0),1)
			if space.intersect_ray(ray).is_empty():
				failures.append("Missing floor at %s" % p)
	for failure in failures:
		push_error(failure)
	print("COORDINACION_LAYOUT_CHECK desks=",desks," routes=",routes.size()," floor_samples=",routes.size()*11," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
