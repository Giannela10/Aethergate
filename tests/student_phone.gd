class_name StudentPhoneRegression
extends SceneTree
const SAVE := "res://tests/phone_temporary.json"
var failures: Array[String] = []
var checks := 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok:
		failures.append(title)
		push_error(title)
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
	var phone = campaign.phone
	check(phone.state.contacts.is_empty(),"No revelar contactos desconocidos")
	check(not phone.send_message("unknown","unknown","Hola"),"No aceptar remitente desconocido")
	campaign.event("talk","Profesor")
	check(phone.state.contacts.has("Profesor"),"Contacto automático al conversar")
	check(phone.state.contacts.Profesor.floor == "3","Piso habitual del NPC, no piso actual del jugador")
	check(phone.unread_count() == 1,"Primer mensaje sin leer")
	campaign.event("talk","Profesor")
	check(phone.state.messages.size() == 1,"Conversaciones repetidas no duplican mensajes")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_P
	key.pressed = true
	campaign._input(key)
	check(campaign.ui.page == "phone:home" and paused,"P abre y pausa celular")
	check(campaign.ui.column.get_node("AppGrid").get_child_count() == 9,"Nueve aplicaciones en pantalla de teléfono")
	check(phone.view.root.visible and not campaign.ui.panel.visible,"Carcasa visible y menú convencional oculto")
	phone.app("map")
	check(campaign.ui.page == "phone:map","Reutilizar mapa existente")
	phone.toggle()
	check(not paused and not campaign.player.busy,"P devuelve controles desde aplicación")
	check(not phone.view.root.visible,"Cerrar oculta la carcasa")
	campaign.show_pause()
	check(campaign.ui.panel.visible and not phone.view.root.visible,"Pausa conserva su presentación normal")
	campaign.ui.close_modal()
	phone.open()
	phone.messages()
	phone.read_message("welcome:Profesor")
	check(phone.unread_count() == 0,"Leer actualiza estado")
	phone.show_contact("Profesor")
	check(campaign.ui.page == "phone:contact","Detalle de contacto")
	phone.view._back()
	check(campaign.ui.page == "phone:contacts","Atrás regresa a contactos")
	phone.toggle()
	for app in ["quests","nexo","collectibles","stats","settings"]:
		phone.open()
		phone.app(app)
		check(campaign.ui.page == "phone:"+app,"Aplicación integrada: "+app)
		phone.toggle()
	campaign.player.busy = true
	check(not phone.toggle(),"No robar entrada durante otra interacción")
	campaign.player.busy = false
	var inventory = campaign.player.inventory.snapshot_data()
	var quests = campaign.data.quests.duplicate(true)
	var bosses = campaign.data.bosses.duplicate(true)
	check(phone.send_message("test:2","Profesor","Pasa cuando puedas."),"API de mensajes")
	check(not phone.send_message("test:2","Profesor","Duplicado"),"Deduplicar por ID persistente")
	var old_duel = campaign.active_duel
	campaign.active_duel = scene
	campaign.ui.toast_t = 0
	phone._process(2)
	check(phone.notification_pending and campaign.ui.toast_t == 0,"No notificar durante duelo")
	campaign.active_duel = old_duel
	campaign.save_path = SAVE
	campaign.persist = true
	campaign.save_game()
	campaign.persist = false
	var saved: Dictionary = preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(SAVE)
	check(saved.phone.contacts.has("Profesor") and saved.phone.messages.size() == 2,"Contactos y mensajes guardados")
	check(saved.phone.messages[0].read == true,"Lectura persistida")
	var restored = preload("res://scripts/campaign/student_phone.gd").new()
	campaign.data.phone = saved.phone
	restored.campaign = campaign
	campaign.add_child(restored)
	check(restored.unread_count() == 1,"Restaurar mensajes sin leer")
	check(not restored.send_message("test:2","Profesor","Duplicado"),"Deduplicar tras restaurar")
	check(campaign.player.inventory.snapshot_data() == inventory,"No modificar inventario")
	check(campaign.data.quests == quests and campaign.data.bosses == bosses,"No modificar misiones ni bosses")
	restored.queue_free()
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("PHONE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
