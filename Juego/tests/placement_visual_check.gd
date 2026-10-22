extends SceneTree
var failures: Array[String] = []
var checked := 0

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var campaign = scene.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene)
	current_scene = scene
	while not campaign.ready_for_play: await process_frame
	var space := root.world_3d.direct_space_state
	var excluded: Array[RID] = [campaign.player.get_rid()]
	for actor in campaign.find_children("*","CharacterBody3D",true,false): excluded.append(actor.get_rid())
	var items: Array = []
	for node in campaign.get_children():
		if not node.has_method("visual_bounds") or node.collected or not node.is_visible_in_tree(): continue
		checked += 1
		var bounds: AABB = node.visual_bounds()
		var ray := PhysicsRayQueryParameters3D.create(node.global_position+Vector3.UP*0.15,node.global_position-Vector3.UP*0.5,1,excluded)
		var hit := space.intersect_ray(ray)
		var gap := 999.0 if hit.is_empty() else bounds.position.y-float(hit.position.y)
		var supported: bool = not hit.is_empty() and node.placement_clear(space,hit.position,excluded)
		if not supported or absf(gap-0.015)>0.006:
			failures.append("Unsupported, floating or intersecting item: "+str(node.name))
		items.append({"id":str(node.name),"item":node.item_id,"position":str(node.global_position),"bottom_gap":gap,"footprint_clear":supported})
	var report := {"checked":checked,"failures":failures,"items":items}
	var file := FileAccess.open("res://reports/placement_visual_check.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report,"\t"))
	print("PLACEMENT_VISUAL_RESULT ",JSON.stringify({"checked":checked,"failures":failures}))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
