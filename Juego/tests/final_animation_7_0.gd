extends Node3D
var body: Node3D
var camera: Camera3D
var out: String
var phase: String
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	out=FileAccess.get_file_as_string("res://reports/final_7_0/active_run.txt").strip_edges().trim_prefix("Juego/")
	out="res://"+out+"/"
	phase=FileAccess.get_file_as_string(out+"phase.txt").strip_edges()
	seed(700)
	var actor=CharacterBody3D.new()
	actor.add_to_group("player")
	add_child(actor)
	body=load("res://scripts/juego/main_character_visual_6_2.gd").new()
	actor.add_child(body)
	body.apply_appearance(preload("res://scripts/juego/character_appearance.gd").normalize({"top":1,"bottom_style":1,"backpack":1,"shoes":6}))
	body.set_meta("important_scene",true)
	var floor_body=StaticBody3D.new()
	add_child(floor_body)
	var shape=CollisionShape3D.new()
	var box=BoxShape3D.new();box.size=Vector3(100,0.1,100)
	shape.shape=box;shape.position.y=-0.05;floor_body.add_child(shape)
	var ground=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(100,100);ground.mesh=plane;add_child(ground)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);add_child(light)
	var environment=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("536070");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=0.6;add_child(environment)
	camera=Camera3D.new();camera.fov=40;add_child(camera);camera.make_current()
	var rig: Skeleton3D=body.human62.rig
	var bones=[]
	for i in rig.get_bone_count():
		bones.append({"name":rig.get_bone_name(i),"parent":rig.get_bone_parent(i),"rest":str(rig.get_bone_global_rest(i))})
	var rows=[]
	for state in ["idle","walk","run","lateral","backward","jump","land","crouch","attack","pickup"]:
		var motion=Vector3(0,0,-2.5) if state=="walk" else Vector3(0,0,-5.5) if state=="run" else Vector3(2.5,0,0) if state=="lateral" else Vector3(0,0,2.5) if state=="backward" else Vector3.ZERO
		if state=="jump": motion.y=3
		if state=="attack": body.start_punch()
		if state=="pickup": body.contextual_pose.play("pickup")
		actor.position=Vector3.ZERO
		for frame in 120:
			actor.position+=Vector3(motion.x,0,motion.z)/60.0
			body.animate(1.0/60.0,motion,state!="jump",state=="crouch")
			camera.position=actor.position+Vector3(5,1.7,0);camera.look_at(actor.position+Vector3.UP*1.35)
			await get_tree().physics_frame
			if frame%15==0 and state in ["walk","run"]:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(out+phase+"_"+state+"_%03d.png"%frame)
		rows.append({"state":state,"height_scale":str(body.scale),"phase":body.phase,"hip_l":str(rig.get_bone_global_pose(rig.find_bone("thigh_l"))),"knee_l":str(rig.get_bone_global_pose(rig.find_bone("calf_l"))),"foot_l":str(rig.get_bone_global_pose(rig.find_bone("foot_l"))),"fps":Performance.get_monitor(Performance.TIME_FPS),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		for angle in [Vector3(0,1.7,-5),Vector3(0,1.7,5),Vector3(-5,1.7,0),Vector3(5,1.7,0)] if state=="walk" else [Vector3(5,1.7,0)]:
			camera.position=actor.position+angle;camera.look_at(actor.position+Vector3.UP*1.35)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out+phase+"_"+state+"_"+str(angle)+".png")
	var file=FileAccess.open(out+phase+"_animation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":rows,"bones":bones,"scope":"Isolated visual fixture; translated actor, procedural animation, physical floor. Not gameplay approval."},"\t"))
	var cadence=[]
	for speed in [2.5,5.5,6.6,0.0]:
		for i in 120: body.animate(1.0/60.0,Vector3(0,0,-speed),true,false)
		var before=body.phase
		body.animate(1.0/60.0,Vector3(0,0,-speed),true,false)
		var rate=fposmod(body.phase-before,TAU)*60.0
		var expected=8.75 if speed==2.5 else 10.0 if speed==5.5 else 12.0 if speed==6.6 else 0.0
		cadence.append({"speed":speed,"rad_per_second":rate,"expected":expected,"passed":absf(rate-expected)<0.01})
	var cadence_file=FileAccess.open(out+phase+"_cadence.json",FileAccess.WRITE);cadence_file.store_string(JSON.stringify(cadence,"\t"))
	print("FINAL70_ANIMATION_DONE ",phase)
