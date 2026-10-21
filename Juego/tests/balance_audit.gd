extends SceneTree
## Read-only fixture: isolated campaign, no user save or telemetry writes.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var c = scene.get_node("CampusCampaign")
	c.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene)
	current_scene = scene
	while not c.ready_for_play: await process_frame
	while get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await process_frame
	c.ui.close_modal()
	var report: Dictionary = c.live.diagnostics.balance_report()
	report["qa"] = c.live.diagnostics.qa.run(c)
	report["quests"] = []
	for q in c.quests.definitions.values():
		report.quests.append({"id":q.quest_id,"title":q.title,"main":q.main_quest,"prerequisite":q.prerequisite,"requirements":q.requirements,"reward":q.reward})
	report["actual_weapons"] = []
	for id in preload("res://scripts/inventory/item_catalog.gd").all_ids():
		var item = preload("res://scripts/inventory/item_catalog.gd").get_item(id)
		if item.category != 1: continue
		var w = c.player.inventory.create_weapon(id)
		c.add_child(w)
		report.actual_weapons.append({"id":id,"name":item.display_name,"rarity":item.rarity,"unique":item.unique,"damage":w.damage,"swing":w.swing_time,"durability":w.durability,"reach":w.reach,"dps_ideal":w.damage/maxf(0.45,w.swing_time)})
		w.queue_free()
	report["positions"] = []
	for group in ["health_station","boss_duel","campus_chair","computer"]:
		for n in get_nodes_in_group(group):
			report.positions.append({"group":group,"name":str(n.name),"position":[n.global_position.x,n.global_position.y,n.global_position.z]})
	var scanner = c.player.get_node("InteractionController")
	var scan_start := Time.get_ticks_usec()
	for iteration in 100: scanner.scan()
	report["scan_mean_us"] = (Time.get_ticks_usec()-scan_start)/100.0
	var locally_accessible := 0
	var chairs_by_floor := {}
	var local_failures: Array = []
	for chair in get_nodes_in_group("campus_chair"):
		var passed := false
		var floor_id: String = c.guidance.nearest_floor(chair.global_position.y)
		chairs_by_floor[floor_id] = int(chairs_by_floor.get(floor_id,0))+1
		if preload("res://tests/chair_access_probe.gd").find_approach(c.player,chair) != null:
			locally_accessible += 1
			passed = true
		if not passed:
			local_failures.append({"world_id":chair.world_id,"path":str(chair.get_path()),"position":[chair.global_position.x,chair.global_position.y,chair.global_position.z]})
	report["chairs"] = {"by_floor":chairs_by_floor,"local_approach_and_ray_pass":locally_accessible,"navigation_from_spawn_proven":false,"local_failures":local_failures}
	var file = FileAccess.open("res://.godot/balance_audit_initial.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("BALANCE_AUDIT weapons=",report.actual_weapons.size()," quests=",report.quests.size()," bosses=",report.bosses.size()," chairs=",locally_accessible,"/",get_nodes_in_group("campus_chair").size()," scan_mean_us=",report.scan_mean_us," qa_errors=",JSON.stringify(report.qa.errors))
	scene.queue_free()
	await process_frame
	quit()
