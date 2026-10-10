extends Node3D
## Apertura automática para dejar accesible la sala sin modificar al jugador.
var _open: bool = false
var _tween: Tween
func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var should_open: bool = is_instance_valid(player) and global_position.distance_to(player.global_position) < 4.0
	if should_open == _open:
		return
	_open = should_open
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation:y", PI / 2.0 if _open else 0.0, 0.4)
