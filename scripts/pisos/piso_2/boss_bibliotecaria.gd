extends Node3D
## Duelo literario: la vida del jugador es la misma del resto del juego.
const Humanoid = preload("res://scripts/juego/humanoid.gd")
const QUESTIONS := [
	["Don Quijote de la Mancha", "¿Cómo se llama el escudero de Don Quijote?", "Sancho Panza", "Rocinante", "Hamlet"],
	["Don Quijote de la Mancha", "¿Quién escribió esta novela?", "Miguel de Cervantes", "Pablo Neruda", "Julio Verne"],
	["El principito", "¿Qué animal le enseña al principito sobre la amistad?", "Un zorro", "Un lobo", "Un caballo"],
	["El principito", "¿Qué flor cuida el principito en su planeta?", "Una rosa", "Un girasol", "Una margarita"],
	["Harry Potter y la piedra filosofal", "¿Cómo se llama la escuela de magia de Harry?", "Hogwarts", "Narnia", "La Comarca"],
	["El hobbit", "¿Cómo se llama el hobbit protagonista?", "Bilbo Bolsón", "Frodo Bolsón", "Gandalf"],
	["El señor de los anillos", "¿Dónde debe destruirse el Anillo Único?", "En el Monte del Destino", "En Rivendel", "En Minas Tirith"],
	["Las aventuras de Alicia en el país de las maravillas", "¿Qué animal sigue Alicia al comienzo?", "Un conejo blanco", "Un gato negro", "Un ratón gris"],
	["La vuelta al mundo en ochenta días", "¿Cómo se llama el viajero que acepta la apuesta?", "Phileas Fogg", "Capitán Nemo", "Robinson Crusoe"],
	["Veinte mil leguas de viaje submarino", "¿Cómo se llama el submarino del capitán Nemo?", "Nautilus", "Titanic", "Hispaniola"],
	["La metamorfosis", "¿Cómo se llama el protagonista que despierta transformado?", "Gregor Samsa", "Dorian Gray", "Oliver Twist"],
	["Cien años de soledad", "¿En qué pueblo transcurre la historia de los Buendía?", "Macondo", "Comala", "Santa María"],
	["Moby Dick", "¿Qué clase de animal persigue el capitán Ahab?", "Un cachalote", "Un tiburón", "Un pulpo"],
	["Pinocho", "¿Qué le ocurre a su nariz cuando miente?", "Crece", "Desaparece", "Cambia de color"],
	["El león, la bruja y el armario", "¿Por qué objeto entran los niños a Narnia?", "Un armario", "Un espejo", "Un reloj"],
	["Frankenstein", "¿Quién escribió esta novela?", "Mary Shelley", "Agatha Christie", "Jane Austen"]
]
@export var max_health: float = 125.0
@export var answer_damage: float = 25.0
@export var mistake_damage: float = 25.0
@export var interaction_range: float = 4.5
var health: float
var defeated := false
var active := false
var resolved := false
var answered := false
var player: CharacterBody3D
var visual: Humanoid
var prompt: Label3D
var overlay: Control
var health_text: Label
var question_text: Label
var feedback: Label
var next_button: Button
var answers: Array[Button] = []
var deck: Array[int] = []
var current_question: Array
var previous_mouse_mode: int
var previous_pause := false
var boss_bar: ProgressBar
var player_bar: ProgressBar
var reply_text: Label
var damage_flash: ColorRect
var duel_camera: Camera3D
var previous_camera: Camera3D
var health_tween: Tween
var hit_tween: Tween
var world_health: Label3D
var world_fill: MeshInstance3D
var damage_number: Label3D
var damage_tween: Tween
var hidden_layers: Array[CanvasLayer] = []

