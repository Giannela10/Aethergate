extends Node
## Añadir como hijo de un acceso nuevo. No cambia puertas existentes.
signal unlocked
@export var required_item := "TarjetaAcceso"
@export var interaction_range := 2.5
var is_unlocked := false

func can_access(player: Node) -> bool:
	return is_unlocked or (is_instance_valid(player) and player.has_method("has_key_item") and player.call("has_key_item",required_item))

func try_unlock(player: Node3D) -> bool:
	if not is_instance_valid(player) or player.get("dead") == true or player.get("busy") == true:
		return false
	var door := get_parent() as Node3D
	if door and (door.global_position.distance_to(player.global_position) > interaction_range or not player.call("_can_reach",door)):
		return false
	if not can_access(player):
		return false
	if not is_unlocked:
		is_unlocked = true
		unlocked.emit()
	return true
