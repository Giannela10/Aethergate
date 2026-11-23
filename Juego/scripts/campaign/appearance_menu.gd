class_name AppearanceMenu
extends Node

const Profile = preload("res://scripts/juego/character_appearance.gd")
const Look = preload("res://scripts/campaign/campus_menu_style.gd")
const Stage = preload("res://scripts/campaign/campus_avatar_stage.gd")
const SECTIONS := {
	"Ropa": ["top", "bottom_style", "shoe_style", "clothes"],
	"Mochila": ["backpack", "backpack_color"],
	"Cabeza": ["hair", "head_accessory", "hair_color"],
	"Accesorios": ["accessory", "outfit"],
	"Colores": ["clothes", "pants", "shoes", "backpack_color"],
	"Apariencia": ["body_type", "face", "skin", "hair"]
}
const LABELS := {"body_type":"Personaje","top":"Polerones y chaquetas","bottom_style":"Pantalones","shoe_style":"Calzado","clothes":"Color principal","backpack":"Mochila","backpack_color":"Color de mochila","hair":"Cabello","head_accessory":"Accesorios de cabeza","hair_color":"Color de cabello","accessory":"Accesorios","outfit":"Conjuntos","pants":"Color de pantalón","shoes":"Color de calzado","face":"Forma del rostro","skin":"Tono de piel"}

var campaign: Node
var working := {}
var original := {}
var allowed := {}
var preview: Node3D
var preview_container: SubViewportContainer
var starting := false
var return_action: Callable
var canvas: Control
var options: Control
var current_section := "Ropa"
var category_buttons := {}
var selectors := {}

func open(new_game: bool = false, on_return: Callable = Callable()) -> void:
	starting = new_game
	return_action = on_return
	Profile.unlock_from_progress(campaign.data.bosses, campaign.data.cosmetics)
	allowed = {} if starting else campaign.data.cosmetics.duplicate()
	working = Profile.normalize(Profile.CAMPUS_REFERENCE if starting else campaign.data.appearance, allowed)
	original = working.duplicate()
	current_section = "Ropa"
	category_buttons.clear()
	var screen: Control = campaign.ui.open_fullscreen(_cancel)
	canvas = Look.screen(screen)
	Look.stripe(canvas, Rect2(24, 27, 4, 49))
	Look.label(canvas, "DuocUC", Rect2(40, 23, 133, 52), 30)
	Look.label(canvas, "Personalización", Rect2(185, 24, 425, 37), 30)
	Look.label(canvas, "Crea y personaliza tu personaje", Rect2(187, 62, 420, 25), 16, Look.MUTED)

	Look.panel(canvas, Rect2(19, 108, 191, 374))
	var index := 0
	var marks := ["▦", "▣", "◇", "◈", "◉", "●"]
	for section in SECTIONS:
		var nav := _category("%s   %s" % [marks[index], section], section, Rect2(31, 123 + index * 56, 167, 47))
		nav.alignment = HORIZONTAL_ALIGNMENT_LEFT
		index += 1

	Look.panel(canvas, Rect2(645, 50, 487, 55))
	_category("Vestimenta", "Ropa", Rect2(654, 58, 145, 38))
	_category("Accesorios", "Accesorios", Rect2(807, 58, 145, 38))
	_category("Colores", "Colores", Rect2(960, 58, 162, 38))
	Look.panel(canvas, Rect2(645, 113, 487, 430))

	var platform := AvatarPlatform.new()
	platform.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Look.place(canvas, platform, Rect2(257, 501, 342, 80))
	preview_container = Stage.new()
	preview_container.can_rotate = true
	preview_container.profile = working
	Look.place(canvas, preview_container, Rect2(213, 79, 427, 494))
	preview = preview_container.model
	Look.button(canvas, "↶", Rect2(285, 533, 44, 35), func(): preview_container.rotate_by(-PI/6), false, 19).tooltip_text = "Girar a la izquierda"
	Look.button(canvas, "↷", Rect2(536, 533, 44, 35), func(): preview_container.rotate_by(PI/6), false, 19).tooltip_text = "Girar a la derecha"
	Look.button(canvas, "−", Rect2(378, 533, 44, 35), func(): preview_container.zoom_by(-0.15), false, 19).tooltip_text = "Alejar"
	Look.button(canvas, "+", Rect2(428, 533, 44, 35), func(): preview_container.zoom_by(0.15), false, 19).tooltip_text = "Acercar"
	Look.button(canvas, "Rostro", Rect2(478, 533, 54, 35), func(): preview_container.toggle_face_focus(), false, 12).tooltip_text = "Alternar entre el rostro y el cuerpo completo"

	Look.button(canvas, "◇   Apariencia aleatoria", Rect2(25, 583, 203, 46), _randomize, false, 15)
	Look.button(canvas, "Estudiante DuocUC", Rect2(241, 583, 179, 46), _apply_campus_reference, false, 15)
	Look.button(canvas, "Cancelar", Rect2(594, 583, 116, 46), _cancel, false, 15)
	Look.button(canvas, "↻  Restablecer", Rect2(720, 583, 153, 46), _reset, false, 15)
	Look.button(canvas, "✓  Confirmar apariencia", Rect2(884, 578, 248, 56), _confirm, true, 18)
	_choose_section(current_section)
	category_buttons["Ropa"][0].grab_focus()

