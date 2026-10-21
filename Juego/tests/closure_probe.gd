extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var c = scene.get_node("CampusCampaign")
	c.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene); current_scene = scene
	while not c.ready_for_play: await process_frame
	c.ui.close_modal(); c.player.set_physics_process(false)
	var pending = JSON.parse_string(FileAccess.get_file_as_string("res://reports/balance_1_0_data.json")).chairs.local_failures
	var evidence: Array = []
	for row in pending:
		var pickup = scene.get_node(NodePath(str(row.path).trim_prefix("/root/Main/")))
		var rejected: Array = []
		for offset in [Vector3(0.9,0,0),Vector3(-0.9,0,0),Vector3(0,0,0.9),Vector3(0,0,-0.9)]:
			var candidate: Vector3 = pickup.global_position+offset
			var ray := PhysicsRayQueryParameters3D.create(candidate+Vector3.UP*1.8,candidate-Vector3.UP*1.4,1,c.player.get_node("SeatController")._chair_rids(pickup.furniture))
			var hit: Dictionary = c.player.get_world_3d().direct_space_state.intersect_ray(ray)
			var reason := "No floor"
			if not hit.is_empty():
				reason = "Ray hits "+str(hit.collider.get_path())+" y="+str(hit.position.y)
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = c.player.standing_capsule; query.transform.origin = hit.position+Vector3.UP*(0.04+1.375)
				query.exclude = ray.exclude; query.margin = 0.005
				for overlap in c.player.get_world_3d().direct_space_state.intersect_shape(query,4): reason += "; capsule overlaps "+str(overlap.collider.get_path())
			rejected.append(reason)
		var safe = preload("res://tests/chair_access_probe.gd").find_approach(c.player,pickup)
		evidence.append({"world_id":pickup.world_id,"original_candidates":rejected,"safe_approach":str(safe),"id_changed":false,"geometry_changed":false})
		print("CHAIR_REVIEW ",row.world_id," safe=",safe)
	var report := FileAccess.open("res://reports/closure_chairs.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(evidence,"  ")); report.close()
	# Validate an open, already built basement bay, away from stairs/columns.
	for center in [Vector3(58,-12.058,-111),Vector3(48,-12.058,-100),Vector3(-48,-12.058,-105)]:
		var valid := 0
		for x in range(-8,9,2):
			for z in range(-8,9,2):
				if c.player.get_node("SeatController").safe_position(center+Vector3(x,0,z)) != null: valid += 1
		print("ARENA_PROBE center=",center," clear=",valid,"/81")
	scene.queue_free(); await process_frame; quit()
