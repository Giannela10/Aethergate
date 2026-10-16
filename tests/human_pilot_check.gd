extends "res://tests/upper_campus_check.gd"
var pilot: Node3D
var pilot_report: Dictionary = {}
var pilot_finished := false

func _ready() -> void:
	super._ready()
	pilot_run.call_deferred()

func window_sample() -> Dictionary:
	await get_tree().create_timer(2).timeout
	var samples: Array = []
	for i in 4:
		await get_tree().create_timer(1).timeout
		samples.append({"fps":Performance.get_monitor(Performance.TIME_FPS),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	return {"samples":samples}

func pilot_run() -> void:
	while not finished: await get_tree().process_frame
	preview_boss("profesor_ingles")
	var origin: Vector3 = c.player.global_position
	pilot_report = {"fixture":"UpperCampusCheck: two Main loads, preview_boss profesor_ingles","gpu_ms":null,"baseline_checks":checks,"baseline_failures":failures.duplicate(),"scenarios":{}}
	pilot_report.scenarios.A_without_pilot = await window_sample()
	pilot = preload("res://tests/human_pilot.gd").new()
	c.get_parent().add_child(pilot)
	pilot.global_position = c.get_node("UpperCampusBosses").actors.profesor_ingles.home+Vector3(-1.15,0,-0.3)
	var near_position: Vector3 = pilot.global_position
	check(not pilot.accepted,"Static unrigged GLB rejected by adapter")
	check(pilot.body.fall_pivot.visible,"Rejected GLB leaves fallback visible")
	var poses := {}
	for state in ["IDLE","WALK","RUN","ATTACK_LIGHT","DEATH","SIT"]:
		pilot.set_test_state(state)
		pilot.body.set_activity_level(0)
		pilot.body.lod_tick = 0; pilot.body.update_visual_lod(0)
		pilot._process(0.05 if state != "DEATH" else 1.0)
		poses[state] = pilot.body.visual_state
		check(pilot.body.visual_state == state,"Procedural fallback "+state)
	check(pilot.body.weapon_node.get_parent() == pilot.body.weapon_socket,"Existing Palo remains in fallback WeaponSocket")
	check(pilot.body.backpack_socket.get_child_count() > 0,"Existing backpack retained")
	pilot.set_test_state("IDLE")
	pilot.body.look_controller.target = c.player
	for i in 20: pilot._process(0.05)
	check(absf(pilot.body.look_controller.yaw) <= pilot.body.look_controller.max_yaw,"Fallback gaze bounded")
	pilot_report.poses = poses
	pilot_report.normalization_scale = pilot.normalization_scale
	pilot_report.imported_accepted = pilot.accepted
	pilot_report.socket_scope = "Procedural sockets only; no GLB bones exist"
	pilot.set_mode(true)
	pilot_report.scenarios.B_static_glb_high = await window_sample()
	pilot.set_mode(false); pilot.set_test_state("RUN")
	pilot_report.scenarios.C_procedural_run_fallback = await window_sample()
	pilot.set_mode(true); pilot.global_position = origin+Vector3(45,0,0)
	pilot_report.scenarios.D_static_glb_distance = await window_sample()
	check(pilot.body.activity_level >= 2,"Distance reduces pilot visual work")
	pilot.global_position = near_position+Vector3(0,36,0)
	pilot_report.scenarios.E_sleep = await window_sample()
	check(pilot.body.activity_level == 3 and not pilot.source_preview.visible,"Off-floor pilot sleeps")
	pilot.global_position = near_position
	for quality in ["CHARACTER_MEDIUM","CHARACTER_LOW"]:
		pilot.set_character_quality(quality)
		pilot_report.scenarios[quality+"_static"] = await window_sample()
	pilot.set_character_quality("CHARACTER_HIGH"); pilot.set_mode(false); pilot.set_test_state("IDLE")
	check(not c.player.get_script().resource_path.contains("human_pilot"),"Campaign protagonist unchanged")
	pilot_report.checks = checks
	pilot_report.failures = failures
	var file := FileAccess.open("res://reports/human_pilot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(pilot_report,"\t"))
	pilot_finished = true
	print("HUMAN_PILOT_RESULT ",JSON.stringify(pilot_report))