func _category(value: String, section: String, rect: Rect2) -> Button:
	var control := Look.button(canvas, value, rect, _choose_section.bind(section), false, 16)
	if not category_buttons.has(section):
		category_buttons[section] = []
	category_buttons[section].append(control)
	return control

func _choose_section(section: String) -> void:
	current_section = section
	for name in category_buttons:
		for item in category_buttons[name]:
			Look.tone(item, name == section)
	if is_instance_valid(options):
		options.hide()
		options.queue_free()
	options = Control.new()
	options.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Look.place(canvas, options, Rect2(661, 122, 454, 408))
	selectors.clear()
	var row := 0
	for key in SECTIONS[section]:
		_build_row(key, row * 102)
		row += 1
	_update_cards()

func _build_row(key: String, y: float) -> void:
	Look.label(options, LABELS[key], Rect2(2, y, 451, 25), 17)
	var scroller := ScrollContainer.new()
	scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroller.follow_focus = true
	var has_more: bool = Profile.OPTIONS[key].size() > 5
	Look.place(options, scroller, Rect2(0, y + 27, 416 if has_more else 454, 65))
	if has_more:
		Look.button(options, "›", Rect2(421, y + 30, 33, 48), func():
			var bar := scroller.get_h_scroll_bar()
			var end := maxf(0, bar.max_value - bar.page)
			scroller.scroll_horizontal = 0 if scroller.scroll_horizontal >= end - 2 else mini(int(end), scroller.scroll_horizontal + 248)
		, false, 20).tooltip_text = "Ver más opciones"
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 6)
	scroller.add_child(strip)
	selectors[key] = []
	for i in Profile.OPTIONS[key].size():
		var card := Button.new()
		card.custom_minimum_size = Vector2(146 if key == "body_type" else 78, 57)
		card.tooltip_text = Profile.OPTIONS[key][i]
		card.disabled = _locked(key, i)
		card.pressed.connect(_select.bind(i, key))
		strip.add_child(card)
		var icon := OptionArt.new()
		icon.kind = key
		icon.variant = i
		icon.color = _option_color(key, i)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var width := card.custom_minimum_size.x
		Look.place(card, icon, Rect2((width - 58) * 0.5, 3, 58, 33))
		var caption := Look.label(card, Profile.OPTIONS[key][i], Rect2(4, 36, width - 8, 18), 10)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if card.disabled:
			var locked := Look.label(card, "×", Rect2(65, 1, 13, 16), 14, Look.MUTED)
			locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card.tooltip_text += " · Bloqueado"
		selectors[key].append({"button":card,"caption":caption,"art":icon})

func _option_color(key: String, i: int) -> Color:
	if key == "skin":
		return Color(Profile.SKIN[i])
	if key == "hair_color":
		return Color(Profile.HAIR[i])
	if key in ["clothes", "pants", "shoes", "backpack_color"]:
		return Color(Profile.COLORS[i])
	var choices := ["#426b9a","#aab9d1","#49576e","#c69a71","#875964","#575c96","#7e8b55","#538889","#caa046"]
	return Color(choices[i % choices.size()])

func _locked(key: String, index: int) -> bool:
	var unlock: String = Profile.LOCKS.get("%s:%d" % [key, index], "")
	return not unlock.is_empty() and not allowed.get(unlock, false)

func _update_cards() -> void:
	for key in selectors:
		for i in selectors[key].size():
			var row: Dictionary = selectors[key][i]
			var selected: bool = working[key] == i
			Look.tone(row.button, selected)
			row.caption.add_theme_color_override("font_color", Look.INK if selected else Look.PALE)
			row.art.modulate.a = 0.48 if row.button.disabled else 1.0

