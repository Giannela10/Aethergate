extends Node
var f: Node
func install(parent: Node) -> String:
	f=parent;parent.add_child(self);play.call_deferred();return "DIRECTOR_ANTIVIRUS_UI_STARTED"
func play() -> void:
	f.active_floor=8;f.phase="director_play"
	var c=f.campaign;var pc=c.get_node("director_antivirus")
	f.player.global_position=pc.global_position+Vector3(0,0,1.5)
	f.player._use_computer(pc)
	var ui=c.manager.minigame;var game=ui.current;var clicks=0;var began=Time.get_ticks_msec()
	await RenderingServer.frame_post_draw
	f.get_viewport().get_texture().get_image().save_png(f.out+"floor_8/antivirus_before_play.png")
	while ui.active and Time.get_ticks_msec()-began<25000:
		if is_instance_valid(game):
			for button in game.buttons:
				if button.text=="VIRUS!": button.pressed.emit();clicks+=1
		await get_tree().create_timer(0.12).timeout
	f.record("director_antivirus_completed","PASS" if pc.done and c.academic_expansion.state.flags.get("director_task_antivirus",false) else "FAIL",{"clicks":clicks,"scope":"Timed clicks on actual visible VIRUS buttons; no completion signal, timer or result injected"})
	f.record("director_three_tasks","PASS" if c.academic_expansion.director_count()==3 else "FAIL",{"count":c.academic_expansion.director_count(),"missing":c.academic_expansion.boss_missing("director")})
	f.record("director_reward_not_faked","PASS" if not c.data.bosses.get("director",false) and not f.player.has_key_item("CredencialDirector") else "FAIL")
	f.write("floor_8/antivirus_play_done",{"clicks":clicks,"done":pc.done})
