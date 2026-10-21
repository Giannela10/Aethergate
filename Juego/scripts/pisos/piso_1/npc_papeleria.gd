@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
const ITEMS := {"lapiz":"Lápiz", "hoja_impresa":"Hoja impresa", "cuaderno":"Cuaderno", "goma":"Goma de borrar"}
var customer: Node3D
var window: PanelContainer
var status: Label
var prompt: Label3D
var manager: Node
var model: Node3D
var dialogue_camera: Node
var visual_timer := 0.0
func _ready() -> void:
	if Engine.is_editor_hint(): return
	add_to_group("stationery_vendor")
	model = load("res://scripts/juego/student_visual.gd").new()
	model.name = "CharacterVisual"
	model.scale = Vector3.ONE*1.5
	model.shirt_color = Color(0.15,0.5,0.36)
	model.rotation.y = PI
	add_child(model)
	preload("res://scripts/juego/character_visual_presets.gd").apply(model,preload("res://scripts/juego/character_visual_presets.gd").create("npc_papeleria","VENDEDOR"))
	prompt = Label3D.new()
	prompt.text = "[E] Pedir artículos"
	prompt.position.y = 3.1
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.font_size = 44
	add_child(prompt)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	window = PanelContainer.new()
	layer.add_child(window)
	window.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	window.position -= Vector2(190,220)
	window.custom_minimum_size = Vector2(380,400)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation",14)
	window.add_child(list)
	var title := Label.new()
	title.text = "Impresiones y papelería\n¿Qué necesitas?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)
	for key in ITEMS:
		var button := Button.new()
		button.text = ITEMS[key]
		button.custom_minimum_size.y = 48
		button.pressed.connect(give_item.bind(key))
		list.add_child(button)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(status)
	var close := Button.new()
	close.text = "Cerrar"
	close.pressed.connect(close_shop)
	list.add_child(close)
	window.hide()
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	visual_timer += _delta
	if is_instance_valid(player) and global_position.distance_squared_to(player.global_position) < 1225 and visual_timer > 0.05:
		model.animate(visual_timer,Vector3.ZERO,true,false)
		visual_timer = 0
	prompt.visible = is_instance_valid(player) and not player.has_node("InteractionController") and global_position.distance_to(player.global_position)<4.5 and not window.visible
func interact(player: Node3D) -> void:
	if window.visible or global_position.distance_to(player.global_position)>4.5: return
	customer = player
	if dialogue_camera == null:
		dialogue_camera = preload("res://scripts/campaign/dialogue_camera_controller.gd").new()
		add_child(dialogue_camera)
	dialogue_camera.begin(player,self,1)
	manager = player.get_parent()
	customer.busy = true
	manager.set_process(false)
	status.text = "Elige un artículo para recibirlo."
	window.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func give_item(key: String) -> void:
	if not window.visible or not is_instance_valid(customer) or not ITEMS.has(key): return
	var count: int = customer.receive_stationery(key)
	status.text = "Recibiste: %s\nEn tu inventario: %d\nPresiona I al cerrar para ver y equipar tus artículos." % [ITEMS[key],count]
func close_shop() -> void:
	if is_instance_valid(dialogue_camera): dialogue_camera.finish()
	window.hide()
	if is_instance_valid(customer): customer.busy = false
	if is_instance_valid(manager): manager.set_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if window.visible and event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()
