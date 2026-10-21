extends SceneTree
var scene: Node3D
var library: Node3D
var furniture: Node3D
var mats: Dictionary = {}

func material(key: String, color: Color, roughness: float = 0.6) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	mats[key] = m

func own(n: Node, parent: Node) -> void:
	parent.add_child(n)
	n.owner = scene

func box(parent: Node3D, title: String, p: Vector3, size: Vector3, key: String, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	n.position = p
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mats[key]
	own(n,parent)
	if solid:
		var body := StaticBody3D.new()
		own(body,n)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		own(collision,body)
	return n

func cylinder(parent: Node3D, title: String, p: Vector3, radius: float, height: float, key: String, solid: bool = false) -> void:
	var n := MeshInstance3D.new()
	n.name = title
	n.position = p
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 64
	n.mesh = mesh
	n.material_override = mats[key]
	own(n,parent)
	if solid:
		var body := StaticBody3D.new()
		own(body,n)
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		own(collision,body)

func chair(p: Vector3, angle: float) -> void:
	var n := Node3D.new()
	n.name = "SillaAzul"
	n.position = p
	n.rotation.y = angle
	own(n,furniture)
	box(n,"AsientoAzul",Vector3(0,0.67,0),Vector3(1.05,0.12,1),"blue",true)
	var back := box(n,"RespaldoAzul",Vector3(0,1.13,0.43),Vector3(1.05,0.85,0.1),"blue",true)
	back.rotation.x = -0.1
	for side in [-1,1]:
		box(n,"PataFrontal",Vector3(side*0.48,0.33,-0.36),Vector3(0.035,0.65,0.035),"steel")
		box(n,"PataPosterior",Vector3(side*0.48,0.57,0.4),Vector3(0.035,1.13,0.035),"steel")
		box(n,"PatinMetalico",Vector3(side*0.48,0.065,0.05),Vector3(0.045,0.045,1.1),"steel")

func table(p: Vector3) -> void:
	var n := Node3D.new()
	n.name = "MesaRedonda"
	n.position = p
	own(n,furniture)
	cylinder(n,"TableroMadera",Vector3(0,1.17,0),1.55,0.13,"wood",true)
	cylinder(n,"PedestalBlanco",Vector3(0,0.6,0),0.13,1.07,"white",true)
	cylinder(n,"BaseCircular",Vector3(0,0.12,0),0.67,0.1,"white")
	for i in range(4):
		var angle := i*PI/2
		chair(p+Vector3(sin(angle)*2.2,0,cos(angle)*2.2),angle)

func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (b-a).cross(c-a).normalized()
	# Godot usa triángulos en sentido horario para las caras visibles.
	for point in [a,c,b,a,d,c]:
		st.set_normal(normal)
		st.add_vertex(point)

func oval_band(parent: Node3D, title: String, rx: float, rz: float, depth: float, bottom: float, top: float, key: String, solid: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body: StaticBody3D
	if solid:
		body = StaticBody3D.new()
		body.name = "ColisionMesonAbierto"
		own(body,parent)
	# Abertura al oeste: 2.5 metros entre las puntas, sin colisión que la cierre.
	var start := PI+0.43
	var sweep := TAU-0.86
	for i in range(80):
		var a := start+sweep*i/80
		var b := start+sweep*(i+1)/80
		var o1 := Vector3(cos(a)*rx,bottom,sin(a)*rz)
		var o2 := Vector3(cos(b)*rx,bottom,sin(b)*rz)
		var i1 := Vector3(cos(a)*(rx-depth),bottom,sin(a)*(rz-depth))
		var i2 := Vector3(cos(b)*(rx-depth),bottom,sin(b)*(rz-depth))
		var up := Vector3(0,top-bottom,0)
		quad(st,o1,o1+up,o2+up,o2)
		quad(st,i2,i2+up,i1+up,i1)
		quad(st,o1+up,i1+up,i2+up,o2+up)
		quad(st,o2,i2,i1,o1)
		if i == 0:
			quad(st,i1,i1+up,o1+up,o1)
		if i == 79:
			quad(st,o2,o2+up,i2+up,i2)
		if solid:
			var collision := CollisionShape3D.new()
			var shape := ConvexPolygonShape3D.new()
			shape.points = PackedVector3Array([o1,o2,i1,i2,o1+up,o2+up,i1+up,i2+up])
			collision.shape = shape
			own(collision,body)
	var n := MeshInstance3D.new()
	n.name = title
	n.mesh = st.commit()
	n.material_override = mats[key]
	own(n,parent)

func snapshot(node: Node) -> Array:
	var values: Array = []
	for child in node.find_children("*","",true,false):
		var entry: Array = [child,child.name]
		if child is Node3D:
			entry.append(child.transform)
		if child is MeshInstance3D:
			entry.append(child.mesh)
			entry.append(child.material_override)
		if child is CSGBox3D:
			entry.append(child.size)
			entry.append(child.material)
		values.append(entry)
	return values

func _initialize() -> void:
	scene = load("res://Main.tscn").instantiate()
	library = scene.get_node("Piso2/Biblioteca")
	var study = library.get_node("SalasEstudio")
	var study_before := snapshot(study)
	var finishes = library.get_node("AcabadosReferencia")
	var ceiling_before = finishes.get_node("FondoCieloMadera").transform
	var ceiling_mesh = finishes.get_node("FondoCieloMadera").mesh
	var ceiling_mat = finishes.get_node("FondoCieloMadera").material_override
	# Solo se retira el antiguo mobiliario de recepción; los acabados permanecen.
	for title in ["MesonAzulBiblioteca","CubiertaMeson","ExtremoCurvoMeson","ZocaloMeson","TextoMeson","PantallaAtencion","ProtectorVidrioMeson","ProtectorVidrioMeson2"]:
		var old = finishes.get_node_or_null(title)
		if old:
			old.free()
	for child in finishes.get_children():
		if str(child.name).begins_with("Silla"):
			child.free()
		elif child is MeshInstance3D and child.position.y == 2.5 and absf(child.position.z+97.1) < 0.01:
			# Segundo protector de vidrio antiguo guardado con un nombre automático.
			child.free()
	var previous = library.get_node_or_null("MobiliarioReferenciaFoto")
	if previous:
		previous.free()
	furniture = Node3D.new()
	furniture.name = "MobiliarioReferenciaFoto"
	own(furniture,library)
	material("blue",Color(0.035,0.09,0.28),0.4)
	material("counterblue",Color(0.035,0.09,0.43),0.35)
	material("wood",Color(0.76,0.58,0.33),0.45)
	material("steel",Color(0.58,0.6,0.62),0.3)
	material("white",Color(0.9,0.9,0.84))
	material("black",Color(0.028,0.03,0.035),0.38)
	material("gold",Color(0.88,0.68,0.2))
	material("red",Color(0.75,0.025,0.035),0.35)
	material("screen",Color(0.12,0.24,0.35))
	material("frost",Color(0.65,0.7,0.67,0.7))
	mats.frost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mats.frost.cull_mode = BaseMaterial3D.CULL_DISABLED
	var counter := Node3D.new()
	counter.name = "MesonOvaladoAbierto"
	counter.position = Vector3(-61.5,0,-115.5)
	own(counter,furniture)
	oval_band(counter,"FrenteAzulCurvo",6.6,3.8,0.72,0.25,1.52,"counterblue",true)
	oval_band(counter,"CubiertaOscuraOvalada",6.74,3.94,1.0,1.52,1.64,"black",false)
	oval_band(counter,"ZocaloMetalico",6.62,3.82,0.75,0.27,0.36,"steel",false)
	box(counter,"MesaTrabajoInterior",Vector3(0,0.96,-2.15),Vector3(5.1,0.15,1.1),"wood",true)
	box(counter,"BaseMonitorAtencion",Vector3(0,1.08,-2.15),Vector3(0.6,0.06,0.4),"black")
	box(counter,"SoporteMonitor",Vector3(0,1.32,-2.2),Vector3(0.1,0.45,0.1),"steel")
	box(counter,"MonitorBibliotecaria",Vector3(0,1.73,-2.2),Vector3(1.3,0.8,0.09),"black")
	box(counter,"PantallaBibliotecaria",Vector3(0,1.73,-2.14),Vector3(1.15,0.67,0.02),"screen")
	box(counter,"Teclado",Vector3(0,1.08,-1.8),Vector3(0.9,0.06,0.25),"black")
	box(counter,"LibrosDevolucion",Vector3(2.5,1.78,-3.15),Vector3(0.65,0.26,0.8),"blue")
	box(counter,"HojasInformacion",Vector3(-2.5,1.66,-3.15),Vector3(0.75,0.025,0.55),"white")
	var title := Label3D.new()
	title.name = "RotuloAtencion"
	title.text = "BIBLIOTECA · ATENCIÓN"
	title.font_size = 48
	title.pixel_size = 0.004
	title.position = Vector3(0,0.85,-3.84)
	title.rotation.y = PI
	title.modulate = Color(0.9,0.76,0.35)
	own(title,counter)
	var boss = library.get_node("BossBibliotecaria")
	boss.position = counter.position+Vector3(0,0.05,0)
	boss.rotation.y = 0
	# Mesas redondas y sillas azules del área común de la referencia.
	for x in [-72.0,-60.0]:
		for z in [-103.0,-92.0,-84.5]:
			table(Vector3(x,0,z))
	# Computadores a lo largo del perímetro, sin ocupar los accesos a las salas.
	var pcs = library.get_node("PuestosComputadores")
	for i in range(pcs.get_child_count()):
		var pc: Node3D = pcs.get_child(i)
		if i < 9:
			pc.position = Vector3(-82,0,-108+i*3.4)
			pc.rotation.y = PI/2
		else:
			pc.position = Vector3(-81+float(i-9)*26.0/maxi(1,pcs.get_child_count()-10),0,-78.6)
			pc.rotation.y = 0
	var shelves = library.get_node("Estanterias")
	for i in range(shelves.get_child_count()):
		if i < 2:
			shelves.get_child(i).position = Vector3(-72.4,0,-118.5+i*5)
			shelves.get_child(i).rotation.y = PI/2
		else:
			shelves.get_child(i).position = Vector3(-69.5+(i-2)*5,0,-121.5)
			shelves.get_child(i).rotation.y = 0
	# Perfiles y franja esmerilada de los ventanales, como en la foto.
	box(furniture,"ViniloVentanal",Vector3(-84.61,1.7,-94.2),Vector3(0.025,2.4,31.8),"frost")
	for z in [-110.0,-106.0,-102.0,-98.0,-94.0,-90.0,-86.0,-82.0,-78.0]:
		box(furniture,"PerfilVentanal",Vector3(-84.59,5.6,z),Vector3(0.08,11.2,0.08),"black")
	for y in [0.2,3.0,7.0,11.15]:
		box(furniture,"TravesanoVentanal",Vector3(-84.59,y,-94.2),Vector3(0.08,0.08,31.8),"black")
	# Mueble auxiliar, papelera, extintor y expositor junto al mesón.
	box(furniture,"MuebleAuxiliar",Vector3(-54.8,0.72,-112),Vector3(1.4,1.3,1.25),"white",true)
	box(furniture,"TiradorMueble",Vector3(-54.8,1.05,-112.65),Vector3(0.42,0.055,0.07),"steel")
	cylinder(furniture,"Papelera",Vector3(-54.8,0.65,-110.5),0.38,1.15,"steel")
	cylinder(furniture,"Extintor",Vector3(-54.8,1.94,-112),0.2,0.95,"red")
	box(furniture,"AsaExtintor",Vector3(-54.8,2.47,-112),Vector3(0.36,0.07,0.12),"black")
	box(furniture,"ExpositorRevistas",Vector3(-53.2,0.95,-107.2),Vector3(1.7,1.8,0.6),"wood",true)
	for y in [0.5,1.0,1.5]:
		box(furniture,"Revistas",Vector3(-53.2,y+0.18,-107.55),Vector3(1.4,0.45,0.045),"white")
		box(furniture,"RepisaExpositor",Vector3(-53.2,y,-107.57),Vector3(1.55,0.08,0.22),"wood")
	assert(study_before == snapshot(study))
	assert(finishes.get_node("FondoCieloMadera").transform == ceiling_before and finishes.get_node("FondoCieloMadera").mesh == ceiling_mesh and finishes.get_node("FondoCieloMadera").material_override == ceiling_mat)
	print("BIBLIOTECA_SALAS_Y_TECHO_CONSERVADOS=true; SUELO_SIN_MODIFICAR=true")
	furniture.set_meta("referencia","WhatsApp 2026-10-09 21:54:08; mesón ovalado con abertura oeste, mesas redondas y sillas azules")
	var packed := PackedScene.new()
	var error := packed.pack(scene)
	if error == OK:
		error = ResourceSaver.save(packed,"res://Main.tscn")
	print("BIBLIOTECA_SAVE=",error)
	scene.free()
	quit(error)
