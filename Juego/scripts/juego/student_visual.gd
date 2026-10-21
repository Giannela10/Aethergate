extends "res://scripts/juego/humanoid.gd"
## Visual exclusivo del jugador: conserva todo el rig y animador procedural.
const STATES := ["IDLE","WALK","RUN","CROUCH","CROUCH_WALK","JUMP","FALL","LAND","ATTACK_LIGHT","ATTACK_HEAVY","THROW","DODGE","BLOCK","PARRY","HIT","DEATH","INTERACT","PICKUP","USE_COMPUTER","PHONE","SIT","TALK","IDLE_LOOK_AROUND","IDLE_CHECK_PHONE","IDLE_ADJUST_BACKPACK","CROSS_ARMS","BOSS_IDLE","BOSS_INTRO","BOSS_MELEE","BOSS_RANGED","BOSS_SPECIAL","BOSS_PHASE","BOSS_HIT","BOSS_DEATH"]
var visual_state := "IDLE"
var idle_wait := randf_range(9.0,18.0)
var idle_variant := ""
var idle_remaining := 0.0
var activity_visual: RefCounted
var combat_check := 0.0
var nearby_combat := false
var module_parts: Dictionary = {}
var phone_visible := false
var weapon_stance := "LIGHT"
var equip_t := 0.0
var transient_state := ""
var transient_time := 0.0

func request_visual_state(state: String, duration: float = 0.4) -> void:
	if state in STATES:
		transient_state = state
		transient_time = clampf(duration,0.05,2.0)

func show_phone(value: bool) -> void:
	phone_visible = value
	if activity_visual != null:
		activity_visual.set_activity("PHONE" if value else "","PHONE" if value else "NONE")
		if value:
			activity_visual.apply(0.2,true)

func set_visual_activity(action: String, prop: String = "NONE") -> void:
	activity_visual.set_activity(action,prop)
var weapon_socket: Marker3D
var item_socket: Marker3D
var backpack_socket: Marker3D
var hair_socket: Marker3D
var head_accessory_socket: Marker3D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_state := "Idle"
var appearance_adapter: RefCounted
var imported_visual: RefCounted

func install_imported_visual(scene: PackedScene, clips: Dictionary, bindings: Dictionary = {}) -> bool:
	if imported_visual == null:
		imported_visual = preload("res://scripts/juego/imported_character_visual.gd").new(self)
	imported_visual.set_quality(get_meta("character_quality","CHARACTER_HIGH"))
	return imported_visual.install(scene,clips,bindings)

var contextual_pose := preload("res://scripts/juego/contextual_pose.gd").new()

func play_context_action(kind: String) -> bool:
	if dead or hurt_t > 0 or is_punching():
		return false
	var played: bool = contextual_pose.play(kind)
	if played and kind in ["read","inspect"]:
		contextual_pose.apply(self,0.15,Vector3.ZERO)
	return played

func apply_appearance(profile: Dictionary) -> void:
	set_meta("appearance_profile",profile.duplicate(true))
	if appearance_adapter == null:
		appearance_adapter = preload("res://scripts/juego/procedural_appearance_adapter.gd").new(self)
	appearance_adapter.apply_appearance(profile)
	if imported_visual != null and is_instance_valid(imported_visual.model) and imported_visual.model.has_method("apply_appearance"):
		imported_visual.model.call("apply_appearance",profile)

