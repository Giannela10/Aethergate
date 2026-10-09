extends Node3D
var checks: Array = []
var results: Array = []
var finished := false

func _ready() -> void:
	var manager := get_node_or_null("Campus/GameplayManager")
	if manager:
		manager.queue_free()
	var paths := [
		[Vector3(70, 12.3, -118.5), Vector3(66, 0, -118.5), Vector3(48, 0, -118.5)],
		[Vector3(70, 12.3, -90.5), Vector3(66, 0, -90.5), Vector3(48, 0, -90.5)],
		[Vector3(48, 9.15, -104.5), Vector3(66, 0, -104.5)]
	]
	for i in paths.size():
		var body := CharacterBody3D.new()
		body.name = "Probe" + str(i)
		body.floor_snap_length = 0.5
		add_child(body)
		var collision := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.45
		capsule.height = 1.8
		collision.shape = capsule
		collision.position.y = 0.9
		body.add_child(collision)
		body.position = paths[i][0]
		checks.append({"body": body, "path": paths[i], "index": 1, "time": 0.0, "done": false})

func _physics_process(delta: float) -> void:
	for check in checks:
		if check.done:
			continue
		check.time += delta
		var body: CharacterBody3D = check.body
		var goal: Vector3 = check.path[check.index]
		var direction := Vector3(goal.x - body.position.x, 0, goal.z - body.position.z)
		if direction.length() < 0.15:
			check.index += 1
			if check.index >= check.path.size():
				results.append({"route": body.name, "passed": true, "position": str(body.position)})
				check.done = true
				continue
			goal = check.path[check.index]
			direction = Vector3(goal.x - body.position.x, 0, goal.z - body.position.z)
		var speed := minf(8, direction.length() / delta)
		direction = direction.normalized()
		body.velocity.x = direction.x * speed
		body.velocity.z = direction.z * speed
		if body.is_on_floor():
			body.velocity.y = 0
		else:
			body.velocity.y -= 14 * delta
		body.move_and_slide()
		if check.time > 12:
			var blockers: Array = []
			for i in body.get_slide_collision_count():
				blockers.append(str(body.get_slide_collision(i).get_collider().get_path()))
			results.append({"route": body.name, "passed": false, "position": str(body.position), "blockers": blockers})
			check.done = true
	if results.size() == checks.size() and not finished:
		finished = true
		print("AUDITORIO_ACCESS_RESULT " + JSON.stringify(results))
