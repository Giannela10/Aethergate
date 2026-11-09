extends Node3D
func _ready(): run.call_deferred()
func run():
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	var camera=Camera3D.new();camera.position=Vector3(0,5,14);add_child(camera);camera.look_at(Vector3(0,1,0));camera.make_current()
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-20,0);add_child(light)
	var player=Node3D.new();player.add_to_group("player");add_child(player)
	var bridge=load("res://scripts/juego/npc_visual_6_3.gd")
	var ids=[]
	for i in 30: ids.append("profiler63_"+str(i))
	bridge.config={"enabled":true,"batch":2,"pilot_ids":ids}
	var actors=[]
	for i in 30:
		var actor=Node3D.new();add_child(actor);actor.position=Vector3((i%6-2.5)*1.5,0,-float(i/6)*2)
		var visual=load("res://scripts/juego/student_visual.gd").new();visual.scale=Vector3.ONE*1.5;actor.add_child(visual)
		var presets=load("res://scripts/juego/character_visual_presets.gd");presets.apply(visual,presets.create("profiler63_"+str(i),"ESTUDIANTE"));actors.append(visual)
	for frame in 8: await get_tree().process_frame
	var report={"meshes":[],"timings":[]}
	for mesh in actors[0].human_visual63.model.human.find_children("*","MeshInstance3D",true,false):
		var vertices=0
		for surface in mesh.mesh.get_surface_count(): vertices+=mesh.mesh.surface_get_array_len(surface)
		report.meshes.append({"name":mesh.name,"vertices":vertices,"shapes":mesh.get_blend_shape_count(),"visible":mesh.visible})
	for phase in ["frozen","animated","hidden_animated"]:
		if phase=="hidden_animated":
			for actor in actors: actor.human_visual63.model.hide()
		var samples=[];var cpu=[]
		for i in 240:
			var begin=Time.get_ticks_usec()
			if phase!="frozen":
				for actor in actors: actor.animate(1.0/60,Vector3(0,0,-2.5),true,false)
			cpu.append((Time.get_ticks_usec()-begin)/1000.0)
			await get_tree().process_frame
			if i>=60: samples.append((Time.get_ticks_usec()-begin)/1000.0)
		samples.sort();cpu.sort()
		report.timings.append({"phase":phase,"frame_ms":samples[90],"cpu_ms":cpu[120]})
	var out=FileAccess.open("res://reports/characters_6_3/profile.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"\t"));out.close()
	print("PROFILE63_DONE ",JSON.stringify(report))
