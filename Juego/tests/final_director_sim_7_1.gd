extends Node
var f: Node
func install(parent: Node) -> String:
	f=parent;parent.add_child(self);run.call_deferred();return "DIRECTOR_SIMULATION_CHECK_STARTED"
func run() -> void:
	f.active_floor=8;f.phase="director_simulation_retry"
	var c=f.campaign;var d=get_tree().get_nodes_in_group("boss_duel").filter(func(duel): return duel.boss_id=="director")[0]
	c.ui.show();c.ui.close_modal();f.player.busy=false
	f.player.global_position=d.interaction_target().global_position+Vector3(0,0,2.5)
	await get_tree().physics_frame;await get_tree().physics_frame
	var scanner=f.player.get_node("InteractionController");scanner.scan()
	f.record("director_E_after_tasks","PASS" if scanner.selected==d else "FAIL")
	if scanner.selected==d: scanner.interact_selected()
	else: d.interact(f.player)
	for button in c.ui.column.find_children("*","Button",true,false):
		if button.text.begins_with("INICIAR SIMUL"): button.pressed.emit();break
	var began=Time.get_ticks_msec()
	while d.state==d.DuelState.INTRO and Time.get_ticks_msec()-began<12000: await get_tree().process_frame
	f.record("director_digital_simulation_start","PASS" if d.state==d.DuelState.COMBAT and d.simulation.active and d.simulation.hologram.visible and d.simulation.mentor.visible and not d.simulation.original_visual.visible else "BLOCKED",{"state":d.state,"published_profile_present":c.get_node("DuocGames4").published_mentors.has("director"),"scope":"Actual simulation button after three earned tasks; isolated unauthenticated catalog. Does not certify a published evaluation"})
	await f.shot("digital_entity_and_mentor",d.spawn_position+Vector3(2,3,8),d.spawn_position+Vector3.UP*1.4)
	d.reset_duel();d.actor.set_physics_process(false)
	f.record("director_simulation_reset_no_reward","PASS" if not c.data.bosses.get("director",false) and not f.player.has_key_item("CredencialDirector") and not d.simulation.active else "FAIL")
	f.write("floor_8/simulation_done",{"state":d.state})
