extends Node3D
## Isolated production scene. No account login, remote question publishing or real saves.
var campus: Node3D
var campaign: Node
var player: CharacterBody3D
var camera: Camera3D
var out: String
var rows: Array=[]
var views: Array=[]
var phase := "survey"
func _ready() -> void: run.call_deferred()
func write(label: String, value: Variant) -> void:
	var f=FileAccess.open(out+label+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(value,"\t"))
func record(label: String, passed: bool, detail: Variant=null) -> void:
	rows.append({"test":label,"passed":passed,"detail":detail})
	write(phase+"_checks",rows)
	print("FINAL70_CHECK ",label," ",passed)
func run() -> void:
	out="res://"+FileAccess.get_file_as_string("res://reports/final_7_0/active_run.txt").strip_edges().trim_prefix("Juego/")+"/"
	if FileAccess.file_exists(out+"campus_phase.txt"): phase=FileAccess.get_file_as_string(out+"campus_phase.txt").strip_edges()
	seed(700)
	campus=load("res://Main.tscn").instantiate()
	campaign=campus.get_node("CampusCampaign")
	campaign.persist=false;campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	player=campaign.player
	player.inventory.persist=false
	campaign.ui.close_modal()
	campaign.live.director.set_process(false)
	for actor in campus.find_children("*","CharacterBody3D",true,false):
		actor.set_process(false);actor.set_physics_process(false)
	campaign.manager.set_process(false)
	camera=Camera3D.new();camera.fov=70;camera.near=0.05;camera.far=400;add_child(camera)
	if phase=="followup":
		camera.make_current()
		preload("res://tests/final_probe_7_0.gd").new().install(self)
		return
	await gameplay()
	player.set_process(false);player.set_physics_process(false)
	player.body.hide();camera.make_current()
	for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()
	for floor_name in ["PisoMenos1","Piso1","Piso2"]:
		await survey_floor(floor_name)
		if floor_name=="PisoMenos1": await basement_checks()
		if floor_name=="Piso1": await first_mission()
		if floor_name=="Piso2": await library_checks()
	write(phase+"_done",{"checks":rows.size(),"views":views.size(),"failures":rows.filter(func(r): return not r.passed),"scope":"Sector cameras and capsule samples; not exhaustive instance approval. Mission victories injected only inside isolated fixture."})
	print("FINAL70_CAMPUS_DONE")
func gameplay() -> void:
	player.global_position=Vector3(4,0.14,-48);player.velocity=Vector3.ZERO;player.busy=false
	player.set_process(true);player.set_physics_process(true)
	campaign.manager.set_process(true);campaign.manager.cam.make_current()
	await get_tree().create_timer(0.5).timeout
	for mode in ["walk","run","lateral","backward","jump","crouch","attack","turn"]:
		var start=player.global_position
		if mode in ["walk","run"]: Input.action_press("move_forward")
		if mode=="run": Input.action_press("run")
		if mode=="lateral": Input.action_press("move_right")
		if mode=="backward": Input.action_press("move_back")
		if mode=="jump": Input.action_press("jump")
		if mode=="crouch": Input.action_press("crouch")
		if mode=="attack": Input.action_press("punch")
		if mode=="turn": player.cam_yaw+=PI*0.5
		var samples=[]
		for frame in 12:
			await get_tree().create_timer(0.15).timeout
			samples.append({"position":str(player.global_position),"state":player.body.visual_state,"ground":player.is_on_floor(),"camera":str(campaign.manager.cam.global_position),"finite":player.body.weapon_socket.global_transform.is_finite()})
			if frame in [2,5,8]:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(out+phase+"_game_"+mode+"_"+str(frame)+".png")
		for action in ["move_forward","run","move_right","move_back","jump","crouch","punch"]: Input.action_release(action)
		record("game_"+mode,player.global_position.is_finite() and samples.all(func(s): return s.finite),{"displacement":player.global_position.distance_to(start),"samples":samples,"note":"Finite motion/socket check; inspect captures for visual approval"})
		await get_tree().create_timer(0.35).timeout
	record("capsule_preserved",is_equal_approx(player.standing_capsule.height,2.7) and is_equal_approx(player.standing_capsule.radius,0.45))
	record("save_isolation",not campaign.persist and not player.inventory.persist and not campaign.cloud_mode)
	campaign.manager.set_process(false)
func bounds(node: Node3D) -> AABB:
	var result=AABB();var first=true
	for n in node.find_children("*","GeometryInstance3D",true,false):
		var box: AABB
		if n is MeshInstance3D and n.mesh: box=n.global_transform*n.get_aabb()
		elif n is CSGBox3D: box=n.global_transform*AABB(-n.size*0.5,n.size)
		else: continue
		result=box if first else result.merge(box);first=false
	return result
