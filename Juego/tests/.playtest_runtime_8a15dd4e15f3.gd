extends Node
## Inspection helpers use live collision, input and UI handlers; never grant wins.
var runner
var actions: Array = []

func run(command: Dictionary) -> Dictionary:
	match str(command.get("mode","geometry")):
		"geometry": return audit_geometry()
		"inspect":
			var node = runner.campus.get_node(NodePath(str(command.path)))
			var result := {"path":str(command.path),"type":node.get_class(),"position":runner.vec(node.global_position),"scale":runner.vec(node.global_basis.get_scale()),"children":node.get_children().map(func(c): return str(c.name))}
			if node is CSGBox3D: result["size"]=runner.vec(node.size)
			if node is MeshInstance3D:
				result["bounds_position"]=runner.vec((node.global_transform*node.get_aabb()).position)
				result["bounds_size"]=runner.vec((node.global_transform*node.get_aabb()).size)
				var material: Material = node.material_override if node.material_override else node.get_active_material(0)
				result["material"]=material.resource_path if material else ""
				if material is ShaderMaterial: result["shader"]=material.shader.resource_path
			return result
		"extra_views": return await extra_views()
		"lighting": return await lighting_comparison()
		"shadow_compare": return await shadow_comparison()
		"campaign_start": return await campaign_start()
		"go": return await go(Vector3(float(command.position[0]),float(command.position[1]),float(command.position[2])))
		"route":
			Input.action_press("run")
			var route: Array=await runner.walk_route(command.points)
			Input.action_release("run")
			return {"route":route}
		"elevator": return await travel_elevator(int(command.floor))
		"key":
			var event := InputEventKey.new()
			event.physical_keycode = int(command.key)
			event.keycode = int(command.key)
			event.pressed = true
			Input.parse_input_event(event)
			await get_tree().process_frame
			event = event.duplicate(); event.pressed = false; Input.parse_input_event(event)
			return {"key":command.key}
		"minigame": return await solve_minigame()
		"fight": return await fight(str(command.boss))
		"retry_fight":
			if not await click_text("REINTENTAR BOSS"): return {"won":false,"reason":"No retry button"}
			return await fight(str(command.boss))
		"traversal": return await room_traversal()
		"targets":
			var rows: Array = []
			for group in ["campus_interactable","inventory_pickup","weapon_pickup","computer"]:
				for node in get_tree().get_nodes_in_group(group):
					rows.append({"group":group,"path":str(runner.campus.get_path_to(node)),"name":str(node.name),"position":runner.vec(node.global_position),"text":node.interaction_text(runner.player) if node.has_method("interaction_text") else ""})
			return {"targets":rows}
	return {}

func audit_geometry() -> Dictionary:
	var planes: Array = []
	for mesh in runner.campus.find_children("*","GeometryInstance3D",true,false):
		if not mesh.is_visible_in_tree(): continue
		var box: AABB
		if mesh is MeshInstance3D and mesh.mesh is BoxMesh: box=mesh.global_transform*mesh.get_aabb()
		elif mesh is CSGBox3D: box=mesh.global_transform*AABB(-mesh.size*0.5,mesh.size)
		else: continue
		if box.size.y > 0.8 or box.size.x < 2 or box.size.z < 2: continue
		planes.append({"path":str(runner.campus.get_path_to(mesh)),"box":box})
	var overlaps: Array = []
	for i in planes.size():
		for j in range(i+1,planes.size()):
			var a: AABB = planes[i].box; var b: AABB = planes[j].box
			var top_delta := absf(a.end.y-b.end.y)
			var bottom_delta := absf(a.position.y-b.position.y)
			if minf(top_delta,bottom_delta)>0.006: continue
			var area: Rect2 = Rect2(a.position.x,a.position.z,a.size.x,a.size.z).intersection(Rect2(b.position.x,b.position.z,b.size.x,b.size.z))
			if area.get_area()<1: continue
			overlaps.append({"a":planes[i].path,"b":planes[j].path,"top_delta":top_delta,"bottom_delta":bottom_delta,"area":area.get_area(),"a_position":runner.vec(a.position),"a_size":runner.vec(a.size),"b_position":runner.vec(b.position),"b_size":runner.vec(b.size)})
	var lights: Array = []
	for lamp in runner.lamps:
		if lamp.type=="DirectionalLight3D": continue
		var y: float = float(lamp.position[1])
		var nearest := INF
		for h in runner.heights: nearest = minf(nearest,absf(y-h))
		lights.append({"path":lamp.path,"energy":lamp.energy,"range":lamp.get("range",0),"shadows":lamp.shadows,"distance_to_nearest_floor":nearest})
	var result := {"horizontal_meshes":planes.size(),"coplanar_candidates":overlaps,"lights":lights,"fps":Engine.get_frames_per_second(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)}
	runner.write_json("geometry_audit.json",result)
	return {"horizontal_meshes":planes.size(),"coplanar_candidates":overlaps.size(),"fps":result.fps,"draw_calls":result.draw_calls}

