@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
# Mobiliario y acabados de terraza según referencia fotográfica.
var mats: Dictionary = {}
func material(key: String, color: Color, roughness: float = 0.85) -> void:
	var m := StandardMaterial3D.new()
	m.resource_name = "MAT_Terrace_" + key
	m.albedo_color = color
	m.roughness = roughness
	mats[key] = m

func group_node(title: String, p: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = title
	n.position = p
	add_child(n)
	n.owner = owner
	return n

func geometry(parent: Node3D, title: String, mesh: Mesh, p: Vector3, key: String, shape: Shape3D = null) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	n.mesh = mesh
	n.position = p
	n.material_override = mats[key]
	parent.add_child(n)
	n.owner = owner
	if shape:
		var body := StaticBody3D.new()
		body.name = "Cuerpo"
		n.add_child(body)
		body.owner = owner
		var collision := CollisionShape3D.new()
		collision.name = "Colision"
		collision.shape = shape
		body.add_child(collision)
		collision.owner = owner
	return n

func box(parent: Node3D, title: String, p: Vector3, size_value: Vector3, key: String, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var shape: BoxShape3D
	if solid:
		shape = BoxShape3D.new()
		shape.size = size_value
	return geometry(parent, title, mesh, p, key, shape)

func cylinder(parent: Node3D, title: String, p: Vector3, radius: float, height: float, key: String, solid: bool = false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	var shape: CylinderShape3D
	if solid:
		shape = CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
	return geometry(parent, title, mesh, p, key, shape)

func build() -> Dictionary:
	if get_child_count() > 0:
		return {"status": "Terraza ya ajustada"}
	material("AzulSombrilla", Color(0.018, 0.035, 0.30))
	material("RojoSilla", Color(0.34, 0.035, 0.035))
	material("Metal", Color(0.045, 0.05, 0.055), 0.55)
	material("Cesped", Color(0.18, 0.29, 0.14), 1)
	material("MaderaOscura", Color(0.43, 0.29, 0.15))
	mats["Madera"] = load("res://materials/entrance/MAT_Auditorium_Plywood.tres")
	var terrace := get_parent()
	var old := CampusNodes.obtener(terrace, "PuestosPicnic")
	terrace.remove_child(old)
	old.queue_free()
	var floor_node := CampusNodes.obtener(terrace.get_parent(), "Building_Floor Piso 5") as MeshInstance3D
	floor_node.material_override = load("res://materials/entrance/MAT_Terrace_Paving.tres")
	for n in CampusNodes.obtener(terrace, "CercaVidrio").find_children("*", "CSGBox3D", true, false):
		if str(n.name).begins_with("Panel"):
			n.material = load("res://materials/entrance/MAT_Glass_Entrance.tres")
		else:
			n.material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	# Muro acristalado existente del fondo de la terraza.
	for title in ["Delantera_piso 6", "Delantera_piso 6a", "MeshInstance3D", "Delantera_piso 5a3", "Delantera_piso 5a4"]:
		CampusNodes.obtener(terrace.get_parent(), title).material_override = load("res://materials/entrance/MAT_Glass_Entrance.tres")
	var facade := group_node("MarcosVidrio")
	for i in range(57):
		box(facade, "Montante" + str(i), Vector3(-84 + i * 3, 5.9, -121.85), Vector3(0.08, 11.8, 0.08), "Metal")
	for y in [0.1, 3.0, 6.0, 9.0, 11.7]:
		box(facade, "Junta" + str(y), Vector3(0, y, -121.85), Vector3(168, 0.07, 0.08), "Metal")
	# Mesas altas de carrete con sombrillas, dejando un corredor junto a la baranda.
	for i in range(10):
		var x := -72.0 + i * 16
		var n := group_node("SombrillaMesa%02d" % (i + 1), Vector3(x, 0, -105))
		cylinder(n, "CarreteCentral", Vector3(0, 0.62, 0), 0.72, 1.24, "Madera", true)
		cylinder(n, "BaseCarrete", Vector3(0, 0.08, 0), 1.15, 0.16, "Madera")
		cylinder(n, "TableroCircular", Vector3(0, 1.32, 0), 1.4, 0.16, "Madera", true)
		cylinder(n, "PosteSombrilla", Vector3(0, 2.0, 0), 0.055, 4.0, "MaderaOscura")
		var canopy := CylinderMesh.new()
		canopy.top_radius = 0.10
		canopy.bottom_radius = 3.5
		canopy.height = 0.75
		canopy.radial_segments = 8
		canopy.cap_bottom = false
		var fabric: StandardMaterial3D = mats["AzulSombrilla"]
		fabric.cull_mode = BaseMaterial3D.CULL_DISABLED
		geometry(n, "TelaOctogonal", canopy, Vector3(0, 4.05, 0), "AzulSombrilla")
		for j in range(8):
			var angle := j * TAU / 8
			var rib := box(n, "Varilla" + str(j), Vector3(sin(angle) * 1.7, 4.0, cos(angle) * 1.7), Vector3(0.025, 0.025, 3.45), "MaderaOscura")
			rib.rotation = Vector3(0.21, angle, 0)
	# Islas de césped con mesas de café y cuatro sillas.
	for i in range(7):
		var x := -66.0 + i * 22
		var island := group_node("ZonaCafe%02d" % (i + 1), Vector3(x, 0, -115))
		var grass_mesh := CylinderMesh.new()
		grass_mesh.top_radius = 3.1
		grass_mesh.bottom_radius = 3.1
		grass_mesh.height = 0.02
		var lawn := geometry(island, "IslaCesped", grass_mesh, Vector3(0, 0.025, 0), "Cesped")
		lawn.scale.x = 1.6
		cylinder(island, "MesaNegra", Vector3(0, 1.1, 0), 0.85, 0.09, "Metal", true)
		cylinder(island, "PieMesa", Vector3(0, 0.55, 0), 0.08, 1.1, "Metal")
		for j in range(4):
			var angle := j * PI / 2
			var chair := Node3D.new()
			chair.name = "SillaRoja" + str(j + 1)
			chair.position = Vector3(sin(angle) * 1.5, 0, cos(angle) * 1.5)
			chair.rotation.y = angle
			island.add_child(chair)
			chair.owner = owner
			box(chair, "Asiento", Vector3(0, 0.60, 0), Vector3(0.72, 0.10, 0.72), "RojoSilla", true)
			box(chair, "Respaldo", Vector3(0, 1.0, 0.32), Vector3(0.75, 0.75, 0.10), "RojoSilla", true)
			for side in [-1, 1]:
				for depth in [-1, 1]:
					box(chair, "Pata" + str(side) + str(depth), Vector3(side * 0.27, 0.28, depth * 0.27), Vector3(0.055, 0.56, 0.055), "Metal")
	return {"sombrillas_y_carretes": 10, "mesas_cafe": 7, "sillas_rojas": 28, "islas_cesped": 7}
