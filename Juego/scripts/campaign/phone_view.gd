class_name PhoneView
extends CanvasLayer
## Presentación del teléfono; los contenidos y callbacks siguen siendo CampaignUI.
var campaign: Node
var root: Control
var frame: PanelContainer
var content_scroll: ScrollContainer
var original_parent: Node
var column: VBoxContainer
var badge: Label

func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.015,0.025,0.045,0.82)
	root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame = PanelContainer.new()
	root.add_child(frame)
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("11151d")
	shell.border_color = Color("505967")
	shell.set_border_width_all(3)
	shell.set_corner_radius_all(38)
	shell.set_content_margin_all(12)
	shell.shadow_color = Color(0,0,0,0.65)
	shell.shadow_size = 22
	frame.add_theme_stylebox_override("panel",shell)
	var screen := PanelContainer.new()
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color("12243b")
	glass.set_corner_radius_all(28)
	glass.set_content_margin_all(16)
	screen.add_theme_stylebox_override("panel",glass)
	frame.add_child(screen)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",12)
	screen.add_child(layout)
	var status := HBoxContainer.new()
	layout.add_child(status)
	var brand := Label.new()
	brand.text = "DUOC  ·  CAMPUS"
	brand.add_theme_font_size_override("font_size",11)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(brand)
	var camera := Label.new()
	camera.text = "●  ━━━  ●"
	camera.add_theme_color_override("font_color",Color("7c91a7"))
	status.add_child(camera)
	var battery := Label.new()
	battery.text = "▰ 100%"
	battery.add_theme_font_size_override("font_size",11)
	status.add_child(battery)
	content_scroll = ScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(content_scroll)
	var navigation := HBoxContainer.new()
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("separation",16)
	layout.add_child(navigation)
	for item in [["‹","Atrás"],["○","Inicio"],["×","Cerrar"]]:
		var button := Button.new()
		button.text = item[0]
		button.tooltip_text = item[1]
		button.custom_minimum_size = Vector2(78,34)
		button.flat = true
		button.add_theme_font_size_override("font_size",24)
		if item[1] == "Cerrar":
			button.pressed.connect(campaign.ui.close_modal)
		elif item[1] == "Atrás":
			button.pressed.connect(_back)
		else:
			button.pressed.connect(campaign.phone.open)
		navigation.add_child(button)
	var gesture := ColorRect.new()
	gesture.color = Color("8091a5")
	gesture.custom_minimum_size = Vector2(96,3)
	gesture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(gesture)
	get_viewport().size_changed.connect(_fit)
	root.hide()

func _back() -> void:
	match campaign.ui.page:
		"phone:message": campaign.phone.messages()
		"phone:contact": campaign.phone.contacts()
		_: campaign.phone.open()

func _fit() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var ratio := minf(1.0,minf((viewport_size.x-24)/364.0,(viewport_size.y-24)/700.0))
	frame.scale = Vector2.ONE*maxf(0.2,ratio)
	frame.size = Vector2(364,700)
	frame.position = (viewport_size-frame.size*frame.scale)*0.5

func present() -> void:
	column = campaign.ui.column
	original_parent = column.get_parent()
	column.reparent(content_scroll)
	column.custom_minimum_size.x = 0
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in column.get_children():
		if child is Label:
			child.custom_minimum_size.x = 0
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			child.add_theme_font_size_override("font_size",20 if child == column.get_child(0) else 14)
		elif child is Button:
			child.clip_text = true
			child.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			child.custom_minimum_size.x = 0
			child.add_theme_font_size_override("font_size",14)
	campaign.ui.panel.hide()
	content_scroll.scroll_vertical = 0
	root.show()
	_fit()

func restore() -> void:
	if is_instance_valid(column) and is_instance_valid(original_parent) and column.get_parent() == content_scroll:
		column.reparent(original_parent)
	root.hide()

