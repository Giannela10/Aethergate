extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,900)
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var library: Node3D = scene.get_node("Piso2/Biblioteca")
	var boss = library.get_node("BossBibliotecaria")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.7
	var all_clear := true
	for p in [Vector3(-66.5,1.48,-115.5),Vector3(-68.1,1.48,-115.5),Vector3(-69.5,1.48,-115.5),Vector3(-53.5,1.48,-120),Vector3(-53.5,1.48,-115),Vector3(-53.5,1.48,-100)]:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY,library.to_global(p))
		var hits := root.world_3d.direct_space_state.intersect_shape(query)
		print("BIBLIOTECA_PASO_LIBRE=",hits.is_empty()," POS=",p)
		if not hits.is_empty():
			all_clear = false
			print("OBSTACULO=",hits[0].collider.get_path())
	print("BIBLIOTECA_INTERACCION_ACCESIBLE=",boss.position.distance_to(Vector3(-61.5,0.05,-119.85)) < boss.interaction_range)
	if DisplayServer.get_name() == "headless":
		quit(0 if all_clear else 1)
		return
	for layer in scene.find_children("*","CanvasLayer",true,false):
		layer.hide()
	var camera := Camera3D.new()
	camera.fov = 73
	scene.add_child(camera)
	camera.make_current()
	for view in [[Vector3(-54,3.1,-120.5),Vector3(-62,1.8,-115.5),"meson"],[Vector3(-53.5,2.5,-109.5),Vector3(-69,1.7,-94),"interior"],[Vector3(-71,3,-112.5),Vector3(-62,1.4,-115.5),"abertura"]]:
		camera.position = library.to_global(view[0])
		camera.look_at(library.to_global(view[1]))
		for i in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.codex/biblioteca-"+view[2]+"-referencia.png")
	print("BIBLIOTECA_CAPTURAS_OK=true")
	quit(0 if all_clear else 1)
