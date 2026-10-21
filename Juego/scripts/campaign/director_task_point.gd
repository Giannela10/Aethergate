class_name DirectorTaskPoint
extends "res://scripts/juego/computer.gd"
var expansion: Node
var task_id := "director_task_network"
var index := 0
var interaction_range := 2.5
func _ready() -> void:
	super._ready()
	remove_from_group("computer")
	add_to_group("campus_interactable")
	set_process(false)
	screen_text.text = "PRUEBA DIRECTOR\n"+("PC0"+str(index+1)+" · "+("Red B" if index == 2 else "Red A") if task_id == "director_task_config" else "SIN CONEXIÓN")
	if expansion.state.flags.get(task_id,false): set_done()
func interaction_priority() -> int: return 1
func context_action() -> String: return "computer"
func interaction_text(_player: Node) -> String:
	return "" if expansion.state.flags.get(task_id,false) else "[E] "+("Revisar PC0"+str(index+1) if task_id == "director_task_config" else "Revisar conexión")
func interact(player: CharacterBody3D) -> void:
	if player.busy or player.dead or is_instance_valid(expansion.campaign.active_duel): return
	expansion.open_task(task_id,index)
