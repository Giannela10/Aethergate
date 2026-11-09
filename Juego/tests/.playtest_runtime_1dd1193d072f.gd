extends Node
## Inspection helpers use live collision, input and UI handlers; never grant wins.
var runner
var actions: Array = []

func run(command: Dictionary) -> Dictionary:
	match str(command.get("mode","geometry")):
		"geometry": return audit_geometry()
		"go": return await go(Vector3(float(command.position[0]),float(command.position[1]),float(command.position[2])))
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
	for mesh in runner.campus.find_children("*","MeshInstance3D",true,false):
		if not mesh.mesh is BoxMesh or not mesh.is_visible_in_tree(): continue
		var box: AABB = mesh.global_transform*mesh.get_aabb()
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
	var step := 1.0
	grid.region = Rect2i(-87,-168,175,190 if y<1 and y>-1 else 97)
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
				clear = space.intersect_shape(query,1).is_empty()
			grid.set_point_solid(id,not clear)
			if clear: open_points.append(id)
		await get_tree().process_frame
	if open_points.is_empty(): return {"reached":false,"reason":"No safe navigation samples"}
	var from := nearest(open_points,player.global_position)
	var to := nearest(open_points,target)
	var path := grid.get_id_path(from,to)
	var route: Array = []
	var previous_direction := Vector2i.ZERO
	for index in range(1,path.size()):
		var direction: Vector2i = path[index]-path[index-1]
		if direction!=previous_direction and index>1: route.append([path[index-1].x*step,y,path[index-1].y*step])
		previous_direction = direction
	if not path.is_empty(): route.append([path[-1].x*step,y,path[-1].y*step])
	if route.is_empty(): return {"reached":false,"reason":"No connected route","start":from,"goal":to}
	var walked: Array = await runner.walk_route(route)
	return {"reached":not walked.is_empty() and walked[-1].reached,"route":walked,"navigation_nodes":path.size(),"requested":runner.vec(target)}

func nearest(points: Array[Vector2i],p: Vector3) -> Vector2i:
	var chosen := points[0]
	var distance := INF
	for candidate in points:
		var d := Vector2(candidate.x-p.x,candidate.y-p.z).length_squared()
		if d<distance: distance=d; chosen=candidate
	return chosen

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
	if duel==null or duel.state!=duel.DuelState.COMBAT: return {"won":false,"reason":"Duel must be accepted through its dialogue first"}
	var player = runner.player
	var start_health: float = player.health
	var deadline := Time.get_ticks_msec()+180000
	var attacks := 0
	var attack_time := 0.0
	while duel.state==duel.DuelState.COMBAT and not player.dead and Time.get_ticks_msec()<deadline:
		var target: Vector3 = duel.actor.global_position
		var offset: Vector3 = target-player.global_position
		offset.y=0
		runner.campaign.manager.cam_yaw=atan2(-offset.x,-offset.z)
		if offset.length()>1.2: Input.action_press("move_forward")
		else: Input.action_release("move_forward")
		if attack_time<=0:
			Input.action_press("punch"); attacks+=1
			attack_time=0.18
		else: Input.action_release("punch")
		attack_time-=get_physics_process_delta_time()
		await get_tree().physics_frame
	Input.action_release("move_forward"); Input.action_release("punch")
	var result := {"boss":id,"won":duel.defeated,"player_dead":player.dead,"health_before":start_health,"health_after":player.health,"boss_health":duel.actor.health,"attack_inputs":attacks}
	runner.write_json("fight_"+id+".json",result)
	return result

func room_traversal() -> Dictionary:
	var results: Array = []
	var player = runner.player
	var original: Vector3 = player.global_position
	runner.campaign.ui.close_modal()
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
		inward=inward.normalized()
		var door_center: Vector3 = door.global_position
		if str(door.name)=="PuertaVidrio": door_center+=door.global_basis.x*0.7
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
	runner.write_json("door_traversal.json",results)
	return {"spaces":results.size(),"passed":results.filter(func(r): return r.status=="passed").size(),"blocked":results.filter(func(r): return r.status=="blocked").size(),"note":"Independent doorway checks start with diagnostic relocation; not a continuous campaign traversal."}
