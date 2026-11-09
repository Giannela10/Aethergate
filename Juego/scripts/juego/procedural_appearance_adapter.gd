class_name ProceduralAppearanceAdapter
extends RefCounted
## Solo modifica mallas del rig; nunca colisiones, sockets, armas ni animación.
const Profile = preload("res://scripts/juego/character_appearance.gd")
var body: Node3D
var parts: Array[Dictionary] = []
var extras: Array[Node3D] = []
var source_skin := Color("e0ac86")

func _init(model: Node3D) -> void:
	body = model
	source_skin = model.skin_color
	_capture(model)

func _capture(node: Node) -> void:
	if node.name in ["WeaponSocket","ItemSocket","ImportedModel"]:
		return
	if node is MeshInstance3D and node.material_override is StandardMaterial3D:
		var material: StandardMaterial3D = node.material_override
		parts.append({"mesh":node,"color":material.albedo_color,"scale":node.scale,"roughness":material.roughness})
	for child in node.get_children():
		_capture(child)

func apply_appearance(profile: Dictionary) -> void:
	for extra in extras:
		if is_instance_valid(extra):
			extra.get_parent().remove_child(extra)
			extra.queue_free()
	extras.clear()
	for part in parts:
		var mesh: MeshInstance3D = part.mesh
		var original: Color = part.color
		var color := original
		mesh.visible = true
		mesh.scale = part.scale
		if original.is_equal_approx(source_skin):
			color = Color(Profile.SKIN[profile.skin])
		elif original.is_equal_approx(source_skin.darkened(0.06)):
			color = Color(Profile.SKIN[profile.skin]).darkened(0.06)
		elif original.is_equal_approx(Color("315e78")):
			color = Color(Profile.COLORS[profile.clothes])
		elif original.is_equal_approx(Color("28394a")):
			color = Color(Profile.COLORS[profile.pants])
		elif original.is_equal_approx(Color("2a2d33")):
			color = Color(Profile.COLORS[profile.shoes])
		elif original.is_equal_approx(Color("332a25")):
			color = Color(Profile.HAIR[profile.hair_color])
			if mesh.mesh is SphereMesh or str(mesh.name)=="HairCap6":
				mesh.visible = profile.hair != 2
				if str(mesh.name)=="HairCap6":
					mesh.scale *= [Vector3.ONE,Vector3(1.08,0.97,1),Vector3(0.95,1.02,1),Vector3(1.04,1,1.03)][clampi(int(profile.get("face",0)),0,3)]
				elif profile.hair == 1:
					mesh.scale.y *= 1.05
					mesh.scale.z *= 1.04
				elif profile.hair == 3:
					mesh.scale.x *= 0.85
				elif profile.hair == 4:
					mesh.scale *= Vector3(1.06,1.3,1.12)
				elif profile.hair == 5:
					mesh.scale *= Vector3(1.15,1.35,1.13)
		if body.backpack_socket.is_ancestor_of(mesh):
			mesh.visible = profile.backpack != 0
			if original.is_equal_approx(Color("bb874e")):
				color = Color(Profile.COLORS[profile.get("backpack_color",4)])
				if profile.backpack == 2: color = color.lightened(0.1)
			elif original.is_equal_approx(Color("926437")):
				color = Color(Profile.COLORS[profile.get("backpack_color",4)]).darkened(0.14)
		var rough: float = float(part.roughness)
		if original.is_equal_approx(source_skin) or original.is_equal_approx(source_skin.darkened(0.06)): rough = 0.82
		if profile.top==6 and (body.hand_l.is_ancestor_of(mesh) or body.hand_r.is_ancestor_of(mesh)):
			color=Color("b89452")
			rough=0.9
		if original.is_equal_approx(Color("315e78")): rough = 0.94 if profile.top == 3 else 0.87
		if original.is_equal_approx(Color("28394a")): rough = 0.88 if profile.get("bottom_style",0) == 1 else 0.8
		if original.is_equal_approx(Color("2a2d33")): rough = 0.62 if profile.get("shoe_style",0) == 1 else 0.78
		if str(mesh.name) == "FaceContour6":
			mesh.scale *= [Vector3.ONE,Vector3(1.08,0.97,1),Vector3(0.95,1.02,1),Vector3(1.04,1,1.03)][clampi(int(profile.get("face",0)),0,3)]
		mesh.material_override = body._mat(color,rough)
		if original.is_equal_approx(Color("315e78")) or original.is_equal_approx(Color("28394a")):
			mesh.material_override.roughness_texture=body.Surface6.fabric()
	var cloth := Color(Profile.COLORS[profile.clothes])
	if profile.top == 1 or profile.outfit in [2,4,5,6]:
		_piece(body._ball(body.chest,0.13,Vector3(0,0.25,0.09),cloth,Vector3(0.95,0.45,0.65)),"TOP")
	if profile.outfit == 1:
		extras.append(body._box(body.chest,Vector3(0.28,0.42,0.025),Vector3(0,-0.04,-0.16),Color("ede3ce")))
	elif profile.outfit == 2:
		extras.append(body._box(body.chest,Vector3(0.12,0.10,0.02),Vector3(0,0.1,-0.17),Color("d8c07b")))
	elif profile.outfit == 3:
		extras.append(body._box(body.chest,Vector3(0.37,0.30,0.24),Vector3(0,0.1,0),Color("4c5962")))
	elif profile.outfit == 4:
		extras.append(body._box(body.chest,Vector3(0.1,0.12,0.025),Vector3(0,0.1,-0.17),Color("ffd461")))
	elif profile.outfit in [5,6]:
		# Cosmetic only; use the selected clothes as the jacket base.
		extras.append(body._box(body.chest,Vector3(0.28,0.015,0.012),Vector3(0,0.16,-0.17),Color("45e5dc")))
		extras.append(body._box(body.chest,Vector3(0.015,0.25,0.012),Vector3(-0.10,0.05,-0.17),Color("45e5dc")))
	elif profile.outfit == 7:
		extras.append(body._box(body.chest,Vector3(0.12,0.15,0.012),Vector3(0,0.1,-0.17),Color("f4e8cc")))
	match profile.accessory:
		1:
			for side in [-1,1]:
				for y in [0.100,0.122]:
					_piece(body._box(body.head_pivot,Vector3(0.043,0.003,0.004),Vector3(side*0.035,y,-0.091),Color("253747")),"ACCESSORY")
				for x in [-0.021,0.021]:
					_piece(body._box(body.head_pivot,Vector3(0.003,0.023,0.004),Vector3(side*0.035+x,0.111,-0.091),Color("253747")),"ACCESSORY")
			_piece(body._box(body.head_pivot,Vector3(0.027,0.003,0.004),Vector3(0,0.114,-0.091),Color("253747")),"ACCESSORY")
		2:
			extras.append(body._box(body.head_pivot,Vector3(0.035,0.06,0.07),Vector3(0.105,0.08,0),Color("41cbdd")))
		3:
			for hand in [body.hand_l,body.hand_r]:
				extras.append(body._ball(hand,0.06,Vector3.ZERO,Color("b89452"),Vector3(0.8,1,0.7)))
		4:
			extras.append(body._ball(body.head_pivot,0.125,Vector3(0,0.18,0),Color("edbb30"),Vector3(1,0.65,1)))
		5:
			extras.append(body._box(body.chest,Vector3(0.08,0.10,0.02),Vector3(0.08,0.02,-0.17),Color("ffd461")))
		6:
			_piece(body._box(body.chest,Vector3(0.065,0.08,0.016),Vector3(-0.085,0.1,-0.17),Color("c7b477")),"ACCESSORY")
		7:
			_piece(body._ball(body.hips,0.14,Vector3(-0.17,-0.07,0.08),cloth.darkened(0.15),Vector3(0.5,1.15,0.9)),"ACCESSORY")
		8:
			_piece(body._box(body.chest,Vector3(0.07,0.11,0.016),Vector3(0.08,0.02,-0.18),Color("5eacb8")),"ACCESSORY")
	_modular_clothing(profile,cloth)
	_finish_clothing6(profile,cloth)
	_batch_extras6()
	body.lod_meshes.clear()
	body._capture_modules()

