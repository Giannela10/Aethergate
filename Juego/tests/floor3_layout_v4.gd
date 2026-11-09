extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var campaign = scene.get_node("CampusCampaign")
	campaign.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene)
	current_scene = scene
	while not campaign.ready_for_play: await process_frame
	await physics_frame
	var candidates: Array = []
	var shape := BoxShape3D.new(); shape.size = Vector3(10,3,8)
	var space: PhysicsDirectSpaceState3D = campaign.player.get_world_3d().direct_space_state
	for x in range(-70,71,12):
		for z in range(-116,-91,10):
			var origin := Vector3(x,24.12,z)
			var ray := PhysicsRayQueryParameters3D.create(origin+Vector3.UP*0.4,origin-Vector3.UP,1)
			if space.intersect_ray(ray).is_empty(): continue
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape; query.collision_mask = 1
			query.transform.origin = origin+Vector3.UP*1.65
			var hits := space.intersect_shape(query,8)
			candidates.append({"x":x,"z":z,"clear":hits.is_empty(),"blockers":hits.map(func(h): return str(h.collider.get_path()))})
	var file := FileAccess.open("res://reports/v4_floor3_layout.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(candidates,"\t")); file.close()
	print("FLOOR3_LAYOUT_V4_RESULT ",JSON.stringify({"checks":candidates.size(),"failures":[],"free":candidates.filter(func(c): return c.clear)}))
	quit()
