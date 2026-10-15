@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
var mats: Dictionary = {}
const LEVELS: Array[float] = [0.0,12.058385849,23.967668533,35.674415588,47.974849701,60.158504486,71.942184448,83.913551331]

func mat(key: String, color: Color, rough: float = 0.7) -> Material:
	var material := StandardMaterial3D.new()
	material.resource_name = key
	material.albedo_color = color
	material.roughness = rough
	mats[key] = material
	ResourceSaver.save(material,"res://materials/entrance/"+key+".tres")
	return material

func group(parent: Node, title: String, clear: bool = true) -> Node3D:
	var old := CampusNodes.buscar(parent, title)
	if old and clear:
		parent.remove_child(old)
		old.free()
	elif old:
		return old
	var n := Node3D.new()
	n.name = title
	parent.add_child(n)
	n.owner = get_tree().edited_scene_root
	return n

func box(parent: Node3D, title: String, pos: Vector3, size: Vector3, material: Material, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	n.position = pos
	var shape := BoxMesh.new()
	shape.size = size
	n.mesh = shape
	n.material_override = material
	parent.add_child(n)
	n.owner = get_tree().edited_scene_root
	if solid:
		var body := StaticBody3D.new()
		n.add_child(body)
		body.owner = n.owner
		var collision := CollisionShape3D.new()
		var c := BoxShape3D.new()
		c.size = size
		collision.shape = c
		body.add_child(collision)
		collision.owner = n.owner
	return n

func label(parent: Node3D, title: String, content: String, pos: Vector3, angle: float = 0.0, pixel: float = 0.005) -> Label3D:
	var n := Label3D.new()
	n.name = title
	n.text = content
	n.font_size = 56
	n.pixel_size = pixel
	n.position = pos
	n.rotation.y = angle
	n.modulate = Color(0.13,0.16,0.18)
	parent.add_child(n)
	n.owner = get_tree().edited_scene_root
	return n

func light(parent: Node3D, pos: Vector3, range_value: float = 10.0) -> void:
	var n := OmniLight3D.new()
	n.name = "Luz"
	n.position = pos
	n.light_color = Color(1,0.95,0.86)
	n.light_energy = 0.8
	n.omni_range = range_value
	parent.add_child(n)
	n.owner = get_tree().edited_scene_root

func init_mats() -> void:
	mats["cream"] = load("res://materials/entrance/MAT_Corridor_Cladding_Light.tres")
	mats["steel"] = load("res://materials/entrance/MAT_Acero_Inoxidable_Ascensor.tres")
	mats["black"] = load("res://materials/entrance/MAT_Metal_Dark.tres")
	mats["glass"] = load("res://materials/entrance/MAT_Vidrio_Panoramico_Ascensor.tres")
	mats["floor"] = load("res://materials/entrance/MAT_Interior_Floor_Dark.tres")
	mats["lamp"] = load("res://materials/entrance/MAT_Luz_Cabina.tres")
	mat("MAT_Madera_Biblioteca",Color(0.63,0.48,0.29))
	mats["wood"] = mats["MAT_Madera_Biblioteca"]
	mat("MAT_Meson_Biblioteca_Azul",Color(0.045,0.075,0.24))
	mats["blue"] = mats["MAT_Meson_Biblioteca_Azul"]
	mat("MAT_Puerta_Ascensor_Grafica",Color(0.86,0.86,0.82),0.35)
	mats["white"] = mats["MAT_Puerta_Ascensor_Grafica"]
	mat("MAT_Detalle_Amarillo_Duoc",Color(0.85,0.63,0.12))
	mats["yellow"] = mats["MAT_Detalle_Amarillo_Duoc"]

func build_elevator_lobbies() -> void:
	var campus := CampusNodes.campus(self)
	for n in campus.find_children("*","CSGBox3D",true,false):
		var title := str(n.name)
		if title.begins_with("ParedEntrePuertas") or title.begins_with("DintelAscensor") or title.begins_with("ParedP") or title.begins_with("DintelP") or title.begins_with("FrentePozo"):
			n.material = mats["cream"]
	var elevators := CampusNodes.obtener(campus, "AscensoresEstudiantiles")
	for floor_index in range(8):
		var lobby := CampusNodes.grupo_de_piso(self, "AscensoresTodosLosPisos/Piso" + str(floor_index+1), floor_index+1, "VestibuloAscensores")
		lobby.position.y = LEVELS[floor_index]
		for i in range(3):
			var x: float = -10+i*10
			for side in [-1,1]:
				box(lobby,"JambaInoxidable",Vector3(x+side*2.65,1.65,-149.43),Vector3(0.16,3.3,0.15),mats["steel"])
			box(lobby,"MarcoSuperior",Vector3(x,3.31,-149.43),Vector3(5.46,0.16,0.15),mats["steel"])
			box(lobby,"IndicadorNegro",Vector3(x,3.85,-149.38),Vector3(1.45,0.43,0.08),mats["black"])
			var display := label(lobby,"NumeroPiso",str(floor_index+1)+"  ▲",Vector3(x,3.85,-149.32),0,0.003)
			display.modulate = Color(0.62,0.9,0.73)
			box(lobby,"PanelLlamada",Vector3(x+3.1,1.5,-149.38),Vector3(0.25,0.62,0.08),mats["steel"])
			box(lobby,"BotonLlamada",Vector3(x+3.1,1.5,-149.325),Vector3(0.11,0.11,0.035),mats["black"])
			label(lobby,"PlacaPiso",str(floor_index+1),Vector3(x+3.15,2.55,-149.32),0,0.007)
			var lift := elevators.get_child(i)
			var gate := CampusNodes.obtener(lift, "PuertaPiso"+str(floor_index+1))
			CampusNodes.obtener(gate, "Panel").material_override = mats["white"]
			var art := group(gate,"GraficaDuoc")
			box(art,"FranjaInstitucional",Vector3(-1.8,1.55,0.067),Vector3(0.25,2.85,0.018),mats["blue"])
			box(art,"FranjaAmarilla",Vector3(-1.58,1.55,0.067),Vector3(0.055,2.85,0.019),mats["yellow"])
			var brand := label(art,"Marca","DuocUC",Vector3(0,2.1,0.072),0,0.009)
			brand.modulate = Color(0.045,0.075,0.24)
			label(art,"Texto","FORMACIÓN\nPARA EL FUTURO",Vector3(0,1.35,0.072),0,0.0035)
		for x in [-20.0,20.0]:
			var panel_x: float = -24.5 if x < 0 else x
			var panel_width: float = 3.5 if x < 0 else 5.0
			box(lobby,"RevestimientoCostado",Vector3(panel_x,2.2,-149.38),Vector3(panel_width,4.4,0.08),mats["cream"])
		# La salida de emergencia en X=-20.7 queda libre de carteles y paneles.
		box(lobby,"CartelPlano",Vector3(-24,2.15,-147.6),Vector3(2.5,3.6,0.14),mats["white"])
		box(lobby,"CabeceraPlano",Vector3(-24,3.8,-147.49),Vector3(2.5,0.3,0.06),mats["blue"])
		label(lobby,"PlanoPisos","PLANO DE LOS PISOS\n\n"+str(floor_index+1)+"  USTED ESTÁ AQUÍ\n\nBIBLIOTECA · CASINO\nCOORDINACIÓN · AUDITORIO",Vector3(-24,2.3,-147.49),0,0.0028)
		for x in [-16.0,0.0,16.0]:
			box(lobby,"LuminariaPasillo",Vector3(x,5.6,-143),Vector3(3.4,0.06,0.12),mats["lamp"])
			light(lobby,Vector3(x,5.3,-142),11)
	set_meta("vestibulos_ascensores",8)

func build_ground_corridor() -> void:
	var campus := CampusNodes.campus(self)
	var corridor := group(CampusNodes.obtener(campus, "Piso1"),"AcabadosPasilloCoordinacion")
	for path in ["coodinacion","MeshInstance3D12","MeshInstance3D13","MeshInstance3D14"]:
		var n := CampusNodes.obtener(campus, "Piso1/"+path)
		n.material_override = mats["cream"]
	for x in [-25.0,-7.0,11.0,29.0,47.0,65.0]:
		box(corridor,"LuminariaLineal",Vector3(x,6.2,-128),Vector3(7.5,0.06,0.11),mats["lamp"])
		light(corridor,Vector3(x,5.7,-129),12)
		for i in range(12):
			box(corridor,"BandejaInstalaciones",Vector3(x-3+i*0.55,6.6,-134),Vector3(0.055,0.12,0.85),mats["black"])
	box(corridor,"CartelCoordinacion",Vector3(64,3,-122.38),Vector3(6,1.0,0.06),mats["blue"])
	var sign_label := label(corridor,"IndicacionCoordinacion","COORDINACIÓN  →",Vector3(64,3,-122.42),PI,0.006)
	sign_label.modulate = Color(0.92,0.94,0.93)
	var casino := CampusNodes.obtener(campus, "Piso1/Casino")
	CampusNodes.obtener(casino, "Letrero").hide()
	var entrance := group(casino,"AcabadosEntradaLateral")
	for z in [-119.12,-113.88]:
		box(entrance,"MarcoEntrada",Vector3(-32.22,1.6,z),Vector3(0.14,3.2,0.13),mats["steel"])
	box(entrance,"FranjaSobreEntrada",Vector3(-32.19,3.65,-116.5),Vector3(0.15,0.65,5.5),mats["cream"])
	label(entrance,"Casino","CASINO",Vector3(-32.08,3.65,-116.5),PI/2,0.007)
	for n in casino.find_children("Cristal","MeshInstance3D",true,false):
		n.material_override = mats["glass"]
	for n in casino.find_children("*","CSGBox3D",true,false):
		if str(n.name) in ["CubiertaMeson","Tablero"]:
			n.material = mats["wood"]
	box(entrance,"LuzEntrada",Vector3(-32.08,4.1,-116.5),Vector3(0.12,0.06,4.2),mats["lamp"])
	light(entrance,Vector3(-31,3.5,-116.5),8)

func chair(parent: Node3D, pos: Vector3, angle: float = 0.0) -> void:
	var n := group(parent,"Silla"+str(parent.get_child_count()),false)
	n.position = pos
	n.rotation.y = angle
	box(n,"Asiento",Vector3(0,0.75,0),Vector3(0.9,0.16,0.9),mats["blue"])
	box(n,"Respaldo",Vector3(0,1.18,0.42),Vector3(0.9,0.85,0.13),mats["blue"])
	box(n,"Base",Vector3(0,0.36,0),Vector3(0.65,0.7,0.65),mats["black"])

func automatic_door(parent: Node3D, pos: Vector3, angle: float = PI/2) -> void:
	var n := group(parent,"PuertaVidrio")
	n.position = pos
	n.rotation.y = angle
	n.set_script(load("res://scripts/compartidos/puerta_vidrio_salas.gd"))
	n.set("ancho",2.4)
	for side in [-1,1]:
		var leaf := AnimatableBody3D.new()
		leaf.name = "HojaIzquierda" if side == -1 else "HojaDerecha"
		leaf.position = Vector3(side*0.6,0,0)
		n.add_child(leaf)
		leaf.owner = get_tree().edited_scene_root
		box(leaf,"Cristal",Vector3(0,1.5,0),Vector3(1.18,3,0.06),mats["glass"])
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.18,3,0.06)
		collision.shape = shape
		collision.position.y = 1.5
		leaf.add_child(collision)
		collision.owner = leaf.owner
		box(leaf,"MarcoVertical",Vector3(side*0.56,1.5,0),Vector3(0.05,3,0.08),mats["steel"])
	box(n,"MarcoSuperior",Vector3(0,3.04,0),Vector3(2.55,0.1,0.1),mats["steel"])