func _piece(mesh: MeshInstance3D, slot: String) -> void:
	mesh.set_meta("visual_module",slot)
	mesh.name = "Clothing"+slot
	extras.append(mesh)

func _modular_clothing(profile: Dictionary, cloth: Color) -> void:
	var top: int = profile.top
	if top >= 1:
		for shoulder in [body.shoulder_l,body.shoulder_r]:
			_piece(body._cyl(shoulder,0.054,0.044,0.28,Vector3(0,-0.14,0),cloth),"TOP")
		for elbow in [body.elbow_l,body.elbow_r]:
			_piece(body._cyl(elbow,0.041,0.034,0.22,Vector3(0,-0.11,0),cloth),"TOP")
	if top in [2,3,4]:
		for side in [-1,1]:
			var lapel: MeshInstance3D = body._box(body.chest,Vector3(0.052,0.12,0.016),Vector3(side*0.045,0.21,-0.14),cloth.lightened(0.15))
			lapel.rotation.z = side*0.28
			_piece(lapel,"TOP")
		_piece(body._box(body.chest,Vector3(0.012,0.29,0.012),Vector3(0,0.075,-0.15),Color("d4d7d9")),"TOP")
	if top == 4:
		_piece(body._node(body.chest,body.Surface6.contour("jacket6",[Vector2(-0.04,0),Vector2(-0.03,0.14),Vector2(0.10,0.16),Vector2(0.23,0.18),Vector2(0.275,0.12),Vector2(0.29,0)],0.79),Vector3.ZERO,cloth,Vector3.ONE,0.86),"TOP")
	if top == 5:
		_piece(body._box(body.chest,Vector3(0.08,0.07,0.015),Vector3(0.09,0.1,-0.15),cloth.lightened(0.12)),"TOP")
	if top == 6:
		for side in [-1,1]:
			_piece(body._box(body.chest,Vector3(0.035,0.34,0.018),Vector3(side*0.10,0.1,-0.15),cloth.darkened(0.2)),"TOP")
		_piece(body._box(body.chest,Vector3(0.14,0.12,0.02),Vector3(0,-0.01,-0.16),cloth.lightened(0.13)),"TOP")
	if profile.get("bottom_style",0) in [1,2,3]:
		for hip in [body.hip_l,body.hip_r]:
			_piece(body._box(hip,Vector3(0.008,0.35,0.012),Vector3(0.06,-0.18,-0.025),Color(Profile.COLORS[profile.pants]).lightened(0.12)),"BOTTOM")
	if profile.get("shoe_style",0) > 0:
		for ankle in [body.ankle_l,body.ankle_r]:
			_piece(body._cyl(ankle,0.046,0.052,0.15 if profile.shoe_style == 2 else 0.07,Vector3(0,0.025,0),Color(Profile.COLORS[profile.shoes])),"SHOES")
	if profile.get("head_accessory",0) == 1:
		for side in [-1,1]:
			_piece(body._ball(body.head_pivot,0.033,Vector3(side*0.105,0.1,0),Color("34495b"),Vector3(0.45,1.2,1)),"HEAD_ACCESSORY")
		_piece(body._box(body.head_pivot,Vector3(0.21,0.018,0.025),Vector3(0,0.22,0),Color("34495b")),"HEAD_ACCESSORY")
	if profile.hair == 5:
		for index in 5:
			var angle := float(index)*TAU/5
			_piece(body._ball(body.head_pivot,0.035,Vector3(sin(angle)*0.07,0.19,cos(angle)*0.06),Color(Profile.HAIR[profile.hair_color])),"HAIR")