func go(target: Vector3) -> Dictionary:
	var player = runner.player
	var y: float = runner.heights[0 if runner.floor_number(target.y)==-1 else runner.floor_number(target.y)]
	if absf(player.global_position.y-y)>2: return {"reached":false,"reason":"Different floor: use an elevator or stairs; no relocation performed."}
	var exclusions: Array[RID] = [player.get_rid()]
	for node in runner.campus.find_children("*","Node3D",true,false):
		var script = node.get_script()
		if script and "puerta" in script.resource_path:
			for body in node.find_children("*","PhysicsBody3D",true,false): exclusions.append(body.get_rid())
	var grid := AStarGrid2D.new()
	var step := 0.5
	grid.region = Rect2i(-174,-336,350,380 if y<1 and y>-1 else 194)
	grid.cell_size = Vector2.ONE*step
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var space = player.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player.standing_capsule
	query.collision_mask = 1
	query.exclude = exclusions
	query.margin = 0.005
	var open_points: Array[Vector2i] = []
	for gx in range(grid.region.position.x,grid.region.end.x):
		for gz in range(grid.region.position.y,grid.region.end.y):
			var id := Vector2i(gx,gz)
			var p := Vector3(gx*step,y+0.1,gz*step)
			var floor_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*1.7,p-Vector3.UP*1.4,1,exclusions))
			var clear := false
			if not floor_hit.is_empty() and floor_hit.normal.y>0.75 and absf(floor_hit.position.y-y)<1:
				query.transform = Transform3D(Basis.IDENTITY,floor_hit.position+Vector3.UP*1.415)
				var hits: Array = space.intersect_shape(query,16)
				clear = hits.all(func(hit): return is_door_collision(hit.collider))
			grid.set_point_solid(id,not clear)
			if clear: open_points.append(id)
		await get_tree().process_frame
	if open_points.is_empty(): return {"reached":false,"reason":"No safe navigation samples"}
	var from := nearest(open_points,player.global_position/step)
	var to := nearest(open_points,target/step)
	var path := grid.get_id_path(from,to)
	var route: Array = []
	var previous_direction := Vector2i.ZERO
	for index in range(1,path.size()):
		var direction: Vector2i = path[index]-path[index-1]
		if direction!=previous_direction and index>1: route.append([path[index-1].x*step,y,path[index-1].y*step])
		previous_direction = direction
	if not path.is_empty(): route.append([path[-1].x*step,y,path[-1].y*step])
	if route.is_empty(): return {"reached":false,"reason":"No connected route","start":from,"goal":to}
	Input.action_press("run")
	var walked: Array = await runner.walk_route(route)
	Input.action_release("run")
	return {"reached":not walked.is_empty() and walked[-1].reached,"route":walked,"navigation_nodes":path.size(),"requested":runner.vec(target)}

