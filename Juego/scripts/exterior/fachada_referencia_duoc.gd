@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
# Constructor manual de detalles visuales, guardados como nodos nativos.
# No ejecuta generación durante la partida ni altera GameplayManager.
var metal: Material
var concrete: Material
var grass: Material
var glass: Material

func refine_casino_side() -> String:
	var campus := CampusNodes.campus(self)
	var casino := CampusNodes.obtener(campus, "Piso1/Casino")
	# El acceso termina en z=-114: el revestimiento no debe invadir su hueco.
	CampusNodes.obtener(casino, "ParedDerechaFrente").position.z = -95.25
	CampusNodes.obtener(casino, "ParedDerechaFrente").size.z = 37.5
	var old := CampusNodes.buscar(self, "CostadoCasinoReferencia")
	if old:
		remove_child(old)
		old.free()
	var details := group_node("CostadoCasinoReferencia")
	var cladding: Material = load("res://materials/entrance/MAT_Wood_Cladding.tres")
	metal = load("res://materials/entrance/MAT_Metal_Dark.tres")
	for title in ["ParedDerechaFondo","ParedDerechaFrente"]:
		CampusNodes.obtener(casino, title).material = cladding
	var dark := StandardMaterial3D.new()
	dark.resource_name = "MAT_Vidrio_Acceso_Casino"
	dark.albedo_color = Color(0.075,0.105,0.11,0.68)
	dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark.cull_mode = BaseMaterial3D.CULL_DISABLED
	dark.roughness = 0.24
	dark.metallic = 0.25
	ResourceSaver.save(dark,"res://materials/entrance/MAT_Vidrio_Acceso_Casino.tres")
	CampusNodes.obtener(casino, "DintelEntradaVidrio").material = dark
	for leaf in ["HojaIzquierda","HojaDerecha"]:
		CampusNodes.obtener(casino, "EntradaVidrio/"+leaf+"/Cristal").material_override = dark
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
	var root := CampusNodes.campus(self)
	metal = load("res://materials/entrance/MAT_Metal_Dark.tres")
	concrete = load("res://materials/entrance/MAT_Columns_Concrete.tres")
	grass = load("res://materials/entrance/MAT_Grass.tres")
	glass = load("res://materials/entrance/MAT_Glass_Entrance.tres")
	CampusNodes.obtener(root, "Piso1/Front_Left").material_override = load("res://materials/entrance/MAT_Wood_Cladding.tres")
	CampusNodes.obtener(root, "Piso1/Front_Right").material_override = glass
	for path in ["Piso2/Front_Left piso 2", "Piso2/Front_Right2", "Piso 3/Front_Right3", "Piso 4/Front_Right3"]:
		CampusNodes.obtener(root, path).material_override = load("res://materials/entrance/MAT_Facade_Glass_Duoc.tres")
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
	if CampusNodes.buscar(self, "PorticoEntrada"):
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


