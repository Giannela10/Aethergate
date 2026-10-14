extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var campus := load("res://Main.tscn").instantiate() as Node3D
	campus.get_node("GameplayManager").free()
	root.add_child(campus)
	var probe := CharacterBody3D.new()
	probe.set_script(load("res://tests/access_probe.gd"))
	probe.floor_snap_length = 0.6
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 2.7
	collision.shape = shape
	collision.position.y = 1.35
	probe.add_child(collision)
	campus.add_child(probe)
	probe.global_position = Vector3(-21.5, 48.12, -127.8)
	var failures: Array[String] = []
	for target in [Vector3(-3, 53.5, -127.8), Vector3(20.4, 60.1585, -127.8), Vector3(-3, 53.5, -127.8), Vector3(-21.5, 47.975, -127.8)]:
		var reached := false
		for frame in range(900):
			await physics_frame
			var offset: Vector3 = target - probe.global_position
			if Vector2(offset.x, offset.z).length() < 0.18 and absf(offset.y) < 0.6:
				reached = true
				break
			probe.velocity.x = signf(offset.x) * minf(5.5, absf(offset.x) * 60.0)
			probe.velocity.y = 0 if probe.is_on_floor() else probe.velocity.y - 14.0 / 60.0
			probe.move_and_slide()
		if not reached:
			var blockers: Array[String] = []
			for i in range(probe.get_slide_collision_count()):
				blockers.append(str(probe.get_slide_collision(i).get_collider().get_path()))
			failures.append("Objetivo %s: %s en %s" % [target, blockers, probe.global_position])
	print("PISO5_ESCALERA ", JSON.stringify({"tramos": 4, "failures": failures}))
	var result := 0 if failures.is_empty() else 1
	campus.free()
	quit(result)