func nearest(points: Array[Vector2i],p: Vector3) -> Vector2i:
	var chosen := points[0]
	var distance := INF
	for candidate in points:
		var d := Vector2(candidate.x-p.x,candidate.y-p.z).length_squared()
		if d<distance: distance=d; chosen=candidate
	return chosen

func is_door_collision(node: Node) -> bool:
	var current := node
	while current and current!=runner.campus:
		var script = current.get_script()
		if script and "puerta" in script.resource_path: return true
		current=current.get_parent()
	return false

func press_button(button: Button) -> void:
	button.emit_signal("pressed")
	await get_tree().process_frame

func solve_minigame() -> Dictionary:
	var shell = runner.campaign.manager.minigame
	if not shell.active or shell.current==null: return {"completed":false,"reason":"No active computer"}
	var game = shell.current
	var deadline := Time.get_ticks_msec()+90000
	var remembered := ""
	var inputs := 0
	while shell.active and Time.get_ticks_msec()<deadline:
		if shell.closing:
			await get_tree().process_frame
			continue
		if not is_instance_valid(game): break
		var file_label = game.get("file_label")
		if file_label is Label:
			var extension: String = file_label.text.get_extension().to_lower()
			for b in game.find_children("*","Button",true,false):
				if b.text.contains("."+extension): await press_button(b); inputs+=1; break
		elif game.get("code_label") is Label:
			var shown: String = game.code_label.text
			if shown.replace(" ","").is_valid_int(): remembered=shown.replace(" ","")
			if int(game.get("phase"))==1 and not remembered.is_empty():
				for digit in remembered:
					for b in game.find_children("*","Button",true,false):
						if b.text==digit: await press_button(b); inputs+=1; break
				for b in game.find_children("*","Button",true,false):
					if b.text=="Enviar": await press_button(b); inputs+=1; break
				remembered=""
		else:
			for b in game.find_children("*","Button",true,false):
				if b.text.contains("VIRUS"): await press_button(b); inputs+=1
		await get_tree().create_timer(0.12).timeout
	return {"completed":not shell.active,"inputs":inputs,"computer_results":runner.campaign.data.computers}

func fight(id: String) -> Dictionary:
	var duel
	for d in get_tree().get_nodes_in_group("boss_duel"):
		if d.boss_id==id: duel=d; break
	if duel==null: return {"won":false,"reason":"Unknown duel"}
	var preparation_deadline:=Time.get_ticks_msec()+8000
	while duel.state!=duel.DuelState.COMBAT and Time.get_ticks_msec()<preparation_deadline: await get_tree().process_frame
	if duel.state!=duel.DuelState.COMBAT: return {"won":false,"reason":"Duel must be accepted through its dialogue first"}
	var player = runner.player
	var start_health: float = player.health
	var deadline := Time.get_ticks_msec()+180000
	var attacks := 0
	var attack_time := 0.0
	var minimum_health: float=duel.actor.health
	var trace: Array=[]
	var trace_timer:=0.0
	var dodges:=0
	while duel.state==duel.DuelState.COMBAT and not player.dead and Time.get_ticks_msec()<deadline:
		var target: Vector3 = duel.actor.global_position
		var offset: Vector3 = target-player.global_position
		offset.y=0
		runner.campaign.manager.cam_yaw=atan2(-offset.x,-offset.z)
		var visual = duel.actor.get("body")
		if visual and visual.get("punch_p") != null and visual.punch_p.any(func(p): return p>0.20 and p<0.45) and player.get_node("CombatExtensions").dodge_cd<=0 and player.stun_t<=0:
			Input.action_press("move_right")
			await key(KEY_ALT)
			Input.action_release("move_right")
			dodges+=1
		if offset.length()>1.2: Input.action_press("move_forward")
		else: Input.action_release("move_forward")
		minimum_health=minf(minimum_health,duel.actor.health)
		trace_timer-=get_physics_process_delta_time()
		if trace_timer<=0:
			trace_timer=0.5
			trace.append({"player_health":player.health,"boss_health":duel.actor.health,"distance":offset.length(),"stun":player.stun_t,"reachable":player._can_reach(duel.actor),"weapon":player.weapon.weapon_name if player.weapon else "fists"})
			runner.write_json("fight_live.json",{"boss":id,"minimum_boss_health":minimum_health,"trace":trace})
		if attack_time<=0 and not player.body.is_punching() and player.punch_cd<=0 and player.stun_t<=0:
			Input.action_press("punch"); attacks+=1
			attack_time=0.04
		else: Input.action_release("punch")
		attack_time-=get_physics_process_delta_time()
		await get_tree().physics_frame
	Input.action_release("move_forward"); Input.action_release("punch")
	var result := {"boss":id,"won":duel.defeated,"player_dead":player.dead,"health_before":start_health,"health_after":player.health,"boss_health":duel.actor.health,"minimum_boss_health":minimum_health,"attack_inputs":attacks,"dodge_inputs":dodges,"trace":trace}
	runner.write_json("fight_"+id+".json",result)
	return result

