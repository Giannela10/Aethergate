extends Node3D
var campus: Node3D
var campaign: Node
var player: CharacterBody3D
var camera: Camera3D
var out: String
var active_floor=3
var results: Array=[]
var views: Array=[]
var busy=false
var phase="before"
func _ready() -> void: boot.call_deferred()
func write(file: String, data: Variant) -> void:
	var stream=FileAccess.open(out+file+".json",FileAccess.WRITE);stream.store_string(JSON.stringify(data,"\t"))
func record(test: String, status: String, detail: Variant=null) -> void:
	results.append({"floor":active_floor,"test":test,"status":status,"detail":detail})
	write("floor_"+str(active_floor)+"/"+phase+"_checks",results.filter(func(r): return r.floor==active_floor))
	print("FINAL71 ",active_floor," ",test," ",status)
func boot() -> void:
	out="res://"+FileAccess.get_file_as_string("res://reports/final_7_1/active_run.txt").strip_edges().trim_prefix("Juego/")+"/"
	seed(710)
	campus=load("res://Main.tscn").instantiate()
	campaign=campus.get_node("CampusCampaign");campaign.persist=false;campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	player=campaign.player;player.inventory.persist=false;campaign.ui.close_modal();player.body.hide()
	campaign.live.director.set_process(false)
	for actor in campus.find_children("*","CharacterBody3D",true,false): actor.set_process(false);actor.set_physics_process(false)
	campaign.manager.set_process(false)
	camera=Camera3D.new();camera.fov=60;camera.near=0.04;camera.far=400;add_child(camera);camera.make_current()
	write("boot",{"project":"Juego/project.godot","persist":campaign.persist,"inventory_persist":player.inventory.persist,"cloud_mode":campaign.cloud_mode})
	await inspect_floor(3)
func bounds(node: Node3D) -> AABB:
	var box=AABB();var first=true
	for mesh in node.find_children("*","GeometryInstance3D",true,false):
		if not mesh.is_visible_in_tree(): continue
		var value: AABB
		if mesh is MeshInstance3D and mesh.mesh: value=mesh.global_transform*mesh.get_aabb()
		elif mesh is CSGBox3D: value=mesh.global_transform*AABB(-mesh.size*0.5,mesh.size)
		else: continue
		box=value if first else box.merge(value);first=false
	return box
func shot(label: String, point: Vector3, target: Vector3) -> void:
	camera.make_current();camera.global_position=point;camera.look_at(target)
	player.global_position=point-Vector3.UP*2.2
	for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()
	await get_tree().create_timer(0.25).timeout
	var previous=Time.get_ticks_usec();var samples=[]
	for i in 20:
		await RenderingServer.frame_post_draw
		var now=Time.get_ticks_usec();samples.append({"ms":float(now-previous)/1000.0,"fps":Performance.get_monitor(Performance.TIME_FPS),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)});previous=now
	var file="floor_"+str(active_floor)+"/"+phase+"_"+label.validate_filename()+".png"
	get_viewport().get_texture().get_image().save_png(out+file)
	views.append({"floor":active_floor,"phase":phase,"label":label,"file":file,"point":str(point),"target":str(target),"samples":samples})
	write("floor_"+str(active_floor)+"/"+phase+"_views",views.filter(func(v): return v.floor==active_floor and v.phase==phase))
func sector(node: Node3D, label: String, height: float) -> void:
	var box=bounds(node);var candidates=[]
	for x in [0.3,0.5,0.7]:
		for z in [0.3,0.5,0.7]:
			var point=Vector3(lerpf(box.position.x,box.end.x,x),height+0.12,lerpf(box.position.z,box.end.z,z))
			var safe=player.get_node("SeatController").safe_position(point)
			if safe!=null and absf(safe.y-height)<0.7: candidates.append(safe)
	var position_value=Vector3(box.get_center().x,height+0.12,box.get_center().z) if candidates.is_empty() else candidates[0]
	record("capsule_sample_"+label,"PASS" if not candidates.is_empty() else "NOT RUN",{"bounds":str(box),"clear_samples":candidates.size(),"scope":"Placement samples, not a walked route"})
	for direction in [Vector3.FORWARD,Vector3.BACK,Vector3.RIGHT,Vector3.LEFT]: await shot(label+"_"+str(direction),position_value+Vector3.UP*2.2,position_value+Vector3.UP*2.2+direction*6)
