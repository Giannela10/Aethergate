extends SceneTree
const SAVE := "res://tests/nueva_partida_temporal.json"
const SCENE := "res://tests/nueva_partida_temporal.tscn"
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Escena de prueba que recarga sus propias rutas de guardado, nunca user://.
	var source = load("res://Main.tscn").instantiate()
	var config = source.get_node("CampusCampaign")
	config.save_path = SAVE
	config.set_meta("test_mode",true)
	source.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	var packed := PackedScene.new()
	check(packed.pack(source) == OK,"Preparar escena aislada")
	check(ResourceSaver.save(packed,SCENE) == OK,"Guardar escena aislada")
	source.free()
	var scene = load(SCENE).instantiate()
	root.add_child(scene)
	current_scene = scene
	var campaign = scene.get_node("CampusCampaign")
	while not campaign.ready_for_play:
		await process_frame
	campaign.ui.close_modal()
	campaign.player.receive_item("Botiquin")
	campaign.event("talk","Profesor")
	check(not campaign.phone.state.contacts.is_empty(),"La partida anterior tiene contactos")
	campaign.academics.state.attended = 3
	campaign.data.bosses.chef = true
	campaign.data.unlocks["8"] = true
	campaign.data.upgrades.Vida = 3
	campaign.data.credits = 777
	campaign.data.xp = 450
	campaign.player.stationery_notes = "Apuntes de la partida anterior"
	campaign.player.global_position = Vector3(25,35.9,-143)
	campaign.save_game()
	campaign.show_start_menu()
	campaign.ui.column.get_child(3).pressed.emit()
	check(campaign.ui.column.get_child(0).text == "NUEVA PARTIDA","Nueva partida abre confirmación")
	campaign.ui.column.get_child(2).pressed.emit()
	check(campaign.ui.column.get_child(0).text == "PERSONALIZACIÓN","Nueva partida permite elegir apariencia")
	campaign.appearance_menu._select(4,"skin")
	campaign.appearance_menu._select(1,"top")
	campaign.appearance_menu._confirm()
	var deadline := Time.get_ticks_msec()+20000
	while (current_scene == scene or current_scene == null) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(current_scene != scene and current_scene != null,"El botón recarga la escena")
	if current_scene != null and current_scene != scene:
		var fresh = current_scene.get_node("CampusCampaign")
		while not fresh.ready_for_play and Time.get_ticks_msec() < deadline:
			await process_frame
		check(fresh.ready_for_play,"Nueva partida termina de iniciar")
		check(fresh.data.appearance.skin == 4 and fresh.data.appearance.top == 1,"Apariencia seleccionada sobrevive al reinicio")
		check(fresh.data.bosses.is_empty(),"Se reinician los jefes")
		check(fresh.academics.state.attended == 0 and fresh.academics.state.missed == 0,"Se reinicia asistencia académica")
		check(fresh.phone.state.contacts.is_empty() and fresh.phone.state.messages.is_empty(),"Nueva partida reinicia celular")
		check(not fresh.floor_unlocked("8"),"Se reinician accesos")
		check(fresh.data.upgrades.is_empty() and fresh.data.xp == 0,"Se reinician mejoras y XP")
		check(fresh.data.credits == 30,"Solo conserva créditos iniciales")
		check(not fresh.player.inventory.has_item("Botiquin"),"Se vacía el inventario")
		check(fresh.player.stationery_notes.is_empty(),"Se vacían apuntes")
		check(Vector2(fresh.player.global_position.x,fresh.player.global_position.z).length() < 3,"Vuelve a la entrada: "+str(fresh.player.global_position))
		check(fresh.player.max_health == 100 and fresh.player.health == 100,"Vida inicial sin mejoras")
		check(fresh.quests.state("inicio") == 1 and not paused,"Primera misión activa y juego sin pausa")
		check(FileAccess.file_exists(SAVE+".bak"),"Conserva respaldo anterior")
		fresh.persist = false
		current_scene.queue_free()
		await process_frame
	for path in [SAVE,SAVE+".bak",SCENE]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("NEW_GAME_RESULT "+JSON.stringify({"failures":failures}))
	quit(0 if failures.is_empty() else 1)
