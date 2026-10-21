extends Node3D
var interaction_range := 3.5
var elevator: Node3D
var landing := -1
var campaign: Node
func _ready() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	add_to_group("campus_interactable")
func interaction_text(_player: Node) -> String:
	return "[E] Elegir piso" if landing < 0 else "[E] Llamar ascensor"
func interact(_player: CharacterBody3D) -> void:
	if elevator.moving:
		campaign.ui.notify("Ascensor en movimiento.")
		return
	if landing >= 0:
		elevator.request_floor(landing)
		return
	var choices: Array = []
	var callbacks: Array = []
	for i in 9:
		var floor_name := "S" if i == 8 else str(i+1)
		choices.append(("Subterráneo" if i == 8 else "Piso "+floor_name)+("" if campaign.floor_unlocked(floor_name) else " · BLOQUEADO"))
		callbacks.append(_request.bind(i,floor_name))
	choices.append("Cancelar")
	callbacks.append(campaign.ui.close_modal)
	campaign.ui.dialog("ASCENSOR","Selecciona un destino desbloqueado.",choices,callbacks)
func _request(index: int, floor_name: String) -> void:
	if not campaign.floor_unlocked(floor_name):
		campaign.ui.notify("Piso bloqueado por progreso.")
		return
	campaign.ui.close_modal()
	elevator.request_floor(index)

func interaction_priority() -> int:
	return 4
