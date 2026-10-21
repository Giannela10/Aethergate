extends Control
## Minijuego 3: CONTRASEÑA.
## Se muestra un código de 4 números durante unos segundos. Memorízalo y escríbelo en el teclado.
## Si te equivocas, el código se muestra de nuevo.

signal completed

var CODE_LEN := 4
var MEMORIZE_TIME := 4.0
const RETRY_TIME := 3.0

enum Phase { MEMORIZE, ENTER }

var code := ""
var entered := ""
var phase := Phase.MEMORIZE
var time_left := MEMORIZE_TIME
var time_total := MEMORIZE_TIME
var done := false

var info: Label
var code_label: Label
var bar: ProgressBar
var feedback: Label
var key_buttons: Array = []


func start() -> void:
	for _i in CODE_LEN:
		code += str(randi() % 10)
	_build_ui()
	_set_phase(Phase.MEMORIZE, MEMORIZE_TIME)


func _flat(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(8)
	return sb


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 22)
	root.add_child(info)

	# Pantallita con el código
	var screen := PanelContainer.new()
	screen.custom_minimum_size = Vector2(420, 100)
	screen.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	screen.add_theme_stylebox_override("panel", _flat(Color(0.05, 0.1, 0.07)))
	root.add_child(screen)
	code_label = Label.new()
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	code_label.add_theme_font_size_override("font_size", 64)
	code_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	screen.add_child(code_label)

	bar = ProgressBar.new()
	bar.max_value = 1.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(420, 12)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(bar)

	feedback = Label.new()
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 18)
	feedback.custom_minimum_size = Vector2(0, 26)
	root.add_child(feedback)

	# Teclado numérico
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	center.add_child(grid)

	for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "Borrar", "0", "Enviar"]:
		var btn := Button.new()
		btn.text = k
		btn.custom_minimum_size = Vector2(110, 52)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_key.bind(k))
		grid.add_child(btn)
		key_buttons.append(btn)


func _spaced(s: String) -> String:
	var parts: PackedStringArray = []
	for ch in s:
		parts.append(ch)
	return "  ".join(parts)


func _set_phase(p: Phase, seconds: float) -> void:
	phase = p
	time_total = seconds
	time_left = seconds
	var memorizing := (p == Phase.MEMORIZE)
	for b in key_buttons:
		(b as Button).disabled = memorizing
	if memorizing:
		info.text = "¡Memoriza el código!"
		code_label.text = _spaced(code)
		bar.visible = true
	else:
		info.text = "Ahora escribe el código que viste"
		bar.visible = false
		_refresh_entered()


func _refresh_entered() -> void:
	var shown := entered + "_".repeat(CODE_LEN - entered.length())
	code_label.text = _spaced(shown)


func _process(delta: float) -> void:
	if done or phase != Phase.MEMORIZE:
		return
	time_left -= delta
	bar.value = clampf(time_left / time_total, 0.0, 1.0)
	if time_left <= 0.0:
		entered = ""
		_set_phase(Phase.ENTER, 0.0)


func _on_key(k: String) -> void:
	if done or phase != Phase.ENTER:
		return
	if k == "Borrar":
		entered = entered.substr(0, maxi(entered.length() - 1, 0))
		feedback.text = ""
	elif k == "Enviar":
		_check()
		return
	elif entered.length() < CODE_LEN:
		entered += k
		feedback.text = ""
	_refresh_entered()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or done or phase != Phase.ENTER:
		return
	if key.keycode >= KEY_0 and key.keycode <= KEY_9:
		_on_key(str(key.keycode - KEY_0))
	elif key.keycode >= KEY_KP_0 and key.keycode <= KEY_KP_9:
		_on_key(str(key.keycode - KEY_KP_0))
	elif key.keycode == KEY_BACKSPACE:
		_on_key("Borrar")
	elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		_on_key("Enviar")
	else:
		return
	get_viewport().set_input_as_handled()


func _check() -> void:
	if entered == code:
		done = true
		feedback.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		feedback.text = "¡Contraseña correcta!"
		completed.emit()
	else:
		feedback.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		feedback.text = "Código incorrecto. Mira el código otra vez."
		entered = ""
		_set_phase(Phase.MEMORIZE, RETRY_TIME)
func configure_difficulty(level: int) -> void:
	CODE_LEN = 5 if level >= 7 else 4
	MEMORIZE_TIME = 5.0 if CODE_LEN == 5 else maxf(3.2,4.0-level*0.1)
