class_name TestProfesorRedes
extends Node
## Escena aislada de verificación. Nunca lee ni escribe el guardado del jugador.
var failures: Array[String] = []
var campus: Node
var campaign: Node
var boss: Node
var duel: Node
var player: CharacterBody3D
var checks := 0
@export var preview := false

func check(condition: bool, text: String) -> void:
	checks += 1
	if not condition:
		failures.append(text)
		push_error(text)

func _ready() -> void:
	call_deferred("run")

func _wait_boot(scene: Node) -> Node:
	var c := scene.get_node("CampusCampaign")
	var deadline := Time.get_ticks_msec()+20000
	while not c.ready_for_play and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	while scene.get_node("Piso3/EncuentroProfesorRedes/ProfesorRedes/BossDuelController").initialized != true and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return c

func _new_campus() -> Node:
	var scene = load("res://Main.tscn").instantiate()
	scene.get_node("CampusCampaign").persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(scene)
	return scene

func run() -> void:
	campus = _new_campus()
	campaign = await _wait_boot(campus)
	boss = campus.get_node("Piso3/EncuentroProfesorRedes/ProfesorRedes")
	duel = boss.get_node("BossDuelController")
	player = campaign.player
	if preview:
		player.global_position = boss.global_position+Vector3(-3,0,0)
		campaign.manager.cam_yaw = -PI/2
		campaign.manager.cam_dist = 7.0
		print("REDES_PREVIEW · prueba aislada sin guardado · E para desafiar")
		return
	player.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
	check(boss.get_parent().placement_valid,"Arena y routers con suelo y espacio")
	if not boss.get_parent().placement_valid:
		get_tree().quit(1)
		return
	print("REDES_POSITIONS ",boss.global_position," routers=",boss.routers.map(func(r): return [str(r.name),r.global_position,r.get_meta("network_placement_valid",false)]))
	check(duel.state == duel.DuelState.NEUTRAL and not boss.is_physics_processing(),"Boss neutral sin IA")
	check(boss.phase == 0 and boss.active_routers() == 0,"Neutral sin fases ni routers activos")
	var hp: float = boss.health
	boss.take_hit(Vector3.ZERO,1000)
	boss._on_punch_landed(0)
	boss.network_pulse()
	boss.create_interference()
	boss.start_connection_loss()
	check(boss.health == hp and boss.projectiles.is_empty() and boss.effects.is_empty(),"Neutral inmune y sin ataques")
	player.global_position = boss.global_position+Vector3(1.7,0,0)
	await get_tree().physics_frame
	var interaction := player.get_node("InteractionController")
	interaction.scan()
	check(interaction.selected == duel,"E selecciona Profesor de Redes")
	interaction.interact_selected()
	check(duel.state == duel.DuelState.DIALOGUE,"E abre diálogo")
	check(campaign.ui.column.get_child(2).text == "Iniciar desafío","Botón solicitado")
	campaign.ui.column.get_child(3).pressed.emit()
	check(duel.state == duel.DuelState.NEUTRAL and not player.busy and boss.active_routers() == 0,"Ahora no mantiene neutralidad")
	duel.interact(player)
	duel.intro_duration = 0.1
	duel.accept()
	await get_tree().create_timer(0.7).timeout
	boss.set_physics_process(false)
	check(boss.combat_active() and boss.phase == 1 and boss.active_routers() == 3,"Aceptar activa combate y tres routers")
	hp = boss.health
	boss.take_hit(Vector3.ZERO,100)
	check(is_equal_approx(boss.health,hp-30),"Tres routers reducen daño 70%")
	player.global_position = boss.global_position+Vector3(3,0,0)
	player.health = player.max_health
	await get_tree().physics_frame
	hp = player.health
	boss.packet_pending = true
	boss._on_punch_landed(0)
	check(boss.projectiles.size() == 1,"Paquete de datos sale durante combate")
	await get_tree().create_timer(0.6).timeout
	check(player.health < hp,"Proyectil digital golpea con colisión barrida")
	hp = player.health
	boss.network_pulse()
	check(player.health < hp,"Pulso cercano causa daño")
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(0.2,3,2.5)
	collision.shape = wall_shape
	wall.add_child(collision)
	boss.get_parent().add_child(wall)
	wall.global_position = boss.global_position+Vector3(1.5,1.3,0)
	await get_tree().physics_frame
	hp = player.health
	boss.network_pulse()
	check(player.health == hp,"Pared bloquea daño de onda")
	wall.queue_free()
	await get_tree().physics_frame
	var router: Node3D = boss.routers[0]
	player.global_position = router.global_position+Vector3(0,0,1.4)
	await get_tree().physics_frame
	interaction.scan()
	check(interaction.selected == router,"E selecciona Router_A")
	interaction.interact_selected()
	check(boss.active_routers() == 2 and is_equal_approx(boss.damage_factor(),0.5),"Desconectar router cambia reducción a 50%")
	router.interact(player)
	check(boss.active_routers() == 2,"Router desactivado no se desconecta dos veces")
	boss.routers[1].set_active(false)
	check(is_equal_approx(boss.damage_factor(),0.75),"Un router reduce daño 25%")
	boss.routers[2].set_active(false)
	check(boss.damage_factor() == 1.0,"Sin routers recibe daño completo")
	boss.take_hit(Vector3.ZERO,180)
	check(boss.phase == 2,"Transición al 65%")
	check(boss.try_reconnect() and boss.active_routers() == 1,"Fase 2 reconecta un router")
	boss.routers[0].set_active(false)
	check(not boss.try_reconnect(),"Solo una reconexión por duelo")
	player.global_position = boss.global_position+Vector3(3,0,0)
	player.health = player.max_health
	var original_speed: float = player.progression_speed
	boss.create_interference()
	check(boss.effects.size() > 0,"Interferencia crea zona")
	boss.effects.back().call("_physics_process",0.21)
	check(is_equal_approx(player.progression_speed,original_speed*0.6),"Ralentización reutiliza estados")
	for effect in boss.effects:
		effect.set_physics_process(false)
	await get_tree().create_timer(1.2).timeout
	check(is_equal_approx(player.progression_speed,original_speed),"Ralentización termina")
	boss.take_hit(Vector3.ZERO,190)
	check(boss.phase == 3,"Transición bajo 30%")
	boss.start_connection_loss()
	check(boss.connection_charge > 0 and is_instance_valid(boss.warning_disc),"Pérdida de conexión se anuncia")
	hp = player.health
	boss.resolve_connection_loss()
	check(player.health < hp and player.progression_speed < original_speed,"Onda aplica daño y ralentización")
	duel.reset_duel()
	check(duel.state == duel.DuelState.NEUTRAL and boss.phase == 0 and boss.active_routers() == 0,"Muerte/reintento reinicia fases y routers")
	check(is_equal_approx(player.progression_speed,original_speed) and boss.connection_charge == 0,"Reinicio limpia efectos")
	campaign.ui.close_modal()
	player.global_position = boss.global_position+Vector3(2,0,0)
	duel.interact(player)
	duel.intro_duration = 0.1
	duel.accept()
	await get_tree().create_timer(0.7).timeout
	boss.set_physics_process(false)
	var credits: int = campaign.data.credits
	var xp: int = campaign.data.xp
	player.health = 25
	boss.take_hit(Vector3.ZERO,10000)
	await get_tree().process_frame
	check(campaign.data.bosses.get("profesor_redes",false) and player.inventory.count_item("RouterPortatil") == 1,"Victoria y recompensa única")
	check(campaign.data.credits == credits+75 and campaign.data.xp == xp+150,"XP y créditos existentes")
	check(player.health == player.max_health and boss.dead,"Victoria recupera vida y deja boss caído")
	check(campaign.events.get("story:nexo_redes",0) == 1,"Pista NEXO registrada")
	campaign.boss_won(duel)
	check(player.inventory.count_item("RouterPortatil") == 1 and campaign.data.credits == credits+75,"Recompensa no se duplica")
	campaign.ui.close_modal()
	campaign.save_path = "res://scripts/pisos/piso_3/redes_test_temporal.json"
	campaign.persist = true
	campaign.save_game()
	campaign.persist = false
	var saved: String = campaign.save_path
	campus.queue_free()
	await get_tree().process_frame
	# Simular carga en un proceso nuevo: el registro local debe preceder al inventario.
	load("res://scripts/inventory/item_catalog.gd").definitions.clear()
	campus = load("res://Main.tscn").instantiate()
	var restored := campus.get_node("CampusCampaign")
	restored.save_path = saved
	restored.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(campus)
	campaign = await _wait_boot(campus)
	boss = campus.get_node("Piso3/EncuentroProfesorRedes/ProfesorRedes")
	duel = boss.get_node("BossDuelController")
	check(duel.defeated and boss.dead and boss.body.death_t == 1.0,"Guardado conserva derrota y pose")
	check(campaign.player.inventory.count_item("RouterPortatil") == 1,"Recompensa persiste al registrar desde Piso3")
	duel.interact(campaign.player)
	check(duel.state == duel.DuelState.DEFEATED,"No permite repetir desafío derrotado")
	campaign.persist = false
	campus.queue_free()
	await get_tree().process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saved))
	print("NETWORK_BOSS_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty()}))
	get_tree().quit(0 if failures.is_empty() else 1)
