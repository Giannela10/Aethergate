@tool
extends Node3D
# Constructor manual de detalles visuales, guardados como nodos nativos.
# No ejecuta generación durante la partida ni altera GameplayManager.
var metal: Material
var concrete: Material
var grass: Material
var glass: Material

func refine_casino_side() -> String:
	var campus := get_parent()
	var casino := campus.get_node("Piso1/Casino")
	var old := get_node_or_null("CostadoCasinoReferencia")
	if old:
		remove_child(old)
		old.free()
	var details := group_node("CostadoCasinoReferencia")
	var cladding: Material = load("res://materials/entrance/MAT_Wood_Cladding.tres")
	metal = load("res://materials/entrance/MAT_Metal_Dark.tres")
	for title in ["ParedDerechaFondo","ParedDerechaFrente"]:
		casino.get_node(title).material = cladding
	var dark := StandardMaterial3D.new()
	dark.resource_name = "MAT_Vidrio_Acceso_Casino"
	dark.albedo_color = Color(0.075,0.105,0.11,0.68)
	dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark.cull_mode = BaseMaterial3D.CULL_DISABLED
	dark.roughness = 0.24
	dark.metallic = 0.25
	ResourceSaver.save(dark,"res://materials/entrance/MAT_Vidrio_Acceso_Casino.tres")
	casino.get_node("DintelEntradaVidrio").material = dark
	for leaf in ["HojaIzquierda","HojaDerecha"]:
		casino.get_node("EntradaVidrio/"+leaf+"/Cristal").material_override = dark
	var rects := [Vector4(-112,-96,10.3,10.95),Vector4(-108,-80,8.8,9.45),Vector4(-113,-101,7.2,7.85),Vector4(-104,-90,5.7,6.4),Vector4(-111,-98,3.8,4.5),Vector4(-100,-84,2.1,2.8),Vector4(-112,-104,0.85,1.5)]
	var window: Material = load("res://materials/entrance/MAT_Window_Dark.tres")
	for i in rects.size():
		var r: Vector4 = rects[i]
		var z := (r.x+r.y)*0.5
		var y := (r.z+r.w)*0.5
		box(details,"VentanaHorizontal"+str(i+1),Vector3(-32.235,y,z),Vector3(0.045,r.w-r.z,r.y-r.x),window)
		for yy in [r.z,r.w]:
			box(details,"MarcoVentana"+str(i)+"_"+str(yy),Vector3(-32.20,yy,z),Vector3(0.09,0.06,r.y-r.x+0.1),metal)
		for zz in [r.x,r.y]:
			box(details,"JambaVentana"+str(i)+"_"+str(zz),Vector3(-32.20,y,zz),Vector3(0.09,r.w-r.z,0.06),metal)
	for z in [-119.0,-116.5,-114.0]:
		box(details,"MontanteAcceso"+str(z),Vector3(-32.20,6,z),Vector3(0.16,12,0.12),metal)
	for y in [3.3,6.0,9.0,11.9]:
		box(details,"TravesanoAcceso"+str(y),Vector3(-32.20,y,-116.5),Vector3(0.16,0.10,5.0),metal)
	return "Costado del casino revestido, siete ventanas horizontales y acceso acristalado alto."


func group_node(title: String) -> Node3D:
	var n := Node3D.new()
	n.name = title
	add_child(n)
	n.owner = owner
	return n

