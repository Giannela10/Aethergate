@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
## Distribución del cartel PISO 4. Escala adaptada a la estructura existente.
## El mobiliario interior es una interpretación; la foto no muestra esos detalles.
const HEIGHT := 35.674415588
var mats: Dictionary = {}
var entries: Array[Dictionary] = []

func own(parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else owner

func group(parent: Node, title: String, p := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = title
	own(parent, n)
	n.position = p
	return n

func box(parent: Node, title: String, p: Vector3, size: Vector3, key: String, solid := false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mats[key]
	own(parent, n)
	n.position = p
	if solid:
		var body := StaticBody3D.new()
		own(n, body)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		own(body, col)
	return n

func text(parent: Node, title: String, value: String, p: Vector3, angle := 0.0, pixel := 0.006) -> Label3D:
	var n := Label3D.new()
	n.name = title
	n.text = value
	n.font_size = 56
	n.pixel_size = pixel
	n.outline_size = 2
	n.modulate = Color(0.95, 0.96, 0.97)
	own(parent, n)
	n.position = p
	n.rotation.y = angle
	return n

func palette() -> void:
	var colors := {"wall":Color(0.82,0.81,0.76),"wood":Color(0.64,0.48,0.29),"blue":Color(0.025,0.08,0.19),"metal":Color(0.16,0.18,0.2),"white":Color(0.93,0.94,0.92),"floor":Color(0.22,0.23,0.24),"tile":Color(0.7,0.76,0.77),"green":Color(0.03,0.4,0.24),"yellow":Color(0.95,0.7,0.12),"screen":Color(0.05,0.23,0.3),"lamp":Color(1,0.95,0.84)}
	for key in colors:
		var m := StandardMaterial3D.new()
		m.albedo_color = colors[key]
		m.roughness = 0.8
		if key == "lamp":
			m.emission_enabled = true
			m.emission = colors[key]
		mats[key] = m
	mats["glass"] = load("res://materials/entrance/MAT_Glass_Entrance.tres")

func chair(parent: Node, p: Vector3) -> void:
	var c := group(parent,"Silla",p)
	box(c,"Asiento",Vector3(0,0.58,0),Vector3(0.65,0.12,0.65),"blue",true)
	box(c,"Respaldo",Vector3(0,1.03,0.28),Vector3(0.65,0.8,0.1),"blue")
	for x in [-0.24,0.24]:
		for z in [-0.24,0.24]:
			box(c,"Pata",Vector3(x,0.25,z),Vector3(0.05,0.5,0.05),"metal")

func desk(parent: Node, p: Vector3, computer := false) -> void:
	var d := group(parent,"Escritorio",p)
	box(d,"Tablero",Vector3(0,0.95,0),Vector3(1.5,0.12,0.85),"wood",true)
	for x in [-0.6,0.6]:
		box(d,"Soporte",Vector3(x,0.45,0),Vector3(0.07,0.9,0.65),"metal")
	chair(d,Vector3(0,0,0.85))
	if computer:
		box(d,"Monitor",Vector3(0,1.43,-0.18),Vector3(0.9,0.58,0.09),"metal")
		box(d,"Pantalla",Vector3(0,1.43,-0.125),Vector3(0.81,0.48,0.015),"screen")
		box(d,"PieMonitor",Vector3(0,1.12,-0.18),Vector3(0.12,0.28,0.12),"metal")
		box(d,"Teclado",Vector3(0,1.025,0.12),Vector3(0.66,0.035,0.22),"metal")

func doorway(parent: Node3D, width: float, depth: float, positive: bool, title: String) -> void:
	var z := depth*0.5 if positive else -depth*0.5
	var a := 0.0 if positive else PI
	# Dos hojas corredizas automáticas, con el mismo comportamiento de las salas existentes.
	var door := group(parent,"Puerta",Vector3(0,0,z))
	door.rotation.y = a
	door.set_script(load("res://scripts/compartidos/puerta_vidrio_salas.gd"))
	door.set("ancho",2.6)
	for side in [-1,1]:
		var leaf := AnimatableBody3D.new()
		leaf.name = "HojaIzquierda" if side<0 else "HojaDerecha"
		own(door,leaf)
		leaf.position = Vector3(side*0.65,0,0)
		box(leaf,"Cristal",Vector3(0,1.6,0),Vector3(1.26,3.2,0.08),"glass")
		box(leaf,"Marco",Vector3(side*0.61,1.6,0),Vector3(0.07,3.2,0.12),"metal")
		box(leaf,"FranjaSeguridad",Vector3(0,1.5,0.06),Vector3(1.22,0.1,0.02),"yellow")
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.26,3.2,0.1)
		collision.shape = shape
		own(leaf,collision)
		collision.position.y = 1.6
	var wing := (width-2.8)*0.5
	for side in [-1,1]:
		box(parent,"MuroAcceso",Vector3(side*(1.4+wing*0.5),5.975,z),Vector3(wing,11.95,0.505),"wall",true)
	box(parent,"Dintel",Vector3(0,7.575,z),Vector3(2.8,8.75,0.505),"wall",true)
	var sign_title := "SALA " + title if title.is_valid_int() else title
	if title == "BAÑO MUJERES": sign_title = "BAÑO\nMUJERES"
	if title == "ProfesoresCoordDocente": sign_title = "SALA PROFESORES\nCOORD. DOCENTE"
	if title == "ED": sign_title = "ED\nESTAR DOCENTE"
	if title == "BanosDocentes": sign_title = "BAÑOS"
	box(door,"Placa",Vector3(0,3.95,0.32),Vector3(4.2,1.25,0.07),"blue")
	var sign_label := text(door,"Nombre",sign_title,Vector3(0,3.95,0.38),0,0.0065 if title == "ProfesoresCoordDocente" else 0.011)
	sign_label.outline_size = 0
	sign_label.no_depth_test = false
	entries.append({"nombre":title,"posicion":door.global_position,"sentido":1 if positive else -1})

func room(title: String, rect: Rect2, positive: bool, kind := "class") -> Node3D:
	var r := group(self,title,Vector3(rect.get_center().x,0,rect.get_center().y))
	r.set_meta("uso",kind)
	r.set_meta("planta",rect)
	var w := rect.size.x
	var d := rect.size.y
	# Los límites exteriores son los muros originales: solo se añaden divisiones.
	# No construir una segunda caja ni una losa dentro del recinto existente.
	if title != "416":
		box(r,"DivisionSala",Vector3(w*0.5,5.975,0),Vector3(0.2,11.95,d),"wall",true)
	doorway(r,w,d,positive,title)
	for z in [-d*0.25,d*0.25]:
		box(r,"Luminaria",Vector3(0,11.2,z),Vector3(minf(w-1,3),0.08,0.3),"lamp")
	var light := OmniLight3D.new()
	light.light_energy = 1.0
	light.omni_range = maxf(w,d)*0.85
	light.omni_attenuation = 0.7
	own(r,light)
	light.position = Vector3(0,5,0)
	if kind=="class":
		# Únicamente mesas y sillas, con espacio libre delante de la entrada.
		for row in range(3):
			for col in range(3):
				desk(r,Vector3((col-1)*2.35,0,-d*0.3+row*d*0.25))
	elif kind=="bath":
		bath(r,w,d)
	return r

func bath(parent: Node3D,w: float,d: float) -> void:
	for i in range(3):
		var z := -d*0.25+i*d*0.25
		var stall := group(parent,"Cabina",Vector3(-w*0.5+1.65,0,z))
		box(stall,"Separador",Vector3(0,1.55,-d*0.125),Vector3(3,3.1,0.1),"tile",true)
		box(stall,"PuertaCabina",Vector3(1.48,1.5,0),Vector3(0.1,2.8,d*0.19),"blue")
		box(stall,"Taza",Vector3(-0.35,0.5,0),Vector3(0.8,0.6,1.05),"white",true)
		box(stall,"AsientoWC",Vector3(-0.35,0.85,0),Vector3(0.84,0.12,1.1),"tile")
		box(stall,"Estanque",Vector3(-0.9,1.1,0),Vector3(0.32,0.85,0.85),"white")
		box(parent,"Lavamanos",Vector3(w*0.5-0.65,1.0,z),Vector3(1,0.22,1.1),"white",true)
		box(parent,"Grifo",Vector3(w*0.5-0.85,1.25,z),Vector3(0.07,0.35,0.07),"metal")
		box(parent,"Espejo",Vector3(w*0.5-0.14,2.0,z),Vector3(0.035,1.4,1.1),"glass")
	box(parent,"SecadorManos",Vector3(w*0.5-0.3,1.7,d*0.37),Vector3(0.35,0.5,0.45),"white")

func side_room(title: String,rect: Rect2,positive: bool,kind: String) -> void:
	var center := rect.get_center()
	var swapped := Vector2(rect.size.y,rect.size.x)
	var r := room(title,Rect2(center-swapped*0.5,swapped),positive,kind)
	r.rotation.y = PI/2
	r.set_meta("planta",rect)
	entries[-1]["posicion"] = CampusNodes.obtener(r, "Puerta").global_position

func apply() -> Dictionary:
	restore_original()
	return add_rear_rooms()

func add_rear_rooms() -> Dictionary:
	palette()
	entries.clear()
	global_position = Vector3(0,HEIGHT,0)
	trim_lower_wall_collision()
	# Ocupar el recinto completo hasta el frente original en z = -140.
	# Cada acceso se abre directamente al pasillo original.
	var original_front := CampusNodes.obtener(get_parent(), "Delantera_piso 4") as MeshInstance3D
	original_front.hide()
	for col in original_front.find_children("*","CollisionShape3D",true,false): col.disabled = true
	var z_back := -162.44
	var depth := 22.44
	var x_left := -71.2
	var widths := [9.6,9.6,8.6,8.2,8.991]
	var titles := ["411","412","413","BAÑO MUJERES","416"]
	for i in range(5):
		room(titles[i],Rect2(x_left,z_back,widths[i],depth),true,"bath" if i==3 else "class")
		x_left += widths[i]
	# Completar el costado en la línea del límite existente, sin alterar el pasillo.
	box(self,"CierreCostadoSector",Vector3(x_left,5.975,z_back+depth*0.5),Vector3(0.2,11.95,depth),"wall",true)
	set_meta("salas_posteriores",4)
	set_meta("alcance","411, 412, 413, baño mujeres, 416")
	set_meta("profundidad_sector",depth)
	return {"salas":4,"banos_mujeres":1,"profundidad":depth,"frente_original_z":-140,"mesas_por_sala":9,"sillas_por_sala":9}

func overview() -> void:
	var viewport := EditorInterface.get_editor_viewport_3d(0)
	var camera := viewport.get_camera_3d()
	camera.position = Vector3(-110,160,-20)
	camera.look_at(Vector3(0,HEIGHT,-125))



func preview_runtime() -> void:
	var campus := get_parent().get_parent()
	for n in campus.find_children("*","GeometryInstance3D",true,false):
		if n is MeshInstance3D and n.mesh:
			var b: AABB = n.global_transform*n.get_aabb()
			if b.position.y>HEIGHT+10 or b.end.y<HEIGHT-0.8: n.hide()
		elif n is CSGBox3D:
			var b: AABB = n.global_transform*AABB(-n.size*0.5,n.size)
			if b.position.y>HEIGHT+10 or b.end.y<HEIGHT-0.8: n.hide()
	for n in campus.find_children("*","CanvasLayer",true,false): n.hide()
	var camera := Camera3D.new()
	campus.add_child(camera)
	camera.global_position = Vector3(-85,170,-15)
	camera.look_at(Vector3(0,HEIGHT,-124))
	camera.make_current()
	var sun := DirectionalLight3D.new()
	campus.add_child(sun)
	sun.rotation_degrees = Vector3(-65,-25,0)
	sun.light_energy = 1.5


func restore_original() -> Dictionary:
	for child in get_children():
		remove_child(child)
		child.free()
	for child in get_parent().get_children():
		if child.has_meta("piso4_sector_docentes_front") or child.has_meta("piso4_fila_frontal") or child.has_meta("piso4_salas_centrales"): continue
		if child is MeshInstance3D and (str(child.name).begins_with("Delantera_piso") or str(child.name).begins_with("Front_Left piso 4 sur") and str(child.name)!="Front_Left piso 4 sur3"):
			child.show()
			for col in child.find_children("*","CollisionShape3D",true,false): col.disabled = false
	for key in ["salas","sectores_banos","entradas","referencia","salas_posteriores","alcance"]:
		if has_meta(key): remove_meta(key)
	return {"distribucion_original_restaurada":true}

func validate_rooms() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var failures: Array = []
	var count := 0
	for r in get_children():
		if not r.has_meta("planta"): continue
		count += 1
		var door = CampusNodes.obtener(r, "Puerta")
		var outward: Vector3 = door.global_basis.z
		player.global_position = door.global_position+outward*1.8+Vector3(0,0.15,0)
		for i in range(40): await get_tree().physics_frame
		var query := PhysicsRayQueryParameters3D.create(door.global_position+outward*1.5+Vector3(0,1.4,0),door.global_position-outward*1.5+Vector3(0,1.4,0))
		query.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty(): failures.append({"recinto":str(r.name),"obstaculo":str(hit.collider.get_path())})
		for p in [door.global_position+outward,door.global_position-outward,r.global_position]:
			var floor_query := PhysicsRayQueryParameters3D.create(p+Vector3(0,0.5,0),p-Vector3(0,0.6,0))
			floor_query.exclude = [player.get_rid()]
			var floor_hit := get_world_3d().direct_space_state.intersect_ray(floor_query)
			if floor_hit.is_empty(): failures.append({"recinto":str(r.name),"piso_ausente":p})
			elif p == r.global_position: print("PISO_SECTOR ",str(r.name)," ",floor_hit.collider.get_path())
	set_meta("validacion",{"recintos":count,"fallos":failures})
	print("PISO4_REAR_CHECK ",JSON.stringify(get_meta("validacion")))


func preview_sector() -> void:
	var campus := get_parent().get_parent()
	for n in campus.find_children("*","GeometryInstance3D",true,false):
		if not is_ancestor_of(n): n.hide()
	# Mostrar el piso y las paredes originales que delimitan este sector.
	for title in ["Building_Floor Piso 3a2","Wall_Back4","Wall_Right piso 4 c5","Wall_Right piso 3a"]:
		CampusNodes.obtener(get_parent(), title).show()
	for n in campus.find_children("*","MeshInstance3D",true,false):
		if str(n.name).begins_with("Piso4_Cierre"): n.show()
	for n in campus.find_children("*","Light3D",true,false):
		if not is_ancestor_of(n): n.light_energy = 0
	for n in campus.find_children("*","CanvasLayer",true,false): n.hide()
	var camera := Camera3D.new()
	campus.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 34
	camera.global_position = Vector3(-48.65,100,-139)
	camera.look_at(Vector3(-48.65,HEIGHT+2,-151.22))
	camera.make_current()
	var sun := DirectionalLight3D.new()
	campus.add_child(sun)
	sun.rotation_degrees = Vector3(-65,-25,0)
	sun.light_energy = 0.8



func check_walk_access() -> void:
	var player = get_tree().get_first_node_in_group("player")
	player.set_physics_process(false)
	var actor := CharacterBody3D.new()
	actor.floor_snap_length = 0.5
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 2.7
	collision.shape = shape
	collision.position.y = 1.35
	actor.add_child(collision)
	get_parent().get_parent().add_child(actor)
	actor.add_collision_exception_with(player)
	var report: Array = []
	for r in get_children():
		if not r.has_meta("planta"): continue
		var door = CampusNodes.obtener(r, "Puerta")
		var outward: Vector3 = door.global_basis.z
		player.global_position = door.global_position + outward*1.5 + Vector3(0,0.1,0)
		actor.global_position = door.global_position + outward*2.5 + Vector3(0,0.1,0)
		for i in range(50): await get_tree().physics_frame
		var reached := false
		var blocked_by: Array = []
		for frame in range(180):
			await get_tree().physics_frame
			actor.velocity = -outward*2.5
			actor.velocity.y = -1 if actor.is_on_floor() else actor.velocity.y-14.0/60
			actor.move_and_slide()
			if (actor.global_position-door.global_position).dot(outward)<-1.8:
				reached = true
				break
			for i in range(actor.get_slide_collision_count()):
				var hit := actor.get_slide_collision(i)
				if absf(hit.get_normal().z)>0.3:
					var path := str(hit.get_collider().get_path())
					if not blocked_by.has(path): blocked_by.append(path)
		report.append({"sala":str(r.name),"entro":reached,"posicion":actor.global_position,"colisiones":blocked_by})
	actor.queue_free()
	player.set_physics_process(true)
	set_meta("prueba_caminando",report)
	print("PISO4_WALK ",JSON.stringify(report))

func trim_lower_wall_collision(wall_path: String = "Piso 3/Delantera_piso 3") -> void:
	# El muro del piso inferior sobresalía unos centímetros por encima del suelo
	# del piso 4. Recortar solo ese exceso físico, conservando la pared inferior.
	var wall := CampusNodes.obtener(get_parent().get_parent(), wall_path)
	for col in wall.find_children("*","CollisionShape3D",true,false):
		if not col.shape is BoxShape3D: continue
		var b: AABB = col.global_transform*AABB(-col.shape.size*0.5,col.shape.size)
		var limit := HEIGHT-0.04
		if b.end.y<=limit or b.position.y>=limit: continue
		var excess := b.end.y-limit
		var shape: BoxShape3D = col.shape.duplicate()
		shape.size.y -= excess/col.global_basis.y.length()
		col.shape = shape
		col.global_position.y -= excess*0.5
		col.set_meta("limite_colision_piso4",limit)



