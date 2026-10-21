class_name ContextualInteractionsRegression
extends SceneTree
var failures: Array[String] = []
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var campaign = scene.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene)
	while not campaign.ready_for_play:
		await process_frame
	campaign.ui.close_modal()
	var player = campaign.player
	player.set_physics_process(false)
	var seating = player.get_node("SeatController")
	var body = player.body
	var socket = body.weapon_socket
	var original = player.inventory.snapshot_data()
	for kind in body.contextual_pose.ACTIONS:
		check(body.play_context_action(kind),"Pose disponible: "+kind)
		body.animate(0.12,Vector3.ZERO,true,false)
	check(not body.play_context_action("invalid"),"Ignorar pose inexistente")
	check(body.weapon_socket == socket,"Mantener socket de arma")
	body.contextual_pose.remaining = 0
	var seats := get_nodes_in_group("campus_seat")
	check(seats.size() == 2,"Solo dos butacas piloto")
	for point in seats:
		check(not point.furniture.has_node("RecogerSilla"),"No convertir armas en asientos")
		var target = seating.safe_position(point.furniture.global_position,point.furniture)
		print("SEAT_FLOOR ",point.furniture.name," ",point.furniture.global_position," target=",target)
		check(target != null,"Suelo y espacio para "+str(point.furniture.name))
		var approach = null
		for offset in [Vector3(0,0,-1.2),Vector3(0,0,1.2),Vector3(-1.2,0,0),Vector3(1.2,0,0)]:
			var candidate: Vector3 = point.furniture.global_position+offset
			var safe = seating.safe_position(candidate)
			if safe != null:
				player.global_position = safe
				if player._can_reach(point.furniture):
					approach = safe
					break
		check(approach != null,"Acceso seguro a "+str(point.furniture.name))
		if approach == null or target == null:
			continue
		var health = player.health
		var quests = campaign.data.quests.duplicate(true)
		check(seating.begin(point),"Sentarse en butaca real")
		check(body.contextual_pose.seated and not player.busy,"Sentarse sin bloquear interfaces")
		check(point.occupant == player,"Reservar asiento")
		var saved: Vector3 = seating.save_position()
		check(saved.distance_to(approach) < 0.05,"Guardar posición de salida")
		campaign.save_path = "res://tests/contextual_save_temporary.json"
		campaign.persist = true
		campaign.save_game()
		campaign.persist = false
		var stored = preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(campaign.save_path)
		var stored_position: Array = stored.get("position",[])
		check(stored_position.size() == 3 and Vector3(stored_position[0],stored_position[1],stored_position[2]).distance_to(saved) < 0.001,"Archivo de guardado usa salida segura")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(campaign.save_path))
		campaign.phone.toggle()
		check(campaign.ui.modal and body.contextual_pose.seated,"Abrir celular sentado")
		campaign.phone.toggle()
		check(not paused and body.contextual_pose.seated,"Cerrar celular mantiene asiento")
		player.inventory_ui.open_inventory()
		check(player.busy and body.contextual_pose.seated,"Inventario disponible sentado")
		player.inventory_ui.close_inventory()
		player.stationery_notes = "Apunte de prueba"
		var reading := InputEventKey.new()
		reading.physical_keycode = KEY_F
		reading.pressed = true
		campaign._input(reading)
		check(campaign.ui.modal and body.contextual_pose.seated,"Leer apuntes sentado")
		campaign.ui.close_modal()
		player.stationery_notes = ""
		body.animate(0.1,Vector3.ZERO,true,false)
		check(absf(body.hip_l.rotation.x-PI*0.5) < 0.01,"Pose de piernas sentado")
		body.animate(0.2,Vector3.ZERO,false,false)
		check(body.animation_state == "Sit" and body.air_t == 0,"Pose sentada no se interpreta como caída")
		check(seating.stand(),"Levantarse con salida segura")
		check(not body.contextual_pose.seated and point.occupant == null,"Liberar asiento y pose")
		check(player.global_position.distance_to(approach) < 0.1,"Volver a posición accesible")
		check(player.health == health and campaign.data.quests == quests,"No alterar vida ni misiones")
		check(seating.begin(point),"Volver a sentarse")
		Input.action_press("move_forward")
		player._physics_process(0.016)
		Input.action_release("move_forward")
		check(not body.contextual_pose.seated,"Movimiento levanta al jugador")
		player.global_position = approach
		check(seating.begin(point),"Sentarse antes de comprobar daño")
		player.take_hit(Vector3.ZERO,1)
		check(not body.contextual_pose.seated,"Recibir daño libera asiento")
		player.heal(1)
		body.hurt_t = 0
		player.stun_t = 0
	check(player.inventory.snapshot_data() == original,"No alterar inventario")
	print("CONTEXT_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
