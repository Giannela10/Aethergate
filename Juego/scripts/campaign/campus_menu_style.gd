extends RefCounted

const DESIGN := Vector2(1152, 648)
const GOLD := Color("#ffc229")
const BLUE := Color("#65a6d9")
const INK := Color("#071929")
const PALE := Color("#f3f8ff")
const MUTED := Color("#b0c3d9")
const CAMPUS_ART := "res://resources/ui/campus_menu.png"
const FALLBACK := preload("res://resources/ui/campus_login.png")

static func place(parent: Control, child: Control, rect: Rect2) -> Control:
	parent.add_child(child)
	child.position = rect.position
	child.size = rect.size
	return child

static func box(fill: Color, edge: Color, radius: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(10)
	return style

static func surface(padding: int = 19, radius: int = 15) -> StyleBoxFlat:
	var style := box(Color("#0b1e32"), BLUE, radius)
	style.set_content_margin_all(padding)
	style.border_width_top = 3
	return style

static func panel(parent: Control, rect: Rect2, edge: Color = BLUE) -> Panel:
	var card := Panel.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", box(Color(0.03, 0.09, 0.16, 0.94), Color(edge, 0.66)))
	place(parent, card, rect)
	return card

static func label(parent: Control, value: String, rect: Rect2, font_size: int, color: Color = PALE) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.clip_text = true
	item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	place(parent, item, rect)
	return item

static func tone(button: Button, selected: bool = false, radius: int = 11) -> void:
	var normal := box(Color("#0e253d"), Color("#3d6588"), radius)
	var hover := box(Color("#173d61"), BLUE, radius)
	var active := box(GOLD, Color("#fff08a"), radius)
	active.set_border_width_all(2)
	var focus := box(Color.TRANSPARENT, PALE, radius)
	focus.set_border_width_all(2)
	if selected:
		active.shadow_color = Color(1, 0.66, 0.07, 0.40)
		active.shadow_size = 7
	button.add_theme_stylebox_override("normal", active if selected else normal)
	button.add_theme_stylebox_override("hover", active if selected else hover)
	button.add_theme_stylebox_override("pressed", active)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", box(Color("#142435"), Color("#304455"), radius))
	for property in ["font_color", "font_hover_color", "font_focus_color"]:
		button.add_theme_color_override(property, INK if selected else PALE)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("#9aadc1"))

static func button(parent: Control, value: String, rect: Rect2, action: Callable, selected: bool = false, font_size: int = 17) -> Button:
	var item := Button.new()
	item.text = value
	item.add_theme_font_size_override("font_size", font_size)
	item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tone(item, selected)
	item.pressed.connect(action)
	place(parent, item, rect)
	return item

static func screen(parent: Control) -> Control:
	var art := TextureRect.new()
	if ResourceLoader.exists(CAMPUS_ART):
		art.texture = load(CAMPUS_ART)
	elif FileAccess.file_exists(CAMPUS_ART):
		art.texture = ImageTexture.create_from_image(Image.load_from_file(CAMPUS_ART))
	else:
		art.texture = FALLBACK
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.38, 0.64, 1.0])
	gradient.colors = PackedColorArray([Color(0.015,0.055,0.10,0.98), Color(0.02,0.07,0.12,0.32), Color(0.02,0.07,0.13,0.23), Color(0.015,0.05,0.095,0.7)])
	var shade_texture := GradientTexture2D.new()
	shade_texture.gradient = gradient
	shade_texture.width = 256
	shade_texture.height = 2
	var shade := TextureRect.new()
	shade.texture = shade_texture
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var design := Control.new()
	design.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(design)
	design.size = DESIGN
	var resize := func():
		var factor := minf(parent.size.x / DESIGN.x, parent.size.y / DESIGN.y)
		design.scale = Vector2.ONE * maxf(0.01, factor)
		design.position = (parent.size - DESIGN * factor) * 0.5
	parent.resized.connect(resize)
	resize.call()
	return design

static func stripe(canvas: Control, rect: Rect2, color: Color = GOLD) -> void:
	var accent := ColorRect.new()
	accent.color = color
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(canvas, accent, rect)