func adaptar_explanada_frontal() -> Dictionary:
	var old := CampusNodes.buscar(self, "ExplanadaFrontalReferenciaAerea")
	if old: old.free()
	var previous := CampusNodes.buscar(self, "JardinesExteriores")
	if previous: previous.visible = false
	var plaza := group_node("ExplanadaFrontalReferenciaAerea")
	var lawn: Material = load("res://materials/entrance/MAT_Grass.tres")
	var pavement: Material = load("res://materials/entrance/MAT_Piedra_Posterior.tres")
	var steel: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color(0.76,0.73,0.65)
	pale.roughness = 0.95
	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.5,0.57,0.57)
	roof_material.metallic = 0.3
	roof_material.roughness = 0.65
	# Long planted beds parallel to the building and the street.
	for span in [Vector2(-84,-20),Vector2(20,84)]:
		box(plaza,"Jardin"+str(span.x),Vector3((span.x+span.y)*0.5,0.11,-39),Vector3(span.y-span.x,0.02,56),lawn)
	box(plaza,"PlazaCentral",Vector3(0,0.13,-32),Vector3(38,0.04,43),pavement)
	box(plaza,"AndenFachada",Vector3(0,0.13,-69.5),Vector3(168,0.04,6),pavement)
	box(plaza,"VeredaFrontal",Vector3(0,0.13,-7),Vector3(168,0.04,6),pale)
	for side in [-1.0,1.0]:
		var points: Array[Vector3] = [Vector3(side*20,0.145,-42),Vector3(side*35,0.145,-58),Vector3(side*50,0.145,-38),Vector3(side*67,0.145,-56),Vector3(side*81,0.145,-30),Vector3(side*65,0.145,-15),Vector3(side*47,0.145,-29),Vector3(side*30,0.145,-14),Vector3(side*20,0.145,-24)]
		for i in range(points.size()-1):
			var a := points[i]
			var b := points[i+1]
			var path := box(plaza,"Sendero"+str(side)+"_"+str(i),(a+b)*0.5,Vector3(2.4,0.05,a.distance_to(b)+1.0),pale)
			path.look_at(b,Vector3.UP)
		for x in [32.0,55.0,77.0]:
			arbol_explanada(plaza,Vector3(side*x,0.15,-63),lawn)
		for x in [38.0,70.0]:
			arbol_explanada(plaza,Vector3(side*x,0.15,-13),lawn)
	for p in [Vector2(-75,-44),Vector2(-55,-36),Vector2(-35,-49),Vector2(35,-49),Vector2(55,-36),Vector2(75,-44),Vector2(-66,-20),Vector2(-40,-24),Vector2(40,-24),Vector2(66,-20)]:
		cubierta_explanada(plaza,Vector3(p.x,0.15,p.y),steel,roof_material)
	# A small square pavilion alongside the central pedestrian passage.
	var pavilion := Node3D.new()
	pavilion.name = "PabellonCentral"
	plaza.add_child(pavilion)
	pavilion.owner = owner
	pavilion.position = Vector3(-14,0.15,-43)
	box(pavilion,"Cubierta",Vector3(0,3.85,0),Vector3(10,0.18,8),roof_material)
	for x in [-4.6,4.6]:
		for z in [-3.6,3.6]:
			box(pavilion,"Pilar"+str(x)+str(z),Vector3(x,1.9,z),Vector3(0.18,3.8,0.18),steel)
	box(pavilion,"ModuloAtencion",Vector3(-1.6,1.2,1.7),Vector3(4,2.4,2.4),load("res://materials/entrance/MAT_Columns_Concrete.tres"))
	for node in plaza.find_children("*","MeshInstance3D",true,false):
		var title := str(node.name)
		if title.begins_with("Pilar") or title == "Tronco" or title == "ModuloAtencion":
			node.create_trimesh_collision()
			for child in node.find_children("*","",true,false): child.owner = owner
	plaza.set_meta("referencia","Captura aérea 2026-10-06 125949")
	plaza.set_meta("paso_torniquetes_libre",Rect2(-8,-36,22,15))
	return {"jardines":2,"cubiertas":10,"arboles":10,"plaza_central":true,"senderos_geometricos":true}

func arbol_explanada(parent: Node3D, p: Vector3, leaves: Material) -> void:
	var tree := Node3D.new()
	tree.name = "Arbol"+str(parent.get_child_count())
	parent.add_child(tree)
	tree.owner = owner
	tree.position = p
	var trunk := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.12
	cylinder.bottom_radius = 0.23
	cylinder.height = 4.2
	trunk.mesh = cylinder
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.26,0.2,0.14)
	trunk.material_override = bark
	trunk.position.y = 2.1
	tree.add_child(trunk)
	trunk.owner = owner
	for i in range(3):
		var crown := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 2.2
		sphere.height = 4.4
		crown.mesh = sphere
		crown.material_override = leaves
		crown.position = Vector3(sin(i*2.1)*0.8,4.4+i*0.35,cos(i*2.1)*0.8)
		tree.add_child(crown)
		crown.owner = owner

func cubierta_explanada(parent: Node3D, p: Vector3, steel: Material, roof_material: Material) -> void:
	var canopy := Node3D.new()
	canopy.name = "CubiertaJardin"+str(parent.get_child_count())
	parent.add_child(canopy)
	canopy.owner = owner
	canopy.position = p
	box(canopy,"BasePavimentada",Vector3(0,0,0),Vector3(5.5,0.03,5.5),load("res://materials/entrance/MAT_Terrace_Paving.tres"))
	for x in [-1.9,1.9]:
		for z in [-1.9,1.9]: box(canopy,"Pilar"+str(x)+str(z),Vector3(x,1.65,z),Vector3(0.08,3.3,0.08),steel)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector3] = [Vector3(-2.4,3.3,-2.4),Vector3(2.4,3.3,-2.4),Vector3(2.4,3.3,2.4),Vector3(-2.4,3.3,2.4)]
	for i in range(4):
		for vertex in [corners[i],Vector3(0,4.25,0),corners[(i+1)%4]]: surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "TechoPiramidal"
	mesh.mesh = surface.commit()
	mesh.material_override = roof_material
	canopy.add_child(mesh)
	mesh.owner = owner
	box(canopy,"Banco",Vector3(0,0.5,1.1),Vector3(2.3,0.14,0.45),steel)