func _ready() -> void:
	shirt_color = Color("315e78")
	pants_color = Color("28394a")
	hair_color = Color("332a25")
	super._ready()
	activity_visual = preload("res://scripts/juego/character_activity_visual.gd").new(self)
	fall_pivot.name = "Model"
	head_pivot.name = "Head"
	chest.name = "Torso"
	shoulder_l.name = "LeftArm"
	shoulder_r.name = "RightArm"
	hip_l.name = "LeftLeg"
	hip_r.name = "RightLeg"
	# Silueta más definida sin cambiar alturas, pivotes ni colisiones.
	_cyl(chest,0.16,0.13,0.28,Vector3(0,0.115,0),shirt_color,Vector3(1.04,1,0.78))
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
	hair_socket = Marker3D.new()
	hair_socket.name = "HairSocket"
	head_pivot.add_child(hair_socket)
	head_accessory_socket = Marker3D.new()
	head_accessory_socket.name = "HeadAccessorySocket"
	head_pivot.add_child(head_accessory_socket)
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
	for state in STATES+["Idle","Walk","Run","Attack","Hurt","Death"]:
		var clip := Animation.new()
		clip.length = 1.0
		clip.loop_mode = Animation.LOOP_LINEAR if state in ["IDLE","WALK","RUN","CROUCH","CROUCH_WALK"] else Animation.LOOP_NONE
		library.add_animation(state,clip)
		var node := AnimationNodeAnimation.new()
		node.animation = state
		machine.add_node(state,node)
	for state in STATES:
		if state != "IDLE":
			for pair in [["IDLE",state],[state,"IDLE"]]:
				var transition := AnimationNodeStateMachineTransition.new()
				transition.xfade_time = 0.12
				machine.add_transition(pair[0],pair[1],transition)
	animation_player.add_animation_library("",library)
	animation_tree = AnimationTree.new()
	animation_tree.name = "AnimationTree"
	animation_tree.tree_root = machine
	animation_tree.anim_player = NodePath("../AnimationPlayer")
	animation_tree.active = false
	add_child(animation_tree)
	set_meta("animation_note","Clips de reserva sin pistas. Reemplazar con un modelo riggeado; el animador procedural continúa activo.")
	_capture_modules()

func _capture_modules() -> void:
	module_parts = {"BODY":[],"HEAD":[],"HAIR":[],"TOP":[],"BOTTOM":[],"SHOES":[],"HEAD_ACCESSORY":[],"ACCESSORY":[],"BACKPACK":[]}
	for mesh in fall_pivot.find_children("*","MeshInstance3D",true,false):
		var category: String = mesh.get_meta("visual_module","BODY")
		var material := mesh.material_override as StandardMaterial3D
		if backpack_socket.is_ancestor_of(mesh): category = "BACKPACK"
		elif material != null and not mesh.has_meta("visual_module"):
			var color := material.albedo_color
			if color.is_equal_approx(hair_color): category = "HAIR" if mesh.mesh is SphereMesh else "HEAD"
			elif color.is_equal_approx(shirt_color): category = "TOP"
			elif color.is_equal_approx(pants_color): category = "BOTTOM"
			elif color in [SHOE_UPPER,SHOE_SOLE]: category = "SHOES"
			elif head_pivot.is_ancestor_of(mesh): category = "HEAD"
		mesh.set_meta("visual_module",category)
		module_parts[category].append(mesh)

func _build_arm(side: float) -> Array:
	var joints := super._build_arm(side)
	# Flatten palms slightly; the established attachment stays put.
	for mesh in joints[2].get_children():
		if mesh is MeshInstance3D:
			mesh.scale.z *= 0.72
	return joints

