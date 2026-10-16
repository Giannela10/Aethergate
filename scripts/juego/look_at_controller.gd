extends RefCounted
## Visual-only gaze, in head-parent space; never rotates the actor/collider.
var target: Node3D
var target_height := 1.7
var yaw := 0.0
var pitch := 0.0
var enabled := true
var max_yaw := deg_to_rad(50.0)
var max_pitch := deg_to_rad(22.0)

func apply(head: Node3D, delta: float) -> void:
	var desired := Vector2.ZERO
	if enabled and is_instance_valid(target) and target.is_inside_tree():
		var local := (head.get_parent() as Node3D).to_local(target.global_position+Vector3.UP*target_height)-head.position
		if local.length_squared() > 0.01:
			var raw_yaw := atan2(-local.x,-local.z)
			# Behind the shoulders: return to neutral rather than stare sideways.
			if absf(raw_yaw) < deg_to_rad(100):
				desired.x = clampf(raw_yaw,-max_yaw,max_yaw)
				desired.y = clampf(atan2(local.y,Vector2(local.x,local.z).length()),-max_pitch,max_pitch)
	var weight := 1.0-exp(-8.0*delta)
	yaw = lerpf(yaw,desired.x,weight)
	pitch = lerpf(pitch,desired.y,weight)
	head.rotation.y = yaw
	head.rotation.x += pitch
