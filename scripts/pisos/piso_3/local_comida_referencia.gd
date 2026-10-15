@tool
extends "res://scripts/pisos/piso_8/piso_8_completo.gd"
const LOCAL_DEPTH := 39.75
## Local del piso 3: geometría guardada, sin reconstrucción al jugar.

func _ready() -> void:
	pass

func build() -> Dictionary:
	for child in get_children():
		child.free()
	position = Vector3(69.3, 23.985, -109.85)
	rotation.y = PI / 2.0
	init_materials()
	material("hormigon", Color(0.43, 0.43, 0.39), 0.95)
	material("madera_local", Color(0.63, 0.43, 0.23), 0.7)
	material("tapizado", Color(0.115, 0.12, 0.125), 0.97)
	material("naranja", Color(0.79, 0.22, 0.07), 0.7)
	material("hoja", Color(0.075, 0.32, 0.085), 0.85).cull_mode = BaseMaterial3D.CULL_DISABLED
	material("tierra", Color(0.095, 0.073, 0.045), 1.0)
	material("menu", Color(0.045, 0.037, 0.032), 0.9)
	material("crema", Color(0.95, 0.87, 0.67), 0.6)
	box("BaldosasLocal", Vector3(0, -0.012, -11.5), Vector3(23.6, 0.024, 23), dark_floor)
	box("MuroFondo", Vector3(0, 5.8, -23.1), Vector3(23.6, 11.6, 0.22), materials.hormigon, true)
	# Doble altura abierta: desde el vacío del piso 4 se ve la cafetería.
	for z in [-3.0, -11.5, -20.0]:
		box("VigaHormigon", Vector3(0, 10.8, z), Vector3(23.6, 1.05, 0.65), materials.hormigon)
	for x in [-11.5, 8.6]:
		box("PilarHormigon", Vector3(x, 5.6, -0.75), Vector3(1.1, 11.2, 1.3), materials.hormigon, true)
		box("EnchufePilar", Vector3(x, 0.65, -0.08), Vector3(0.24, 0.14, 0.035), materials.steel)
	# Celosía lateral izquierda de madera con luz entre los listones.
	box("FondoCelosia", Vector3(-11.55, 2.9, -10.9), Vector3(0.12, 5.8, 21.3), materials.madera_local)
	for i in range(40):
		box("ListonVertical", Vector3(-11.36, 2.9, -0.75 - i * 0.54), Vector3(0.24, 5.8, 0.20), materials.madera_local)
		if i % 4 == 0:
			box("LuzEntreListones", Vector3(-11.21, 2.9, -0.91 - i * 0.54), Vector3(0.03, 5.3, 0.045), materials.lamp)
	box("FrenteGaleriaSuperior", Vector3(-9.9, 6.15, -11.3), Vector3(0.38, 0.55, 22.4), materials.hormigon)
	box("LosaGaleriaSuperior", Vector3(-10.8, 6.18, -11.3), Vector3(1.8, 0.25, 22.4), materials.hormigon)
	box("BarandaVidrioGaleria", Vector3(-9.86, 7.2, -11.3), Vector3(0.055, 1.7, 22.4), materials.glass)
	box("PasamanosGaleria", Vector3(-9.86, 8.07, -11.3), Vector3(0.085, 0.085, 22.4), materials.black)
	for z in [-0.2, -3.4, -6.6, -9.8, -13.0, -16.2, -19.4, -22.5]:
		box("PosteGaleria", Vector3(-9.86, 7.2, z), Vector3(0.085, 1.85, 0.085), materials.black)
	for x in [-10.7, 10.6]:
		box("BarraLateral", Vector3(x, 1.48, -12.1), Vector3(1.1, 0.13, 13.6), materials.crema, true)
		for z in [-6.0, -11.0, -17.8]:
			box("SoporteBarra", Vector3(x, 0.72, z), Vector3(0.09, 1.44, 0.09), materials.steel)
		for z in [-7.5, -10.2, -12.9, -15.6]:
			stool(Vector3(x - signf(x) * 1.2, 0, z))
	# Sala de espera al frente izquierdo y mesas bajas de madera.
	sofa(Vector3(-8.1, 0, -3.0), 0.0)
	sofa(Vector3(-9.7, 0, -5.8), PI / 2.0)
	box("MesaBajaMadera", Vector3(-6.8, 0.48, -5.1), Vector3(2.3, 0.96, 1.65), materials.madera_local, true)
	box("MesaBajaEntrada", Vector3(3.8, 0.45, -2.8), Vector3(1.7, 0.90, 1.4), materials.madera_local, true)
	for p in [Vector3(-10.1, 0, -0.3), Vector3(-7.8, 0, -0.3), Vector3(4.0, 0, -0.4), Vector3(6.35, 0, -0.4), Vector3(8.9, 0, -6.2)]:
		planter(p)
	# Mesas paralelas con sillas negras de asiento naranja; eje central libre.
	for x in [-5.1, 4.1]:
		for z in [-8.6, -12.7, -16.8]:
			dining_table(Vector3(x, 0, z))
	# Mostrador de venta al fondo, estantería, bebidas y carta superior.
	var shop := group("MostradorYProductos", Vector3(0, 0, -20.4))
	box("FrenteMostradorMadera", Vector3(-0.8, 1.1, 0), Vector3(13.2, 2.2, 1.35), materials.madera_local, true, shop)
	box("CubiertaMostrador", Vector3(-0.8, 2.24, 0), Vector3(13.5, 0.17, 1.6), materials.black, true, shop)
	box("VitrinaVidrio", Vector3(-3.5, 2.9, 0), Vector3(5.2, 1.2, 1.15), materials.glass, false, shop)
	box("BaseVitrina", Vector3(-3.5, 2.36, 0), Vector3(5.2, 0.08, 1.15), materials.steel, false, shop)
	for x in [-5.7, -3.5, -1.3]:
		box("MarcoVitrina", Vector3(x, 2.95, 0.59), Vector3(0.045, 1.1, 0.045), materials.black, false, shop)
	box("CajaRegistradora", Vector3(3.8, 2.45, 0), Vector3(0.85, 0.35, 0.68), materials.black, false, shop)
	box("PantallaCaja", Vector3(3.8, 2.87, -0.14), Vector3(0.9, 0.55, 0.09), materials.menu, false, shop)
	box("FondoEstanteria", Vector3(-0.8, 3.0, -2.1), Vector3(13.3, 5.7, 0.16), materials.madera_local, false, shop)
	for y in [2.4, 3.5, 4.6]:
		box("RepisaProductos", Vector3(-0.8, y, -1.78), Vector3(13.2, 0.09, 0.65), materials.black, false, shop)
		for i in range(25):
			var product_mat: Material = [materials.red, materials.green, materials.yellow, materials.blue, materials.white][i % 5]
			cylinder("Bebida", Vector3(-7.0 + i * 0.51, y + 0.32, -1.75), 0.14, 0.55, product_mat, shop)
			cylinder("TapaBebida", Vector3(-7.0 + i * 0.51, y + 0.62, -1.75), 0.095, 0.055, materials.white, shop)
	for i in range(5):
		var x: float = -6.0 + i * 2.55
		box("PanelMenu", Vector3(x, 6.7, -2.0), Vector3(2.45, 1.55, 0.14), materials.menu, false, shop)
		label_on(shop, "CategoriaMenu", ["CAFÉ", "SÁNDWICHES", "COLACIONES", "BEBIDAS", "SNACKS"][i], Vector3(x, 7.12, -1.91), 0, Color.WHITE, 0.0032)
		label_on(shop, "DetalleMenu", "Duoc UC\nPide en caja", Vector3(x, 6.53, -1.91), 0, Color(0.95, 0.72, 0.39), 0.0027)
		cylinder("FotoPlatoMenu", Vector3(x, 6.05, -1.89), 0.25, 0.03, materials.crema, shop).rotation.x = PI / 2.0
	box("FondoRotulo", Vector3(-0.8, 8.1, -2.0), Vector3(8.5, 0.95, 0.12), materials.madera_local, false, shop)
	label_on(shop, "RotuloLocal", "puntoBreak", Vector3(-0.8, 8.12, -1.90), 0, Color(1.0, 0.39, 0.11), 0.011)
	box("Refrigerador", Vector3(9.55, 2.45, -21.7), Vector3(2.7, 4.9, 1.6), materials.white, true)
	box("PuertaRefrigerador", Vector3(9.55, 2.6, -20.87), Vector3(2.4, 3.9, 0.08), materials.glass)
	for row in range(5):
		for col in range(4):
			cylinder("ProductoRefrigerado", Vector3(8.65 + col * 0.6, 0.9 + row * 0.77, -20.99), 0.16, 0.58, materials.green if col % 2 else materials.red)
	box("PapeleraLocal", Vector3(7.6, 0.8, -18.2), Vector3(0.9, 1.6, 0.9), materials.black, true)
	# Mampara de la sala vecina visible a la derecha de la fotografía.
	box("MamparaSala304", Vector3(11.55, 3.65, -8.0), Vector3(0.07, 7.3, 13.2), materials.glass, true)
	for z in [-1.4, -5.8, -10.2, -14.6]:
		box("MarcoMampara304", Vector3(11.48, 3.65, z), Vector3(0.13, 7.3, 0.10), materials.black)
	box("Placa304", Vector3(11.36, 3.7, -2.4), Vector3(0.035, 0.65, 1.25), materials.white)
	label_on(self, "Numero304", "304", Vector3(11.32, 3.7, -2.4), -PI / 2, Color.BLACK, 0.008)
	for i in range(6):
		var x := -8.0 + i * 0.27
		pipe(Vector3(x, 10.13, -0.2), Vector3(x, 10.13, -22.7), 0.07)
	for z in [-3.0, -11.5, -20.0]:
		pipe(Vector3(-10.4, 10.12, z), Vector3(10.4, 10.12, z), 0.065)
	for x in [-8.0, 7.5]:
		for z in [-3.0, -10.5, -18.0]:
			box("LuminariaLineal", Vector3(x, 9.8, z), Vector3(0.12, 0.08, 2.4), materials.lamp)
			var light := OmniLight3D.new()
			light.name = "LuzLocal"
			light.position = Vector3(x, 7.8, z)
			light.light_color = Color(1.0, 0.86, 0.68)
			light.light_energy = 2.3
			light.omni_range = 15.0
			owned(light, self)
	extend_back_to_wall()
	set_meta("profundidad", LOCAL_DEPTH)
	set_meta("referencia", "WhatsApp Image 2026-10-13 at 12.17.40.jpeg")
	set_meta("entrada_global", Vector3(69.3, 23.985, -109.85))
	return {"nodes": find_children("*", "", true, false).size(), "mesas": 6, "piso": 3}

