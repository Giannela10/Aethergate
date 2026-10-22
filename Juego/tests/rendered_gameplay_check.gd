extends SceneTree
var failures: Array[String] = []
var captures: Array[String] = []
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _initialize() -> void:
	run.call_deferred()

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://reports/detail_gameplay_"+label+".png"
	check(root.get_texture().get_image().save_png(path) == OK,"Capture "+label)
	captures.append(path)

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1152,648))
	var scene = load("res://Main.tscn").instantiate()
	var campaign = scene.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene)
	current_scene = scene
	while not campaign.ready_for_play: await process_frame
	campaign.ui.close_modal()
	# Keep the real entrance spawn; the stair aperture at z=-130 is intentional.
	await create_timer(0.5).timeout
	var start: Vector3 = campaign.player.global_position
	Input.action_press("move_forward")
	await create_timer(1.0).timeout
	Input.action_release("move_forward")
	check(campaign.player.global_position.distance_to(start) > 1.0,"Player moves with real physics/input")
	check(not campaign.player.dead,"Player remains alive")
	await capture("walking")
	campaign.player.inventory_ui.open_inventory()
	check(campaign.player.inventory_ui.panel.visible and campaign.player.busy,"Inventory opens and blocks movement")
	await capture("inventory")
	check(not campaign.ui.objective.visible and not campaign.ui.toast.visible,"Inventory is not covered by campaign HUD")
	campaign.player.inventory_ui.close_inventory()
	check(not campaign.player.busy,"Inventory releases player")
	campaign.show_pause()
	check(paused and campaign.ui.modal,"Pause stops game")
	await capture("pause")
	check(not campaign.ui.objective.visible,"Pause hides objective overlay")
	campaign.ui.close_modal()
	check(not paused,"Continue resumes game")
	await process_frame
	await process_frame
	check(campaign.ui.objective.visible,"Continue restores objective HUD")
	campaign.show_map()
	await capture("map")
	campaign.ui.close_modal()
	campaign.phone.open()
	await capture("phone")
	campaign.ui.close_modal()
	print("RENDERED_GAMEPLAY_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"personal_saves_used":false}))
	quit(0 if failures.is_empty() else 1)
