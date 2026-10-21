extends RefCounted
## Local access validation, not navigation from spawn. Uses actual pickup range.
static func find_approach(player: CharacterBody3D,pickup: Node3D) -> Variant:
	for radius in [0.9,1.3,1.7,2.0]:
		for angle in 16:
			var candidate: Vector3 = pickup.global_position+Vector3(cos(angle*TAU/16),0,sin(angle*TAU/16))*radius
			var safe = player.get_node("SeatController").safe_position(candidate)
			if safe == null or safe.distance_to(pickup.global_position) > pickup.interaction_range: continue
			var ray := PhysicsRayQueryParameters3D.create(safe+Vector3.UP*1.2,pickup.global_position+Vector3.UP*1.2,player.collision_mask,[player.get_rid()])
			var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
			var collider = hit.get("collider")
			if hit.is_empty() or collider == pickup.furniture or (collider != null and pickup.furniture.is_ancestor_of(collider)): return safe
	return null
