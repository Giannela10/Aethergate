@tool
extends Node3D
## Reconstrucción visual modular del subsuelo. Solo se ejecuta desde el editor bajo demanda.
const BASE_Y: float = -12.058385849
const FLOOR_SHADER: Shader = preload("res://materials/entrance/piso_menos1_hormigon.gdshader")
var scene_root: Node
var campus: Node3D
var m: Dictionary = {}

func _ready() -> void:
	set_process(false)
	set_physics_process(false)

func _own(parent: Node, node: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node)
	if scene_root != null:
		node.owner = scene_root
	return node

func _group(parent: Node, node_name: String) -> Node3D:
	return _own(parent, Node3D.new(), node_name) as Node3D

func _make_materials() -> void:
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = FLOOR_SHADER
	m["concrete"] = floor_mat
	m["wall"] = _mat(Color("656b6d"), 0.05, 0.82)
	m["beam"] = _mat(Color("4f5558"), 0.12, 0.88)
	m["steel"] = _mat(Color("343d42"), 0.72, 0.38)
	m["dark"] = _mat(Color("171d20"), 0.18, 0.55)
	m["glass"] = _mat(Color(0.30, 0.46, 0.49, 0.20), 0.12, 0.20)
	m["glass"].transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m["glass"].cull_mode = BaseMaterial3D.CULL_DISABLED
	m["blue"] = _mat(Color("1768a0"), 0.24, 0.36)
	m["blue_light"] = _mat(Color("258bc1"), 0.20, 0.34)
	m["yellow"] = _mat(Color("efb92f"), 0.10, 0.48)
	m["yellow_dark"] = _mat(Color("b97c1e"), 0.16, 0.52)
	m["red"] = _mat(Color("bd3d2f"), 0.16, 0.44)
	m["white"] = _mat(Color("d5dcda"), 0.08, 0.52)
	m["line"] = _mat(Color("e6b72f"), 0.05, 0.5)
	m["green"] = _mat(Color("277853"), 0.02, 0.62)
	m["wood"] = _mat(Color("805e3e"), 0.0, 0.72)
	m["warm"] = _mat(Color("f4b65f"), 0.0, 0.32)
	m["lamp"] = _mat(Color("e8f2eb"), 0.0, 0.28)
	m["lamp"].emission_enabled = true
	m["lamp"].emission = Color("e8f2eb")
	m["lamp"].emission_energy_multiplier = 1.65
	m["screen"] = _mat(Color("3ca5ad"), 0.0, 0.27)
	m["screen"].emission_enabled = true
	m["screen"].emission = Color("3ca5ad")
	m["screen"].emission_energy_multiplier = 0.8
	m["orange"] = _mat(Color("e47427"), 0.08, 0.46)
	m["locker_frame"] = _mat(Color("424b4e"), 0.58, 0.45)

func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metal
	result.roughness = rough
	return result

func _box(parent: Node3D, node_name: String, pos: Vector3, dims: Vector3, material: Material, solid := false, shadows := false) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dims
	mesh_node.mesh = mesh
	mesh_node.material_override = material
	mesh_node.position = pos
	mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_own(parent, mesh_node, node_name)
	if solid:
		var body := StaticBody3D.new()
		_own(mesh_node, body, "ColisionEstatica")
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dims
		collider.shape = shape
		_own(body, collider, "Forma")
	return mesh_node

func _cylinder(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, material: Material, axis := Vector3.UP) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh_node.mesh = mesh
	mesh_node.material_override = material
	mesh_node.position = pos
	mesh_node.quaternion = Quaternion(Vector3.UP, axis.normalized())
	mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_node.visibility_range_end = 150.0
	_own(parent, mesh_node, node_name)
	return mesh_node

func _label(parent: Node3D, node_name: String, text_value: String, pos: Vector3, font_size := 48, color := Color("e1e5df")) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.position = pos
	label.font_size = font_size
	label.pixel_size = 0.006
	label.modulate = color
	label.outline_size = 6
	label.outline_modulate = Color("151a1b")
	label.visibility_range_end = 90.0
	_own(parent, label, node_name)
	return label

