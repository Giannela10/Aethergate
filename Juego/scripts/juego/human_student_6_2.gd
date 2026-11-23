extends Node3D
## CC0 skinned data only. Poses are driven by the established player visual rig.
const DIR="res://assets/characters/shared_6_3/"
const HAIRSTYLES := ["hair_short02","hair_long01","","hair_short04","hair_bob01","hair_afro01","hair_ponytail01","hair_braid01"]
const PLAYER_TOPS := ["clothing_tshirt","clothing_hoodie","clothing_shirt","clothing_hoodie","clothing_jacket","clothing_shirt","clothing_jacket"]
const OUTFIT_TOPS := ["","clothing_tshirt","clothing_hoodie","clothing_jacket","clothing_hoodie","clothing_jacket","clothing_jacket","clothing_tshirt"]
const MOTION_BONES := ["spine_02","spine_03","neck_01","head"]
const REFERENCE_FACE := {
	"face_jaw_width_incr":0.27,
	"face_chin_incr":0.13,
	"face_cheekbones_incr":0.31,
	"face_nose_width_decr":0.23,
	"face_nose_length_incr":0.17,
	"face_eye_size_decr":0.14,
	"face_eye_tilt_incr":0.11,
	"face_lips_incr":0.12,
	"face_mouth_width_incr":0.09
}
static var motion_library: AnimationLibrary
var host: Node3D
var rig: Skeleton3D
var human: Node3D
var pieces: Dictionary={}
var rests: Array[Transform3D]=[]
var garment_materials: Dictionary={}
var blink_channels: Array[Dictionary] = []
var bone_map: Dictionary={}
var clock:=0.0
var active:=true
var socket_defaults: Dictionary={}
var footwear63: RefCounted
var player_retarget := false
var motion_tree: AnimationTree
var motion_playback: AnimationNodeStateMachinePlayback
var motion_state := ""
var motion_weight := 0.0

func asset_dir() -> String: return DIR
func asset_files() -> Array:
	var files := ["clothing_hoodie","clothing_tshirt","clothing_shirt","clothing_jacket","clothing_jeans","clothing_shoes"]
	for style in HAIRSTYLES:
		if not style.is_empty(): files.append(style)
	return files

func initialize(owner_visual: Node3D) -> bool:
	host=owner_visual
	player_retarget=host.get_script().resource_path.contains("main_character_visual")
	name="ImportedModel"
	rotation.y=PI
	scale=Vector3.ONE*1.07
	var body_scene=load(asset_dir()+"native/base_body_anim.scn") as PackedScene
	if body_scene==null: return false
	human=body_scene.instantiate()
	add_child(human)
	rig=human.find_children("*","Skeleton3D",true,false)[0]
	for player in human.find_children("*","AnimationPlayer",true,false): player.stop()
	if player_retarget:
		_setup_motion()
	for file in asset_files():
		var part_scene=load(asset_dir()+"native/"+file+".scn") as PackedScene
		if part_scene==null: return false
		var source=part_scene.instantiate()
		add_child(source)
		var meshes: Array=[]
		for mesh in source.find_children("*","MeshInstance3D",true,false):
			mesh.reparent(human,true)
			mesh.skeleton=mesh.get_path_to(rig)
			meshes.append(mesh)
		pieces[file]=meshes
		source.free()
	footwear63=preload("res://scripts/juego/character_footwear_6_3.gd").new()
	footwear63.install(self)
	for mesh in human.find_children("*","MeshInstance3D",true,false):
		for i in mesh.get_blend_shape_count(): mesh.set_blend_shape_value(i,0)
		if player_retarget:
			for channel in ["blink_left","blink_right"]:
				var index: int = mesh.find_blend_shape_by_name(channel)
				if index >= 0: blink_channels.append({"mesh":mesh,"index":index})
		for surface in mesh.mesh.get_surface_count():
			var original=mesh.get_active_material(surface)
			if original is StandardMaterial3D:
				var mat=original.duplicate() as StandardMaterial3D
				mat.metallic_specular=0.25
				mesh.set_surface_override_material(surface,mat)
				garment_materials[str(mesh.get_instance_id())+":"+str(surface)]={"mesh":mesh,"surface":surface,"material":mat,"original":mat.albedo_color}
	for i in rig.get_bone_count(): rests.append(rig.get_bone_global_rest(i))
	bone_map={"upperarm_l":host.shoulder_l,"lowerarm_l":host.elbow_l,"hand_l":host.hand_l,"upperarm_r":host.shoulder_r,"lowerarm_r":host.elbow_r,"hand_r":host.hand_r,"thigh_l":host.hip_l,"calf_l":host.knee_l,"foot_l":host.ankle_l,"thigh_r":host.hip_r,"calf_r":host.knee_r,"foot_r":host.ankle_r}
	# Preserve the actual socket objects and all external references.
	for socket in [host.get("weapon_socket"),host.get("item_socket")]:
		if not is_instance_valid(socket): continue
		socket_defaults[socket]={"parent":socket.get_parent(),"transform":socket.transform}
		socket.reparent(self,false)
	return true

