extends SceneTree
const Progress = preload("res://scripts/education/academic_progress.gd")
const Migration = preload("res://scripts/live/save_migration.gd")
const Auth = preload("res://scripts/auth/auth_manager.gd")
var failures: Array[String] = []
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var auth := root.get_node("AuthManager")
	var service := root.get_node("QuestionService")
	check(Auth.pkce_challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk") == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM","RFC 7636 S256 vector")
	var listener := preload("res://scripts/auth/oauth_loopback.gd").new()
	listener.nonce = "test-nonce"
	check(listener.parse_request("GET /auth/callback?nonce=test-nonce&code=abc HTTP/1.1\r\nHost: 127.0.0.1:8765\r\n\r\n").get("code") == "abc","Callback code accepted")
	check(listener.parse_request("GET /auth/callback?nonce=wrong&code=abc HTTP/1.1\r\nHost: 127.0.0.1:8765\r\n\r\n").is_empty(),"Reject wrong nonce")
	check(listener.parse_request("GET /auth/callback?nonce=test-nonce&code=abc HTTP/1.1\r\nHost: evil.test\r\n\r\n").is_empty(),"Reject wrong host")
	check(listener.parse_request("POST /auth/callback?nonce=test-nonce&code=abc HTTP/1.1\r\nHost: 127.0.0.1:8765\r\n\r\n").is_empty(),"Reject POST")
	listener.free()
	var legacy := {"version":1,"inventory":{"old":true},"bosses":{"nexo":true},"quests":{"inicio":{"state":2}},"unlocks":{"3":true}}
	var migrated: Dictionary = Migration.migrate(legacy)
	check(migrated.inventory == legacy.inventory and migrated.quests == legacy.quests and migrated.bosses == legacy.bosses,"Legacy progress unchanged")
	check(migrated.campaign_completed and migrated.academic_floor_unlocks.is_empty(),"Legacy finale preserved, educational unlock separate")
	check(Migration.migrate(migrated) == migrated,"Idempotent migration")
	check(not Migration.supported({"version":1,"save_version":999}),"Future save protection")
	# Do not touch any pre-existing real session in an automated test.
	if FileAccess.file_exists(auth.SESSION_FILE):
		print("EDUCATION_TEST_SKIPPED auth dev tests: existing real session retained")
	else:
		for role in ["student","teacher","admin"]:
			auth.dev_login(role)
			check(auth.role == role and auth.session_valid(),"DEV role "+role)
			check(not FileAccess.file_exists(auth.SESSION_FILE),"DEV sessions never persisted")
		auth.dev_login("student")
		var q: Dictionary = await service.get_random_question("INF_GENERAL","floor_unlock")
		check(not q.has("correct_option") and not q.has("explanation"),"Student question hides key")
		var key := "A" if q.id == "demo-sql" else "B"
		var result: Dictionary = await service.submit_answer(q.id,key,"floor_unlock")
		check(result.get("correct",false) and not str(result.get("explanation","")).is_empty(),"Correct answer and explanation")
		Progress.record(migrated,q,result,"floor_unlock")
		migrated.academic_floor_unlocks["3"] = true
		var repeated: Dictionary = await service.submit_answer(q.id,key,"floor_unlock")
		check(repeated.has("error"),"Single use local answer")
		var q2: Dictionary = await service.get_random_question("INF_GENERAL","floor_unlock")
		check(q2.id != q.id,"Retry offers different question")
		var wrong: Dictionary = await service.submit_answer(q2.id,"D","floor_unlock")
		check(not wrong.correct and not str(wrong.explanation).is_empty(),"Incorrect answer and explanation")
		Progress.record(migrated,q2,wrong,"floor_unlock")
		var path := "user://education_test_fixture.json"
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(JSON.stringify(migrated))
		file.close()
		var restored: Dictionary = Migration.migrate(JSON.parse_string(FileAccess.get_file_as_string(path)))
		check(restored.academic_floor_unlocks.get("3",false) and restored.academic_progress.answered == 2,"Unlock and counters survive save/load")
		check(restored.academic_progress.offline_attempts.size() == 2,"Offline attempts locally queued")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		auth.dev_login("teacher")
		var invalid: Dictionary = await service.create_question({})
		check(invalid.has("error"),"Teacher form validation")
		var data := {"subject_id":"INF_GENERAL","question_text":"Test question","option_a":"A","option_b":"B","option_c":"C","option_d":"D","correct_option":"C","explanation":"Test explanation","difficulty":"medium","active":true}
		check((await service.create_question(data)).get("ok",false),"DEV teacher creates question")
		var rows: Array = await service.get_questions_for_teacher()
		var created: Dictionary = rows.back()
		data.question_text = "Updated question"
		check((await service.update_question(created.id,data)).get("ok",false),"DEV teacher edits question")
		check((await service.set_question_active(created.id,false)).get("ok",false),"DEV teacher deactivates question")
		service.clear_session()
		auth.logout()
		check(not auth.session_valid() and auth.user_id.is_empty(),"Logout clears session")
	var gate := preload("res://scripts/education/academic_floor_gate.gd").new()
	var stub := Node.new()
	stub.set_script(preload("res://tests/education_gate_fixture.gd"))
	stub.data = Progress.migrate({})
	gate.campaign = stub
	for route in [Vector3(0,24,-148),Vector3(0,24,-130),Vector3(70,24,-130)]:
		check(gate.requires_challenge(route),"Gate covers elevator/central/emergency arrival %s" % route)
	stub.data.academic_floor_unlocks["3"] = true
	check(not gate.requires_challenge(Vector3(0,24,-148)),"Unlocked floor never prompts")
	check(not gate.requires_challenge(Vector3(0,12,-148)),"Other floor unaffected")
	gate.free()
	stub.free()
	var report := {"checks":checks,"failures":failures,"google_oauth":"NOT TESTED: external credentials required","supabase_rls":"NOT TESTED: deployment required","release_export":"NOT TESTED: export templates required"}
	var report_file := FileAccess.open("res://reports/education_1_0_tests.json",FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report,"\t"))
	report_file.close()
	print("EDUCATION_1_0_RESULT ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
