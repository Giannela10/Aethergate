extends VBoxContainer
signal answered(value: Variant)
var activity: Dictionary = {}
var sequence: Array = []
var status: Label
var locked := false

func _ready() -> void:
	var prompt := Label.new()
	prompt.text = str(activity.get("prompt",""))
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(prompt)
	if not str(activity.get("image_path","")).is_empty(): _load_image.call_deferred()
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	var kind := str(activity.get("kind","multiple_choice"))
	var content: Dictionary = activity.get("content",{})
	if kind == "reflection":
		status.text = "Reflexión: no hay una única respuesta ni una nota oficial."
		var text := TextEdit.new()
		text.custom_minimum_size.y = 120
		add_child(text)
		_button("ENVIAR REFLEXIÓN",func():
			if not text.text.strip_edges().is_empty(): _send(text.text.strip_edges()))
	elif kind in ["ordering","sequence","matching","practical"]:
		status.text = "Selecciona los elementos en orden. En relaciones, sigue el orden de las claves indicadas en el enunciado."
		var items: Array = content.get("items",[])
		for index in items.size():
			var button := _button(str(index+1)+". "+str(items[index]),_pick.bind(index,items.size()))
			button.pressed.connect(func(): button.disabled = true)
		_button("REINICIAR ORDEN",_reset)
	else:
		var options: Array = content.get("options",[])
		for index in options.size(): _button(str(index+1)+". "+str(options[index]),_send.bind(index))
		if kind == "physical_zone":
			status.text = "Puedes responder por botones o caminando hacia una zona numerada."
			if get_tree().get_first_node_in_group("campus_campaign")!=null: _button("RESPONDER CON MOVIMIENTO",_start_zones)

func _start_zones() -> void:
	var campaign := get_tree().get_first_node_in_group("campus_campaign")
	if campaign==null or locked: return
	var zones := preload("res://scripts/education/learning_zones_v4.gd").new()
	campaign.add_child(zones)
	if not zones.begin(campaign,self,activity):
		zones.queue_free()
		status.text="No hay suficientes zonas transitables aquí. Responde con los botones o vuelve a un espacio abierto."

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.pressed.connect(action)
	add_child(button)
	return button

func _load_image() -> void:
	var service := preload("res://scripts/education/learning_activity_service.gd").new()
	service.auth = get_node("/root/AuthManager")
	var texture: Texture2D = await service.image_texture(str(activity.image_path))
	if not is_inside_tree() or texture==null: return
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(200,180)
	add_child(image); move_child(image,1)

func _pick(index: int, count: int) -> void:
	if locked or sequence.has(index): return
	sequence.append(index)
	status.text = "Orden elegido: " + str(sequence.map(func(i): return int(i)+1))
	if sequence.size() == count: _send(sequence.duplicate())

func _reset() -> void:
	sequence.clear()
	for child in get_children():
		if child is Button: child.disabled = false
	status.text = "Selecciona nuevamente el orden."

func _send(value: Variant) -> void:
	if locked: return
	locked = true
	for child in get_children():
		if child is Button: child.disabled = true
	answered.emit(value)
