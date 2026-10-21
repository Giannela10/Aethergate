class_name SeatInteractable
extends Node3D
## Punto optativo en una butaca fija. Nunca se registra en sillas recogibles.
var interaction_range := 2.0
var furniture: Node3D
var occupant: Node
func _ready() -> void:
	furniture = get_parent()
	add_to_group("campus_interactable")
	add_to_group("campus_seat")
func interaction_target() -> Node3D:
	return furniture
func context_action() -> String:
	return "sit"
func interaction_priority() -> int:
	return 1
func interaction_text(player: Node) -> String:
	return "[E] Sentarse" if not is_instance_valid(occupant) or occupant == player else ""
func interact(player: CharacterBody3D) -> void:
	var controller = player.get_node_or_null("SeatController")
	if controller:
		controller.begin(self)
func surface_height() -> float:
	var cushion := furniture.get_node_or_null("Cojin") as MeshInstance3D
	if cushion and cushion.mesh:
		return cushion.to_global(Vector3(0,cushion.mesh.get_aabb().end.y,0)).y
	return furniture.global_position.y+0.8
static func setup(campaign: Node) -> void:
	var area := campaign.get_parent().get_node_or_null("Piso2/AuditorioPiso2e/Butacas")
	if area == null:
		return
	# Solo dos butacas con suelo y espacio comprobados, sin alterar el mobiliario.
	var registered := 0
	var controller: Node = campaign.player.get_node("SeatController")
	for chair in area.get_children():
		if registered >= 2:
			break
		if not str(chair.name).begins_with("Butaca") or chair.has_node("RecogerSilla") or chair.has_node("Sentarse"):
			continue
		if controller.safe_position(chair.global_position,chair) == null:
			continue
		registered += 1
		var seat = load("res://scripts/campaign/seat_interactable.gd").new()
		seat.name = "Sentarse"
		chair.add_child(seat)