func home() -> void:
	present()
	# Sustituye los botones de lista por una pantalla de aplicaciones.
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	var date := Label.new()
	date.text = "MI CAMPUS"
	date.add_theme_font_size_override("font_size",12)
	date.add_theme_color_override("font_color",Color("91b4d0"))
	column.add_child(date)
	var heading := Label.new()
	heading.text = "Hola, estudiante."
	heading.add_theme_font_size_override("font_size",25)
	column.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "Todo tu día, en un lugar."
	subtitle.add_theme_font_size_override("font_size",13)
	subtitle.add_theme_color_override("font_color",Color("9fb4c9"))
	column.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 12
	column.add_child(spacer)
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("223e59")
	style.set_corner_radius_all(16)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel",style)
	column.add_child(card)
	badge = Label.new()
	badge.text = "✉  "+str(campaign.phone.unread_count())+" mensajes sin leer\nPiso "+(campaign.floor_current if not campaign.floor_current.is_empty() else campaign.phone._floor_for(campaign.player))+"  ·  "+campaign.academics.clock_text()
	badge.add_theme_font_size_override("font_size",14)
	card.add_child(badge)
	var grid := GridContainer.new()
	grid.name = "AppGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	column.add_child(grid)
	var apps := [
		["map","Mapa","map","4095d5"],["quests","Misiones","list","a57aea"],
		["messages","Mensajes","chat","35b68c"],["contacts","Contactos","person","dc9d4c"],
		["nexo","NEXO","chip","4bc3d3"],["collectibles","Colección","star","d2ad55"],
		["stats","Estadísticas","chart","dc737d"],["settings","Ajustes","gear","7f91ab"],
		["schedule","Horario","list","5cb6a1"]]
	for app in apps:
		var button := Button.new()
		button.name = app[0]
		button.text = app[1]
		button.icon = _icon(app[2])
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = false
		button.add_theme_constant_override("icon_max_width",24)
		button.add_theme_font_size_override("font_size",12)
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size = Vector2(0,70)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tile := StyleBoxFlat.new()
		tile.bg_color = Color(app[3]).darkened(0.52)
		tile.border_color = Color(app[3]).darkened(0.15)
		tile.set_border_width_all(1)
		tile.set_corner_radius_all(16)
		tile.set_content_margin_all(8)
		button.add_theme_stylebox_override("normal",tile)
		var hover: StyleBoxFlat = tile.duplicate()
		hover.bg_color = Color(app[3]).darkened(0.28)
		button.add_theme_stylebox_override("hover",hover)
		button.add_theme_stylebox_override("focus",hover)
		if app[0] == "messages":
			button.pressed.connect(campaign.phone.messages)
		elif app[0] == "contacts":
			button.pressed.connect(campaign.phone.contacts)
		else:
			button.pressed.connect(campaign.phone.app.bind(app[0]))
		grid.add_child(button)

func _icon(kind: String) -> Texture2D:
	var shapes := {
		"map":'<path d="M5 8l9-4 8 4 9-4v24l-9 4-8-4-9 4zM14 4v24M22 8v24"/>',
		"list":'<rect x="6" y="5" width="24" height="27" rx="4"/><path d="M11 13l2 2 3-4M20 13h5M11 23l2 2 3-4M20 23h5"/>',
		"chat":'<path d="M6 5h24v20H15l-9 7zM12 12h12M12 18h8"/>',
		"person":'<circle cx="18" cy="11" r="6"/><path d="M6 32v-4a12 12 0 0124 0v4z"/>',
		"chip":'<rect x="9" y="9" width="18" height="18" rx="3"/><path d="M14 14h8v8h-8zM13 3v6M23 3v6M13 27v6M23 27v6M3 13h6M3 23h6M27 13h6M27 23h6"/>',
		"star":'<path d="M18 3l5 10 11 2-8 8 2 11-10-5-10 5 2-11-8-8 11-2z"/>',
		"chart":'<path d="M5 4v28h28M11 26V17h4v9M20 26V11h4v15M29 26V6h4v20"/>',
		"gear":'<circle cx="18" cy="18" r="10"/><circle cx="18" cy="18" r="4"/><path d="M18 2v6M18 28v6M2 18h6M28 18h6M6 6l5 5M25 25l5 5M6 30l5-5M25 11l5-5"/>'}
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 36 36"><g fill="none" stroke="#e5f2ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'+str(shapes[kind])+'</g></svg>'
	var picture := Image.new()
	picture.load_svg_from_string(svg)
	return ImageTexture.create_from_image(picture)
