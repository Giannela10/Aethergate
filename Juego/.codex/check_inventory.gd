extends SceneTree
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var saved_path := "user://papeleria_inventario.json"
	var existed := FileAccess.file_exists(saved_path)
	var backup := FileAccess.get_file_as_string(saved_path) if existed else ""
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var player = scene.get_node("GameplayManager").player
	player.stationery_inventory.clear()
	player.equip_stationery("")
	if player.equip_stationery("cuaderno"): failures.append("equipped an unowned item")
	for key in ["lapiz","hoja_impresa","cuaderno","goma"]:
		player.receive_stationery(key)
		if not player.equip_stationery(key): failures.append("cannot equip "+key)
		if not is_instance_valid(player.stationery_model) or player.stationery_model.get_parent() != player.body.hand_r: failures.append("missing held model "+key)
	var ui = player.stationery_ui
	ui.open_inventory()
	if not player.busy or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE: failures.append("inventory did not unlock the mouse")
	ui.use_item("cuaderno")
	ui.editor.text = "Apunte de prueba: ejercicio 1"
	ui.save_note()
	ui.use_item("lapiz")
	if ui.editor.text != player.stationery_notes: failures.append("pencil cannot read saved notes")
	ui.use_item("goma")
	ui.editor.text = "Apunte corregido"
	ui.save_note()
	ui.use_item("hoja_impresa")
	if not ui.info.text.contains("HOJA IMPRESA"): failures.append("printed sheet unavailable")
	ui.close_inventory()
	if player.busy: failures.append("inventory did not release player")
	player.equip_stationery("lapiz")
	var counts: Dictionary = player.stationery_inventory.duplicate()
	player.stationery_inventory.clear()
	player.stationery_notes = ""
	player.equipped_stationery = ""
	player.load_stationery()
	if player.stationery_inventory != counts or player.stationery_notes != "Apunte corregido" or player.equipped_stationery != "lapiz": failures.append("inventory save/load failed")
	player.equip_stationery("")
	if is_instance_valid(player.stationery_model): failures.append("held item not cleared")
	print("INVENTORY_EQUIP_USE_PERSISTENCE failures=",JSON.stringify(failures))
	if existed:
		var file := FileAccess.open(saved_path,FileAccess.WRITE)
		file.store_string(backup)
	else: DirAccess.remove_absolute(saved_path)
	quit(0 if failures.is_empty() else 1)
