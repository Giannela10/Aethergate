extends SubViewportContainer

const AVATAR = preload("res://scripts/juego/main_character_visual_6_2.gd")
var model: Node3D
var camera: Camera3D
var stage_viewport: SubViewport
var yaw := PI
var fitting_size := 2.8
var profile := {}
var can_rotate := false
var portrait := false
var applied_profile := {}
var frame_revision := 0

func _ready() -> void:
	stretch = true
	stage_viewport = SubViewport.new()
	stage_viewport.size = Vector2i(maxi(2, int(size.x)), maxi(2, int(size.y)))
	stage_viewport.own_world_3d = true
	stage_viewport.transparent_bg = true
	stage_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(stage_viewport)
	model = AVATAR.new()
	stage_viewport.add_child(model)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#dceaff")
	environment.environment.ambient_light_energy = 0.78
	stage_viewport.add_child(environment)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-35, 23, 0)
	sunlight.light_color = Color("#fff2db")
	sunlight.light_energy = 1.4
	stage_viewport.add_child(sunlight)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 180, 0)
	rim.light_color = Color("#87bcff")
	rim.light_energy = 0.65
	stage_viewport.add_child(rim)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	stage_viewport.add_child(camera)
	camera.current = true
	mouse_filter = Control.MOUSE_FILTER_STOP if can_rotate else Control.MOUSE_FILTER_IGNORE
	if not profile.is_empty():
		set_profile(profile)
	resized.connect(_refresh)
	_refresh.call_deferred()

func set_profile(value: Dictionary) -> void:
	profile = value
	if not is_instance_valid(model) or applied_profile == profile:
		return
	model.apply_appearance(profile)
	applied_profile = profile.duplicate(true)
	_refresh()

func rotate_by(angle: float) -> void:
	yaw += angle
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if can_rotate and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		rotate_by(event.relative.x * 0.012)
		accept_event()

func _refresh() -> void:
	if not is_instance_valid(camera):
		return
	model.rotation.y = yaw
	model.animate(0.016, Vector3.ZERO, true, false)
	var head: Vector3 = model.head_pivot.global_position
	var foot := model.global_position.y - 0.08
	var top := head.y + 0.39
	if model.human62 != null and model.human62.active:
		var rig: Skeleton3D = model.human62.rig
		var head_id := rig.find_bone("head")
		if head_id != -1:
			top = maxf(top, rig.to_global(rig.get_bone_global_pose(head_id).origin).y + 0.30)
	var target := Vector3(0, (top + foot) * 0.5, 0)
	fitting_size = maxf((top - foot) * 1.12, 2.75)
	if portrait:
		target.y = top - 0.30
		fitting_size = 0.82
	camera.position = target + Vector3(0, 0, 5)
	camera.look_at(target)
	camera.size = fitting_size
	_render_preview()

func _render_preview() -> void:
	if DisplayServer.get_name() == "headless":
		stage_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	frame_revision += 1
	var revision := frame_revision
	# Let the renderer register the skinned garments before holding a static frame.
	self_modulate.a = 0.0
	stage_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for _frame in 2:
		await RenderingServer.frame_post_draw
		if revision != frame_revision:
			return
	stage_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	self_modulate.a = 1.0
