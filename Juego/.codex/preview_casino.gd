extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(900, 720)
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var player = scene.get_node("GameplayManager").player
	player.global_position = Vector3(-30, 0.1, -116.5)
	await create_timer(1.4).timeout
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(-30, 1.6, -114.6), Vector3(-34, 1.6, -114.6))
	query.exclude = [player.get_rid()]
	var hit := root.world_3d.direct_space_state.intersect_ray(query)
	print("CASINO_ENTRY_CLEAR ", hit.is_empty())
	for layer in scene.find_children("*", "CanvasLayer", true, false):
		layer.hide()
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.global_position = Vector3(-18, 5.7, -116.5)
	camera.look_at(Vector3(-32.338, 5.7, -116.5))
	camera.make_current()
	for i in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.codex/casino-entrada-corregida.png")
	var casino = scene.get_node("Piso1/Casino")
	print("CASINO_ALIGNMENT ", JSON.stringify({"door_axis":casino.get_node("EntradaVidrio").position.z,"sign_axis":casino.get_node("AcabadosEntradaLateral/Casino").position.z,"light_axis":casino.get_node("AcabadosEntradaLateral/LuzEntrada").position.z,"duplicate_hidden":not casino.get_node("Letrero").visible}))
	quit()
