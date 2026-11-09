extends "res://scripts/juego/human_student_6_2.gd"
## Shared CC0 source; one authored rig, independent Skeleton3D poses per actor.
var wardrobe="clothing_tshirt"
var hairstyle="hair_short02"
var identity=""
var traits: Dictionary={}
static var meshes: Dictionary={}
static var materials: Dictionary={}
func asset_dir() -> String: return "res://assets/characters/shared_6_3/"
func asset_files() -> Array:
	var files=[wardrobe,"clothing_jeans"]
	if wardrobe in ["clothing_jacket","clothing_trenchcoat"]: files.append("clothing_shirt")
	if not hairstyle.is_empty(): files.append(hairstyle)
	return files
func apply_profile(profile: Dictionary) -> void:
	super.apply_profile(profile)
	for key in pieces:
		for mesh in pieces[key]: mesh.show()
	for mesh in human.find_children("*","MeshInstance3D",true,false):
		if mesh==footwear63.mesh: continue
		for i in mesh.get_blend_shape_count(): mesh.set_blend_shape_value(i,0)
		for key in traits:
			var index=mesh.find_blend_shape_by_name(key)
			if index>=0: mesh.set_blend_shape_value(index,traits[key])
		# Bake the chosen face/body shape once, retaining skinning. NPCs do not need
		# dozens of live morph buffers; movement remains fully skeletal.
		var mesh_key=identity+":"+str(mesh.name)
		if meshes.has(mesh_key): mesh.mesh=meshes[mesh_key]
		else:
			var original: ArrayMesh=mesh.mesh
			var baked=mesh.bake_mesh_from_current_blend_shape_mix()
			var importer=ImporterMesh.new()
			for surface in baked.get_surface_count():
				var arrays=baked.surface_get_arrays(surface)
				var source=original.surface_get_arrays(surface)
				arrays[Mesh.ARRAY_BONES]=source[Mesh.ARRAY_BONES]
				arrays[Mesh.ARRAY_WEIGHTS]=source[Mesh.ARRAY_WEIGHTS]
				importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},original.surface_get_material(surface))
			importer.generate_lods(25.0,60.0,[])
			mesh.mesh=importer.get_mesh()
			meshes[mesh_key]=mesh.mesh
		mesh.lod_bias=0.35
		for surface in mesh.mesh.get_surface_count():
			var mat=mesh.get_active_material(surface)
			if not mat is StandardMaterial3D: continue
			# Preserve atlas/normal textures, fabric wrinkles and face details.
			if str(mesh.name).begins_with("Cloth_") and not str(mesh.name).begins_with("Cloth_jeans"):
				mat.albedo_color=Color(preload("res://scripts/juego/character_appearance.gd").COLORS[profile.clothes])
				mat.roughness=0.94
			if str(mesh.name).begins_with("Cloth_jeans") and int(profile.get("bottom_style",0)) in [2,3]:
				mat.albedo_texture=null
				mat.albedo_color=Color(preload("res://scripts/juego/character_appearance.gd").COLORS[profile.pants])
				mat.roughness_texture=preload("res://scripts/juego/character_surface_6.gd").fabric()
			var texture_id=mat.albedo_texture.get_instance_id() if mat.albedo_texture else 0
			var normal_id=mat.normal_texture.get_instance_id() if mat.normal_texture else 0
			var key="%s:%s:%s:%s:%s:%s"%[texture_id,normal_id,mat.albedo_color.to_html(),mat.roughness,mat.transparency,mat.cull_mode]
			if not materials.has(key): materials[key]=mat.duplicate()
			mesh.set_surface_override_material(surface,materials[key])
	standardize_height()

var pose_names: Array[String]=[]
var pose_parents: Array[int]=[]
var pose_rests: Array[Transform3D]=[]
var inverse_rests: Array[Transform3D]=[]
func initialize(owner_visual: Node3D) -> bool:
	if not super.initialize(owner_visual): return false
	for bone in rig.get_bone_count():
		pose_names.append(rig.get_bone_name(bone))
		pose_parents.append(rig.get_bone_parent(bone))
		pose_rests.append(rig.get_bone_rest(bone))
		inverse_rests.append(rig.get_bone_rest(bone).affine_inverse())
	return true

func update_pose(delta: float) -> void:
	if not active: return
	clock+=delta
	var poses: Array[Transform3D]=[]
	var rig_inverse=rig.global_basis.inverse()
	var to_rig=rig.global_transform.affine_inverse()
	for i in pose_names.size():
		var parent=pose_parents[i]
		var pose: Transform3D=pose_rests[i] if parent<0 else poses[parent]*pose_rests[i]
		var label=pose_names[i]
		if label=="pelvis":
			pose.origin=to_rig*host.hips.global_position
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
				direction=(rig_inverse*joint.global_basis*Vector3.FORWARD).normalized()
				pose.basis=Basis(Quaternion(original,direction))*rests[i].basis
			else:
				direction=(rig_inverse*joint.global_basis*Vector3.DOWN).normalized()
				pose.basis=Basis(Quaternion(rests[i].basis.y.normalized(),direction))*rests[i].basis
		elif label in ["spine_01","spine_02","spine_03","neck_01","head"]:
			if label=="spine_01": pose.origin.y+=(host.spine.position.y-0.05)/scale.y
			var joint: Node3D=host.head_pivot if label=="head" else host.chest if label in ["spine_03","neck_01"] else host.spine
			var direction=(rig_inverse*joint.global_basis*Vector3.UP).normalized()
			pose.basis=Basis(Quaternion(Vector3.UP,direction))*rests[i].basis
		elif label.begins_with("index_") or label.begins_with("middle_") or label.begins_with("ring_") or label.begins_with("pinky_"):
			pose.basis=pose.basis*Basis(Vector3.RIGHT,0.8 if host.armed or host.is_punching() else 0.22 if host.visual_speed>3.2 else 0.08)
		poses.append(pose)
	if not host.get_meta("npc63_distant",false): footwear63.resolve_contact(poses,delta)
	# Apply local poses in hierarchy order, then flush once. Global overrides
	# force repeated hierarchy updates in the Compatibility renderer.
	for i in poses.size():
		var local=poses[i] if pose_parents[i]<0 else poses[pose_parents[i]].affine_inverse()*poses[i]
		rig.set_bone_pose(i,local)
	# Skeleton3D flushes the local pose changes once before rendering.
	var hand=poses[rig.find_bone("hand_r")]
	var grip=rig.global_transform*(hand.origin+hand.basis.y*0.065)
	for socket in socket_defaults:
		socket.global_transform=Transform3D(host.hand_r.global_basis,grip)