func _ready() -> void:
	health = max_health
	process_mode = Node.PROCESS_MODE_ALWAYS
	visual = Humanoid.new()
	visual.scale = Vector3.ONE * 1.5
	visual.shirt_color = Color("72475c")
	visual.pants_color = Color("343044")
	visual.hair_color = Color("a7a09a")
	visual.angry = true
	add_child(visual)
	# Moño, falda y lentes, siguiendo el estilo procedural de los personajes.
	visual._ball(visual.head_pivot, 0.075, Vector3(0, 0.16, 0.09), visual.hair_color)
	visual._cyl(visual.hips, 0.145, 0.24, 0.48, Vector3(0, -0.24, 0), visual.pants_color)
	for x in [-0.047, 0.047]:
		for y in [0.075, 0.116]:
			visual._box(visual.head_pivot, Vector3(0.073, 0.007, 0.01), Vector3(x, y, -0.106), Color("24212a"))
		for side in [-1, 1]:
			visual._box(visual.head_pivot, Vector3(0.007, 0.045, 0.01), Vector3(x + side * 0.035, 0.095, -0.106), Color("24212a"))
	visual._box(visual.head_pivot, Vector3(0.023, 0.008, 0.012), Vector3(0, 0.1, -0.11), Color("24212a"))
	visual._box(visual.hand_l, Vector3(0.15, 0.05, 0.21), Vector3(0, -0.03, -0.05), Color("a33637"))
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 2.7
	collision.shape = capsule
	collision.position.y = 1.35
	body.add_child(collision)
	add_child(body)
	prompt = Label3D.new()
	prompt.position.y = 3.15
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.font_size = 40
	prompt.pixel_size = 0.004
	prompt.text = "Doña Elvira · Bibliotecaria\n[E] Duelo de libros"
	add_child(prompt)
	_build_world_health()
	_build_ui()

func _build_world_health() -> void:
	world_health = Label3D.new()
	world_health.position.y = 2.85
	world_health.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	world_health.font_size = 36
	world_health.pixel_size = 0.003
	add_child(world_health)
	for fill in [false, true]:
		var bar := MeshInstance3D.new()
		bar.position = Vector3(0, 2.7, 0.01 if fill else 0.0)
		var mesh := QuadMesh.new()
		mesh.size = Vector2(1.8 if fill else 1.9, 0.12 if fill else 0.18)
		bar.mesh = mesh
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.no_depth_test = true
		material.render_priority = 1 if fill else 0
		material.albedo_color = Color("c86189") if fill else Color("211c2b")
		bar.material_override = material
		add_child(bar)
		bar.visible = false
		if fill:
			world_fill = bar
		else:
			bar.name = "FondoVidaBibliotecaria"
	damage_number = Label3D.new()
	damage_number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	damage_number.no_depth_test = true
	damage_number.font_size = 72
	damage_number.pixel_size = 0.004
	damage_number.modulate = Color("ff7186")
	damage_number.hide()
	add_child(damage_number)
	world_health.hide()

func _panel_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _make_bar(parent: Node, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(230, 20)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _panel_style(Color("251f31"), Color("41364f")))
	bar.add_theme_stylebox_override("fill", _panel_style(color, color))
	parent.add_child(bar)
	return bar

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	overlay = Control.new()
	layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()
	damage_flash = ColorRect.new()
	damage_flash.color = Color(1, 0.1, 0.15, 0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(damage_flash)
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.05, 0.11, 0.94), Color("ad8653")))
	overlay.add_child(status_panel)
	status_panel.anchor_left = 0.15
	status_panel.anchor_right = 0.85
	status_panel.offset_top = 18
	var status_list := VBoxContainer.new()
	status_panel.add_child(status_list)
	health_text = Label.new()
	health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_list.add_child(health_text)
	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 20)
	status_list.add_child(bars)
	boss_bar = _make_bar(bars, Color("c86189"))
	player_bar = _make_bar(bars, Color("55b5ac"))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.05, 0.11, 0.96), Color("ad8653")))
	overlay.add_child(panel)
	panel.anchor_left = 0.06
	panel.anchor_right = 0.94
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -330
	panel.offset_bottom = -14
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	panel.add_child(list)
	var title := Label.new()
	title.text = "DOÑA ELVIRA · BIBLIOTECARIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("e8bd7c"))
	list.add_child(title)
	question_text = Label.new()
	question_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_text.custom_minimum_size = Vector2(0, 54)
	question_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_text.add_theme_font_size_override("font_size", 19)
	list.add_child(question_text)
	reply_text = Label.new()
	reply_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reply_text.text = "TÚ · Elige lo que vas a decir (1, 2 o 3)"
	reply_text.add_theme_color_override("font_color", Color("87d5cc"))
	reply_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(reply_text)
	for i in range(3):
		var button := Button.new()
		button.custom_minimum_size.y = 34
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_stylebox_override("normal", _panel_style(Color("262135"), Color("504361")))
		button.add_theme_stylebox_override("hover", _panel_style(Color("3a304d"), Color("e8bd7c")))
		button.pressed.connect(_answer.bind(i))
		list.add_child(button)
		answers.append(button)
	feedback = Label.new()
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 42
	list.add_child(feedback)
	next_button = Button.new()
	next_button.text = "Siguiente pregunta"
	next_button.custom_minimum_size.y = 32
	next_button.pressed.connect(_next)
	list.add_child(next_button)
	var close := Button.new()
	close.text = "Salir del duelo (Esc)"
	close.pressed.connect(_close)
	list.add_child(close)
	overlay.hide()

