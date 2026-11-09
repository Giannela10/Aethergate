extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var c = scene.get_node("CampusCampaign"); c.persist=false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	root.add_child(scene); current_scene=scene
	while not c.ready_for_play: await process_frame
	await physics_frame
	var candidates: Array = []
	var shape := BoxShape3D.new(); shape.size=Vector3(10,3,8)
	var space: PhysicsDirectSpaceState3D = c.player.get_world_3d().direct_space_state
	for x in range(-70,71,6):
		for z in range(-174,-148,4):
			var origin := Vector3(x,24.12,z)
			var ray := PhysicsRayQueryParameters3D.create(origin+Vector3.UP*0.4,origin-Vector3.UP,1)
			if space.intersect_ray(ray).is_empty(): continue
			var query := PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.collision_mask=1; query.transform.origin=origin+Vector3.UP*1.65
			if not space.intersect_shape(query,1).is_empty(): continue
			var corners_ok := true
			for offset in [Vector3(-4,0,-3),Vector3(4,0,-3),Vector3(-4,0,3),Vector3(4,0,3)]:
				var probe := PhysicsRayQueryParameters3D.create(origin+offset+Vector3.UP*0.4,origin+offset-Vector3.UP,1)
				if space.intersect_ray(probe).is_empty(): corners_ok=false
			if corners_ok: candidates.append({"x":x,"z":z})
	var file := FileAccess.open("res://reports/v4_floor3_north_layout.json",FileAccess.WRITE); file.store_string(JSON.stringify(candidates,"\t")); file.close()
	print("FLOOR3_NORTH_LAYOUT_V4_RESULT ",JSON.stringify({"checks":168,"failures":[],"free":candidates})); quit()
