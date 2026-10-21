@tool
extends Node3D
## Construcción manual del pasillo de la fotografía del 13 de octubre.
## Los elementos quedan guardados en la escena; no se generan al jugar.
var materials: Dictionary = {}

func material(key: String, color: Color, roughness: float = 0.6, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	materials[key] = result
	return result

func owned(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = get_tree().edited_scene_root

func box(title: String, center: Vector3, size_value: Vector3, surface: Material, solid: bool = false, parent: Node = self) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = title
	mesh_node.position = center
	var mesh := BoxMesh.new()
	mesh.size = size_value
	mesh_node.mesh = mesh
	mesh_node.material_override = surface
	owned(mesh_node, parent)
	if solid:
		var body := StaticBody3D.new()
		owned(body, mesh_node)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size_value
		collision.shape = shape
		owned(collision, body)
	return mesh_node

func cylinder(title: String, center: Vector3, radius: float, height_value: float, surface: Material, parent: Node = self) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.position = center
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height_value
	mesh.radial_segments = 16
	node.mesh = mesh
	node.material_override = surface
	owned(node, parent)
	return node

func text_label(title: String, content: String, center: Vector3, angle: float, color: Color, pixel: float = 0.003) -> void:
	var label := Label3D.new()
	label.name = title
	label.text = content
	label.position = center
	label.rotation.y = angle
	label.font_size = 48
	label.pixel_size = pixel
	label.modulate = color
	label.outline_size = 0
	owned(label, self)

func build() -> Dictionary:
	if not Engine.is_editor_hint():
		return {"error": "Construcción disponible solo en el editor"}
	for child in get_children():
		child.free()
	global_position = Vector3(34, 83.94, -136.8)
	rotation.y = -PI / 2
	material("beige", Color(0.66, 0.58, 0.47))
	material("joint", Color(0.24, 0.22, 0.20))
	material("black", Color(0.025, 0.028, 0.033), 0.34, 0.45)
	material("steel", Color(0.53, 0.56, 0.57), 0.24, 0.8)
	material("red", Color(0.72, 0.025, 0.018), 0.35)
	material("white", Color(0.84, 0.83, 0.77), 0.48)
	material("purple", Color(0.31, 0.055, 0.58), 0.88)
	material("green", Color(0.06, 0.38, 0.12))
	material("yellow", Color(0.86, 0.68, 0.03))
	material("blue", Color(0.035, 0.11, 0.33))
	material("ceiling", Color(0.25, 0.25, 0.24), 0.95)
	var glass := material("glass", Color(0.13, 0.20, 0.23, 0.25), 0.14, 0.18)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var frosted := material("frosted", Color(0.62, 0.70, 0.69, 0.75), 0.65)
	frosted.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frosted.cull_mode = BaseMaterial3D.CULL_DISABLED
	var lamp := material("lamp", Color(1, 0.93, 0.80), 0.25)
	lamp.emission_enabled = true
	lamp.emission = Color(1, 0.93, 0.80)
	lamp.emission_energy_multiplier = 2.5
	var floor_material := ShaderMaterial.new()
	floor_material.shader = load("res://scripts/pisos/piso_8/baldosas_oscuras.gdshader")
	box("PisoBaldosasOscuras", Vector3(0, -0.015, -15), Vector3(4.8, 0.03, 30), floor_material)
	box("CieloHormigon", Vector3(0, 4.06, -15), Vector3(4.95, 0.16, 30), materials.ceiling)
	# Pilares y paños beige alternan con las puertas de salas 805–809.
	for i in range(5):
		var z := -3.0 - i * 6.0
		box("PilarBeige%02d" % i, Vector3(-2.38, 1.98, z + 1.4), Vector3(0.28, 3.96, 2.3), materials.beige, true)
		box("ZocaloIzquierdo%02d" % i, Vector3(-2.21, 0.06, z + 1.4), Vector3(0.045, 0.12, 2.3), materials.black)
		for row in range(1, 10):
			box("JuntaHorizontal%02d_%02d" % [i, row], Vector3(-2.232, row * 0.39, z + 1.4), Vector3(0.012, 0.012, 2.3), materials.joint)
		for offset in [-0.55, 0.35]:
			box("JuntaVertical", Vector3(-2.231, 1.98, z + 1.4 + offset), Vector3(0.012, 3.96, 0.008), materials.joint)
		box("MamparaSala%02d" % i, Vector3(-2.36, 1.85, z - 1.65), Vector3(0.06, 3.7, 3.6), glass, true)
		box("EsmeriladoSala%02d" % i, Vector3(-2.317, 1.1, z - 1.65), Vector3(0.008, 1.15, 3.55), frosted)
		for dz in [-3.45, -1.65, 0.15]:
			box("MarcoSala", Vector3(-2.3, 1.85, z + dz), Vector3(0.08, 3.7, 0.06), materials.black)
		box("DintelSala", Vector3(-2.3, 3.68, z - 1.65), Vector3(0.08, 0.08, 3.6), materials.black)
		box("PlacaSala", Vector3(-2.27, 2.65, z - 0.65), Vector3(0.04, 0.36, 0.48), materials.white)
		text_label("NumeroSala", str(805 + i), Vector3(-2.242, 2.65, z - 0.65), PI / 2, Color(0.06, 0.06, 0.06), 0.0024)
		box("FranjaDuoc", Vector3(-2.239, 2.65, z - 0.94), Vector3(0.008, 0.36, 0.1), materials.blue)
		box("ManillaSala", Vector3(-2.19, 1.3, z - 1.12), Vector3(0.06, 0.42, 0.035), materials.steel)
		# Fachada acristalada con pilares y perfiles oscuros.
		box("VentanalDerecho%02d" % i, Vector3(2.38, 1.98, z), Vector3(0.06, 3.96, 5.9), glass, true)
		box("PilarDerecho%02d" % i, Vector3(2.24, 1.98, z - 2.9), Vector3(0.38, 3.96, 0.48), materials.beige, true)
		for dz in [-2.65, -1.3, 0, 1.3, 2.65]:
			box("PerfilVentanal", Vector3(2.30, 1.98, z + dz), Vector3(0.1, 3.96, 0.065), materials.black)
		box("ZocaloVentanal", Vector3(2.30, 0.06, z), Vector3(0.12, 0.12, 5.9), materials.black)
		box("BandejaElectrica", Vector3(-0.8, 3.82, z), Vector3(0.56, 0.14, 5.9), materials.black)
		for dz in range(6):
			box("TravesanoCielo", Vector3(0, 3.92, z - 2.5 + dz), Vector3(4.6, 0.1, 0.09), materials.steel)
		box("ConductoVentilacion", Vector3(1.25, 3.83, z), Vector3(0.62, 0.26, 5.9), materials.ceiling)
		box("LuzLineal%02d" % i, Vector3(0, 3.65, z), Vector3(0.12, 0.055, 3.4), lamp)
		var light := OmniLight3D.new()
		light.name = "IluminacionPasillo%02d" % i
		light.position = Vector3(0, 3.35, z)
		light.light_color = Color(1, 0.92, 0.80)
		light.light_energy = 1.15
		light.omni_range = 7
		owned(light, self)
	build_fire_cabinet()
	for i in range(2):
		var z := -5.1 - i * 0.5
		cylinder("Basurero", Vector3(-1.88, 0.45, z), 0.2, 0.9, materials.steel)
		cylinder("TapaBasurero", Vector3(-1.88, 0.91, z), 0.205, 0.065, materials.yellow if i == 0 else materials.green)
		box("BocaBasurero", Vector3(-1.65, 0.76, z), Vector3(0.015, 0.12, 0.22), materials.black)
	for z in [-8.0, -17.0, -25.0]:
		build_table(z)
	build_armchair()
	# La salida queda abierta para mantener la circulación al resto del nivel.
	for x in [-1.75, 1.75]:
		box("MamparaFinal", Vector3(x, 1.8, -29.8), Vector3(1.25, 3.6, 0.06), glass, true)
		box("EsmeriladoFinal", Vector3(x, 1.05, -29.75), Vector3(1.25, 0.9, 0.012), frosted)
		box("MarcoFinal", Vector3(signf(x) * 1.11, 1.8, -29.75), Vector3(0.07, 3.6, 0.1), materials.steel)
	text_label("MarcaDuocFinal", "DuocUC", Vector3(1.75, 2.38, -29.70), 0, Color(1, 1, 1), 0.004)
	set_meta("referencia", "WhatsApp Image 2026-10-13 at 09.16.56.jpeg")
	return {"built": true, "elements": get_child_count(), "floor": 8}

func build_fire_cabinet() -> void:
	var z := -3.3
	cylinder("TuberiaIncendio", Vector3(-2.03, 1.9, z), 0.045, 3.8, materials.red)
	box("FondoGabinete", Vector3(-1.96, 1.82, z), Vector3(0.16, 0.96, 0.72), materials.red, true)
	for dz in [-0.38, 0.38]:
		box("LateralGabinete", Vector3(-1.76, 1.82, z + dz), Vector3(0.48, 0.96, 0.055), materials.red)
	for y in [1.31, 2.33]:
		box("BordeGabinete", Vector3(-1.76, y, z), Vector3(0.48, 0.055, 0.8), materials.red)
	var hose := MeshInstance3D.new()
	hose.name = "MangueraEnrollada"
	hose.position = Vector3(-1.62, 1.89, z)
	hose.rotation.z = PI / 2
	var torus := TorusMesh.new()
	torus.inner_radius = 0.13
	torus.outer_radius = 0.28
	hose.mesh = torus
	hose.material_override = materials.white
	owned(hose, self)
	box("SenalIncendio", Vector3(-2.20, 2.91, z), Vector3(0.025, 0.48, 0.30), materials.red)
	text_label("TextoIncendio", "RED\nHÚMEDA", Vector3(-2.18, 2.91, z), PI / 2, Color.WHITE, 0.0012)
	box("SenalZonaSegura", Vector3(-2.2, 1.82, z - 0.75), Vector3(0.03, 0.28, 0.85), materials.green)
	text_label("TextoZonaSegura", "ZONA SEGURA", Vector3(-2.175, 1.82, z - 0.75), PI / 2, Color.WHITE, 0.0013)

func build_table(z: float) -> void:
	box("MesaAlta", Vector3(1.92, 1.08, z), Vector3(0.83, 0.055, 1.05), materials.white, true)
	box("SoporteMesa", Vector3(2.24, 0.55, z), Vector3(0.08, 1.08, 0.7), materials.steel)
	var chair := Node3D.new()
	chair.name = "SillaBlanca"
	chair.position = Vector3(1.69, 0, z + 0.75)
	owned(chair, self)
	box("Asiento", Vector3(0, 0.57, 0), Vector3(0.46, 0.06, 0.46), materials.white, true, chair)
	box("Respaldo", Vector3(0, 0.88, 0.21), Vector3(0.46, 0.57, 0.055), materials.white, true, chair)
	for x in [-0.19, 0.19]:
		for dz in [-0.18, 0.18]:
			box("Pata", Vector3(x, 0.28, dz), Vector3(0.045, 0.56, 0.045), materials.white, false, chair)
	box("Reposapies", Vector3(0, 0.23, -0.17), Vector3(0.42, 0.035, 0.045), materials.steel, false, chair)

func build_armchair() -> void:
	var chair := Node3D.new()
	chair.name = "SillonMorado"
	chair.position = Vector3(1.76, 0, -1.25)
	owned(chair, self)
	box("Base", Vector3(0, 0.35, 0), Vector3(0.96, 0.30, 0.92), materials.purple, true, chair)
	box("Cojin", Vector3(0, 0.55, 0), Vector3(0.72, 0.16, 0.75), materials.purple, false, chair)
	box("Respaldo", Vector3(0.39, 0.88, 0), Vector3(0.19, 0.87, 0.92), materials.purple, true, chair)
	for z in [-0.40, 0.40]:
		box("Apoyabrazos", Vector3(0, 0.66, z), Vector3(0.95, 0.39, 0.16), materials.purple, true, chair)
		for x in [-0.35, 0.35]:
			cylinder("PataSillon", Vector3(x, 0.12, z), 0.035, 0.24, materials.steel, chair)
