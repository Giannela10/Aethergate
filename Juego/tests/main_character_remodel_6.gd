extends Node3D
const OUT := "res://reports/main_character_6_0/"
var phase := "before"
var campus: Node
var player: Node3D
var camera: Camera3D
func _ready() -> void:
	seed(600)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if FileAccess.file_exists(OUT+"phase.txt"): phase=FileAccess.get_file_as_string(OUT+"phase.txt").strip_edges()
	run.call_deferred()
func shot(label: String, offset: Vector3, height: float = 1.4) -> void:
	camera.global_position=player.global_position+offset
	camera.look_at(player.global_position+Vector3.UP*height)
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+phase+"_"+label+".png")
func run() -> void:
	campus=load("res://Main.tscn").instantiate()
	var campaign=campus.get_node("CampusCampaign")
	campaign.persist=false
	campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	campaign.ui.close_modal()
	campaign.set_process(false)
	player=campaign.player
	if phase=="before":
		var previous=player.body
		var baseline=preload("res://scripts/juego/student_visual.gd").new()
		baseline.name="CharacterVisualBaseline"
		baseline.scale=previous.scale
		baseline.punch_time=previous.punch_time
		player.add_child(baseline)
		baseline.apply_appearance(previous.get_meta("appearance_profile").duplicate(true))
		player.body=baseline
		previous.get_parent().remove_child(previous)
		previous.free()
	player.body.contextual_pose.remaining=0
	player.body.transient_time=0
	player.body.idle_remaining=0
	player.body.set_visual_activity("","NONE")
	player.body.set_meta("important_scene",true)
	player.body.secondary_animation_enabled=false
	player.inventory.persist=false
	for actor in campus.find_children("*","CharacterBody3D",true,false):
		actor.set_physics_process(false)
		actor.set_process(false)
	for i in 120: player.body.animate(0.016,Vector3.ZERO,true,false)
	for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+phase+"_game_camera.png")
	campaign.manager.set_process(false)
	camera=Camera3D.new()
	camera.near=0.02
	camera.fov=45
	add_child(camera)
	camera.make_current()
	for pair in [["front",Vector3(0,1.5,-4.6)],["back",Vector3(0,1.5,4.6)],["left",Vector3(-4.6,1.5,0)],["right",Vector3(4.6,1.5,0)],["face",Vector3(0,2.36,-0.75)]]:
		await shot(pair[0],pair[1],2.36 if pair[0]=="face" else 1.4)
	for i in 30: player.body.animate(0.016,Vector3(0,0,-2.5),true,false)
	await shot("walking_campus",Vector3(2,1.8,-4.5))
	var meshes=player.body.find_children("*","MeshInstance3D",true,false)
	var vertices=0
	var surfaces=0
	for mesh in meshes:
		if not mesh.is_visible_in_tree() or mesh.mesh==null: continue
		surfaces+=mesh.mesh.get_surface_count()
		for s in mesh.mesh.get_surface_count(): vertices+=mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX].size()
	var metrics={"meshes":meshes.size(),"vertices":vertices,"surfaces":surfaces,"fps":Performance.get_monitor(Performance.TIME_FPS),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"player_scale":str(player.body.scale),"capsule_height":player.capsule.height,"capsule_radius":player.capsule.radius,"rig":"procedural joint transforms; placeholder Skeleton3D has no bones"}
	var samples: Array=[]
	var last=Time.get_ticks_usec()
	for i in 90:
		await RenderingServer.frame_post_draw
		var now=Time.get_ticks_usec()
		samples.append({"ms":float(now-last)/1000.0,"fps":Performance.get_monitor(Performance.TIME_FPS),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		last=now
	metrics["samples"]=samples
	var file=FileAccess.open(OUT+phase+"_metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t"))
	print("MAIN_CHARACTER_60_DONE ",phase," ",metrics)
	if phase=="after": await verify(campaign)

func verify(campaign: Node) -> void:
	var model=player.body
	var failures: Array=[]
	var profile=model.get_meta("appearance_profile").duplicate(true)
	var socket=model.weapon_socket
	var parent=socket.get_parent()
	var Profile=preload("res://scripts/juego/character_appearance.gd")
	var unlocked: Dictionary={}
	for key in Profile.LOCKS.values(): unlocked[key]=true
	for style in [0,1,4]:
		var p=profile.duplicate(true)
		p.hair=style
		p.top=1
		p.bottom_style=1
		model.apply_appearance(p)
		for i in 30: model.animate(0.016,Vector3.ZERO,true,false)
		await shot("hoodie_hair_"+str(style),Vector3(1.7,1.7,-4.0))
	var count=model.find_children("*","MeshInstance3D",true,false).size()
	for i in 5: model.apply_appearance(model.get_meta("appearance_profile").duplicate(true))
	if count!=model.find_children("*","MeshInstance3D",true,false).size(): failures.append("Mesh accumulation")
	if socket!=model.weapon_socket or socket.get_parent()!=parent: failures.append("Socket identity")
	var path="user://main_character_60_isolated_appearance.json"
	var stream=FileAccess.open(path,FileAccess.WRITE)
	stream.store_string(JSON.stringify(profile));stream.close()
	var restored=Profile.normalize(JSON.parse_string(FileAccess.get_file_as_string(path)),unlocked)
	if restored!=profile: failures.append("Appearance disk roundtrip")
	DirAccess.remove_absolute(path)
	var hits=[0]
	model.punch_landed.connect(func(_side): hits[0]+=1)
	model.start_punch()
	for i in 90: model.animate(0.016,Vector3.ZERO,true,false)
	if hits[0]!=1: failures.append("Punch event count")
	for motion in [["walk",Vector3(0,0,-2.5),true,false],["run",Vector3(0,0,-5.5),true,false],["jump",Vector3(0,4,0),false,false],["crouch",Vector3.ZERO,true,true]]:
		for i in 30: model.animate(0.016,motion[1],motion[2],motion[3])
		await shot("motion_"+motion[0],Vector3(1.6,1.7,-4.1))
	for i in 90: model.animate(0.016,Vector3.ZERO,true,false)
	var weapon_found=false
	for weapon in get_tree().get_nodes_in_group("weapon_pickup"):
		if weapon.get("durability")==null or weapon.durability<=0: continue
		if player.inventory.collect_weapon(weapon,true):
			weapon_found=true
			for i in 60: model.animate(0.016,Vector3.ZERO,true,false)
			await shot("equipped",Vector3(1.6,1.7,-3.8))
			break
	if model.armed:
		var held=model.unequip()
		if held: held.hide()
	for i in 90: model.animate(0.016,Vector3.ZERO,true,false)
	var report={"failures":failures,"isolated_appearance_disk_roundtrip":restored==profile,"socket_identity":socket==model.weapon_socket,"one_punch_event":hits[0]==1,"equipped_real_pickup":weapon_found,"personal_saves_used":false,"campaign_save_flow":"not tested; unchanged","mesh_reapply_count":count}
	for zone in [["entrance",Vector3(0,0.05,-65)],["corridor",Vector3(-20,0.05,-100)],["library",Vector3(-58.7,12.1,-119.7)],["computer_lab",Vector3(27.93,24.52,-111.58)],["exterior",Vector3(8,0.05,-45)]]:
		var safe=player.get_node("SeatController").safe_position(zone[1])
		if safe==null:
			report[zone[0]]="No safe capsule position; skipped"
			continue
		player.global_position=safe
		if zone[0]=="library":
			model.rotation.y=-PI*0.5
			await shot("zone_"+zone[0],Vector3(3.7,1.7,0))
			model.rotation.y=0
		else: await shot("zone_"+zone[0],Vector3(1.7,1.7,-4.3))
		report[zone[0]]={"position":str(safe),"note":"Diagnostic teleport; no walked route"}
	model.apply_appearance(profile)
	model.secondary_animation_enabled=true
	for exp in ["NEUTRAL","HAPPY","SURPRISED","FOCUSED","PAIN","VICTORY"]:
		model.set_expression(exp)
		for i in 3: model.animate(0.016,Vector3.ZERO,true,false)
		await shot("expression_"+exp,Vector3(0,2.36,-0.75),2.36)
	for top in 7:
		var p=profile.duplicate(true)
		p.top=top
		model.apply_appearance(p)
		if model.weapon_socket!=socket: failures.append("Socket on top "+str(top))
	model.apply_appearance(profile)
	campaign.appearance_menu.open(true)
	report["new_game_default_hoodie"]=campaign.appearance_menu.working.top==1 and campaign.appearance_menu.working.bottom_style==1
	report["preview_script"]=campaign.appearance_menu.preview.get_script().resource_path
	campaign.ui.show()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"after_personalization.png")
	campaign.ui.close_modal()
	var f=FileAccess.open(OUT+"functional.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"));f.close()
	print("MAIN_CHARACTER_60_FUNCTIONAL ",report)
