extends Node3D
const Catalog = preload("res://scripts/inventory/item_catalog.gd")
@export var item_id := "Botiquin"
@export_range(1,999) var quantity := 1
var collected := false
var prompt: Label3D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("inventory_pickup")
	var item = Catalog.get_item(item_id)
	if item == null:
		push_warning("Objeto desconocido: "+item_id)
		return
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(0.32,0.25,0.20)
	mesh.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.albedo_color = [Color("45a18b"),Color("b58b52"),Color("dcbb58"),Color("8e6acc"),Color("e1e9d8")][item.category]
	mesh.material_override = mat
	mesh.position.y = 0.25
	add_child(mesh)
	prompt = Label3D.new()
	prompt.text = "[E] %s ×%d" % [item.display_name,quantity]
	prompt.position.y = 0.7
	prompt.pixel_size = 0.004
	prompt.font_size = 40
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(prompt)

func collect(player: Node3D) -> bool:
	if collected or player.get("dead") == true or player.global_position.distance_to(global_position) > 1.8 or not player._can_reach(self):
		return false
	if not player.has_method("receive_item") or player.receive_item(item_id,quantity) <= 0:
		return false
	collected = true
	remove_from_group("inventory_pickup")
	hide()
	queue_free()
	return true

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not is_instance_valid(prompt):
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	prompt.visible = is_instance_valid(player) and not player.has_node("InteractionController") and global_position.distance_to(player.global_position) < 2.5
