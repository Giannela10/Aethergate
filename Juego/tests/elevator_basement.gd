extends Node3D
const BASEMENT_Y := -12.058385849
var probe: CharacterBody3D
var lifts: Array
var lift_index := 0
var phase := "call"
var elapsed := 0.0
var stable := 0.0
var results: Array = []
var failures: Array = []
var completed := false
var call_pressed := false

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
	lifts = get_node("Campus/SistemasCompartidos/AscensoresEstudiantiles").get_children()
	probe = CharacterBody3D.new()
	probe.set_script(load("res://tests/access_probe.gd"))
	probe.floor_snap_length = 0.6
	probe.add_to_group("player")
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 2.7
	collision.shape = shape
	collision.position.y = 1.35
	probe.add_child(collision)
	add_child(probe)
	start_lift()

func start_lift() -> void:
	var lift: Node3D = lifts[lift_index]
	probe.position = Vector3(lift.position.x, BASEMENT_Y + 0.15, -147.5)
	probe.velocity = Vector3.ZERO
	phase = "call"
	elapsed = 0.0
	stable = 0.0
	call_pressed = false

func next_phase(value: String) -> void:
	phase = value
	elapsed = 0.0
	stable = 0.0

func select_floor(code: Key) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.pressed = true
	lifts[lift_index]._unhandled_key_input(key)

func _physics_process(delta: float) -> void:
	if completed:
		return
	elapsed += delta
	var lift = lifts[lift_index]
	var destination := Vector3(lift.position.x, probe.position.y, -154.0 if phase == "enter" else -147.5)
	var horizontal := Vector3.ZERO
	if phase in ["enter", "exit"]:
		var offset := destination - probe.position
		offset.y = 0.0
		horizontal = offset.normalized() * minf(3.0, offset.length() / delta)
	probe.velocity.x = horizontal.x
	probe.velocity.z = horizontal.z
	probe.velocity.y = 0.0 if probe.is_on_floor() else probe.velocity.y - 14.0 * delta
	probe.move_and_slide()
	match phase:
		"call":
			if elapsed > 0.7 and not call_pressed:
				Input.action_press("interact")
				call_pressed = true
			elif call_pressed:
				Input.action_release("interact")
				if lift.destination == lift.BASEMENT_INDEX:
					next_phase("wait_basement")
		"wait_basement":
			if not lift.moving and lift.current_floor == lift.BASEMENT_INDEX:
				stable += delta
				if stable > 0.7:
					next_phase("enter")
		"enter":
			if probe.position.distance_to(destination) < 0.15 and lift._inside:
				select_floor(KEY_8 if lift_index == lifts.size() - 1 else KEY_1)
				next_phase("up")
		"up":
			var expected := 7 if lift_index == lifts.size() - 1 else 0
			if not lift.moving and lift.current_floor == expected:
				stable += delta
				if stable > 0.7:
					if absf(probe.position.y - lift.LEVELS[expected]) > 0.12:
						finish_lift(false, "El pasajero no acompaña la subida")
						return
					select_floor(KEY_0)
					next_phase("down")
		"down":
			if not lift.moving and lift.current_floor == lift.BASEMENT_INDEX:
				stable += delta
				if stable > 0.7:
					if absf(probe.position.y - BASEMENT_Y) > 0.12:
						finish_lift(false, "El pasajero no acompaña la bajada")
						return
					if lift._gates[lift.BASEMENT_INDEX].position.x < 4.3 or lift._gates[0].position.x > 0.1:
						finish_lift(false, "Las puertas de piso no corresponden a la cabina")
						return
					next_phase("exit")
		"exit":
			if probe.position.distance_to(destination) < 0.15:
				finish_lift(absf(probe.position.y - BASEMENT_Y) < 0.12, "Salida al piso −1")
	if elapsed > 35.0 or probe.position.y < -20.0:
		finish_lift(false, "Tiempo agotado o caída")

func finish_lift(passed: bool, message: String) -> void:
	Input.action_release("interact")
	var blockers: Array = []
	for i in probe.get_slide_collision_count():
		blockers.append(str(probe.get_slide_collision(i).get_collider().get_path()))
	var result := {"lift": str(lifts[lift_index].name), "passed": passed, "phase": phase, "message": message, "position": str(probe.position), "blockers": blockers if not passed else []}
	results.append(result)
	if not passed:
		failures.append(result)
	print("ELEVATOR_BASEMENT_ROUTE " + JSON.stringify(result))
	lift_index += 1
	if lift_index < lifts.size():
		start_lift()
	else:
		completed = true
		print("ELEVATOR_BASEMENT_RESULT " + JSON.stringify({"tested": results.size(), "failed": failures}))
		get_tree().quit(0 if failures.is_empty() else 1)
