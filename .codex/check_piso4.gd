extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var floor4 = scene.get_node("Piso 4/DistribucionPlanoPiso4")
	var failures: Array = []
	var rooms := 0
	var player = scene.get_node("GameplayManager").player
	for room in floor4.get_children():
		if not room.has_meta("planta"): continue
		rooms += 1
		var door = room.get_node("Puerta")
		var outward: Vector3 = door.global_basis.z
		player.global_position = door.global_position + outward*1.8 + Vector3(0,0.15,0)
		for frame in range(50): await physics_frame
		var start: Vector3 = door.global_position + outward*1.7 + Vector3(0,1.4,0)
		var finish: Vector3 = door.global_position - outward*1.7 + Vector3(0,1.4,0)
		var query := PhysicsRayQueryParameters3D.create(start,finish)
		query.exclude = [player.get_rid()]
		var hit := root.world_3d.direct_space_state.intersect_ray(query)
		if not hit.is_empty(): failures.append({"room":str(room.name),"blocked":str(hit.collider.get_path())})
		for p in [door.global_position+outward,door.global_position-outward]:
			var floor_query := PhysicsRayQueryParameters3D.create(p+Vector3(0,0.5,0),p-Vector3(0,0.6,0))
			var floor_hit := root.world_3d.direct_space_state.intersect_ray(floor_query)
			if floor_hit.is_empty(): failures.append({"room":str(room.name),"floor_missing":p})
	print("PISO4_CHECK ",JSON.stringify({"rooms":rooms,"classrooms":floor4.get_meta("salas"),"bathrooms":floor4.get_meta("sectores_banos"),"failures":failures}))
	quit(0 if failures.is_empty() and rooms==28 else 1)