func extend_back_to_wall() -> void:
	# Amplía el recinto desde su entrada, conservando las medidas del mobiliario.
	var factor := LOCAL_DEPTH / 23.0
	var longitudinal := ["BaldosasLocal", "FondoCelosia", "FrenteGaleriaSuperior", "LosaGaleriaSuperior", "BarandaVidrioGaleria", "PasamanosGaleria", "MamparaSala304"]
	for child in get_children():
		if not child is Node3D:
			continue
		child.position.z *= factor
		if child is MeshInstance3D and str(child.name) in longitudinal:
			var stretched := child.mesh.duplicate() as BoxMesh
			stretched.size.z *= factor
			child.mesh = stretched
			for collision in child.find_children("*", "CollisionShape3D", true, false):
				var stretched_shape := collision.shape.duplicate() as BoxShape3D
				stretched_shape.size.z *= factor
				collision.shape = stretched_shape
		elif child is MeshInstance3D and str(child.name).begins_with("TuberiaVista"):
			var tube := child.mesh as CylinderMesh
			if tube.height > 20.0 and absf(child.position.x) > 6.0:
				var stretched_tube := tube.duplicate() as CylinderMesh
				stretched_tube.height *= factor
				child.mesh = stretched_tube

func pipe(a: Vector3, b: Vector3, radius: float) -> void:
	var node := cylinder("TuberiaVista", (a + b) * 0.5, radius, a.distance_to(b), materials.hormigon)
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func sofa(p: Vector3, angle: float) -> void:
	var node := group("SillonGris", p)
	node.rotation.y = angle
	box("BaseSillon", Vector3(0, 0.57, 0), Vector3(3.6, 0.8, 1.7), materials.tapizado, true, node)
	box("Respaldo", Vector3(0, 1.27, -0.72), Vector3(3.6, 1.0, 0.34), materials.tapizado, true, node)
	for x in [-1.68, 1.68]:
		box("Brazo", Vector3(x, 0.96, 0), Vector3(0.28, 0.75, 1.7), materials.tapizado, true, node)
	for x in [-1.1, 0.0, 1.1]:
		box("Cojin", Vector3(x, 1.03, 0.12), Vector3(1.04, 0.18, 1.24), materials.tapizado, false, node)
	for x in [-1.5, 1.5]:
		for z in [-0.6, 0.6]:
			cylinder("PataSillon", Vector3(x, 0.14, z), 0.045, 0.28, materials.madera_local, node)

