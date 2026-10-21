class_name AcademicBossesCheck
extends Node
var c: Node
var failures: Array[String] = []
var checks := 0
var result := {}
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func _ready() -> void:
	run.call_deferred()
func probe_floor(floor_number: int, xs: Array, zs: Array) -> Array:
	var found := []
	var height: float = load("res://scripts/campaign/campus_content.gd").HEIGHTS[floor_number-1]
	for x in xs:
		for z in zs:
			var p = c.player.get_node("SeatController").safe_position(Vector3(x,height+0.12,z))
			if p != null and absf(p.y-height) < 0.5:
				var count := 0
				for offset in [Vector3(-3,0,0),Vector3(3,0,0),Vector3(0,0,-2),Vector3(0,0,2)]:
					var safe = c.player.get_node("SeatController").safe_position(p+offset)
					if safe != null and absf(safe.y-height) < 0.5: count += 1
				if count >= 3: found.append([p.x,p.y,p.z,count])
	return found
func verify_expansion() -> void:
	var hub = c.academic_expansion
	var Data = load("res://scripts/campaign/academic_expansion_data.gd")
	for id in hub.actors:
		var actor = hub.actors[id]
		var duel = actor.duel
		if id == "coordinador_profesores":
			hub.state.seen.clear()
			hub.state.flags.erase("coordinator_returned")
			c.data.quests.ubicar_profesores.state = 0
			for professor in ["profesor_algoritmos","profesor_ingles","profesor_matematicas"]: c.events.erase("talk:"+professor)
			duel.interact(c.player)
			check(duel.state == 0 and c.quests.state("ubicar_profesores") == 1,"Coordinator requires search")
			c.ui.close_modal()
			for professor in ["profesor_algoritmos","profesor_ingles","profesor_matematicas"]: c.event("talk",professor)
		duel.interact(c.player)
		await duel.accept()
		actor.set_physics_process(false)
		c.player.global_position = actor.home
		for phase in [1,2,3]:
			actor.phase = phase
			for variant in range(2):
				actor.finish_activity(true) if not actor.activity.is_empty() else actor.clear_objectives()
				actor.begin_activity()
				check(not actor.activity.is_empty(),"Activity phase "+id+str(phase))
				if actor.activity == "listen":
					actor.pulses = 2
					actor.create_points(["IZQUIERDA","DERECHA"],"walk")
				var guard := 0
				while not actor.activity.is_empty() and guard < 10:
					guard += 1
					var token: String = actor.expected[actor.sequence_index] if actor.activity != "plaque" else actor.expected[0]
					if actor.activity == "decision": token = "0"
					var points: Array = actor.objectives.filter(func(p): return is_instance_valid(p) and p.enabled and p.token == token)
					if points.is_empty(): break
					c.player.global_position = points[0].global_position
					if points[0].mode == "walk":
						points[0]._physics_process(0.7)
					elif points[0].mode == "use":
						points[0].interact(c.player)
					else:
						c.player.global_position -= c.player.body.forward()
						c.player._on_punch_landed(0)
				check(actor.activity.is_empty() and actor.vulnerability > 0,"Physical solution "+id+str(phase))
		var retry = c.live.retry
		var captured: Dictionary = retry.snapshot.inventory.duplicate(true)
		c.player.health = 7
		c.player.get_node("CombatExtensions").stamina = 0
		c.give_reward_item("Bebida",2)
		c.player.dead = true
		retry.on_death()
		duel.reset_duel()
		check(retry.can_retry(),"Death retry available "+id)
		await retry.retry_boss()
		await get_tree().create_timer(0.8).timeout
		check(not c.player.dead and actor.combat_active(),"Retry active "+id)
		check(c.player.inventory.snapshot_data() == captured,"Snapshot inventory restored "+id)
		check(c.player.get_node("CombatExtensions").stamina > 0,"Stamina restored "+id)
		actor.set_physics_process(false)
		actor.take_hit(Vector3.ZERO,999999)
		check(c.data.bosses.get(id,false) and c.player.inventory.has_item(Data.REWARDS[id][0],1),"Actual victory reward "+id)
		var credits: int = c.data.credits
		c.boss_won(duel)
		check(c.data.credits == credits,"Victory does not duplicate credits "+id)
		c.ui.close_modal()
	for id in Data.REWARDS:
		hub.grant_academic_reward(id)
		hub.grant_academic_reward(id)
		check(c.player.inventory.has_item(Data.REWARDS[id][0],1),"Reward exists "+id)
		check(c.player.inventory.count_item(Data.REWARDS[id][0]) == 1,"Unique reward "+id)
	check(hub.map_notes().contains("MAPA DOCENTE"),"Teacher map")
	var director = get_tree().get_nodes_in_group("boss_duel").filter(func(d): return d.boss_id == "director")[0]
	check(hub.director_count() == 0,"New Director tasks locked")
	director.interact(c.player)
	check(director.state == 0 and c.ui.modal,"Director refuses before tasks")
	c.ui.close_modal()
	hub.open_task("director_task_network")
	for i in 4: hub.network_next()
	hub.open_task("director_task_config",0)
	hub.select_config(0)
	check(not hub.state.flags.get("director_task_config",false),"Wrong network not accepted")
	hub.open_task("director_task_config",2)
	hub.select_config(2)
	c.ui.close_modal()
	var pc = c.get_node("director_antivirus")
	c.manager._on_computer_requested(pc)
	check(c.manager.minigame.current.GOAL == 4,"Existing short antivirus")
	c.manager.minigame.close(true)
	await get_tree().process_frame
	check(hub.director_count() == 3,"All three actual task flows")
	director.interact(c.player)
	check(director.state == 1,"Director unlocked")
	director.decline()
	var old := {"version":1,"bosses":{"profesor_ingles":true,"profesor_lenguaje":true,"profesor_etica":true,"director":true},"events":{"talk:profesor_ingles":1},"quests":{"academico5":{"state":2}},"computers":{"pc5":true,"pc6":true,"pc7":true},"unlocks":{"8":true}}
	var migrated: Dictionary = load("res://scripts/live/save_migration.gd").migrate(old)
	check(migrated.bosses == old.bosses and migrated.computers == old.computers and migrated.quests == old.quests,"Legacy victories/PC/quests retained")
	check(migrated.academic_expansion.flags.size() == 3,"Legacy Director tasks grandfathered")
	check(migrated == load("res://scripts/live/save_migration.gd").migrate(migrated),"Migration idempotent")
	var save_path := "res://tests/academic_expansion_temporary.json"
	c.save_path = save_path; c.persist = true
	c.save_game()
	var saved = load("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(save_path)
	check(saved.academic_expansion.flags == hub.state.flags,"Task flags persisted")
	check(JSON.parse_string(JSON.stringify(saved.inventory)) == JSON.parse_string(JSON.stringify(c.player.inventory.snapshot_data())),"Inventory rewards persisted")
	c.persist = false
	var old_scene = c.get_parent()
	remove_child(old_scene)
	old_scene.queue_free()
	await get_tree().process_frame
	var restored = load("res://Main.tscn").instantiate()
	c = restored.get_node("CampusCampaign")
	c.save_path = save_path
	restored.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(restored)
	while not c.ready_for_play: await get_tree().process_frame
	c.persist = false
	c.ui.close_modal()
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	c.ui.close_modal()
	check(c.loaded_save and c.academic_expansion.director_count() == 3,"Actual campaign reload tasks")
	for id in Data.REWARDS:
		check(c.player.inventory.count_item(Data.REWARDS[id][0]) == 1,"Reload no duplicate reward "+id)
	for id in c.academic_expansion.actors:
		check(c.data.bosses.get(id,false) and c.academic_expansion.actors[id].duel.defeated,"Reload victory "+id)
	c.player.set_physics_process(false)
	c.live.director.enabled = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+".bak"))
	check(get_tree().get_nodes_in_group("boss_duel").size() == 15,"Fifteen bosses including optional Redes")
	check(c.quests.definitions.size() == 20,"Twenty quests without duplicate main chain")
