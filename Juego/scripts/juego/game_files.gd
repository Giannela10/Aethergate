extends Control
## Minijuego 1: ORDENAR ARCHIVOS.
## Aparece un archivo; haz clic en la carpeta correcta según su extensión (.jpg, .mp3...).
## Las carpetas muestran ejemplos para que cualquiera pueda jugarlo.

signal completed

var TOTAL := 6    # archivos a ordenar
var instructions := "Guarda cada archivo en su carpeta.\nFíjate en la extensión: lo que va después del punto."
var category_hint := ""
var progress_caption := "Archivos ordenados"
var wrong_answer := "Esa no es. Mira la extensión y los ejemplos de cada carpeta."

var folders := [
	{"name": "Imágenes", "hint": ".jpg  .png", "color": Color(0.23, 0.51, 0.96)},
	{"name": "Música", "hint": ".mp3  .wav", "color": Color(0.13, 0.70, 0.35)},
	{"name": "Videos", "hint": ".mp4  .avi", "color": Color(0.88, 0.25, 0.25)},
	{"name": "Documentos", "hint": ".docx  .txt", "color": Color(0.85, 0.65, 0.10)},
]
# [nombre del archivo, número de carpeta correcta]
var all_files := [
	["foto_vacaciones.jpg", 0], ["gato.png", 0],
	["mi_cancion.mp3", 1], ["sonido.wav", 1],
	["pelicula.mp4", 2], ["video_gracioso.avi", 2],
	["tarea.docx", 3], ["lista_compras.txt", 3],
]

var queue: Array = []
var index := 0
var done := false
var file_label: Label
var type_label: Label
var feedback: Label
var progress_label: Label


func start() -> void:
	queue = all_files.duplicate()
	queue.shuffle()
	queue = queue.slice(0, TOTAL)
	_build_ui()
	_show_file()


func _flat(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(10)
	return sb


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var info := Label.new()
	info.text = instructions
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 18)
	root.add_child(info)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 18)
	root.add_child(progress_label)

	# Tarjeta con el archivo actual
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(460, 140)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel", _flat(Color(0.95, 0.95, 0.97)))
	root.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)
	file_label = Label.new()
	file_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	file_label.add_theme_font_size_override("font_size", 34)
	file_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15))
	box.add_child(file_label)
	type_label = Label.new()
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 20)
	type_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
	box.add_child(type_label)

	feedback = Label.new()
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 20)
	feedback.custom_minimum_size = Vector2(0, 30)
	root.add_child(feedback)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	# Carpetas
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)
	for i in folders.size():
		var f: Dictionary = folders[i]
		var btn := Button.new()
		btn.text = "%s\n%s" % [f["name"], f["hint"]]
		btn.custom_minimum_size = Vector2(160, 90)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 18)
		var c: Color = f["color"]
		btn.add_theme_stylebox_override("normal", _flat(c.darkened(0.25)))
		btn.add_theme_stylebox_override("hover", _flat(c))
		btn.add_theme_stylebox_override("pressed", _flat(c.lightened(0.2)))
		btn.pressed.connect(_on_folder.bind(i))
		row.add_child(btn)


func _show_file() -> void:
	var f: Array = queue[index]
	var file_name: String = f[0]
	file_label.text = file_name
	type_label.text = category_hint if not category_hint.is_empty() else "Tipo de archivo: .%s" % file_name.get_extension()
	progress_label.text = "%s: %d / %d" % [progress_caption, index, TOTAL]


func _on_folder(i: int) -> void:
	if done or index >= queue.size():
		return
	var f: Array = queue[index]
	if i == f[1]:
		index += 1
		feedback.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		feedback.text = "¡Correcto!"
		if index >= TOTAL:
			done = true
			progress_label.text = "%s: %d / %d" % [progress_caption, TOTAL, TOTAL]
			completed.emit()
		else:
			_show_file()
	else:
		feedback.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		feedback.text = wrong_answer
func configure_difficulty(level: int) -> void:
	TOTAL = mini(8,6+floori(level/3.0))
