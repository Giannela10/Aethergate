@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
# Acabados del pasillo de ascensores y pavimento compartido entre niveles.
var mats: Dictionary = {}

func group_node(title: String) -> Node3D:
	var n := Node3D.new()
	n.name = title
	add_child(n)
	n.owner = owner
	return n

func box(parent: Node3D, title: String, p: Vector3, size_value: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = size_value
	n.mesh = mesh
	n.material_override = mat
	n.position = p
	parent.add_child(n)
	n.owner = owner
	if solid:
		var body := StaticBody3D.new()
		body.name = "Cuerpo"
		n.add_child(body)
		body.owner = owner
		var collision := CollisionShape3D.new()
		collision.name = "Colision"
		var shape := BoxShape3D.new()
		shape.size = size_value
		collision.shape = shape
		body.add_child(collision)
		collision.owner = owner
	return n

func apply_all_floors() -> Dictionary:
	var root := get_parent().get_parent()
	var mat: Material = load("res://materials/entrance/MAT_Interior_Floor_Dark.tres")
	var applied: Array = []
	for level in root.get_children():
		if not str(level.name).begins_with("Piso") and str(level.name) not in ["AccesosAscensores", "AjusteFondoAscensores", "AscensoresEstudiantiles"]:
			continue
		for n in level.find_children("*", "GeometryInstance3D", true, false):
			var title := str(n.name)
			var is_floor := title.begins_with("Building_Floor") and not title.contains("Techo")
			is_floor = is_floor or title.begins_with("Losa") and not title.contains("Techo")
			is_floor = is_floor or title in ["PisoCoordinacion", "RellenoFrenteEscalera", "Piso"]
			is_floor = is_floor or title.begins_with("UmbralPiso") or title.begins_with("Step") or title.begins_with("Escalera Norte")
			if not is_floor:
				continue
			if n is MeshInstance3D:
				n.material_override = mat
			elif n is CSGBox3D:
				n.material = mat
			else:
				continue
			applied.append(str(root.get_path_to(n)))
	var report := FileAccess.open("res://materials/entrance/pisos_material_oscuro.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(applied, "\t"))
	return {"superficies": applied.size(), "material": "MAT_Interior_Floor_Dark"}

func build() -> Dictionary:
	var result := apply_all_floors()
	if get_child_count() > 0:
		return result
	var wood: Material = load("res://materials/entrance/MAT_Corridor_Cladding_Light.tres")
	var glass: Material = load("res://materials/entrance/MAT_Glass_Entrance.tres")
	var metal: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var window: Material = load("res://materials/entrance/MAT_Window_Dark.tres")
	for title in ["Wall_Right piso 2 c3", "Wall_Right piso 2 c4", "Delantera_piso 2a", "Delantera_piso 2b"]:
		CampusNodes.obtener(get_parent(), title).material_override = wood
	var openings := group_node("VentanasHorizontales")
	for x in [-48.0, 50.0]:
		for y in [13.5, 16.4]:
			box(openings, "Vidrio" + str(x) + str(y), Vector3(x, y, -140.57), Vector3(9.0, 1.1, 0.04), window)
			for yy in [y - 0.59, y + 0.59]:
				box(openings, "Marco" + str(x) + str(yy), Vector3(x, yy, -140.60), Vector3(9.15, 0.07, 0.08), metal)
	for y in [13.5, 16.4]:
		box(openings, "VentanaCostado" + str(y), Vector3(-25.29, y, -145), Vector3(0.04, 1.1, 5.0), window)
	var rails := group_node("BarandasAtrio")
	for i in range(9):
		var x := -16.0 + i * 3.6
		box(rails, "VidrioFrente" + str(i), Vector3(x, 12.86, -133.0532), Vector3(3.5, 1.6, 0.06), glass, true)
		box(rails, "PosteFrente" + str(i), Vector3(x - 1.8, 12.91, -133.0532), Vector3(0.07, 1.7, 0.07), metal)
	box(rails, "PasamanosFrente", Vector3(-1.6, 13.75, -133.0532), Vector3(32.4, 0.07, 0.08), metal)
	for i in range(8):
		var z := -120.2 + i * 3.6
		box(rails, "VidrioPasillo" + str(i), Vector3(25.60, 12.86, z), Vector3(0.06, 1.6, 3.5), glass, true)
		box(rails, "PostePasillo" + str(i), Vector3(25.6, 12.91, z - 1.8), Vector3(0.07, 1.7, 0.07), metal)
	box(rails, "PasamanosPasillo", Vector3(25.6, 13.75, -107.6), Vector3(0.08, 0.07, 28.8), metal)
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color(0.22, 0.24, 0.24)
	concrete.roughness = 0.96
	var ceiling := group_node("TechoInstalaciones")
	for x in [-8.0, 8.0]:
		box(ceiling, "BandejaCables" + str(x), Vector3(x, 19.6, -141.7), Vector3(1.0, 0.08, 15.3), metal)
		for i in range(31):
			box(ceiling, "TravesanoBandeja" + str(x) + str(i), Vector3(x, 19.72, -149 + i * 0.5), Vector3(1.1, 0.12, 0.07), metal)
		for z in [-146.0, -139.0]:
			box(ceiling, "Suspensor" + str(x) + str(z), Vector3(x, 21.2, z), Vector3(0.05, 3.0, 0.05), metal)
		var pipe := MeshInstance3D.new()
		pipe.name = "Conducto" + str(x)
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.24
		cylinder.bottom_radius = 0.24
		cylinder.height = 14.8
		pipe.mesh = cylinder
		pipe.material_override = concrete
		pipe.position = Vector3(x + 2, 20.4, -142)
		pipe.rotation.x = PI / 2
		ceiling.add_child(pipe)
		pipe.owner = owner
	var luminous := StandardMaterial3D.new()
	luminous.albedo_color = Color(0.95, 0.93, 0.86)
	luminous.emission_enabled = true
	luminous.emission = Color(1, 0.92, 0.78)
	luminous.emission_energy_multiplier = 2.0
	for x in [-16.0, 0.0, 16.0]:
		for z in [-146.0, -136.0]:
			box(ceiling, "Luminaria" + str(x) + str(z), Vector3(x, 19.2, z), Vector3(3.6, 0.06, 0.12), luminous)
			var light := OmniLight3D.new()
			light.name = "LuzPasillo" + str(x) + str(z)
			light.position = Vector3(x, 18.8, z)
			light.light_color = Color(1, 0.94, 0.84)
			light.light_energy = 0.9
			light.omni_range = 12
			ceiling.add_child(light)
			light.owner = owner
	var sign_label := Label3D.new()
	sign_label.name = "IndicacionAscensores"
	sign_label.text = "ASCENSORES  ·  PISO 2"
	sign_label.position = Vector3(0, 16.2, -149.3)
	sign_label.font_size = 72
	sign_label.pixel_size = 0.006
	sign_label.modulate = Color(0.1, 0.2, 0.17)
	ceiling.add_child(sign_label)
	sign_label.owner = owner
	result["zona"] = "Pasillo de ascensores del piso 2"
	result["barandas_vidrio"] = 17
	return result