func _layout_ui() -> void:
	# Mantener todo dentro de la ventana, incluso en la vista pequeña del editor.
	var viewport_size := get_viewport().get_visible_rect().size
	var ui_scale := clampf(minf(viewport_size.x / 960.0, viewport_size.y / 640.0), 0.25, 1.25)
	overlay.scale = Vector2.ONE * ui_scale
	overlay.size = viewport_size / ui_scale
	overlay.position = Vector2.ZERO

func _process(delta: float) -> void:
	if not active:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	visual.animate(delta, Vector3.ZERO, true, false)
	if active and is_instance_valid(player):
		# El mundo está pausado, pero las reacciones de ambos personajes continúan.
		player.body.animate(delta, Vector3.ZERO, true, false)
	prompt.visible = not active and is_instance_valid(player) and global_position.distance_to(player.global_position) <= interaction_range
	if is_instance_valid(player) and not defeated:
		var offset := player.global_position - global_position
		if Vector2(offset.x, offset.z).length() > 0.1:
			visual.rotation.y = atan2(-offset.x, -offset.z)

func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if active:
		if key.keycode == KEY_ESCAPE:
			_close()
		elif key.keycode in [KEY_1, KEY_2, KEY_3] and not answered:
			_answer(key.keycode - KEY_1)
		elif key.keycode == KEY_ENTER and answered:
			_next()
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_E and not has_node("BossDuelController") and _can_interact():
		interact(player)
		get_viewport().set_input_as_handled()

func _can_interact() -> bool:
	if not is_instance_valid(player) or defeated or player.get("dead") == true or player.get("busy") == true or get_tree().paused:
		return false
	if global_position.distance_to(player.global_position) > interaction_range:
		return false
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.6, global_position + Vector3.UP * 1.6)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or is_ancestor_of(hit.get("collider"))

func interact(candidate: CharacterBody3D) -> void:
	player = candidate
	if active or not _can_interact():
		return
	previous_mouse_mode = Input.mouse_mode
	previous_pause = get_tree().paused
	player.set("busy", true)
	player.set("velocity", Vector3.ZERO)
	get_tree().paused = true
	_start_duel_camera()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	active = true
	resolved = false
	hidden_layers.clear()
	for node in get_tree().root.find_children("*", "CanvasLayer", true, false):
		var canvas := node as CanvasLayer
		if canvas.visible and not is_ancestor_of(canvas):
			hidden_layers.append(canvas)
			canvas.hide()
	overlay.show()
	_show_question()

func _start_duel_camera() -> void:
	previous_camera = get_viewport().get_camera_3d()
	duel_camera = Camera3D.new()
	duel_camera.fov = 58
	add_child(duel_camera)
	var direction := player.global_position - global_position
	direction.y = 0
	if direction.length() < 0.1:
		direction = Vector3.FORWARD
	direction = direction.normalized().rotated(Vector3.UP, 0.65)
	duel_camera.global_position = global_position + direction * 4.8 + Vector3.UP * 2.7
	duel_camera.look_at(global_position + Vector3.UP * 0.85)
	duel_camera.make_current()

func _show_question() -> void:
	if deck.is_empty():
		for i in range(QUESTIONS.size()):
			deck.append(i)
		deck.shuffle()
	current_question = QUESTIONS[deck.pop_back()]
	var options: Array = [current_question[2], current_question[3], current_question[4]]
	options.shuffle()
	question_text.text = "«Hablemos de %s. %s»" % [current_question[0], current_question[1]]
	reply_text.text = "TÚ · Elige lo que vas a decir (1, 2 o 3)"
	for i in range(3):
		answers[i].text = "%d. «Creo que la respuesta es: %s.»" % [i + 1, options[i]]
		answers[i].set_meta("reply", options[i])
		answers[i].show()
		answers[i].set_meta("correct", options[i] == current_question[2])
		answers[i].disabled = false
	answered = false
	feedback.text = ""
	feedback.hide()
	next_button.hide()
	_update_health()
	answers[0].grab_focus()

