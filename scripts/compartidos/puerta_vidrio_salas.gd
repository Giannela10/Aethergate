extends Node3D
## Conserva el bloqueo de campaña; las hojas de referencia giran sobre bisagra.
@export var ancho: float = 2.0
var _homes: Array[Vector3] = []
@onready var left: AnimatableBody3D = $HojaIzquierda
@onready var right: AnimatableBody3D = $HojaDerecha
func _ready() -> void:
	_homes = [left.position, right.position]
func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var opened: bool = is_instance_valid(player) and global_position.distance_to(player.global_position) < 4.2
	opened = opened and not bool(get_meta("campaign_locked", false))
	if bool(get_meta("photo_hinged", false)):
		left.rotation.y = move_toward(left.rotation.y, 1.52 if opened else 0.0, delta * 2.1)
		return
	var slide: float = ancho * 0.5 + 0.1 if opened else 0.0
	left.position = left.position.move_toward(_homes[0] + Vector3.LEFT * slide, delta * 3.0)
	right.position = right.position.move_toward(_homes[1] + Vector3.RIGHT * slide, delta * 3.0)
