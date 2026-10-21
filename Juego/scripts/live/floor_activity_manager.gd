extends Node
## Presentation/perception budget only. Quests, schedules, saves and interactions stay awake.
enum Activity { FULL, REDUCED, SLEEP }
var hub: Node
var tick := 0.0
var counts := {"LOD0":0,"LOD1":0,"LOD2":0,"SLEEP":0}

func _process(delta: float) -> void:
	tick -= delta
	if tick > 0 or not is_instance_valid(hub.campaign.player): return
	tick = 0.35
	refresh()

func refresh() -> void:
	counts = {"LOD0":0,"LOD1":0,"LOD2":0,"SLEEP":0}
	var viewer = hub.campaign.player
	for visual in get_tree().get_nodes_in_group("campus_character_visual"):
		if not visual is Node3D or not visual.is_inside_tree(): continue
		var actor = visual.get_parent()
		var duel = actor.get_node_or_null("BossDuelController")
		var critical: bool = viewer.is_ancestor_of(visual) or (duel != null and duel.state in [duel.DuelState.INTRO,duel.DuelState.COMBAT])
		var offset: Vector3 = visual.global_position-viewer.global_position
		var distance_squared := offset.length_squared()
		var level := 0
		if not critical:
			if absf(offset.y) > 18 or distance_squared > pow(visual.visual_far_distance*2,2): level = 3
			elif absf(offset.y) > 4 or distance_squared > pow(visual.visual_far_distance,2): level = 2
			elif distance_squared > pow(visual.visual_near_distance,2): level = 1
		visual.set_activity_level(level)
		counts[["LOD0","LOD1","LOD2","SLEEP"][level]] += 1
		# Only perception/movement of normal campus enemies sleeps off-floor.
		# Controllers and mission NPC state are never disabled here.
		if actor.get_script() != null and str(actor.get_script().resource_path) == "res://scripts/campaign/campus_enemy.gd":
			actor.set_meta("perception_sleep",not critical and absf(offset.y) > 4)
		actor.set_meta("floor_activity",Activity.FULL if absf(offset.y) <= 4 else (Activity.REDUCED if absf(offset.y) <= 18 else Activity.SLEEP))
