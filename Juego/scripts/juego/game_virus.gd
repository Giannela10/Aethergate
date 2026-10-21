extends Control
## Minijuego 2: ANTIVIRUS.
## Aparecen virus (cuadros rojos) entre los archivos. Haz clic en ellos antes de que desaparezcan.

signal completed

const COLS := 4
const ROWS := 3
var GOAL := 8             # virus que hay que atrapar
var VIRUS_TIME := 1.6     # segundos que dura cada virus
var SPAWN_EVERY := 0.7    # cada cuánto aparece uno nuevo
const MAX_AT_ONCE := 2

var buttons: Array = []
var timers: Array = []      # segundos restantes de cada casilla (0 = sin virus)
var file_names := ["datos.sys", "foto.jpg", "musica.mp3", "tarea.docx", "juego.exe", "video.mp4",
		"notas.txt", "clave.dat", "correo.eml", "mapa.png", "backup.zip", "logo.svg"]
var caught := 0
var spawn_t := 0.6
var done := false
var info: Label
var bar: ProgressBar
var sb_file: StyleBoxFlat
var sb_virus: StyleBoxFlat


func start() -> void:
	sb_file = _flat(Color(0.30, 0.34, 0.42))
	sb_virus = _flat(Color(0.85, 0.15, 0.15))
	_build_ui()


func _flat(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(8)
	return sb


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var help := Label.new()
	help.text = "¡Hay virus en el computador!\nHaz clic en los cuadros rojos VIRUS antes de que desaparezcan."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 18)
	root.add_child(help)

	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 20)
	root.add_child(info)

	bar = ProgressBar.new()
	bar.max_value = GOAL
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(400, 16)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(bar)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	center.add_child(grid)

	for i in COLS * ROWS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 80)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_cell.bind(i))
		grid.add_child(btn)
		buttons.append(btn)
		timers.append(0.0)
		_apply(i, false)
	_update_info()


## Cambia el aspecto de una casilla: archivo normal o virus.
func _apply(i: int, virus: bool) -> void:
	var btn: Button = buttons[i]
	var sb := sb_virus if virus else sb_file
	btn.text = "VIRUS!" if virus else file_names[i % file_names.size()]
	for state in ["normal", "hover", "pressed"]:
		btn.add_theme_stylebox_override(state, sb)


func _update_info() -> void:
	info.text = "Virus eliminados: %d / %d" % [caught, GOAL]
	bar.value = caught


func _process(delta: float) -> void:
	if done or buttons.is_empty():
		return
	for i in timers.size():
		if timers[i] > 0.0:
			timers[i] -= delta
			if timers[i] <= 0.0:
				_apply(i, false)     # el virus escapó
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = SPAWN_EVERY
		_spawn_virus()


func _spawn_virus() -> void:
	var free_cells: Array = []
	var active := 0
	for i in timers.size():
		if timers[i] > 0.0:
			active += 1
		else:
			free_cells.append(i)
	if active >= MAX_AT_ONCE or free_cells.is_empty():
		return
	var idx: int = free_cells[randi() % free_cells.size()]
	timers[idx] = VIRUS_TIME
	_apply(idx, true)


func _on_cell(i: int) -> void:
	if done or timers[i] <= 0.0:
		return
	timers[i] = 0.0
	_apply(i, false)
	caught += 1
	_update_info()
	if caught >= GOAL:
		done = true
		completed.emit()
func configure_difficulty(level: int) -> void:
	GOAL = 8+mini(4,floori(level/2.0))
	VIRUS_TIME = maxf(1.3,1.6-level*0.03)
	SPAWN_EVERY = maxf(0.55,0.7-level*0.015)
