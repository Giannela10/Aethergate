extends Node
var checks := 0
var failures: Array[String] = []
var result := {}
var c: Node
var finished := false
func preview_boss(id: String) -> Dictionary:
	var actor = c.get_node("UpperCampusBosses").actors[id]
	actor.duel.defeated = false
	actor.duel.reset_duel()
	c.ui.close_modal()
	c.restore_player([actor.home.x+2,actor.home.y,actor.home.z+2],100)
	c.player.global_position = actor.home+Vector3(-3,0,-3)
	c.player.set_physics_process(false)
	c.manager.set_process(false)
	actor.body.fall_pivot.rotation = Vector3.ZERO; actor.body.fall_pivot.position = Vector3.ZERO
	actor.body.rotation.y = PI
	actor.duel.identity_label.text = actor.config.display_name+"\n[E] Hablar"
	c.manager.cam.global_position = actor.home+Vector3(0,2.0,3.5)
	c.manager.cam.look_at(actor.home+Vector3.UP*1.15)
	return {"boss":id,"hp":actor.health,"position":str(actor.global_position)}
func performance_sample() -> Dictionary:
	return {"fps":Performance.get_monitor(Performance.TIME_FPS),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"memory_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func _ready() -> void: run.call_deferred(); watchdog.call_deferred()
func watchdog() -> void:
	await get_tree().create_timer(120,true,false,true).timeout
	if not finished: push_error("UPPER_CAMPUS_TIMEOUT"); get_tree().quit(2)
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	c = scene.get_node("CampusCampaign"); c.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(scene)
	while not c.ready_for_play: await get_tree().process_frame
	c.ui.close_modal(); c.live.director.enabled = false; c.player.set_physics_process(false)
	var upper = c.get_node_or_null("UpperCampusBosses")
	if upper == null:
		upper = preload("res://scripts/campaign/upper_campus_bosses.gd").new(); upper.name = "UpperCampusBosses"; upper.campaign = c; c.add_child(upper); await upper.setup()
	while not upper.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	check(upper.failures.is_empty(),"Arena placement")
	for enemy in get_tree().get_nodes_in_group("enemy"): enemy.set_physics_process(false)
	# AcademicExpansion adds its own actors; the old global count of nine is
	# obsolete. Validate the configured upper actors and unique duel identities.
	check(upper.actors.size() == upper.CONFIGS.size(),"All configured upper bosses exist")
	var duel_ids: Array[String] = []
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		check(not duel_ids.has(duel.boss_id),"Unique boss identity: "+str(duel.boss_id))
		duel_ids.append(duel.boss_id)
	for config in upper.CONFIGS:
		check(duel_ids.has(config.boss_id),"Upper boss retains duel: "+config.boss_id)
	var chosen_appearance: Dictionary = c.data.appearance.duplicate(true)
	for q in ["inicio","biblioteca","academico3","academico4"]: c.data.quests[q].state = 2
	for floor_id in ["5","6","7"]: c.events["floor:"+floor_id] = 1
	c.events["door:acceso7"] = 1; c.quests.refresh()
	for actor in upper.actors.values():
		var duel = actor.duel
		check(upper.arena_samples[actor.config.boss_id].size() >= 5,"Arena has capsule paths/camera space "+actor.config.boss_id)
		check(actor.health == actor.config.max_health,"Configured HP "+actor.config.boss_id)
		actor.take_hit(Vector3.ZERO,1000)
		check(actor.health == actor.config.max_health,"Neutral invulnerable "+actor.config.boss_id)
		duel.interact(c.player); check(duel.state == duel.DuelState.DIALOGUE,"E dialogue")
		duel.decline(); check(not actor.running and duel.state == duel.DuelState.NEUTRAL,"Decline neutral")
		duel.intro_duration = 0.02; duel.interact(c.player)
		await duel.accept()
		check(actor.combat_active(),"Accept real duel "+actor.config.role)
		check(not actor.prepared,"Unprepared duel allowed")
		actor.set_physics_process(false)
		c.player.global_position = actor.home+Vector3(4,0,0)
		actor.target = c.player
		actor.start_attack("WORD SHOT" if actor.config.role == "INGLES" else ("HOJA CORTANTE" if actor.config.role == "LENGUAJE" else "DUDA"))
		actor.resolve_attack()
		check(actor.projectiles.size() == 1,"Projectile attack")
		for index in 10: actor.shoot("CAP",Vector3.FORWARD,6,1)
		check(actor.projectiles.size() == 6,"Hard cap of six projectiles")
		for index in 7: actor.zone("CAP",actor.home,1,1.2,0.3,1)
		check(actor.effects.size() == 5,"Hard cap of five ground zones")
		var warning_zone = actor.effects[0]
		warning_zone.set_physics_process(false)
		c.player.global_position = warning_zone.global_position
		var player_hp: float = c.player.health
		warning_zone._physics_process(0.1)
		check(c.player.health == player_hp,"Telegraph never damages before its warning")
		actor.take_hit(Vector3.ZERO,actor.boss_max_health*0.4)
		check(actor.phase == 2,"Phase 60%")
		actor.take_hit(Vector3.ZERO,actor.boss_max_health*0.3)
		check(actor.phase == 3,"Phase 30%")
		if actor.config.role == "ETICA":
			check(actor.effects.filter(func(e): return e.kind == "choice").size() == 2,"Two physical choice zones")
			var stance_zone = actor.effects.filter(func(e): return e.choice == "A")[0]
			c.player.global_position = stance_zone.global_position
			stance_zone._physics_process(0.01)
			check(actor.choice == "A" and not c.ui.modal,"Choose by walking, no quiz")
			var before: float = actor.health
			actor.take_hit(Vector3.ZERO,10)
			check(is_equal_approx(before-actor.health,12),"A +20% outgoing damage scoped to duel")
			c.player.health = 100; actor.hit_player(10)
			check(is_equal_approx(c.player.health,88.5),"A receives +15% damage")
		duel.reset_duel()
		check(actor.health == actor.boss_max_health and actor.phase == 1 and actor.effects.is_empty() and actor.projectiles.is_empty(),"Reset cleans threats")
		c.data.computers[actor.config.computer_id] = true
		duel.interact(c.player); await duel.accept(); actor.set_physics_process(false)
		check(actor.prepared and c.data.unlocks.get(actor.config.preparation_flag,false),"Preparation flag from original PC")
		c.player.global_position = actor.home+Vector3(4,0,0); actor.target = c.player
		if actor.config.role == "INGLES":
			actor.start_attack("WORD RUSH"); actor.resolve_attack()
			check(actor.projectiles.size() <= 6 and actor.attack_timer > 3.3,"English preparation reduces rush frequency")
			actor.start_attack("VOCABULARY STORM")
			check(actor.effects.size() == 2 and actor.effects[0].warning >= 1.2,"Storm telegraphed, limited zones")
		if actor.config.role == "LENGUAJE":
			actor.start_attack("TINTA"); actor.resolve_attack()
			check(actor.effects.size() == 1 and actor.effects[0].lifetime == 2,"Prepared ink duration")
			var speed_before: float = c.player.progression_speed
			actor.apply_ink(c.player)
			check(is_equal_approx(c.player.progression_speed,speed_before*0.85),"Prepared ink weaker slow")
			actor._slow_effect.clear_slow(); await get_tree().process_frame
			check(is_equal_approx(c.player.progression_speed,speed_before),"Slow cleanup restores movement")
		if actor.config.role == "ETICA":
			actor.take_hit(Vector3.ZERO,actor.boss_max_health*0.4)
			check(actor.choices_remaining == 10,"Prepared reflection gives 10 seconds")
			actor.choose_stance("B")
			c.player.health = 100; actor.hit_player(10)
			check(c.player.health == 92,"B +20% defense")
			var before: float = actor.health; actor.take_hit(Vector3.ZERO,10)
			check(is_equal_approx(before-actor.health,8.5),"B −15% outgoing scoped to duel")
		# Existing pre-duel save policy and real retry path.
		var retry = c.live.retry
		check(not retry.snapshot.is_empty() and retry.duel == duel,"Existing checkpoint/snapshot captured")
		c.player.health = 17
		check(c.save_payload().health != 17,"Combat save uses pre-duel resources")
		c.player.dead = true; retry.on_death(); duel.reset_duel()
		check(retry.can_retry(),"Real death enables retry")
		await retry.retry_boss()
		await get_tree().create_timer(0.8).timeout
		check(not c.player.dead and actor.health == actor.boss_max_health and actor.combat_active(),"Real retry restores player and starts full-health duel")
		actor.set_physics_process(false)
		c.player.health = 20
		actor.take_hit(Vector3.ZERO,99999)
		check(c.data.bosses.get(actor.config.boss_id,false) and c.player.inventory.has_item(actor.config.reward),"Victory reward persisted")
		check(c.player.health == c.player.max_health and actor.dead and actor.is_inside_tree(),"Victory heals, body remains")
		var credits: int = c.data.credits
		c.boss_won(duel)
		check(c.data.credits == credits and c.player.inventory.count_item(actor.config.reward) == 1,"Reward idempotent")
		check(c.data.appearance == chosen_appearance,"Cosmetics never auto-equip")
		c.data.computers[actor.config.computer_id] = false
		c.quests.refresh()
		var quest_id: String = {"INGLES":"academico5","LENGUAJE":"seguridad6","ETICA":"acceso7"}[actor.config.role]
		check(c.quests.state(quest_id) == 2,"Main action mission completes without PC")
	# Existing Director preserved, with optional document preparation.
	var director = scene.get_node("Piso8/EncuentroDirectorInformatica/DirectorInformaticaBoss")
	if director == null: director = get_tree().get_nodes_in_group("boss_duel").filter(func(d): return d.boss_id == "director")[0].actor
	check(director.health == 700 and director.boss_max_health == 700,"Director 700 HP")
	check(is_equal_approx(director.body.scale.x,1.2),"Director human visual scale")
	var dd = director.get_node("BossDuelController")
	dd.state = dd.DuelState.COMBAT; c.active_duel = dd; director.target = c.player
	c.player.global_position = director.home+Vector3(4,0,0)
	c.data.computers.pc8 = true
	director._activate_security(); director._activate_security()
	check(director.minions.size() == 2,"Director max two viruses")
	check(director.minions.all(func(v): return v.health == 40),"NEXO document gives lighter viruses")
	director._director_zone("FIREWALL",director.home,0.8,7)
	director._director_zone("ACCESO DENEGADO",c.player.global_position,1.5)
	check(director.effects.size() == 2 and director.effects[0].warning == 1.8,"Director telegraphs limited hazards")
	dd.reset_duel(); check(director.effects.is_empty() and director.minions.is_empty(),"Director reset cleans added hazards")
	check(scene.get_node("Piso1/Casino/ChefSupremoCasino").boss_max_health == 350,"Chef remains 350")
	var qa = preload("res://scripts/live/qa_tools.gd").new().run(c)
	check(qa.errors.is_empty(),"Quest/item/boss ID references")
	# Save/reload actual appearance, boss victory, PC flags and legacy completed quests.
	c.save_path = "res://.godot/upper_campus_save.json"; c.persist = true; c.save_game(); c.persist = false
	check(c.last_save_succeeded,"Actual save success")
	var payload = preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(c.save_path)
	check(preload("res://scripts/juego/character_appearance.gd").normalize(payload.appearance,c.data.cosmetics) == chosen_appearance and payload.bosses.profesor_ingles,"Appearance and victories JSON roundtrip")
	var saved_visuals: Dictionary = c.data.npc_visuals.duplicate(true)
	scene.queue_free(); await get_tree().process_frame
	scene = load("res://Main.tscn").instantiate(); c = scene.get_node("CampusCampaign")
	c.persist = true; c.save_path = "res://.godot/upper_campus_save.json"; c.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false; add_child(scene)
	while not c.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	c.persist = false; c.ui.close_modal(); c.player.set_physics_process(false); c.live.director.enabled = false
	upper = c.get_node("UpperCampusBosses")
	check(JSON.parse_string(JSON.stringify(c.data.npc_visuals)) == JSON.parse_string(JSON.stringify(saved_visuals)),"Stable NPC/boss wardrobe after load")
	check(c.data.appearance == chosen_appearance,"Chosen player outfit after load")
	c.player.global_position = Vector3(0,2,0)
	for actor in upper.actors.values():
		actor.body.lod_tick = 0; actor.body.update_visual_lod(0.1)
		check(actor.body.lod_level == 2 and not actor.body.secondary_animation_enabled,"Other floors disable secondary visual processing")
	check(upper.actors.values().all(func(a): return a.duel.defeated),"All academic victories remain defeated after load")
	check(c.quests.state("academico5") == 2 and c.floor_unlocked("8"),"Completed quest/unlock preserved")
	# A legacy completed stage is never reopened just because a new boss exists.
	c.data.bosses.erase("profesor_ingles"); c.data.quests.academico5.state = 2; c.quests.refresh()
	check(c.quests.state("academico5") == 2,"Legacy completed mission remains complete")
	result = {"checks":checks,"failures":failures,"bosses":upper.actors.size(),"memory_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"render_fps_sample":Performance.get_monitor(Performance.TIME_FPS),"arena_samples":{}}
	for key in upper.arena_samples: result.arena_samples[key] = upper.arena_samples[key].size()
	finished = true
	print("UPPER_CAMPUS_RESULT "+JSON.stringify(result))
	var file := FileAccess.open("res://reports/upper_campus_result.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(result,"\t")); file.close()
	if "--auto-quit" in OS.get_cmdline_user_args(): get_tree().quit(0 if failures.is_empty() else 1)
