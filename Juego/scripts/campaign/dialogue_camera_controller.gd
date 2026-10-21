extends Node
enum Mode { NORMAL, CLOSE_UP, TWO_SHOT, BOSS_DIALOGUE }
var mode := Mode.NORMAL
var camera: Camera3D
var source: Camera3D
var speaker: Node3D
var listener: Node3D
var elapsed := 0.0
var expression_before := "NEUTRAL"

func begin(player: Node3D, actor: Node3D, requested: Mode = Mode.TWO_SHOT) -> void:
	finish()
	listener = player
	speaker = actor
	_set_gaze(player,actor)
	_set_gaze(actor,player)
	source = get_viewport().get_camera_3d()
	if source == null or requested == Mode.NORMAL:
		return
	var a := player.global_position+Vector3.UP*1.9
	var b := actor.global_position+Vector3.UP*1.9
	if a.distance_to(b) > 7 or absf(a.y-b.y) > 3:
		return
	camera = Camera3D.new()
	camera.name = "DialogueCamera"
	add_child(camera)
	camera.global_transform = source.global_transform
	camera.fov = source.fov
	camera.near = source.near
	camera.far = source.far
	var focus := a.lerp(b,0.65 if requested == Mode.CLOSE_UP else 0.5)
	var destination := focus+(source.global_position-focus).normalized()*clampf(source.global_position.distance_to(focus)*0.85,2.6,5.0)
	# A sphere catches corners which a single camera ray would miss.
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = source.global_position
	query.motion = destination-source.global_position
	query.exclude = _exclude_bodies(player,actor)
	var space := player.get_world_3d().direct_space_state
	var sweep := space.cast_motion(query)
	var ray := PhysicsRayQueryParameters3D.create(focus,destination)
	ray.exclude = query.exclude
	query.transform.origin = destination
	query.motion = Vector3.ZERO
	if sweep[0] < 1.0 or not space.intersect_shape(query,1).is_empty() or not space.intersect_ray(ray).is_empty():
		camera.queue_free()
		camera = null
		return
	mode = requested
	camera.make_current()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var target_transform := Transform3D(camera.global_basis,destination).looking_at(focus)
	tween.tween_property(camera,"global_transform",target_transform,0.25)

func _exclude_bodies(a: Node, b: Node) -> Array[RID]:
	var result: Array[RID] = []
	for node in [a,b]:
		if node is CollisionObject3D:
			result.append(node.get_rid())
		for child in node.find_children("*","CollisionObject3D",true,false):
			result.append(child.get_rid())
	return result

func _visual(actor: Node) -> Node3D:
	for property in ["body","model","_visual","visual"]:
		var candidate = actor.get(property)
		if candidate is Node3D and candidate.get("look_controller") != null:
			return candidate
	return null

func _set_gaze(actor: Node3D, target: Node3D) -> void:
	var visual := _visual(actor)
	if visual != null:
		visual.look_controller.target = target
		visual.look_controller.target_height = 1.8
		visual.look_controller.apply(visual.head_pivot,0.18)
		if visual.has_method("play_context_action"):
			visual.play_context_action("talk")

func finish() -> void:
	for actor in [speaker,listener]:
		if is_instance_valid(actor):
			var visual := _visual(actor)
			if visual != null:
				visual.look_controller.target = null
	if is_instance_valid(camera):
		if is_instance_valid(source):
			source.make_current()
		camera.queue_free()
	camera = null
	mode = Mode.NORMAL
	speaker = null
	listener = null
