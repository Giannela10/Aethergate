extends Node3D
var campaign: Node
var failures=[]
var camera: Camera3D
func _ready(): run.call_deferred()
func press(label: String) -> bool:
	for button in campaign.ui.column.find_children("*","Button",true,false):
		if button.text==label and not button.is_queued_for_deletion(): button.pressed.emit();return true
	failures.append("Missing button: "+label);return false
func capture(label: String):
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/capstone_capturas/"+label+".png")
func run():
	var campus=load("res://Main.tscn").instantiate();campaign=campus.get_node("CampusCampaign")
	campaign.persist=false;campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	campaign.ui.close_modal();campaign.live.director.set_process(false)
	campaign.get_node("AcademicFloorGate").set_physics_process(false)
	var duel: Node
	for candidate in get_tree().get_nodes_in_group("boss_duel"):
		if candidate.boss_id=="profesor_datos": duel=candidate
	var target=duel.interaction_target();var player=campaign.player
	var safe=player.get_node("SeatController").safe_position(target.global_position+Vector3(0,0,4.2))
	if safe==null: failures.append("No demo approach");finish({});return
	player.global_position=safe;player.velocity=Vector3.ZERO
	camera=Camera3D.new();camera.fov=65;add_child(camera)
	camera.global_position=target.global_position+Vector3(5,3.2,7)
	camera.look_at(target.global_position+Vector3(0,1,1.5));camera.make_current()
	campaign.manager.cam_yaw=0
	await get_tree().create_timer(2).timeout
	var started=Time.get_ticks_msec()
	await capture("01_campus_demo")
	await get_tree().create_timer(7).timeout
	var before=player.global_position
	Input.action_press("move_forward")
	await get_tree().create_timer(0.6).timeout
	Input.action_release("move_forward")
	var distance=before.distance_to(player.global_position)
	if distance<0.3: failures.append("Actual input movement too small: "+str(distance))
	await get_tree().create_timer(4).timeout
	player.get_node("InteractionController").scan()
	if player.get_node("InteractionController").selected!=duel: failures.append("Teacher not selected")
	else: player.get_node("InteractionController").interact_selected()
	await get_tree().process_frame
	await capture("02_dialogo_profesor")
	await get_tree().create_timer(8).timeout
	press("ACTIVIDAD DEL DOCENTE");await get_tree().process_frame
	await get_tree().create_timer(6).timeout
	press("PRÁCTICA LOCAL");await get_tree().process_frame
	var view: Node
	for child in campaign.ui.column.get_children():
		if not child.is_queued_for_deletion() and child.get_script()!=null and child.get_script().resource_path.ends_with("learning_activity_view.gd"): view=child
	if view==null: failures.append("No question view");finish({});return
	await capture("03_pregunta_demo")
	var bank=JSON.parse_string(FileAccess.get_file_as_string("res://resources/education/capstone_practice_bank.json"))
	var q=bank.questions.filter(func(row): return row.id==view.activity.id)[0]
	await get_tree().create_timer(13).timeout
	view.find_children("*","Button",true,false)[int(q.answer)].pressed.emit()
	await get_tree().process_frame
	if int(campaign.data.academic_progress.correct)!=1: failures.append("Correct answer not recorded")
	await capture("04_respuesta_demo")
	await get_tree().create_timer(10).timeout
	press("CONTINUAR");await get_tree().process_frame
	campaign.get_node("DuocGames4").summary.show_progress()
	await capture("05_progreso_academico")
	await get_tree().create_timer(12).timeout
	finish({"duration_seconds":(Time.get_ticks_msec()-started)/1000.0,"input_movement_metres":distance,"start":str(before),"end":str(player.global_position),"teacher":str(target.global_position),"practice_answers":campaign.data.academic_progress.get("practice_answers",0),"official_mentor_pass":campaign.data.education_v4.get("mentor_passes",{}).get("profesor_datos",false)})
func finish(data: Dictionary):
	data["failures"]=failures
	data["scope"]="Isolated Main, floor 3 diagnostic start, actual input movement and interaction scanner, production question UI and progress. No login, remote verification or mission unlock claim."
	var file=FileAccess.open("res://reports/capstone/demo_test.json",FileAccess.WRITE);file.store_string(JSON.stringify(data,"\t"));file.close()
	print("CAPSTONE_DEMO_DONE ",failures.size())
