extends Node
var hub: Node
var snapshot := {}
var duel: Node
var failed := false
var signals: Dictionary = {}
var arena_time := 0.0
var retrying := false
var return_point: Node3D
func capture(controller: Node) -> void:
	if retrying: return
	var c = hub.campaign
	var position_value = c.player.get_node("SeatController").safe_position(c.player.global_position)
	if position_value == null: position_value = c.player.global_position
	duel = controller
	failed = false
	snapshot = {"inventory":c.player.inventory.snapshot_data().duplicate(true),"health":c.player.health,"position":[position_value.x,position_value.y,position_value.z],"stamina":c.player.get_node("CombatExtensions").stamina,"checkpoint":c.data.checkpoint.duplicate(true)}
	# Keep disk saves coherent if objects/quests change while the duel is open.
	snapshot["campaign_data"] = c.data.duplicate(true)
	# Reuse the existing checkpoint mechanism at the already occupied approach.
	c.data.checkpoint = {"id":"Pre-boss: "+controller.boss_name,"position":snapshot.position.duplicate(),"health":snapshot.health}
	c.save_game()
func on_death() -> void:
	failed = is_instance_valid(duel) and hub.campaign.active_duel == duel and not snapshot.is_empty() and not duel.defeated
func can_retry() -> bool:
	return failed and is_instance_valid(duel) and not duel.defeated and not snapshot.is_empty()
func retry_boss() -> void:
	if not can_retry() or retrying: return
	retrying = true
	var c = hub.campaign
	c.ui.close_modal()
	duel.reset_duel()
	# Remove old thrown/dropped copies of snapshot weapons before rehydrating.
	var uids := {}
	for entry in snapshot.inventory.entries: uids[entry.uid] = true
	for node in get_tree().get_nodes_in_group("weapon_pickup"):
		if uids.has(str(node.get_meta("inventory_uid",""))): node.queue_free()
	for node in c.get_parent().find_children("*","CharacterBody3D",true,false):
		if node.get("shooter") == c.player: node.queue_free()
	hub.restoring_inventory = true
	c.player.inventory.restore_snapshot(snapshot.inventory.duplicate(true))
	c.restore_player(snapshot.position,snapshot.health)
	c.player.get_node("CombatExtensions").stamina = snapshot.stamina
	c._capture_inventory()
	await get_tree().process_frame
	hub.restoring_inventory = false
	failed = false
	if not is_instance_valid(duel) or duel.defeated:
		retrying = false
		return
	duel.interact(c.player)
	if duel.state == duel.DuelState.DIALOGUE: duel.accept()
	retrying = false
	c.save_game()
func victory(id: String) -> void:
	if is_instance_valid(duel) and duel.boss_id == id:
		failed = false; snapshot.clear(); duel = null
func _process(delta: float) -> void:
	var current = hub.campaign.active_duel
	for id in signals:
		if is_instance_valid(signals[id]): signals[id].hide()
	if not is_instance_valid(current) or current.state != current.DuelState.COMBAT:
		arena_time = 0
		if is_instance_valid(return_point):
			return_point.remove_from_group("campus_interactable")
		return
	var actor = current.actor
	var key := str(current.get_instance_id())
	if not signals.has(key):
		var label := Label3D.new()
		label.font_size = 30; label.pixel_size = 0.005
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position.y = 3.0
		label.modulate = Color("ffe2a1")
		current.add_child(label)
		signals[key] = label
	var special := false
	for property in ["digital_pending","tray_pending","_throw_pending","packet_pending"]:
		if actor.get(property) == true: special = true
	for property in ["blue_charge","connection_charge"]:
		if actor.get(property) != null and float(actor.get(property)) > 0: special = true
	var distance: float = actor.global_position.distance_to(hub.campaign.player.global_position)
	arena_time = arena_time+delta if distance > 35 else 0.0
	signals[key].text = "Preparando ataque especial" if special else ""
	if arena_time > 3: signals[key].text = "El desafío continúa junto a su zona de inicio"
	if arena_time > 4:
		if not is_instance_valid(return_point):
			return_point = preload("res://scripts/live/arena_return.gd").new()
			return_point.retry = self
			hub.campaign.add_child(return_point)
		return_point.add_to_group("campus_interactable")
		return_point.global_position = hub.campaign.player.global_position+hub.campaign.player.body.forward()
	elif is_instance_valid(return_point):
		return_point.remove_from_group("campus_interactable")
	signals[key].visible = not signals[key].text.is_empty() and distance < 45