func _answer(index: int) -> void:
	if not active or answered or resolved or index < 0 or index >= answers.size():
		return
	answered = true
	feedback.show()
	reply_text.text = "TÚ: «Creo que la respuesta es: %s.»" % answers[index].get_meta("reply")
	for button in answers:
		button.disabled = true
		button.hide()
	if answers[index].get_meta("correct"):
		health = maxf(0, health - answer_damage)
		var campaign := get_tree().get_first_node_in_group("campus_campaign")
		if campaign:
			campaign.event("answer","bibliotecaria")
		visual.hurt()
		_show_damage(answer_damage)
		feedback.text = "DOÑA ELVIRA: «¡Correcto! Veo que sí has leído... No me rendiré tan fácil.»\nLa bibliotecaria pierde %d de vida." % int(answer_damage)
	else:
		player.call("take_hit", Vector3.ZERO, mistake_damage)
		_flash_player_damage()
		feedback.text = "DOÑA ELVIRA: «Te equivocaste. La respuesta es %s. ¡Debes leer más!»\nPierdes %d de vida." % [current_question[2], int(mistake_damage)]
	_update_health(true)
	if health <= 0:
		defeated = true
		resolved = true
		visual.die()
		prompt.text = "Doña Elvira\n¡Duelo superado!"
		feedback.text += "\n¡Ganaste! «Has demostrado conocer mis libros.»"
	elif player.get("dead") == true:
		resolved = true
		feedback.text += "\nPerdiste el duelo. Cierra y presiona R para reiniciar."
	next_button.text = "Volver al juego" if resolved else "Siguiente pregunta"
	next_button.show()
	next_button.grab_focus()

func _update_health(animated: bool = false) -> void:
	health_text.text = "Bibliotecaria: %d / %d     Tu vida: %d / %d" % [int(health), int(max_health), int(player.get("health")), int(player.get("max_health"))]
	boss_bar.max_value = max_health
	player_bar.max_value = player.max_health
	world_health.text = "Doña Elvira · %d / %d" % [int(health), int(max_health)]
	world_health.visible = not active
	world_fill.visible = not active
	get_node("FondoVidaBibliotecaria").visible = not active
	if health_tween and health_tween.is_valid():
		health_tween.kill()
	var mesh := world_fill.mesh as QuadMesh
	var width := maxf(0.001, 1.8 * health / maxf(1, max_health))
	if animated:
		health_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		health_tween.tween_property(boss_bar, "value", health, 0.65)
		health_tween.tween_property(player_bar, "value", player.health, 0.65)
		health_tween.tween_property(mesh, "size:x", width, 0.65)
		health_tween.tween_property(mesh, "center_offset:x", -(1.8 - width) / 2, 0.65)
	else:
		boss_bar.value = health
		player_bar.value = player.health
		mesh.size.x = width
		mesh.center_offset.x = -(1.8 - width) / 2

func _show_damage(amount: float) -> void:
	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()
	damage_number.text = "−%d" % int(amount)
	damage_number.position = Vector3(0.8, 2.3, 0)
	damage_number.modulate.a = 1
	damage_number.show()
	damage_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	damage_tween.tween_property(damage_number, "position:y", 3.0, 1.0)
	damage_tween.tween_property(damage_number, "modulate:a", 0.0, 1.0)
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
	var recoil := global_position - player.global_position
	recoil.y = 0
	visual.position = recoil.normalized() * 0.22
	hit_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	hit_tween.tween_property(visual, "position", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _flash_player_damage() -> void:
	damage_flash.color.a = 0.3
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(damage_flash, "color:a", 0.0, 0.55)

func _next() -> void:
	if not active or not answered:
		return
	if resolved:
		_close()
	else:
		_show_question()

func _close() -> void:
	if not active:
		return
	active = false
	overlay.hide()
	world_health.show()
	world_fill.show()
	get_node("FondoVidaBibliotecaria").show()
	for canvas in hidden_layers:
		if is_instance_valid(canvas):
			canvas.show()
	hidden_layers.clear()
	if is_instance_valid(previous_camera):
		previous_camera.make_current()
	if is_instance_valid(duel_camera):
		duel_camera.queue_free()
	if is_instance_valid(player):
		player.set("busy", false)
	get_tree().paused = previous_pause
	Input.mouse_mode = previous_mouse_mode as Input.MouseMode

func _exit_tree() -> void:
	if active:
		_close()