func _idle_variation(delta: float, speed: float, on_floor: bool) -> void:
	if not secondary_animation_enabled:
		idle_variant = ""
		return
	var actor := get_parent()
	var campaign := get_tree().get_first_node_in_group("campus_campaign")
	combat_check -= delta
	if combat_check <= 0:
		combat_check = 0.5
		nearby_combat = false
		if actor.is_in_group("player"):
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if enemy is Node3D and enemy.get("dead") != true and enemy.global_position.distance_squared_to(actor.global_position) < 100:
					nearby_combat = true
	var blocked: bool = not actor.is_in_group("player") or speed > 0.1 or not on_floor or dead or hurt_t > 0 or armed or is_punching() or contextual_pose.seated or contextual_pose.remaining > 0 or actor.get("busy") == true or nearby_combat or actor.get_meta("important_scene",false)
	blocked = blocked or (campaign != null and (campaign.active_duel != null or (campaign.ui != null and campaign.ui.modal)))
	if blocked:
		if idle_variant == "IDLE_CHECK_PHONE" and not phone_visible:
			activity_visual.set_activity("","NONE")
		idle_remaining = 0
		idle_variant = ""
		idle_wait = maxf(idle_wait,3)
		return
	idle_wait -= delta
	if idle_wait <= 0:
		idle_variant = ["IDLE_LOOK_AROUND","IDLE_CHECK_PHONE","IDLE_ADJUST_BACKPACK","CROSS_ARMS"].pick_random()
		idle_remaining = 2.0
		if idle_variant == "IDLE_CHECK_PHONE":
			activity_visual.set_activity("PHONE","PHONE")
		idle_wait = randf_range(12.0,24.0)
	idle_remaining = maxf(0,idle_remaining-delta)
	if idle_remaining <= 0:
		if idle_variant == "IDLE_CHECK_PHONE" and not phone_visible:
			activity_visual.set_activity("","NONE")
		idle_variant = ""
		return
	var weight := sin(PI*(1.0-idle_remaining/2.0))
	match idle_variant:
		"IDLE_LOOK_AROUND":
			head_pivot.rotation.y += sin(time*1.3)*0.35*weight
		"IDLE_CHECK_PHONE":
			shoulder_l.rotation.x = lerpf(shoulder_l.rotation.x,0.8,weight)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x,1.8,weight)
			head_pivot.rotation.x += 0.18*weight
		"IDLE_ADJUST_BACKPACK":
			shoulder_l.rotation.x = lerpf(shoulder_l.rotation.x,0.5,weight)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x,2.1,weight)
		"CROSS_ARMS":
			for shoulder in [shoulder_l,shoulder_r]: shoulder.rotation.x = lerpf(shoulder.rotation.x,0.7,weight)
			for elbow in [elbow_l,elbow_r]: elbow.rotation.x = lerpf(elbow.rotation.x,2.2,weight)

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
		_ball(head_pivot,0.011,Vector3(side*0.038,0.11,-0.088),Color("f4f3ec"),Vector3(1,0.65,0.5))
		_ball(head_pivot,0.0055,Vector3(side*0.038,0.11,-0.095),Color("303b32"))
		_box(head_pivot,Vector3(0.035,0.007,0.012),Vector3(side*0.038,0.135,-0.088),hair_color)
	_ball(head_pivot,0.017,Vector3(0,0.086,-0.096),skin_color.darkened(0.06),Vector3(0.7,1,1.1))
	_box(head_pivot,Vector3(0.042,0.005,0.008),Vector3(0,0.052,-0.085),Color("986958"))

func equip(weapon: Node3D) -> void:
	weapon_socket.add_child(weapon)
	weapon.position = Vector3.ZERO
	weapon.rotation = Vector3.ZERO
	weapon_node = weapon
	armed = true
	equip_t = 0.18
	weapon_stance = "MEDIUM"
	var id := str(weapon.get_meta("catalog_item_id",""))
	if id in ["Silla","LibroPesado","ExtintorDorado","NotebookRoto"]:
		weapon_stance = "HEAVY"
	elif id in ["PaletaPingPong","Cable"]: weapon_stance = "LIGHT"
	elif id in ["TecladoAdministrador","RouterPortatil"]: weapon_stance = "SPECIAL"
	elif weapon.has_method("can_throw") and weapon.can_throw(): weapon_stance = "THROWABLE"
	punch_p[0] = -1
	punch_p[1] = -1

func unequip() -> Node3D:
	var weapon := weapon_node
	if is_instance_valid(weapon) and weapon.get_parent():
		weapon.get_parent().remove_child(weapon)
	weapon_node = null
	armed = false
	weapon_stance = "LIGHT"
	punch_p[1] = -1
	return weapon

