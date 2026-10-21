@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
const LEVELS = [0.0,12.058385849,23.967668533,35.674415588,47.974849701,60.158504486,71.942184448,83.913551331]

func owned(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = get_tree().edited_scene_root

func box(parent: Node3D, title: String, pos: Vector3, dimensions: Vector3, material: Material, solid: bool = true) -> CSGBox3D:
	var n := CSGBox3D.new()
	n.name = title
	n.position = pos
	n.size = dimensions
	n.material = material
	n.use_collision = solid
	owned(parent,n)
	return n

func build() -> Dictionary:
	var root := CampusNodes.campus(self)
	if CampusNodes.buscar(root, "Piso2/SalaImpresiones"):
		return {"status":"already_built"}
	var cream: Material = load("res://materials/entrance/MAT_Corridor_Cladding_Light.tres")
	var dark: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var wood: Material = load("res://materials/entrance/MAT_Madera_Biblioteca.tres")
	var white: Material = load("res://materials/entrance/MAT_Puerta_Ascensor_Grafica.tres")
	var library := CampusNodes.obtener(root, "Piso2/Biblioteca")
	var room := Node3D.new()
	room.name = "SalaImpresiones"
	owned(CampusNodes.obtener(root, "Piso2"),room)
	room.global_position = Vector3(0,LEVELS[1],0)
	room.set_meta("independiente_de_biblioteca",true)
	var rear := CampusNodes.obtener(library, "ParedPosteriorVidrio") as CSGBox3D
	rear.position.x = -66.25
	rear.size.x = 20.5
	box(room,"FrenteIzquierdo",Vector3(-83.125,6,-122.7),Vector3(3.25,12,0.16),cream)
	box(room,"DintelAcceso",Vector3(-79,7.6,-122.7),Vector3(5,8.8,0.16),cream)
	box(room,"SeparacionBiblioteca",Vector3(-73,6,-116.65),Vector3(0.16,12,12.1),cream)
	box(room,"ParedFondo",Vector3(-78.875,6,-110.6),Vector3(11.75,12,0.16),cream)
	var sign_label := CampusNodes.obtener(library, "Letrero").duplicate() as Label3D
	sign_label.name = "LetreroImpresiones"
	sign_label.text = "IMPRESIONES Y ARTICULOS"
	sign_label.font_size = 56
	sign_label.pixel_size = 0.005
	owned(room,sign_label)
	sign_label.position = Vector3(-79,3.65,-122.82)
	box(room,"Mostrador",Vector3(-78.8,0.9,-115.8),Vector3(7.8,1.8,1.2),cream)
	box(room,"CubiertaMostrador",Vector3(-78.8,1.85,-115.8),Vector3(8,0.12,1.35),wood)
	box(room,"Impresora",Vector3(-80.8,2.3,-115.8),Vector3(1.4,0.8,0.9),white)
	box(room,"BandejaImpresora",Vector3(-80.8,2.75,-115.8),Vector3(1,0.08,0.65),dark,false)
	box(room,"PantallaImpresora",Vector3(-80.8,2.4,-116.27),Vector3(0.5,0.22,0.04),dark,false)
	box(room,"Copiadora",Vector3(-82.8,1,-112.2),Vector3(1.5,2,1.4),white)
	box(room,"TapaCopiadora",Vector3(-82.8,2.05,-112.2),Vector3(1.55,0.15,1.45),dark)
	for shelf in range(3):
		box(room,"RepisaArticulos"+str(shelf),Vector3(-76.7,1.1+shelf*1.05,-111),Vector3(4.6,0.12,0.55),wood)
		for item in range(5):
			box(room,"Papeleria"+str(shelf)+"_"+str(item),Vector3(-78.5+item*0.85,1.33+shelf*1.05,-111),Vector3(0.55,0.32,0.35),white,false)
	for index in [1,2]:
		CampusNodes.obtener(library, "PuestosComputadores/Puesto%02d" % index).position.z = -94
	configurar_pared_vidrio()
	configurar_ventanilla()
	return {"sala_independiente":true,"ventanilla":true,"vidrio_interior_escalera":false,"paneles_vidrio":0}

func configurar_pared_vidrio() -> Dictionary:
	return configurar_costados_referencia()

func configurar_ventanilla() -> Dictionary:
	var room := CampusNodes.obtener(CampusNodes.campus(self), "Piso2/SalaImpresiones") as Node3D
	var door := CampusNodes.buscar(room, "EntradaIndependiente")
	if door:
		room.remove_child(door)
		door.free()
	if CampusNodes.buscar(room, "VentanillaAtencion"):
		return {"ventanilla":true,"acceso_publico":false}
	var cream: Material = load("res://materials/entrance/MAT_Corridor_Cladding_Light.tres")
	var dark: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var glass: Material = load("res://materials/entrance/MAT_Glass_Entrance.tres")
	var window := Node3D.new()
	window.name = "VentanillaAtencion"
	owned(room,window)
	box(window,"ParedBajoVentanilla",Vector3(-79,0.9,-122.7),Vector3(5,1.8,0.16),cream)
	box(window,"JambaIzquierda",Vector3(-81.05,2.5,-122.7),Vector3(0.9,1.4,0.16),cream)
	box(window,"JambaDerecha",Vector3(-76.95,2.5,-122.7),Vector3(0.9,1.4,0.16),cream)
	# A small transfer slot remains above the counter; the glass blocks entry.
	box(window,"CristalVentanilla",Vector3(-79,2.65,-122.7),Vector3(3.2,1.1,0.06),glass)
	for x in [-80.6,-77.4]:
		box(window,"MarcoVertical"+str(x),Vector3(x,2.55,-122.75),Vector3(0.07,1.3,0.1),dark)
	for y in [2.1,3.16]:
		box(window,"MarcoHorizontal"+str(y),Vector3(-79,y,-122.75),Vector3(3.2,0.07,0.1),dark)
	var counter := CampusNodes.obtener(room, "Mostrador") as CSGBox3D
	counter.position = Vector3(-79,0.9,-122.1)
	counter.size = Vector3(3.4,1.8,1.2)
	var surface := CampusNodes.obtener(room, "CubiertaMostrador") as CSGBox3D
	surface.position = Vector3(-79,1.85,-122.7)
	surface.size = Vector3(3.4,0.12,0.85)
	room.set_meta("acceso_publico",false)
	room.set_meta("atencion_por_ventanilla",true)
	return {"ventanilla":true,"acceso_publico":false}

func vista_piso_dos() -> Dictionary:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(0,280,-140)
	camera.look_at(Vector3(0,0,-140),Vector3.FORWARD)
	return {"position":camera.global_position}

func configurar_costados_referencia() -> Dictionary:
	var root := CampusNodes.campus(self)
	var glass := ShaderMaterial.new()
	glass.shader = load("res://materials/entrance/vidrio_costados_referencia.gdshader")
	glass.resource_name = "VidrioAzulCostadosReferencia"
	var concrete := StandardMaterial3D.new()
	concrete.resource_name = "MuroGrisCostadosReferencia"
	concrete.albedo_color = Color(0.32,0.34,0.35)
	concrete.roughness = 0.9
	var dark: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var window: Material = load("res://materials/entrance/MAT_Glass_Entrance.tres")
	var floor_names = ["Piso2","Piso 3","Piso 4"]
	for index in range(3):
		var level := CampusNodes.obtener(root, floor_names[index])
		if CampusNodes.buscar(level, "CostadosReferencia"):
			continue
		var old := CampusNodes.buscar(level, "VidrioEscaleraYPasillo")
		if old:
			level.remove_child(old)
			old.free()
		if index == 0:
			var old_library := CampusNodes.obtener(root, "Piso2/Biblioteca/ParedIzquierdaSectorPosterior") as CSGBox3D
			old_library.visible = false
			old_library.use_collision = false
		# Cut the existing east wall back to the solid front-room area.
		var east := CampusNodes.obtener(level, "Wall_Right2" if index == 0 else "Wall_Right3") as MeshInstance3D
		var bounds: AABB = east.global_transform * east.get_aabb()
		var dimensions := Vector3(bounds.size.x,bounds.size.y,bounds.end.z+122.7)
		var front_mesh := BoxMesh.new()
		front_mesh.size = dimensions
		east.mesh = front_mesh
		east.global_position = Vector3(bounds.get_center().x,bounds.get_center().y,(-122.7+bounds.end.z)*0.5)
		for collision in east.find_children("*","CollisionShape3D",true,false):
			var shape := BoxShape3D.new()
			shape.size = dimensions
			collision.shape = shape
			collision.global_position = east.global_position
		var finishes := Node3D.new()
		finishes.name = "CostadosReferencia"
		owned(level,finishes)
		finishes.global_position = Vector3.ZERO
		var bottom: float = LEVELS[index+1]
		var top: float = LEVELS[index+2]
		var height := top-bottom
		for side in range(2):
			var x: float = -85.0 if side == 0 else bounds.get_center().x
			var group := Node3D.new()
			group.name = "CostadoIzquierdo" if side == 0 else "CostadoDerecho"
			owned(finishes,group)
			# Tall blue glass is confined to the staircase tower.
			box(group,"VidrioTorreEscalera",Vector3(x,(bottom+top)*0.5,-151.46),Vector3(0.12,height,22.92),glass)
			for z in [-162.92,-140.0]:
				box(group,"MarcoTorre"+str(z),Vector3(x,(bottom+top)*0.5,z),Vector3(0.18,height,0.12),dark)
			for y in [bottom+0.06,top-0.06]:
				box(group,"BordeTorre"+str(y),Vector3(x,y,-151.46),Vector3(0.18,0.12,22.92),dark)
			# Grey corridor wall with a real narrow horizontal window opening.
			var window_z := -132.0
			var window_y := bottom+6.0
			var window_width := 4.4
			var window_height := 1.1
			var lower_height := window_y-window_height*0.5-bottom
			var upper_height := top-(window_y+window_height*0.5)
			box(group,"MuroBajoVentana",Vector3(x,bottom+lower_height*0.5,-131.35),Vector3(0.3,lower_height,17.3),concrete)
			box(group,"MuroSobreVentana",Vector3(x,top-upper_height*0.5,-131.35),Vector3(0.3,upper_height,17.3),concrete)
			var left_end := window_z-window_width*0.5
			var right_start := window_z+window_width*0.5
			box(group,"MuroJuntoTorre",Vector3(x,window_y,(-140.0+left_end)*0.5),Vector3(0.3,window_height,left_end+140.0),concrete)
			box(group,"MuroHaciaSalas",Vector3(x,window_y,(right_start-122.7)*0.5),Vector3(0.3,window_height,-122.7-right_start),concrete)
			box(group,"VentanaHorizontal",Vector3(x,window_y,window_z),Vector3(0.06,window_height,window_width),window)
			for y in [window_y-window_height*0.5,window_y+window_height*0.5]:
				box(group,"MarcoVentana"+str(y),Vector3(x,y,window_z),Vector3(0.34,0.06,window_width+0.1),dark)
			for z in [left_end,right_start]:
				box(group,"JambaVentana"+str(z),Vector3(x,window_y,z),Vector3(0.34,window_height,0.06),dark)
		finishes.set_meta("referencia","Torre de vidrio azul y muro gris con ventanas horizontales")
	return {"pisos":[2,3,4],"costados":2,"vidrio":"torre escalera","pasillo":"muro gris y ventana horizontal"}




