extends SceneTree
var failures: Array[String] = []
var probe: CharacterBody3D
var campus: Node3D

func _initialize() -> void:
	call_deferred("run")

func walk(points: Array[Vector3], title: String) -> void:
	var cafeteria := campus.get_node("Piso3/LocalComidaReferencia") as Node3D
	if not title.begins_with("Entrada y salida de la sala"):
		var factor := float(cafeteria.get_meta("profundidad", 23.0)) / 23.0
		for i in range(points.size()):
			points[i].x = cafeteria.global_position.x + (points[i].x - 69.3) * factor
			points[i].y = cafeteria.global_position.y
			points[i].z += cafeteria.global_position.z + 109.85
	else:
		var room_origin := campus.get_node("Piso3/SalaDetrasLocal").global_position as Vector3
		for i in range(points.size()):
			points[i].x += room_origin.x
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
	probe.add_to_group("player")
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
	await walk([Vector3(39.4, y, -125.2), Vector3(39.4, y, -120.7), Vector3(39.4, y, -125.2)], "Entrada y salida de la sala detrás del negocio")
	for x in [47.5, 51.7, 56.5]:
		var offset: float = campus.get_node("Piso3/SalaDetrasLocal").global_position.x
		var ray := PhysicsRayQueryParameters3D.create(Vector3(x + offset, y + 1.5, -125), Vector3(x + offset, y + 1.5, -119))
		var hit := campus.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or not str(hit.collider.get_path()).contains("CierrePasoContiguo"):
			failures.append("El paso contiguo debe quedar cerrado en X=%s" % x)
	var cafeteria := campus.get_node("Piso3/LocalComidaReferencia") as Node3D
	if cafeteria.has_node("CieloHormigon") or cafeteria.has_node("CieloMadera"):
		failures.append("El techo debe dejar abierta la vista desde el piso 4")
	var floor_mesh := cafeteria.get_node("BaldosasLocal") as MeshInstance3D
	var floor_bounds := floor_mesh.global_transform * floor_mesh.get_aabb()
	var classroom := campus.get_node("Piso3/SalaDetrasLocal/Sala303") as Node3D
	if absf(floor_bounds.position.x - (classroom.global_position.x + 6.7)) > 0.15:
		failures.append("La cafetería debe completar la franja hasta el borde de la sala")
	for x in [50.0, 55.0, 60.0]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(x, 36, -110.5), Vector3(x, 28, -110.5))
		var hit := campus.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			failures.append("Vista tapada desde el piso 4 en X=%s: %s" % [x, hit.collider.get_path()])
	print("LOCAL_PISO3_ROUTES_RESULT ", JSON.stringify({"tested": 13, "failures": failures}))
	campus.free()
	quit(0 if failures.is_empty() else 1)
