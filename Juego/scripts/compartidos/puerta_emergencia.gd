@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
## Puerta abatible. La proximidad abre ambos sentidos de circulación.
@export var floor_label := "1"
@export var interaction_distance := 3.3
@onready var hinge: AnimatableBody3D = $Bisagra
@onready var collision: CollisionShape3D = $Bisagra/Colision
var opened := false

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("emergency_door")

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	opened = is_instance_valid(player) and player.get("dead") != true and absf(player.global_position.y - global_position.y) < 1.8 and Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z).length() < interaction_distance
	hinge.rotation.y = move_toward(hinge.rotation.y, -PI * 0.5 if opened else 0.0, delta * 2.5)
	# La hoja no empuja al personaje durante el giro; bloquea de nuevo al cerrar.
	collision.set_deferred("disabled", opened or absf(hinge.rotation.y) > 0.05)
