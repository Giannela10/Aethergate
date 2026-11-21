@tool
extends Node3D

const BALDOSAS := preload("res://materials/entrance/vereda_frente_duoc.gdshader")

func _ready() -> void:
	var metal := _paint(Color("#252c29"))
	var hormigon := _paint(Color("#756b5e"))
	var arena := _paint(Color("#a58c6f"))
	var pintura := _paint(Color("#d4ad52"))
	var tronco := _paint(Color("#584638"))
	var hojas := [_paint(Color("#414c35")), _paint(Color("#536049")), _paint(Color("#364633"))]

	var baldosa := ShaderMaterial.new()
	baldosa.shader = BALDOSAS
	_box("VeredaBaldosas", Vector3(-7.5, 0.1, 18.0), Vector3(312, 0.14, 8), baldosa)
	_box("FranjaArbolada", Vector3(-7.5, 0.09, 23.2), Vector3(312, 0.16, 2.4), arena)
	_box("Berma", Vector3(-7.5, 0.01, 29.9), Vector3(312, 0.22, 10.9), arena)
	_box("SoleraAmarilla", Vector3(-7.5, 0.02, 35.3), Vector3(312, 0.20, 0.22), pintura)
	_box("BaseAvenida", Vector3(-7.5, -0.92, 45), Vector3(390, 1.34, 20), hormigon)
	_box("ZocaloBaranda", Vector3(-7.5, -0.57, 24.4), Vector3(313, 1.5, 0.32), hormigon)
	_baranda("BarandaVereda", 24.4, 0.16, 1.25, 313.0, 0.24, metal)

	_box("TableroViaducto", Vector3(-7.5, 10.7, 57.5), Vector3(390, 1.55, 9), hormigon)
	_box("VigaLongitudinal", Vector3(-7.5, 9.8, 57.5), Vector3(390, 0.65, 4.8), hormigon)
	for z in [53.0, 62.0]:
		_box("PretilViaducto", Vector3(-7.5, 11.47, z), Vector3(390, 0.4, 0.48), hormigon)
		_baranda("BarandaViaducto", z, 11.65, 0.85, 390.0, 1.8, metal)

	var pilares: Array[Vector3] = []
	var capiteles: Array[Vector3] = []
	for x in range(-181, 181, 34):
		pilares.append(Vector3(x, 4.1, 57.5))
		capiteles.append(Vector3(x, 9.3, 57.5))
	_repeat("PilaresViaducto", _box_mesh(Vector3(2.2, 11.2, 2.6), hormigon), pilares)
	_repeat("CapitelesViaducto", _box_mesh(Vector3(3.0, 0.75, 7.4), hormigon), capiteles)

	var postes: Array[Vector3] = []
	var brazos: Array[Vector3] = []
	var focos: Array[Vector3] = []
	for x in range(-147, 148, 27):
		postes.append(Vector3(x, 3.33, 22.65))
		brazos.append(Vector3(x, 6.5, 23.45))
		focos.append(Vector3(x, 6.46, 24.23))
	_repeat("PostesAlumbrado", _box_mesh(Vector3(0.13, 6.35, 0.13), metal), postes)
	_repeat("BrazosAlumbrado", _box_mesh(Vector3(0.11, 0.11, 1.75), metal), brazos)
	_repeat("FocosAlumbrado", _box_mesh(Vector3(0.40, 0.16, 0.55), pintura), focos)

	var tallos: Array[Vector3] = []
	var copas: Array[Vector3] = []
	for x in range(-155, 145, 14):
		tallos.append(Vector3(x, 1.94, 22.55))
		copas.append(Vector3(x, 4.2, 22.55))
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.10
	cilindro.bottom_radius = 0.18
	cilindro.height = 3.6
	cilindro.radial_segments = 8
	cilindro.material = tronco
	_repeat("Troncos", cilindro, tallos)
	for i in range(3):
		var copa := SphereMesh.new()
		copa.radius = [1.55, 1.23, 1.04][i]
		copa.height = [3.7, 2.45, 2.0][i]
		copa.radial_segments = 9
		copa.rings = 5
		copa.material = hojas[i]
		var ramas: Array[Vector3] = []
		for j in range(copas.size()):
			var lado := -1.0 if j % 2 == 0 else 1.0
			var altura := float(j % 4) * 0.2
			var desplazamiento := [Vector3(0, altura, 0), Vector3(lado, altura + 0.12, -0.47), Vector3(-lado * 0.75, altura + 0.74, 0.52)]
			ramas.append(copas[j] + desplazamiento[i])
		_repeat("Follaje", copa, ramas)

func _baranda(label: String, z: float, base: float, height: float, length: float, spacing: float, metal: Material) -> void:
	var center := -7.5
	var bars: Array[Vector3] = []
	var count := int(floor(length / spacing))
	for i in range(count + 1):
		bars.append(Vector3(center + (float(i) - count * 0.5) * spacing, base + height * 0.5, z))
	_repeat(label, _box_mesh(Vector3(0.054, height, 0.065), metal), bars)
	_box(label + "Superior", Vector3(center, base + height, z), Vector3(length, 0.10, 0.12), metal)
	_box(label + "Inferior", Vector3(center, base + 0.09, z), Vector3(length, 0.08, 0.09), metal)

func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material

func _box_mesh(size: Vector3, material: Material) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	return mesh

func _box(label: String, center: Vector3, size: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = _box_mesh(size, material)
	instance.position = center
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance, true)

func _repeat(label: String, mesh: Mesh, positions: Array[Vector3]) -> void:
	# Keep the bounds of the long fences local so the camera can reject offscreen sections.
	const CHUNK_SIZE := 64
	for first in range(0, positions.size(), CHUNK_SIZE):
		var name_suffix := "" if first == 0 else "_%d" % first
		_add_batch(label + name_suffix, mesh, positions, first, mini(CHUNK_SIZE, positions.size() - first))

func _add_batch(label: String, mesh: Mesh, positions: Array[Vector3], first: int, count: int) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = count
	for i in range(count):
		batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[first + i]))
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = batch
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance, true)