func preview(id: String) -> Dictionary:
	var actor = c.academic_expansion.actors[id]
	c.ui.close_modal()
	actor.duel.defeated = false
	actor.duel.state = 0
	actor.reset_academic_duel()
	actor.duel.state = 3
	c.active_duel = actor.duel
	actor.running = true
	actor.target = c.player
	c.player.global_position = actor.home+Vector3(0,0,3)
	c.player.set_physics_process(false)
	actor.set_physics_process(false)
	actor.phase = 2
	actor.begin_activity()
	c.manager.cam.global_position = actor.home+Vector3(0,7,9)
	c.manager.cam.look_at(actor.home+Vector3(0,1,0))
	c.manager.set_process(false)
	return {"id":id,"position":str(actor.home),"points":actor.objective_positions.size()}
func verify_passives() -> void:
	c.give_reward_item("Botiquin",1)
	c.player.health = 10
	var entry: Dictionary = c.player.inventory.entries.filter(func(e): return e.item_id == "Botiquin")[0]
	c.player.inventory.use_entry(entry.uid)
	check(c.player.health == 65,"Clinical kit +5 healing")
	c.player.velocity = Vector3.ZERO
	c.player.take_hit(Vector3.RIGHT,10)
	check(is_equal_approx(c.player.velocity.x,3.6),"Dental protector only reduces push")
	var status = load("res://scripts/pisos/piso_3/network_slow_status.gd").new()
	c.player.add_child(status)
	status.apply_status("RALENTIZADO",10,0.7)
	check(is_equal_approx(status.statuses.RALENTIZADO.time,7.65),"Combined negative-effect duration")
	status.clear_slow()
	c.grant_reward({},"quest:llaves")
	var count: int = c.player.inventory.count_item("Comida")
	c.grant_reward({},"quest:cargador")
	c.grant_reward({},"quest:cargador")
	check(c.player.inventory.count_item("Comida") == count+1,"Oratory social reward once")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	c = scene.get_node("CampusCampaign")
	c.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(scene)
	while not c.ready_for_play: await get_tree().process_frame
	c.ui.close_modal()
	c.player.set_physics_process(false)
	c.live.director.enabled = false
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	var upper = c.get_node("UpperCampusBosses")
	check(upper.failures.is_empty(),"Placement")
	for row in [["profesor_ingles","6"],["profesor_etica","6"],["profesor_lenguaje","7"]]:
		var actor = upper.actors[row[0]]
		check(c.phone._floor_for(actor) == row[1],"Moved floor "+row[0])
		check(actor.duel.state == 0,"Neutral "+row[0])
	for row in [["pc5","6"],["pc6","7"],["pc7","6"],["pc8","8"]]:
		var pcs = get_tree().get_nodes_in_group("computer").filter(func(pc): return pc.get_meta("campaign_id","") == row[0])
		check(pcs.size() == 1 and c.phone._floor_for(pcs[0]) == row[1],"Stable PC "+row[0])
	check(c.academic_expansion.failures.is_empty(),"Expansion arenas")
	for id in c.academic_expansion.actors:
		var actor = c.academic_expansion.actors[id]
		check(actor.objective_positions.size() == 4,"Four reachable physical points "+id)
		var duel = actor.duel
		if id == "coordinador_profesores":
			for professor in ["profesor_algoritmos","profesor_ingles","profesor_matematicas"]: c.academic_expansion.state.seen[professor] = true
		actor.take_hit(Vector3.ZERO,9999)
		check(actor.health == actor.config.max_health,"Neutral immunity "+id)
		duel.interact(c.player)
		check(duel.state == 1,"Dialogue "+id)
		duel.decline()
		check(duel.state == 0 and actor.objectives.is_empty(),"Decline "+id)
		duel.intro_duration = 0.01
		duel.interact(c.player)
		await duel.accept()
		actor.set_physics_process(false)
		check(actor.combat_active(),"Accept "+id)
		c.player.global_position = actor.home+Vector3(0,0,1)
		actor.begin_activity()
		check(not actor.activity.is_empty(),"Physical activity "+id)
		check(actor.objectives.size() <= 4,"Objective cap "+id)
		actor.take_hit(Vector3.ZERO,actor.boss_max_health*0.41)
		check(actor.phase == 2,"Phase 60 "+id)
		actor.take_hit(Vector3.ZERO,actor.boss_max_health*0.30)
		check(actor.phase == 3,"Phase 30 "+id)
		duel.reset_duel()
		check(actor.phase == 1 and actor.objectives.is_empty() and actor.projectiles.is_empty(),"Reset cleanup "+id)
	await verify_expansion()
	verify_passives()
	result = {"checks":checks,"failures":failures,"stage":11,"expansion_failures":c.academic_expansion.failures,"actors":c.academic_expansion.actors.keys()}
	print("ACADEMIC_BOSSES_RESULT ",JSON.stringify(result))
	var file = FileAccess.open("res://reports/academic_bosses_result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
