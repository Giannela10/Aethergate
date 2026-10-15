extends Node3D
## E llama el ascensor; 1..8 elige piso y 0 elige el piso −1.
@export_range(0, 7) var initial_floor: int = 0
@export var speed: float = 5.0
## Puertas fijas guardadas en el piso correspondiente (1..8, −1).
@export var gate_paths: Array[NodePath] = []
const BASEMENT_INDEX := 8
const LEVELS: Array[float] = [0.0,12.058385849,23.967668533,35.674415588,47.974849701,60.158504486,71.942184448,83.913551331,-12.058385849]
var current_floor: int = 0
var destination: int = 0
var moving: bool = false
var close_timer: float = 0.0
var player: CharacterBody3D
var _ui: Label
var _gates: Array[AnimatableBody3D] = []
var _inside: bool = false
@onready var cabin: AnimatableBody3D = $Cabina
@onready var cabin_door: AnimatableBody3D = $Cabina/PuertaCabina
@onready var indicator: Label3D = $Indicador

func _ready() -> void:
	current_floor = initial_floor
	destination = current_floor
	cabin.position.y = LEVELS[current_floor]
	if gate_paths.size() == LEVELS.size():
		for path in gate_paths:
			_gates.append(get_node(path) as AnimatableBody3D)
	else:
		for i in range(8):
			_gates.append(get_node("PuertaPiso%d" % (i + 1)) as AnimatableBody3D)
		_gates.append(get_node("PuertaPisoMenos1") as AnimatableBody3D)
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	_ui = Label.new()
	_ui.add_theme_font_size_override("font_size", 24)
	_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	_ui.add_theme_constant_override("outline_size", 8)
	layer.add_child(_ui)
	_ui.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_ui.offset_left = 20.0
	_ui.offset_top = -90.0
	_ui.offset_bottom = -20.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_inside = false
	var near_floor: int = -1
	if is_instance_valid(player) and not player.dead and not player.get("busy"):
		var local := player.global_position - cabin.global_position
		_inside = absf(local.x) < 2.2 and local.z > -5.2 and local.z < 7.0 and local.y > -0.3 and local.y < 3.3
		for i in LEVELS.size():
			var landing := global_position + Vector3(0, LEVELS[i], 9.0)
			if player.global_position.distance_to(landing) < 3.5:
				near_floor = i
				break
	if moving:
		close_timer = maxf(0.0, close_timer - delta)
		if close_timer <= 0.0:
			cabin.position.y = move_toward(cabin.position.y, LEVELS[destination], speed * delta)
			if absf(cabin.position.y - LEVELS[destination]) < 0.001:
				current_floor = destination
				moving = false
	for i in LEVELS.size():
		var opened: bool = not moving and current_floor == i
		_gates[i].position.x = move_toward(_gates[i].position.x, 4.4 if opened else 0.0, 8.0 * delta)
	cabin_door.position.x = move_toward(cabin_door.position.x, 4.4 if not moving else 0.0, 8.0 * delta)
	indicator.text = "ASCENSOR · PISO %s%s" % [floor_name(current_floor), " → %s" % floor_name(destination) if moving else ""]
	_ui.visible = (_inside or near_floor >= 0) and not get_tree().get_first_node_in_group("campus_campaign")
	if _inside:
		_ui.text = "Ascensor: 1–8 para elegir piso · 0: piso −1\n" + ("En movimiento…" if moving else "Piso %s" % floor_name(current_floor))
	else:
		_ui.text = "[E] Llamar ascensor al piso %s" % floor_name(near_floor)
	if not get_tree().get_first_node_in_group("campus_campaign") and not moving and not _inside and near_floor >= 0 and Input.is_action_just_pressed("interact"):
		request_floor(near_floor)

func _unhandled_key_input(event: InputEvent) -> void:
	if get_tree().get_first_node_in_group("campus_campaign"):
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not _inside or moving:
		return
	if key.keycode >= KEY_1 and key.keycode <= KEY_8:
		request_floor(key.keycode - KEY_1)
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_0 or key.keycode == KEY_KP_0:
		request_floor(BASEMENT_INDEX)
		get_viewport().set_input_as_handled()

func floor_name(index: int) -> String:
	return "−1" if index == BASEMENT_INDEX else str(index + 1)

func request_floor(index: int) -> void:
	var campaign := get_tree().get_first_node_in_group("campus_campaign")
	if campaign and not campaign.floor_unlocked("S" if index == 8 else str(index+1)):
		return
	if moving or index < 0 or index >= LEVELS.size() or index == current_floor:
		return
	destination = index
	moving = true
	close_timer = 1.0

