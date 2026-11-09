extends Node3D
var model: Node3D
var motion:=Vector3.ZERO
var grounded:=true
var crouching:=false
func _ready() -> void:
	add_to_group("player")
	model=load("res://scripts/juego/main_character_visual_6_2.gd").new()
	add_child(model)
	model.apply_appearance(preload("res://scripts/juego/character_appearance.gd").normalize({"top":1,"bottom_style":1,"backpack":1,"backpack_color":5,"pants":0,"shoes":6}))
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("29323e")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE
	env.environment.ambient_light_energy=0.55
	add_child(env)
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-35,-145,0)
	add_child(light)
	var camera=Camera3D.new()
	add_child(camera)
	camera.position=Vector3(0,1.1,-3.6)
	camera.look_at(Vector3(0,0.95,0))
	camera.fov=38
	camera.make_current()
	for entry in [["idle",0.0],["walk",2.5],["run",5.5]]:
		motion=Vector3(0,0,-entry[1])
		await get_tree().create_timer(1).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://reports/main_character_6_2/skinned_"+entry[0]+".png")
	for state in ["crouch","jump","attack","computer","pickup"]:
		motion=Vector3(0,3,0) if state=="jump" else Vector3.ZERO
		grounded=state!="jump"
		crouching=state=="crouch"
		if state=="attack": model.start_punch()
		if state in ["computer","pickup"]: model.play_context_action(state)
		await get_tree().create_timer(0.22).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://reports/main_character_6_2/skinned_"+state+".png")
	print("SKINNED62_DONE")
func _process(delta: float) -> void:
	if is_instance_valid(model): model.animate(delta,motion,grounded,crouching)
