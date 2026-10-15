extends Node
## Componente optativo. Ningún jefe conoce los IDs de los objetos.
@export var weaknesses: Dictionary = {}
@export var resistances: Dictionary = {}
@export var immunities: PackedStringArray = []
@export var stun_seconds := 3.0
@export var cancel_methods: PackedStringArray = []
var remaining := 0.0
var was_processing := false
var statuses: Dictionary = {}

func can_apply(item_id: String) -> bool:
	var actor := get_parent()
	var duel := actor.get_node_or_null("BossDuelController")
	if duel and not duel.allows_damage():
		return false
	return not actor.is_queued_for_deletion() and actor.get("dead") != true and actor.has_method("take_hit") and not immunities.has(item_id) and (weaknesses.has(item_id) or resistances.has(item_id)) and float(weaknesses.get(item_id,1.0)) > 0 and float(resistances.get(item_id,1.0)) > 0

func apply_item(item: Resource, source: Node3D) -> bool:
	if not can_apply(item.id):
		return false
	var actor := get_parent()
	var factor := maxf(0,float(weaknesses.get(item.id,1.0))) * clampf(float(resistances.get(item.id,1.0)),0,1)
	if factor <= 0:
		return false
	actor.call("take_hit",source.global_position.direction_to(actor.global_position),item.special_damage * factor)
	if actor.get("dead") == true:
		return true
	for method in cancel_methods:
		if actor.has_method(method):
			actor.call(method)
	var visual = actor.get("body") if actor.get("body") != null else actor.get("_visual")
	if is_instance_valid(visual):
		visual.set("punch_p",[-1.0,-1.0])
	if stun_seconds > 0:
		if remaining <= 0:
			was_processing = actor.is_physics_processing()
		remaining = maxf(remaining,stun_seconds)
		actor.set_physics_process(false)
		if actor is CharacterBody3D:
			actor.velocity = Vector3.ZERO
		var mover = actor.get("_mover")
		if mover is CharacterBody3D:
			mover.velocity = Vector3.ZERO
	return true

func _process(delta: float) -> void:
	for id in statuses.keys():
		statuses[id].time -= delta
		if statuses[id].time <= 0:
			get_parent().set(statuses[id].property,statuses[id].original)
			statuses.erase(id)
	if remaining <= 0:
		return
	remaining = maxf(0,remaining-delta)
	var actor := get_parent()
	if remaining <= 0 and actor.get("dead") != true:
		actor.set_physics_process(was_processing)

func _exit_tree() -> void:
	if remaining > 0 and is_instance_valid(get_parent()) and get_parent().get("dead") != true:
		get_parent().set_physics_process(was_processing)
func apply_status(id: String, duration: float, multiplier: float = 0.7) -> bool:
	var actor := get_parent()
	var duel := actor.get_node_or_null("BossDuelController")
	if actor.get("dead") == true or duration <= 0 or (duel and not duel.allows_damage()):
		return false
	if id == "PARALIZADO":
		if remaining <= 0:
			was_processing = actor.is_physics_processing()
		remaining = maxf(remaining,duration)
		actor.set_physics_process(false)
		for method in cancel_methods:
			if actor.has_method(method):
				actor.call(method)
		var visual = actor.get("body") if actor.get("body") != null else actor.get("_visual")
		if is_instance_valid(visual):
			visual.punch_p[0] = -1
			visual.punch_p[1] = -1
		return true
	var properties := ["speed_factor","progression_speed"] if id == "RALENTIZADO" else ["melee_damage","progression_damage","attack_damage"]
	if id not in ["RALENTIZADO","AUMENTADO","DEBILITADO"]:
		return false
	for property in properties:
		if actor.get(property) != null:
			var original: float = actor.get(property)
			if statuses.has(id):
				original = statuses[id].original
			statuses[id] = {"property":property,"original":original,"time":duration}
			actor.set(property,original*clampf(multiplier,0.1,3))
			return true
	return false
