extends Node3D
func read_glb(file: String) -> Node:
	var doc=GLTFDocument.new()
	var state=GLTFState.new()
	var err=doc.append_from_file("res://assets/characters/main_6_2/source/"+file+".glb",state)
	print("GLTF_IMPORT ",file," ",err)
	return doc.generate_scene(state)
func _ready() -> void:
	var body=read_glb("base_body_anim")
	add_child(body)
	var rig: Skeleton3D=body.find_children("*","Skeleton3D",true,false)[0]
	for file in ["clothing_hoodie","clothing_jeans","clothing_shoes","hair_short04"]:
		var part=read_glb(file)
		add_child(part)
		for mesh in part.find_children("*","MeshInstance3D",true,false):
			mesh.reparent(body,true)
			mesh.skeleton=mesh.get_path_to(rig)
		part.queue_free()
	for mesh in body.find_children("*","MeshInstance3D",true,false):
		for i in mesh.get_blend_shape_count(): mesh.set_blend_shape_value(i,0)
		var male=mesh.find_blend_shape_by_name("gender_male")
		if male>=0: mesh.set_blend_shape_value(male,1)
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("29323e")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE
	env.environment.ambient_light_energy=0.6
	add_child(env)
	var key=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-30,-35,0)
	add_child(key)
	var camera=Camera3D.new()
	add_child(camera)
	camera.position=Vector3(0,1.1,3.5)
	camera.look_at(Vector3(0,0.9,0))
	camera.fov=38
	camera.make_current()
	var anim=body.find_children("*","AnimationPlayer",true,false)[0]
	print("CANDIDATE62 ",rig.get_path()," ",anim.get_animation_list())
	anim.play("idle")
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/main_character_6_2/candidate_front.png")
	var rows=[]
	for i in rig.get_bone_count(): rows.append({"i":i,"name":rig.get_bone_name(i),"parent":rig.get_bone_parent(i),"rest":str(rig.get_bone_global_rest(i))})
	var f=FileAccess.open("res://reports/main_character_6_2/rig.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"\t"))