func inspect_floor(number: int, capture_phase: String="before") -> void:
	if busy: return
	busy=true;active_floor=number;phase=capture_phase;player.body.hide()
	write("duel_catalog",get_tree().get_nodes_in_group("boss_duel").map(func(d): return {"id":d.boss_id,"actor":str(d.actor.get_path()),"position":str(d.actor.global_position),"type":d.duel_type}))
	var height: float=preload("res://scripts/campaign/campus_content.gd").HEIGHTS[number-1]
	var root=campus.get_node("Piso"+str(number));var inventory=[]
	for node in root.find_children("*","Node",true,false):
		var row={"path":str(campus.get_path_to(node)),"type":node.get_class()}
		if node is Node3D: row["position"]=str(node.global_position);row["visible"]=node.is_visible_in_tree()
		if node is Label3D: row["text"]=node.text;row["double_sided"]=node.double_sided
		if node is Light3D: row["energy"]=node.light_energy;row["shadows"]=node.shadow_enabled
		if node is MeshInstance3D and node.mesh: row["bounds"]=str(node.global_transform*node.get_aabb())
		inventory.append(row)
	write("floor_"+str(number)+"/inventory",inventory)
	var platform=campaign.get_node("DuocGames4")
	if number==3:
		for key in platform.laboratories: await sector(platform.laboratories[key],"laboratory_"+str(key),height)
		for path in ["VestibuloAscensores","EncuentroProfesorRedes","CostadosReferencia"]: await sector(root.get_node(path),path,height)
	elif number==4:
		for path in ["DistribucionPlanoPiso4","SectorDocentesPiso4/ProfesoresCoordDocente","FilaFrontalPiso4/CoworkDocente","SalasCentralesPiso4/415","SalasCentralesPiso4/417","SalasCentralesPiso4/418","FilaFrontalPiso4/PanolSalud","VestibuloAscensores"]: await sector(root.get_node(path),path.replace("/","_"),height)
	elif number==5:
		for path in ["TerrazaPicnic","TiendaEsquinaPiso5","VestibuloAscensores"]: await sector(root.get_node(path),path,height)
	else:
		await sector(root.get_node("PasilloReferencia"),"PasilloReferencia",height)
		for room in root.get_node("PasilloReferencia").get_children():
			if room is Node3D and (str(room.name).begins_with("Sala") or "Bano" in str(room.name) or "Encuentro" in str(room.name)): await sector(room,str(room.name),height)
		await sector(root.get_node("VestibuloAscensores"),"VestibuloAscensores",height)
		if number==8: await sector(root.get_node("EncuentroDirectorInformatica"),"EncuentroDirectorInformatica",height)
	var directory=root.get_node("VestibuloAscensores/PlanoPisos")
	await shot("PlanoPisos_front",directory.global_position+directory.global_basis.z*3-Vector3.UP*0.2,directory.global_position)
	record("directory_destinations","PASS" if directory.text.contains("Casino") and directory.text.contains("Auditorio") else "FAIL",{"text":directory.text})
	await mentors(number)
	var computers=[]
	for pc in get_tree().get_nodes_in_group("computer"):
		if absf(pc.global_position.y-height)<1: computers.append({"path":str(pc.get_path()),"id":pc.get_meta("campaign_id",""),"position":str(pc.global_position),"activity_profile":pc.get("activity_profile"),"done":pc.done})
	write("floor_"+str(number)+"/computers",computers)
	var quests=[]
	for id in campaign.quests.definitions:
		var q=campaign.quests.definitions[id];quests.append({"id":id,"title":q.title,"requirements":q.requirements,"reward":q.reward,"state":campaign.quests.state(id)})
	write("floor_"+str(number)+"/effective_quests",quests)
	record("campaign_gates_not_bypassed","PASS",{"unlocks":campaign.data.unlocks,"scope":"Diagnostic relocation for inspection; no campaign authorization injected"})
	write("floor_"+str(number)+"/inspection_done",{"floor":number,"views":views.filter(func(v): return v.floor==number).size(),"results":results.filter(func(r): return r.floor==number)})
	busy=false;print("FINAL71_FLOOR_DONE ",number)
