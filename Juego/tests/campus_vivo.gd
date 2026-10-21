extends SceneTree
const Migration = preload("res://scripts/live/save_migration.gd")
const Campus = preload("res://scripts/live/campus_state.gd")
var failures: Array[String] = []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func _initialize() -> void:
	call_deferred("run")
	call_deferred("watchdog")
func watchdog() -> void:
	await create_timer(60).timeout
	push_error("CAMPUS_LIVE_TIMEOUT")
	quit(2)
func run() -> void:
	var migrated := Migration.migrate({"version":1,"quests":{"inicio":{"state":1}},"other_system":{"keep":true},"campus_live":{"reward_spent":9.0,"once":{"seen":true},"journal":["bad",{"title":"ok"}]}})
	check(migrated.save_version == 2 and migrated.version == 1,"Versioned compatible envelope")
	check(migrated.other_system.keep and migrated.quests.inicio.state == 1,"Unknown existing systems and progress preserved")
	check(migrated.campus_live.reward_spent == 9 and migrated.campus_live.journal.size() == 1,"Nested migration and finite reward cap survive JSON numbers")
	check(not Migration.supported({"version":1,"save_version":99}),"Future saves protected")
	check(Campus.derive({}) == 0,"Normal phase")
	check(Campus.derive({"computers":{"pc3":true}}) == 1,"Low anomaly")
	check(Campus.derive({"computers":{"pc6":true}}) == 2,"Medium anomaly")
	check(Campus.derive({"bosses":{"director":true}}) == 3,"High anomaly")
	check(Campus.derive({"campaign_completed":true}) == 4,"Restored campus after actual finale")
	var scene: Node = load("res://Main.tscn").instantiate()
	var c = scene.get_node("CampusCampaign")
	c.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene); current_scene = scene
	while not c.ready_for_play: await process_frame
	while get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await process_frame
	var live = c.live
	var player = c.player
	c.ui.close_modal()
	player.set_physics_process(false)
	live.director.set_process(false)
	for enemy in get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
		enemy.dead = true
	live.director.remaining = 0; live.director.combat_remaining = 0; live.director.state = 1
	check(live.director.can_offer(),"Director allows safe opportunity")
	live.director.acquire_story_lock("test")
	check(not live.director.can_offer(),"Explicit cinematic/story lock")
	live.director.release_story_lock("test"); live.director.state = 1
	player.busy = true
	check(not live.director.can_offer(),"No events during interaction")
	player.busy = false
	live.director.damage_received()
	check(not live.director.can_offer(),"Recent combat grace")
	live.director.combat_remaining = 0
	var npc = c.get_node("Tecnico")
	player.global_position = npc.global_position+Vector3(2,0,0)
	await physics_frame
	live.director.remaining = 0; live.director.state = 1
	var event = live.events.catalog.filter(func(e): return e.event_id == "tecnico_sistema")[0]
	var npc_position: Vector3 = npc.global_position
	check(live.events.start(event),"Ambient event at valid themed anchor")
	check(live.state.once.get("tecnico_sistema",false),"Unique event persisted at successful start")
	check(not live.events.start(event),"Single event cap")
	check(npc.global_position == npc_position,"Mission actor never relocated")
	live.events.finish()
	check(not live.events.eligible(event),"Unique event cannot repeat after cleanup/load")
	check(live.director.remaining >= live.config.minimum_gap,"Cooldown after event")
	live.director.remaining = 0; live.director.state = 1
	var situation_event = live.events.catalog.filter(func(e): return e.event_id == "orientar")[0]
	check(live.events.start(situation_event),"Short voluntary situation")
	if live.events.situation != null:
		var situation = live.events.situation
		player.global_position = situation.global_position+Vector3(0.5,0,0)
		var credits: int = c.data.credits
		situation.interact(player)
		check(c.data.credits == credits+3,"Small idempotent event reward")
		situation.interact(player)
		check(c.data.credits == credits+3,"No duplicate reward")
	live.events.finish()
	var spent_before: int = live.state.reward_spent
	for index in 20: live.events.reward_once("test_budget_"+str(index))
	check(live.state.reward_spent <= live.config.reward_budget,"No infinite event economy")
	var library_anchor: Node3D
	for node in get_nodes_in_group("campus_area"):
		if node.marker_id == "biblioteca": library_anchor = node
	player.global_position = library_anchor.global_position+Vector3(1,0,0)
	await physics_frame
	live.director.remaining = 0; live.director.state = 1
	var study = live.events.catalog.filter(func(e): return e.event_id == "biblioteca_estudio")[0]
	check(live.events.start(study),"Library scene uses editable resource override")
	if live.events.presentation != null:
		check(live.events.presentation.bodies.size() > 0 and live.events.presentation.bodies.size() <= 3,"Existing visual rig reused for bounded temporary cast")
		live.events.presentation.update(0.1)
	live.events.finish()
	var pc = get_nodes_in_group("computer")[0]
	pc.set_done()
	live.reactive.refresh()
	check(pc.done and pc.screen_text.text == "COMPLETADO","Repaired PC remains completed and usable logic preserved")
	var inv = player.inventory
	inv.add_item("Botiquin",2)
	var entry: Dictionary = inv.entries.filter(func(e): return e.item_id == "Botiquin")[0]
	inv.toggle_favorite(entry.uid)
	check(inv.discard_protected(entry.uid),"Favorite protects disposal")
	var saved: Dictionary = inv.snapshot_data().duplicate(true)
	live.restoring_inventory = true; inv.restore_snapshot(saved); c._capture_inventory(); live.restoring_inventory = false
	check(inv.entry_for(entry.uid).get("favorite",false),"Favorites survive inventory restore")
	live.qol.log_entry("Una actividad")
	live.qol.show_journal()
	check(c.ui.page == "phone:history","Activity in existing phone")
	c.ui.close_modal()
	player.global_position = npc.global_position+Vector3(1,0,0)
	c.ui.begin_character_dialogue(npc)
	c.ui.dialog(npc.npc_name,"Texto importante de prueba",["Cerrar"],[c.ui.close_modal])
	check(not live.state.dialogues.is_empty(),"Important dialogue history")
	c.ui.close_modal()
	for i in 5: live.qol.add_marker("Nota "+str(i))
	check(live.state.markers.size() == 3,"Bounded custom map markers")
	check(not live.qol.travel("Entrada"),"No fast travel before campaign completion")
	c.ui.close_modal()
	var previous_postgame: Dictionary = c.data.quests.postgame.duplicate(true)
	c.data["campaign_completed"] = true
	live.state.discoveries["floor:1"] = true
	live.director.combat_remaining = 0
	live.qol.show_map()
	check(live.qol.travel("Entrada"),"Postgame fast travel validates an existing arrival point")
	check(not live.qol.travel("Acceso a terraza"),"Undiscovered terrace cannot be bypassed")
	c.data.quests.postgame = previous_postgame
	c.data["campaign_completed"] = false
	c.ui.close_modal()
	live.moments.discover("floor:3","Piso 3","3")
	check(live.state.discoveries.get("floor:3",false),"Discovery persisted")
	var before_moments: int = live.moments.queue.size()
	live.moments.offer("test_once","Prueba","Texto","3")
	live.moments.offer("test_once","Prueba","Texto","3")
	check(live.moments.queue.size() == before_moments+1,"Story moment queue deduplicates")
	var report: Dictionary = live.diagnostics.balance_report()
	check(report.bosses.size() >= 4 and report.weapons.size() >= 10,"Read-only balance report")
	var qa: Dictionary = live.diagnostics.qa.run(c)
	check(qa.errors.is_empty(),"Quest/item/ID validators: "+str(qa.errors))
	check(qa.geometry_modified == false,"QA never edits campus geometry")
	live.settings.set_option("quality","BAJO")
	check(player.body.visual_far_distance == 22 and not player.body.cast_near_shadows,"Low graphics extends existing LOD")
	live.settings.set_option("fps",30)
	check(Engine.max_fps == 30,"FPS cap")
	live.settings.set_option("fps",0); live.settings.set_option("quality","ALTO")
	live.settings.set_option("language","en")
	check(TranslationServer.translate("Cerrar") == "Close","English infrastructure")
	live.settings.set_option("language","es")
	for size in [Vector2i(1920,1080),Vector2i(2560,1440)]:
		root.size = size
		c.ui.dialog("QA","Texto de prueba",["Cerrar"],[c.ui.close_modal],true)
		c.ui._fit()
		check(c.ui.panel.position.x >= 0 and c.ui.panel.position.y >= 0 and c.ui.panel.size.x*c.ui.panel.scale.x <= size.x,"UI fits "+str(size))
	c.ui.close_modal()
	var chef = scene.get_node("Piso1/Casino/ChefSupremoCasino/BossDuelController")
	player.global_position = chef.actor.global_position+Vector3(3,0,0)
	await physics_frame
	player.health = player.max_health
	chef.intro_duration = 0.1
	chef.interact(player); chef.accept()
	await create_timer(0.8).timeout
	check(chef.state == chef.DuelState.COMBAT and not live.retry.snapshot.is_empty(),"Pre-duel snapshot")
	check(not live.director.can_offer(),"No ambient events during boss")
	chef.actor.set_physics_process(false)
	var snapshot: Dictionary = live.retry.snapshot.inventory.duplicate(true)
	var events_before: Dictionary = c.events.duplicate(true)
	player.take_hit(Vector3.ZERO,100000)
	await process_frame; await process_frame
	check(live.retry.can_retry(),"Quick retry offered after boss death")
	await live.retry.retry_boss()
	await create_timer(0.8).timeout
	check(not player.dead and chef.state == chef.DuelState.COMBAT,"Retry reuses normal intro and duel state")
	check(player.inventory.snapshot_data() == snapshot,"Retry restores inventory, favorite flags, equipment and durability")
	check(int(c.events.get("collect:Botiquin",0)) == int(events_before.get("collect:Botiquin",0)),"Restore does not advance collection quests")
	chef.reset_duel()
	check(not c.data.bosses.get("chef",false),"Retry grants no boss reward")
	live.config.telemetry_enabled = false
	live.diagnostics.record("test")
	check(live.diagnostics.telemetry.is_empty(),"Telemetry opt-in only")
	print("CAMPUS_VIVO_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"qa_review":qa.manual_review}))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
