extends SceneTree
var failures: Array[String] = []
var checks := 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok: failures.append(title); push_error(title)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var c = scene.get_node("CampusCampaign")
	c.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene); current_scene = scene
	while not c.ready_for_play: await process_frame
	c.ui.close_modal()
	c.player.set_physics_process(false)
	c.live.director.set_process(false)
	for enemy in get_nodes_in_group("enemy"): enemy.set_physics_process(false)
	var inv = c.player.inventory
	inv.restore_snapshot({"version":1,"entries":[],"quick":[],"serial":0,"equipped":""})
	inv.max_entries = 1
	inv.add_item("Palo",1,false)
	c.get_node("Profesor")._accept()
	check(inv.has_item("Documentos"),"Documentos obligatorios entregados con mochila llena")
	c.ui.close_modal()
	c.data.bosses["punto"] = true
	c.events.erase("boss:punto")
	check(c.quests.progress({"kind":"boss","id":"punto","amount":1}) == 1,"Derrota antigua sin evento redundante")
	inv.restore_snapshot({"version":1,"entries":[],"quick":[],"serial":0,"equipped":""})
	inv.max_entries = 2
	check(inv.add_item("Palo",5,false) == 2 and inv.entries.size() == 2,"Lote de armas respeta capacidad e informa cantidad")
	inv.restore_snapshot({"version":1,"entries":[],"quick":[],"serial":0,"equipped":""})
	inv.max_entries = 1
	inv.add_item("Bebida",999,false)
	check(inv.add_item("Bebida",1,false) == 0 and inv.count_item("Bebida") == 999,"Stack lleno no crea entrada ni informa éxito")
	check(inv.remove_items("Bebida",5),"Consumir cantidad válida")
	check(inv.add_item("Bebida",3,false) == 3,"Retorno es cantidad añadida, no total anterior")
	# Repair a legacy provided flag whose quest key was never received.
	c.data.unlocks["provided:documentos"] = true
	c.get_node("Profesor")._provide_starting_items()
	check(inv.has_item("Documentos"),"Recuperar documento perdido de guardado antiguo")
	var serial_before: int = inv.serial
	c.get_node("Profesor")._provide_starting_items()
	check(inv.serial == serial_before,"Recuperación de clave idempotente")
	var ui = c.ui
	ui.close_modal(); ui.notice_queue.clear(); ui.toast_t = 0
	ui.notify("info",4,ui.NoticePriority.INFO)
	ui.notify("reward",4,ui.NoticePriority.REWARD)
	ui.notify("mission",4,ui.NoticePriority.MISSION)
	ui.notify("mission",4,ui.NoticePriority.MISSION)
	check(ui.notice_queue.size() == 2,"Avisos simultáneos deduplicados")
	ui._process(4.1)
	check(ui.toast.text == "mission","Misión antes que recompensa pendiente")
	ui.notify("critical",4,ui.NoticePriority.CRITICAL)
	check(ui.toast.text == "critical","Aviso crítico interrumpe y conserva el anterior")
	ui.modal = true
	var remaining: float = ui.toast_t
	ui._process(10)
	check(ui.toast_t == remaining and not ui.toast.visible,"Avisos esperan durante diálogo")
	ui.modal = false
	for i in 30: ui.notify("info_"+str(i))
	check(ui.notice_queue.size() <= 16,"Cola acotada")
	while get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await process_frame
	var duel = get_nodes_in_group("boss_duel").filter(func(d): return d.boss_id == "chef")[0]
	c.player.health = 75
	c.live.retry.capture(duel)
	var pre_inventory: Dictionary = inv.snapshot_data().duplicate(true)
	c.active_duel = duel; duel.state = duel.DuelState.COMBAT
	c.player.health = 10
	c.data.collected["temporary_duel_pickup"] = true
	inv.remove_items("Bebida",1)
	var payload: Dictionary = c.save_payload()
	check(payload.health == 75 and payload.inventory == pre_inventory,"Guardado de combate conserva recursos previos")
	check(not payload.collected.has("temporary_duel_pickup"),"Estado del mundo y recursos pertenecen al mismo snapshot")
	check(c.player.health == 10 and inv.count_item("Bebida") == 996,"Serializar no cura ni restaura en combate")
	c.save_path = "res://.godot/balance_test_save.json"; c.persist = true
	c.save_game(); c.persist = false
	var disk = JSON.parse_string(FileAccess.get_file_as_string(c.save_path))
	check(disk.health == 75 and disk.save_version == 2,"Guardar y leer JSON real durante duelo")
	c.player.dead = true; c.live.retry.on_death(); duel.reset_duel()
	check(c.save_payload().health == 75,"Cerrar en pantalla de muerte conserva estado previo")
	c.respawn()
	check(c.live.retry.snapshot.is_empty() and not c.live.retry.can_retry(),"Checkpoint abandona snapshot, no reescribe guardados futuros")
	c.data.inventory = inv.snapshot_data(); c.data.health = c.player.health
	check(c.save_payload().inventory == inv.snapshot_data(),"Guardado ordinario vuelve al inventario actual")
	print("BALANCE_REGRESSION checks=",checks," failures=",JSON.stringify(failures))
	scene.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
