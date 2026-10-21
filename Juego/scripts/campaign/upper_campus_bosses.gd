extends Node
const CONFIGS := [preload("res://resources/live/profesor_ingles.tres"),preload("res://resources/live/profesor_lenguaje.tres"),preload("res://resources/live/profesor_etica.tres")]
var campaign: Node
var actors: Dictionary = {}
var ready_for_play := false
var failures: Array[String] = []
var arena_samples: Dictionary = {}
@export_range(1,3) var enabled_stages := 3
func _ready() -> void: pass
func setup() -> void:
	await get_tree().physics_frame
	for config in CONFIGS.slice(0,enabled_stages):
		var height: float = preload("res://scripts/campaign/campus_content.gd").HEIGHTS[config.floor_number-1]
		var position_value: Variant = null
		var best_samples: Array = []
		var side := -1.0 if config.boss_id == "profesor_etica" else 1.0
		for seed in [Vector3(side*52,height+0.12,-132),Vector3(side*43,height+0.12,-132),Vector3(side*35,height+0.12,-140)]:
			var candidate = campaign.player.get_node("SeatController").safe_position(seed)
			if candidate == null or absf(candidate.y-height) >= 0.5: continue
			var samples: Array = []
			for x in [-6.0,0.0,6.0]:
				for z in [-2.0,0.0,2.0]:
					var safe = campaign.player.get_node("SeatController").safe_position(candidate+Vector3(x,0,z))
					if safe == null: continue
					var query := PhysicsRayQueryParameters3D.create(candidate+Vector3.UP,safe+Vector3.UP,1,[campaign.player.get_rid()])
					if campaign.player.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): samples.append(safe)
			if samples.size() > best_samples.size(): position_value = candidate; best_samples = samples
		if position_value == null:
			failures.append("Sin posición segura: "+config.boss_id)
			push_error(failures.back()); continue
		var actor = preload("res://scripts/campaign/academic_action_boss.gd").new()
		actor.name = config.boss_id; actor.config = config; actor.position = campaign.get_parent().get_node("Piso"+str(config.floor_number)).to_local(position_value)
		campaign.get_parent().get_node("Piso"+str(config.floor_number)).add_child(actor)
		actor.placement_valid = true
		actor.set_meta("placement_validated",true)
		actors[config.boss_id] = actor
		arena_samples[config.boss_id] = best_samples
		if best_samples.size() < 5: push_warning("Arena requiere revisión manual: "+config.boss_id+"; muestras transitables: "+str(best_samples.size()))
	ready_for_play = true