func _finish_clothing6(profile: Dictionary, cloth: Color) -> void:
	var top: int = profile.top
	var trim := cloth.darkened(0.22)
	# Hems, pockets and cuffs follow existing articulated pivots.
	_piece(body._cyl(body.spine,0.137,0.137,0.018,Vector3(0,0.025,0),trim,Vector3(1,1,0.78)),"TOP")
	for side in [-1.0,1.0]:
		if top in [2,4,5,6]:
			_piece(body._box(body.chest,Vector3(0.061,0.052,0.006),Vector3(side*0.088,0.115,-0.13),cloth.lightened(0.05)),"TOP")
		if top>0:
			var elbow: Node3D = body.elbow_l if side<0 else body.elbow_r
			_piece(body._cyl(elbow,0.036,0.036,0.025,Vector3(0,-0.215,0),trim),"TOP")
		if profile.backpack>0:
			# Straps now exist only when a backpack is equipped.
			var strap: MeshInstance3D = body._box(body.chest,Vector3(0.024,0.32,0.015),Vector3(side*0.123,0.115,-0.132),Color(Profile.COLORS[profile.get("backpack_color",0)]).darkened(0.22))
			strap.rotation.z = side*0.08
			_piece(strap,"BACKPACK")
		var ankle: Node3D = body.ankle_l if side<0 else body.ankle_r
		if profile.get("shoe_style",0)==0:
			for i in 3:
				_piece(body._box(ankle,Vector3(0.065,0.004,0.008),Vector3(0,-0.019,-0.07-i*0.019),Color("d8dbdc")),"SHOES")
	if top in [2,4]:
		for i in 4:
			_piece(body._ball(body.chest,0.004,Vector3(0,0.03+i*0.045,-0.14),Color("bac0c5")),"TOP")
	if top==1:
		for side in [-1,1]:
			_piece(body._box(body.chest,Vector3(0.003,0.10,0.004),Vector3(side*0.035,0.18,-0.14),cloth.lightened(0.3)),"TOP")
	if profile.get("bottom_style",0)==4:
		for hip in [body.hip_l,body.hip_r]:
			_piece(body._box(hip,Vector3(0.009,0.38,0.009),Vector3(0.075,-0.20,0),Color("bfc6cf")),"BOTTOM")
	if profile.get("head_accessory",0)==2:
		_piece(body._ball(body.head_pivot,0.105,Vector3(0,0.163,0.01),cloth,Vector3(0.96,0.62,0.93)),"HEAD_ACCESSORY")
	if profile.outfit==1:
		_piece(body._cyl(body.head_pivot,0.102,0.102,0.04,Vector3(0,0.19,0),Color("eee9dc"),Vector3(1,1,0.95)),"HEAD_ACCESSORY")
		_piece(body._ball(body.head_pivot,0.11,Vector3(0,0.235,0),Color("eee9dc"),Vector3(1,0.65,0.95)),"HEAD_ACCESSORY")
	if profile.hair==1:
		_piece(body._ball(body.head_pivot,0.085,Vector3(0,0.05,0.057),Color(Profile.HAIR[profile.hair_color]),Vector3(0.95,1.5,0.58)),"HAIR")
	elif profile.hair in [3,4]:
		for side in [-1,1]:
			_piece(body._ball(body.head_pivot,0.024,Vector3(side*0.083,0.142,0.005),Color(Profile.HAIR[profile.hair_color]),Vector3(0.48,1.4 if profile.hair==4 else 0.8,1.5)),"HAIR")

func _batch_extras6() -> void:
	# One draw surface per parent/material/module; no merging across animated joints.
	var groups := {}
	for mesh in extras:
		if not is_instance_valid(mesh) or not mesh is MeshInstance3D: continue
		var key := str(mesh.get_parent().get_instance_id())+":"+str(mesh.material_override.get_instance_id())+":"+str(mesh.get_meta("visual_module","ACCESSORY"))
		if not groups.has(key): groups[key]=[]
		groups[key].append(mesh)
	var combined: Array[Node3D] = []
	for group in groups.values():
		if group.size()<2:
			combined.append(group[0])
			continue
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mesh in group: tool.append_from(mesh.mesh,0,mesh.transform)
		var merged := MeshInstance3D.new()
		merged.name="Wardrobe6"
		merged.mesh=tool.commit()
		merged.material_override=group[0].material_override
		merged.set_meta("visual_module",group[0].get_meta("visual_module","ACCESSORY"))
		group[0].get_parent().add_child(merged)
		combined.append(merged)
		for mesh in group:
			mesh.get_parent().remove_child(mesh)
			mesh.free()
	extras=combined