func build_library() -> void:
	var library := CampusNodes.obtener(CampusNodes.campus(self), "Piso2/Biblioteca")
	CampusNodes.obtener(library, "Letrero").pixel_size = 0.005
	# Entrada en la pared que mira al pasillo posterior.
	var side_back := CampusNodes.obtener(library, "ParedDerechaFondo") as CSGBox3D
	side_back.size = Vector3(0.16,12,46.2)
	side_back.position = Vector3(-32.338,6,-99.6)
	var side_front := CampusNodes.obtener(library, "ParedDerechaFrente") as CSGBox3D
	side_front.size = Vector3(18.55,12,0.16)
	side_front.position = Vector3(-41.725,6,-122.7)
	var rear := CampusNodes.obtener(library, "ParedPosteriorVidrio") as CSGBox3D
	rear.size = Vector3(28.75,12,0.16)
	rear.position = Vector3(-70.375,6,-122.7)
	var lintel := CampusNodes.obtener(library, "DintelEntradaVidrio") as CSGBox3D
	lintel.size = Vector3(5,8.8,0.16)
	lintel.position = Vector3(-53.5,7.6,-122.7)
	for wall in [side_back,side_front,rear,lintel]:
		wall.material = mats["cream"]
	CampusNodes.obtener(library, "EntradaVidrio").position = Vector3(-53.5,0,-122.7)
	CampusNodes.obtener(library, "EntradaVidrio").rotation.y = 0
	CampusNodes.obtener(library, "Letrero").position = Vector3(-53.5,3.65,-122.82)
	CampusNodes.obtener(library, "Letrero").rotation.y = PI
	var old := CampusNodes.obtener(library, "SalasEstudio")
	for child in old.get_children():
		old.remove_child(child)
		child.free()
	# Six rooms along the rear wall marked in red.
	var height := 4.2
	for i in range(6):
		var room := group(old,"SalaEstudio"+str(i+1))
		var x0: float = -84.8+i*7.0
		var cx: float = x0+3.5
		var z0 := -122.4
		var front := -104.4
		box(room,"ParedLateral",Vector3(x0,height/2,-113.4),Vector3(0.12,height,18),mats["cream"],true)
		if i == 5:
			box(room,"ParedFinal",Vector3(x0+7.0,height/2,-113.4),Vector3(0.12,height,18),mats["cream"],true)
		box(room,"ParedFondo",Vector3(cx,height/2,z0),Vector3(7.0,height,0.12),mats["cream"],true)
		for side in [-1,1]:
			box(room,"FrenteVidriado",Vector3(cx+side*2.35,height/2,front),Vector3(2.3,height,0.09),mats["glass"],true)
		box(room,"Dintel",Vector3(cx,3.6,front),Vector3(2.4,1.2,0.1),mats["cream"],true)
		automatic_door(room,Vector3(cx,0,front),0)
		box(room,"TechoBox",Vector3(cx,4.25,-113.4),Vector3(7.0,0.1,18),mats["white"])
		box(room,"MesaEstudio",Vector3(cx,1.2,-114),Vector3(2.2,0.15,9),mats["wood"],true)
		for z in [-117.7,-110.3]:
			box(room,"PataMesa",Vector3(cx,0.6,z),Vector3(1.8,1.2,0.18),mats["black"],true)
		for z in [-117.3,-115.1,-112.9,-110.7]:
			chair(room,Vector3(cx-2.1,0,z),-PI/2)
			chair(room,Vector3(cx+2.1,0,z),PI/2)
		box(room,"Pizarra",Vector3(cx,2.4,-122.25),Vector3(4.3,1.7,0.08),mats["white"])
		label(room,"NumeroBox","BOX "+str(i+1),Vector3(cx,3.55,front+0.12),0,0.005)
		box(room,"Luminaria",Vector3(cx,4.13,-113.4),Vector3(0.13,0.05,8),mats["lamp"])
		light(room,Vector3(cx,3.7,-113.4),13)
		# Seis boxes sobre el costado largo marcado, con acceso desde el interior.
		var facing := Basis(Vector3.UP,-PI/2).scaled_local(Vector3(7.68/7.0,1,1))
		var target := Vector3(-41.478,0,-118.76+i*7.68)
		room.transform = Transform3D(facing,target-facing*Vector3(cx,0,-113.4))
	var finishes := group(library,"AcabadosReferencia")
	for title in ["AccesoEscalera","BarandaAccesoFrente","BarandaAccesoDerecha"]:
		var previous := CampusNodes.buscar(library, title)
		if previous:
			library.remove_child(previous)
			previous.free()
	# El costado exterior queda abierto hacia el atrio, según la referencia.
	# Reception inside the entrance, with the curved blue counter shown in the photo.
	box(finishes,"MesonAzulBiblioteca",Vector3(-41.2,0.88,-80.9),Vector3(7.6,1.76,1.8),mats["blue"],true)
	box(finishes,"CubiertaMeson",Vector3(-41.2,1.82,-80.9),Vector3(7.85,0.12,1.95),mats["wood"])
	var round_mesh := CylinderMesh.new()
	round_mesh.top_radius = 0.95
	round_mesh.bottom_radius = 0.95
	round_mesh.height = 1.76
	round_mesh.radial_segments = 32
	var curved := MeshInstance3D.new()
	curved.name = "ExtremoCurvoMeson"
	curved.mesh = round_mesh
	curved.position = Vector3(-45,0.88,-80.9)
	curved.material_override = mats["blue"]
	finishes.add_child(curved)
	curved.owner = get_tree().edited_scene_root
	box(finishes,"ZocaloMeson",Vector3(-41.2,0.13,-79.96),Vector3(7.65,0.2,0.04),mats["steel"])
	var motto := label(finishes,"TextoMeson","Cambia · IDEA · Crea",Vector3(-41.2,1.05,-79.97),0,0.006)
	motto.modulate = Color(0.87,0.69,0.31)
	box(finishes,"PantallaAtencion",Vector3(-40.5,2.15,-81.4),Vector3(1.15,0.6,0.08),mats["black"])
	chair(finishes,Vector3(-40.5,0,-82.7),PI)
	for x in [-43.2,-39.0]:
		box(finishes,"ProtectorVidrioMeson",Vector3(x,2.5,-80),Vector3(2.5,1.25,0.035),mats["glass"])
	# Trasladar el conjunto completo de recepción al centro del área pública.
	for furnishing in finishes.get_children():
		if furnishing is Node3D:
			furnishing.position += Vector3(-20.8,0,-17.1)
	# Lamella ceiling, batched to keep the scene tree compact.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var slat := BoxMesh.new()
	slat.size = Vector3(0.18,0.16,45.6)
	mm.mesh = slat
	mm.instance_count = 160
	for i in range(mm.instance_count):
		mm.set_instance_transform(i,Transform3D(Basis(),Vector3(-84.1+i*0.32,11.23,-99.55)))
	var ceiling := MultiMeshInstance3D.new()
	ceiling.name = "CieloListonesMadera"
	ceiling.multimesh = mm
	ceiling.material_override = mats["wood"]
	ceiling.visible = false
	var ceiling_mat := ShaderMaterial.new()
	ceiling_mat.shader = load("res://materials/entrance/cielo_listones_biblioteca.gdshader")
	ceiling_mat.resource_name = "MAT_Cielo_Listones_Biblioteca"
	ResourceSaver.save(ceiling_mat,"res://materials/entrance/MAT_Cielo_Listones_Biblioteca.tres")
	box(finishes,"FondoCieloMadera",Vector3(-58.55,11.38,-99.55),Vector3(51.5,0.06,45.6),ceiling_mat)
	box(finishes,"RevestimientoFrenteBiblioteca",Vector3(-58.55,5.6,-76.72),Vector3(51.5,11.2,0.08),mats["cream"])
	var skyglass := mat("MAT_Ventana_Biblioteca",Color(0.62,0.76,0.81),0.22)
	for x in [-79.0,-69.0,-59.0,-49.0,-39.0]:
		for y in [2.5,9.2]:
			box(finishes,"VentanaHorizontal",Vector3(x,y,-76.78),Vector3(9.0,1.4,0.03),skyglass)
			for edge in [-0.73,0.73]:
				box(finishes,"MarcoVentana",Vector3(x,y+edge,-76.81),Vector3(9.12,0.055,0.05),mats["black"])
	finishes.add_child(ceiling)
	ceiling.owner = get_tree().edited_scene_root
	for x in [-77.0,-65.0,-52.0,-40.0]:
		for z in [-115.0,-101.0,-87.0]:
			box(finishes,"LuzCielo",Vector3(x,10.96,z),Vector3(0.12,0.04,5),mats["lamp"])
	for pos in [Vector3(-70,5,-110),Vector3(-70,5,-90),Vector3(-43,4,-80)]:
		light(finishes,pos,18)
	# Reposition furniture that occupied the enlarged rooms or reception aisle.
	var pcs := CampusNodes.obtener(library, "PuestosComputadores")
	for i in range(pcs.get_child_count()):
		var pc := pcs.get_child(i) as Node3D
		if i < 10:
			pc.position = Vector3(-81+(i%5)*6.3,0,-113.5+floori(i/5.0)*6.0)
		else:
			pc.position = Vector3(-81+((i-10)%5)*6.3,0,-87.5+floori((i-10)/5.0)*7.0)
	for i in range(4):
		CampusNodes.obtener(library, "Estanterias").get_child(i).position = Vector3(-81,0,-102+i*4.5)
	for n in library.find_children("*","CSGBox3D",true,false):
		if str(n.name).begins_with("Libro"): continue
		if str(n.name) in ["Tablero","Repisa1","Repisa2","Repisa3","Fondo"]:
			n.material = mats["wood"]
	for n in library.find_children("Cristal","MeshInstance3D",true,false):
		n.material_override = mats["glass"]
	old.set_meta("boxes",6)
	old.set_meta("medidas_box",Vector2(8.7,18.0))
	set_meta("boxes_estudio",6)

func build() -> Dictionary:
	init_mats()
	build_elevator_lobbies()
	build_ground_corridor()
	build_library()
	return {"pisos_ascensores":8,"boxes":6,"medidas_box":"8.7 × 18 m","casino":"entrada lateral","biblioteca":"mesón azul, cielo de madera"}

