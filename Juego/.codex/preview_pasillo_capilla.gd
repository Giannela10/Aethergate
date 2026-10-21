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
	var query := PhysicsRayQueryParameters3D.create(Vector3(65,1.8,-141),Vector3(65,1.8,-146))
	var hit := root.world_3d.direct_space_state.intersect_ray(query)
	print("CAPILLA_ENTRADA_LIBRE=",hit.is_empty())
	if not hit.is_empty():
		print("CAPILLA_OBSTACULO=",hit.collider.get_path()," POS=",hit.position)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.fov = 70
	camera.position = Vector3(35,2.8,-137)
	camera.look_at(Vector3(70,2.4,-141))
	camera.make_current()
	for i in range(12):
		await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.codex/pasillo-derecho-referencia.png")
	camera.position = Vector3(65,3.0,-145)
	camera.look_at(Vector3(69,2.7,-152))
	for i in range(12):
		await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.codex/capilla-referencia.png")
	print("CAPILLA_PREVIEW_OK")
	quit()
