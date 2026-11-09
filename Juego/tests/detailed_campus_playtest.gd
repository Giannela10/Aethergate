extends SceneTree
## Isolated, rendered inspection session. Commands and evidence stay in reports/.
## Diagnostic relocation is logged and must never be described as walking a route.
const OUT := "res://reports/detailed_walkthrough_2026_10_26"
var campus
var campaign
var player
var camera: Camera3D
var command_id := ""
var active := false
var rooms: Array[Dictionary] = []
var history: Array[Dictionary] = []
var lamps: Array[Dictionary] = []
var geometries: Array[MeshInstance3D] = []
var heights := [-12.058385849,0.0,12.058385849,23.967668533,35.674415588,47.974849701,60.158504486,71.942184448,83.913551331]

func _initialize() -> void: boot.call_deferred()

func write_json(file: String, data: Variant) -> void:
	var stream := FileAccess.open(OUT.path_join(file),FileAccess.WRITE)
	if stream: stream.store_string(JSON.stringify(data,"\t"))

func vec(value: Vector3) -> Array: return [value.x,value.y,value.z]
func point(value: Array) -> Vector3: return Vector3(float(value[0]),float(value[1]),float(value[2]))

func boot() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DisplayServer.window_set_size(Vector2i(1152,648))
	campus = load("res://Main.tscn").instantiate()
	campaign = campus.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(campus)
	current_scene = campus
	while not campaign.ready_for_play: await process_frame
	while get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await process_frame
	campaign.ui.close_modal()
	player = campaign.player
	camera = Camera3D.new()
	camera.name = "InspectionCamera"
	camera.fov = 95
	camera.near = 0.05
	camera.far = 500
	campus.add_child(camera)
	build_inventory()
	write_json("inventory.json",{"rooms":rooms,"lights":lamps,"environment":environment_info(),"geometry_count":geometries.size()})
	write_json("ready.json",state())
	print("DETAILED_PLAYTEST_READY rooms=",rooms.size()," lights=",lamps.size())
	poll()

func environment_info() -> Array:
	var result: Array = []
	for node in campus.find_children("*","WorldEnvironment",true,false):
		var e: Environment = node.environment
		if e: result.append({"path":str(campus.get_path_to(node)),"background":e.background_mode,"ambient_source":e.ambient_light_source,"ambient_energy":e.ambient_light_energy,"ambient_color":str(e.ambient_light_color),"tonemap":e.tonemap_mode,"exposure":e.tonemap_exposure,"fog":e.fog_enabled})
	return result

func build_inventory() -> void:
	var regex := RegEx.new()
	regex.compile("^(Sala[0-9]+|[0-9]{3}|Banos.*|Baños.*|BAÑO.*|Ba[nñ]o(?:Mujeres|Hombres|Accesible).*|Capilla|Casino|Biblioteca|AuditorioPiso2e|SalaAyudaEstudiantil|SalaImpresiones|InteriorCoordinacion|SalaReuniones.*|SalaProfesores.*|SalaDocentes.*|ProfesoresCoordDocente|ED|CoworkDocente|PanolSalud|AdmisionComunicacionExtension|ContabilidadAdministracion|Cafeteria|DireccionSede|Laboratorio.*|Taller.*|LocalComida.*|SalaDetras.*|TiendaEsquina.*|Enfermeria.*|Odontologia.*|BoxClinico.*|Pabellon.*|MecanicaAutomotriz|SoldaduraYEstructurasMetalicas|MaquinariaIndustrial|NegocioCafeteria|AreaCentralEstudiantes|PasilloSalasTecnicas|NexoFinalArea|TerrazaPicnic)$")
	var tree: Array = []
	for node in campus.find_children("*","Node3D",true,false):
		var p := str(campus.get_path_to(node))
		if p.count("/") <= 3 and not node is GeometryInstance3D and not node is CollisionObject3D and not node is CollisionShape3D: tree.append({"path":p,"position":vec(node.global_position),"type":node.get_class()})
		if node is MeshInstance3D and node.mesh: geometries.append(node)
		if node is Light3D:
			var row := {"path":p,"type":node.get_class(),"position":vec(node.global_position),"energy":node.light_energy,"visible":node.is_visible_in_tree(),"shadows":node.shadow_enabled,"color":str(node.light_color),"cull_mask":node.light_cull_mask}
			if node is OmniLight3D: row["range"] = node.omni_range
			if node is SpotLight3D: row["range"] = node.spot_range
			lamps.append(row)
		if not regex.search(str(node.name)): continue
		if p.begins_with("GameplayManager") or p.begins_with("CampusCampaign"): continue
		var bounds := AABB()
		var first := true
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			if not mesh.mesh: continue
			var box: AABB = mesh.global_transform*mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		if first or bounds.size.x < 0.5 or bounds.size.z < 0.5: continue
		var floor_id := floor_number(node.global_position.y)
		if p.begins_with("PisoMenos1/"): floor_id = -1
		elif p.begins_with("Piso") and p.substr(4,1).is_valid_int(): floor_id = p.substr(4,1).to_int()
		rooms.append({"id":rooms.size(),"path":p,"name":str(node.name),"origin":vec(node.global_position),"bounds_position":vec(bounds.position),"bounds_size":vec(bounds.size),"floor":floor_id})
	write_json("tree.json",tree)

