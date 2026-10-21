extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1152, 720)
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var boss = scene.get_node("Piso2/Biblioteca/BossBibliotecaria")
	var player = scene.get_node("GameplayManager").player
	player.global_position = boss.global_position + Vector3(0, 0, 2)
	await physics_frame
	boss.interact(player)
	root.size = Vector2i(442, 355)
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.codex/bibliotecaria-centrada-pequena.png")
	root.size = Vector2i(1152, 720)
	for i in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.codex/bibliotecaria-dialogo.png")
	for i in range(3):
		if boss.answers[i].get_meta("correct"):
			boss._answer(i)
			break
	await create_timer(0.25, true).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.codex/bibliotecaria-dano.png")
	boss._close()
	quit()
