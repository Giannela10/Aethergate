extends CanvasLayer
const ITEMS := {"lapiz":"Lápiz", "hoja_impresa":"Hoja impresa", "cuaderno":"Cuaderno", "goma":"Goma de borrar"}
var player: Node3D
var panel: PanelContainer
var rows: VBoxContainer
var info: Label
var editor: TextEdit
var save_button: Button
var selected := ""
var editing := false
func _ready() -> void:
	player = get_parent()
	layer = 25
	var hint := Label.new()
	hint.text = "[I] Inventario · [F] Usar objeto equipado"
	hint.position = Vector2(20,360)
	add_child(hint)
	panel = PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position -= Vector2(250,270)
	panel.custom_minimum_size = Vector2(500,540)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Inventario"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	rows = VBoxContainer.new()
	box.add_child(rows)
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	editor = TextEdit.new()
	editor.custom_minimum_size = Vector2(460,150)
	box.add_child(editor)
	save_button = Button.new()
	save_button.text = "Guardar nota"
	save_button.pressed.connect(save_note)
	box.add_child(save_button)
	var unequip := Button.new()
	unequip.text = "Guardar objeto equipado"
	unequip.pressed.connect(func(): player.equip_stationery(""); refresh())
	box.add_child(unequip)
	var close := Button.new()
	close.text = "Cerrar [I / Esc]"
	close.pressed.connect(close_inventory)
	box.add_child(close)
	panel.hide()
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_I and not editing:
		if panel.visible: close_inventory()
		elif not player.busy and not player.dead: open_inventory()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F and not panel.visible and not player.busy and not player.dead:
		if not player.equipped_stationery.is_empty():
			open_inventory()
			use_item(player.equipped_stationery)
			get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and panel.visible:
		close_inventory()
		get_viewport().set_input_as_handled()
func open_inventory() -> void:
	player.busy = true
	player.get_parent().set_process(false)
	player.velocity.x = 0
	player.velocity.z = 0
	panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh()
func close_inventory() -> void:
	panel.hide()
	editing = false
	player.busy = false
	player.get_parent().set_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func refresh() -> void:
	for child in rows.get_children(): child.free()
	editor.hide()
	save_button.hide()
	editing = false
	var empty := true
	for key in ITEMS:
		var count: int = player.stationery_inventory.get(key,0)
		if count <= 0: continue
		empty = false
		var row := HBoxContainer.new()
		rows.add_child(row)
		var label := Label.new()
		label.text = "%s × %d%s" % [ITEMS[key],count," (equipado)" if player.equipped_stationery == key else ""]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var equip := Button.new()
		equip.text = "Equipar"
		equip.pressed.connect(func(): player.equip_stationery(key); refresh())
		row.add_child(equip)
		var use := Button.new()
		use.text = "Usar"
		use.pressed.connect(use_item.bind(key))
		row.add_child(use)
	info.text = "Está vacío. Pide artículos en SalaImpresiones." if empty else "Equipa un artículo para llevarlo en la mano o elige Usar."
func use_item(key: String) -> void:
	if player.stationery_inventory.get(key,0)<=0: return
	selected = key
	editor.hide()
	save_button.hide()
	editing = false
	if key == "hoja_impresa":
		info.text = "HOJA IMPRESA\nMaterial de estudio — Duoc\nNombre: ____________________\nAsignatura: _________________\nApuntes: usa un lápiz o cuaderno para escribir."
	else:
		info.text = "Escribe tus apuntes." if key != "goma" else "Corrige o borra el texto de tus apuntes y guarda los cambios."
		editor.text = player.stationery_notes
		editor.show()
		save_button.text = "Guardar corrección" if key == "goma" else "Guardar nota"
		save_button.show()
		editing = true
		editor.grab_focus()
func save_note() -> void:
	player.stationery_notes = editor.text
	player.save_stationery()
	info.text = "Apuntes guardados. Puedes volver a leerlos desde el lápiz o el cuaderno."