func room_traversal() -> Dictionary:
	var results: Array = []
	var player = runner.player
	var original: Vector3 = player.global_position
	runner.campaign.ui.close_modal()
	var enemy_states: Array = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy_states.append([enemy,enemy.is_physics_processing()])
		enemy.set_physics_process(false)
	for room in runner.rooms:
		var node = runner.campus.get_node(NodePath(room.path))
		var door
		for candidate in node.find_children("*","Node3D",true,false):
			var script = candidate.get_script()
			if script and "puerta" in script.resource_path:
				door=candidate; break
		if door==null:
			results.append({"id":room.id,"path":room.path,"status":"No automatic door: open space or manual route required"})
			continue
		var bounds := AABB(runner.point(room.bounds_position),runner.point(room.bounds_size))
		var inward: Vector3 = bounds.get_center()-door.global_position
		inward.y=0
		var normal: Vector3 = door.get_parent().global_basis.z if str(door.name)=="PuertaVidrio" else door.global_basis.z
		normal.y=0
		normal=normal.normalized()
		inward=normal if inward.dot(normal)>0 else -normal
		var door_center: Vector3 = door.global_position
		if str(door.name)=="PuertaVidrio": door_center+=door.get_parent().global_basis.x*0.7
		var gate = door.get_node_or_null("CampaignAccess")
		if gate and not player.inventory.has_item(gate.required_id,1):
			results.append({"id":room.id,"path":room.path,"status":"locked_as_designed","required_item":gate.required_id})
			continue
		var floor_y: float = runner.heights[0 if int(room.floor)==-1 else int(room.floor)]
		door_center.y=floor_y+0.1
		var start = player.get_node("SeatController").safe_position(door_center-inward*2.2)
		if start==null:
			results.append({"id":room.id,"path":room.path,"status":"Approach sample obstructed","door":runner.vec(door_center)})
			continue
		player.global_position=start
		player.velocity=Vector3.ZERO
		await get_tree().create_timer(0.65).timeout
		var inner: Vector3 = door_center+inward*2.2
		var route: Array = await runner.walk_route([runner.vec(inner),runner.vec(start)])
		results.append({"id":room.id,"path":room.path,"status":"passed" if route.size()==2 and route[-1].reached else "blocked","route":route,"door":str(runner.campus.get_path_to(door))})
		runner.write_json("door_traversal.json",results)
		print("DOOR_TRAVERSAL ",room.id," ",results[-1].status)
	player.global_position=original
	player.velocity=Vector3.ZERO
	for entry in enemy_states:
		if is_instance_valid(entry[0]): entry[0].set_physics_process(entry[1])
	runner.write_json("door_traversal.json",results)
	return {"spaces":results.size(),"passed":results.filter(func(r): return r.status=="passed").size(),"blocked":results.filter(func(r): return r.status=="blocked").size(),"note":"Independent doorway checks start with diagnostic relocation; not a continuous campaign traversal."}

