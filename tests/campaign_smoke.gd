extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	scene.get_node("CampusCampaign").persist = false
	scene.get_node("GameplayManager").set("populate_entrance",false)
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	var campaign = scene.get_node("CampusCampaign")
	assert(campaign.ready_for_play)
	for duel in get_nodes_in_group("boss_duel"):
		assert(duel.state == duel.DuelState.NEUTRAL)
		var hp: float = duel.actor.health
		if duel.actor.has_method("take_hit"):
			duel.actor.take_hit(Vector3.ZERO,10000)
			assert(duel.actor.health == hp)
		assert(not duel.actor.is_physics_processing())
	print("CAMPAIGN SMOKE OK fase ",campaign.implementation_phase)
	quit()
