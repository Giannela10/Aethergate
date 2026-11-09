extends Node
## Isolated visual inspection: no personal saves, no production state changes.
const OUT := "res://reports/visual_5"
var campus: Node
var campaign: Node
var camera: Camera3D
var ready_for_inspection := false
var phase := "before"
var results: Array = []

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	campus = load("res://Main.tscn").instantiate()
	campaign = campus.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	campaign.ui.close_modal()
	campaign.player.set_physics_process(false)
	campaign.player.body.hide()
	campaign.manager.set_process(false)
	for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()
	camera = Camera3D.new()
	camera.fov = 85
	camera.near = 0.05
	camera.far = 600
	add_child(camera)
	camera.make_current()
	ready_for_inspection = true
	if FileAccess.file_exists(OUT.path_join("phase.txt")):
		phase = FileAccess.get_file_as_string(OUT.path_join("phase.txt")).strip_edges()
	if FileAccess.file_exists(OUT.path_join(phase+"_views.json")):
		var previous_results = JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join(phase+"_views.json")))
		if previous_results is Array: results = previous_results
	inventory()
	print("VISUAL_5_READY")

func write_json(file: String, value: Variant) -> void:
	var stream := FileAccess.open(OUT.path_join(file),FileAccess.WRITE)
	if stream: stream.store_string(JSON.stringify(value,"\t"))

func inventory() -> void:
	var lights: Array = []
	var signs: Array = []
	for n in campus.find_children("*","Node3D",true,false):
		if n is Light3D:
			lights.append({"path":str(campus.get_path_to(n)),"position":str(n.global_position),"energy":n.light_energy,"color":str(n.light_color),"shadows":n.shadow_enabled,"visible":n.is_visible_in_tree(),"range":n.omni_range if n is OmniLight3D else n.spot_range if n is SpotLight3D else 0})
		if n is Label3D:
			signs.append({"path":str(campus.get_path_to(n)),"position":str(n.global_position),"text":n.text,"pixel_size":n.pixel_size,"no_depth_test":n.no_depth_test,"billboard":n.billboard})
	write_json(phase+"_inventory.json",{"lights":lights,"signs":signs,"persist":campaign.persist,"test_mode":campaign.has_meta("test_mode")})

func view(label: String, position: Vector3, target: Vector3) -> void:
	camera.global_position = position
	camera.look_at(target)
	campaign.player.global_position = position-Vector3.UP*2
	await get_tree().create_timer(0.6).timeout
	var samples: Array = []
	for i in 30:
		await get_tree().process_frame
		samples.append({"fps":Performance.get_monitor(Performance.TIME_FPS),"frame_ms":get_process_delta_time()*1000,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	await RenderingServer.frame_post_draw
	var file := OUT.path_join(phase+"_"+label.validate_filename()+".png")
	get_viewport().get_texture().get_image().save_png(file)
	results.append({"label":label,"capture":file,"camera":str(position),"target":str(target),"samples":samples})
	write_json(phase+"_views.json",results)
	print("VISUAL_5_CAPTURE ",label)

func survey() -> void:
	results.clear()
	var previous = JSON.parse_string(FileAccess.get_file_as_string("res://reports/detailed_walkthrough_2026_10_26/room_survey.json"))
	for row in previous:
		var p: Array = row.camera_position
		var at := Vector3(float(p[0]),float(p[1]),float(p[2]))
		var label := "floor_%s_room_%03d" % [str(row.room.floor),int(row.room.id)]
		await view(label+"_north",at,at+Vector3.FORWARD*10)
		await view(label+"_south",at,at+Vector3.BACK*10)
	await view("exterior_front",Vector3(15,8,-210),Vector3(0,18,-140))
	await view("exterior_side",Vector3(115,15,-100),Vector3(30,25,-90))
	print("VISUAL_5_SURVEY_DONE ",results.size())

func trial_lights() -> void:
	phase = "candidate_lights"
	for floor_id in range(1,9):
		for side in ["Norte","Sur"]:
			var n = campus.get_node_or_null("Piso%d/Iluminacion/Luz%s" % [floor_id,side])
			if n: n.hide()
	inventory()
	await selected_views()

func selected_views() -> void:
	results.clear()
	var previous = JSON.parse_string(FileAccess.get_file_as_string("res://reports/detailed_walkthrough_2026_10_26/room_survey.json"))
	for row in previous:
		if not int(row.room.id) in [0,1,3,7,11,20,28,39,41,49,57,66,68]: continue
		var p: Array = row.camera_position
		var at := Vector3(float(p[0]),float(p[1]),float(p[2]))
		var label := "floor_%s_room_%03d" % [str(row.room.floor),int(row.room.id)]
		await view(label+"_north",at,at+Vector3.FORWARD*10)
		await view(label+"_south",at,at+Vector3.BACK*10)
	print("VISUAL_5_SELECTED_DONE")

func details(paths: Array) -> void:
	var rows: Array = []
	for path in paths:
		var n = campus.get_node_or_null(str(path))
		if not n: continue
		var row := {"path":str(path),"position":str(n.position),"global_position":str(n.global_position),"rotation":str(n.rotation),"scale":str(n.scale),"children":n.get_children().map(func(c): return str(c.name))}
		if n is GeometryInstance3D:
			row["material_override"] = str(n.material_override)
			if n.material_override: row["material_path"] = n.material_override.resource_path
		if n is Label3D: row["text"] = n.text
		rows.append(row)
	write_json("details.json",rows)