func extra_views() -> Dictionary:
	var views: Array = []
	for floor_id in [-1,1,2,3,4,5,6,7,8]:
		var y: float = runner.heights[0 if floor_id==-1 else floor_id]+2.2
		for side in [-1,1]:
			views.append({"label":"corridor_%s_%s" % [str(floor_id),str(side)],"position":Vector3(side*24,y,-133),"target":Vector3(side*82,y,-133)})
		views.append({"label":"elevators_"+str(floor_id),"position":Vector3(0,y,-137),"target":Vector3(0,y,-155)})
		views.append({"label":"stairs_"+str(floor_id),"position":Vector3(20,y,-146),"target":Vector3(0,y+3,-152)})
		views.append({"label":"emergency_"+str(floor_id),"position":Vector3(-78,y,-143),"target":Vector3(-85,y,-155)})
	views.append_array([
		{"label":"exterior_front","position":Vector3(0,12,35),"target":Vector3(0,35,-125)},
		{"label":"exterior_west","position":Vector3(-115,35,-120),"target":Vector3(0,35,-120)},
		{"label":"exterior_east","position":Vector3(115,35,-120),"target":Vector3(0,35,-120)},
		{"label":"exterior_back","position":Vector3(0,35,-205),"target":Vector3(0,35,-130)},
		{"label":"roof","position":Vector3(0,120,-100),"target":Vector3(0,70,-130)},
		{"label":"auditorium_aisle","position":Vector3(65.5,14.1,-104.5),"target":Vector3(44,10,-104.5)},
		{"label":"printing_counter","position":Vector3(-27,14.2,-119),"target":Vector3(-31,14.2,-119)}])
	var position_before: Vector3 = runner.player.global_position
	var layers: Array = runner.campus.find_children("*","CanvasLayer",true,false)
	var visibility: Array = layers.map(func(l): return l.visible)
	for layer in layers: layer.hide()
	runner.player.set_physics_process(false)
	runner.campaign.manager.set_process(false)
	runner.player.body.hide()
	var results: Array = []
	for view in views:
		runner.player.global_position=view.position-Vector3.UP*2.2
		runner.camera.global_position=view.position
		runner.camera.look_at(view.target)
		runner.camera.make_current()
		results.append({"label":view.label,"position":runner.vec(view.position),"target":runner.vec(view.target),"capture":await runner.capture(view.label)})
	for index in layers.size(): layers[index].visible=visibility[index]
	runner.player.global_position=position_before
	runner.player.body.show()
	runner.player.set_physics_process(true)
	runner.campaign.manager.set_process(true)
	runner.campaign.manager.cam.make_current()
	runner.write_json("extra_views.json",results)
	return {"captures":results.size()}

