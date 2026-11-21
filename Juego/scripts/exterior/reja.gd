@tool
extends Node3D
const BARS_PER_BATCH := 64

@export var width := 6.0
@export var height := 1.5
@export var bar_spacing := 0.15
@export var bar_thickness := 0.03
@export var bar_color := Color(0.6, 0.6, 0.6)

@export_tool_button("Regenerar Reja") var regenerar_btn: Callable = regenerar

var mat_iron := StandardMaterial3D.new()
var generated: Node3D

func _ready() -> void:
	regenerar()

func regenerar() -> void:
	mat_iron.albedo_color = bar_color
	mat_iron.metallic = 0.8
	mat_iron.roughness = 0.3
	if is_instance_valid(generated):
		generated.free()
	generated = Node3D.new()
	generated.name = "RejaGenerada"
	add_child(generated)
	_build_fence()

func _build_fence() -> void:
	_add_batch("Postes", Vector3(0.08, height, 0.08),
		[Vector3(-width / 2, height / 2, 0), Vector3(width / 2, height / 2, 0)])
	_add_batch("Travesanos", Vector3(width, 0.06, 0.06),
		[Vector3(0, height - 0.05, 0), Vector3(0, 0.1, 0)])
	var count := int(width / bar_spacing) + 1
	var size := Vector3(bar_thickness, height - 0.2, bar_thickness)
	for first in range(0, count, BARS_PER_BATCH):
		var positions: Array[Vector3] = []
		for index in range(first, mini(first + BARS_PER_BATCH, count)):
			positions.append(Vector3(-width / 2 + index * bar_spacing, height / 2, 0))
		_add_batch("Barras_%d" % first, size, positions)

func _add_batch(label: String, size: Vector3, positions: Array[Vector3]) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat_iron
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = positions.size()
	var visual := MultiMeshInstance3D.new()
	visual.name = label
	visual.multimesh = batch
	generated.add_child(visual)
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	for i in positions.size():
		batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = positions[i]
		body.add_child(collision)
	generated.add_child(body)
