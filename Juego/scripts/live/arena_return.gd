extends Node3D
var retry: Node
var interaction_range := 2.5
func interaction_text(_player: Node) -> String:
	return "[E] Volver a la zona del duelo" if retry.arena_time > 4 else ""
func interact(player: Node3D) -> void:
	if retry.arena_time <= 4 or player.dead or player.busy or not is_instance_valid(retry.duel): return
	var safe = player.get_node("SeatController").safe_position(Vector3(float(retry.snapshot.position[0]),float(retry.snapshot.position[1]),float(retry.snapshot.position[2])))
	if safe == null: return
	player.global_position = safe
	player.velocity = Vector3.ZERO
	retry.hub.campaign.manager.cam_pivot = safe+Vector3.UP*1.4
	retry.arena_time = 0