func floor_number(y: float) -> int:
	var best := 1
	var distance := INF
	for index in heights.size():
		if absf(y-heights[index]) < distance:
			distance = absf(y-heights[index]); best = index
	return -1 if best == 0 else best

func state() -> Dictionary:
	var buttons: Array = []
	for button in campus.find_children("*","Button",true,false):
		if button.is_visible_in_tree(): buttons.append({"text":button.text,"path":str(campus.get_path_to(button)),"rect":str(button.get_global_rect())})
	var duel_rows: Array = []
	for d in get_nodes_in_group("boss_duel"):
		duel_rows.append({"id":d.boss_id,"state":d.state,"hp":d.actor.get("health"),"position":vec(d.actor.global_position)})
	return {"player":vec(player.global_position),"health":player.health,"dead":player.dead,"busy":player.busy,"paused":paused,"objective":campaign.quests.objective_text(),"quests":campaign.data.quests,"bosses":campaign.data.bosses,"inventory":player.inventory.snapshot_data(),"events":campaign.events,"buttons":buttons,"duels":duel_rows,"minigame":campaign.manager.minigame.active,"selected":str(player.get_node("InteractionController").selected),"camera":vec(root.get_camera_3d().global_position)}

func poll() -> void:
	while is_instance_valid(campus):
		if FileAccess.file_exists(OUT.path_join("command.json")):
			var command = JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join("command.json")))
			if command is Dictionary and str(command.get("id","")) != command_id:
				command_id = str(command.id)
				await execute(command)
		await create_timer(0.15,true,false,true).timeout

func tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame

func capture(label: String) -> String:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var destination := OUT.path_join(label.validate_filename()+".png")
	root.get_texture().get_image().save_png(destination)
	return destination

func execute(command: Dictionary) -> void:
	var started := Time.get_ticks_msec()
	var details: Dictionary = {}
	match str(command.get("action","state")):
		"capture": details["capture"] = await capture(str(command.get("label","view")))
		"survey": await survey()
		"fresh_campaign": await fresh_campus()
		"extension":
			var task = ResourceLoader.load(str(command.get("script","res://tests/detailed_walkthrough_extension.gd")),"",ResourceLoader.CACHE_MODE_REPLACE).new()
			task.runner = self
			root.add_child(task)
			details = await task.run(command)
			task.queue_free()
		"snapshot":
			campaign.save_path = OUT.path_join("playthrough_save.json")
			campaign.persist = true
			campaign.save_game()
			campaign.persist = false
			details["saved"] = campaign.last_save_succeeded
		"relocate":
			campaign.ui.close_modal()
			player.global_position = point(command.position)
			player.velocity = Vector3.ZERO
			campaign.manager.cam_pivot = player.global_position+Vector3.UP*1.4
			await create_timer(0.25).timeout
		"look":
			camera.global_position = point(command.position)
			camera.look_at(point(command.target))
			camera.make_current()
			details["capture"] = await capture(str(command.get("label","inspection")))
		"player_camera": campaign.manager.cam.make_current()
		"walk":
			campaign.manager.cam.make_current()
			if command.has("yaw"): campaign.manager.cam_yaw = float(command.yaw)
			var origin: Vector3 = player.global_position
			Input.action_press(str(command.get("input","move_forward")))
			if command.get("run",false): Input.action_press("run")
			await create_timer(float(command.get("seconds",1))).timeout
			Input.action_release(str(command.get("input","move_forward")))
			Input.action_release("run")
			details["displacement"] = vec(player.global_position-origin)
		"route": details["route"] = await walk_route(command.points)
		"tap": await tap(str(command.input))
		"button":
			for button in campus.find_children("*","Button",true,false):
				if button.is_visible_in_tree() and button.text == str(command.text):
					button.emit_signal("pressed")
					details["button"] = str(button.text)
					break
		"wait": await create_timer(float(command.get("seconds",1))).timeout
		"quit": quit(); return
	var row := {"id":command_id,"command":command,"elapsed_ms":Time.get_ticks_msec()-started,"details":details,"state":state()}
	history.append(row)
	write_json("history.json",history)
	write_json("response.json",row)
	print("PLAYTEST_COMMAND ",command_id," ",str(command.get("action","state")))

func walk_route(points: Array) -> Array:
	var results: Array = []
	campaign.manager.cam.make_current()
	for value in points:
		var target := point(value)
		var origin: Vector3 = player.global_position
		var deadline := Time.get_ticks_msec()+int((5+origin.distance_to(target)/2.0)*1000)
		while Time.get_ticks_msec()<deadline and not player.dead and not player.busy:
			var offset: Vector3 = target-player.global_position
			offset.y = 0
			if offset.length() < 0.5: break
			campaign.manager.cam_yaw = atan2(-offset.x,-offset.z)
			Input.action_press("move_forward")
			await physics_frame
			if player.global_position.y < target.y-3: break
		Input.action_release("move_forward")
		var reached: bool = Vector2(player.global_position.x-target.x,player.global_position.z-target.z).length()<0.6 and absf(player.global_position.y-target.y)<1.0
		var blockers: Array = []
		for index in player.get_slide_collision_count(): blockers.append(str(player.get_slide_collision(index).get_collider().get_path()))
		results.append({"target":value,"origin":vec(origin),"actual":vec(player.global_position),"reached":reached,"blockers":blockers})
		if not reached: break
	return results

