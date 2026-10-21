extends SceneTree
var checks := 0
var failures: Array[String] = []
func json_value(value: Variant) -> Variant:
	# Godot JSON represents integer fields as floats; compare serialized semantics.
	return JSON.parse_string(JSON.stringify(value))
func check(ok: bool,title: String) -> void:
	checks += 1
	if not ok: failures.append(title); push_error(title)
func _initialize() -> void: call_deferred("run"); call_deferred("watchdog")
func watchdog() -> void:
	await create_timer(90,true,false,true).timeout
	push_error("NEXO_TEST_TIMEOUT"); quit(2)
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var c = scene.get_node("CampusCampaign"); c.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene); current_scene = scene
	while not c.ready_for_play: await process_frame
	while get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await process_frame
	c.ui.close_modal(); c.player.set_physics_process(false); c.live.director.enabled = false
	for enemy in get_nodes_in_group("enemy"): enemy.set_physics_process(false); enemy.dead = true
	var player = c.player
	var area = c.final_area
	var boss = area.actor
	var duel = boss.duel
	check(area.placement_valid,"Existing basement points allow capsule")
	check(get_nodes_in_group("boss_duel").size() == 15,"Six previous bosses plus three academic action bosses")
	check(c.quests.definitions.size() == 20,"One principal finale, no duplicate quests")
	check(not area.can_access() and not c.live.completed(),"New game access and completion locked")
	area.enter_core(); check(not c.data.unlocks.get("door:nexo_core",false),"Unauthorized access cannot unlock core")
	var original_hp: float = boss.health
	boss.take_hit(Vector3.ZERO,99999)
	check(boss.health == original_hp and not boss.combat_active(),"Neutral NEXO never attacks or takes damage")
	var chair_rows = JSON.parse_string(FileAccess.get_file_as_string("res://reports/balance_1_0_data.json")).chairs.local_failures
	check(chair_rows.size() == 9,"Historical nine chairs retained as regression fixture")
	var ids := {}
	for row in chair_rows:
		var chair = scene.get_node(NodePath(str(row.path).trim_prefix("/root/Main/")))
		check(not str(chair.world_id).is_empty() and not ids.has(chair.world_id),"Stable unique chair ID: "+chair.world_id)
		ids[chair.world_id] = true
		var position_value = preload("res://tests/chair_access_probe.gd").find_approach(player,chair)
		check(position_value != null,"Local approach exists: "+chair.world_id)
		if position_value == null: continue
		player.global_position = position_value; await physics_frame
		var quantity: int = player.inventory.count_item("Silla")
		chair.interact(player)
		check(chair.collected and player.inventory.count_item("Silla") == quantity+1,"Actual pickup succeeds: "+chair.world_id)
		chair.interact(player)
		check(player.inventory.count_item("Silla") == quantity+1,"Chair pickup idempotent")
	var old_data := {"version":1,"quests":{"postgame":{"state":2}},"bosses":{"director":true},"cosmetics":{"nexo_jacket":true}}
	var migrated = preload("res://scripts/live/save_migration.gd").migrate(old_data)
	check(not migrated.campaign_completed and migrated.quests.postgame.state == 2 and migrated.cosmetics.nexo_jacket,"Legacy archive/rewards preserved without granting new ending")
	check(preload("res://scripts/live/campus_state.gd").derive(migrated) == 3,"Legacy archive no longer restores campus early")
	# Progress fixture, not a playthrough: reuse the real final quest/access handlers.
	for q in c.quests.definitions.values():
		if q.main_quest and q.quest_id != "nexo_final": c.data.quests[q.quest_id].state = 2
	c.data.bosses["director"] = true; c.data.secrets["archivo_subterraneo"] = true
	c.quests.refresh(); c.give_reward_item("CredencialDirector",1)
	check(c.quests.state("nexo_final") == 1,"Final objective follows completed archive")
	area.read_archive()
	check(c.data.notes.has("proyecto_nexo_final") and duel.state == duel.DuelState.NEUTRAL,"Reading archive reveals information, never starts duel")
	c.ui.close_modal()
	player.global_position = area.access.global_position+Vector3(1,0,0); await physics_frame
	area.access.interact(player); area.access.interact(player)
	check(area.authorized() and int(c.events.get("door:nexo_core",0)) == 1,"Access opens once with archive/progress/credential")
	check(c.data.checkpoint.id == "NEXO · preparación","Nearby preparation checkpoint")
	player.global_position = boss.global_position+Vector3(0,0,1.8); await physics_frame
	duel.interact(player)
	check(duel.state == duel.DuelState.DIALOGUE and paused,"Final dialogue offers a safe choice")
	duel.decline()
	check(duel.state == duel.DuelState.NEUTRAL and not paused and not boss.running,"Retreat keeps boss neutral")
	player.receive_item("Bebida",2); player.receive_item("Palo",1)
	var entry = player.inventory.entries.filter(func(e): return e.item_id == "Palo")[0]
	player.inventory.equip_entry(entry.uid); player.weapon.durability = 7
	player.health = 75
	var chosen: Dictionary = c.data.appearance.duplicate(true)
	duel.intro_duration = 0.1; duel.interact(player); duel.accept()
	await create_timer(0.9).timeout
	boss.set_physics_process(false)
	check(boss.combat_active() and boss.health == area.config.max_health,"Accepted introduction reaches combat")
	check(not boss.router_assist,"Finale starts without optional equipment")
	var snapshot: Dictionary = c.live.retry.snapshot.inventory.duplicate(true)
	var credits_before: int = c.data.credits
	check(snapshot.equipped == entry.uid and snapshot.quick.size() == 4,"Existing snapshot captures weapon and quickslots")
	check(boss.start_attack("packet") and boss.projectiles.is_empty() and boss.charge > 0,"Packet has windup before spawn")
	boss.resolve_attack()
	check(boss.projectiles.size() == 1,"Packet reuses existing swept projectile")
	boss.clear_threats(); await process_frame
	boss.start_attack("zone"); boss.resolve_attack()
	check(boss.zones.size() == 1,"One floor hazard")
	boss.cooldowns["zone"] = 0
	boss.cancel_attack(); check(not boss.start_attack("zone"),"Zone concurrency cap")
	var hp: float = player.health
	boss.zones[0]._physics_process(0.5)
	check(player.health == hp,"Floor hazard warning does not damage immediately")
	boss.clear_threats(); await process_frame
	boss.take_hit(Vector3.ZERO,400)
	check(boss.phase == 2,"Phase 2 at 70 percent")
	boss.last_attack = "packet"; boss.cooldowns = {"fan":5.0}
	for iteration in 20:
		var selected: String = boss.choose_attack()
		check(selected != "packet" and selected != "fan","No immediate repeat or cooldown bypass")
	boss.take_hit(Vector3.ZERO,400)
	check(boss.phase == 3 and boss.active_links() == 3,"Phase 3 activates three links")
	check(is_equal_approx(boss.damage_factor(),0.46),"Three links give partial protection")
	player.receive_item("RouterPortatil",1); boss.prepare_core()
	check(boss.router_assist and is_equal_approx(boss.damage_factor(),0.64) and player.inventory.has_item("RouterPortatil"),"Router assists passively, without consumption")
	player.inventory.remove_items("RouterPortatil",1); boss.router_assist = false
	player.receive_item("USBInfectado",1)
	var usb = preload("res://scripts/inventory/item_catalog.gd").get_item("USBInfectado")
	var receiver = boss.get_node("ItemEffects")
	check(receiver.can_apply("USBInfectado") and receiver.apply_item(usb,player),"Existing USB receiver supports NEXO")
	check(receiver.remaining == 2.0,"USB stun is bounded")
	boss.take_hit(Vector3.ZERO,99999)
	check(boss.health == 1 and not boss.dead,"Links must be disabled before shutdown")
	for terminal in area.terminals:
		player.global_position = terminal.global_position+Vector3(0,0,1.3); await physics_frame
		var before: int = boss.active_links()
		terminal.interact(player); terminal.interact(player)
		check(not terminal.link and boss.active_links() == before-1,"Link disables exactly once: "+str(terminal.name))
	check(boss.active_links() == 0 and boss.damage_factor() == 1.0,"Core fully exposed")
	player.global_position = boss.global_position+Vector3(0,0,8); await physics_frame
	check(boss.start_attack("deletion") and boss.charge == area.config.deletion_warning,"Deletion gets explicit long warning")
	hp = player.health; boss.resolve_attack()
	check(player.health == hp,"Outer arena ring is safe from deletion")
	player.global_position = boss.global_position+Vector3(0,0,2); await physics_frame
	check(not boss.start_attack("deletion"),"Deletion cooldown cannot be bypassed")
	boss.cooldowns["deletion"] = 0 # Simulate its elapsed cooldown without a long sleep.
	boss.start_attack("deletion"); boss.resolve_attack()
	check(player.health == hp-area.config.deletion_damage and not player.dead,"Deletion is damaging, not instant death")
	player.take_hit(Vector3.ZERO,9999); await process_frame; await process_frame
	check(c.live.retry.can_retry() and c.ui.column.get_child(0).text.contains("NEXO"),"Death offers existing NEXO retry")
	c.live.retry.retry_boss(); await create_timer(0.9).timeout
	boss.set_physics_process(false)
	check(boss.combat_active() and boss.phase == 1 and boss.active_links() == 0,"Retry resets phase and links")
	check(player.health == 75 and player.inventory.snapshot_data() == snapshot and c.data.credits == credits_before,"Retry restores exact resources, durability, quickslots without reward")
	c.save_path = "res://.godot/closure-test-save.json"; c.persist = true; c.save_game(); c.persist = false
	var disk = JSON.parse_string(FileAccess.get_file_as_string(c.save_path))
	check(not disk.campaign_completed and disk.inventory.entries == json_value(snapshot.entries),"Pre-victory save is coherent")
	boss.take_hit(Vector3.ZERO,99999)
	for terminal in area.terminals:
		player.global_position = terminal.global_position+Vector3(0,0,1.3); await physics_frame; terminal.interact(player)
	boss.take_hit(Vector3.ZERO,10)
	check(c.data.campaign_completed and c.data.bosses.get("nexo",false) and c.quests.state("nexo_final") == 2,"Victory completes campaign and main quest")
	check(boss.dead and boss.projectiles.is_empty() and boss.zones.is_empty(),"Shutdown clears active threats")
	check(c.data.credits == credits_before+75,"New boss uses existing one-time reward")
	c.boss_won(duel)
	check(c.data.credits == credits_before+75,"Victory reward never duplicates")
	check(c.data.cosmetics.get("nexo_jacket",false) and c.data.appearance == chosen,"Final cosmetic unlock never changes selected clothes")
	check(c.live.completed() and c.live.campus_state.phase == 4,"Restored campus requires actual finale")
	await create_timer(2.9).timeout
	area.skip_credits()
	check(c.ui.column.get_child(0).text.contains("CAMPAÑA COMPLETADA") and area.results_text().contains("Armas de escenario"),"Final results use recorded statistics")
	c.persist = true; c.save_game(); c.persist = false
	var save_path: String = c.save_path
	disk = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	check(disk.campaign_completed and disk.bosses.nexo and disk.quests.nexo_final.state == 2,"Postgame saved to real JSON")
	c.ui.close_modal(); scene.queue_free(); await process_frame
	scene = load("res://Main.tscn").instantiate(); c = scene.get_node("CampusCampaign")
	c.set_meta("test_mode",true); c.save_path = save_path
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene); current_scene = scene
	while not c.ready_for_play: await process_frame
	while get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await process_frame
	c.persist = false
	check(c.loaded_save and c.data.campaign_completed and c.final_area.actor.duel.defeated and not c.final_area.actor.combat_active(),"Close scene/load keeps NEXO permanently defeated")
	check(c.live.campus_state.phase == 4 and json_value(c.player.inventory.snapshot_data().entries) == disk.inventory.entries,"Load preserves restoration and inventory")
	check(c.player.inventory.has_item("Bebida",2) and c.player.weapon != null and c.player.weapon.durability == 7,"Load preserves actual consumable quantity and weapon wear")
	check(c.quests.state("llaves") == 0,"Pending side quests remain available")
	check(c.data.unlocks.get("nexo_credits_seen",false),"Credits choice persists")
	c.ui.close_modal(); scene.queue_free(); await process_frame
	print("NEXO_FINAL_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
