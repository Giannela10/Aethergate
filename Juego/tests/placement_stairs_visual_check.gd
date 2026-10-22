extends SceneTree
var failures: Array[String] = []
var captures: Array[String] = []
var states: Array = []
func _initialize() -> void: run.call_deferred()
func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://reports/placement_"+label+".png"
	if root.get_texture().get_image().save_png(path) != OK: failures.append("Capture "+label)
	captures.append(path)
func run() -> void:
	DisplayServer.window_set_size(Vector2i(1152,648))
	var scene = load("res://Main.tscn").instantiate()
	var c = scene.get_node("CampusCampaign")
	c.persist = false
	c.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene)
	current_scene = scene
	while not c.ready_for_play: await process_frame
	c.ui.close_modal()
	var safe = c.player.get_node("SeatController").safe_position(Vector3(-20.7,0.1,-149.8))
	if safe == null:
		failures.append("Emergency landing is not safe")
	else:
		c.restore_player([safe.x,safe.y,safe.z],c.player.max_health)
		# Let physics settle onto the landing so captures show the actual standing
		# pose, rather than freezing the character's falling animation in midair.
		await create_timer(0.8).timeout
		for index in range(3):
			c.manager.cam_yaw = index*PI/2
			c.manager.cam_pitch = 0.35
			await create_timer(0.4).timeout
			await capture("stairs_view_"+str(index))
			states.append({"angle":index,"camera_distance":c.manager.cam.global_position.distance_to(c.manager.cam_pivot),"body_visible":c.player.body.visible})
		c.manager.cam_dist = 0.5
		await process_frame
		await process_frame
		if c.player.body.visible: failures.append("Close camera must not be blocked by player body")
		c.manager.cam_dist = 5
		c.manager.cam_yaw = 0
		await process_frame
		await process_frame
		if c.manager.cam.global_position.distance_to(c.manager.cam_pivot) >= 1.2 and not c.player.body.visible:
			failures.append("Character must return when camera clears")
	# Inspect real grounded pickups near the first-floor stair approach.
	var item = c.get_node("Arma_00")
	c.manager.set_process(false)
	c.manager.cam.global_position = item.global_position+Vector3(2.4,1.7,2.4)
	c.manager.cam.look_at(item.global_position+Vector3.UP*0.2)
	await capture("grounded_stick")
	item = c.get_node("Arma_01")
	c.manager.cam.global_position = item.global_position+Vector3(2.4,1.7,2.4)
	c.manager.cam.look_at(item.global_position+Vector3.UP*0.3)
	await capture("grounded_chair")
	var report := {"failures":failures,"captures":captures,"camera_states":states,"personal_saves_used":false}
	var file := FileAccess.open("res://reports/placement_stairs_visual_check.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report,"\t"))
	print("PLACEMENT_STAIRS_RESULT ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