func lighting_comparison() -> Dictionary:
	var survey: Array = JSON.parse_string(FileAccess.get_file_as_string(runner.OUT.path_join("room_survey.json")))
	var results: Array = []
	var position_before: Vector3 = runner.player.global_position
	runner.player.set_physics_process(false)
	runner.campaign.manager.set_process(false)
	runner.player.body.hide()
	var layers: Array = runner.campus.find_children("*","CanvasLayer",true,false)
	var visibility: Array = layers.map(func(l): return l.visible)
	for layer in layers: layer.hide()
	for id in [3,14,43,59,68]:
		var row: Dictionary = survey[id]
		var p: Vector3 = runner.point(row.camera_position)
		runner.player.global_position=p-Vector3.UP*2.15
		runner.camera.global_position=p
		runner.camera.look_at(p+Vector3.FORWARD)
		runner.camera.make_current()
		var baseline_path: String = await runner.capture("lighting_%03d_all" % id)
		var baseline: Image = runner.root.get_texture().get_image()
		var changed: Array = []
		var own_prefix: String = "PisoMenos1/" if int(row.room.floor)==-1 else "Piso%d/" % int(row.room.floor)
		for lamp in runner.campus.find_children("*","OmniLight3D",true,false):
			var path := str(runner.campus.get_path_to(lamp))
			if path.begins_with("Piso") and not path.begins_with(own_prefix) and lamp.visible:
				lamp.hide(); changed.append(lamp)
		var isolated_path: String = await runner.capture("lighting_%03d_own_floor" % id)
		var isolated: Image = runner.root.get_texture().get_image()
		var difference := 0.0
		var count := 0
		for x in range(0,baseline.get_width(),16):
			for y in range(0,baseline.get_height(),16):
				var a := baseline.get_pixel(x,y); var b := isolated.get_pixel(x,y)
				difference+=(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3
				count+=1
		for lamp in changed: lamp.show()
		results.append({"id":id,"path":row.room.path,"hidden_foreign_floor_lights":changed.size(),"mean_absolute_rgb_difference":difference/count,"all_lights_capture":baseline_path,"own_floor_capture":isolated_path})
	for index in layers.size(): layers[index].visible=visibility[index]
	runner.player.global_position=position_before
	runner.player.body.show()
	runner.player.set_physics_process(true)
	runner.campaign.manager.set_process(true)
	runner.campaign.manager.cam.make_current()
	runner.write_json("lighting_comparison.json",results)
	return {"comparisons":results}

func shadow_comparison() -> Dictionary:
	var survey: Array = JSON.parse_string(FileAccess.get_file_as_string(runner.OUT.path_join("room_survey.json")))
	var sun = runner.campus.get_node("SistemasCompartidos/LuzExterior")
	var before: bool = sun.shadow_enabled
	var results: Array = []
	var old_position: Vector3 = runner.player.global_position
	runner.player.set_physics_process(false)
	runner.campaign.manager.set_process(false)
	runner.player.body.hide()
	var layers: Array = runner.campus.find_children("*","CanvasLayer",true,false)
	var visibility: Array = layers.map(func(l): return l.visible)
	for layer in layers: layer.hide()
	for pair in [[3,Vector3(0,0.95,-0.25)],[20,Vector3(0,-0.95,-0.25)],[57,Vector3.FORWARD]]:
		var id: int = pair[0]
		var p: Vector3 = runner.point(survey[id].camera_position)
		runner.player.global_position=p-Vector3.UP*2.15
		runner.camera.global_position=p
		runner.camera.look_at(p+pair[1])
		runner.camera.make_current()
		sun.shadow_enabled=before
		var a: String = await runner.capture("shadow_%03d_on"%id)
		sun.shadow_enabled=false
		var b: String = await runner.capture("shadow_%03d_off"%id)
		results.append({"id":id,"shadow_on":a,"shadow_off":b,"shadow_bias":sun.shadow_bias,"normal_bias":sun.shadow_normal_bias,"max_distance":sun.directional_shadow_max_distance})
	sun.shadow_enabled=before
	for index in layers.size(): layers[index].visible=visibility[index]
	runner.player.global_position=old_position
	runner.player.body.show()
	runner.player.set_physics_process(true)
	runner.campaign.manager.set_process(true)
	runner.campaign.manager.cam.make_current()
	runner.write_json("shadow_comparison.json",results)
	return {"comparisons":results}

func click_text(text: String) -> bool:
	for button in runner.campus.find_children("*","Button",true,false):
		if button.is_visible_in_tree() and button.text==text:
			await press_button(button)
			return true
	return false

func record_step(title: String,result: Dictionary) -> void:
	actions.append({"step":title,"result":result,"state":runner.state()})
	runner.write_json("playthrough_actions.json",actions)
	var c=runner.campaign
	c.save_path=runner.OUT.path_join("playthrough_save.json")
	c.persist=true
	c.save_game()
	c.persist=false
	print("PLAYTHROUGH_STEP ",title," ",JSON.stringify(result))

func key(code: int) -> void:
	var event:=InputEventKey.new()
	event.keycode=code; event.physical_keycode=code; event.pressed=true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event=event.duplicate(); event.pressed=false; Input.parse_input_event(event)

func campaign_start() -> Dictionary:
	await runner.fresh_campus()
	record_step("Fresh isolated campaign",{"no_real_save_used":true,"no_progress_granted":true})
	var route: Dictionary = await go(Vector3(-3,0,-5.5))
	record_step("Walk to entrance weapon",route)
	if not route.get("reached",false): return {"stopped":"Entrance weapon route"}
	await runner.tap("interact")
	await key(KEY_1)
	record_step("Collect and equip through controls",{"inventory":runner.player.inventory.snapshot_data()})
	route=await go(Vector3(-5,0,-6.5))
	if not route.get("reached",false): record_step("Initial computer route",route); return {"stopped":"Initial computer route"}
	await runner.tap("interact")
	var computer: Dictionary=await solve_minigame()
	record_step("Play initial computer through UI",computer)
	if not computer.get("completed",false): return {"stopped":"Initial computer"}
	await runner.capture("playthrough_initial_computer_complete")
	route=await go(Vector3(-40.7,0,-142.5))
	record_step("Walk from plaza to Punto Estudiantil",route)
	if not route.get("reached",false): return {"stopped":"Punto route"}
	await runner.tap("interact")
	await runner.capture("playthrough_punto_dialogue")
	if not await click_text("Iniciar duelo"): return {"stopped":"Punto interaction did not offer duel"}
	await get_tree().create_timer(3.5).timeout
	var duel: Dictionary=await fight("punto")
	record_step("Punto Estudiantil combat with normal stats",duel)
	await runner.capture("playthrough_punto_result")
	return {"punto":duel,"no_teleports":true,"no_damage_or_health_overrides":true}

func travel_elevator(floor_id: int) -> Dictionary:
	var elevator=runner.campus.get_node("SistemasCompartidos/AscensoresEstudiantiles/Ascensor01")
	var source_floor: int=runner.floor_number(runner.player.global_position.y)
	var index: int=8 if floor_id==-1 else floor_id-1
	var source_index: int=8 if source_floor==-1 else source_floor-1
	if Vector2(runner.player.global_position.x+10,runner.player.global_position.z+148).length()>3.5:
		return {"arrived":false,"reason":"Walk to the first elevator landing at X=-10, Z=-148 first"}
	await runner.tap("interact")
	var deadline:=Time.get_ticks_msec()+40000
	while (elevator.moving or elevator.current_floor!=source_index) and Time.get_ticks_msec()<deadline: await get_tree().process_frame
	await get_tree().create_timer(0.7).timeout
	var y: float=runner.heights[0 if source_floor==-1 else source_floor]
	var entry: Array=await runner.walk_route([[-10,y,-151],[-10,y,-155]])
	if entry.is_empty() or not entry[-1].reached: return {"arrived":false,"entry":entry}
	await runner.tap("interact")
	if not await click_text("Subterráneo" if floor_id==-1 else "Piso "+str(floor_id)):
		return {"arrived":false,"reason":"The destination is not available in the real elevator menu"}
	deadline=Time.get_ticks_msec()+40000
	while (elevator.moving or elevator.current_floor!=index) and Time.get_ticks_msec()<deadline: await get_tree().process_frame
	await get_tree().create_timer(0.7).timeout
	var destination_y: float=runner.heights[0 if floor_id==-1 else floor_id]
	var body_arrived: bool=absf(runner.player.global_position.y-destination_y)<1
	var exit: Array=await runner.walk_route([[-10,destination_y,-146.5]])
	var result:={"from":source_floor,"to":floor_id,"arrived":body_arrived and elevator.current_floor==index,"player_y":runner.player.global_position.y,"exit":exit}
	record_step("Ride elevator using its menu",result)
	return result
