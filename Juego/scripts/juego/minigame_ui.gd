extends CanvasLayer
## Ventana de computador que se abre sobre la pantalla y aloja el minijuego elegido.
## main.gd la abre con open(id) y la cierra con close(exito).

signal finished(success: bool)

const GAME_SCRIPTS := [
	preload("res://scripts/juego/game_files.gd"),
	preload("res://scripts/juego/game_virus.gd"),
	preload("res://scripts/juego/game_password.gd"),
]
const TITLES := ["Ordenar archivos", "Antivirus", "Contraseña"]

var active := false
var session_id := 0
var closing := false        # true cuando el juego ya se ganó y se muestra el mensaje final

var title_label: Label
var holder: Control
var success_label: Label
var current                 # minijuego en pantalla (sin tipo a propósito)


func _ready() -> void:
	# Sobre HUD de campaña (40) e inventario (26), debajo del celular (55).
	layer = 50
	visible = false

	# Fondo oscuro (también bloquea los clics hacia el juego)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Ventana
	var window := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1f2430")
	sb.border_color = Color("4a5370")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(14)
	window.add_theme_stylebox_override("panel", sb)
	center.add_child(window)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	window.add_child(vbox)

	# Barra de título
	var bar := HBoxContainer.new()
	vbox.add_child(bar)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title_label)
	var close_btn := Button.new()
	close_btn.text = " X "
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(close.bind(false))
	bar.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	holder = Control.new()
	holder.custom_minimum_size = Vector2(740, 440)
	vbox.add_child(holder)

	var hint := Label.new()
	hint.text = "Esc o X para salir"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	vbox.add_child(hint)

	# Mensaje de éxito
	success_label = Label.new()
	success_label.text = "¡TAREA COMPLETADA!"
	success_label.add_theme_font_size_override("font_size", 56)
	success_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	success_label.add_theme_color_override("font_outline_color", Color.BLACK)
	success_label.add_theme_constant_override("outline_size", 10)
	success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	success_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	success_label.visible = false
	add_child(success_label)
	success_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func open(id: int, activity_profile: String = "") -> void:
	if active or id < 0 or id >= GAME_SCRIPTS.size():
		return
	session_id += 1
	active = true
	closing = false
	visible = true
	success_label.visible = false
	var activity = preload("res://scripts/juego/campus_activity.gd")
	var themed: bool = activity.PROFILES.has(activity_profile)
	title_label.text = "Computador - " + (activity.title_for(activity_profile) if themed else TITLES[id])
	current = activity.new() if themed else GAME_SCRIPTS[id].new()
	holder.add_child(current)
	current.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current.completed.connect(_on_completed)
	var campaign := get_tree().get_first_node_in_group("campus_campaign")
	if campaign and current.has_method("configure_difficulty"):
		current.configure_difficulty(8 if campaign.floor_current == "S" else int(campaign.floor_current))
	if themed:
		current.configure_activity(activity_profile)
	current.start()


func _on_completed() -> void:
	if not active or closing:
		return
	var completed_session := session_id
	closing = true
	success_label.visible = true
	await get_tree().create_timer(1.2).timeout
	if active and session_id == completed_session:
		close(true)


func close(success: bool = false) -> void:
	if not active:
		return
	if closing:
		success = true          # ya lo había ganado: aunque cierre con Esc cuenta
	active = false
	closing = false
	visible = false
	success_label.visible = false
	if current != null:
		current.queue_free()
		current = null
	finished.emit(success)
