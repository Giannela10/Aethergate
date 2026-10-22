extends RefCounted
## Reserve volume around the camera, rather than checking only its center ray.
static func resolve(space: PhysicsDirectSpaceState3D, pivot: Vector3, desired: Vector3, excluded: Array[RID]) -> Vector3:
	var offset := desired-pivot
	if offset.length_squared() < 0.0001: return desired
	var shape := SphereShape3D.new()
	shape.radius = 0.22
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = pivot
	query.motion = offset
	query.collision_mask = 1
	query.exclude = excluded
	query.margin = 0.005
	var sweep := space.cast_motion(query)
	var distance := offset.length()*float(sweep[0])
	var ray := PhysicsRayQueryParameters3D.create(pivot,desired,1,excluded)
	var hit := space.intersect_ray(ray)
	if not hit.is_empty(): distance = minf(distance,maxf(0.05,pivot.distance_to(hit.position)-shape.radius))
	return pivot+offset.normalized()*maxf(0.05,distance-0.025 if distance < offset.length() else distance)