func animate(delta: float, velocity: Vector3, on_floor: bool, crouching: bool) -> void:
	if not animation_due(delta): return
	delta = animation_delta
	var visual_velocity := Vector3.ZERO if contextual_pose.seated else velocity
	super._animate_pose(delta,visual_velocity,on_floor or contextual_pose.seated,crouching and not contextual_pose.seated)
	contextual_pose.apply(self,delta,visual_velocity)
	_idle_variation(delta,Vector2(velocity.x,velocity.z).length(),on_floor)
	if activity_visual != null:
		activity_visual.apply(delta,not armed and velocity.length() < 0.2 and (phone_visible or contextual_pose.remaining <= 0))
	equip_t = maxf(0,equip_t-delta)
	if armed and not is_punching() and not dead and hurt_t <= 0:
		shoulder_r.rotation.x -= sin(PI*equip_t/0.18)*0.18
		if weapon_stance == "HEAVY":
			shoulder_l.rotation.x = lerpf(shoulder_l.rotation.x,0.8,armed_t)
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x,1.45,armed_t)
	animation_state = "Death" if dead else ("Hurt" if hurt_t > 0 else ("Attack" if is_punching() else ("Run" if velocity.length() > 3.2 else ("Walk" if Vector2(velocity.x,velocity.z).length() > 0.2 else "Idle"))))
	if contextual_pose.seated and not dead and hurt_t <= 0:
		animation_state = "Sit"
	visual_state = "IDLE"
	var speed := Vector2(velocity.x,velocity.z).length()
	if dead: visual_state = "DEATH"
	elif hurt_t > 0: visual_state = "HIT"
	elif is_punching(): visual_state = "ATTACK_LIGHT"
	elif contextual_pose.seated: visual_state = "SIT"
	elif not on_floor: visual_state = "JUMP" if velocity.y > 0 else "FALL"
	elif land_t > 0.15: visual_state = "LAND"
	elif crouching: visual_state = "CROUCH_WALK" if speed > 0.2 else "CROUCH"
	elif speed > 3.2: visual_state = "RUN"
	elif speed > 0.2: visual_state = "WALK"
	elif contextual_pose.remaining > 0:
		visual_state = {"pickup":"PICKUP","computer":"USE_COMPUTER","phone":"PHONE"}.get(contextual_pose.action,"INTERACT")
	elif not idle_variant.is_empty(): visual_state = idle_variant
	if phone_visible and not dead and not is_punching(): visual_state = "PHONE"
	var combat := get_parent().get_node_or_null("CombatExtensions")
	if not dead and hurt_t <= 0 and combat != null:
		if combat.dodge_t > 0: visual_state = "DODGE"
		elif is_punching() and combat.heavy: visual_state = "ATTACK_HEAVY"
	transient_time = maxf(0,transient_time-delta)
	if transient_time > 0 and not dead and hurt_t <= 0:
		visual_state = transient_state
	if secondary_animation_enabled and not dead and hurt_t <= 0 and not is_punching():
		if visual_state in ["BLOCK","PARRY","BOSS_SPECIAL","BOSS_RANGED"]:
			shoulder_l.rotation.x = 0.85
			elbow_l.rotation.x = 1.65
			shoulder_r.rotation.x = 1.1
		elif visual_state == "THROW":
			shoulder_r.rotation.x = 2.3
		elif visual_state == "DODGE": chest.rotation.z += 0.12
	if imported_visual != null:
		var imported_state := hit_variant if visual_state == "HIT" and imported_visual.clips.has(hit_variant) else visual_state
		imported_visual.update(imported_state,speed,delta)
		imported_visual.set_expression(expression)
	if imported_visual == null or not imported_visual.imported_visible:
		backpack_socket.rotation.x = sin(phase)*0.025*minf(speed/2.5,1.0)
	set_meta("visual_state",visual_state)
	set_meta("animation_state",animation_state)
