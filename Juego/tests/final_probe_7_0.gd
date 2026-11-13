extends Node
var fixture: Node
var c: Node
var p: CharacterBody3D
var rows=[]
var out: String
func install(parent: Node) -> String:
	fixture=parent;c=parent.campaign;p=parent.player;out=parent.out
	parent.add_child(self);run.call_deferred()
	return "FINAL70_PROBES_STARTED"
func record(label: String, passed: bool, detail: Variant=null) -> void:
	rows.append({"test":label,"passed":passed,"detail":detail})
	var f=FileAccess.open(out+"targeted_checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"\t"))
	print("FINAL70_TARGET ",label," ",passed)
func run() -> void:
	var area=c.final_area
	record("nexo_actual_reference",is_instance_valid(area) and area.is_inside_tree(),str(area.get_path()))
	area.enter_core()
	record("nexo_prerequisites_preserved",not area.archive_available() and not area.can_access() and not area.authorized() and not c.data.unlocks.get("door:nexo_core",false),{"placement_valid":area.placement_valid})
	await punto_probe()
	if c.quests.state("inicio")!=2: await fixture.first_mission()
	await routes()
	await library()
	await save_roundtrip()
	var file=FileAccess.open(out+"targeted_done.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":rows.size(),"failures":rows.filter(func(r): return not r.passed)},"\t"))
	print("FINAL70_TARGET_DONE")
func punto_probe() -> void:
	var duel=fixture.campus.get_node("Piso1/SalaAyudaEstudiantil/BossAyudaEstudiantil/BossDuelController")
	var previous_state=duel.state;var previous_defeated=duel.defeated
	duel.state=duel.DuelState.NEUTRAL;duel.defeated=false
	var mentor=duel.simulation.mentor
	var previous_position=mentor.global_position
	mentor.global_position=duel.spawn_position
	c.active_duel=null;c.ui.close_modal();p.busy=false;p.dead=false
	var scanner=p.get_node("InteractionController")
	var samples=[];var accessible=false
	for offset in [Vector3(0,0,1.6),Vector3(0,0,-1.6),Vector3(1.6,0,0),Vector3(-1.6,0,0),Vector3(0,0,3),Vector3(3,0,0),Vector3(-3,0,0)]:
		p.global_position=mentor.global_position+offset
		await get_tree().physics_frame;await get_tree().physics_frame
		scanner.scan()
		var ray=PhysicsRayQueryParameters3D.create(p.global_position+Vector3.UP*1.2,mentor.global_position+Vector3.UP*1.2)
		ray.exclude=[p.get_rid()]
		if duel.actor is CollisionObject3D: ray.exclude.append(duel.actor.get_rid())
		var hit=p.get_world_3d().direct_space_state.intersect_ray(ray)
		var selected=scanner.selected==duel
		samples.append({"offset":str(offset),"selected":str(scanner.selected.get_path()) if scanner.selected else null,"can_reach":scanner.can_reach_target(duel),"blocker":str(hit.collider.get_path()) if not hit.is_empty() else null,"safe":p.get_node("SeatController").safe_position(p.global_position)!=null})
		if selected:
			accessible=true;scanner.interact_selected()
			record("punto_real_dialogue",duel.state==duel.DuelState.DIALOGUE)
			duel.decline()
			break
	record("punto_access_from_valid_side",accessible,samples)
	mentor.global_position=previous_position;duel.state=previous_state;duel.defeated=previous_defeated
func routes() -> void:
	# Actual player/controller input, no changes to collision masks or campaign gates.
	await walk(Vector3(-53.5,12.2,-125),Vector3(-53.5,12.2,-116),"library_main_aisle",7)
	await walk(Vector3(70,12.2,-118.5),Vector3(64,12.2,-118.5),"auditorium_entry1",6)
	await walk(Vector3(70,12.2,-90.5),Vector3(64,12.2,-90.5),"auditorium_entry2",6)
	await walk(Vector3(-22.65,0.15,-150),Vector3(-22.65,3,-157),"stairs_floor1_first_flight",7)
	await walk(Vector3(24.37,-11.9,-124),Vector3(24.37,-7,-138),"basement_ramp_up",9)
