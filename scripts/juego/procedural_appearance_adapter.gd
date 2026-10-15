class_name ProceduralAppearanceAdapter
extends RefCounted
## Solo modifica mallas del rig; nunca colisiones, sockets, armas ni animación.
const Profile = preload("res://scripts/juego/character_appearance.gd")
var body: Node3D
var parts: Array[Dictionary] = []
var extras: Array[Node3D] = []

func _init(model: Node3D) -> void:
	body = model
	_capture(model)

func _capture(node: Node) -> void:
	if node.name in ["WeaponSocket","ItemSocket","ImportedModel"]:
		return
	if node is MeshInstance3D and node.material_override is StandardMaterial3D:
		var material: StandardMaterial3D = node.material_override.duplicate()
		node.material_override = material
		parts.append({"mesh":node,"color":material.albedo_color,"scale":node.scale})
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
		if original.is_equal_approx(Color("e0ac86")):
			color = Color(Profile.SKIN[profile.skin])
		elif original.is_equal_approx(Color("e0ac86").darkened(0.06)):
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
		if body.backpack_socket.is_ancestor_of(mesh):
			mesh.visible = profile.backpack != 0
			if profile.backpack == 2 and original.is_equal_approx(Color("bb874e")):
				color = Color("286f9b")
		mesh.material_override.albedo_color = color
	var cloth := Color(Profile.COLORS[profile.clothes])
	if profile.top == 1 or profile.outfit in [2,4]:
		extras.append(body._ball(body.chest,0.16,Vector3(0,0.27,0.04),cloth,Vector3(1,0.55,0.8)))
	if profile.outfit == 1:
		extras.append(body._box(body.chest,Vector3(0.28,0.42,0.025),Vector3(0,-0.04,-0.16),Color("ede3ce")))
	elif profile.outfit == 2:
		extras.append(body._box(body.chest,Vector3(0.12,0.10,0.02),Vector3(0,0.1,-0.17),Color("d8c07b")))
	elif profile.outfit == 3:
		extras.append(body._box(body.chest,Vector3(0.37,0.30,0.24),Vector3(0,0.1,0),Color("4c5962")))
	elif profile.outfit == 4:
		extras.append(body._box(body.chest,Vector3(0.1,0.12,0.025),Vector3(0,0.1,-0.17),Color("ffd461")))
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