func planter(p: Vector3) -> void:
	var node := group("JardineraNegra", p)
	box("Macetero", Vector3(0, 0.9, 0), Vector3(2.1, 1.8, 1.65), materials.black, true, node)
	box("Tierra", Vector3(0, 1.82, 0), Vector3(1.9, 0.04, 1.45), materials.tierra, false, node)
	for i in range(9):
		var angle := i * TAU / 9.0
		var tip := Vector3(cos(angle) * (0.8 + (i % 3) * 0.32), 2.8 + (i % 4) * 0.33, sin(angle) * 0.95)
		var stem := cylinder("Tallo", (Vector3(0, 1.75, 0) + tip) * 0.5, 0.027, Vector3(0, 1.75, 0).distance_to(tip), materials.green, node)
		stem.quaternion = Quaternion(Vector3.UP, (tip - Vector3(0, 1.75, 0)).normalized())
		leaf(node, tip, angle)

func leaf(parent: Node3D, p: Vector3, angle: float) -> void:
	# Lámina orgánica con lóbulos y nervio central, en lugar de cajas verdes.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for j in range(9):
		var t := j / 8.0
		var width := sin(t * PI) * (0.48 if j % 2 == 0 else 0.32)
		for side in [-1.0, 1.0]:
			vertices.append(Vector3(side * width, sin(t * PI) * 0.12, -t * 1.3))
			normals.append(Vector3.UP)
	for j in range(8):
		var k := j * 2
		indices.append_array(PackedInt32Array([k, k + 2, k + 1, k + 1, k + 2, k + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.name = "HojaMonstera"
	node.mesh = mesh
	node.material_override = materials.hoja
	node.position = p
	node.rotation = Vector3(-0.24, angle, 0)
	owned(node, parent)
	box("NervioHoja", Vector3(0, 0.06, -0.55), Vector3(0.018, 0.02, 1.1), materials.green, false, node)

func stool(p: Vector3) -> void:
	box("AsientoTaburete", p + Vector3(0, 1.0, 0), Vector3(0.65, 0.12, 0.65), materials.crema, true)
	for x in [-0.25, 0.25]:
		for z in [-0.25, 0.25]:
			box("PataTaburete", p + Vector3(x, 0.5, z), Vector3(0.035, 1.0, 0.035), materials.steel)

func dining_table(p: Vector3) -> void:
	var table := group("MesaComedor", p)
	box("Cubierta", Vector3(0, 1.55, 0), Vector3(3.0, 0.13, 2.3), materials.crema, true, table)
	for x in [-1.2, 1.2]:
		for z in [-0.88, 0.88]:
			box("PataMesa", Vector3(x, 0.76, z), Vector3(0.055, 1.52, 0.055), materials.black, false, table)
	for x in [-0.82, 0.82]:
		for side in [-1.0, 1.0]:
			var chair_node := group("SillaNegraNaranja", p + Vector3(x, 0, side * 1.78))
			chair_node.rotation.y = 0.0 if side > 0 else PI
			box("Asiento", Vector3(0, 0.85, 0), Vector3(0.86, 0.14, 0.86), materials.naranja, true, chair_node)
			for leg_x in [-0.36, 0.36]:
				for leg_z in [-0.36, 0.36]:
					box("PataSilla", Vector3(leg_x, 0.42, leg_z), Vector3(0.035, 0.84, 0.035), materials.black, false, chair_node)
			for back_x in [-0.36, 0.36]:
				box("MarcoRespaldo", Vector3(back_x, 1.3, 0.37), Vector3(0.035, 1.1, 0.035), materials.black, false, chair_node)
			box("TravesanoRespaldo", Vector3(0, 1.84, 0.37), Vector3(0.75, 0.035, 0.035), materials.black, false, chair_node)
			box("Respaldo", Vector3(0, 1.43, 0.37), Vector3(0.68, 0.28, 0.055), materials.black, true, chair_node)
