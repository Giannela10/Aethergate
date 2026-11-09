extends SceneTree
var failures: Array[String] = []
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	set_meta("education_v4_suppress_story",true)
	root.get_node("CloudSave").journal_enabled = false
	var auth := root.get_node("AuthManager")
	var original_client = auth.client
	var backend := preload("res://tests/cloud_backend_fixture.gd").new()
	root.add_child(backend)
	auth.client = backend
	auth.user_id = "campaign-fixture"
	auth.access_token = "campaign-fixture"
	auth.expires_at = int(Time.get_unix_time_from_system())+3600
	auth.role = "student"
	auth.profile_ready = true
	auth.dev_session = false
	auth.session_changed.emit()
	set_meta("education_enabled",true)
	set_meta("education_entry","continue")
	var scene = load("res://Main.tscn").instantiate()
	var initial = preload("res://scripts/live/save_migration.gd").migrate(scene.get_node("CampusCampaign").data)
	initial.credits = 88
	initial.inventory = {"version":1,"entries":[],"quick":["","","",""],"serial":0,"equipped":""}
	initial.settings = {"language":"en","quality":"BAJO","window":"WINDOWED","fps":60,"telemetry":false}
	backend.rows[auth.user_id] = {"revision":1,"payload":initial}
	root.add_child(scene)
	current_scene = scene
	var campaign = scene.get_node("CampusCampaign")
	var deadline := Time.get_ticks_msec()+20000
	while not campaign.ready_for_play and Time.get_ticks_msec()<deadline: await process_frame
	check(campaign.ready_for_play and campaign.cloud_mode,"Campus boots through real cloud branch using fixture transport")
	check(campaign.loaded_save and campaign.data.credits >= 88,"Campaign loaded from account payload")
	check(not campaign.get_node("DuocGames4").story.state.story.intro_seen,"Fresh cloud campaign retains the narrative introduction")
	check(not campaign.player.persist_inventory and not campaign.player.inventory.persist,"Shared local inventory reads and writes disabled")
	check(not scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist,"Shared credential persistence disabled")
	check(campaign.live.settings.data.language == "en","Account settings loaded from cloud payload")
	campaign.data.credits = 321
	campaign.player.stationery_notes = "fixture-notes"
	campaign.live.settings.set_option("language","es")
	campaign.save_game()
	var cloud := root.get_node("CloudSave")
	check(await cloud.flush(),"Campaign save awaits remote acknowledgment")
	check(backend.rows[auth.user_id].payload.credits == 321,"Account credits saved remotely")
	check(backend.rows[auth.user_id].payload.stationery.notes == "fixture-notes","Notes saved in same remote campaign")
	check(backend.rows[auth.user_id].payload.settings.language == "es","Settings changes saved remotely")
	# R must keep the current scene alive until the latest snapshot is confirmed.
	campaign.data.credits = 654
	backend.fail_next = true
	await campaign.reload_cloud_scene()
	check(current_scene == scene and not campaign.restarting,"Failed save cancels the scene restart")
	check(not cloud.operation.is_empty() and campaign.ui.modal,"Failed restart retains pending data and shows recovery choices")
	campaign.ui.close_modal()
	check(not paused and not campaign.player.busy,"Continue playing restores input after a failed restart")
	backend.hold = true
	var restart_key := InputEventKey.new()
	restart_key.keycode = KEY_R
	restart_key.pressed = true
	campaign.manager._unhandled_key_input(restart_key)
	await process_frame
	check(current_scene == scene and cloud.busy and paused,"R waits for the cloud while gameplay is paused")
	var request_count: int = backend.requests.size()
	campaign.manager._unhandled_key_input(restart_key)
	check(backend.requests.size() == request_count,"Repeated R does not start a second restart")
	backend.release = true
	deadline = Time.get_ticks_msec()+20000
	while (current_scene == null or current_scene == scene) and Time.get_ticks_msec()<deadline: await process_frame
	if current_scene != scene:
		campaign = current_scene.get_node("CampusCampaign")
		while not campaign.ready_for_play and Time.get_ticks_msec()<deadline: await process_frame
	check(current_scene != scene and campaign.ready_for_play and not paused,"R reloads after cloud confirmation and restores gameplay")
	check(campaign.data.credits == 654 and campaign.player.stationery_notes == "fixture-notes","R preserves the latest campaign data")
	scene = current_scene
	deadline = Time.get_ticks_msec()+20000
	campaign.new_game()
	while (current_scene == null or current_scene == scene) and Time.get_ticks_msec()<deadline: await process_frame
	if current_scene != scene:
		campaign = current_scene.get_node("CampusCampaign")
		while not campaign.ready_for_play and Time.get_ticks_msec()<deadline: await process_frame
	check(current_scene != scene and campaign.ready_for_play,"New campaign reloads only after cloud confirmation")
	check(backend.rows[auth.user_id].previous_payload.credits == 654,"New campaign preserves previous cloud snapshot")
	check(campaign.data.credits == 30 and campaign.player.stationery_notes.is_empty(),"New campaign resets credits and notes")
	campaign.save_game()
	await cloud.flush()
	check(backend.rows[auth.user_id].previous_payload.credits == 654,"Autosave does not overwrite pre-reset backup")
	campaign.persist = false
	current_scene.queue_free()
	await process_frame
	remove_meta("education_enabled")
	remove_meta("education_v4_suppress_story")
	auth.client = original_client
	# Do not call real clear_session/logout: they may delete an existing user's session file.
	auth.user_id = ""
	auth.access_token = ""
	auth.profile_ready = false
	auth.role = "pending"
	cloud._session_changed()
	backend.queue_free()
	print("CLOUD_CAMPAIGN_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"remote_database_tested":false}))
	quit(0 if failures.is_empty() else 1)