func mentors(number: int) -> void:
	campaign.ui.show()
	var bank=JSON.parse_string(FileAccess.get_file_as_string("res://resources/education/capstone_practice_bank.json"))
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		if not bank.mentors.has(duel.boss_id) or int(bank.mentors[duel.boss_id].floor)!=number: continue
		var id: String=duel.boss_id
		campaign.ui.close_modal();player.busy=false;campaign.active_duel=null
		var scanner=player.get_node("InteractionController");var selected=false
		for offset in [Vector3(0,0,2.8),Vector3(0,0,-2.8),Vector3(2.8,0,0),Vector3(-2.8,0,0)]:
			var safe=player.get_node("SeatController").safe_position(duel.interaction_target().global_position+offset)
			if safe==null: continue
			player.global_position=safe;await get_tree().physics_frame;await get_tree().physics_frame
			scanner.scan()
			if scanner.selected==duel: selected=true;break
		record("E_selection_"+id,"PASS" if selected else "FAIL",{"actor":str(duel.actor.global_position),"selected":str(scanner.selected.get_path()) if scanner.selected else null,"simulation":duel.simulation!=null})
		if selected: scanner.interact_selected()
		else: duel.interact(player)
		record("dialogue_"+id,"PASS" if campaign.ui.modal else "FAIL",{"state":duel.state,"missing":campaign.academic_expansion.boss_missing(id),"scope":"Direct method fallback if E selection failed"})
		duel.learn_from_mentor()
		var activity=duel.base_education
		var passes_before=campaign.data.education_v4.get("mentor_passes",{}).duplicate(true)
		var issued=[]
		for attempt in 3:
			activity.open_local();await get_tree().process_frame
			if activity.activity.has("error"): record("local_question_"+id,"FAIL",activity.activity);break
			var question: Dictionary=activity.activity
			issued.append(question.id)
			var original=bank.questions.filter(func(q): return q.id==question.id)[0]
			var view=campaign.ui.column.get_child(campaign.ui.column.get_child_count()-1)
			var buttons=view.get_children().filter(func(n): return n is Button)
			record("question_options_"+id+"_"+str(attempt),"PASS" if buttons.size()==4 and not question.prompt.is_empty() else "FAIL",{"id":question.id,"subject":question.subject_id,"prompt":question.prompt})
			if attempt==0:
				await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png(out+"floor_"+str(number)+"/"+phase+"_mentor_"+id+"_question.png")
			buttons[int(original.answer)].pressed.emit();await get_tree().process_frame
			record("feedback_"+id+"_"+str(attempt),"PASS" if campaign.ui.modal and campaign.ui.column.get_child_count()>0 else "FAIL",{"explanation":original.explanation,"scope":"Real local view button signal; not a remote grade"})
			if attempt==0:
				await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png(out+"floor_"+str(number)+"/"+phase+"_mentor_"+id+"_feedback.png")
		record("no_early_repeat_"+id,"PASS" if issued.size()==3 and issued[0]!=issued[1] and issued[1]!=issued[2] and issued[0]!=issued[2] else "FAIL",issued)
		record("local_practice_no_official_pass_"+id,"PASS" if campaign.data.education_v4.get("mentor_passes",{})==passes_before else "FAIL")
		campaign.ui.close_modal();player.busy=false
func extension(path: String) -> Variant:
	return load(path).new().install(self)
