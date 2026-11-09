extends "res://tests/inventory_6_3.gd"
var camera: Camera3D
func run():
	campus_setup_placeholder()
func campus_setup_placeholder():
	var campus=load("res://Main.tscn").instantiate()
	var campaign=campus.get_node("CampusCampaign")
	campaign.persist=false;campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	await get_tree().create_timer(3).timeout
	campaign.ui.close_modal();campaign.set_process(false);campaign.manager.set_process(false)
	for actor in campus.find_children("*","CharacterBody3D",true,false): actor.set_process(false);actor.set_physics_process(false)
	camera=Camera3D.new();camera.near=0.03;camera.fov=40;add_child(camera);camera.make_current()
	var batch=int(load("res://scripts/juego/npc_visual_6_3.gd").config.get("batch",0))
	var phase="batch"+str(batch)
	var rows=[]
	for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()
	for visual in get_tree().get_nodes_in_group("campus_character_visual"):
		var actor=visual.get_parent()
		actor.set_process(false);actor.set_physics_process(false)
		var meta=visual.get_meta("remodel63",{})
		var original=visual.get_meta("visual_preset",{})
		var row={"path":str(visual.get_path()),"id":meta.get("id",original.get("visual_id",str(actor.name))),"role":meta.get("role",original.get("role","")),"floor_y":visual.global_position.y,"visible":visual.is_visible_in_tree(),"remodel":meta,"interaction":actor.interaction_text(campaign.player) if actor.has_method("interaction_text") else ""}
		rows.append(row)
		if meta.is_empty() and not (batch==0 and row.id in ["Auxiliar","Estudiante"]): continue
		# Place only the test player nearby so distance culling reflects a close visit.
		campaign.player.global_position=visual.global_position+Vector3(2,0,1)
		visual.lod_level=0;visual.activity_level=0;visual.lod_tick=0;visual.update_visual_lod(1)
		for i in 15: visual.animate(0.016,Vector3.ZERO,true,false)
		var height=1.8*visual.global_basis.get_scale().y
		var center=visual.global_position+Vector3.UP*height*0.5
		var front=(visual.global_basis*Vector3.FORWARD).normalized()
		for angle in ["front","side","back"] if batch in [0,2] else ["front"]:
			camera.fov=60
			var offset=front*height if angle=="front" else -front*height if angle=="back" else (visual.global_basis*Vector3.RIGHT).normalized()*height
			camera.global_position=center+offset+Vector3.UP*0.15;camera.look_at(center)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://reports/characters_6_3/"+phase+"_"+str(row.id).replace(":","_").replace("/","_")+"_"+angle+".png")
		if meta.is_empty(): continue
		for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()
		var head=visual.human_visual63.model.rig
		var head_pos=head.global_transform*head.get_bone_global_pose(head.find_bone("head")).origin
		head_pos.y+=height*0.035
		camera.global_position=head_pos+front*height*0.55;camera.look_at(head_pos)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://reports/characters_6_3/"+phase+"_"+str(row.id).replace(":","_").replace("/","_")+"_face.png")
		row["poses"]={}
		row["anatomy_valid"]=true
		for state in ["walk","run","crouch","attack","read","computer","talk","sit","stand","write","celebrate"]:
			if state=="attack": visual.start_punch()
			if state in ["talk","write","celebrate"] and visual.has_method("set_visual_activity"): visual.set_visual_activity({"talk":"EXPLAIN","write":"WRITE","celebrate":"CELEBRATE"}[state])
			if state=="sit" and visual.get("contextual_pose")!=null: visual.contextual_pose.seated=true;visual.contextual_pose.seat_height=0.55
			if state=="stand" and visual.get("contextual_pose")!=null: visual.contextual_pose.seated=false
			if state in ["read","computer"] and visual.has_method("play_context_action"): visual.play_context_action(state)
			for i in 10: visual.animate(0.016,Vector3(0,0,-2.5 if state=="walk" else -5.0 if state=="run" else 0),true,state=="crouch")
			var skeleton=visual.human_visual63.model.rig
			var bones={}
			for label in ["head","hand_l","hand_r","foot_l","foot_r"]:
				var pose=skeleton.get_bone_global_pose(skeleton.find_bone(label))
				bones[label]={"finite":pose.origin.is_finite() and pose.basis.is_finite(),"position":str(pose.origin)}
			row.poses[state]=bones
			var head_y=skeleton.get_bone_global_pose(skeleton.find_bone("head")).origin.y
			var foot_y=minf(skeleton.get_bone_global_pose(skeleton.find_bone("foot_l")).origin.y,skeleton.get_bone_global_pose(skeleton.find_bone("foot_r")).origin.y)
			if head_y-foot_y<0.45 or head_y-foot_y>2.5: row.anatomy_valid=false
		row["bone_count"]=visual.human_visual63.model.rig.get_bone_count()
		row["mesh_skin_valid"]=true
		for mesh in visual.human_visual63.model.human.find_children("*","MeshInstance3D",true,false):
			if mesh.skin==null or mesh.get_node_or_null(mesh.skeleton)!=visual.human_visual63.model.rig: row.mesh_skin_valid=false
	var out=FileAccess.open("res://reports/characters_6_3/"+phase+"_coverage.json",FileAccess.WRITE);out.store_string(JSON.stringify(rows,"\t"));out.close()
	# Actual dialogue opening, without accepting a mission or writing a save.
	var auxiliary=campus.get_node("CampusCampaign/Auxiliar")
	campaign.player.busy=false;campaign.player.dead=false
	auxiliary.interact(campaign.player)
	await get_tree().process_frame
	var dialogue={"text":auxiliary.interaction_text(campaign.player),"ui_busy":campaign.player.busy,"mission_not_accepted":campaign.quests.state(auxiliary.quest_id)==0}
	out=FileAccess.open("res://reports/characters_6_3/"+phase+"_dialogue.json",FileAccess.WRITE);out.store_string(JSON.stringify(dialogue,"\t"));out.close()
	campaign.ui.close_modal()
	# Same Main camera and animated player for a reproducible campus comparison.
	for visual in get_tree().get_nodes_in_group("campus_character_visual"):
		if visual.has_method("set_visual_activity"): visual.set_visual_activity("","NONE")
		var context=visual.get("contextual_pose")
		if context!=null: context.seated=false
	campaign.player.global_position=Vector3(4,0.15,-48)
	camera.global_position=Vector3(7,2.2,-53);camera.look_at(Vector3(4,1.4,-48))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	for visual in get_tree().get_nodes_in_group("campus_character_visual"): visual.update_visual_lod(1)
	var samples=[];var calls=[]
	for i in 240:
		var begin=Time.get_ticks_usec()
		campaign.player.body.animate(0.016,Vector3(0,0,-2.5),true,false)
		for visual in get_tree().get_nodes_in_group("campus_character_visual"):
			if visual!=campaign.player.body: visual.animate(0.016,Vector3.ZERO,true,false)
		await RenderingServer.frame_post_draw
		if i>59:
			samples.append((Time.get_ticks_usec()-begin)/1000.0)
			calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	samples.sort();calls.sort()
	out=FileAccess.open("res://reports/characters_6_3/"+phase+"_main_performance.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"median_ms":samples[90],"p95_ms":samples[171],"fps":1000.0/samples[90],"draw_calls":calls[90],"samples":samples.size(),"method":"Actual Main, same entry camera, player walking in place, NPC idle animation calls; actor physics frozen, vsync off."},"\t"));out.close()
	print("NPC63_DONE ",phase," ",rows.size())
