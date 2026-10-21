extends Node
## Fixture aislado: no lee ni escribe la partida personal del jugador.
const WorldItem = preload("res://scripts/campaign/world_item.gd")
const Reader = preload("res://scripts/compartidos/lectura_guardado.gd")
var checks := 0
var failures: Array[String] = []
var finished := false
var result: Dictionary = {}

class SaveProbe extends "res://scripts/campaign/campus_campaign.gd":
	var fail_replace := false
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func _input(_event: InputEvent) -> void: pass
	func _replace_save_file(temporary: String, destination: String) -> Error:
		return ERR_FILE_CANT_WRITE if fail_replace else super._replace_save_file(temporary,destination)

func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok:
		failures.append(title)
		push_error(title)

func _ready() -> void:
	run.call_deferred()
	watchdog.call_deferred()

func watchdog() -> void:
	await get_tree().create_timer(90,true,false,true).timeout
	if not finished:
		push_error("CAMPUS_FIXES_TIMEOUT")
		get_tree().quit(2)

func pickup(c: Node, id: String, amount: int = 5) -> Node3D:
	var node := WorldItem.new()
	node.world_id = id
	node.item_id = "Bebida"
	node.quantity = amount
	c.add_child(node)
	node.global_position = c.player.global_position
	return node

func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var c = scene.get_node("CampusCampaign")
	c.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(scene)
	while not c.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	c.ui.close_modal()
	c.live.director.enabled = false
	c.player.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemy"): enemy.set_physics_process(false)
	var inv = c.player.inventory
	inv.restore_snapshot({"version":1,"entries":[],"quick":[],"serial":0,"equipped":""})
	inv.max_entries = 1
	inv.add_item("Bebida",997,false)
	c.player.global_position = Vector3(0,2,0)
	c.player.busy = false
	await get_tree().physics_frame
	var item := pickup(c,"test_partial")
	item.interact(c.player)
	check(inv.count_item("Bebida") == 999,"Inventario real acepta solo 2 de 5")
	check(item.quantity == 3 and not item.collected and item.visible and item.is_in_group("campus_interactable"),"Quedan 3 unidades físicas e interactivas")
	check(item.interaction_text(c.player).ends_with("x3"),"Contexto actualizado x3")
	check(not c.data.collected.test_partial and c.data.remaining_quantity.test_partial == 3,"Booleano y cantidad parcial separados")
	c.data.collected.Apunte_redes = true
	c.save_path = "res://.godot/campus_fixes_save.json"
	c.persist = true
	c.save_game()
	c.persist = false
	check(c.last_save_succeeded,"Guardado en disco confirmado")
	var saved := Reader.read_dictionary(c.save_path)
	check(saved.remaining_quantity.test_partial == 3 and not saved.collected.test_partial,"JSON conserva remaining_quantity=3")
	item.free()
	# Recarga real de la campaña y su inventario desde el JSON aislado.
	scene.queue_free()
	await get_tree().process_frame
	scene = load("res://Main.tscn").instantiate()
	c = scene.get_node("CampusCampaign")
	c.save_path = "res://.godot/campus_fixes_save.json"
	c.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(scene)
	while not c.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	c.persist = false
	c.ui.close_modal()
	c.live.director.enabled = false
	c.player.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemy"): enemy.set_physics_process(false)
	inv = c.player.inventory
	check(c.loaded_save and inv.count_item("Bebida") == 999,"Cargar campaña e inventario reales")
	inv.max_entries = 1
	item = pickup(c,"test_partial")
	check(item.quantity == 3 and not item.collected,"Después de cerrar/cargar siguen 3")
	item.interact(c.player)
	check(item.quantity == 3,"Mochila llena no consume sobrante")
	inv.max_entries = 1
	inv.remove_items("Bebida",3)
	item.interact(c.player)
	check(inv.count_item("Bebida") == 999 and item.quantity == 0,"Después de liberar espacio recibe las 3 restantes")
	check(item.collected and not item.visible and not item.is_in_group("campus_interactable"),"Solo al agotarse desaparece")
	c.persist = true; c.save_game(); c.persist = false
	saved = Reader.read_dictionary(c.save_path)
	check(saved.collected.test_partial and saved.remaining_quantity.test_partial == 0,"Recogida completa persistida")
	item.free()
	item = pickup(c,"test_partial")
	check(item.collected and not item.visible,"Objeto agotado no reaparece")
	var old := pickup(c,"legacy_unpicked")
	check(old.quantity == 5 and not old.collected,"Save antiguo sin cantidad usa original")
	c.data.collected.legacy_picked = true
	old = pickup(c,"legacy_picked")
	check(old.collected and old.quantity == 0,"Save antiguo recogido sigue agotado")
	c.data.remaining_quantity.legacy_picked = 3
	old = pickup(c,"legacy_picked")
	check(old.collected,"Booleano antiguo true tiene prioridad")
	var repeatable := WorldItem.new()
	repeatable.world_id = "legacy_picked"; repeatable.item_id = "Bebida"; repeatable.quantity = 5; repeatable.respawn = true
	c.add_child(repeatable)
	check(repeatable.quantity == 5 and not repeatable.collected,"Respawn explícito conserva su comportamiento")
	# Claves y desbloqueos no cambian.
	c.give_reward_item("TarjetaAcceso",1)
	check(inv.has_item("TarjetaAcceso") and not inv.remove_items("TarjetaAcceso",1),"Clave protegida; recompensa con mochila llena")
	var expected := {"pc_intro":0,"pc3":1,"pc4":2,"pc5":0,"pc6":2,"pc7":1,"pc8":2,"pc_secreto":1}
	check(c.manager.minigame.layer > c.ui.layer and c.manager.minigame.layer > c.player.inventory_ui.layer,"Minijuegos por encima del HUD sin tapar opciones")
	for pc in get_tree().get_nodes_in_group("computer"):
		var id: String = pc.get_meta("campaign_id","")
		check(expected.has(id) and pc.game_id == expected[id],"game_id conservado: "+id)
	for q in ["inicio","biblioteca","academico3","academico4","academico5"]:
		c.data.quests[q].state = 2
	c.quests.refresh()
	for id in ["pc4","pc5","pc6","pc7","pc8"]:
		var pc = c.get_node(id)
		check(pc.activity_profile == id and pc.get_meta("campaign_id") == id,"Perfil independiente del ID: "+id)
		c.manager._on_computer_requested(pc)
		var game = c.manager.minigame.current
		check(game.get_script() == preload("res://scripts/juego/campus_activity.gd"),"Clasificación reutilizada: "+id)
		var completions := [0]
		game.completed.connect(func(): completions[0] += 1)
		while not game.done: game._on_folder(int(game.queue[game.index][1]))
		game._on_folder(0)
		check(completions[0] == 1,"Una señal completed: "+id)
		c.manager.minigame.close(true)
		check(pc.done and c.data.computers.get(id,false) and c.events.get("computer:"+id,0) == 1,"Flag/evento originales: "+id)
		if id == "pc6":
			check(c.quests.state("seguridad6") == 1,"pc6 ahora prepara; duelo de Lenguaje pendiente")
			c.data.bosses.profesor_lenguaje = true; c.event("boss","profesor_lenguaje")
			check(c.quests.state("seguridad6") == 2 and c.floor_unlocked("7"),"Misión de Lenguaje y ascensor 7")
		if id == "pc7":
			c.event("door","acceso7")
			c.data.bosses.profesor_etica = true; c.event("boss","profesor_etica")
			check(c.quests.state("acceso7") == 2 and c.floor_unlocked("8"),"Misión pc7 y ascensor 8")
	check(c.quests.progress({"kind":"computer","id":"pc8","amount":1}) == 1,"Progreso por flag persistida")
	for id in ["programacion","datos","redes","ia"]:
		var note = c.get_node("Apunte_"+id)
		check(absf(note.global_position.y - preload("res://scripts/campaign/campus_content.gd").HEIGHTS[2]) < 1.0,"Apunte en piso 3: "+id)
		check(note.world_id == "Apunte_"+id and note.item_id == "hoja_impresa" and note.get_meta("placement_validated",false),"ID y posición segura: "+id)
	check(c.get_node("Apunte_redes").collected and not c.get_node("Apunte_redes").visible,"Apunte trasladado ya encontrado no reaparece al cargar")
	var duel = scene.get_node("Piso1/Casino/ChefSupremoCasino/BossDuelController")
	var chef = duel.actor
	check(chef.boss_max_health == 350 and chef.health == 350 and duel.max_health == 350,"Chef y controlador 350 HP tras cargar")
	duel.state = duel.DuelState.COMBAT; c.active_duel = duel
	c.ui._process(0)
	check(c.ui.boss_title.text == "Chef Supremo del Casino" and c.ui.boss_value.text.begins_with("350 / 350"),"HUD Chef 350 / 350")
	chef.take_hit(Vector3.ZERO,139)
	check(chef.phase == 1,"Chef fase 1 sobre 60%")
	chef.take_hit(Vector3.ZERO,1)
	check(chef.phase == 2 and chef.health == 210,"Chef fase 2 al 60%")
	chef.take_hit(Vector3.ZERO,105)
	check(chef.phase == 3 and chef.health == 105,"Chef fase 3 al 30%")
	duel.reset_duel()
	check(chef.health == 350 and chef.phase == 1,"Reset/reintento restaura 350 HP y fase 1")
	# Fallo de reemplazo inyectado: el guardado previo y el temporal deben sobrevivir.
	var probe := SaveProbe.new()
	probe.persist = true; probe.booting = false; probe.player = c.player; probe.ui = c.ui
	probe.save_path = "res://.godot/campus_fixes_failure.json"
	add_child(probe)
	check(probe._write_save_payload({"sentinel":"old"}) == OK,"Crear guardado previo para fallo")
	var original := FileAccess.get_file_as_bytes(probe.save_path)
	probe.fail_replace = true
	c.ui.notice_queue.clear(); c.ui.toast_t = 0
	probe.save_game()
	check(not probe.last_save_succeeded and probe.save_failure_notified,"Fallo explícito sin marcar éxito")
	check(FileAccess.get_file_as_bytes(probe.save_path) == original and FileAccess.get_file_as_bytes(probe.save_path+".bak") == original,"Fallo conserva original y backup")
	check(not Reader.read_dictionary(probe.save_path+".tmp").is_empty(),"Temporal recuperable conservado")
	check(c.ui.toast.text == "No se pudo guardar la partida.","Aviso sin detalles técnicos")
	c.ui.toast_t = 0; c.ui.notice_queue.clear()
	probe.save_game()
	check(c.ui.notice_queue.is_empty() and c.ui.toast_t == 0,"Fallo consecutivo no repite aviso")
	probe.fail_replace = false; probe.save_game()
	check(probe.last_save_succeeded and not probe.save_failure_notified,"Recuperación permite nuevos avisos futuros")
	probe.save_path = "res://.godot/campus_fixes_missing_parent/save.json"
	probe.save_game()
	check(not probe.last_save_succeeded,"Fallo al abrir temporal comprobado")
	probe.persist = false
	result = {"checks":checks,"failures":failures}
	finished = true
	print("CAMPUS_FIXES_RESULT "+JSON.stringify(result))
	var report := FileAccess.open("res://reports/campus_fixes_result.json",FileAccess.WRITE)
	if report: report.store_string(JSON.stringify(result,"\t")); report.close()
	if "--auto-quit" in OS.get_cmdline_user_args(): get_tree().quit(0 if failures.is_empty() else 1)
