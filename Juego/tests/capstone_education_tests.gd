extends Node3D
var failures=[]
var checks=0
var campus: Node
var campaign: Node
var bank: Dictionary
var by_id={}
var teacher_rows=[]
func check(value: bool, label: String) -> void:
	checks+=1
	if not value: failures.append(label);push_error(label)
func _ready(): run.call_deferred()
func press(text: String) -> bool:
	for button in campaign.ui.column.find_children("*","Button",true,false):
		if button.text==text and not button.is_queued_for_deletion(): button.pressed.emit();return true
	return false
func current_view() -> Node:
	for child in campaign.ui.column.get_children():
		if not child.is_queued_for_deletion() and child.get_script()!=null and child.get_script().resource_path.ends_with("learning_activity_view.gd"): return child
	return null
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/capstone_capturas/"+label+".png")
func unit_bank() -> void:
	for question in bank.questions: by_id[question.id]=question
	check(by_id.size()==150,"150 stable unique IDs")
	for subject in bank.subjects:
		var questions=bank.questions.filter(func(q): return q.subject_id==subject.id)
		check(questions.size()==15,subject.code+" has 15")
		for difficulty in ["easy","medium","hard"]: check(questions.filter(func(q): return q.difficulty==difficulty).size()==5,subject.code+" difficulty "+difficulty)
		var service=preload("res://scripts/education/local_practice_service.gd").new()
		var mentor=str(questions[0].mentor_id);var seen={}
		for index in 15:
			var q=service.fetch(int(subject.floor),"teacher_challenge",mentor)
			check(not q.has("error"),subject.code+" fetch "+str(index))
			if q.has("error"): continue
			check(not seen.has(q.id),subject.code+" no early repeat");seen[q.id]=true
			check(not q.has("answer") and not q.has("explanation") and q.content.options.size()==4,"Student projection")
			check(service.submit(q.id,9,"teacher_challenge").has("error"),"Invalid answer rejected")
			var correct=service.submit(q.id,by_id[q.id].answer,"teacher_challenge")
			check(correct.get("correct",false) and not correct.verified and correct.educational_xp==0 and not correct.explanation.is_empty(),"Correct feedback without verification")
			check(service.submit(q.id,by_id[q.id].answer,"teacher_challenge").has("error"),"Replay rejected")
		var q=service.fetch(int(subject.floor),"teacher_challenge",mentor)
		var wrong=service.submit(q.id,(int(by_id[q.id].answer)+1)%4,"teacher_challenge")
		check(not wrong.correct and not wrong.explanation.is_empty(),subject.code+" incorrect feedback")
		check(service.fetch(int(subject.floor),"mission",mentor).has("error"),"No local mission validation")
		service.catalog.questions=[]
		check(service.fetch(int(subject.floor),"training",mentor).has("error"),"Empty bank error")
		service.catalog.questions=[{"id":questions[0].id,"active":true,"answer":-1}]
		check(service.fetch(int(subject.floor),"training",mentor).has("error"),"Invalid record skipped")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/capstone_capturas"))
	bank=JSON.parse_string(FileAccess.get_file_as_string("res://resources/education/capstone_practice_bank.json"))
	unit_bank()
	campus=load("res://Main.tscn").instantiate();campaign=campus.get_node("CampusCampaign")
	campaign.persist=false;campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	campaign.ui.close_modal();campaign.live.director.set_process(false)
	for actor in campus.find_children("*","CharacterBody3D",true,false):
		if actor!=campaign.player: actor.set_physics_process(false)
	var player=campaign.player
	for id in bank.mentors:
		var duel: Node
		for candidate in get_tree().get_nodes_in_group("boss_duel"):
			if candidate.boss_id==id: duel=candidate;break
		check(duel!=null,"Teacher exists "+id)
		if duel==null: continue
		campaign.ui.close_modal();duel.decline()
		var target=duel.interaction_target()
		var safe=null
		for offset in [Vector3(0,0,2),Vector3(2,0,0),Vector3(-2,0,0),Vector3(0,0,-2)]:
			safe=player.get_node("SeatController").safe_position(target.global_position+offset)
			if safe!=null and absf(safe.y-target.global_position.y)<0.7:
				player.global_position=safe;player.velocity=Vector3.ZERO
				await get_tree().physics_frame
				if player.get_node("InteractionController").can_reach_target(duel): break
			safe=null
		check(safe!=null,"Approachable "+id)
		if safe==null: continue
		player.global_position=safe;player.velocity=Vector3.ZERO
		await get_tree().create_timer(0.12).timeout
		var expected_floor=int(bank.mentors[id].floor)
		var reachable=player.get_node("InteractionController").can_reach_target(duel)
		check(int(campaign.phone._floor_for(duel.actor))==expected_floor,"Correct floor "+id)
		check(reachable,"Reachable teacher "+id)
		check(not duel.interaction_text(player).is_empty(),"Interaction prompt "+id)
		if id=="profesor_datos":
			player.set_physics_process(false)
			var wall=StaticBody3D.new();var col=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(0.4,2,0.4);col.shape=shape;wall.add_child(col);add_child(wall)
			wall.global_position=(player.global_position+target.global_position)*0.5+Vector3.UP*1.2
			await get_tree().physics_frame;await get_tree().physics_frame
			check(not player.get_node("InteractionController").can_reach_target(duel),"Wall still blocks educational interaction")
			wall.queue_free();await get_tree().physics_frame;await get_tree().physics_frame
			check(player.get_node("InteractionController").can_reach_target(duel),"Reach recovers after temporary wall removed")
			player.set_physics_process(true)
		duel.interact(player)
		await get_tree().process_frame
		check(player.busy,"Dialogue opens "+id)
		var opened=press("ACTIVIDAD DEL DOCENTE") or press("EVALUACIÓN INTEGRADORA") or press("ACTIVIDAD DE REDES")
		check(opened,"Education entry "+id)
		await get_tree().process_frame
		check(press("PRÁCTICA LOCAL"),"Local choice "+id)
		await get_tree().process_frame
		var seen={};var before=int(campaign.data.academic_progress.answered)
		var rewards=JSON.stringify([campaign.data.credits,campaign.data.xp,campaign.data.bosses,campaign.data.unlocks])
		for attempt in 3:
			var view=current_view();check(view!=null,"Question view "+id)
			if view==null: break
			var q: Dictionary=view.activity
			check(not seen.has(q.id),"Consecutive questions unique "+id);seen[q.id]=true
			var buttons=view.find_children("*","Button",true,false)
			check(buttons.size()==4,"Four UI alternatives "+id)
			if id=="profesor_datos" and attempt==0: await capture("03_pregunta_bases_datos")
			var key=int(by_id[q.id].answer)
			buttons[(key+1)%4 if attempt==0 else key].pressed.emit()
			await get_tree().process_frame
			check(int(campaign.data.academic_progress.answered)==before+attempt+1,"Answer recorded "+id)
			if id=="profesor_datos" and attempt==1: await capture("04_retroalimentacion_correcta")
			if attempt<2: check(press("OTRA ACTIVIDAD"),"Next question "+id);await get_tree().process_frame
		check(JSON.stringify([campaign.data.credits,campaign.data.xp,campaign.data.bosses,campaign.data.unlocks])==rewards,"No duplicate or official rewards "+id)
		check(not campaign.data.education_v4.get("mentor_passes",{}).get(id,false),"No forged mentor pass "+id)
		check(press("CONTINUAR"),"Close "+id);await get_tree().process_frame
		check(not player.busy,"Close releases player "+id)
		duel.interact(player);await get_tree().process_frame
		press("ACTIVIDAD DEL DOCENTE") or press("EVALUACIÓN INTEGRADORA") or press("ACTIVIDAD DE REDES")
		await get_tree().process_frame
		press("PRÁCTICA LOCAL");await get_tree().process_frame
		var reopened=current_view();check(reopened!=null and not seen.has(reopened.activity.id),"Reopen keeps deck "+id)
		campaign.ui.close_modal();duel.decline()
		var old_position=target.global_position
		var old_player_position=player.global_position
		var moved=player.get_node("SeatController").safe_position(old_position+Vector3(6,0,0))
		if moved!=null and absf(moved.y-old_position.y)<0.5:
			target.global_position=moved
			var approach=player.get_node("SeatController").safe_position(moved+Vector3(0,0,2))
			if approach!=null: player.global_position=approach
		duel.defeated=true;duel.state=duel.DuelState.DEFEATED
		check(not duel.interaction_text(player).is_empty(),"Completed teacher retains education prompt "+id)
		player.get_node("InteractionController").scan()
		check(player.get_node("InteractionController").selected==duel,"Visible mentor selected after relocation "+id)
		duel.interact(player);await get_tree().process_frame
		check(press("ACTIVIDAD DEL DOCENTE") or press("ACTIVIDAD DE REDES"),"Practice available after completed simulation "+id)
		await get_tree().process_frame
		campaign.ui.close_modal();duel.decline();duel.defeated=false
		target.global_position=old_position;player.global_position=old_player_position
		teacher_rows.append({"id":id,"floor":expected_floor,"reachable":reachable,"questions":bank.mentors[id].question_ids.size(),"three_consecutive_answers":int(campaign.data.academic_progress.answered)-before,"no_official_rewards":JSON.stringify([campaign.data.credits,campaign.data.xp,campaign.data.bosses,campaign.data.unlocks])==rewards})
		print("CAPSTONE_TEACHER ",id)
	var progress=preload("res://scripts/education/academic_progress.gd")
	var restored=progress.migrate(JSON.parse_string(JSON.stringify(campaign.data)))
	check(restored.academic_progress.answered==campaign.data.academic_progress.answered,"Practice survives save serialization and migration")
	check(restored.academic_progress.practice_answers==33,"33 UI attempts saved as practice")
	var result={"checks":checks,"failures":failures,"teachers":teacher_rows,"all_questions_exercised":150,"remote_published":0,"practice_answers":campaign.data.academic_progress.answered,"save_roundtrip":"Isolated JSON serialization and production migration; not remote persistence"}
	var file=FileAccess.open("res://reports/capstone/education_tests.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"\t"));file.close()
	print("CAPSTONE_EDUCATION_DONE ",failures.size())