func box(parent: Node3D, title: String, p: Vector3, s: Vector3, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = s
	n.mesh = mesh
	n.material_override = material
	n.position = p
	parent.add_child(n)
	n.owner = owner
	return n

func repeated(parent: Node3D, title: String, size_value: Vector3, positions: Array, material: Material) -> void:
	var n := MultiMeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = size_value
	mesh.material = material
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = positions.size()
	for i in positions.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
	n.multimesh = mm
	parent.add_child(n)
	n.owner = owner

func signage(parent: Node3D, title: String, text_value: String, p: Vector3, pixel: float) -> void:
	var n := Label3D.new()
	n.name = title
	n.text = text_value
	n.position = p
	n.font_size = 160
	n.pixel_size = pixel
	n.modulate = Color(0.97, 0.97, 0.93)
	n.outline_size = 0
	n.no_depth_test = false
	parent.add_child(n)
	n.owner = owner

func build_reference() -> Dictionary:
	if get_child_count() > 0:
		return {"status": "La fachada de referencia ya existe."}
	var root := get_parent()
	metal = load("res://materials/entrance/MAT_Metal_Dark.tres")
	concrete = load("res://materials/entrance/MAT_Columns_Concrete.tres")
	grass = load("res://materials/entrance/MAT_Grass.tres")
	glass = load("res://materials/entrance/MAT_Glass_Entrance.tres")
	root.get_node("Piso1/Front_Left").material_override = load("res://materials/entrance/MAT_Wood_Cladding.tres")
	root.get_node("Piso1/Front_Right").material_override = glass
	for path in ["Piso2/Front_Left piso 2", "Piso2/Front_Right2", "Piso 3/Front_Right3", "Piso 4/Front_Right3"]:
		root.get_node(path).material_override = load("res://materials/entrance/MAT_Facade_Glass_Duoc.tres")
	var facade := group_node("CelosiaMetalica")
	var vertical: Array = []
	for i in range(114):
		vertical.append(Vector3(-84.5 + i * 1.48, 29.8, -75.35))
	repeated(facade, "MontantesVerticales", Vector3(0.10, 35.4, 0.42), vertical, metal)
	var fine: Array = []
	for i in range(565):
		fine.append(Vector3(-84.5 + i * 0.299, 29.8, -75.47))
	repeated(facade, "VarillasCelosia", Vector3(0.028, 35.4, 0.09), fine, metal)
	var horizontal: Array = []
	for i in range(144):
		horizontal.append(Vector3(-0.3, 12.1 + i * 0.248, -75.25))
	repeated(facade, "LamasHorizontales", Vector3(169, 0.024, 0.11), horizontal, metal)
	for i in range(7):
		box(facade, "Travesano" + str(i), Vector3(-0.3, 12.2 + i * 5.85, -75.15), Vector3(169, 0.18, 0.28), metal)
	box(facade, "VigaInferiorHormigon", Vector3(-0.3, 11.85, -75.2), Vector3(169, 0.65, 1.5), concrete)
	var windows := group_node("VentanasHorizontales")
	var rects := [
		Vector4(-80, -62, 9.6, 10.2), Vector4(-70, -37, 10.5, 11.1),
		Vector4(-61, -35, 8.1, 8.8), Vector4(-78, -66, 7.9, 8.45),
		Vector4(-63, -42, 6.5, 7.1), Vector4(-63, -44, 4.2, 4.8),
		Vector4(-45, -34, 3.2, 3.9), Vector4(-71, -51, 1.9, 2.5),
		Vector4(-51, -34, 0.75, 1.35)
	]
	var dark_window: Material = load("res://materials/entrance/MAT_Window_Dark.tres")
	for i in rects.size():
		var r: Vector4 = rects[i]
		var x := (r.x + r.y) * 0.5
		var y := (r.z + r.w) * 0.5
		box(windows, "VidrioHorizontal" + str(i + 1), Vector3(x, y, -75.96), Vector3(r.y - r.x, r.w - r.z, 0.025), dark_window)
		for yy in [r.z, r.w]:
			box(windows, "MarcoHorizontal" + str(i) + str(yy), Vector3(x, yy, -75.91), Vector3(r.y - r.x + 0.08, 0.045, 0.08), metal)
	var curtain := group_node("VidrioDerecho")
	var grid: Array = []
	for i in range(17):
		grid.append(Vector3(36.1 + i * 3.0, 6, -75.85))
	repeated(curtain, "MontantesVidrio", Vector3(0.06, 12, 0.1), grid, metal)
	for y in [0.1, 3.0, 6.0, 9.0, 11.8]:
		box(curtain, "JuntaVidrio" + str(y), Vector3(60.2, y, -75.85), Vector3(48.3, 0.055, 0.1), metal)
	var signs := group_node("Letreros")
	signage(signs, "LogoDuocUC", "DuocUC", Vector3(-64, 25, -74.7), 0.055)
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color(0.96, 0.61, 0.08)
	yellow.roughness = 0.5
	var ground_sign := Label3D.new()
	ground_sign.name = "DuocUCAcceso"
	ground_sign.text = "DuocUC"
	ground_sign.font_size = 160
	ground_sign.pixel_size = 0.025
	ground_sign.position = Vector3(-29, 1.6, -70)
	ground_sign.modulate = yellow.albedo_color
	ground_sign.outline_size = 0
	signs.add_child(ground_sign)
	ground_sign.owner = owner
	var gardens := group_node("JardinesExteriores")
	box(gardens, "CespedIzquierdo", Vector3(-53, -1.415, -50), Vector3(57, 0.035, 16), grass)
	box(gardens, "CespedDerecho", Vector3(56, -1.415, -50), Vector3(49, 0.035, 16), grass)
	box(gardens, "CespedLateral", Vector3(76, -1.415, -67), Vector3(16, 0.035, 12), grass)
	var trunks := StandardMaterial3D.new()
	trunks.albedo_color = Color(0.28, 0.20, 0.12)
	trunks.roughness = 1
	for x in [-72.0, -49.0, 44.0, 67.0]:
		var tree := Node3D.new()
		tree.name = "Arbol" + str(int(x))
		gardens.add_child(tree)
		tree.owner = owner
		var trunk := MeshInstance3D.new()
		trunk.name = "Tronco"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.22
		cyl.height = 5.0
		trunk.mesh = cyl
		trunk.material_override = trunks
		trunk.position = Vector3(x, 1.08, -51)
		tree.add_child(trunk)
		trunk.owner = owner
		for j in range(3):
			var leaf := MeshInstance3D.new()
			leaf.name = "Copa" + str(j)
			var sphere := SphereMesh.new()
			sphere.radius = 1.7
			sphere.height = 3.4
			leaf.mesh = sphere
			leaf.material_override = grass
			leaf.position = Vector3(x + sin(j * 2.1) * 1.0, 4.1 + j * 0.5, -51 + cos(j * 2.1))
			tree.add_child(leaf)
			leaf.owner = owner
	return {"celosia": vertical.size() + fine.size() + horizontal.size(), "ventanas": rects.size(), "jardines": 3, "arboles": 4, "status": "Construido"}

func complete_entrance() -> String:
	if get_node_or_null("PorticoEntrada"):
		return "El pórtico ya existe."
	concrete = load("res://materials/entrance/MAT_Columns_Concrete.tres")
	var portico := group_node("PorticoEntrada")
	box(portico, "VidrioSuperiorCentral", Vector3(1.9, 18, -76.04), Vector3(68.2, 11.6, 0.08), load("res://materials/entrance/MAT_Facade_Glass_Duoc.tres"))
	for x in [-26.0, -12.0, 2.0, 16.0, 30.0]:
		var column := box(portico, "Columna" + str(int(x)), Vector3(x, 5.9, -77), Vector3(1.2, 11.8, 1.5), concrete)
		var body := StaticBody3D.new()
		body.name = "Cuerpo"
		column.add_child(body)
		body.owner = owner
		var collision := CollisionShape3D.new()
		collision.name = "Colision"
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.2, 11.8, 1.5)
		collision.shape = shape
		body.add_child(collision)
		collision.owner = owner
	return "Pórtico con cinco columnas y paño superior completo."

