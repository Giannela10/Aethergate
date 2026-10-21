extends SceneTree

const LEVELS := [-12.058385849, 0.0, 12.058385849, 23.967668533, 35.674415588, 47.974849701, 60.158504486, 71.942184448, 83.913551331]
var campus: Node3D
var probe: CharacterBody3D
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func walk(z: float, floor_y: float, title: String) -> void:
	for frame in range(300):
		await physics_frame
		var offset := z - probe.global_position.z
		if absf(offset) < 0.16:
			return
		probe.velocity = Vector3(0, 0 if probe.is_on_floor() else probe.velocity.y - 14.0 / 60.0, signf(offset) * minf(5.0, absf(offset) * 60.0))
		probe.move_and_slide()
		if probe.global_position.y < floor_y - 1:
			break
	var blockers: Array[String] = []
	for i in range(probe.get_slide_collision_count()):
		blockers.append(str(probe.get_slide_collision(i).get_collider().get_path()))
	failures.append("%s: %s en %s" % [title, blockers, probe.global_position])

func run() -> void:
	campus = load("res://Main.tscn").instantiate()
	campus.get_node("GameplayManager").free()
	root.add_child(campus)
	probe = CharacterBody3D.new()
	probe.set_script(load("res://tests/access_probe.gd"))
	probe.add_to_group("player")
	probe.floor_snap_length = 0.6
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 2.7
	collision.shape = shape
	collision.position.y = 1.35
	probe.add_child(collision)
	campus.add_child(probe)
	for index in range(LEVELS.size()):
		var y: float = LEVELS[index]
		probe.global_position = Vector3(-20.7, y + 0.2, -146.4)
		probe.velocity = Vector3.ZERO
		for frame in range(40):
			await physics_frame
			probe.velocity = Vector3(0, probe.velocity.y - 14.0 / 60.0, 0)
			probe.move_and_slide()
		await walk(-150.2, y, "Entrada emergencia piso %s" % (index - 1))
		await walk(-146.4, y, "Salida emergencia piso %s" % (index - 1))
		var floor_node := campus.get_node("PisoMenos1" if index == 0 else "Piso%d" % index)
		var lobby := floor_node.get_node_or_null("VestibuloAscensores")
		if lobby:
			var aperture := AABB(Vector3(-22.2, y + 0.2, -149.6), Vector3(3.0, 3.0, 3.1))
			for name in ["CartelPlano", "CabeceraPlano", "RevestimientoCostado"]:
				var panel := lobby.get_node_or_null(name) as MeshInstance3D
				if panel and panel.is_visible_in_tree() and aperture.intersects(panel.global_transform * panel.get_aabb()):
					failures.append("Panel tapa visualmente la salida: %s" % panel.get_path())
	print("SALIDAS_EMERGENCIA ", JSON.stringify({"pisos": 9, "recorridos": 18, "failures": failures}))
	var result := 0 if failures.is_empty() else 1
	campus.free()
	quit(result)
