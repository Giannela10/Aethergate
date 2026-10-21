@tool
extends "res://scripts/pisos/piso_4/piso_4_referencia.gd"
## Fila exterior del plano: 410 a 401, pañol, cowork y oficinas de dirección.
const LEFT := -84.65
const RIGHT := 83.98
const FRONT_WALL := -87.409836
const BACK_WALL := -76.8
const PLAN := [
	["410","SALA 410",9.5,"class"],
	["409","SALA 409",8.5,"class"],
	["408","SALA 408",8.5,"class"],
	["PanolSalud","PAÑOL\nSALUD",4.5,"storage"],
	["407","SALA 407",11.0,"class"],
	["406","SALA 406",8.5,"class"],
	["405","SALA 405",8.5,"class"],
	["404","SALA 404",10.5,"class"],
	["CoworkDocente","COWORK\nDOCENTE",10.5,"office"],
	["402","SALA 402",11.0,"class"],
	["401","SALA 401",11.0,"class"],
	["AdmisionComunicacionExtension","ADMISIÓN\nCOMUNICACIÓN\nY EXTENSIÓN",15.0,"office"],
	["ContabilidadAdministracion","CONTABILIDAD\nY ADMIN.",11.0,"office"],
	["Cafeteria","CAFETERÍA",5.5,"cafe"],
	["DireccionSede","DS\nDIRECCIÓN SEDE",19.0,"office"],
	["SalaReunionesDireccion","SALA REUNIONES\nDIRECCIÓN",17.0,"meeting"]
]

func apply() -> Dictionary:
	for child in get_children():
		remove_child(child)
		child.free()
	palette()
	entries.clear()
	global_position = Vector3(0,HEIGHT,0)
	trim_lower_wall_collision("Piso 3/Delantera_piso 3c3")
	var old_wall := CampusNodes.obtener(get_parent(), "Delantera_piso 4c3")
	old_wall.set_meta("piso4_fila_frontal",true)
	old_wall.hide()
	for col in old_wall.find_children("*","CollisionShape3D",true,false): col.disabled = true
	# La fila ocupa la franja original junto a la fachada. Completar su suelo
	# no invade el vacío de profesores ni el atrio o sus pasillos.
	var depth := BACK_WALL-FRONT_WALL
	var material: Material = CampusNodes.obtener(get_parent(), "Building_Floor Piso 4").get_active_material(0)
	var floor_node := box(self,"LosaFilaFrontal",Vector3((LEFT+RIGHT)*0.5,-0.15,(FRONT_WALL+BACK_WALL)*0.5),Vector3(RIGHT-LEFT,0.3,depth),"floor",true)
	if material: floor_node.material_override = material
	box(self,"LimiteIzquierdo",Vector3(LEFT,5.975,(FRONT_WALL+BACK_WALL)*0.5),Vector3(0.2,11.95,depth),"wall",true)
	var total_weight := 0.0
	for item in PLAN: total_weight += item[2]
	var x := LEFT
	var rectangles: Array = []
	var classes := 0
	for item in PLAN:
		var width: float = (RIGHT-LEFT)*float(item[2])/total_weight
		var rect := Rect2(x,FRONT_WALL,width,depth)
		var r := room(item[0],rect,false,item[3])
		var sign_label := CampusNodes.obtener(r, "Puerta/Nombre") as Label3D
		sign_label.text = item[1]
		sign_label.pixel_size = 0.011 if item[3]=="class" else 0.0065
		r.set_meta("nombre_plano",item[1])
		if item[3]=="class":
			fit_class_furniture(r)
			classes += 1
		elif item[3]=="storage": furnish_storage(r,width,depth)
		elif item[3]=="meeting": furnish_meeting(r)
		elif item[3]=="cafe": furnish_cafe(r)
		else: furnish_office(r,width)
		rectangles.append({"recinto":item[0],"ancho":width,"planta":rect})
		x += width
	set_meta("planta_fila",rectangles)
	set_meta("ancho_fila",RIGHT-LEFT)
	set_meta("recintos",PLAN.size())
	set_meta("salas_clases",classes)
	return {"recintos":PLAN.size(),"salas_clases":classes,"ancho":RIGHT-LEFT,"profundidad_original":depth,"termina_x":x,"limite_x":RIGHT}

