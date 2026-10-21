class_name AppearanceRegression
extends SceneTree
const Profile = preload("res://scripts/juego/character_appearance.gd")
var failures: Array[String] = []
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)
		push_error(detail)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var unlocked := {}
	check(Profile.normalize({"skin":99,"hair":-9,"outfit":4}).skin == 5,"Limitar índices corruptos")
	check(Profile.normalize({"outfit":4}).outfit == 0,"No equipar cosméticos bloqueados")
	check(Profile.normalize({"skin":"invalid"}).skin == 0,"Aceptar datos antiguos o mal formados")
	check(Profile.unlock_from_progress({"chef":true,"profesor_redes":true},unlocked),"Detectar desbloqueos")
	check(unlocked.has("delantal_chef") and unlocked.has("telecomunicaciones"),"Recompensas visuales por progreso")
	check(not Profile.unlock_from_progress({"chef":true,"profesor_redes":true},unlocked),"Desbloqueo idempotente")
	var world = load("res://Main.tscn").instantiate()
	var campaign = world.get_node("CampusCampaign")
	campaign.persist = false
	world.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(world)
	while not campaign.ready_for_play:
		await process_frame
	campaign.ui.close_modal()
	var body = campaign.player.body
	var socket = body.weapon_socket
	var health = campaign.player.health
	var before = campaign.data.appearance.duplicate()
	campaign.show_personalization()
	campaign.appearance_menu._select(3,"skin")
	campaign.appearance_menu._select(1,"hair")
	check(campaign.data.appearance == before,"Vista previa no cambia datos antes de confirmar")
	campaign.appearance_menu._cancel()
	check(campaign.data.appearance == before,"Cancelar conserva apariencia")
	campaign.show_personalization()
	campaign.appearance_menu._select(5,"skin")
	campaign.appearance_menu._select(1,"top")
	campaign.appearance_menu._confirm()
	check(campaign.data.appearance.skin == 5,"Confirmar aplica apariencia")
	check(body.weapon_socket == socket and socket.is_inside_tree(),"Se conserva socket de armas")
	check(campaign.player.health == health,"Personalización no cambia vida")
	check(not paused and not campaign.player.busy,"Confirmar devuelve controles")
	var expected_extras: int = body.appearance_adapter.extras.size()
	for index in 10:
		campaign.show_personalization()
		campaign.appearance_menu._select(index%3,"hair")
		campaign.appearance_menu._confirm()
		await process_frame
	check(body.appearance_adapter.extras.size() == expected_extras,"Cambios repetidos no acumulan ropa ni accesorios")
	print("APPEARANCE_RESULT ",JSON.stringify({"failures":failures}))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
