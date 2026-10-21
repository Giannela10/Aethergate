extends RefCounted
## Asset adapter: gameplay timing remains in the procedural host.
var host: Node3D
var model: Node3D
var player: AnimationPlayer
var skeleton: Skeleton3D
var tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var clips: Dictionary = {}
var socket_bindings: Dictionary = {}
var original_sockets: Dictionary = {}
var expression := "NEUTRAL"
var locomotion_speed := 0.0
var resolved_sockets: Dictionary = {}
var activity_level := 0
var active_state := ""
var imported_visible := false
var blend_position := -1.0
var last_blink := false
var face_channels: Dictionary = {}
var visual_quality := "CHARACTER_HIGH"
# Disabled until a compatible, individually tested skeleton is supplied.
var ragdoll_enabled := false
var foot_ik_enabled := false

func _init(owner_visual: Node3D) -> void:
	host = owner_visual

func install(scene: PackedScene, animation_map: Dictionary, bindings: Dictionary = {}) -> bool:
	if scene == null: return false
	var instance := scene.instantiate()
	if not instance is Node3D:
		instance.free()
		return false
	var candidate := instance as Node3D
	var players := candidate.find_children("*","AnimationPlayer",true,false)
	var skeletons := candidate.find_children("*","Skeleton3D",true,false)
	if candidate is Skeleton3D: skeletons.push_front(candidate)
	if players.is_empty() or skeletons.is_empty():
		candidate.free()
		return false
	if (skeletons[0] as Skeleton3D).get_bone_count() == 0:
		candidate.free()
		return false
	var drawable := false
	var meshes := candidate.find_children("*","MeshInstance3D",true,false)
	if candidate is MeshInstance3D: meshes.push_front(candidate)
	for mesh in meshes:
		if mesh.mesh != null and mesh.mesh.get_surface_count() > 0 and mesh.visible:
			drawable = true
			break
	if not drawable:
		candidate.free()
		return false
	var animator := players[0] as AnimationPlayer
	var normalized_clips := {}
	for key in animation_map: normalized_clips[str(key).to_upper()] = animation_map[key]
	for state in ["IDLE","WALK","RUN"]:
		if not animator.has_animation(str(normalized_clips.get(state,""))):
			candidate.free()
			return false
	# Required real sockets prevent equipped items from disappearing with fallback.
	var targets := {}
	for key in ["weapon_socket","item_socket","backpack_socket","hair_socket","head_accessory_socket"]:
		if not bindings.has(key):
			if key not in ["weapon_socket","item_socket"]: continue
			candidate.free()
			return false
		var socket_target := _resolve_binding(candidate,skeletons[0],bindings[key],bindings.get("bones",{}))
		if socket_target == null:
			candidate.free()
			return false
		targets[key] = socket_target
	clear()
	host.add_child(candidate)
	model = candidate
	model.name = "ImportedCharacter"
	model.hide()
	player = animator
	skeleton = skeletons[0]
	clips = normalized_clips
	resolved_sockets = targets
	socket_bindings = {}
	for key in targets: socket_bindings[key] = true
	for key in socket_bindings:
		var socket = host.get(key)
		if socket is Node3D:
			original_sockets[key] = {"parent":socket.get_parent(),"transform":socket.transform}
	_build_tree()
	_cache_face_channels(bindings.get("expressions",{}))
	expression = ""
	set_expression("NEUTRAL")
	if model.has_method("apply_appearance"):
		model.call("apply_appearance",host.get_meta("appearance_profile",{}))
	if model.has_method("set_visual_quality"): model.call("set_visual_quality",visual_quality)
	return true

func set_quality(value: String) -> void:
	if visual_quality == value: return
	visual_quality = value
	if is_instance_valid(model) and model.has_method("set_visual_quality"):
		model.call("set_visual_quality",value)

func _resolve_binding(candidate: Node3D, rig: Skeleton3D, binding: Variant, bones: Dictionary) -> Node3D:
	if binding is String or binding is NodePath:
		return candidate.get_node_or_null(NodePath(str(binding))) as Node3D
	if not binding is Dictionary: return null
	var requested := str(binding.get("bone",""))
	var bone_name := str(bones.get(requested,requested))
	if rig.find_bone(bone_name) < 0: return null
	var offset = binding.get("offset",Transform3D.IDENTITY)
	if not offset is Transform3D: return null
	var attachment := BoneAttachment3D.new()
	attachment.name = "SocketBone_"+bone_name
	rig.add_child(attachment)
	attachment.bone_name = bone_name
	var marker := Marker3D.new()
	marker.name = "SocketOffset"
	attachment.add_child(marker)
	marker.transform = offset
	return marker

func set_activity(level: int) -> void:
	if activity_level == level: return
	activity_level = level
	if is_instance_valid(tree): tree.active = level < 2 and imported_visible