func _multimesh(parent: Node3D, node_name: String, dims: Vector3, material: Material, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = dims
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = mm
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = 150.0
	_own(parent, instance, node_name)

func _lights(parent: Node3D) -> void:
	var positions: Array[Vector3] = []
	for z in [-145.0, -130.0, -114.0, -98.0, -84.0]:
		for x in [-65.0, -43.0, -20.0, 3.0, 26.0, 49.0, 71.0]:
			positions.append(Vector3(x, BASE_Y + 8.2, z))
	var transforms: Array[Transform3D] = []
	for p in positions:
		transforms.append(Transform3D(Basis.IDENTITY, p))
	_multimesh(parent, "ModulosLuminariaLineal", Vector3(4.2, 0.08, 0.26), m["lamp"], transforms)
	# Pocas luminarias locales, sin sombras dinámicas.
	var cafe := OmniLight3D.new()
	cafe.position = Vector3(-30.0, BASE_Y + 4.7, -131.0)
	cafe.light_color = Color("ffc77d")
	cafe.light_energy = 1.0
	cafe.omni_range = 9.0
	cafe.shadow_enabled = false
	_own(parent, cafe, "LuzCalidaNegocio")
	var ramp_light := OmniLight3D.new()
	ramp_light.position = Vector3(24.37, BASE_Y + 4.0, -158.0)
	ramp_light.light_color = Color("dce8e4")
	ramp_light.light_energy = 0.8
	ramp_light.omni_range = 12.0
	ramp_light.shadow_enabled = false
	_own(parent, ramp_light, "LuzTransicionRampa")

func _lockers(parent: Node3D, center: Vector3, count: int, yaw := 0.0, along_x := true, unit := 0.92) -> void:
	var frames: Array[Transform3D] = []
	var blue_doors: Array[Transform3D] = []
	var yellow_doors: Array[Transform3D] = []
	var handles: Array[Transform3D] = []
	var vents: Array[Transform3D] = []
	var half := float(count - 1) * unit * 0.5
	for i in count:
		var offset := float(i) * unit - half
		var local := Vector3(offset, 0.0, 0.0) if along_x else Vector3(0.0, 0.0, offset)
		var pos: Vector3 = center + Basis(Vector3.UP, yaw) * local
		var b := Basis(Vector3.UP, yaw)
		frames.append(Transform3D(b, pos + Vector3.UP * 1.12))
		var door_local := Vector3(offset, 1.12, 0.27) if along_x else Vector3(0.27, 1.12, offset)
		var handle_local := Vector3(offset + unit * 0.30, 1.12, 0.315) if along_x else Vector3(0.315, 1.12, offset + unit * 0.30)
		var vent_local := Vector3(offset, 1.68, 0.314) if along_x else Vector3(0.314, 1.68, offset)
		var t := Transform3D(b, center + b * door_local)
		if i % 3 == 1:
			yellow_doors.append(t)
		else:
			blue_doors.append(t)
		handles.append(Transform3D(b, center + b * handle_local))
		vents.append(Transform3D(b, center + b * vent_local))
	_multimesh(parent, "CuerpoModular", Vector3(0.88, 2.12, 0.52), m["locker_frame"], frames)
	_multimesh(parent, "PuertasAzules", Vector3(0.79, 1.82, 0.055), m["blue"], blue_doors)
	_multimesh(parent, "PuertasAmarillas", Vector3(0.79, 1.82, 0.055), m["yellow"], yellow_doors)
	_multimesh(parent, "Manillas", Vector3(0.035, 0.26, 0.045), m["steel"], handles)
	_multimesh(parent, "Rejillas", Vector3(0.38, 0.035, 0.025), m["dark"], vents)
	var body := StaticBody3D.new()
	body.position = center + Vector3.UP * 1.05
	body.rotation.y = yaw
	_own(parent, body, "ColisionFilaCasilleros")
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(count * unit, 2.1, 0.62) if along_x else Vector3(0.62, 2.1, count * unit)
	shape_node.shape = shape
	_own(body, shape_node, "Volumen")

func _ping_pong(parent: Node3D, center: Vector3, index: int) -> void:
	var table := _group(parent, "MesaPingPong%d" % index)
	_box(table, "TableroAzul", center + Vector3(0, 0.78, 0), Vector3(2.74, 0.055, 1.525), m["blue"], true)
	_box(table, "BandaPerimetral", center + Vector3(0, 0.744, 0), Vector3(2.78, 0.025, 1.57), m["white"])
	_box(table, "RedCentral", center + Vector3(0, 0.87, 0), Vector3(0.028, 0.16, 1.56), m["white"])
	for x in [-1.12, 1.12]:
		for z in [-0.56, 0.56]:
			_box(table, "Pata", center + Vector3(x, 0.37, z), Vector3(0.09, 0.74, 0.09), m["steel"])
	_box(table, "Travesano", center + Vector3(0, 0.34, 0), Vector3(2.35, 0.07, 0.08), m["steel"])

func _student_tables(parent: Node3D) -> void:
	for i in 4:
		var x := -14.0 + float(i % 2) * 12.0
		var z := -100.0 - float(i / 2) * 8.0
		var table := _group(parent, "MesaEstudiantes%d" % (i + 1))
		_box(table, "Cubierta", Vector3(x, BASE_Y + 0.78, z), Vector3(2.4, 0.12, 1.15), m["wall"], true)
		for dx in [-1.0, 1.0]:
			for dz in [-0.4, 0.4]:
				_box(table, "Pata", Vector3(x + dx, BASE_Y + 0.38, z + dz), Vector3(0.07, 0.76, 0.07), m["steel"])
		for seat in [-1.0, 1.0]:
			var cz: float = z + seat * 1.05
			_box(table, "Asiento", Vector3(x, BASE_Y + 0.48, cz), Vector3(0.72, 0.11, 0.72), m["blue_light"])
			_box(table, "SoporteSilla", Vector3(x, BASE_Y + 0.24, cz), Vector3(0.055, 0.48, 0.055), m["steel"])

func _central_area(parent: Node3D) -> void:
	var social := _group(parent, "AreaCentralEstudiantes")
	_ping_pong(social, Vector3(-7.0, BASE_Y, -108.0), 1)
	_ping_pong(social, Vector3(6.0, BASE_Y, -108.0), 2)
	_student_tables(social)
	_lockers(social, Vector3(-14.0, BASE_Y, -82.0), 14, PI, true, 0.92)
	_lockers(social, Vector3(1.0, BASE_Y, -82.0), 14, PI, true, 0.92)
	# Orientación discreta visible al salir del elevador y aproximarse al centro.
	var orientation_sign := _label(social, "OrientacionSubsuelo", "MECANICA  ←       AREA COMUN       →  CAFETERIA / SALAS", Vector3(0, BASE_Y + 3.4, -121.0), 45)
	orientation_sign.rotation.y = PI
	# Marcas de seguridad en la escalera central existente: visuales sobrepuestas, sin tocar colisión.
	var noses: Array[Transform3D] = []
	for i in 35:
		var x := -18.65 + float(i) * 0.90
		var y := BASE_Y + 0.13 + float(i) * 0.365
		noses.append(Transform3D(Basis.IDENTITY, Vector3(x, y, -132.833)))
	_multimesh(social, "NarizAmarillaEscaleraCentral", Vector3(0.055, 0.045, 9.55), m["line"], noses)

func _cafe(parent: Node3D) -> void:
	var shop := _group(parent, "NegocioCafeteria")
	var x := -31.0
	var z := -130.0
	_box(shop, "FondoGrafito", Vector3(x, BASE_Y + 2.0, z + 2.0), Vector3(9.0, 4.0, 0.28), m["dark"], true)
	_box(shop, "LateralIzquierdo", Vector3(x - 4.5, BASE_Y + 1.8, z), Vector3(0.22, 3.6, 4.0), m["dark"], true)
	_box(shop, "LateralDerecho", Vector3(x + 4.5, BASE_Y + 1.8, z), Vector3(0.22, 3.6, 4.0), m["dark"], true)
	_box(shop, "Marquesina", Vector3(x, BASE_Y + 3.9, z), Vector3(9.1, 0.18, 4.0), m["dark"])
	_box(shop, "FrenteVidriadoIzq", Vector3(x - 2.65, BASE_Y + 2.0, z - 1.82), Vector3(3.5, 2.5, 0.06), m["glass"], true)
	_box(shop, "FrenteVidriadoDer", Vector3(x + 2.65, BASE_Y + 2.0, z - 1.82), Vector3(3.5, 2.5, 0.06), m["glass"], true)
	_box(shop, "Meson", Vector3(x, BASE_Y + 1.12, z - 1.2), Vector3(8.7, 1.1, 1.1), m["dark"], true)
	_box(shop, "CubiertaMeson", Vector3(x, BASE_Y + 1.72, z - 1.15), Vector3(9.0, 0.12, 1.24), m["steel"])
	for dx in [-3.1, -1.1, 1.1, 3.1]:
		_box(shop, "Vitrina", Vector3(x + dx, BASE_Y + 2.0, z - 1.1), Vector3(1.55, 0.58, 0.78), m["glass"])
		_box(shop, "BandejaProducto", Vector3(x + dx, BASE_Y + 1.78, z - 1.1), Vector3(1.35, 0.06, 0.58), m["wood"])
	_box(shop, "RefrigeradorAzul", Vector3(x - 5.25, BASE_Y + 1.45, z - 0.5), Vector3(1.0, 2.9, 1.2), m["blue"], true)
	_box(shop, "PuertaRefrigerador", Vector3(x - 5.25, BASE_Y + 1.5, z + 0.12), Vector3(0.78, 2.55, 0.08), m["glass"])
	_box(shop, "MaquinaCafe", Vector3(x + 5.15, BASE_Y + 1.35, z - 0.45), Vector3(1.1, 2.5, 1.1), m["dark"])
	_box(shop, "PantallaCafe", Vector3(x + 5.15, BASE_Y + 1.95, z + 0.12), Vector3(0.58, 0.48, 0.035), m["screen"])
	_box(shop, "LamparaCalida", Vector3(x, BASE_Y + 3.73, z - 1.0), Vector3(6.4, 0.06, 0.07), m["warm"])
	var shop_sign := _label(shop, "LetreroCafeteria", "CAFETERIA  ·  TALLER 21", Vector3(x, BASE_Y + 3.25, z - 2.0), 64, Color("f1c36b"))
	shop_sign.rotation.y = PI

func _corridor_rooms(parent: Node3D) -> void:
	var corridor := _group(parent, "PasilloSalasTecnicas")
	# Cuatro recintos existentes en el plano nuevo; marcos, paños esmerilados y vanos de puerta.
	var starts: Array[float] = [-119.0, -109.5, -100.0, -90.5]
	var titles: Array[String] = ["MECANICA 01", "ELECTROMECANICA", "SOLDADURA", "PRIMEROS AUXILIOS"]
	for i in starts.size():
		var z := starts[i]
		var length := 8.6
		_box(corridor, "MuroFondo%d" % i, Vector3(-68.0, BASE_Y + 1.8, z - 4.5), Vector3(0.25, 3.6, length), m["wall"], true)
		_box(corridor, "MuroLateralIzq%d" % i, Vector3(-77.0, BASE_Y + 1.8, z), Vector3(0.25, 3.6, length), m["wall"], true)
		var east_wall := _box(corridor, "MuroLateralDer%d" % i, Vector3(-59.0, BASE_Y + 1.8, z), Vector3(0.25, 3.6, length), m["wall"], true)
		east_wall.visible = false
		# Frontal con puerta libre al centro y laterales acristalados.
		_box(corridor, "Antepecho%d" % i, Vector3(-68.0, BASE_Y + 0.48, z + 4.4), Vector3(17.5, 0.96, 0.20), m["wall"])
		_box(corridor, "VidrioFrontalIzq%d" % i, Vector3(-72.0, BASE_Y + 2.1, z + 4.4), Vector3(9.0, 2.2, 0.08), m["glass"])
		_box(corridor, "VidrioFrontalDer%d" % i, Vector3(-62.0, BASE_Y + 2.1, z + 4.4), Vector3(7.5, 2.2, 0.08), m["glass"])
		_box(corridor, "Dintel%d" % i, Vector3(-68.0, BASE_Y + 3.35, z + 4.4), Vector3(17.5, 0.30, 0.22), m["steel"])
		_box(corridor, "MarcoPuerta%d" % i, Vector3(-67.7, BASE_Y + 1.4, z + 4.25), Vector3(1.0, 2.8, 0.08), m["steel"])
		_box(corridor, "HojaVidrio%d" % i, Vector3(-66.9, BASE_Y + 1.4, z + 4.2), Vector3(0.72, 2.55, 0.06), m["glass"])
		_box(corridor, "Manilla%d" % i, Vector3(-66.55, BASE_Y + 1.35, z + 4.05), Vector3(0.035, 0.42, 0.08), m["steel"])
		_label(corridor, "RotuloSala%d" % i, titles[i], Vector3(-68.0, BASE_Y + 3.75, z + 4.15), 34)
		_box(corridor, "LuzSala%d" % i, Vector3(-68.0, BASE_Y + 3.5, z), Vector3(3.0, 0.06, 0.14), m["lamp"])
		# Equipamiento interior resumido visible a través de la fachada.
		_box(corridor, "BancoPractica%d" % i, Vector3(-71.0, BASE_Y + 0.95, z - 1.1), Vector3(3.8, 0.12, 1.1), m["blue"])
		for dx in [-2.5, 2.5]:
			_box(corridor, "EstacionTecnica%d" % i, Vector3(-68.0 + dx, BASE_Y + 1.35, z - 2.0), Vector3(0.75, 1.8, 0.55), m["steel"])
	# Fachadas de vidrio orientadas al pasillo oriental; puertas centradas por sala.
	for i in starts.size():
		var room_z := starts[i]
		_box(corridor, "VidrioPasilloIzq%d" % i, Vector3(-58.84, BASE_Y + 2.05, room_z - 2.55), Vector3(0.08, 2.25, 3.45), m["glass"])
		_box(corridor, "VidrioPasilloDer%d" % i, Vector3(-58.84, BASE_Y + 2.05, room_z + 2.55), Vector3(0.08, 2.25, 3.45), m["glass"])
		_box(corridor, "DintelPasillo%d" % i, Vector3(-58.84, BASE_Y + 3.32, room_z), Vector3(0.22, 0.28, 8.55), m["steel"])
		_box(corridor, "HojaPuertaPasillo%d" % i, Vector3(-58.84, BASE_Y + 1.35, room_z), Vector3(0.07, 2.55, 1.25), m["glass"])
		_box(corridor, "ManillaPuertaPasillo%d" % i, Vector3(-58.76, BASE_Y + 1.32, room_z - 0.40), Vector3(0.06, 0.42, 0.035), m["steel"])
		var room_sign := _label(corridor, "RotuloPasillo%d" % i, titles[i], Vector3(-58.55, BASE_Y + 3.72, room_z), 30)
		room_sign.rotation.y = PI * 0.5
	# Pasillo claro de circulación y lockers al costado oriental de la banda de salas.
	_box(corridor, "FranjaOrientacion", Vector3(-50.5, BASE_Y + 0.03, -101.0), Vector3(0.16, 0.025, 37.0), m["line"])
	_lockers(corridor, Vector3(-53.0, BASE_Y, -101.0), 30, PI * 0.5, true, 0.85)
	# La sala queda en el lado oeste; el eje libre discurre por X=-49…-57.
	var corridor_sign := _label(corridor, "CartelPasillo", "SALAS TECNICAS  →", Vector3(-51.5, BASE_Y + 3.3, -119.5), 44)
	corridor_sign.rotation.y = PI

func _vehicle(parent: Node3D, center: Vector3, index: int, color: Material) -> void:
	var car := _group(parent, "VehiculoTaller%d" % index)
	_box(car, "Chasis", center + Vector3(0, 0.58, 0), Vector3(1.9, 0.42, 4.5), m["dark"], true)
	_box(car, "Carroceria", center + Vector3(0, 1.0, 0.25), Vector3(1.88, 0.68, 3.5), color)
	_box(car, "Cabina", center + Vector3(0, 1.67, -0.25), Vector3(1.55, 0.8, 1.72), m["glass"])
	_box(car, "Capo", center + Vector3(0, 1.15, 1.54), Vector3(1.74, 0.16, 1.0), color)
	_box(car, "Parabrisas", center + Vector3(0, 1.68, 0.62), Vector3(1.48, 0.64, 0.06), m["screen"])
	for side in [-1.0, 1.0]:
		for z in [-1.45, 1.48]:
			_cylinder(car, "Rueda", center + Vector3(side * 1.0, 0.55, z), 0.43, 0.24, m["dark"], Vector3.RIGHT)
	_box(car, "Parachoques", center + Vector3(0, 0.72, 2.35), Vector3(1.95, 0.16, 0.14), m["steel"])

func _tool_cart(parent: Node3D, center: Vector3, index: int, color: Material) -> void:
	var cart := _group(parent, "CarroHerramientas%d" % index)
	_box(cart, "Caja", center + Vector3(0, 0.75, 0), Vector3(1.0, 0.82, 0.72), color, true)
	for y in [0.58, 0.82, 1.06]:
		_box(cart, "Bandeja", center + Vector3(0, y, 0.39), Vector3(0.92, 0.04, 0.08), m["steel"])
	for x in [-0.38, 0.38]:
		for z in [-0.27, 0.27]:
			_cylinder(cart, "RuedaCarro", center + Vector3(x, 0.18, z), 0.13, 0.09, m["dark"], Vector3.RIGHT)

func _hose(parent: Node3D, from: Vector3, to: Vector3, index: int) -> void:
	var sections := 5
	for i in sections:
		var a := from.lerp(to, float(i) / float(sections))
		var b := from.lerp(to, float(i + 1) / float(sections))
		var dir := (b - a).normalized()
		var seg := _cylinder(parent, "MangueraFlexible%d_%d" % [index, i], (a + b) * 0.5, 0.25, a.distance_to(b) + 0.04, m["orange"], dir)

func _automotive(parent: Node3D) -> void:
	var shop := _group(parent, "MecanicaAutomotriz")
	# Delimitación de puestos en el hormigón, sin cerrar la nave.
	for x in [33.0, 47.0, 61.0, 79.0]:
		_box(shop, "LineaPuesto", Vector3(x, BASE_Y + 0.018, -125.0), Vector3(0.06, 0.025, 34.0), m["line"])
	for z in [-150.0, -108.0]:
		_box(shop, "LineaCabecera", Vector3(51.0, BASE_Y + 0.018, z), Vector3(54.0, 0.025, 0.06), m["line"])
	_vehicle(shop, Vector3(36.0, BASE_Y, -127.0), 1, m["blue"])
	_vehicle(shop, Vector3(69.0, BASE_Y, -129.0), 2, m["red"])
	var automotive_sign := _label(shop, "TituloMecanica", "MECANICA AUTOMOTRIZ  ·  PUESTOS DE DIAGNOSTICO", Vector3(50.0, BASE_Y + 4.2, -143.0), 54)
	automotive_sign.rotation.y = PI
	for i in 3:
		var bx := 26.0 + float(i) * 16.0
		_box(shop, "BancoDidactico", Vector3(bx, BASE_Y + 1.05, -109.0), Vector3(4.4, 1.8, 1.5), m["steel"], true)
		_box(shop, "PanelInstrumentos", Vector3(bx, BASE_Y + 2.15, -109.72), Vector3(3.6, 0.55, 0.10), m["blue"])
		_box(shop, "PantallaBanco", Vector3(bx, BASE_Y + 2.18, -109.65), Vector3(1.0, 0.38, 0.035), m["screen"])
		_box(shop, "MotorPractica", Vector3(bx, BASE_Y + 2.18, -108.0), Vector3(1.35, 0.9, 0.85), m["dark"])
		_box(shop, "MesaTrabajo", Vector3(bx, BASE_Y + 0.88, -140.0), Vector3(3.4, 0.12, 1.5), m["blue"], true)
		_box(shop, "ComponenteMotor", Vector3(bx, BASE_Y + 1.55, -140.0), Vector3(1.4, 1.0, 0.9), m["steel"])
	for i in 3:
		_hose(shop, Vector3(32.0 + float(i) * 18.0, BASE_Y + 7.8, -126.0), Vector3(32.0 + float(i) * 18.0, BASE_Y + 2.7, -127.0), i)
		_cylinder(shop, "CampanaExtraccion", Vector3(32.0 + float(i) * 18.0, BASE_Y + 7.65, -126.0), 0.42, 0.34, m["steel"])
	_tool_cart(shop, Vector3(42.0, BASE_Y, -137.0), 1, m["red"])
	_tool_cart(shop, Vector3(59.0, BASE_Y, -137.0), 2, m["blue"])

func _welding(parent: Node3D) -> void:
	var bay := _group(parent, "SoldaduraYEstructurasMetalicas")
	# Reserva el núcleo NEXO en el sector oriental (x≈48, z≈−100).
	var floor_mark := Vector3(69.0, BASE_Y + 0.018, -143.0)
	_box(bay, "DelimitacionAmarilla", floor_mark, Vector3(28.0, 0.025, 0.07), m["line"])
	_label(bay, "TituloSoldadura", "SOLDADURA  ·  ESTRUCTURAS METALICAS", Vector3(69.0, BASE_Y + 4.0, -157.0), 52)
	# Pórtico de acero, alejado de la arena de NEXO.
	for x in [62.0, 80.0]:
		_box(bay, "PilarPortalAcero", Vector3(x, BASE_Y + 3.2, -151.0), Vector3(0.24, 6.4, 0.24), m["steel"], true)
	_box(bay, "VigaPortalAcero", Vector3(71.0, BASE_Y + 6.3, -151.0), Vector3(18.2, 0.26, 0.28), m["steel"])
	for i in 3:
		var x := 63.0 + float(i) * 8.0
		_box(bay, "MesaSoldadura", Vector3(x, BASE_Y + 0.9, -145.0), Vector3(5.6, 0.16, 1.8), m["steel"], true)
		_box(bay, "TornilloBancoRojo", Vector3(x, BASE_Y + 1.25, -145.0), Vector3(0.62, 0.52, 0.48), m["red"])
		_box(bay, "Mordaza", Vector3(x, BASE_Y + 1.54, -145.0), Vector3(0.12, 0.1, 0.6), m["steel"])
		_box(bay, "PantallaSoldadura", Vector3(x + 2.4, BASE_Y + 1.9, -146.8), Vector3(0.12, 3.7, 3.2), m["blue"])
	# Perfiles ordenados sobre bastidores.
	for level in [BASE_Y + 0.9, BASE_Y + 1.35, BASE_Y + 1.8]:
		for i in 4:
			_box(bay, "PerfilMetalicoApilado", Vector3(70.0, level, -135.0 + float(i) * 0.55), Vector3(10.0, 0.12, 0.11), m["steel"])
	_box(bay, "ContenedorChatarra", Vector3(80.0, BASE_Y + 0.85, -137.0), Vector3(3.4, 1.7, 2.4), m["blue"], true)
	for i in 5:
		_box(bay, "RestosMetalicos", Vector3(78.8 + float(i % 3) * 0.8, BASE_Y + 1.75 + float(i / 3) * 0.16, -137.0 + float(i % 2) * 0.48), Vector3(0.9, 0.12, 0.45), m["red"] if i % 2 == 0 else m["steel"])
	for i in 3:
		_cylinder(bay, "CilindroIndustrialDecorativo", Vector3(60.5 + float(i) * 1.1, BASE_Y + 0.75, -136.0), 0.34, 1.5, m["blue"])
	# Extracción superior compartida visualmente con módulos de ducto.
	_box(bay, "DuctoExtraccion", Vector3(70.0, BASE_Y + 8.4, -145.0), Vector3(22.0, 0.7, 0.65), m["steel"])
	for x in [63.0, 71.0, 79.0]:
		_box(bay, "CampanaSoldadura", Vector3(x, BASE_Y + 6.5, -145.0), Vector3(2.4, 0.18, 1.9), m["steel"])

func _machinery(parent: Node3D) -> void:
	var machines := _group(parent, "MaquinariaIndustrial")
	# Grúa horquilla estática, con envolvente de colisión simple.
	var fork := _group(machines, "GruaHorquilla")
	_box(fork, "ChasisAmarillo", Vector3(38.0, BASE_Y + 0.72, -115.0), Vector3(2.1, 1.25, 3.0), m["yellow"], true)
	_box(fork, "Cabina", Vector3(38.0, BASE_Y + 1.95, -115.6), Vector3(1.7, 1.4, 1.65), m["dark"])
	_box(fork, "TechoCabina", Vector3(38.0, BASE_Y + 2.72, -115.6), Vector3(1.95, 0.16, 1.8), m["yellow"])
	_box(fork, "Mastil", Vector3(38.0, BASE_Y + 1.75, -112.75), Vector3(1.45, 3.2, 0.16), m["steel"], true)
	_box(fork, "HorquillaIzquierda", Vector3(37.55, BASE_Y + 0.18, -111.7), Vector3(0.18, 0.12, 2.1), m["steel"])
	_box(fork, "HorquillaDerecha", Vector3(38.45, BASE_Y + 0.18, -111.7), Vector3(0.18, 0.12, 2.1), m["steel"])
	for side in [-1.0, 1.0]:
		for z in [-116.0, -113.9]:
			_cylinder(fork, "RuedaIndustrial", Vector3(38.0 + side * 1.08, BASE_Y + 0.45, z), 0.48, 0.23, m["dark"], Vector3.RIGHT)
	# Minicargador simplificado, estacionado sin controles.
	var loader := _group(machines, "Minicargador")
	_box(loader, "Chasis", Vector3(74.0, BASE_Y + 0.82, -119.0), Vector3(2.55, 1.5, 3.5), m["orange"], true)
	_box(loader, "Cabina", Vector3(74.0, BASE_Y + 1.95, -119.2), Vector3(1.65, 1.7, 1.75), m["dark"])
	_box(loader, "VidrioCabina", Vector3(74.0, BASE_Y + 2.0, -118.25), Vector3(1.38, 1.25, 0.04), m["glass"])
	_box(loader, "BrazosPala", Vector3(74.0, BASE_Y + 1.45, -116.55), Vector3(2.7, 0.18, 0.18), m["steel"])
	_box(loader, "Cuchara", Vector3(74.0, BASE_Y + 0.48, -115.3), Vector3(3.0, 0.65, 1.15), m["yellow"], true)
	for side in [-1.0, 1.0]:
		for z in [-120.2, -117.4]:
			_cylinder(loader, "Neumatico", Vector3(74.0 + side * 1.25, BASE_Y + 0.52, z), 0.63, 0.33, m["dark"], Vector3.RIGHT)
	for i in 2:
		var comp := _group(machines, "CarroComponente%d" % i)
		_box(comp, "CarroAzul", Vector3(53.0 + float(i) * 8.0, BASE_Y + 0.72, -117.0), Vector3(2.5, 0.18, 1.5), m["blue"], true)
		_box(comp, "Diferencial", Vector3(53.0 + float(i) * 8.0, BASE_Y + 1.25, -117.0), Vector3(1.35, 0.9, 1.05), m["steel"])
		for side in [-1.0, 1.0]:
			_cylinder(comp, "RuedaCarroComponente", Vector3(53.0 + float(i) * 8.0 + side * 1.0, BASE_Y + 0.24, -117.0), 0.16, 0.1, m["dark"], Vector3.RIGHT)

func _vending(parent: Node3D) -> void:
	var machines := _group(parent, "VendingGenericas")
	for i in 2:
		var x := -45.0 - float(i) * 2.2
		_box(machines, "MaquinaAzul%d" % i, Vector3(x, BASE_Y + 1.2, -128.0), Vector3(1.5, 2.4, 0.86), m["blue"], true)
		_box(machines, "PanelProductos%d" % i, Vector3(x, BASE_Y + 1.35, -127.54), Vector3(1.2, 1.45, 0.06), m["glass"])
		_box(machines, "Pantalla%d" % i, Vector3(x + 0.4, BASE_Y + 2.08, -127.5), Vector3(0.35, 0.3, 0.04), m["screen"])
		_box(machines, "Bandeja%d" % i, Vector3(x, BASE_Y + 0.25, -127.48), Vector3(0.8, 0.16, 0.1), m["dark"])

func _ramp(parent: Node3D) -> void:
	var ramp := _group(parent, "RampaVehicularExterior")
	var start_z := -162.94
	var end_z := -116.0
	var center_z := (start_z + end_z) * 0.5
	var run := end_z - start_z
	var rise := -BASE_Y
	var angle := atan(rise / run)
	var center_y := BASE_Y * 0.5
	var deck := _box(ramp, "LosaInclinada", Vector3(24.37, center_y, center_z), Vector3(5.0, 0.42, run + 0.6), m["concrete"], true, true)
	deck.rotation.x = angle
	# Muros altos y baranda/reja de contención a ambos lados, todos siguen la pendiente.
	for side in [-1.0, 1.0]:
		var wall := _box(ramp, "MuroHormigonLateral", Vector3(24.37 + side * 2.65, center_y + 2.0, center_z), Vector3(0.38, 4.2, run + 0.5), m["wall"], true)
		wall.rotation.x = angle
		var top_z := end_z
		var top_y := 0.0
		var rail := _box(ramp, "VigaSuperiorReja", Vector3(24.37 + side * 2.65, center_y + 4.6, center_z), Vector3(0.11, 0.10, run + 0.5), m["steel"])
		rail.rotation.x = angle
		for i in 18:
			var t := float(i) / 17.0
			var post := _box(ramp, "PosteReja", Vector3(24.37 + side * 2.65, lerpf(4.2, BASE_Y + 4.2, t), lerpf(start_z, top_z, t)), Vector3(0.09, 1.25, 0.09), m["steel"])
			post.rotation.x = angle
		for level in [2.8, 3.3, 3.8]:
			var wire := _box(ramp, "MallaRejaHorizontal", Vector3(24.37 + side * 2.65, center_y + level, center_z), Vector3(0.04, 0.035, run), m["steel"])
			wire.rotation.x = angle
	# Marcas amarillas de borde y juntas transversales muy discretas.
	for side in [-1.0, 1.0]:
		var stripe := _box(ramp, "BordeSeguridad", Vector3(24.37 + side * 2.18, center_y + 0.23, center_z), Vector3(0.12, 0.035, run), m["line"])
		stripe.rotation.x = angle
	_label(ramp, "SalidaVehicular", "SALIDA VEHICULAR  ·  EXTERIOR", Vector3(24.37, BASE_Y + 5.2, -119.0), 48, Color("f2d783"))
	_label(ramp, "SalidaExterior", "EXTERIOR", Vector3(24.37, 3.1, -164.0), 54, Color("f0f2ed"))
	# Franjas de transición de luz, sin iluminar el nivel con un falso cielo.
	for i in 5:
		var z := lerpf(start_z + 2.0, end_z - 2.0, float(i) / 4.0)
		_box(ramp, "LuminariaRampa", Vector3(24.37, lerpf(1.5, BASE_Y + 7.8, float(i) / 4.0), z), Vector3(2.8, 0.10, 0.22), m["lamp"])

func _overhead(parent: Node3D) -> void:
	var overhead := _group(parent, "InstalacionesExpuestas")
	# Vigas de hormigón añadidas bajo el forjado; el cielo permanece abierto.
	for x in [-72.0, -49.0, -26.0, -3.0, 20.0, 43.0, 66.0, 80.0]:
		_box(overhead, "VigaHormigon", Vector3(x, BASE_Y + 10.9, -119.0), Vector3(0.72, 0.82, 79.0), m["beam"])
	for z in [-151.0, -136.0, -120.0, -104.0, -88.0]:
		# El corredor de rampa queda abierto: las bandejas se interrumpen entre X=20…31.
		for segment in [[-27.5, 95.0], [51.0, 40.0]]:
			_box(overhead, "BandejaPortacables", Vector3(segment[0], BASE_Y + 9.4, z), Vector3(segment[1], 0.18, 0.8), m["steel"])
			_box(overhead, "BandejaPortacablesTapa", Vector3(segment[0], BASE_Y + 9.53, z), Vector3(segment[1], 0.08, 0.86), m["locker_frame"])
	# Ductos rectangulares comunes y red de cañerías paralela.
	for x in [-69.0, -46.0, -23.0, 0.0, 35.0, 46.0, 69.0]:
		_box(overhead, "DuctoVentilacion", Vector3(x, BASE_Y + 8.7, -116.0), Vector3(0.58, 0.72, 74.0), m["steel"])
		_box(overhead, "ConduitElectrico", Vector3(x + 0.7, BASE_Y + 8.25, -116.0), Vector3(0.12, 0.12, 74.0), m["yellow_dark"])
	for z in [-148.0, -137.0, -126.0, -115.0, -104.0, -93.0, -82.0]:
		_cylinder(overhead, "TuberiaRoja", Vector3(14.0, BASE_Y + 8.5, z), 0.11, 150.0, m["red"], Vector3.RIGHT)
		_cylinder(overhead, "TuberiaAzul", Vector3(16.0, BASE_Y + 8.25, z), 0.10, 150.0, m["blue_light"], Vector3.RIGHT)
	# Suspensiones oscuras repetidas desde forjado.
	for x in [-69.0, -46.0, -23.0, 0.0, 35.0, 46.0, 69.0]:
		for z in [-145.0, -119.0, -93.0]:
			_box(overhead, "TiranteInstalacion", Vector3(x, BASE_Y + 10.0, z), Vector3(0.06, 0.9, 0.06), m["steel"])

func _safety(parent: Node3D) -> void:
	var safety := _group(parent, "SenaleticaSeguridad")
	var signs: Array = [
		["TALLER MECANICA", Vector3(39, BASE_Y + 4.0, -143), m["yellow"]],
		["EPP OBLIGATORIO", Vector3(67, BASE_Y + 3.0, -157), m["red"]],
		["AREA DE TRABAJO", Vector3(57, BASE_Y + 3.2, -105), m["yellow"]],
		["PRIMEROS AUXILIOS", Vector3(-68, BASE_Y + 4.4, -88), m["green"]],
		["SALIDA", Vector3(-41, BASE_Y + 3.0, -78), m["green"]],
		["ZONA DE VEHICULOS", Vector3(71, BASE_Y + 3.2, -108), m["yellow"]],
		["EXTINTOR", Vector3(45, BASE_Y + 2.5, -139), m["red"]]
	]
	for i in signs.size():
		var entry: Array = signs[i]
		var pos: Vector3 = entry[1]
		_box(safety, "PlacaSeguridad%d" % i, pos, Vector3(3.2, 0.75, 0.08), entry[2])
		_label(safety, "TextoSeguridad%d" % i, entry[0], pos + Vector3(0, -0.03, 0.06), 26)
	# Extintores y conos como decoración compacta.
	for i in 4:
		var x := 44.0 + float(i % 2) * 4.0
		var z := -140.0 + float(i / 2) * 18.0
		_cylinder(safety, "Extintor", Vector3(x, BASE_Y + 0.65, z), 0.22, 1.3, m["red"])
		_box(safety, "ConoNaranja", Vector3(28.0 + float(i) * 2.0, BASE_Y + 0.45, -145.0), Vector3(0.42, 0.9, 0.42), m["orange"])
	# Basureros diferenciados para zona común.
	for x in [-24.0, -40.0]:
		_box(safety, "BasureroReciclaje", Vector3(x, BASE_Y + 0.58, -114.0), Vector3(0.75, 1.15, 0.75), m["green"])

func build_all() -> Dictionary:
	campus = get_parent() as Node3D
	if campus == null or campus.name != "PisoMenos1":
		return {"status":"error", "detail":"El nodo debe colgar directamente de Main/PisoMenos1."}
	if campus.has_node("AmbientacionIndustrial2026"):
		return {"status":"already_built"}
	scene_root = get_tree().edited_scene_root
	_make_materials()
	var root := _group(campus, "AmbientacionIndustrial2026")
	root.set_meta("propietario", "reconstruccion_visual_piso_menos1_2026")
	# Solo cambia el material visual de la losa existente; su cuerpo y forma permanecen.
	var slab := campus.get_node_or_null("Piso") as MeshInstance3D
	if slab != null:
		slab.material_override = m["concrete"]
	_overhead(root)
	_lights(root)
	_cafe(root)
	_central_area(root)
	_corridor_rooms(root)
	_automotive(root)
	_welding(root)
	_machinery(root)
	_vending(root)
	_ramp(root)
	_safety(root)
	return {"status":"built", "zones":11, "rooms":4, "vehicles":2, "ping_pong":2, "locker_rows":3, "nexo_reserved":Vector2(48,-100), "ramp_start":Vector3(24.37,BASE_Y,-116), "ramp_exit":Vector3(24.37,0,-162.94)}

func rebuild_all() -> Dictionary:
	campus = get_parent() as Node3D
	var old_visuals: Node = campus.get_node_or_null("AmbientacionIndustrial2026")
	if old_visuals != null:
		old_visuals.free()
	return build_all()

func audit_layout() -> Dictionary:
	if campus == null:
		campus = get_parent() as Node3D
	return {
		"floor_node":"PisoMenos1",
		"height":BASE_Y,
		"footprint_m":[169.1,86.05],
		"elevator_forward":"+Z",
		"player_left_world":"+X",
		"player_right_world":"-X",
		"central_stair_preserved":campus.get_node_or_null("EscaleraCentralMenos1") != null,
		"emergency_stair_preserved":campus.get_node_or_null("EscaleraEmergencia") != null,
		"existing_elevator_lobbies":campus.get_node_or_null("VestibuloAscensores") != null,
		"nexo_reserved_world":[48.0,-100.0],
		"ambientation_built":campus.has_node("AmbientacionIndustrial2026")
	}
