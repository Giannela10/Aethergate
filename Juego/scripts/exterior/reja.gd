@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")

@export var width := 6.0
@export var height := 1.5
@export var bar_spacing := 0.15
@export var bar_thickness := 0.03
@export var bar_color := Color(0.6, 0.6, 0.6)

@export_tool_button("Regenerar Reja") var regenerar_btn: Callable = regenerar

var mat_iron := StandardMaterial3D.new()

func _ready() -> void:
	regenerar()

func regenerar() -> void:
	mat_iron.albedo_color = bar_color
	mat_iron.metallic = 0.8
	mat_iron.roughness = 0.3
	_clear_fence()
	_build_fence()

func _clear_fence() -> void:
	for child in get_children():
		child.free()

func _build_fence() -> void:
	_add_bar("PostL", Vector3(-width/2, height/2, 0), Vector3(0.08, height, 0.08))
	_add_bar("PostR", Vector3(width/2, height/2, 0), Vector3(0.08, height, 0.08))
	_add_bar("RailTop", Vector3(0, height - 0.05, 0), Vector3(width, 0.06, 0.06))
	_add_bar("RailBottom", Vector3(0, 0.1, 0), Vector3(width, 0.06, 0.06))

	var count := int(width / bar_spacing)
	for i in range(count + 1):
		var x := -width/2 + i * bar_spacing
		_add_bar("Bar%d" % i, Vector3(x, height/2, 0), Vector3(bar_thickness, height - 0.2, bar_thickness))

func _add_bar(bar_name: String, pos: Vector3, size: Vector3) -> void:
	var box := CSGBox3D.new()
	box.name = bar_name
	box.size = size
	box.position = pos
	box.material = mat_iron

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	body.add_child(col)

	add_child(box)
	add_child(body)

	if Engine.is_editor_hint():
		box.owner = get_tree().edited_scene_root
		body.owner = get_tree().edited_scene_root
		col.owner = get_tree().edited_scene_root
