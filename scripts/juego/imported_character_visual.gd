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
# Disabled until a compatible, individually tested skeleton is supplied.
var ragdoll_enabled := false
var foot_ik_enabled := false

func _init(owner_visual: Node3D) -> void:
	host = owner_visual

func install(scene: PackedScene, animation_map: Dictionary, bindings: Dictionary = {}) -> bool:
	var candidate := scene.instantiate() as Node3D
	if candidate == null: return false
	var players := candidate.find_children("*","AnimationPlayer",true,false)
	var skeletons := candidate.find_children("*","Skeleton3D",true,false)
	if players.is_empty() or skeletons.is_empty():
		candidate.free()
		return false
	if (skeletons[0] as Skeleton3D).get_bone_count() == 0:
		candidate.free()
		return false
	var animator := players[0] as AnimationPlayer
	for state in ["IDLE","WALK","RUN"]:
		if not animator.has_animation(str(animation_map.get(state,""))):
			candidate.free()
			return false
	# Required real sockets prevent equipped items from disappearing with fallback.
	for key in ["weapon_socket","item_socket"]:
		var socket_target := candidate.get_node_or_null(NodePath(str(bindings.get(key,"__missing"))))
		if not socket_target is Node3D:
			candidate.free()
			return false
	clear()
	host.add_child(candidate)
	model = candidate
	model.name = "ImportedCharacter"
	player = animator
	skeleton = skeletons[0]
	clips = animation_map.duplicate()
	socket_bindings = bindings.duplicate()
	for key in socket_bindings:
		var socket = host.get(key)
		if socket is Node3D:
			original_sockets[key] = {"parent":socket.get_parent(),"transform":socket.transform}
	_build_tree()
	if model.has_method("apply_appearance"):
		model.call("apply_appearance",host.get_meta("appearance_profile",{}))
	return true

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

func update(state: String, speed: float) -> void:
	if not is_instance_valid(model): return
	var supported := clips.has(state) and player.has_animation(str(clips[state]))
	if not supported:
		tree.active = false
		model.hide()
		host.fall_pivot.show()
		_restore_sockets()
		return
	model.show()
	tree.active = true
	host.fall_pivot.hide()
	var target_state := "LOCOMOTION" if state in ["IDLE","WALK","RUN"] else state
	playback.travel(target_state)
	tree.set("parameters/LOCOMOTION/blend_position",clampf(speed,0,5.5))
	for key in socket_bindings:
		var target := model.get_node_or_null(NodePath(str(socket_bindings[key]))) as Node3D
		var socket = host.get(key)
		if target != null and socket is Node3D:
			if socket.get_parent() != host:
				socket.reparent(host,true)
			socket.global_transform = target.global_transform
	if model.has_method("set_gaze"):
		model.call("set_gaze",host.look_controller.yaw,host.look_controller.pitch)
	if model.has_method("set_blink"):
		model.call("set_blink",host.blink_time > 0)

func set_expression(value: String) -> void:
	expression = value
	if is_instance_valid(model) and model.has_method("set_expression"):
		model.call("set_expression",value)

func clear() -> void:
	_restore_sockets()
	original_sockets.clear()
	if is_instance_valid(model):
		model.queue_free()
	model = null
	player = null
	skeleton = null
	tree = null
	playback = null
	host.fall_pivot.show()