func ray(a: Vector3,b: Vector3) -> Dictionary:
	return player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1,[player.get_rid()]))

func fresh_campus() -> void:
	campus.queue_free()
	await process_frame
	paused = false
	campus = load("res://Main.tscn").instantiate()
	campaign = campus.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(campus)
	current_scene = campus
	while not campaign.ready_for_play: await process_frame
	while get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await process_frame
	campaign.ui.close_modal()
	player = campaign.player
	camera = Camera3D.new()
	camera.fov = 95
	camera.near = 0.05
	campus.add_child(camera)

func survey() -> void:
	var results: Array = []
	campaign.ui.close_modal()
	player.busy = true
	player.set_physics_process(false)
	campaign.manager.set_process(false)
	player.body.hide()
	# HUD can obscure geometry; only UI is hidden, never walls, roofs or lights.
	var layers: Array = campus.find_children("*","CanvasLayer",true,false)
	var layer_visibility: Array = layers.map(func(layer): return layer.visible)
	for layer in layers: layer.hide()
	for room in rooms:
		var bounds := AABB(point(room.bounds_position),point(room.bounds_size))
		var center := bounds.get_center()
		var y: float = heights[0 if int(room.floor) == -1 else int(room.floor)]
		var samples: Array = []
		var safe: Array[Vector3] = []
		for ix in range(1,6):
			for iz in range(1,6):
				var p := Vector3(lerpf(bounds.position.x,bounds.end.x,float(ix)/6),y+0.15,lerpf(bounds.position.z,bounds.end.z,float(iz)/6))
				var candidate = player.get_node("SeatController").safe_position(p)
				var ground := ray(p+Vector3.UP*1.7,p-Vector3.UP*2.0)
				var ceiling := ray(p+Vector3.UP*3,p+Vector3.UP*14)
				samples.append({"position":vec(p),"floor_hit":not ground.is_empty(),"floor_y":ground.position.y if not ground.is_empty() else null,"capsule_clear":candidate != null,"ceiling_hit":not ceiling.is_empty(),"ceiling_path":str(ceiling.collider.get_path()) if not ceiling.is_empty() else ""})
				if candidate != null: safe.append(candidate)
		var chosen: Vector3 = Vector3(center.x,y+0.12,center.z)
		if not safe.is_empty():
			safe.sort_custom(func(a,b): return a.distance_squared_to(Vector3(center.x,y,center.z)) < b.distance_squared_to(Vector3(center.x,y,center.z)))
			chosen = safe[0]
		if room.name == "AuditorioPiso2e": chosen = Vector3(56,8.8,-105)
		player.global_position = chosen
		camera.global_position = chosen+Vector3.UP*2.15
		camera.make_current()
		var views: Array = []
		var brightness: Array = []
		for direction in [Vector3.FORWARD,Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3(0,0.95,-0.25),Vector3(0,-0.95,-0.25)]:
			camera.look_at(camera.global_position+direction)
			var filename := "room_%03d_%d" % [int(room.id),views.size()]
			views.append(await capture(filename))
			var screenshot: Image = root.get_texture().get_image()
			var sum := 0.0
			var dark := 0
			var clipped := 0
			var total := 0
			for sx in range(0,screenshot.get_width(),16):
				for sy in range(0,screenshot.get_height(),16):
					var color := screenshot.get_pixel(sx,sy)
					var luminance := color.r*0.2126+color.g*0.7152+color.b*0.0722
					sum += luminance
					if luminance < 0.03: dark += 1
					if color.r > 0.98 and color.g > 0.98 and color.b > 0.98: clipped += 1
					total += 1
			brightness.append({"mean_srgb_luma":sum/total,"near_black_fraction":float(dark)/total,"white_clip_fraction":float(clipped)/total})
		var local_lights: Array = lamps.filter(func(l): return point(l.position).distance_to(chosen) < float(l.get("range",0)) and l.visible)
		results.append({"room":room,"camera_position":vec(camera.global_position),"safe_samples":safe.size(),"samples":samples,"nearby_lights":local_lights.size(),"captures":views,"screen_statistics":brightness})
		write_json("room_survey.json",results)
		print("SURVEY_ROOM ",room.id," ",room.path," safe=",safe.size())
	for index in layers.size(): layers[index].visible = layer_visibility[index]
	player.body.show()
	campaign.manager.set_process(true)
	player.set_physics_process(true)
	player.busy = false
	campaign.manager.cam.make_current()
	print("SURVEY_FINISHED ",results.size())
