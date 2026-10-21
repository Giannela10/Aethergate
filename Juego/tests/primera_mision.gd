extends SceneTree
var failures: Array[String] = []
var scene: Node
var campaign: Node
var player: CharacterBody3D

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

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
	player.set_physics_process(false)
	var punto := scene.get_node("Piso1/SalaAyudaEstudiantil/BossAyudaEstudiantil/BossDuelController")
	check(campaign.quests.state("inicio") == 1,"Primer día activa al comenzar")
	campaign.guidance._process(1.0)
	check(campaign.guidance.target == punto.actor,"Marcador inicial identifica al Encargado")
	check(punto.identity_label.text.contains("Encargado"),"Encargado identificado por su nombre")
	player.global_position = punto.actor.global_position+Vector3(0,0,1.6)
	await physics_frame
	await physics_frame
	check(player._can_reach(punto.interaction_target()),"El propio cuerpo del Encargado no bloquea hablar")
	var interaction := player.get_node("InteractionController")
	interaction.scan()
	check(interaction.selected == punto,"Acción contextual E selecciona al Encargado")
	interaction.interact_selected()
	check(punto.state == punto.DuelState.DIALOGUE,"E abre el diálogo inicial")
	punto.decline()
	check(campaign.events.get("talk:punto",0) == 1,"Hablar cumple el primer objetivo")
	var item := campaign.get_node("Arma_00")
	player.global_position = item.global_position+Vector3(0.7,0,0)
	await physics_frame
	item.interact(player)
	check(campaign.quests.progress({"kind":"collect","id":"*","amount":1}) == 1,"Recoger cuenta para Primer día")
	var pc := campaign.get_node("pc_intro")
	player.global_position = pc.global_position+Vector3(0,0,1.6)
	await physics_frame
	interaction.scan()
	check(interaction.selected == pc,"Computador inicial accesible mediante E")
	interaction.interact_selected()
	check(campaign.manager.current_computer == pc,"E inicia el computador correcto")
	# Completar el resultado del minijuego mediante su señal real.
	campaign.manager.minigame.close(true)
	check(campaign.data.computers.get("pc_intro",false),"Computador cuenta para la misión")
	for duel in [punto,scene.get_node("Piso1/Casino/ChefSupremoCasino/BossDuelController")]:
		player.global_position = duel.actor.global_position+Vector3(1.6,0,0)
		duel.interact(player)
		duel.intro_duration = 0.1
		duel.accept()
		await create_timer(0.7).timeout
		duel.actor.set_physics_process(false)
		duel.actor.take_hit(Vector3.ZERO,10000)
	check(campaign.quests.state("inicio") == 2,"Primer día se puede completar")
	check(campaign.floor_unlocked("2"),"Victoria habilita ascensor al piso 2")
	check(campaign.quests.state("biblioteca") == 1,"Se activa la siguiente misión")
	campaign.events.erase("talk:punto")
	check(campaign.quests.progress({"kind":"talk","id":"punto","amount":1}) == 1,"Partidas antiguas no exigen hablar con boss ya derrotado")
	scene.queue_free()
	await process_frame
	print("FIRST_MISSION_RESULT "+JSON.stringify({"failures":failures}))
	quit(0 if failures.is_empty() else 1)
