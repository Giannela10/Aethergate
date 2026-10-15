extends "res://scripts/juego/humanoid.gd"
## Visual exclusivo del jugador: conserva todo el rig y animador procedural.
var weapon_socket: Marker3D
var item_socket: Marker3D
var backpack_socket: Marker3D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_state := "Idle"
var appearance_adapter: RefCounted
var contextual_pose := preload("res://scripts/juego/contextual_pose.gd").new()

func play_context_action(kind: String) -> bool:
	if dead or hurt_t > 0 or is_punching():
		return false
	var played: bool = contextual_pose.play(kind)
	if played and kind in ["read","inspect"]:
		contextual_pose.apply(self,0.15,Vector3.ZERO)
	return played

func apply_appearance(profile: Dictionary) -> void:
	if appearance_adapter == null:
		appearance_adapter = preload("res://scripts/juego/procedural_appearance_adapter.gd").new(self)
	appearance_adapter.apply_appearance(profile)

func _ready() -> void:
	shirt_color = Color("315e78")
	pants_color = Color("28394a")
	hair_color = Color("332a25")
	super._ready()
	fall_pivot.name = "Model"
	head_pivot.name = "Head"
	chest.name = "Torso"
	shoulder_l.name = "LeftArm"
	shoulder_r.name = "RightArm"
	hip_l.name = "LeftLeg"
	hip_r.name = "RightLeg"
	# Silueta más definida sin cambiar alturas, pivotes ni colisiones.
	_cyl(chest,0.175,0.14,0.28,Vector3(0,0.115,0),shirt_color,Vector3(1.12,1,0.81))
	for side in [-1.0,1.0]:
		var collar := _box(chest,Vector3(0.075,0.10,0.025),Vector3(side*0.055,0.25,-0.13),Color("e3e8e8"))
		collar.rotation.z = side*0.3
		_box(chest,Vector3(0.018,0.35,0.02),Vector3(side*0.11,0.06,-0.143),Color("1c3546"))
		_box(chest,Vector3(0.018,0.31,0.035),Vector3(side*0.135,0.1,0.085),Color("172732"))
	for ankle in [ankle_l,ankle_r]:
		for index in 3:
			_box(ankle,Vector3(0.075,0.008,0.012),Vector3(0,-0.018,-0.07-index*0.023),Color("dce6ea"))
	_box(chest,Vector3(0.08,0.09,0.016),Vector3(-0.085,0.08,-0.16),Color("dceff2"))
	_cyl(elbow_l,0.04,0.04,0.03,Vector3(0,-0.22,0),Color("15212a"))
	weapon_socket = Marker3D.new()
	weapon_socket.name = "WeaponSocket"
	hand_r.add_child(weapon_socket)
	item_socket = Marker3D.new()
	item_socket.name = "ItemSocket"
	hand_r.add_child(item_socket)
	backpack_socket = Marker3D.new()
	backpack_socket.name = "BackpackSocket"
	backpack_socket.position = Vector3(0,0.07,0.18)
	chest.add_child(backpack_socket)
	var bag := _ball(backpack_socket,0.23,Vector3(0,-0.02,0.05),Color("bb874e"),Vector3(0.80,1.15,0.52))
	bag.name = "Mochila"
	_box(backpack_socket,Vector3(0.25,0.18,0.07),Vector3(0,-0.12,0.16),Color("926437"))
	_box(backpack_socket,Vector3(0.24,0.012,0.012),Vector3(0,-0.04,0.20),Color("d5d9d5"))
	_box(backpack_socket,Vector3(0.10,0.045,0.045),Vector3(0,0.245,0.04),Color("28363d"))
	var future := Node3D.new()
	future.name = "ImportedModel"
	future.visible = false
	fall_pivot.add_child(future)
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	future.add_child(skeleton)
	animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	add_child(animation_player)
	var library := AnimationLibrary.new()
	var machine := AnimationNodeStateMachine.new()
	for state in ["Idle","Walk","Run","Attack","Hurt","Death"]:
		var clip := Animation.new()
		clip.length = 1.0
		clip.loop_mode = Animation.LOOP_LINEAR if state in ["Idle","Walk","Run"] else Animation.LOOP_NONE
		library.add_animation(state,clip)
		var node := AnimationNodeAnimation.new()
		node.animation = state
		machine.add_node(state,node)
	animation_player.add_animation_library("",library)
	animation_tree = AnimationTree.new()
	animation_tree.name = "AnimationTree"
	animation_tree.tree_root = machine
	animation_tree.anim_player = NodePath("../AnimationPlayer")
	animation_tree.active = false
	add_child(animation_tree)
	set_meta("animation_note","Clips de reserva sin pistas. Reemplazar con un modelo riggeado; el animador procedural continúa activo.")

func _build_head() -> void:
	_ball(head_pivot,0.107,Vector3(0,0.10,0),skin_color,Vector3(0.87,1.14,0.88),0.65)
	_ball(head_pivot,0.073,Vector3(0,0.045,-0.015),skin_color,Vector3(0.95,0.66,0.92),0.65)
	var hair := SphereMesh.new()
	hair.radius = 0.11
	hair.height = 0.22
	hair.is_hemisphere = true
	_node(head_pivot,hair,Vector3(0,0.13,0.01),hair_color,Vector3(0.92,0.75,0.93),0.9)
	for side in [-1.0,1.0]:
		_ball(head_pivot,0.018,Vector3(side*0.094,0.095,0),skin_color,Vector3(0.7,1,0.7))
		_ball(head_pivot,0.014,Vector3(side*0.038,0.11,-0.088),Color("f4f3ec"),Vector3(1,0.65,0.5))
		_ball(head_pivot,0.007,Vector3(side*0.038,0.11,-0.095),Color("303b32"))
		_box(head_pivot,Vector3(0.035,0.007,0.012),Vector3(side*0.038,0.135,-0.088),hair_color)
	_ball(head_pivot,0.017,Vector3(0,0.086,-0.096),skin_color.darkened(0.06),Vector3(0.7,1,1.1))
	_box(head_pivot,Vector3(0.042,0.005,0.008),Vector3(0,0.052,-0.085),Color("986958"))

func equip(weapon: Node3D) -> void:
	weapon_socket.add_child(weapon)
	weapon.position = Vector3.ZERO
	weapon.rotation = Vector3.ZERO
	weapon_node = weapon
	armed = true
	punch_p[0] = -1
	punch_p[1] = -1

func unequip() -> Node3D:
	var weapon := weapon_node
	if is_instance_valid(weapon) and weapon.get_parent():
		weapon.get_parent().remove_child(weapon)
	weapon_node = null
	armed = false
	punch_p[1] = -1
	return weapon

func animate(delta: float, velocity: Vector3, on_floor: bool, crouching: bool) -> void:
	var visual_velocity := Vector3.ZERO if contextual_pose.seated else velocity
	super.animate(delta,visual_velocity,on_floor or contextual_pose.seated,crouching and not contextual_pose.seated)
	contextual_pose.apply(self,delta,visual_velocity)
	animation_state = "Death" if dead else ("Hurt" if hurt_t > 0 else ("Attack" if is_punching() else ("Run" if velocity.length() > 3.2 else ("Walk" if Vector2(velocity.x,velocity.z).length() > 0.2 else "Idle"))))
	if contextual_pose.seated and not dead and hurt_t <= 0:
		animation_state = "Sit"
	set_meta("animation_state",animation_state)
