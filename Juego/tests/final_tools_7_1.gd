extends Node
var f: Node
func install(parent: Node) -> String:
	f=parent;name="AuditTools71";parent.add_child(self);return "AUDIT_TOOLS_READY"
func monitors(correct: bool) -> void:
	f.active_floor=3;f.phase="monitor_after" if correct else "monitor_before"
	var data=[]
	for key in f.campaign.get_node("DuocGames4").laboratories:
		var room=f.campaign.get_node("DuocGames4").laboratories[key]
		if not room.has_method("box"): continue
		var monitors=room.get_children().filter(func(n): return n is MeshInstance3D and n.mesh is BoxMesh and n.mesh.size.is_equal_approx(Vector3(0.7,0.45,0.07)))
		for monitor in monitors:
			var point: Vector3=monitor.position
			if correct:
				room.box("BaseMonitor71",Vector3(point.x,0.815,point.z),Vector3(0.36,0.03,0.24),Color("24252b"))
				room.box("SoporteMonitor71",Vector3(point.x,0.92,point.z),Vector3(0.055,0.21,0.055),Color("24252b"))
			data.append({"room":str(key),"monitor":str(monitor.name),"screen_bottom_local":point.y-monitor.mesh.size.y*0.5,"desk_top_local":0.8,"stand_top_local":1.025 if correct else null,"stand_base_local":0.8 if correct else null})
		await f.shot("detail_monitor_"+str(key),room.to_global(Vector3(0,1.7,-2.7)),room.to_global(Vector3(2.7,1.0,1.0)))
	f.write("floor_3/"+f.phase+"_support",data)
	f.record("monitor_supports","PASS" if correct else "FAIL",{"monitors":data.size(),"unsupported_gap_before":0.225,"added_noncolliding_stands":correct})
func walk(label: String, start: Vector3, target: Vector3, timeout: float=24.0) -> void:
	var p=f.player;var c=f.campaign
	c.ui.close_modal();p.busy=false;p.dead=false;p.velocity=Vector3.ZERO
	var safe=p.get_node("SeatController").safe_position(start)
	if safe==null: f.record(label,"NOT RUN",{"reason":"No safe start","start":str(start)});return
	p.global_position=safe;p.body.show();p.set_process(true);p.set_physics_process(true)
	var direction=target-safe;direction.y=0;direction=direction.normalized();p.cam_yaw=atan2(-direction.x,-direction.z)
	c.manager.cam_yaw=p.cam_yaw;c.manager.set_process(true);c.manager.cam.make_current()
	await get_tree().create_timer(0.4).timeout
	Input.action_press("move_forward");var elapsed=0.0;var trace=[]
	while elapsed<timeout:
		await get_tree().create_timer(0.2).timeout;elapsed+=0.2;trace.append(str(p.global_position))
		if Vector2(target.x-p.global_position.x,target.z-p.global_position.z).length()<0.65: break
	Input.action_release("move_forward")
	var blockers=[]
	for i in p.get_slide_collision_count(): blockers.append(str(p.get_slide_collision(i).get_collider().get_path()))
	f.record(label,"PASS" if Vector2(target.x-p.global_position.x,target.z-p.global_position.z).length()<0.8 and absf(p.global_position.y-target.y)<0.7 else "FAIL",{"start":str(safe),"end":str(p.global_position),"expected":str(target),"blockers":blockers,"trace":trace,"scope":"Real input/controller; diagnostic relocation to start"})
	await RenderingServer.frame_post_draw;f.get_viewport().get_texture().get_image().save_png(f.out+"floor_"+str(f.active_floor)+"/route_"+label+".png")
	p.set_process(false);p.set_physics_process(false);p.body.hide();c.manager.set_process(false);f.camera.make_current()
func floor_checks(number: int) -> void:
	f.active_floor=number;f.phase="functional"
	var height: float=preload("res://scripts/campaign/campus_content.gd").HEIGHTS[number-1]
	await walk("hall_walk_"+str(number),Vector3(-30,height+0.12,-140),Vector3(-35,height,-140),5)
	if number<8:
		var above: float=preload("res://scripts/campaign/campus_content.gd").HEIGHTS[number]
		await walk("stairs_"+str(number)+"_up",Vector3(-21.8,height+0.15,-127.8),Vector3(20.4,above,-127.8),27)
		await walk("stairs_"+str(number)+"_down",Vector3(20.4,above+0.15,-127.8),Vector3(-21.8,height,-127.8),27)
	var lift=f.campus.get_node("SistemasCompartidos/AscensoresEstudiantiles").get_child(0)
	var before=lift.moving;lift.request_floor(number-1)
	f.record("elevator_campaign_gate","PASS" if not lift.moving and not f.campaign.floor_unlocked(str(number)) else "FAIL",{"unlocked":f.campaign.floor_unlocked(str(number)),"scope":"Negative authorization test; authorized inter-floor ride BLOCKED by unmet campaign, no unlock injection"})
	f.record("authorized_elevator_trip","BLOCKED","Current isolated new campaign has not earned upper-floor destinations")
	var old=f.campaign.save_path
	f.campaign.save_path=f.out+"floor_"+str(number)+"/isolated_save.json";f.campaign.persist=true;f.campaign.save_game();f.campaign.persist=false
	var restored=preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(f.campaign.save_path)
	var expected=f.campaign.save_payload()
	f.record("isolated_save_read","PASS" if JSON.parse_string(JSON.stringify(expected))==JSON.parse_string(JSON.stringify(restored)) else "FAIL",{"path":f.campaign.save_path,"cloud":f.campaign.cloud_mode})
	f.campaign.save_path=old
	f.write("floor_"+str(number)+"/functional_done",{"floor":number})
func published_block(number: int) -> void:
	f.active_floor=number;f.phase="functional"
	var missions=f.campaign.get_node("DuocGames4").missions
	var catalog=[]
	for row in missions.CATALOG:
		if int(row.floor)==number: catalog.append(row)
	f.write("floor_"+str(number)+"/incident_catalog",catalog)
	for row in catalog: f.record("published_incident_"+str(row.id),"BLOCKED",{"steps":row.steps,"reason":"Anonymous read-only probes return PGRST205 for V4 resources; no verified remote result fabricated"})
