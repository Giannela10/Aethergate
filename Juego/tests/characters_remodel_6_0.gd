extends Node3D
const OUT := "res://reports/characters_6_0"
const Visual = preload("res://scripts/juego/student_visual.gd")
const Presets = preload("res://scripts/juego/character_visual_presets.gd")
var actors: Array = []
var camera: Camera3D
var phase := "before"
var rows: Array = []
var motion := Vector3.ZERO
var grounded := true
var crouching := false
func _ready() -> void:
	seed(600)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if FileAccess.file_exists(OUT+"/phase.txt"): phase = FileAccess.get_file_as_string(OUT+"/phase.txt").strip_edges()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("28333d")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.55
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35,-25,0)
	add_child(sun)
	camera = Camera3D.new()
	camera.fov = 45
	add_child(camera)
	camera.make_current()
	var player := Node3D.new()
	player.add_to_group("player")
	add_child(player)
	var model = Visual.new()
	player.add_child(model)
	actors.append(model)
	Presets.apply(model,Presets.create("student_preview","ESTUDIANTE"))
	print("CHARACTERS60_READY ",phase)
	run.call_deferred()
func _process(delta: float) -> void:
	for model in actors:
		model.animate(delta,motion,grounded,crouching)
func shot(label: String, at: Vector3, target: Vector3) -> void:
	camera.position = at
	camera.look_at(target)
	await get_tree().create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"/"+phase+"_"+label+".png")
func run() -> void:
	var model = actors[0]
	for pair in [["front",Vector3(0,1,-3.1)],["back",Vector3(0,1,3.1)],["left",Vector3(-3.1,1,0)],["right",Vector3(3.1,1,0)],["face",Vector3(0,1.57,-0.65)]]:
		await shot(pair[0],pair[1],Vector3(0,1.0 if pair[0]!="face" else 1.57,0))
	for role in ["PROFESOR","INGLES","LENGUAJE","ETICA","DIRECTOR","ENFERMERIA","ODONTOLOGIA","TALLER","GUARDIA","FUNCIONARIO","VENDEDOR"]:
		Presets.apply(model,Presets.create("preview_"+role,role))
		await shot(role,Vector3(1,1.3,-2.8),Vector3(0,1,0))
	for expression in ["NEUTRAL","HAPPY","SURPRISED","WORRIED"]:
		model.set_expression(expression)
		await shot("expression_"+expression,Vector3(0,1.57,-0.65),Vector3(0,1.57,0))
	model.set_expression("NEUTRAL")
	for count in [0,5,15,30]:
		while actors.size()<count+1:
			var i := actors.size()
			var actor := Node3D.new()
			actor.position = Vector3((i%7-3)*0.75,0,-float(i/7)*0.8)
			add_child(actor)
			var npc = Visual.new()
			actor.add_child(npc)
			Presets.apply(npc,Presets.create("benchmark_"+str(i),"ESTUDIANTE"))
			actors.append(npc)
		camera.position = Vector3(0,2.8,-8)
		camera.look_at(Vector3(0,0.9,-1.4))
		await get_tree().create_timer(1.5).timeout
		var samples: Array = []
		var last := Time.get_ticks_usec()
		for i in 90:
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			samples.append({"ms":float(now-last)/1000,"fps":Performance.get_monitor(Performance.TIME_FPS),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
			last=now
		rows.append({"npc":count,"samples":samples})
		await shot("population_"+str(count),camera.position,Vector3(0,0.9,-1.4))
	var file := FileAccess.open(OUT+"/"+phase+"_performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(rows,"\t"))
	file.close()
	if phase=="after":
		for i in range(1,actors.size()): actors[i].get_parent().hide()
		for expression in ["FOCUSED","PAIN","VICTORY"]:
			model.set_expression(expression)
			await shot("expression_"+expression,Vector3(0,1.57,-0.65),Vector3(0,1.57,0))
		model.set_expression("NEUTRAL")
		var profile := Presets.create("wardrobe_student","ESTUDIANTE")
		profile.hair=0
		for face in 4:
			profile.face=face
			Presets.apply(model,profile)
			await shot("face_"+str(face),Vector3(0,1.57,-0.65),Vector3(0,1.57,0))
		for top in 7:
			profile.top=top
			Presets.apply(model,profile)
			await shot("wardrobe_"+str(top),Vector3(1,1.3,-2.8),Vector3(0,1,0))
		for state in ["WALK","RUN","JUMP","FALL","CROUCH","LAND"]:
			motion=Vector3(0,0,2.5 if state=="WALK" else 5.5 if state=="RUN" else 0)
			grounded=state not in ["JUMP","FALL"]
			crouching=state=="CROUCH"
			if not grounded: motion.y=4 if state=="JUMP" else -4
			await shot("motion_"+state,Vector3(1,1.3,-2.8),Vector3(0,1,0))
		motion=Vector3.ZERO; grounded=true; crouching=false
		for action in ["GREET","EXPLAIN","CELEBRATE","PHONE","TYPE","READ"]:
			model.set_visual_activity(action,"TABLET" if action in ["EXPLAIN","TYPE"] else "BOOK" if action=="READ" else "PHONE" if action=="PHONE" else "NONE")
			await shot("social_"+action,Vector3(1,1.3,-2.8),Vector3(0,1,0))
	print("CHARACTERS60_DONE ",phase)
