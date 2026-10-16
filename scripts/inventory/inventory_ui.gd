extends CanvasLayer
const Catalog = preload("res://scripts/inventory/item_catalog.gd")
const Item = preload("res://scripts/inventory/inventory_item.gd")
var player: CharacterBody3D
var inventory: Node
var panel: PanelContainer
var root_control: Control
var shade: ColorRect
var list: ItemList
var description: Label
var notes: TextEdit
var save_note: Button
var filter: OptionButton
var quick_labels: Array[Label] = []
var row_uids: Array[String] = []
var selected_uid := ""
var previous_mouse := Input.MOUSE_MODE_CAPTURED
var toast: Label
var toast_time := 0.0

func _ready() -> void:
	player = get_parent()
	inventory = player.inventory
	layer = 26
	root_control = Control.new()
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	shade = ColorRect.new()
	shade.color = Color(0.01,0.025,0.05,0.65)
	root_control.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.hide()
	panel = PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.add_theme_stylebox_override("panel",_style(Color("142332"),Color("479baf")))
	root_control.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",8)
	scroll.add_child(column)
	var heading := Label.new()
	heading.text = "MOCHILA DEL ESTUDIANTE"
	heading.add_theme_font_size_override("font_size",22)
	column.add_child(heading)
	filter = OptionButton.new()
	for title in ["Todas las categorías","Consumibles","Armas","Objetos clave","Objetos especiales","Papelería"]:
		filter.add_item(title)
	filter.item_selected.connect(func(_index): refresh())
	column.add_child(filter)
	list = ItemList.new()
	list.custom_minimum_size.y = 180
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.fixed_icon_size = Vector2i(28,28)
	list.item_selected.connect(_select)
	column.add_child(list)
	description = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	_button(actions,"Usar",_use_selected)
	_button(actions,"Equipar",_equip_selected)
	_button(actions,"★ Favorito",func(): inventory.toggle_favorite(selected_uid); refresh())
	_button(actions,"Guardar equipado",func(): inventory.stash_equipped(); player.equip_stationery(""); refresh())
	var assignments := HBoxContainer.new()
	column.add_child(assignments)
	for i in 4:
		_button(assignments,"Asignar a %d" % (i+1),_assign.bind(i))
	notes = TextEdit.new()
	notes.custom_minimum_size.y = 95
	notes.placeholder_text = "Apuntes del cuaderno / lápiz"
	column.add_child(notes)
	save_note = Button.new()
	save_note.text = "Guardar apuntes"
	save_note.pressed.connect(_save_notes)
	column.add_child(save_note)
	_button(column,"Cerrar [I / Esc]",close_inventory)
	var quick := HBoxContainer.new()
	quick.name = "QuickBar"
	root_control.add_child(quick)
	quick.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	quick.offset_left = -320
	quick.offset_right = 320
	quick.offset_top = -85
	quick.offset_bottom = -16
	for i in 4:
		var slot := PanelContainer.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.custom_minimum_size = Vector2(154,64)
		slot.add_theme_stylebox_override("panel",_style(Color(0.04,0.08,0.13,0.9),Color("385c6c")))
		quick.add_child(slot)
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",13)
		slot.add_child(label)
		quick_labels.append(label)
	var hint := Label.new()
	hint.text = "[I] Mochila · [1–4] Usar / equipar · [E] Recoger · [F] Apuntes"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -340
	hint.offset_right = 340
	hint.offset_top = -112
	hint.offset_bottom = -88
	toast = Label.new()
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color",Color("a6f2d2"))
	toast.add_theme_color_override("font_outline_color",Color.BLACK)
	toast.add_theme_constant_override("outline_size",5)
	root_control.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toast.offset_left = -400
	toast.offset_right = 400
	toast.offset_top = -145
	toast.offset_bottom = -117
	panel.hide()
	inventory.changed.connect(refresh)
	inventory.notice.connect(show_notice)
	player.hit_received.connect(_on_hit)
	player.died.connect(close_inventory)
	get_viewport().size_changed.connect(_layout)
	_layout()
	refresh()