func vista_explanada_frontal() -> Dictionary:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(0,125,-32)
	camera.look_at(Vector3(0,0,-40),Vector3.FORWARD)
	return {"view":"front forecourt"}

func agregar_guardias_torniquetes() -> Dictionary:
	var old := CampusNodes.buscar(self, "GuardiasTorniquetes")
	if old: old.free()
	var group := group_node("GuardiasTorniquetes")
	for i in range(2):
		var guard := CharacterBody3D.new()
		guard.name = "Guardia"+str(i+1)
		guard.set_script(load("res://scripts/exterior/guardia_torniquetes.gd"))
		var z := -25.0 if i == 0 else -35.0
		guard.patrol_points = [Vector3(12.8,0.1,z),Vector3(2,0.1,z),Vector3(-6.8,0.1,z),Vector3(2,0.1,z)]
		group.add_child(guard)
		guard.owner = owner
		guard.position = Vector3(12.8 if i == 0 else -6.8,0.1,z)
	return {"guardias":2,"chaleco":"rojo reflectante","saludo":"Buenos días","zona":"torniquetes"}
func agregar_guardia_caseta() -> Dictionary:
	var booth := CampusNodes.obtener(CampusNodes.campus(self), "Caseta") as Node3D
	var old := CampusNodes.buscar(booth, "PuestoRegistro")
	if old: old.free()
	var station := Node3D.new()
	station.name = "PuestoRegistro"
	booth.add_child(station)
	station.owner = owner
	var steel: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var wood: Material = load("res://materials/entrance/MAT_Madera_Biblioteca.tres")
	box(station,"Escritorio",Vector3(2.5,1.55,3.6),Vector3(2.6,0.12,1.2),wood)
	for x in [1.35,3.65]:
		for z in [3.1,4.1]: box(station,"Pata"+str(x)+str(z),Vector3(x,0.78,z),Vector3(0.08,1.56,0.08),steel)
	box(station,"Monitor",Vector3(2.5,2.15,3.85),Vector3(1.05,0.65,0.08),steel)
	box(station,"SoporteMonitor",Vector3(2.5,1.8,3.85),Vector3(0.08,0.4,0.08),steel)
	box(station,"BaseMonitor",Vector3(2.5,1.63,3.85),Vector3(0.5,0.035,0.3),steel)
	box(station,"Teclado",Vector3(2.5,1.63,3.3),Vector3(0.75,0.04,0.25),steel)
	box(station,"Mouse",Vector3(3.12,1.65,3.3),Vector3(0.12,0.07,0.2),steel)
	box(station,"TorreComputador",Vector3(3.4,0.47,3.7),Vector3(0.38,0.75,0.65),steel)
	var screen := StandardMaterial3D.new()
	screen.albedo_color = Color(0.025,0.12,0.17)
	screen.emission_enabled = true
	screen.emission = Color(0.07,0.25,0.3)
	box(station,"PantallaRegistro",Vector3(2.5,2.15,3.795),Vector3(0.95,0.54,0.012),screen)
	var label := Label3D.new()
	label.name = "RegistroPersonas"
	label.text = "REGISTRO DE INGRESO\nNombre   |   Hora\n________________\nEstudiantes y visitas"
	label.font_size = 28
	label.pixel_size = 0.0016
	label.position = Vector3(2.5,2.15,3.782)
	label.rotation.y = PI
	station.add_child(label)
	label.owner = owner
	var guard := CharacterBody3D.new()
	guard.name = "GuardiaRegistro"
	guard.set_script(load("res://scripts/exterior/guardia_torniquetes.gd"))
	guard.desk_mode = true
	station.add_child(guard)
	guard.owner = owner
	guard.position = Vector3(2.5,0.1,2.2)
	return {"guardia_adicional":1,"ubicacion":"Caseta","computador":"registro de personas","puesto_fijo":true}
