@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")

var mats: Dictionary = {}
func material(key: String, color: Color, rough: float = 0.8, metal: float = 0.0) -> StandardMaterial3D:
	if mats.has(key): return mats[key]
	var m := StandardMaterial3D.new()
	m.resource_name = key
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	mats[key] = m
	return m

func group(label: String) -> Node3D:
	var n := Node3D.new()
	n.name = label
	add_child(n)
	n.owner = get_tree().edited_scene_root
	return n

func mesh(p: Node3D, label: String, shape: Mesh, pos: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = shape
	n.position = pos
	n.material_override = mat
	p.add_child(n)
	n.owner = get_tree().edited_scene_root
	if solid:
		var b := StaticBody3D.new()
		b.name = "Cuerpo"
		n.add_child(b)
		b.owner = n.owner
		var c := CollisionShape3D.new()
		c.shape = shape.create_convex_shape()
		b.add_child(c)
		c.owner = n.owner
	return n

func box(p: Node3D, label: String, pos: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(p, label, shape, pos, mat, solid)

func cylinder(p: Node3D, label: String, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 16
	return mesh(p, label, shape, pos, mat)

func line(p: Node3D, label: String, a: Vector3, b: Vector3, width: float, mat: Material) -> void:
	var n := box(p, label, (a+b)*0.5, Vector3(width, width, a.distance_to(b)), mat)
	n.look_at_from_position((a+b)*0.5, b, Vector3.UP if absf((b-a).normalized().y)<0.99 else Vector3.RIGHT)

func fence(p: Node3D, label: String, a: Vector3, b: Vector3) -> void:
	var green: Material = mats["MAT_Reja_Posterior"]
	var span := a.distance_to(b)
	var segments := maxi(1, int(ceil(span/3.0)))
	for i in range(segments+1):
		var base := a.lerp(b, float(i)/segments)
		box(p, label+"Poste"+str(i), base+Vector3(0,1.45,0), Vector3(0.09,2.9,0.09), green, true)
	for y in [0.3,1.45,2.65]:
		line(p,label+"Travesano"+str(y), a+Vector3(0,y,0), b+Vector3(0,y,0),0.035,green)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var rod := BoxMesh.new()
	rod.size = Vector3(0.018,2.4,0.018)
	mm.mesh = rod
	mm.instance_count = int(span/0.15)+1
	for i in range(mm.instance_count):
		mm.set_instance_transform(i,Transform3D(Basis(),a.lerp(b,float(i)/maxi(1,mm.instance_count-1))+Vector3(0,1.45,0)))
	var wires := MultiMeshInstance3D.new()
	wires.name = label+"MallaVertical"
	wires.multimesh = mm
	wires.material_override = green
	wires.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wires.visibility_range_end = 75.0
	wires.visibility_range_end_margin = 15.0
	wires.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	p.add_child(wires)
	wires.owner = get_tree().edited_scene_root
	for i in range(17):
		line(p,label+"MallaHorizontal"+str(i), a+Vector3(0,0.25+i*0.15,0), b+Vector3(0,0.25+i*0.15,0),0.013,green)
	var body := StaticBody3D.new()
	body.name = label+"Colision"
	p.add_child(body)
	body.owner = get_tree().edited_scene_root
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.08,2.7,span)
	collision.shape = shape
	collision.position = (a+b)*0.5+Vector3(0,1.35,0)
	body.add_child(collision)
	collision.owner = body.owner
	collision.look_at_from_position(collision.position,b+Vector3(0,1.35,0),Vector3.UP)

func car(p: Node3D, number: int, pos: Vector3, paint: Material) -> void:
	var n := Node3D.new()
	n.name = "Auto"+str(number)
	n.position = pos
	p.add_child(n)
	n.owner = get_tree().edited_scene_root
	box(n,"Carroceria",Vector3(0,0.7,0),Vector3(1.85,0.72,4.15),paint,true)
	box(n,"CabinaVidriada",Vector3(0,1.32,-0.1),Vector3(1.55,0.75,2.1),mats["MAT_Vidrio_Autos"])
	box(n,"Techo",Vector3(0,1.72,-0.15),Vector3(1.58,0.08,1.65),paint)
	for x in [-0.92,0.92]:
		for z in [-1.35,1.35]:
			var wheel := cylinder(n,"Rueda",Vector3(x,0.48,z),0.37,0.2,mats["MAT_Neumaticos"])
			wheel.rotation.z = PI/2
			var rim := cylinder(n,"Llanta",Vector3(x*1.035,0.48,z),0.19,0.21,mats["MAT_Metal_Posterior"])
			rim.rotation.z = PI/2
	for x in [-0.6,0.6]:
		box(n,"Faro",Vector3(x,0.78,2.085),Vector3(0.42,0.2,0.035),mats["MAT_Lineas_Cancha"])
		box(n,"LuzTrasera",Vector3(x,0.78,-2.085),Vector3(0.42,0.18,0.035),mats["MAT_Auto_Rojo"])
	box(n,"Parachoques",Vector3(0,0.46,2.08),Vector3(1.75,0.16,0.08),mats["MAT_Neumaticos"])

func build() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	mats.clear()
	var concrete := material("MAT_Hormigon_Patio",Color(0.43,0.45,0.44))
	var court := material("MAT_Cancha_Gris",Color(0.58,0.6,0.58))
	var asphalt := material("MAT_Asfalto_Estacionamientos",Color(0.13,0.15,0.15))
	var white := material("MAT_Lineas_Cancha",Color(0.88,0.88,0.8))
	var grass: Material = load("res://materials/entrance/MAT_Grass.tres")
	var metal := material("MAT_Metal_Posterior",Color(0.12,0.15,0.16),0.48,0.5)
	var orange := material("MAT_Aros_Naranjos",Color(0.84,0.25,0.035),0.5,0.25)
	var cream := material("MAT_Caseta_Crema",Color(0.78,0.75,0.65))
	var glass := material("MAT_Vidrio_Autos",Color(0.12,0.21,0.25),0.22,0.3)
	material("MAT_Reja_Posterior",Color(0.12,0.25,0.19),0.7,0.25)
	material("MAT_Neumaticos",Color(0.025,0.027,0.028))
	var paints: Array[Material] = [
		material("MAT_Auto_Rojo",Color(0.6,0.045,0.035),0.3,0.3),
		material("MAT_Auto_Azul",Color(0.025,0.15,0.42),0.3,0.3),
		material("MAT_Auto_Blanco",Color(0.8,0.82,0.8),0.3,0.3),
		material("MAT_Auto_Gris",Color(0.27,0.29,0.3),0.3,0.3)]
	var ground := group("PavimentosYJardines")
	box(ground,"BasePatioTransitable",Vector3(0,0,-204),Vector3(190,0.2,84),concrete,true)
	box(ground,"CallePosterior",Vector3(0,0,-252),Vector3(210,0.2,12),asphalt,true)
	box(ground,"VeredaPosterior",Vector3(0,0.14,-244.5),Vector3(190,0.28,3),concrete,true)
	box(ground,"Estacionamiento",Vector3(0,0.2,-178),Vector3(172,0.03,25),asphalt)
	box(ground,"AccesoVehicular",Vector3(-73,0.2,-217),Vector3(12,0.03,53),asphalt)
	box(ground,"CespedAlrededorCancha",Vector3(0,0.14,-217),Vector3(180,0.08,50),grass)
	box(ground,"CespedFrenteCancha",Vector3(-30,0.14,-236),Vector3(115,0.08,12),grass)
	box(ground,"JardinCostadoDerecho",Vector3(80,0.14,-216),Vector3(20,0.08,48),grass)
	box(ground,"JardinCostadoIzquierdo",Vector3(-81,0.14,-213),Vector3(13,0.08,32),grass)
	var sports := group("CanchaBasquetbol")
	box(sports,"LosaCancha",Vector3(-27,0.22,-212),Vector3(62,0.06,32),court)
	# Court regulation markings inside a generous concrete apron.
	for z in [-224,-200]:
		box(sports,"LineaLateral",Vector3(-27,0.257,z),Vector3(40,0.008,0.1),white)
	for x in [-47,-7,-27]:
		box(sports,"LineaFondoOCentro",Vector3(x,0.257,-212),Vector3(0.1,0.008,24),white)
	for side in [-1,1]:
		var end_x: float = -27+side*20
		var free_x: float = end_x-side*7
		for z in [-215,-209]:
			box(sports,"LineaArea",Vector3((end_x+free_x)/2,0.257,z),Vector3(7,0.008,0.1),white)
		box(sports,"LineaTiroLibre",Vector3(free_x,0.257,-212),Vector3(0.1,0.008,6),white)
		for i in range(50):
			var angle0: float = -PI/2+i*PI/50
			var angle1: float = -PI/2+(i+1)*PI/50
			line(sports,"ArcoTriple",Vector3(end_x-side*6.7*cos(angle0),0.26,-212+6.7*sin(angle0)),Vector3(end_x-side*6.7*cos(angle1),0.26,-212+6.7*sin(angle1)),0.09,white)
		var pole_x: float = end_x+side*1.8
		box(sports,"PosteNaranjo",Vector3(pole_x,2.1,-212),Vector3(0.18,4,0.18),orange,true)
		line(sports,"SoporteTablero",Vector3(pole_x,3.8,-212),Vector3(end_x,3.8,-212),0.14,orange)
		box(sports,"TableroBlanco",Vector3(end_x,3.9,-212),Vector3(0.1,1.2,1.8),white)
		for z in [-212.3,-211.7]:
			box(sports,"CuadroTablero",Vector3(end_x-side*0.061,3.72,z),Vector3(0.02,0.45,0.035),orange)
		for y in [3.495,3.945]:
			box(sports,"CuadroTablero",Vector3(end_x-side*0.061,y,-212),Vector3(0.02,0.035,0.6),orange)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.24
		ring.outer_radius = 0.28
		mesh(sports,"Aro",ring,Vector3(end_x-side*0.34,3.18,-212),orange)
		for i in range(12):
			var angle: float = TAU*i/12
			line(sports,"Red",Vector3(end_x-side*0.34+0.25*cos(angle),3.16,-212+0.25*sin(angle)),Vector3(end_x-side*0.34+0.16*cos(angle+0.3),2.7,-212+0.16*sin(angle+0.3)),0.015,white)
	for i in range(48):
		var a: float = TAU*i/48
		var b: float = TAU*(i+1)/48
		line(sports,"CirculoCentral",Vector3(-27+3*cos(a),0.26,-212+3*sin(a)),Vector3(-27+3*cos(b),0.26,-212+3*sin(b)),0.09,white)
	var court_fence := group("RejasCancha")
	fence(court_fence,"FondoNorte",Vector3(-60,0.2,-194),Vector3(6,0.2,-194))
	fence(court_fence,"FondoSur",Vector3(-60,0.2,-230),Vector3(6,0.2,-230))
	fence(court_fence,"LateralIzquierdo",Vector3(-60,0.2,-230),Vector3(-60,0.2,-194))
	fence(court_fence,"LateralDerecho1",Vector3(6,0.2,-230),Vector3(6,0.2,-214))
	fence(court_fence,"LateralDerecho2",Vector3(6,0.2,-210),Vector3(6,0.2,-194))
	var goals := group("ArcosFutbol")
	for side in [-1,1]:
		var front: float = -27+side*20
		var back: float = front+side*1.6
		for z in [-215,-209]:
			cylinder(goals,"PosteArco",Vector3(front,1.45,z),0.07,2.4,white)
			line(goals,"MarcoTrasero",Vector3(back,0.25,z),Vector3(back,2.1,z),0.05,white)
			line(goals,"BaseArco",Vector3(front,0.29,z),Vector3(back,0.29,z),0.05,white)
			line(goals,"SoporteRedSuperior",Vector3(front,2.65,z),Vector3(back,2.1,z),0.05,white)
		line(goals,"Travesano",Vector3(front,2.65,-215),Vector3(front,2.65,-209),0.14,white)
		for i in range(31):
			var z: float = -215+i*0.2
			line(goals,"RedFondoVertical",Vector3(back,0.3,z),Vector3(back,2.1,z),0.012,white)
			line(goals,"RedTecho",Vector3(front,2.65,z),Vector3(back,2.1,z),0.012,white)
		for i in range(10):
			var y: float = 0.3+i*0.2
			line(goals,"RedFondoHorizontal",Vector3(back,y,-215),Vector3(back,y,-209),0.012,white)
			for z in [-215,-209]:
				line(goals,"RedLateral",Vector3(front,y,z),Vector3(back,y,z),0.012,white)
		for z in [-215,-209]:
			for i in range(9):
				var x: float = lerpf(front,back,i/8.0)
				line(goals,"RedLateralVertical",Vector3(x,0.3,z),Vector3(x,lerpf(2.65,2.1,i/8.0),z),0.012,white)
	var parking := group("Estacionamientos")
	for i in range(47):
		var x: float = -80+i*3.4
		box(parking,"Demarcacion"+str(i),Vector3(x,0.23,-172.4),Vector3(0.09,0.015,5.2),white)
	for i in range(47):
		if i%5 == 0: continue
		var x: float = -78.3+i*3.4
		car(parking,i,Vector3(x,0.14,-172.3),paints[i%4])
	var perimeter := group("CierrePerimetral")
	fence(perimeter,"FondoIzquierdo",Vector3(-94,0.15,-242),Vector3(-79,0.15,-242))
	fence(perimeter,"FondoDerecho",Vector3(-67,0.15,-242),Vector3(94,0.15,-242))
	fence(perimeter,"LadoIzquierdo",Vector3(-94,0.15,-242),Vector3(-94,0.15,-165))
	fence(perimeter,"LadoDerecho",Vector3(94,0.15,-242),Vector3(94,0.15,-165))
	var entry := group("AccesoVehicularYCaseta")
	# Gate leaf is slid to the side, leaving the driveway passable.
	fence(entry,"PortonAbierto",Vector3(-66.7,0.15,-241.6),Vector3(-54.7,0.15,-241.6))
	box(entry,"Caseta",Vector3(-61,1.65,-237),Vector3(3.5,3,4),cream,true)
	box(entry,"TechoCaseta",Vector3(-61,3.22,-237),Vector3(4,0.15,4.5),metal)
	box(entry,"VentanaCaseta",Vector3(-61,2,-239.02),Vector3(2.3,1.1,0.035),glass)
	box(entry,"VentanaLateralCaseta",Vector3(-62.77,2,-237),Vector3(0.035,1.1,2),glass)
	for i in range(20):
		box(entry,"JuntaRevestimiento",Vector3(-61,0.3+i*0.145,-239.025),Vector3(3.5,0.016,0.02),concrete)
	box(entry,"LetreroAcceso",Vector3(-49,2.6,-242.12),Vector3(9,2.6,0.1),metal)
	var label := Label3D.new()
	label.name = "DuocUC"
	label.text = "DuocUC\nSEDE SAN JOAQUÍN"
	label.font_size = 64
	label.pixel_size = 0.009
	label.position = Vector3(-49,2.6,-242.2)
	label.rotation.y = PI
	entry.add_child(label)
	label.owner = get_tree().edited_scene_root
	var landscape := group("ArbolesEIluminacion")
	for i in range(7):
		var x: float = -82+i*18
		cylinder(landscape,"Tronco",Vector3(x,2.2,-237),0.18,4.1,cream)
		var crown := SphereMesh.new()
		crown.radius = 2.4
		crown.height = 5
		mesh(landscape,"CopaArbol",crown,Vector3(x,5,-237),grass)
	for x in [-68,16,83]:
		cylinder(landscape,"PosteLuz",Vector3(x,6,-195),0.12,12,metal)
		box(landscape,"Foco",Vector3(x,12,-195),Vector3(1.3,0.25,0.7),white)
	# Reuse the existing rear facade meshes; no elevator or gameplay geometry is changed.
	var campus := CampusNodes.campus(self)
	for n in campus.find_children("*", "MeshInstance3D", true, false):
		if is_ancestor_of(n): continue
		if n.name.to_lower().contains("back") and n.mesh != null and n.global_position.z < -161 and absf(n.global_position.x) > 25:
			n.material_override = load("res://materials/entrance/MAT_Facade_Glass_Duoc.tres")
	var facade := group("CelosiaPosterior")
	var rear_glass := ShaderMaterial.new()
	rear_glass.shader = load("res://materials/entrance/celosia_posterior.gdshader")
	rear_glass.resource_name = "MAT_Celosia_Posterior"
	ResourceSaver.save(rear_glass,"res://materials/entrance/MAT_Celosia_Posterior.tres")
	for x in [-50.25,50.25]:
		box(facade,"PanelVidrioOscuro",Vector3(x,53.5,-164.1),Vector3(69.5,83,0.1),rear_glass)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var rod := BoxMesh.new()
	rod.size = Vector3(0.055,83,0.12)
	mm.mesh = rod
	mm.instance_count = 341
	for i in range(mm.instance_count):
		mm.set_instance_transform(i,Transform3D(Basis(),Vector3(-85+i*0.5,53.5,-164.3)))
	var lattice := MultiMeshInstance3D.new()
	lattice.name = "CelosiaMetalica"
	lattice.multimesh = mm
	lattice.material_override = metal
	lattice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lattice.visible = false
	facade.add_child(lattice)
	lattice.owner = get_tree().edited_scene_root
	for y in range(12,96,3):
		for x in [-50.25,50.25]:
			box(facade,"MarcoHorizontal",Vector3(x,y,-164.3),Vector3(69.5,0.065,0.12),metal)
	for key in mats:
		ResourceSaver.save(mats[key],"res://materials/entrance/"+key+".tres")
	set_meta("descripcion","Cancha posterior, estacionamientos, césped, cierre y acceso vehicular según fotografías")
