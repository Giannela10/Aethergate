extends Node3D
var failures=[]
func _ready(): run.call_deferred()
func run():
	var campus=load("res://Main.tscn").instantiate();var campaign=campus.get_node("CampusCampaign")
	campaign.persist=false;campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	campaign.ui.close_modal();campaign.live.director.set_process(false)
	# Teleport inspection only: do not turn a benchmark into an access challenge.
	campaign.get_node("AcademicFloorGate").set_process(false)
	campaign.get_node("AcademicFloorGate").set_physics_process(false)
	var camera=Camera3D.new();camera.fov=65;add_child(camera);camera.make_current()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	var rows=[]
	for floor_number in [-1,1,2,3,4,5,6,7,8]:
		var level=campus.get_node("PisoMenos1" if floor_number==-1 else "Piso"+str(floor_number))
		var height=preload("res://scripts/campaign/campus_content.gd").HEIGHTS[8 if floor_number==-1 else floor_number-1]
		var safe=null
		for point in [Vector3(0,height+0.15,-138),Vector3(-20,height+0.15,-140),Vector3(25,height+0.15,-133),Vector3(-35,height+0.15,-135)]:
			safe=campaign.player.get_node("SeatController").safe_position(point)
			if safe!=null and absf(safe.y-height)<0.5: break
			safe=null
		if safe==null: failures.append("No safe observation point floor "+str(floor_number));continue
		campaign.player.global_position=safe;campaign.player.velocity=Vector3.ZERO
		camera.global_position=safe+Vector3(6,4,8);camera.look_at(safe+Vector3(0,1.2,-6))
		await get_tree().create_timer(1.2).timeout
		campaign.ui.close_modal()
		var samples=[];var draws=[]
		for frame in 180:
			var begin=Time.get_ticks_usec()
			await RenderingServer.frame_post_draw
			if frame>=60: samples.append((Time.get_ticks_usec()-begin)/1000.0);draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		samples.sort();draws.sort()
		var query=PhysicsRayQueryParameters3D.create(campaign.player.global_position+Vector3.UP*0.4,campaign.player.global_position-Vector3.UP*0.7,1,[campaign.player.get_rid()])
		var hit=campaign.player.get_world_3d().direct_space_state.intersect_ray(query)
		var human_count=0
		for visual in get_tree().get_nodes_in_group("campus_character_visual"):
			if visual.has_meta("remodel63") and absf(visual.global_position.y-height)<4: human_count+=1
		var row={"floor":floor_number,"scene_loaded":level.is_inside_tree(),"root_visible":level.is_visible_in_tree(),"safe_position":str(safe),"floor_collision":not hit.is_empty(),"human_npcs":human_count,"lights":level.find_children("*","Light3D",true,false).size(),"labels":level.find_children("*","Label3D",true,false).size(),"median_ms":samples[60],"p95_ms":samples[114],"fps_from_median":1000.0/samples[60],"draw_calls":draws[60],"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
		if not row.scene_loaded or not row.floor_collision: failures.append(row)
		rows.append(row)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://reports/capstone_capturas/piso_"+str(floor_number)+".png")
		print("CAPSTONE_FLOOR ",floor_number)
	var report={"failures":failures,"floors":rows,"renderer":ProjectSettings.get_setting("rendering/renderer/rendering_method"),"method":"Main instantiated, actor physics active, custom fixed inspection camera, 1.2 s settling, 120 measured frames after 60 warmup frames, vsync off. Access gate suspended only in this isolated benchmark. Diagnostic relocation is not a continuous manual walkthrough."}
	var file=FileAccess.open("res://reports/capstone/campus_tests.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("CAPSTONE_CAMPUS_DONE ",failures.size())
