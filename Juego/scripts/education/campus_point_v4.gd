extends Node3D
var title := "Punto educativo"
var action := Callable()
var interaction_range := 3.5
func _ready() -> void:
	add_to_group("campus_interactable")
	var label := Label3D.new()
	label.text = title
	label.position.y = 2.3
	label.font_size = 30
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
func interaction_text(_player: Node) -> String: return "[E] "+title
func interaction_target() -> Node3D: return self
func interaction_priority() -> int: return 2
func interact(player: CharacterBody3D) -> void:
	if not player.dead and not player.busy and action.is_valid(): action.call()