func _setup_motion() -> void:
	var players := human.find_children("*","AnimationPlayer",true,false)
	if players.is_empty(): return
	var source := players[0] as AnimationPlayer
	var clips := {"Locomotion":"idle_breathe","Jump":"jump","Fall":"fall","Land":"land"}
	if motion_library == null:
		var library := AnimationLibrary.new()
		for clip in ["idle_breathe","walk","run","jump","fall","land"]:
			if not source.has_animation(clip): return
			var animation := source.get_animation(clip).duplicate() as Animation
			for index in range(animation.get_track_count()-1,-1,-1):
				var track := animation.track_get_path(index)
				if animation.track_get_type(index) != Animation.TYPE_ROTATION_3D or not str(track.get_concatenated_subnames()) in MOTION_BONES:
					animation.remove_track(index)
			library.add_animation(clip,animation)
		motion_library = library
	var driver := AnimationPlayer.new()
	add_child(driver)
	var target := source.get_node(source.root_node)
	driver.root_node = driver.get_path_to(target)
	driver.add_animation_library("",motion_library)
	var machine := AnimationNodeStateMachine.new()
	var gait := AnimationNodeBlendSpace1D.new()
	gait.min_space = 0.0
	gait.max_space = 7.0
	for entry in [[0.0,"idle_breathe"],[2.5,"walk"],[5.5,"run"]]:
		var node := AnimationNodeAnimation.new()
		node.animation = entry[1]
		gait.add_blend_point(node,entry[0],-1,entry[1])
	machine.add_node("Locomotion",gait)
	for state in ["Jump","Fall","Land"]:
		var node := AnimationNodeAnimation.new()
		node.animation = clips[state]
		machine.add_node(state,node)
	for from in clips:
		for to in clips:
			if from == to: continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.15
			machine.add_transition(from,to,transition)
	motion_tree = AnimationTree.new()
	motion_tree.tree_root = machine
	motion_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(motion_tree)
	motion_tree.anim_player = motion_tree.get_path_to(driver)
	motion_tree.root_node = motion_tree.get_path_to(target)
	motion_tree.active = true
	motion_playback = motion_tree.get("parameters/playback")

func _advance_motion(delta: float) -> void:
	if motion_tree == null: return
	var state := String(host.get("visual_state"))
	var next: String = {"JUMP":"Jump","FALL":"Fall","LAND":"Land"}.get(state,"Locomotion")
	if motion_state.is_empty():
		motion_playback.start(next)
	elif next != motion_state:
		motion_playback.travel(next)
	motion_state = next
	motion_tree.set("parameters/Locomotion/blend_position",clampf(host.visual_speed,0.0,7.0))
	motion_tree.advance(delta)
	var weight := 0.22 if state in ["IDLE","WALK","RUN","JUMP","FALL","LAND"] else 0.0
	motion_weight = move_toward(motion_weight,weight,delta * 2.0)

func set_active(value: bool) -> void:
	if not value: host.reset_visual_height_reference()
	active=value
	visible=value
	for socket in socket_defaults:
		var original: Dictionary=socket_defaults[socket]
		var target: Node3D=self if value else original.parent
		if socket.get_parent()!=target: socket.reparent(target,false)
		if not value: socket.transform=original.transform