func _select(index: int, key: String) -> void:
	if _locked(key, index):
		return
	working[key] = index
	_apply_profile()

func _apply_profile() -> void:
	working = Profile.normalize(working, allowed)
	if is_instance_valid(preview_container):
		preview_container.set_profile(working)
	_update_cards()

func _randomize() -> void:
	for key in Profile.OPTIONS:
		var available: Array[int] = []
		for i in Profile.OPTIONS[key].size():
			if not _locked(key, i):
				available.append(i)
		working[key] = available.pick_random()
	_apply_profile()

func _reset() -> void:
	working = original.duplicate()
	_apply_profile()

func _apply_campus_reference() -> void:
	working = Profile.CAMPUS_REFERENCE.duplicate()
	_apply_profile()

func _confirm() -> void:
	if starting:
		campaign.pending_appearance = working.duplicate()
		campaign.new_game()
		return
	campaign.data.appearance = Profile.normalize(working, allowed)
	campaign.player.body.apply_appearance(campaign.data.appearance)
	campaign.save_game()
	campaign.ui.close_modal()
	if return_action.is_valid():
		return_action.call()
	else:
		campaign.ui.notify("Apariencia guardada")

func _cancel() -> void:
	if return_action.is_valid():
		return_action.call()
	elif starting:
		campaign.show_start_menu()
	else:
		campaign.show_pause()

class AvatarPlatform extends Control:
	func _draw() -> void:
		var edge := PackedVector2Array()
		for i in range(65):
			var a := TAU * float(i) / 64.0
			edge.append(Vector2(size.x * 0.5 + cos(a) * size.x * 0.46, size.y * 0.5 + sin(a) * size.y * 0.34))
		draw_colored_polygon(edge.slice(0, 64), Color(0.02, 0.08, 0.18, 0.82))
		draw_polyline(edge, Color(1.0, 0.66, 0.17, 0.23), 10, true)
		draw_polyline(edge, Color("#ffce4b"), 3, true)

class OptionArt extends Control:
	var kind := ""
	var variant := 0
	var color := Color.WHITE

	func _draw() -> void:
		var light := color.lightened(0.28)
		var dark := color.darkened(0.27)
		if kind in ["clothes", "pants", "shoes", "backpack_color", "skin", "hair_color"]:
			draw_rect(Rect2(10, 4, 38, 25), dark)
			draw_rect(Rect2(12, 6, 34, 21), color)
			return
		match kind:
			"top", "outfit":
				_polygon([Vector2(19,3),Vector2(25,1),Vector2(31,6),Vector2(36,1),Vector2(42,4),Vector2(53,13),Vector2(46,20),Vector2(41,15),Vector2(42,32),Vector2(17,32),Vector2(18,15),Vector2(12,20),Vector2(5,13)], color)
				draw_line(Vector2(21,29), Vector2(38,29), light, 1.2, true)
				if variant > 0:
					draw_line(Vector2(29,8), Vector2(29,27), dark, 1.5, true)
			"bottom_style":
				_polygon([Vector2(18,2),Vector2(41,2),Vector2(44,32),Vector2(33,32),Vector2(29,14),Vector2(26,32),Vector2(15,32)], color)
				draw_line(Vector2(20,7),Vector2(39,7),light,1.4,true)
			"shoe_style":
				_polygon([Vector2(13,7),Vector2(27,8),Vector2(33,19),Vector2(47,20),Vector2(54,26),Vector2(52,31),Vector2(8,31),Vector2(5,26)], color)
				draw_line(Vector2(8,29),Vector2(52,29),light,2,true)
			"backpack":
				draw_arc(Vector2(29,10),7,PI,TAU,12,light,2,true)
				draw_rect(Rect2(16,8,26,24),dark)
				draw_rect(Rect2(19,9,20,20),color)
				draw_rect(Rect2(21,20,16,8),light)
			"accessory":
				draw_arc(Vector2(20,17),8,0,TAU,18,color,2.6,true)
				draw_arc(Vector2(40,17),8,0,TAU,18,color,2.6,true)
				draw_line(Vector2(27,15),Vector2(33,15),light,2,true)
			_:
				draw_circle(Vector2(29,15),11,color,true,-1,true)
				draw_rect(Rect2(20,26,18,5),dark)
				if kind != "face":
					draw_arc(Vector2(29,13),11,PI,TAU,22,light,3,true)

	func _polygon(points: Array[Vector2], fill: Color) -> void:
		draw_colored_polygon(PackedVector2Array(points), fill)
