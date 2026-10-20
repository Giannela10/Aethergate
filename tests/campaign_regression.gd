extends SceneTree
var failures: Array[String] = []
var scene: Node
var campaign: Node
var player: CharacterBody3D

func check(condition: bool, title: String) -> void:
	if not condition:
		failures.append(title)
		push_error(title)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	scene = load("res://Main.tscn").instantiate()
	campaign = scene.get_node("CampusCampaign")
	campaign.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene)
	current_scene = scene
	while not campaign.ready_for_play:
		await process_frame
	while get_nodes_in_group("boss_duel").any(func(duel): return not duel.initialized):
		await process_frame
	player = campaign.player
	campaign.show_pause()
	var guide_button := campaign.ui.column.get_child(3) as Button
	guide_button.pressed.emit()
	check(campaign.ui.column.get_child(0).text == "GUÍA DE JUEGO","Abrir guía desde señal pressed")
	var back_button := campaign.ui.column.get_child(campaign.ui.column.get_child_count()-1) as Button
	back_button.pressed.emit()
	check(campaign.ui.column.get_child(0).text == "PAUSA","Volver sin liberar el botón que emite la señal")
	campaign.ui.close_modal()
	player.set_physics_process(false)
	for enemy in campaign.find_children("*","CharacterBody3D",true,false):
		enemy.set_physics_process(false)
	check(campaign.implementation_phase == 10,"Todas las fases integradas")
	check(load("res://scripts/campaign/campus_content.gd").weapon_manifest.size() == 51,"51 armas distribuidas")
	var cards := 0
	var invalid: Array = []
	for node in campaign.get_children():
		if str(node.name).begins_with("Tarjeta_"):
			cards += 1
		if node.has_meta("placement_validated") and not node.get_meta("placement_validated"):
			invalid.append(str(node.name))
	check(cards == 20,"20 tarjetas físicas")
	check(invalid.is_empty(),"Contenido con suelo y espacio transitable: "+str(invalid))
	check(campaign.quests.definitions.size() >= 14,"Campaña y secundarias definidas")
	check(not campaign.floor_unlocked("8"),"Ascensor avanzado bloqueado")
	check(get_nodes_in_group("health_station").size() == 12,"Doce centros de vida distribuidos")
	var station := campaign.get_node("CentroVida_Piso1")
	player.global_position = station.global_position+Vector3(0.8,0,0)
	await physics_frame
	player.health = 15.0
	var station_credits: int = campaign.data.credits
	station.interact(player)
	check(player.health == player.max_health and campaign.data.credits == station_credits,"Centro cura completamente y gratis")
	check(campaign.data.checkpoint.id == str(station.name) and campaign.data.checkpoint.health == player.max_health,"Centro guarda reaparición con vida completa")
	player.health = 30.0
	station.interact(player)
	check(player.health == player.max_health,"Centro de vida reutilizable")
	player.global_position = station.global_position+Vector3(10,0,0)
	player.health = 30.0
	station.interact(player)
	check(player.health == 30.0,"No cura a distancia")
	var chair_pickup: Node3D
	var interaction := player.get_node("InteractionController")
	for candidate in get_nodes_in_group("campus_chair"):
		if chair_pickup != null:
			break
		for offset in [Vector3(1.4,0,0),Vector3(0,0,1.4),Vector3(-1.4,0,0)]:
			player.global_position = candidate.global_position+offset
			await physics_frame
			interaction.scan()
			if interaction.selected != null and interaction.selected.is_in_group("campus_chair"):
				chair_pickup = interaction.selected
				break
	check(chair_pickup != null,"Sillas del escenario accesibles mediante E")
	var chair_id := ""
	if chair_pickup != null:
		chair_id = chair_pickup.world_id
		var chair_count: int = player.inventory.count_item("Silla")
		interaction.interact_selected()
		await physics_frame
		check(player.inventory.count_item("Silla") == chair_count+1 and player.weapon.kind == "silla","E recoge y equipa la silla para atacar")
		check(chair_pickup.collected and not chair_pickup.furniture.visible,"Silla recogida desaparece del escenario")
		for node in chair_pickup.furniture.find_children("*","CollisionObject3D",true,false):
			check(node.collision_layer == 0,"Sin colisiones invisibles de la silla")
		chair_pickup.interact(player)
		check(player.inventory.count_item("Silla") == chair_count+1,"No duplica la silla al interactuar otra vez")
	check(get_nodes_in_group("campus_chair").size() > 20,"Mobiliario del campus disponible como arma")
	var funcionario := campaign.get_node("Funcionario")
	funcionario._accept()
	check(not campaign.data.unlocks.get("provided:documentos",false),"Funcionario no bloquea entrega del profesor")
	campaign.get_node("Profesor").interact(player)
	campaign.ui.close_modal()
	check(player.inventory.has_item("Documentos"),"Profesor entrega documentos tras hablar primero con funcionario")
	check(campaign.get_node("Tarjeta_17").global_position.distance_to(campaign.get_node("Tarjeta_19").global_position) > 1.0,"Tarjetas 17 y 19 separadas")
	check(campaign.get_node("Tarjeta_18").global_position.distance_to(campaign.get_node("Tarjeta_20").global_position) > 1.0,"Tarjetas 18 y 20 separadas")
	for duel in get_nodes_in_group("boss_duel"):
		check(duel.state == duel.DuelState.NEUTRAL,"Boss neutral: "+duel.boss_id)
		var hp: float = duel.actor.health
		if duel.actor.has_method("take_hit"):
			duel.actor.take_hit(Vector3.ZERO,10000)
		check(duel.actor.health == hp,"Inmunidad neutral: "+duel.boss_id)
		check(not duel.actor.is_physics_processing(),"IA apagada neutral")
	var chef := scene.get_node("Piso1/Casino/ChefSupremoCasino/BossDuelController")
	player.global_position = chef.actor.global_position+Vector3(3,0,0)
	chef.interact(player)
	check(chef.state == chef.DuelState.DIALOGUE and player.busy,"Diálogo del boss")
	chef.decline()
	check(chef.state == chef.DuelState.NEUTRAL and not player.busy,"Ahora no deja neutral")
	chef.interact(player)
	chef.intro_duration = 0.1
	chef.accept()
	await create_timer(0.7).timeout
	check(chef.state == chef.DuelState.COMBAT and chef.allows_damage(),"Aceptación inicia combate")
	chef.actor.set_physics_process(false)
	player.health = 23.0
	chef.actor.take_hit(Vector3.ZERO,10000)
	check(player.health == player.max_health,"Vencer al boss recupera toda la vida")
	await create_timer(1.1).timeout
	check(chef.actor.body.death_t == 1.0 and chef.actor.body.fall_pivot.rotation.x > 1.5,"Boss termina la animación de caída")
	check(campaign.data.bosses.get("chef",false),"Victoria registrada")
	check(player.inventory.has_item("BandejaDelChef"),"Arma única Chef")
	var credits: int = campaign.data.credits
	campaign.boss_won(chef)
	check(campaign.data.credits == credits and player.inventory.count_item("BandejaDelChef") == 1,"Recompensa única")
	var npc := campaign.get_node("Auxiliar")
	npc._accept()
	player.receive_item("LlavesPerdidas")
	npc._deliver()
	check(campaign.quests.state("llaves") == 2 and player.inventory.has_item("Botiquin"),"Misión secundaria completa y recompensa")
	check(not player.inventory.has_item("LlavesPerdidas"),"Entrega consume solo objeto solicitado")
	campaign.quests.start_quest("documentos")
	var professor := campaign.get_node("Profesor")
	professor.interact(player)
	campaign.ui.close_modal()
	check(player.inventory.has_item("Documentos"),"Documentos disponibles aunque se acepte en otro NPC")
	campaign.get_node("Funcionario")._deliver()
	check(player.has_key_item("TarjetaAcceso"),"Recompensa TarjetaAcceso")
	var gate := scene.get_node("Piso7/PasilloReferencia/Sala805/PuertaSala/CampaignAccess")
	gate.interact(player)
	check(gate.unlocked and campaign.data.unlocks.get("door:acceso7",false),"Puerta con objeto conserva desbloqueo")
	check(player.has_key_item("TarjetaAcceso"),"No consumir credencial")
	var card := campaign.get_node("Tarjeta_01")
	player.global_position = card.global_position+Vector3(0.7,0,0)
	await physics_frame
	card.interact(player)
	var amount: int = campaign.data.cards.size()
	card.interact(player)
	check(amount == 1 and campaign.data.cards.size() == 1,"Tarjeta no duplicable")
	var quiz := scene.get_node("Piso2/Biblioteca/BossBibliotecaria/BossDuelController")
	# Approach the front of the existing desk; the side can be occluded by furniture.
	player.global_position = quiz.actor.global_position+Vector3(0,0,2)
	quiz.interact(player)
	quiz.intro_duration = 0.1
	quiz.accept()
	# Wait for the actual intro transition; a wall-clock delay is unreliable under headless load.
	var quiz_deadline := Time.get_ticks_msec() + 5000
	while not quiz.actor.active and Time.get_ticks_msec() < quiz_deadline:
		await process_frame
	check(quiz.actor.active and paused,"Bibliotecaria conserva duelo de preguntas")
	for i in 5:
		var correct := 0
		for index in quiz.actor.answers.size():
			if quiz.actor.answers[index].get_meta("correct"):
				correct = index
		quiz.actor._answer(correct)
		quiz.actor._next()
	await process_frame
	await process_frame
	check(not paused and campaign.data.bosses.get("bibliotecaria",false),"Preguntas ganan duelo y restauran pausa")
	var inventory_before: Dictionary = player.inventory.snapshot_data().duplicate(true)
	campaign.data.checkpoint = {"id":"Prueba","position":[25,35.9,-143],"health":80}
	player.take_hit(Vector3.ZERO,10000)
	await process_frame
	await process_frame
	check(player.dead and campaign.ui.modal,"Pantalla de muerte")
	campaign.respawn()
	check(not player.dead and player.health == 80 and not paused,"Reaparición sin recargar mapa")
	check(player.inventory.entries.size() == inventory_before.entries.size(),"Muerte no pierde objetos")
	var combat := player.get_node("CombatExtensions")
	combat.stamina = 100
	check(combat.dodge(),"Esquiva disponible")
	var hp: float = player.health
	player.take_hit(Vector3.ZERO,20)
	check(player.health == hp,"Invulnerabilidad breve en esquiva")
	combat.dodge_t = 0
	check(not combat.dodge(),"Enfriamiento evita esquiva infinita")
	var old_credits: int = campaign.data.credits
	campaign.grant_reward({"credits":20,"xp":30},"test_reward")
	campaign.grant_reward({"credits":20,"xp":30},"test_reward")
	check(campaign.data.credits == old_credits+20,"Recompensas idempotentes")
	var vendor: Node
	for child in campaign.get_children():
		if child.get_script() == load("res://scripts/campaign/campus_vendor.gd"):
			vendor = child
			break
	campaign.data.credits = 100
	var count: int = player.inventory.count_item("Bebida")
	vendor._buy("Bebida")
	campaign.ui.close_modal()
	check(player.inventory.count_item("Bebida") == count+1 and campaign.data.credits == 95,"Compra descuenta créditos")
	campaign.save_path = "res://tests/campaign_temporal.json"
	campaign.persist = true
	campaign.save_game()
	var saved = JSON.parse_string(FileAccess.get_file_as_string(campaign.save_path))
	check(saved.credits == 95 and saved.bosses.chef and saved.cards.has("Tarjeta_01"),"Guardado extendido")
	check(saved.inventory.entries.size() == player.inventory.entries.size() and saved.checkpoint.id == "Prueba","Guardado de inventario y checkpoint")
	campaign.persist = false
	var path: String = campaign.save_path
	scene.queue_free()
	await process_frame
	var reloaded = load("res://Main.tscn").instantiate()
	var restored = reloaded.get_node("CampusCampaign")
	restored.set_meta("test_mode",true)
	restored.save_path = path
	reloaded.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(reloaded)
	current_scene = reloaded
	while not restored.ready_for_play:
		await process_frame
	check(restored.data.credits == 95,"Créditos conservados al cargar JSON")
	check(restored.player.inventory.has_item("BandejaDelChef"),"Arma única restaurada")
	var restored_chef: Node = reloaded.get_node("Piso1/Casino/ChefSupremoCasino/BossDuelController")
	while not restored_chef.initialized:
		await process_frame
	check(restored_chef.actor.dead and restored_chef.actor.body.death_t == 1.0,"Boss sigue caído al cargar partida")
	check(restored.player.global_position.distance_to(Vector3(saved.position[0],saved.position[1]+0.15,saved.position[2])) < 0.5,"Posición conservada al cargar")
	check(not restored.get_node("Tarjeta_01").visible,"Tarjeta recogida no reaparece")
	var chair_restored := false
	for pickup in get_nodes_in_group("campus_chair"):
		if pickup.world_id == chair_id:
			chair_restored = pickup.collected and not pickup.furniture.visible
	check(chair_restored,"Silla del escenario permanece recogida al cargar")
	restored.ui.close_modal()
	restored.persist = false
	reloaded.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CAMPAIGN_REGRESSION "+JSON.stringify({"passed":failures.is_empty(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