func _cache_face_channels(mapping: Dictionary) -> void:
	face_channels.clear()
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if not mesh.mesh is ArrayMesh: continue
		for i in mesh.mesh.get_blend_shape_count():
			var shape: String = str(mesh.mesh.get_blend_shape_name(i))
			for state in ["HAPPY","ANGRY","WORRIED","SURPRISED","TIRED"]:
				if shape.to_lower() == str(mapping.get(state, state.to_lower())).to_lower():
					if not face_channels.has(state): face_channels[state] = []
					face_channels[state].append({"mesh":mesh,"index":i})

func _animation(clip: String) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = clip
	return node

func _build_tree() -> void:
	var machine := AnimationNodeStateMachine.new()
	var movement := AnimationNodeBlendSpace1D.new()
	movement.min_space = 0
	movement.max_space = 5.5
	movement.add_blend_point(_animation(str(clips.IDLE)),0,-1,&"IDLE")
	movement.add_blend_point(_animation(str(clips.WALK)),2.5,-1,&"WALK")
	movement.add_blend_point(_animation(str(clips.RUN)),5.5,-1,&"RUN")
	machine.add_node("LOCOMOTION",movement)
	for state in clips:
		if state in ["IDLE","WALK","RUN"] or not player.has_animation(str(clips[state])): continue
		machine.add_node(state,_animation(str(clips[state])))
		for pair in [["LOCOMOTION",state],[state,"LOCOMOTION"]]:
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.12
			machine.add_transition(pair[0],pair[1],transition)
	for pair in [["JUMP","FALL"],["FALL","LAND"]]:
		if machine.has_node(pair[0]) and machine.has_node(pair[1]):
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.1
			machine.add_transition(pair[0],pair[1],transition)
	tree = AnimationTree.new()
	tree.name = "CharacterAnimationTree"
	model.add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.tree_root = machine
	tree.active = true
	playback = tree.get("parameters/playback")
	playback.start("LOCOMOTION")

func _restore_sockets() -> void:
	for key in original_sockets:
		var socket = host.get(key)
		var saved: Dictionary = original_sockets[key]
		if is_instance_valid(socket) and is_instance_valid(saved.parent):
			if socket.get_parent() != saved.parent:
				socket.reparent(saved.parent,false)
			socket.transform = saved.transform

func update(state: String, speed: float, delta: float = 0.0166667) -> void:
	if not is_instance_valid(model): return
	if activity_level >= 3:
		tree.active = false
		return
	var supported := clips.has(state) and player.has_animation(str(clips[state]))
	if not supported:
		tree.active = false
		if imported_visible:
			model.hide()
			host.fall_pivot.show()
			_restore_sockets()
		imported_visible = false
		active_state = ""
		return
	model.show()
	tree.active = activity_level < 2
	host.fall_pivot.hide()
	imported_visible = true
	var target_state := "LOCOMOTION" if state in ["IDLE","WALK","RUN"] else state
	if active_state != target_state:
		playback.travel(target_state)
		active_state = target_state
	locomotion_speed = move_toward(locomotion_speed,clampf(speed,0,5.5),maxf(delta,0)*16.0)
	if not is_equal_approx(blend_position,locomotion_speed):
		blend_position = locomotion_speed
		tree.set("parameters/LOCOMOTION/blend_position",locomotion_speed)
	# LOD2 samples the imported pose only on the host's reduced visual tick.
	if activity_level == 2: tree.advance(delta)
	for key in socket_bindings:
		var target := resolved_sockets.get(key) as Node3D
		var socket = host.get(key)
		if target != null and socket is Node3D:
			if socket.get_parent() != host:
				socket.reparent(host,true)
			socket.global_transform = target.global_transform
	if activity_level == 0 and model.has_method("set_gaze"):
		model.call("set_gaze",host.look_controller.yaw,host.look_controller.pitch)
	var blinking: bool = activity_level == 0 and host.blink_time > 0
	if blinking != last_blink and model.has_method("set_blink"):
		model.call("set_blink",blinking)
	last_blink = blinking

func set_expression(value: String) -> void:
	if expression == value or activity_level > 0: return
	expression = value
	if is_instance_valid(model) and model.has_method("set_expression"):
		model.call("set_expression",value)
	for state in face_channels:
		for channel in face_channels[state]:
			if is_instance_valid(channel.mesh): channel.mesh.set_blend_shape_value(channel.index,1.0 if state == value else 0.0)

func clear() -> void:
	_restore_sockets()
	original_sockets.clear()
	resolved_sockets.clear()
	face_channels.clear()
	if is_instance_valid(model):
		model.queue_free()
	model = null
	player = null
	skeleton = null
	tree = null
	playback = null
	locomotion_speed = 0.0
	blend_position = -1.0
	active_state = ""
	imported_visible = false
	host.fall_pivot.show()