func shot(label: String, at: Vector3, target: Vector3) -> void:
	camera.global_position=at;camera.look_at(target)
	player.global_position=at-Vector3.UP*2.2
	await get_tree().create_timer(0.2).timeout
	var metrics=[];var previous=Time.get_ticks_usec()
	for i in 12:
		await RenderingServer.frame_post_draw
		var now=Time.get_ticks_usec()
		metrics.append({"ms":float(now-previous)/1000.0,"fps":Performance.get_monitor(Performance.TIME_FPS),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		previous=now
	var file=phase+"_"+label.validate_filename()+".png"
	get_viewport().get_texture().get_image().save_png(out+file)
	views.append({"label":label,"file":file,"at":str(at),"target":str(target),"samples":metrics})
	write(phase+"_views",views)
func sector(path: String, height: float) -> void:
	var node=campus.get_node_or_null(path)
	if node==null: record("sector_exists_"+path,false);return
	var box=bounds(node);var center=box.get_center();var candidates=[]
	for x in [0.25,0.5,0.75]:
		for z in [0.25,0.5,0.75]:
			var at=Vector3(lerpf(box.position.x,box.end.x,x),height+0.12,lerpf(box.position.z,box.end.z,z))
			var safe=player.get_node("SeatController").safe_position(at)
			if safe!=null: candidates.append(safe)
	var point=Vector3(center.x,height+0.12,center.z) if candidates.is_empty() else candidates[0]
	record("capsule_sample_"+path,not candidates.is_empty(),{"bounds":str(box),"clear_samples":candidates.size(),"note":"Capsule placement samples, not a complete walked route"})
	for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
		await shot(path.replace("/","_")+"_"+str(direction),point+Vector3.UP*2.2,point+Vector3.UP*2.2+direction*8)
func survey_floor(floor_name: String) -> void:
	var floor_node=campus.get_node(floor_name)
	var inventory=[]
	for n in floor_node.find_children("*","Node",true,false):
		var row={"path":str(campus.get_path_to(n)),"type":n.get_class()}
		if n is Node3D: row["position"]=str(n.global_position);row["visible"]=n.is_visible_in_tree()
		if n is Light3D:
			row["energy"]=n.light_energy;row["shadows"]=n.shadow_enabled
			if n is OmniLight3D: row["range"]=n.omni_range
		if n is Label3D: row["text"]=n.text;row["double_sided"]=n.double_sided;row["basis"]=str(n.global_basis)
		if n is CollisionShape3D: row["disabled"]=n.disabled
		if n.get_script()!=null: row["script"]=n.get_script().resource_path
		inventory.append(row)
	write(phase+"_"+floor_name+"_inventory",inventory)
	if floor_name=="PisoMenos1":
		for sector_name in ["MecanicaAutomotriz","SoldaduraYEstructurasMetalicas","MaquinariaIndustrial","AreaCentralEstudiantes","NegocioCafeteria","PasilloSalasTecnicas","RampaVehicularExterior"]:
			await sector(floor_name+"/AmbientacionIndustrial2026/"+sector_name,-12.058385849)
		await shot("ramp_lower",Vector3(24.37,-9.8,-124),Vector3(24.37,-6,-144))
		await shot("ramp_exit",Vector3(24.37,2.2,-166),Vector3(24.37,-5,-143))
	elif floor_name=="Piso1":
		for sector_name in ["SalaAyudaEstudiantil","Casino","InteriorCoordinacion","PasilloDerechoYCapilla","VestibuloAscensores","AcabadosPasillos"]: await sector(floor_name+"/"+sector_name,0)
	else:
		for sector_name in ["Biblioteca","SalaImpresiones","AuditorioPiso2e","VestibuloAscensores","AcabadosPasillos"]: await sector(floor_name+"/"+sector_name,12.058385849)
		for i in range(1,7): await sector("Piso2/Biblioteca/SalasEstudio/SalaEstudio"+str(i),12.058385849)
		for group in ["EntradasAuditorio","AuditorioAmpliado"]:
			for suffix in ["-118_5","-90_5"]:
				var label=campus.get_node("Piso2/AuditorioPiso2e/"+group+"/LetreroEntrada"+suffix)
				for side in [1,-1]: await shot(group+suffix+"_side_"+str(side),label.global_position+label.global_basis.z*4*side-Vector3.UP*1.0,label.global_position)
func basement_checks() -> void:
	record("basement_campaign_locked",not campaign.floor_unlocked("S"))
	var lift=campus.get_node("SistemasCompartidos/AscensoresEstudiantiles").get_child(0)
	lift.request_floor(8)
	record("basement_lift_respects_campaign",not lift.moving)
	var area=campaign.final_area
	record("nexo_area_preserved",area!=null,{"path":str(area.get_path()) if area else "missing","note":"No final unlock injected; end encounter remains pending"})
func first_mission() -> void:
	var punto=campus.get_node("Piso1/SalaAyudaEstudiantil/BossAyudaEstudiantil/BossDuelController")
	record("first_day_initial_active",campaign.quests.state("inicio")==1)
	player.global_position=punto.interaction_target().global_position+Vector3(0,0,1.6)
	await get_tree().physics_frame
	var interaction=player.get_node("InteractionController")
	interaction.scan()
	if interaction.selected!=punto:
		for offset in [Vector3(0,0,-2.5),Vector3(-2.5,0,0),Vector3(2.5,0,0),Vector3(0,0,3)]:
			player.global_position=punto.interaction_target().global_position+offset
			await get_tree().physics_frame
			interaction.scan()
			if interaction.selected==punto: break
	record("punto_scanner",interaction.selected==punto,{"position":str(player.global_position),"selected":str(interaction.selected.get_path()) if interaction.selected else null})
	interaction.interact_selected();record("punto_dialogue",punto.state==punto.DuelState.DIALOGUE)
	punto.decline();record("punto_talk_objective",campaign.events.get("talk:punto",0)>=1)
	var item=campaign.get_node("Arma_00")
	player.global_position=item.global_position+Vector3(0.7,0,0);await get_tree().physics_frame;item.interact(player)
	record("first_collect_objective",campaign.quests.progress({"kind":"collect","id":"*","amount":1})==1)
	var pc=campaign.get_node("pc_intro")
	player.global_position=pc.global_position+Vector3(0,0,1.6);await get_tree().physics_frame
	interaction.scan();record("intro_pc_scanner",interaction.selected==pc)
	interaction.interact_selected();record("intro_pc_started",campaign.manager.current_computer==pc)
	campaign.manager.minigame.close(true)
	record("intro_pc_objective",campaign.data.computers.get("pc_intro",false))
	for duel in [punto,campus.get_node("Piso1/Casino/ChefSupremoCasino/BossDuelController")]:
		player.global_position=duel.interaction_target().global_position+Vector3(1.6,0,0)
		duel.interact(player);await duel.accept()
		await get_tree().create_timer(duel.intro_duration+0.4).timeout
		record("simulation_"+duel.boss_id,duel.state==duel.DuelState.COMBAT and duel.simulation!=null and duel.simulation.mentor.visible and duel.simulation.hologram.visible)
		# Exercise defeat/reward plumbing only. This is not a normal combat win.
		duel.actor.take_hit(Vector3.ZERO,10000)
		await get_tree().process_frame
	record("first_day_completed_fixture",campaign.quests.state("inicio")==2)
	record("floor2_unlocked_by_quest",campaign.floor_unlocked("2") and campaign.quests.state("biblioteca")==1)
	var credits=campaign.data.credits;var xp=campaign.data.xp
	for i in 3: campaign.quests.refresh()
	record("first_day_no_duplicate_reward",credits==campaign.data.credits and xp==campaign.data.xp)
	await lift_trip(1,"one_to_two")
	await lift_trip(0,"two_to_one")
	await lift_trip(1,"one_to_two_again")
func lift_trip(index: int, label: String) -> void:
	var lift=campus.get_node("SistemasCompartidos/AscensoresEstudiantiles").get_child(0)
	player.global_position=lift.cabin.global_position+Vector3(0,0.15,0);player.velocity=Vector3.ZERO;player.busy=false
	player.set_process(true);player.set_physics_process(true)
	await get_tree().create_timer(0.5).timeout
	lift.request_floor(index);var accepted=lift.moving;var elapsed=0.0
	while lift.moving and elapsed<12:
		await get_tree().create_timer(0.25).timeout;elapsed+=0.25
	record("lift_"+label,accepted and lift.current_floor==index and not lift.moving,{"position":str(player.global_position),"cabin":str(lift.cabin.global_position),"floor":campaign.floor_current,"note":"Real platform ride; diagnostic relocation into cabin"})
	player.set_process(false);player.set_physics_process(false)
func library_checks() -> void:
	record("floor3_still_locked_before_library",not campaign.floor_unlocked("3"))
	var librarian=campus.get_node("Piso2/Biblioteca/BossBibliotecaria")
	write(phase+"_librarian_methods",librarian.get_method_list().map(func(m): return m.name))
	record("librarian_present",is_instance_valid(librarian),{"script":librarian.get_script().resource_path,"note":"Question UI and progression checked separately; presence alone is not approval"})
func start_extras() -> String:
	return load("res://tests/final_extras_7_0.gd").new().install(self)
func start_regressions() -> String:
	return load("res://tests/final_regressions_7_0.gd").new().install(self)
func start_ramp_diagnostic() -> String:
	return load("res://tests/final_ramp_7_0.gd").new().install(self)
