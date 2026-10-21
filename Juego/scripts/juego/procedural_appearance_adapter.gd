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
			if mesh.mesh is SphereMesh:
				mesh.visible = profile.hair != 2
				if profile.hair == 1:
					mesh.scale.y *= 1.6
					mesh.scale.z *= 1.12
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
		mesh.material_override = body._mat(color,float(part.roughness))
	var cloth := Color(Profile.COLORS[profile.clothes])
	if profile.top == 1 or profile.outfit in [2,4,5,6]:
		extras.append(body._ball(body.chest,0.16,Vector3(0,0.27,0.04),cloth,Vector3(1,0.55,0.8)))
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
				extras.append(body._box(body.head_pivot,Vector3(0.055,0.033,0.012),Vector3(side*0.035,0.11,-0.102),Color("253747")))
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
		for side in [-1,1]:
			_piece(body._cyl(body.chest,0.07,0.08,0.31,Vector3(side*0.1,0.06,0),cloth.darkened(0.15),Vector3(1,1,1.7)),"TOP")
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
