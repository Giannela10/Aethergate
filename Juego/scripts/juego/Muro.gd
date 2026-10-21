@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")

@export var wall_length := 2.0
@export var wall_height := 2.5
@export var wall_thickness := 0.3
@export var wall_color := Color(0.75, 0.73, 0.68)

@export_tool_button("Regenerar Muro") var regenerar_btn: Callable = regenerar

var mat_wall := StandardMaterial3D.new()

func _ready() -> void:
	regenerar()

func regenerar() -> void:
	mat_wall.albedo_color = wall_color
	mat_wall.roughness = 0.9
	_clear()
	_build()

func _clear() -> void:
	# Solo borra lo que este mismo script genero, no otros hijos
	# que hayas agregado vos (como el siguiente tramo de muro).
	var old_box := CampusNodes.buscar(self, "Bloque")
	if old_box:
		old_box.free()
	var old_body := CampusNodes.buscar(self, "Cuerpo")
	if old_body:
		old_body.free()

func _build() -> void:
	var size := Vector3(wall_length, wall_height, wall_thickness)
	var box_pos := Vector3(wall_length / 2.0, wall_height / 2.0, 0)

	var box := CSGBox3D.new()
	box.name = "Bloque"
	box.size = size
	box.position = box_pos
	box.material = mat_wall
	add_child(box)

	var body := StaticBody3D.new()
	body.name = "Cuerpo"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = box_pos
	body.add_child(col)
	add_child(body)

	if Engine.is_editor_hint():
		box.owner = get_tree().edited_scene_root
		body.owner = get_tree().edited_scene_root
		col.owner = get_tree().edited_scene_root
