extends Node
## Diagnostic cameras only. Never write a personal save or trigger interactions.
const OUT := "res://reports/visual_5_1"
var campus: Node3D
var campaign: Node
var camera: Camera3D
var phase := "before"
var results: Array = []
var audit_ready := false
var view_index := 0
var extra_mode := false

func _ready() -> void:
	seed(510)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if FileAccess.file_exists(OUT.path_join("phase.txt")):
		phase = FileAccess.get_file_as_string(OUT.path_join("phase.txt")).strip_edges()
	extra_mode = FileAccess.file_exists(OUT.path_join("extra_mode.txt")) and FileAccess.get_file_as_string(OUT.path_join("extra_mode.txt")).strip_edges()=="true"
	campus = load("res://Main.tscn").instantiate()
	campaign = campus.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	campaign.ui.close_modal()
	# Freeze actors identically for paired views; leave sector/LOD scripts active.
	for actor in campus.find_children("*","CharacterBody3D",true,false):
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	campaign.player.body.hide()
	campaign.manager.set_process(false)
	for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()
	camera = Camera3D.new()
	camera.fov = campaign.manager.cam.fov
	camera.near = 0.05
	camera.far = 600
	add_child(camera)
	camera.make_current()
	inventory()
	audit_ready = true
	print("VISUAL_5_1_READY phase=",phase," fov=",camera.fov)
	if extra_mode: run_extra.call_deferred()
	else: run_audit.call_deferred()

func write_json(file: String, value: Variant) -> void:
	var stream := FileAccess.open(OUT.path_join(file),FileAccess.WRITE)
	if stream: stream.store_string(JSON.stringify(value,"\t"))

func v(p: Vector3) -> Array: return [p.x,p.y,p.z]

func inventory() -> void:
	var rows: Array = []
	for n in campus.find_children("*","Light3D",true,false):
		rows.append({"path":str(campus.get_path_to(n)),"position":v(n.global_position),"energy":n.light_energy,"color":str(n.light_color),"visible":n.is_visible_in_tree(),"shadows":n.shadow_enabled,"range":n.omni_range if n is OmniLight3D else n.spot_range if n is SpotLight3D else 0})
	var labels: Array = []
	for n in campus.find_children("*","Label3D",true,false):
		if "LetreroEntrada" in str(n.name) or n.name == "PlanoPisos":
			labels.append({"path":str(campus.get_path_to(n)),"position":v(n.global_position),"text":n.text,"visible":n.is_visible_in_tree(),"double_sided":n.double_sided,"pixel_size":n.pixel_size,"font_size":n.font_size})
	var mesh = campus.get_node("Exterior/EntradaReferenciaDuoc/CelosiaMetalica/VarillasCelosia")
	write_json(phase+"_inventory.json",{"lights":rows,"labels":labels,"persist":campaign.persist,"test_mode":campaign.has_meta("test_mode"),"fov":camera.fov,"resolution":str(get_viewport().size),"screen_space_aa":get_viewport().screen_space_aa,"lattice_transform":str(mesh.global_transform),"lattice_bounds":str(mesh.get_aabb())})

func capture(label: String, at: Vector3, target: Vector3, profile := false, note := "") -> void:
	camera.global_position = at
	camera.look_at(target)
	campaign.player.global_position = at-Vector3.UP*2.2
	await get_tree().create_timer(1.5 if profile else 0.18).timeout
	var samples: Array = []
	var previous := Time.get_ticks_usec()
	for i in (90 if profile else 3):
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		if profile:
			samples.append({"frame_ms":float(now-previous)/1000.0,"engine_fps":Performance.get_monitor(Performance.TIME_FPS),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		previous = now
	var image := get_viewport().get_texture().get_image()
	var filename := phase+"_"+label.validate_filename()+".png"
	image.save_png(OUT.path_join(filename))
	var ground := campus.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at,at-Vector3.UP*4,1,[campaign.player.get_rid()]))
	results.append({"label":label,"capture":filename,"camera":v(at),"target":v(target),"profile":profile,"note":note,"ground_y":ground.position.y if not ground.is_empty() else null,"samples":samples})
	write_json(phase+("_extra_views.json" if extra_mode else "_views.json"),results)
	view_index += 1
	print("VISUAL_5_1_CAPTURE ",view_index," ",label)

