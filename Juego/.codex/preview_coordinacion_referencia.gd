extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,900)
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	for layer in scene.find_children("*","CanvasLayer",true,false):
		layer.hide()
	for segment in [[Vector3(71,1.8,-125),Vector3(71,1.8,-112)],[Vector3(70.2,1.8,-111),Vector3(70.2,1.8,-103)]]:
		var query := PhysicsRayQueryParameters3D.create(segment[0],segment[1])
		var hit := root.world_3d.direct_space_state.intersect_ray(query)
		print("COORDINACION_PASO_LIBRE=",hit.is_empty())
		if not hit.is_empty():
			print("OBSTACULO=",hit.collider.get_path()," POS=",hit.position)
	var coordination: Node3D = scene.get_node("Piso1/InteriorCoordinacion")
	assert(coordination.get_node("PisoCoordinacion").position.is_equal_approx(Vector3(58,0.02,-107.55)))
	assert(coordination.get_node("TechoCoordinacion").position.is_equal_approx(Vector3(58,4.99,-107.55)))
	print("COORDINACION_SUELO_TECHO_OK=true")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.7
	for p in [Vector3(71,1.1,-120),Vector3(71,1.1,-115),Vector3(70.2,1.1,-108),Vector3(70.2,1.1,-104)]:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY,p)
		var obstacles := root.world_3d.direct_space_state.intersect_shape(query)
		print("COORDINACION_ESPACIO_JUGADOR=",obstacles.is_empty()," POS=",p)
	if DisplayServer.get_name() == "headless":
		quit()
		return
	var camera := Camera3D.new()
	camera.fov = 73
	scene.add_child(camera)
	camera.make_current()
	for view in [[Vector3(74,2.3,-131),Vector3(70,2.2,-120),"entrada"],[Vector3(71,2.25,-120.5),Vector3(71,1.8,-110),"recepcion"],[Vector3(58,2.2,-107.8),Vector3(48,1.8,-103.5),"oficinas"]]:
		camera.position = view[0]
		camera.look_at(view[1])
		for i in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.codex/coordinacion-"+view[2]+"-referencia.png")
	print("COORDINACION_CAPTURAS_OK=true")
	quit()