func apply_profile(profile: Dictionary) -> void:
	var hair_style=int(profile.hair)
	var female := player_retarget and int(profile.get("body_type",0)) == 1
	var top: String = PLAYER_TOPS[int(profile.top)]
	if player_retarget and int(profile.outfit) > 0:
		top = OUTFIT_TOPS[int(profile.outfit)]
	for key in pieces:
		var enabled=true
		if player_retarget and key in PLAYER_TOPS:
			enabled = key == top or (top == "clothing_jacket" and key == "clothing_shirt")
		elif key=="clothing_hoodie": enabled=int(profile.top)!=0
		elif key=="clothing_tshirt": enabled=int(profile.top)==0
		elif key.begins_with("hair_"):
			enabled=key==HAIRSTYLES[hair_style]
		for mesh in pieces[key]: mesh.visible=enabled
	var Profile=preload("res://scripts/juego/character_appearance.gd")
	for row in garment_materials.values():
		var mesh: MeshInstance3D=row.mesh
		var mat: StandardMaterial3D=row.material
		var label=mat.resource_name
		if str(mesh.name).begins_with("Cloth_hoodie") or str(mesh.name).begins_with("Cloth_tshirt") or (player_retarget and (mesh in pieces.get("clothing_shirt",[]) or mesh in pieces.get("clothing_jacket",[]))):
			mat.albedo_color=Color("344661") if int(profile.clothes)==0 else Color(Profile.COLORS[profile.clothes])
			mat.roughness=0.94
			if player_retarget and mesh in pieces.get("clothing_hoodie",[]):
				mat.roughness_texture = preload("res://scripts/juego/character_surface_6.gd").fabric()
		elif str(mesh.name).begins_with("Cloth_jeans"):
			mat.albedo_color=row.original if int(profile.pants)==0 else Color(Profile.COLORS[profile.pants])
			mat.roughness=0.92
		elif str(mesh.name).begins_with("Cloth_shoes"):
			var shoe=ShaderMaterial.new()
			shoe.shader=preload("res://scripts/juego/shoe_material_6_2.gdshader")
			shoe.set_shader_parameter("source_texture",mat.albedo_texture)
			shoe.set_shader_parameter("normal_texture",mat.normal_texture)
			shoe.set_shader_parameter("use_normal",mat.normal_enabled and mat.normal_texture!=null)
			shoe.set_shader_parameter("tone",Color.WHITE if int(profile.shoes)==6 else Color(Profile.COLORS[profile.shoes]))
			mesh.set_surface_override_material(row.surface,shoe)
		elif str(mesh.name).begins_with("Hair") or label in ["Eyebrow","Eyelash"]:
			mat.albedo_color=Color(Profile.HAIR[profile.hair_color])
			mat.roughness=0.72
		elif label=="Skin":
			mat.albedo_color=Color(Profile.SKIN[profile.skin]).lightened(0.10)
			mat.roughness=0.72
	var face := int(profile.get("face",0))
	var weights := {}
	for channel in REFERENCE_FACE:
		weights[channel] = REFERENCE_FACE[channel] if face == 4 else 0.0
	if face != 4:
		weights.merge({
			"face_jaw_width_incr":0.18 if face == 3 else 0.0,
			"face_cheekbones_incr":0.15 if face == 0 else 0.0,
			"face_chin_incr":0.10 if face == 2 else 0.0
		},true)
	weights["face_jaw_width_decr"] = 0.12 if face == 2 else 0.0
	weights["gender_male"] = 0.0 if female else 0.65
	weights["gender_female"] = 0.65 if female else 0.0
	for mesh in human.find_children("*","MeshInstance3D",true,false):
		for channel in weights:
			var index: int = mesh.find_blend_shape_by_name(channel)
			if index >= 0: mesh.set_blend_shape_value(index,weights[channel])
	footwear63.apply_profile(profile)
	standardize_height()

func standardize_height() -> void:
	# Calibrate from the neutral morph geometry, never from a crouch/attack pose.
	var body_mesh := human.find_child("Body",true,false) as MeshInstance3D
	if body_mesh == null: return
	var neutral := body_mesh.bake_mesh_from_current_blend_shape_mix()
	var crown := neutral.get_aabb().end.y
	var sole: float = footwear63.mesh.mesh.get_aabb().position.y
	host.set_visual_height_reference(crown-sole,scale.y)

func head_pose_basis(rest: Basis) -> Basis:
	var rig_inverse := rig.global_basis.orthonormalized().inverse()
	var neutral := rig_inverse * host.global_basis.orthonormalized()
	var current: Basis = rig_inverse * host.head_pivot.global_basis.orthonormalized()
	return current * neutral.inverse() * rest

