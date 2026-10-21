extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var boss = scene.get_node("Piso2/Biblioteca/BossBibliotecaria")
	var player = scene.get_node("GameplayManager").player
	player.global_position = boss.global_position + Vector3(0, 0, 2)
	await physics_frame
	boss.interact(player)
	check(boss.active and paused and player.busy, "duel did not start at library desk")
	check(boss.duel_camera.current, "dialogue camera not active")
	check(boss.boss_bar.value == 125.0 and boss.player_bar.value == 100.0, "initial health bars")
	check(not boss.hidden_layers.is_empty(), "gameplay HUD was not hidden")
	if not boss.active:
		print("LIBRARIAN_RESULT ", failures)
		quit(1)
		return
	var wrong := 0
	for i in range(3):
		if not boss.answers[i].get_meta("correct"):
			wrong = i
	boss._answer(wrong)
	check(player.health == 75.0 and boss.health == 125.0, "wrong answer damage")
	check(boss.reply_text.text.begins_with("TÚ:"), "chosen answer missing from dialogue")
	await create_timer(0.75, true).timeout
	check(is_equal_approx(boss.player_bar.value, 75.0), "player health animation did not finish while paused")
	boss._answer(wrong)
	check(player.health == 75.0, "double answer dealt extra damage")
	boss._close()
	check(not paused and not player.busy, "closing did not restore controls")
	boss.interact(player)
	var seen: Array[String] = []
	for turn in range(5):
		var question: String = boss.current_question[1]
		check(not seen.has(question), "repeated question")
		seen.append(question)
		for i in range(3):
			if boss.answers[i].get_meta("correct"):
				boss._answer(i)
				break
		if turn < 4:
			if turn == 0:
				check(boss.damage_number.visible, "floating damage missing")
				await create_timer(0.75, true).timeout
				check(is_equal_approx(boss.boss_bar.value, 100.0), "boss health animation did not finish while paused")
			boss._next()
	check(boss.defeated and boss.resolved and boss.health == 0, "victory not resolved")
	check(player.health == 75.0, "correct answer hurt player")
	boss._next()
	check(not paused and not player.busy and not boss.active, "victory did not release controls")
	boss.interact(player)
	check(not boss.active, "defeated boss restarted")
	# A fresh encounter covers lethal mistakes and the exit after defeat.
	var second = load("res://scripts/pisos/piso_2/boss_bibliotecaria.gd").new()
	scene.add_child(second)
	second.global_position = player.global_position + Vector3(0, 0, 2)
	await physics_frame
	second.interact(player)
	check(second.active, "second duel failed to start")
	if second.active:
		for turn in range(3):
			for i in range(3):
				if not second.answers[i].get_meta("correct"):
					second._answer(i)
					break
			if turn < 2:
				second._next()
		check(player.dead and second.resolved, "player death not resolved")
		second._next()
		check(not paused and not player.busy, "death did not release pause")
	print("LIBRARIAN_RESULT ", JSON.stringify({"failures": failures, "questions": seen.size(), "victory": boss.defeated, "player_death": player.dead}))
	quit(0 if failures.is_empty() else 1)