func fit_class_furniture(r: Node3D) -> void:
	var desks: Array[Node3D] = []
	for n in r.get_children():
		if n is Node3D and n.has_node("Tablero"): desks.append(n)
	# Seis mesas con sus sillas; dejar la entrada y los pasillos libres.
	for i in range(desks.size()):
		if i>=6:
			r.remove_child(desks[i])
			desks[i].free()
		else:
			desks[i].position = Vector3((i%3-1)*2.4,0,-1.2+(i/3)*3.4)

func furnish_storage(r: Node3D,width: float,depth: float) -> void:
	for side in [-1,1]:
		for level in range(4):
			box(r,"Estante",Vector3(side*(width*0.5-0.55),0.5+level*0.75,1.5),Vector3(0.7,0.1,depth-4),"metal")
			for z in [-0.5,1.5,3.5]: box(r,"Caja",Vector3(side*(width*0.5-0.55),0.75+level*0.75,z),Vector3(0.55,0.4,0.7),"wood")

func furnish_office(r: Node3D,width: float) -> void:
	for row in range(2):
		for col in range(2): desk(r,Vector3((col-0.5)*minf(width*0.5,6.0),0,-0.7+row*3.4))

func furnish_meeting(r: Node3D) -> void:
	var table := group(r,"MesaReuniones",Vector3(0,0,1.0))
	box(table,"Tablero",Vector3(0,1.0,0),Vector3(7.5,0.12,1.6),"wood",true)
	for x in [-3.1,3.1]: box(table,"Pie",Vector3(x,0.45,0),Vector3(0.1,0.9,1.3),"metal")
	for x in [-2.8,-0.9,0.9,2.8]:
		chair(table,Vector3(x,0,1.5))
		var c := group(table,"SillaOpuesta",Vector3(x,0,-1.5))
		c.rotation.y = PI
		chair(c,Vector3.ZERO)

func furnish_cafe(r: Node3D) -> void:
	box(r,"MesonCafe",Vector3(0,0.8,3.5),Vector3(3.7,1.6,0.9),"wood",true)
	box(r,"Cafetera",Vector3(-0.8,1.98,3.4),Vector3(0.7,0.65,0.5),"metal")
	box(r,"ZonaCafe",Vector3(0.65,1.64,3.4),Vector3(0.9,0.07,0.5),"white")

func audit_layout() -> Dictionary:
	var overlaps: Array = []
	var rooms: Array = []
	var previous_end := LEFT
	var max_gap := 0.0
	for child in get_children():
		if not child.has_meta("planta"): continue
		var rect: Rect2 = child.get_meta("planta")
		max_gap = maxf(max_gap,absf(rect.position.x-previous_end))
		previous_end = rect.end.x
		rooms.append({"nombre":child.get_meta("nombre_plano"),"planta":rect})
		for other in get_children():
			if child==other or not other.has_meta("planta"): continue
			var other_rect: Rect2 = other.get_meta("planta")
			var intersection := rect.intersection(other_rect)
			if intersection.size.x>0.001 and intersection.size.y>0.001: overlaps.append([str(child.name),str(other.name)])
	return {"recintos":rooms.size(),"orden":rooms,"solapamientos":overlaps,"hueco_maximo_entre_recintos":max_gap,"error_limite_final":absf(previous_end-RIGHT)}

func preview_front() -> void:
	var campus := get_parent().get_parent()
	for level in range(5,9):
		var n := CampusNodes.buscar(campus, "Piso "+str(level))
		if n: n.hide()
	for n in campus.find_children("*","GeometryInstance3D",true,false):
		if n is MeshInstance3D and n.mesh:
			var b: AABB = n.global_transform*n.get_aabb()
			if b.position.y>HEIGHT+10.5 and not is_ancestor_of(n): n.hide()
		elif n is CSGBox3D:
			var b: AABB = n.global_transform*AABB(-n.size*0.5,n.size)
			if b.position.y>HEIGHT+10.5: n.hide()
	for n in campus.find_children("*","CanvasLayer",true,false): n.hide()
	var camera := Camera3D.new()
	campus.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 110
	camera.global_position = Vector3(0,160,-155)
	camera.look_at(Vector3(0,HEIGHT,-82))
	camera.make_current()
	var sun := DirectionalLight3D.new()
	campus.add_child(sun)
	sun.rotation_degrees = Vector3(-65,0,0)
	sun.light_energy = 0.8
