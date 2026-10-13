extends SceneTree
var failures: Array[String] = []
var probe: CharacterBody3D
var campus: Node3D

func _initialize() -> void:
	call_deferred("run")

func walk(points: Array[Vector3], title: String) -> void:
	probe.global_position = points[0] + Vector3.UP * 0.2
	probe.velocity = Vector3.ZERO
	for i in range(15):
		await physics_frame
		probe.velocity.y -= 14.0 / 60.0
		probe.move_and_slide()
	for target in points.slice(1):
		var reached := false
		for frame in range(1200):
			await physics_frame
			var offset: Vector3 = target - probe.global_position
			offset.y = 0
			if offset.length() < 0.18:
				reached = true
				break
			var step: Vector3 = offset.normalized() * minf(6.0, offset.length() * 60.0)
			probe.velocity.x = step.x
			probe.velocity.z = step.z
			probe.velocity.y = 0 if probe.is_on_floor() else probe.velocity.y - 14.0 / 60.0
			probe.move_and_slide()
			if probe.global_position.y < target.y - 2.0:
				break
		if not reached:
			var blockers: Array[String] = []
			for i in probe.get_slide_collision_count():
				blockers.append(str(probe.get_slide_collision(i).get_collider().get_path()))
			failures.append("%s: %s en %s" % [title, blockers, probe.global_position])
			break

func run() -> void:
	campus = load("res://Main.tscn").instantiate()
	campus.get_node("GameplayManager").free()
	root.add_child(campus)
	probe = CharacterBody3D.new()
	probe.set_script(load("res://tests/access_probe.gd"))
	probe.floor_snap_length = 0.5
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 2.7
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 1.35
	probe.add_child(collision)
	campus.add_child(probe)
	var y := 23.985
	await walk([Vector3(72, y, -109.85), Vector3(67.6, y, -109.85), Vector3(50.6, y, -109.85), Vector3(72, y, -109.85)], "Entrada orientada al este, mostrador y salida")
	await walk([Vector3(66.6, y, -109.85), Vector3(66.6, y, -104.9), Vector3(63.6, y, -104.9), Vector3(66.6, y, -104.9), Vector3(66.6, y, -109.85)], "Acceso a sillones")
	for z in [-110.85, -108.85]:
		await walk([Vector3(67.6, y, z), Vector3(50.6, y, z), Vector3(67.6, y, z)], "Circulación entre mesas %s" % z)
	print("LOCAL_PISO3_ROUTES_RESULT ", JSON.stringify({"tested": 4, "failures": failures}))
	campus.free()
	quit(0 if failures.is_empty() else 1)
