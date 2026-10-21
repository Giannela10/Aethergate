extends Node
enum State { QUIET, NORMAL, ACTIVE, STORY_LOCK }
signal opportunity
var hub: Node
var state := State.NORMAL
var observations := {}
var since_activity := 0.0
var combat_remaining := 0.0
var remaining := 90.0
var tick := 0.0
var enabled := true
var story_locks: Dictionary = {}
func locked() -> bool:
	var c = hub.campaign
	return not story_locks.is_empty() or c.player.dead or c.player.busy or c.ui.modal or c.manager.minigame.active or is_instance_valid(c.active_duel) or c.player.get_meta("important_scene",false) or c.get_tree().paused
func in_combat() -> bool:
	var c = hub.campaign
	if c.player.body.is_punching(): return true
	for enemy in c.get_tree().get_nodes_in_group("enemy"):
		if enemy is Node3D and enemy.get("dead") != true and absf(enemy.global_position.y-c.player.global_position.y) < 3 and enemy.global_position.distance_squared_to(c.player.global_position) < 100:
			return true
	return false
func acquire_story_lock(id: String) -> void:
	story_locks[id] = true
	state = State.STORY_LOCK
func release_story_lock(id: String) -> void:
	story_locks.erase(id)
func activity() -> void:
	since_activity = 0
	remaining = maxf(remaining,20)
func damage_received() -> void:
	combat_remaining = hub.config.combat_grace
func can_offer() -> bool:
	return enabled and hub.config.enabled and not locked() and not in_combat() and combat_remaining <= 0 and remaining <= 0 and hub.campaign.player.health >= hub.campaign.player.max_health*0.25 and state in [State.QUIET,State.NORMAL]
func event_finished() -> void:
	since_activity = 0
	remaining = hub.rng.randf_range(hub.config.minimum_gap,maxf(hub.config.minimum_gap,hub.config.maximum_gap))
	hub.state.cooldown = remaining
func _process(delta: float) -> void:
	if not hub.campaign.ready_for_play: return
	tick += delta
	if tick < 1: return
	var elapsed := tick
	tick = 0
	var c = hub.campaign
	observations = {"floor":hub.floor_id(),"mission":c.quests.objective_text() if c.quests else "","health":c.player.health,"bosses":c.data.bosses.duplicate(),"time":c.academics.current_time(),"since_event":since_activity,"recent_combat":combat_remaining}
	if locked():
		state = State.STORY_LOCK
		return
	since_activity += elapsed
	combat_remaining = maxf(0,combat_remaining-elapsed)
	if in_combat(): combat_remaining = hub.config.combat_grace
	if combat_remaining > 0 or hub.event_active():
		state = State.ACTIVE
		return
	remaining = maxf(0,remaining-elapsed)
	hub.state.cooldown = remaining
	state = State.QUIET if since_activity > 90 else State.NORMAL
	if can_offer():
		opportunity.emit()
		if not hub.event_active(): remaining = 20