func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _button(parent: Node, title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.pressed.connect(callback)
	parent.add_child(button)

func _layout() -> void:
	if not is_inside_tree():
		return
	var size := get_viewport().get_visible_rect().size
	root_control.scale = Vector2.ONE * minf(1.0,size.x/740.0)
	root_control.size = size / root_control.scale
	var width := minf(700,root_control.size.x-24)
	var height := minf(560,root_control.size.y-135)
	panel.position = Vector2((root_control.size.x-width)*0.5,12)
	panel.set_deferred("size",Vector2(width,height))

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or get_tree().paused:
		return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if panel.visible:
		if key == KEY_ESCAPE or (key == KEY_I and not notes.has_focus()):
			close_inventory()
			get_viewport().set_input_as_handled()
		return
	if player.dead or player.busy:
		return
	if key == KEY_I:
		open_inventory()
	elif key >= KEY_1 and key <= KEY_4:
		inventory.use_quick(key-KEY_1)
	elif key == KEY_F and not player.equipped_stationery.is_empty():
		open_inventory()
		for uid in row_uids:
			if inventory.entry_for(uid).item_id == player.equipped_stationery:
				selected_uid = uid
				_show_details()
				break
	else:
		return
	get_viewport().set_input_as_handled()

func open_inventory() -> void:
	if player.dead or player.busy or get_tree().paused:
		return
	previous_mouse = Input.mouse_mode
	player.busy = true
	player.velocity.x = 0
	player.velocity.z = 0
	shade.show()
	panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh()
	_layout()

func close_inventory() -> void:
	if not is_instance_valid(panel) or not panel.visible:
		return
	if notes.visible:
		_save_notes()
	panel.hide()
	shade.hide()
	player.busy = false
	player.punch_cd = maxf(player.punch_cd,0.18)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if player.dead else previous_mouse as Input.MouseMode

func _on_hit() -> void:
	if panel.visible:
		close_inventory()
		show_notice("Inventario cerrado: recibiste un golpe.")

func refresh() -> void:
	if not is_instance_valid(list):
		return
	list.clear()
	row_uids.clear()
	for entry in inventory.entries:
		var item = Catalog.get_item(entry.item_id)
		if filter.selected > 0 and item.category != filter.selected-1:
			continue
		var text := "%s  ×%d  ·  %s" % [item.display_name,entry.quantity,item.category_name()]
		if inventory.weapon_nodes.has(entry.uid):
			text += "  · %d/%d · %s" % [inventory.weapon_nodes[entry.uid].durability,inventory.weapon_nodes[entry.uid].get_meta("max_durability",inventory.weapon_nodes[entry.uid].durability),inventory.weapon_nodes[entry.uid].get_meta("rarity_name","COMÚN")]
		if entry.uid == inventory.equipped_uid or player.equipped_stationery == entry.item_id:
			text += "  [Equipado]"
		list.add_item(text,item.icon)
		row_uids.append(entry.uid)
		if entry.uid == selected_uid:
			list.select(list.item_count-1)
	if inventory.entry_for(selected_uid).is_empty():
		selected_uid = row_uids[0] if not row_uids.is_empty() else ""
		if not selected_uid.is_empty():
			list.select(0)
	for i in 4:
		var entry: Dictionary = inventory.entry_for(inventory.quick_slots[i])
		if entry.is_empty():
			quick_labels[i].text = "%d\nVacío" % (i+1)
		else:
			var item = Catalog.get_item(entry.item_id)
			quick_labels[i].text = "%d · %s\n×%d%s" % [i+1,item.display_name,entry.quantity," · Equipado" if entry.uid == inventory.equipped_uid else ""]
	_show_details()
	call_deferred("_layout")

func _select(index: int) -> void:
	selected_uid = row_uids[index]
	_show_details()

func _show_details() -> void:
	var entry: Dictionary = inventory.entry_for(selected_uid)
	notes.hide()
	save_note.hide()
	if entry.is_empty():
		description.text = "Mochila vacía. Acércate a un objeto y pulsa E."
		return
	var item = Catalog.get_item(entry.item_id)
	description.text = item.display_name + " · " + item.category_name() + "\n" + item.description
	description.text += "\n★ Favorito" if entry.get("favorite",false) else ""
	description.text += inventory.describe_comparison(selected_uid)
	if item.heal_amount > 0: description.text += "\nRestaura %.0f HP" % item.heal_amount
	if item.speed_multiplier > 1: description.text += "\nVelocidad +%.0f%% durante %.0f s" % [(item.speed_multiplier-1)*100,item.duration]
	if item.category == Item.Category.CLAVE:
		description.text += " Se conserva y los accesos pueden comprobar su presencia."
	if item.category == Item.Category.PAPELERIA:
		if entry.item_id == "hoja_impresa":
			description.text += "\nMaterial de estudio · Nombre: ______ · Asignatura: ______"
		else:
			notes.text = player.stationery_notes
			notes.show()
			save_note.show()

func _save_notes() -> void:
	player.stationery_notes = notes.text
	player.save_stationery()
	show_notice("Apuntes guardados.")

func _use_selected() -> void:
	var entry: Dictionary = inventory.entry_for(selected_uid)
	if not entry.is_empty() and Catalog.get_item(entry.item_id).category == Item.Category.PAPELERIA:
		_show_details()
	else:
		inventory.use_entry(selected_uid)

func _equip_selected() -> void:
	inventory.equip_entry(selected_uid)

func _assign(slot: int) -> void:
	if inventory.assign_quick(slot,selected_uid):
		show_notice("Asignado al espacio %d." % (slot+1))

func show_notice(text: String) -> void:
	toast.text = text
	toast_time = 3.0

func _process(delta: float) -> void:
	toast_time = maxf(0,toast_time-delta)
	toast.visible = toast_time > 0
