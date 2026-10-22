extends SceneTree
var failures: Array[String] = []
var checks := 0
const SAVE := "res://tests/education_integration_fixture.json"

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	# Use production auth behavior with in-memory session storage. Never inspect,
	# restore or delete the user's real session when exercising dev login/logout.
	var original_auth := root.get_node("AuthManager")
	root.remove_child(original_auth)
	original_auth.free()
	var auth = preload("res://tests/supabase_session_fixture.gd").new()
	auth.name = "AuthManager"
	root.add_child(auth)
	root.get_node("QuestionService").auth = auth
	auth.dev_login("student")
	set_meta("education_enabled",true)
	var scene = load("res://Main.tscn").instantiate()
	var campaign = scene.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene)
	current_scene = scene
	while not campaign.ready_for_play: await process_frame
	await physics_frame
	var gate = campaign.get_node("AcademicFloorGate")
	check(gate != null,"Gate installed in real campus")
	for arrival in [Vector3(0,24,-148),Vector3(0,24,-130),Vector3(70,24,-130)]:
		campaign.player.global_position = arrival
		gate.cooldown = 0
		await physics_frame
		await physics_frame
		check(gate.pending and campaign.ui.modal,"Arrival triggers modal %s" % arrival)
		check(not gate.requires_challenge(campaign.player.global_position),"Arrival cannot bypass guard %s" % arrival)
		gate._cancel()
		await physics_frame
	gate.pending = true
	gate._begin()
	campaign.ui.close_modal()
	await physics_frame
	await physics_frame
	check(not gate.pending,"Esc/close cancels pending guard state")
	gate.cooldown = 0
	campaign.player.global_position = Vector3(0,24,-130)
	await physics_frame
	await physics_frame
	check(gate.pending,"Closing modal cannot bypass next arrival")
	await gate._fetch()
	check(not gate.question.has("error"),"Actual gate fetches demo question")
	var before_health: float = campaign.player.health
	var before_inventory: Dictionary = campaign.player.inventory.snapshot_data()
	var view: Node = campaign.ui.column.get_child(2)
	check(view.get_child_count() == 5,"Shared question component has text and four options")
	view.get_child(4).pressed.emit()
	await process_frame
	check(campaign.ui.column.get_child(0).text == "INCORRECTO","Actual gate wrong answer result")
	check(campaign.player.health == before_health and campaign.player.inventory.snapshot_data() == before_inventory,"Wrong answer no health/item penalty")
	var previous: String = gate.question.id
	await gate._fetch()
	check(gate.question.id != previous,"Actual gate retry changes question")
	var option := "A" if gate.question.id == "demo-sql" else "B"
	campaign.persist = true
	campaign.save_path = SAVE
	view = campaign.ui.column.get_child(2)
	view.get_child(1 if option == "A" else 2).pressed.emit()
	await process_frame
	check(campaign.data.academic_floor_unlocks.get("3",false),"Actual gate unlock")
	check(campaign.last_save_succeeded,"Actual campaign writer persists educational data")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(saved.academic_floor_unlocks.get("3",false) and saved.academic_progress.answered == 2,"Actual save contains unlock/counters")
	gate._cancel()
	campaign.player.global_position = Vector3(0,24,-130)
	await physics_frame
	await physics_frame
	check(not gate.pending,"Unlocked arrival skips question")
	campaign.persist = false
	scene.queue_free()
	await process_frame
	remove_meta("education_enabled")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	auth.logout()
	var result := {"checks":checks,"failures":failures}
	var file := FileAccess.open("res://reports/education_integration_tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	print("EDUCATION_INTEGRATION_RESULT ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
