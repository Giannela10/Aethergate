class_name NetworkSlowStatus
extends "res://scripts/inventory/item_effect_receiver.gd"
## Reutiliza RALENTIZADO y garantiza restauración al terminar el duelo.
var source_boss: Node

func _process(delta: float) -> void:
	if not is_instance_valid(source_boss) or not source_boss.combat_active() or get_parent().get("dead") == true:
		clear_slow()
		return
	super._process(delta)
	if statuses.is_empty():
		queue_free()

func apply_status(id: String, duration: float, multiplier: float = 0.7) -> bool:
	var player = get_parent()
	if player.get("inventory") != null and id == "RALENTIZADO":
		if player.inventory.has_item("DepuradorPortatil",1): duration *= 0.85
		if player.inventory.has_item("InsigniaDeIntegridad",1): duration *= 0.9
	return super.apply_status(id,duration,multiplier)

func clear_slow() -> void:
	_restore()
	queue_free()

func _restore() -> void:
	if is_instance_valid(get_parent()):
		for status in statuses.values():
			get_parent().set(status.property,status.original)
	statuses.clear()

func _exit_tree() -> void:
	_restore()
	super._exit_tree()