func room_bounds(node: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for mesh in node.find_children("*","GeometryInstance3D",true,false):
		if mesh is Label3D: continue
		var box: AABB
		if mesh is MeshInstance3D and mesh.mesh: box = mesh.global_transform*mesh.get_aabb()
		elif mesh is CSGBox3D: box = mesh.global_transform*AABB(-mesh.size*0.5,mesh.size)
		else: continue
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds

func sector(path: String, floor_y: float, profile := false) -> void:
	var node = campus.get_node_or_null(path)
	if not node:
		results.append({"label":path,"missing":true})
		write_json(phase+"_views.json",results)
		return
	var bounds := room_bounds(node)
	var center := bounds.get_center()
	var point := Vector3(center.x,floor_y+0.12,center.z)
	var candidates: Array[Vector3] = []
	for x in [0.3,0.5,0.7]:
		for z in [0.3,0.5,0.7]:
			var p := Vector3(lerpf(bounds.position.x,bounds.end.x,x),floor_y+0.12,lerpf(bounds.position.z,bounds.end.z,z))
			var safe = campaign.player.get_node("SeatController").safe_position(p)
			if safe != null: candidates.append(safe)
	var note := "No capsule-clear sample; diagnostic camera only" if candidates.is_empty() else "Capsule-clear eye-height sample; not a walked campaign route"
	if not candidates.is_empty():
		candidates.sort_custom(func(a,b): return a.distance_squared_to(point)<b.distance_squared_to(point))
		point = candidates[0]
	var at := point+Vector3.UP*2.2
	var label := path.replace("/","_")
	for item in [["east",Vector3.RIGHT],["west",Vector3.LEFT],["upper",Vector3(0,0.75,-1)]]:
		await capture(label+"_"+item[0],at,at+item[1]*8,profile and item[0]=="east",note)
	# A second station reveals furniture backs rather than only rotating in place.
	if candidates.size()>1:
		var rear: Vector3 = candidates[-1]+Vector3.UP*2.2
		await capture(label+"_return",rear,at,false,note)

func sign_views() -> void:
	for group in ["EntradasAuditorio","AuditorioAmpliado"]:
		for suffix in ["-118_5","-90_5"]:
			var node = campus.get_node("Piso2/AuditorioPiso2e/"+group+"/LetreroEntrada"+suffix)
			for side in [1,-1]:
				var at: Vector3 = node.global_position+node.global_basis.z*4*side-Vector3.UP*1.15
				await capture("auditorio_"+group+suffix+("_front" if side==1 else "_back"),at,node.global_position)
	for f in range(2,9):
		var label = campus.get_node("Piso%d/VestibuloAscensores/PlanoPisos" % f)
		for distance in [2.0,4.0]:
			var at: Vector3 = label.global_position+label.global_basis.z*distance-Vector3.UP*0.1
			await capture("directory_%d_%dm" % [f,int(distance)],at,label.global_position)

func lattice_views() -> void:
	for item in [["near",Vector3(0,2.2,-60)],["medium",Vector3(0,2.2,-30)],["far",Vector3(0,2.2,25)]]:
		await capture("lattice_"+item[0],item[1],Vector3(0,27,-75.4),true)
	for x in [-12,-6,0,6,12]:
		await capture("lattice_motion_"+str(x),Vector3(x,2.2,25),Vector3(0,27,-75.4))
	if phase == "before":
		var original_aa := get_viewport().screen_space_aa
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		await capture("lattice_trial_fxaa",Vector3(0,2.2,25),Vector3(0,27,-75.4),true,"Runtime-only trial; original AA restored immediately afterwards")
		get_viewport().screen_space_aa = original_aa

func run_audit() -> void:
	await sign_views()
	await lattice_views()
	var old = JSON.parse_string(FileAccess.get_file_as_string("res://reports/detailed_walkthrough_2026_10_26/room_survey.json"))
	for row in old:
		if not int(row.room.id) in [0,1,3,7,11,12,13,18,28,36,37,38,39,40,41,46,49,54,57,62,66,67,68,69,70,71]: continue
		var floor_id := int(row.room.floor)
		var heights := {-1:-12.058385849,1:0.0,2:12.058385849,3:23.967668533,4:35.674415588,5:47.974849701,6:60.158504486,7:71.942184448,8:83.913551331}
		await sector(str(row.room.path),heights[floor_id],int(row.room.id) in [7,11,28,41,49,57])
	for i in range(1,7): await sector("Piso2/Biblioteca/SalasEstudio/SalaEstudio"+str(i),12.058385849,i==1)
	for f in [6,7,8]:
		var h: float = {6:60.158504486,7:71.942184448,8:83.913551331}[f]
		await sector("Piso%d/PasilloReferencia/ZonaEncuentroDuoc" % f,h)
		await sector("Piso%d/PasilloReferencia/SalaEstudioExtremoSur" % f,h)
	# Exact late-game locations are observed without activating NPCs or computers.
	await sector("Piso8/EncuentroDirectorInformatica",83.913551331)
	for node in campus.find_children("*","Node3D",true,false):
		if str(node.name) not in ["pc8"]: continue
		await capture("mission_computer_"+str(node.name),node.global_position+Vector3(2,2.2,2),node.global_position+Vector3.UP)
	await capture("ramp_lower",Vector3(24.37,-9.8,-124),Vector3(24.37,-6,-144))
	await capture("ramp_middle",Vector3(24.37,-4.5,-143),Vector3(24.37,0,-163))
	await capture("ramp_exit",Vector3(24.37,2.2,-166),Vector3(24.37,-5,-143))
	await sector("Exterior/PatioPosteriorDuoc",0)
	await sector("Exterior/EstructuraYAccesoPosterior/EntradaPosteriorEstacionamientos",0)
	await capture("exterior_west",Vector3(-110,2.2,-100),Vector3(-80,15,-100),true)
	await capture("exterior_east",Vector3(110,2.2,-100),Vector3(80,15,-100),true)
	await capture("entrance_student",Vector3(0,2.2,-45),Vector3(0,5,-75))
	await extra_views()
	await motion_pan()
	write_json(phase+"_done.json",{"captures":view_index,"phase":phase,"profile":"same seeded scene, actors frozen, production LOD scripts retained, actual student camera FOV; diagnostic relocation only"})
	print("VISUAL_5_1_DONE ",phase," captures=",view_index)

func extra_views() -> void:
	var pc = campus.get_node("CampusCampaign/pc8")
	await capture("pc8_close",pc.global_position+Vector3(2,2.2,2),pc.global_position+Vector3(0,1,0))
	var details: Array = []
	for name_value in ["418","417","415"]:
		var path: String = "Piso4/SalasCentralesPiso4/"+str(name_value)
		var room = campus.get_node(path)
		var door = room.get_node_or_null("Puerta")
		details.append({"path":path,"global_position":v(room.global_position),"bounds":str(room_bounds(room)),"door_position":v(door.global_position) if door else null})
		if door:
			var origin: Vector3 = door.global_position+Vector3.UP*2.2
			await capture("central_"+name_value+"_hall",origin+door.global_basis.z*2,origin-door.global_basis.z*4,false,"Door-relative student-height view, no architectural modification")
			await capture("central_"+name_value+"_interior",origin-door.global_basis.z*2,origin+Vector3(0,5,-4),false,"Compare actual node elevation with upper atrium photographs before changing any wall")
	write_json(phase+"_central_geometry.json",details)
	# Readable approach along the actual public side of the upper lobby wall.
	for f in range(5,9):
		var h: float = {5:47.974849701,6:60.158504486,7:71.942184448,8:83.913551331}[f]
		await capture("directory_public_%d" % f,Vector3(-16,h+2.2,-143),Vector3(-20,h+2.3,-143))

func motion_pan() -> void:
	var start := Time.get_ticks_msec()
	var frames := 0
	var sequence: Array = []
	while Time.get_ticks_msec()-start < 3500:
		var elapsed := float(Time.get_ticks_msec()-start)/3500.0
		camera.global_position = Vector3(lerpf(-12,12,elapsed),2.2,25)
		camera.look_at(Vector3(0,27,-75.4))
		await RenderingServer.frame_post_draw
		if frames%10==0:
			var file := phase+"_continuous_lattice_%04d.png" % frames
			get_viewport().get_texture().get_image().save_png(OUT.path_join(file))
			sequence.append({"frame":frames,"capture":file,"elapsed_ms":Time.get_ticks_msec()-start,"camera":v(camera.global_position)})
		frames += 1
	write_json(phase+"_motion.json",sequence)

func run_extra() -> void:
	await extra_views()
	await motion_pan()
	write_json(phase+"_extra_done.json",{"captures":view_index,"motion":true})
	print("VISUAL_5_1_EXTRA_DONE")