func walk(start: Vector3, target: Vector3, label: String, timeout: float) -> void:
	c.ui.close_modal();p.busy=false;p.dead=false;p.velocity=Vector3.ZERO
	var safe=p.get_node("SeatController").safe_position(start)
	if safe==null: record(label,false,{"reason":"No capsule-clear starting point","start":str(start)});return
	p.global_position=safe
	var direction=target-safe;direction.y=0;direction=direction.normalized()
	p.cam_yaw=atan2(-direction.x,-direction.z)
	c.manager.cam_yaw=p.cam_yaw;c.manager.cam.make_current();c.manager.set_process(true)
	p.body.show();p.set_process(true);p.set_physics_process(true)
	await get_tree().create_timer(0.4).timeout
	Input.action_press("move_forward")
	var elapsed=0.0;var trace=[]
	while elapsed<timeout:
		await get_tree().create_timer(0.2).timeout;elapsed+=0.2
		trace.append(str(p.global_position))
		var offset=target-p.global_position;offset.y=0
		if offset.length()<0.65: break
	Input.action_release("move_forward")
	var remaining=target-p.global_position;remaining.y=0
	var blockers=[]
	for i in p.get_slide_collision_count(): blockers.append(str(p.get_slide_collision(i).get_collider().get_path()))
	record(label,remaining.length()<0.8,{"start":str(safe),"end":str(p.global_position),"target":str(target),"blockers":blockers,"trace":trace,"note":"Input-driven segment; vertical target is diagnostic, horizontal reach is assertion"})
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out+"route_"+label+".png")
	p.set_process(false);p.set_physics_process(false);p.body.hide();c.manager.set_process(false);fixture.camera.make_current()
func library() -> void:
	var librarian=fixture.campus.get_node("Piso2/Biblioteca/BossBibliotecaria")
	var duel=librarian.get_node("BossDuelController")
	var count=0
	for node in c.get_children():
		if node.get("item_id")!="LibroBiblioteca": continue
		p.global_position=node.global_position+Vector3(0.7,0,0);p.busy=false
		await get_tree().physics_frame
		node.interact(p)
		if node.collected: count+=1
	record("three_books_real_pickups",count==3,{"collected":count,"objective":c.quests.progress({"kind":"collect","id":"LibroBiblioteca","amount":3})})
	p.global_position=librarian.global_position+Vector3(-2.8,0,0);p.busy=false;c.ui.close_modal()
	await get_tree().physics_frame
	duel.interact(p)
	record("library_dialogue",duel.state==duel.DuelState.DIALOGUE)
	await duel.accept()
	await get_tree().process_frame
	record("library_quiz_started",librarian.active and librarian.current_question.size()==5 and librarian.answers.size()==3,{"type":duel.duel_type,"question":librarian.question_text.text})
	if not librarian.active: return
	# Preserve the real question deck and answer buttons. No fabricated quest event.
	for i in 5:
		var answer=-1
		for j in librarian.answers.size():
			if librarian.answers[j].get_meta("correct",false): answer=j
		if answer<0: record("valid_question_"+str(i),false);break
		librarian.answers[answer].pressed.emit()
		record("question_feedback_"+str(i),librarian.answered and not librarian.feedback.text.is_empty(),{"question":str(librarian.current_question[1]),"feedback":librarian.feedback.text})
		await RenderingServer.frame_post_draw
		if i==0: get_viewport().get_texture().get_image().save_png(out+"library_question_feedback.png")
		librarian.next_button.pressed.emit()
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	record("library_quiz_finished",librarian.defeated and not librarian.active and c.data.bosses.get("bibliotecaria",false))
	record("library_quest_unlock3",c.quests.state("biblioteca")==2 and c.floor_unlocked("3"),{"state":c.quests.state("biblioteca"),"floor3":c.floor_unlocked("3"),"note":"Only checked unlock dependency; floor 3 not visited"})
	var credits=c.data.credits;var xp=c.data.xp
	c.quests.refresh();c.quests.refresh()
	record("library_no_duplicate_reward",credits==c.data.credits and xp==c.data.xp)
func save_roundtrip() -> void:
	var previous_path=c.save_path
	c.save_path=out+"isolated_campaign_save.json";c.persist=true
	c.save_game();c.persist=false
	var restored=preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(c.save_path)
	record("local_save_written_and_read",c.last_save_succeeded and not restored.is_empty())
	var expected=[c.data.credits,c.data.xp,c.data.quests.duplicate(true),c.data.collected.duplicate(true),c.player.inventory.snapshot_data()]
	if not restored.is_empty():
		c.data=preload("res://scripts/live/save_migration.gd").migrate(restored)
		c.quests.refresh()
		record("save_quests_rewards_persistent_ids",JSON.parse_string(JSON.stringify(expected.slice(0,4)))==JSON.parse_string(JSON.stringify([c.data.credits,c.data.xp,c.data.quests,c.data.collected])))
	c.save_path=previous_path
