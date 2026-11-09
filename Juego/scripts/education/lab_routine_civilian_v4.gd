extends "res://scripts/education/routine_civilian_v4.gd"
var route_index := 0
func _physics_process(delta: float) -> void:
	if sleeping or route.size()!=4: return
	var inside: bool=activity in ["CLASS","PHONE","TALK"]
	var destination_index := 3 if inside else 0
	visual.contextual_pose.seated=inside and route_index==3
	visual.contextual_pose.seat_height=0.45
	velocity=Vector3.ZERO
	if route_index!=destination_index:
		var next := route_index+(1 if destination_index>route_index else -1)
		var offset: Vector3=route[next]-global_position; offset.y=0
		if offset.length()<0.18: route_index=next
		else:
			velocity=offset.normalized()*1.3
			rotation.y=atan2(-velocity.x,-velocity.z)
	elif inside:
		rotation.y=0
		visual.set_visual_activity("TYPE" if activity=="CLASS" else activity)
	else: visual.set_visual_activity("")
	velocity.y=-8 if not is_on_floor() else 0
	move_and_slide()
	visual.animate(delta,velocity,is_on_floor(),false)
