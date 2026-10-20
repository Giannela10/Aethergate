extends Node3D
const LEVELS: Array[float] = [-12.058385849, 0.0, 12.058385849, 23.967668533, 35.674415588, 47.974849701, 60.158504486, 71.942184448, 83.913551331]
var routes: Array = []
var results: Array = []
var route_index := 0
var waypoint := 1
var elapsed := 0.0
var wait_time := 0.0
var probe: CharacterBody3D
var finished := false

func _ready() -> void:
	# This fixture replaces Player with a capsule and exercises standalone lifts/routes.
	# Remove campaign before its deferred boot; it must not reference the deleted Player.
	var campaign := get_node_or_null("Campus/CampusCampaign")
	if campaign != null: campaign.free()
	var credential := get_node_or_null("Campus/Piso8/EncuentroDirectorInformatica/CredencialDirector")
	if credential != null: credential.persist = false
	var manager := get_node("Campus/GameplayManager")
	manager.process_mode = Node.PROCESS_MODE_DISABLED
	for player in get_tree().get_nodes_in_group("player"):
		player.remove_from_group("player")
	manager.queue_free()
	probe = CharacterBody3D.new()
	probe.set_script(load("res://tests/access_probe.gd"))
	probe.floor_snap_length = 0.6
	probe.add_to_group("player")
	add_child(probe)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 2.7
	collision.shape = shape
	collision.position.y = 1.35
	probe.add_child(collision)
	for i in range(8):
		var y := LEVELS[i]
		var rise := (LEVELS[i + 1] - y) / 4.0
		var path: Array[Vector3] = [Vector3(-20.7, y + 0.15, -146.8), Vector3(-20.7, y, -149.8), Vector3(-22.65, y, -149.8)]
		for flight in range(4):
			var outward := flight % 2 == 0
			var x := -22.65 if outward else -18.75
			var end_y := y + rise * (flight + 1)
			path.append(Vector3(x, end_y, -159.5 if outward else -149.8))
			if flight < 3:
				path.append(Vector3(-18.75 if outward else -22.65, end_y, -159.5 if outward else -149.8))
		path.append(Vector3(-20.7, LEVELS[i + 1], -149.8))
		path.append(Vector3(-20.7, LEVELS[i + 1], -146.8))
		routes.append({"name": "Emergencia_Subida_%d" % i, "path": path})
		var down := path.duplicate()
		down.reverse()
		down[0].y += 0.15
		routes.append({"name": "Emergencia_Bajada_%d" % i, "path": down})
	var central: Array[Vector3] = [Vector3(-21.8, LEVELS[0] + 0.15, -127.8), Vector3(-3.0, LEVELS[0] + 5.48, -127.8), Vector3(20.4, 0.0, -127.8)]
	routes.append({"name": "Central_Subida", "path": central})
	var central_down := central.duplicate()
	central_down.reverse()
	central_down[0].y += 0.15
	routes.append({"name": "Central_Bajada", "path": central_down})
	var existing_central: Array[Vector3] = [Vector3(-21.8, 0.15, -127.8), Vector3(-3.0, 5.48, -127.8), Vector3(20.4, LEVELS[2], -127.8)]
	routes.append({"name": "Central_Existente_Subida", "path": existing_central})
	var existing_down := existing_central.duplicate()
	existing_down.reverse()
	existing_down[0].y += 0.15
	routes.append({"name": "Central_Existente_Bajada", "path": existing_down})
	start_route()

func start_route() -> void:
	elapsed = 0
	wait_time = 0
	waypoint = 1
	probe.position = routes[route_index].path[0]
	probe.velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	wait_time += delta
	var goal: Vector3 = routes[route_index].path[waypoint]
	var offset := Vector3(goal.x - probe.position.x, 0, goal.z - probe.position.z)
	if offset.length() < 0.18 and absf(goal.y - probe.position.y) < 0.5:
		waypoint += 1
		if waypoint >= routes[route_index].path.size():
			finish_route(true)
			return
		goal = routes[route_index].path[waypoint]
		offset = Vector3(goal.x - probe.position.x, 0, goal.z - probe.position.z)
	var speed := minf(5.5, offset.length() / delta) if wait_time > 1.0 else 0.0
	probe.velocity.x = offset.normalized().x * speed
	probe.velocity.z = offset.normalized().z * speed
	probe.velocity.y = 0.0 if probe.is_on_floor() else probe.velocity.y - 14.0 * delta
	probe.move_and_slide()
	if elapsed > 24.0 or probe.position.y < -20.0:
		finish_route(false)

func finish_route(passed: bool) -> void:
	var blockers: Array = []
	for i in probe.get_slide_collision_count():
		blockers.append(str(probe.get_slide_collision(i).get_collider().get_path()))
	var result := {"route": routes[route_index].name, "passed": passed, "position": str(probe.position), "waypoint": waypoint, "blockers": blockers if not passed else []}
	results.append(result)
	print("BASEMENT_ROUTE " + JSON.stringify(result))
	route_index += 1
	if route_index < routes.size():
		start_route()
	else:
		finished = true
		var ray := PhysicsRayQueryParameters3D.create(Vector3(0, 0.5, -113), Vector3(0, -15, -113))
		ray.exclude = [probe.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		var aperture_ok: bool = not hit.is_empty() and absf(hit.position.y - LEVELS[0]) < 0.1
		var doors := get_tree().get_nodes_in_group("emergency_door").size()
		var failed := results.filter(func(result): return not result.passed)
		print("BASEMENT_ACCESS_RESULT " + JSON.stringify({"tested": results.size(), "failed": failed, "aperture_open": aperture_ok, "doors": doors}))
		get_tree().quit(0 if failed.is_empty() and aperture_ok and doors == 9 else 1)
