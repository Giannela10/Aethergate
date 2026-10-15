class_name AcademicClassPoint
extends Node3D
var schedule: Node
var site := ""
var interaction_range := 2.5
func _ready() -> void:
	add_to_group("campus_interactable")
	var label := Label3D.new()
	label.text = "CLASES OPCIONALES\n[E] Consultar horario"
	label.position.y = 2.2
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.pixel_size = 0.003
	label.modulate = Color("9bd8ed")
	add_child(label)
func interaction_priority() -> int:
	return 0
func interaction_text(_player: Node) -> String:
	return "[E] Consultar clase"
func context_action() -> String:
	return "read"
func interact(player: CharacterBody3D) -> void:
	if not player.dead and not player.busy:
		schedule.show_site(site)
