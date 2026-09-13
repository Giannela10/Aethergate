@tool
extends Node3D

@export var post_height := 1.0
@export var post_radius := 0.06
@export var arm_length := 1.2
@export var arm_height := 1.5        # <- nuevo: alto del panel
@export var arm_thickness := 0.05    # <- ahora es solo el grosor (delgado)
@export var metal_color := Color(0.7, 0.7, 0.75)
@export var open_angle := 90.0

@export_tool_button("Regenerar Torniquete") var regenerar_btn: Callable = regenerar

var mat_metal := StandardMaterial3D.new()
var pivot: Node3D
var is_open := false

func _ready() -> void:
	regenerar()
	if not Engine.is_editor_hint():
		_setup_trigger()

func regenerar() -> void:
	mat_metal.albedo_color = metal_color
	mat_metal.metallic = 0.9
	mat_metal.roughness = 0.2
	_clear()
	_build()

func _clear() -> void:
	var old_post := get_node_or_null("Poste")
	if old_post:
		old_post.free()
	var old_body := get_node_or_null("PosteCuerpo")
	if old_body:
		old_body.free()
	var old_pivot := get_node_or_null("Pivote")
	if old_pivot:
		old_pivot.free()
	pivot = null

func _build() -> void:
	var post := CSGCylinder3D.new()
	post.name = "Poste"
	post.radius = post_radius
	post.height = post_height
	post.position = Vector3(0, post_height / 2.0, 0)
	post.material = mat_metal
	add_child(post)

	var body := StaticBody3D.new()
	body.name = "PosteCuerpo"
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = post_radius
	shape.height = post_height
	col.shape = shape
	col.position = Vector3(0, post_height / 2.0, 0)
	body.add_child(col)
	add_child(body)

	pivot = Node3D.new()
	pivot.name = "Pivote"
	pivot.position = Vector3(0, arm_height / 2.0, 0)
	add_child(pivot)

	# Ahora es un panel: largo (arm_length) x alto (arm_height) x grosor fino (arm_thickness)
	var arm := CSGBox3D.new()
	arm.name = "Brazo"
	arm.size = Vector3(arm_length, arm_height, arm_thickness)
	arm.position = Vector3(arm_length / 2.0, 0, 0)
	arm.material = mat_metal
	pivot.add_child(arm)

	if Engine.is_editor_hint():
		post.owner = get_tree().edited_scene_root
		body.owner = get_tree().edited_scene_root
		col.owner = get_tree().edited_scene_root
		pivot.owner = get_tree().edited_scene_root
		arm.owner = get_tree().edited_scene_root

func _setup_trigger() -> void:
	var area := Area3D.new()
	area.name = "Trigger"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(arm_length + 0.5, 2.0, 0.6)
	col.shape = shape
	col.position = Vector3(arm_length / 2.0, 1.0, 0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Character":
		_toggle()

func _toggle() -> void:
	is_open = not is_open
	var target_angle := deg_to_rad(open_angle) if is_open else 0.0
	var tween := create_tween()
	tween.tween_property(pivot, "rotation:y", target_angle, 0.5)
