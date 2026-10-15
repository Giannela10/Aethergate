class_name PlayerSeating
extends Node
## Conserva cápsula y cámara. El asiento se ocupa solo tras validar suelo/espacio.
var player: CharacterBody3D
var campaign: Node
var seat: Node3D
var exit_position := Vector3.ZERO
var anchor := Vector3.ZERO
var ignored: Array[PhysicsBody3D] = []

func _ready() -> void:
	player = get_parent()
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	player.hit_received.connect(_on_hit)

func _chair_rids(chair: Node3D) -> Array[RID]:
	var result: Array[RID] = [player.get_rid()]
	if chair:
		for object in chair.find_children("*","PhysicsBody3D",true,false):
			result.append(object.get_rid())
	return result

func safe_position(candidate: Vector3, chair: Node3D = null) -> Variant:
	var rids := _chair_rids(chair)
	var ray := PhysicsRayQueryParameters3D.create(candidate+Vector3.UP*1.8,candidate-Vector3.UP*1.4,player.collision_mask,rids)
	var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.normal.y < 0.75 or absf(hit.position.y-candidate.y) > 1.0:
		return null
	var floor_position: Vector3 = hit.position+Vector3.UP*0.04
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player.standing_capsule
	query.transform = Transform3D(Basis.IDENTITY,floor_position+Vector3.UP*1.375)
	query.collision_mask = player.collision_mask
	query.exclude = rids
	query.margin = 0.005
	if not player.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
		return null
	return floor_position

func begin(point: Node3D) -> bool:
	if is_instance_valid(seat) or player.dead or player.busy or player.body.is_punching() or player.stun_t > 0 or campaign.active_duel != null:
		return false
	var combat := player.get_node_or_null("CombatExtensions")
	if combat and combat.dodge_t > 0:
		return false
	if is_instance_valid(point.occupant) or point.furniture.has_node("RecogerSilla") or point.furniture.is_in_group("weapon_pickup"):
		return false
	if player.global_position.distance_to(point.global_position) > point.interaction_range or not player._can_reach(point.furniture):
		return false
	var target = safe_position(point.furniture.global_position,point.furniture)
	var leave = safe_position(player.global_position)
	if target == null or leave == null:
		campaign.ui.notify("No hay espacio seguro para sentarse aquí.")
		return false
	seat = point
	seat.occupant = player
	exit_position = leave
	anchor = target
	for object in point.furniture.find_children("*","PhysicsBody3D",true,false):
		if not player.get_collision_exceptions().has(object):
			player.add_collision_exception_with(object)
			ignored.append(object)
	player.global_position = anchor
	player.velocity = Vector3.ZERO
	player.running = false
	player.crouching = false
	var direction: Vector3 = -point.furniture.global_basis.z.normalized()
	player.body.rotation.y = atan2(-direction.x,-direction.z)
	player.body.contextual_pose.seated = true
	player.body.contextual_pose.seat_height = clampf((point.surface_height()-anchor.y)/player.body.scale.y,0.35,0.85)
	player.body.play_context_action("sit")
	campaign.ui.notify("Sentado · E o movimiento para levantarte · P celular · I inventario")
	return true

func update_seated() -> bool:
	if not is_instance_valid(seat):
		if player.body.contextual_pose.seated:
			_finish()
		return false
	if player.global_position.distance_to(anchor) > 0.75:
		_finish()
		return false
	player.velocity = Vector3.ZERO
	if player.busy or get_tree().paused:
		return true
	if Input.get_vector("move_left","move_right","move_forward","move_back").length() > 0.1 or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("punch"):
		stand()
	return true

func stand(force: bool = false) -> bool:
	if not is_instance_valid(seat):
		_finish()
		return true
	var forward: Vector3 = -seat.furniture.global_basis.z.normalized()
	for candidate in [exit_position,anchor+forward*1.2,anchor-forward*1.2]:
		var destination = safe_position(candidate)
		if destination != null:
			player.global_position = destination
			_finish()
			player.body.play_context_action("stand")
			return true
	if force:
		_finish()
		return true
	campaign.ui.notify("El paso está ocupado. Espera un momento.")
	return false

func _finish() -> void:
	if is_instance_valid(seat):
		seat.occupant = null
	seat = null
	for object in ignored:
		if is_instance_valid(object):
			player.remove_collision_exception_with(object)
	ignored.clear()
	player.body.contextual_pose.seated = false

func save_position() -> Vector3:
	return exit_position if is_instance_valid(seat) else player.global_position

func _on_hit() -> void:
	if is_instance_valid(seat):
		stand(true)