func update_pose(delta: float) -> void:
	if not active: return
	_advance_motion(delta)
	clock+=delta
	var poses: Array[Transform3D]=[]
	for i in rig.get_bone_count():
		var parent=rig.get_bone_parent(i)
		var pose: Transform3D=rig.get_bone_rest(i) if parent<0 else poses[parent]*rig.get_bone_rest(i)
		var label=rig.get_bone_name(i)
		if label=="pelvis":
			pose.origin=rig.to_local(host.hips.global_position)
			pose.basis=Basis(Vector3.UP,host.hips.rotation.y)*rests[i].basis
		elif bone_map.has(label):
			var joint: Node3D=bone_map[label]
			var direction: Vector3
			if label.begins_with("foot_"):
				var ball=rig.find_bone("ball_"+label.right(1))
				var original=(rests[ball].origin-rests[i].origin).normalized()
				# The ankle-to-toe segment slopes down in the bind pose. Only its
				# horizontal heading is a forward reference; flattening the segment
				# itself pitches the entire sole upward.
				original.y=0
				original=original.normalized()
				direction=(rig.global_basis.inverse()*joint.global_basis*Vector3.FORWARD).normalized()
				pose.basis=Basis(Quaternion(original,direction))*rests[i].basis
			else:
				direction=(rig.global_basis.inverse()*joint.global_basis*Vector3.DOWN).normalized()
				if player_retarget:
					# Transfer a complete rotation from the procedural bind frame.
					# A fresh shortest-arc aim every frame loses limb roll and the
					# elbow/knee bend plane as the parent turns.
					var neutral_frame=rig.global_basis.orthonormalized().inverse()*host.global_basis.orthonormalized()
					var moving_frame=rig.global_basis.orthonormalized().inverse()*joint.global_basis.orthonormalized()
					var motion=moving_frame*neutral_frame.inverse()
					pose.basis=motion*Basis(Quaternion(rests[i].basis.y.normalized(),Vector3.DOWN))*rests[i].basis
				else:
					pose.basis=Basis(Quaternion(rests[i].basis.y.normalized(),direction))*rests[i].basis
		elif label in ["spine_01","spine_02","spine_03","neck_01","head"]:
			if label=="spine_01": pose.origin.y+=(host.spine.position.y-0.05)/scale.y
			var joint: Node3D=host.head_pivot if label=="head" else host.chest if label in ["spine_03","neck_01"] else host.spine
			var direction=(rig.global_basis.inverse()*joint.global_basis*Vector3.UP).normalized()
			pose.basis=Basis(Quaternion(Vector3.UP,direction))*rests[i].basis
			if label == "head": pose.basis = head_pose_basis(rests[i].basis)
			if motion_tree != null and motion_weight > 0.0 and label in MOTION_BONES:
				var rotation_delta := rig.get_bone_rest(i).basis.get_rotation_quaternion().inverse() * rig.get_bone_pose_rotation(i)
				if rotation_delta.w < 0.0: rotation_delta = -rotation_delta
				var contribution := minf(motion_weight,0.14 / maxf(rotation_delta.get_angle(),0.001))
				pose.basis *= Basis(Quaternion.IDENTITY.slerp(rotation_delta,contribution))
		elif label.begins_with("index_") or label.begins_with("middle_") or label.begins_with("ring_") or label.begins_with("pinky_"):
			pose.basis=pose.basis*Basis(Vector3.RIGHT,0.8 if host.armed or host.is_punching() else 0.22 if host.visual_speed>3.2 else 0.08)
		poses.append(pose)
	if not host.get_meta("npc63_distant",false): footwear63.resolve_contact(poses,delta)
	for i in poses.size(): rig.set_bone_global_pose_override(i,poses[i],1.0,true)
	var hand=poses[rig.find_bone("hand_r")]
	var grip=rig.global_transform*(hand.origin+hand.basis.y*0.065)
	for socket in socket_defaults:
		socket.global_transform=Transform3D(host.hand_r.global_basis,grip)
	var blink=maxf(0,1-absf(fmod(clock,4.6)-4.4)/0.1)
	for channel in blink_channels:
		channel.mesh.set_blend_shape_value(channel.index,blink)
