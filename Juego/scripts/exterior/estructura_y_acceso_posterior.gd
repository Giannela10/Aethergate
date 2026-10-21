@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")

# Four bridge entrances and three protected voids from the blue/yellow markup.
const TERRACE_ENTRY_RATIOS: Array[Vector2] = [Vector2(0.02,0.08),Vector2(0.25,0.35),Vector2(0.65,0.75),Vector2(0.92,0.98)]
const TERRACE_VOID_FRONT_Z := -111.0

func terrace_entries() -> Array[Vector2]:
	var floor_node := CampusNodes.obtener(CampusNodes.campus(self), "Piso 5/Building_Floor Piso 5") as MeshInstance3D
	var b: AABB = floor_node.global_transform * floor_node.get_aabb()
	var entries: Array[Vector2] = []
	for ratio in TERRACE_ENTRY_RATIOS:
		entries.append(Vector2(lerpf(b.position.x,b.end.x,ratio.x),lerpf(b.position.x,b.end.x,ratio.y)))
	return entries

func owned(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = get_tree().edited_scene_root

func box(parent: Node3D, title: String, position_value: Vector3, dimensions: Vector3, material: Material, solid: bool = true) -> CSGBox3D:
	var node := CSGBox3D.new()
	node.name = title
	node.position = position_value
	node.size = dimensions
	node.material = material
	node.use_collision = solid
	owned(parent,node)
	return node

func beam(parent: Node3D, title: String, start: Vector3, end: Vector3, material: Material) -> void:
	var node := box(parent,title,(start+end)*0.5,Vector3(0.08,0.08,start.distance_to(end)),material)
	node.look_at(end,Vector3.UP)

func build() -> Dictionary:
	var root := CampusNodes.campus(self)
	if get_child_count() > 0:
		return {"status":"already_built"}
	var concrete: Material = load("res://materials/entrance/MAT_Columns_Concrete.tres")
	var metal: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var paving: Material = load("res://materials/entrance/MAT_Terrace_Paving.tres")
	var white := StandardMaterial3D.new()
	white.resource_name = "CubiertaClaraReferenciaAerea"
	white.albedo_color = Color(0.86,0.88,0.89)
	white.roughness = 0.85
	# Recesses above the existing end staircase bays.
	var roof := CampusNodes.obtener(root, "Piso 8/Building_Floor Piso 8 Techo") as MeshInstance3D
	var roof_bounds: AABB = roof.global_transform * roof.get_aabb()
	roof.visible = false
	for collision in roof.find_children("*","CollisionShape3D",true,false):
		collision.disabled = true
	var roof_group := Node3D.new()
	roof_group.name = "CubiertaConEntrantesLaterales"
	owned(self,roof_group)
	var roof_y := roof_bounds.get_center().y
	var front_z := -139.7
	var left_x := -70.7
	var right_x := 70.6
	box(roof_group,"CubiertaCentral",Vector3((left_x+right_x)*0.5,roof_y,roof_bounds.get_center().z),Vector3(right_x-left_x,0.5,roof_bounds.size.z),white)
	for interval in [Vector2(roof_bounds.position.x,left_x),Vector2(right_x,roof_bounds.end.x)]:
		box(roof_group,"CubiertaExtremo"+str(interval.x),Vector3((interval.x+interval.y)*0.5,roof_y,(front_z+roof_bounds.end.z)*0.5),Vector3(interval.y-interval.x,0.5,roof_bounds.end.z-front_z),white)
		box(roof_group,"BordeEntrante"+str(interval.x),Vector3((interval.x+interval.y)*0.5,roof_y+0.65,front_z),Vector3(interval.y-interval.x,0.8,0.18),white)
	for x in [left_x,right_x]:
		box(roof_group,"BordeLongitudinalEntrante"+str(x),Vector3(x,roof_y+0.65,(roof_bounds.position.z+front_z)*0.5),Vector3(0.18,0.8,front_z-roof_bounds.position.z),white)
	roof_group.set_meta("entrantes",2)
	# Terrace inset at both ends, with fences and furniture following its footprint.
	var terrace_floor := CampusNodes.obtener(root, "Piso 5/Building_Floor Piso 5") as MeshInstance3D
	var mesh := terrace_floor.mesh.duplicate() as BoxMesh
	var terrace_ratio := 138.0/mesh.size.x
	mesh.size.x = 138.0
	terrace_floor.mesh = mesh
	for collision in terrace_floor.find_children("*","CollisionShape3D",true,false):
		var shape := collision.shape.duplicate() as BoxShape3D
		shape.size.x = 138.0
		collision.shape = shape
	var terrace := CampusNodes.obtener(root, "Piso 5/TerrazaPicnic")
	CampusNodes.obtener(terrace, "CercaVidrio").scale.x *= terrace_ratio
	for furniture in CampusNodes.obtener(terrace, "MobiliarioReferencia").get_children():
		if furniture is Node3D and str(furniture.name) != "MarcosVidrio":
			furniture.position.x *= terrace_ratio
	terrace.set_meta("ancho_referencia_aerea",138.0)
	# Small pedestrian access beside the parked cars.
	var entrance := Node3D.new()
	entrance.name = "EntradaPosteriorEstacionamientos"
	entrance.position.x = 18.0
	owned(self,entrance)
	var wall := CampusNodes.obtener(root, "Piso1/Wall_Back2") as MeshInstance3D
	var bounds: AABB = wall.global_transform * wall.get_aabb()
	var facade: Material = wall.material_override
	if facade == null:
		facade = concrete
	wall.visible = false
	for collision in wall.find_children("*","CollisionShape3D",true,false):
		collision.disabled = true
	var z := bounds.get_center().z
	box(entrance,"MuroIzquierdoAcceso",Vector3((bounds.position.x-18.0-2.5)*0.5,6,z),Vector3(-2.5-(bounds.position.x-18.0),12,0.5),facade)
	box(entrance,"MuroDerechoAcceso",Vector3((bounds.end.x-18.0+2.5)*0.5,6,z),Vector3(bounds.end.x-18.0-2.5,12,0.5),facade)
	box(entrance,"DintelAccesoPosterior",Vector3(0,8.25,z),Vector3(5,7.5,0.5),facade)
	box(entrance,"BaseUmbralAcceso",Vector3(0,0.65,z),Vector3(5,1.3,0.5),concrete)
	box(entrance,"DescansoExterior",Vector3(0,0.65,-164),Vector3(6,1.3,2.4),paving)
	box(entrance,"DescansoInterior",Vector3(0,0.65,-161.8),Vector3(5.2,1.3,1.8),paving)
	for index in range(6):
		var top := 0.22+(index+1)*0.18
		box(entrance,"Peldano"+str(index+1),Vector3(0,top*0.5,-167.9+(index+0.5)*0.45),Vector3(6,top,0.45),concrete)
		for x in [-2.95,2.95]:
			box(entrance,"Poste"+str(index)+"_"+str(x),Vector3(x,top+0.525,-167.9+(index+0.5)*0.45),Vector3(0.07,1.05,0.07),metal)
	for x in [-2.95,2.95]:
		beam(entrance,"PasamanosEscalera"+str(x),Vector3(x,1.45,-167.8),Vector3(x,2.35,-165.2),metal)
		beam(entrance,"PasamanosDescanso"+str(x),Vector3(x,2.35,-165.2),Vector3(x,2.35,-162.8),metal)
	var ramp := box(entrance,"ConexionInterior",Vector3(0,0.58,-158.15),Vector3(5.2,0.14,sqrt(5.5*5.5+1.3*1.3)),paving)
	ramp.rotation.x = atan(1.3/5.5)
	var door := CampusNodes.obtener(root, "Piso2/Biblioteca/EntradaVidrio").duplicate() as Node3D
	door.name = "PuertaPosterior"
	owned(entrance,door)
	door.position = Vector3(0,1.3,z)
	for descendant in door.find_children("*","",true,false):
		descendant.owner = get_tree().edited_scene_root
	var sign_label := CampusNodes.obtener(root, "Piso2/Biblioteca/Letrero").duplicate() as Label3D
	sign_label.name = "LetreroAccesoPosterior"
	sign_label.text = "ACCESO SEDE"
	owned(entrance,sign_label)
	sign_label.position = Vector3(0,4.9,z-0.3)
	for vehicle in CampusNodes.obtener(root, "PatioPosteriorDuoc/Estacionamientos").get_children():
		if vehicle is Node3D and str(vehicle.name).begins_with("Auto") and absf(vehicle.position.x-18.0) < 6:
			vehicle.position.z -= 12.0
	box(entrance,"PasoPeatonal",Vector3(0,0.24,-172),Vector3(6,0.06,8.2),concrete)
	for marking in CampusNodes.obtener(root, "PatioPosteriorDuoc/Estacionamientos").get_children():
		if marking is GeometryInstance3D and str(marking.name).begins_with("Demarcacion") and absf(marking.position.x-18.0)<5:
			marking.visible = false
	set_meta("referencia","Vista aerea: entrantes en extremos, terraza retraida y acceso junto a los autos")
	ajustar_orillas_referencia()
	return {"entradas_terraza":4,"vacios_protegidos":3,"terraza_ancho_original":true,"acceso_posterior":true,"peldanos":6}

func alinear_terraza() -> Dictionary:
	var root := CampusNodes.campus(self)
	var west := CampusNodes.obtener(root, "Piso 4/Front_Left piso 4 sur3") as MeshInstance3D
	var east := CampusNodes.obtener(root, "Piso 4/Wall_Right3") as MeshInstance3D
	var center_x := (west.global_position.x + east.global_position.x) * 0.5
	# Restore the full original slab width; only the three yellow wells are cut.
	var full_width := east.global_position.x - west.global_position.x + 0.5
	var floor_node := CampusNodes.obtener(root, "Piso 5/Building_Floor Piso 5") as MeshInstance3D
	var terrace_mesh := floor_node.mesh.duplicate() as BoxMesh
	terrace_mesh.size.x = full_width
	floor_node.mesh = terrace_mesh
	floor_node.global_position.x = center_x
	for collision in floor_node.find_children("*","CollisionShape3D",true,false):
		if collision.get_parent() != floor_node and collision.get_parent().get_parent() != floor_node: continue
		var shape := BoxShape3D.new()
		shape.size = terrace_mesh.size
		collision.shape = shape
		collision.global_position = floor_node.global_position
	var terrace := CampusNodes.obtener(root, "Piso 5/TerrazaPicnic")
	var fence := CampusNodes.obtener(terrace, "CercaVidrio") as Node3D
	var left := CampusNodes.obtener(fence, "Izquierda/Panel01") as CSGBox3D
	var right := CampusNodes.obtener(fence, "Derecha/Panel01") as CSGBox3D
	# Panels are nested under the side groups, so measure their world centers.
	var current_width := absf(right.global_position.x-left.global_position.x)
	if current_width > 0.01:
		fence.scale.x *= full_width/current_width
	var fence_center := (left.global_position.x+right.global_position.x)*0.5
	fence.global_position.x += center_x-fence_center
	var furniture := CampusNodes.obtener(terrace, "MobiliarioReferencia") as Node3D
	furniture.global_position.x = center_x
	for i in range(10):
		CampusNodes.obtener(furniture, "SombrillaMesa%02d" % (i+1)).position.x = -72.0 + i * 16.0
	for i in range(7):
		CampusNodes.obtener(furniture, "ZonaCafe%02d" % (i+1)).position.x = -66.0 + i * 22.0
	terrace.set_meta("ancho_referencia_aerea", full_width)
	return {"centro_x":center_x,"ancho_losa":terrace_mesh.size.x,"barandas_y_colision":"alineadas"}

func ajustar_orillas_referencia() -> Dictionary:
	var campus := CampusNodes.campus(self)
	var roof := CampusNodes.obtener(campus, "Piso 8/Building_Floor Piso 8 Techo") as MeshInstance3D
	var bounds: AABB = roof.global_transform * roof.get_aabb()
	var group := CampusNodes.obtener(self, "CubiertaConEntrantesLaterales")
	for child in group.get_children():
		group.remove_child(child)
		child.free()
	var white := StandardMaterial3D.new()
	white.resource_name = "CubiertaClaraReferenciaAerea"
	white.albedo_color = Color(0.86,0.88,0.89)
	white.roughness = 0.85
	box(group,"CubiertaPrincipalRecta",bounds.get_center(),bounds.size,white)
	var rim_y := bounds.end.y+0.45
	for z in [bounds.position.z,bounds.end.z]:
		box(group,"BordeLongitudinal"+str(z),Vector3(bounds.get_center().x,rim_y,z),Vector3(bounds.size.x,0.9,0.25),white)
	for x in [bounds.position.x,bounds.end.x]:
		box(group,"BordeExtremo"+str(x),Vector3(x,rim_y,bounds.get_center().z),Vector3(0.25,0.9,bounds.size.z),white)
	group.name = "CubiertaConEntrantesLaterales"
	group.set_meta("entrantes",0)
	group.set_meta("contorno_referencia","Cubierta rectangular; entrantes en la terraza inferior")
	var terrace_result := alinear_terraza()
	var floor_node := CampusNodes.obtener(campus, "Piso 5/Building_Floor Piso 5") as MeshInstance3D
	var terrace_bounds: AABB = floor_node.global_transform * floor_node.get_aabb()
	var old := CampusNodes.buscar(self, "BordesTerrazaReferencia")
	if old:
		remove_child(old)
		old.free()
	var borders := Node3D.new()
	borders.name = "BordesTerrazaReferencia"
	owned(self,borders)
	var concrete: Material = load("res://materials/entrance/MAT_Columns_Concrete.tres")
	# Solid fascia below the walking surface follows the inset footprint.
	for x in [terrace_bounds.position.x,terrace_bounds.end.x]:
		box(borders,"CantoLateral"+str(x),Vector3(x,terrace_bounds.end.y-0.45,terrace_bounds.get_center().z),Vector3(0.3,0.9,terrace_bounds.size.z),concrete)
	box(borders,"CantoFrontal",Vector3(terrace_bounds.get_center().x,terrace_bounds.end.y-0.45,terrace_bounds.end.z),Vector3(terrace_bounds.size.x,0.9,0.3),concrete)
	set_meta("referencia","Captura marcada: cuatro entradas azules, tres vacios amarillos con barandas; terraza de ancho original")
	distribuir_terraza_referencia()
	abrir_entradas_terraza()
	return {"cubierta":str(bounds),"terraza":terrace_result,"entradas":4,"vacios_protegidos":3}

func vista_terraza_cercana() -> void:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(0,100,-43)
	camera.look_at(Vector3(0,49,-112),Vector3.UP)

func vista_orillas_referencia() -> void:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(-145,150,-35)
	camera.look_at(Vector3(0,64,-120),Vector3.UP)

func distribuir_terraza_referencia() -> Dictionary:
	var terrace := CampusNodes.obtener(CampusNodes.campus(self), "Piso 5/TerrazaPicnic") as Node3D
	var furniture := CampusNodes.obtener(terrace, "MobiliarioReferencia") as Node3D
	var umbrella_x: Array[float] = [-68,-55,-45,-12,-4,4,12,45,55,68]
	for i in range(10):
		var n := CampusNodes.obtener(furniture, "SombrillaMesa%02d" % (i+1)) as Node3D
		n.position.x = umbrella_x[i]
		n.position.z = -99.0
	var cafe_x: Array[float] = [-65,-48,-12,0,12,48,65]
	for i in range(7):
		var n := CampusNodes.obtener(furniture, "ZonaCafe%02d" % (i+1)) as Node3D
		n.position.x = cafe_x[i]
		n.position.z = -88.0
	var old := CampusNodes.buscar(terrace, "ZonasCubiertasReferencia")
	if old:
		terrace.remove_child(old)
		old.free()
	# The pale/yellow strips are inaccessible wells, not glass-roof seating.
	construir_vacios_terraza()
	terrace.set_meta("distribucion_referencia","Tres zonas de mesas frente a los vacios; cuatro entradas intermedias")
	return {"vacios_protegidos":3,"sombrillas":10,"mesas_cafe":7,"entradas":4}

func construir_vacios_terraza() -> void:
	var terrace := CampusNodes.obtener(CampusNodes.campus(self), "Piso 5/TerrazaPicnic") as Node3D
	var original := CampusNodes.obtener(CampusNodes.campus(self), "Piso 5/Building_Floor Piso 5") as MeshInstance3D
	var b: AABB = original.global_transform*original.get_aabb()
	original.visible = false
	for c in original.find_children("*","CollisionShape3D",true,false): c.disabled = true
	for title in ["PlataformaConEntradas","BarandasVacios"]:
		var old := CampusNodes.buscar(terrace, title)
		if old:
			terrace.remove_child(old)
			old.free()
	var platform := Node3D.new()
	platform.name = "PlataformaConEntradas"
	owned(terrace,platform)
	var paving: Material = original.material_override
	if paving == null: paving = load("res://materials/entrance/MAT_Terrace_Paving.tres")
	var glass: Material = load("res://materials/entrance/MAT_Glass_Entrance.tres")
	var metal: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	box(platform,"LosaTerrazaCompleta",Vector3(b.get_center().x,-0.25,(TERRACE_VOID_FRONT_Z+b.end.z)*0.5),Vector3(b.size.x,0.5,b.end.z-TERRACE_VOID_FRONT_Z),paving)
	var entries := terrace_entries()
	var bridge_spans: Array[Vector2] = entries.duplicate()
	bridge_spans.append(Vector2(b.position.x,entries.front().x))
	bridge_spans.append(Vector2(entries.back().y,b.end.x))
	for i in range(bridge_spans.size()):
		var span := bridge_spans[i]
		box(platform,"PuenteAcceso"+str(i+1),Vector3((span.x+span.y)*0.5,-0.25,(b.position.z+TERRACE_VOID_FRONT_Z)*0.5),Vector3(span.y-span.x,0.5,TERRACE_VOID_FRONT_Z-b.position.z),paving)
	var rails := Node3D.new()
	rails.name = "BarandasVacios"
	owned(terrace,rails)
	for i in range(3):
		var span := Vector2(entries[i].y,entries[i+1].x)
		var well := Node3D.new()
		well.name = "VacioAmarillo"+str(i+1)
		owned(rails,well)
		var center := (span.x+span.y)*0.5
		box(well,"VidrioFrente",Vector3(center,0.85,TERRACE_VOID_FRONT_Z+0.04),Vector3(span.y-span.x,1.7,0.08),glass)
		box(well,"PasamanosFrente",Vector3(center,1.73,TERRACE_VOID_FRONT_Z+0.04),Vector3(span.y-span.x,0.07,0.1),metal,false)
		var count := maxi(1,ceili((span.y-span.x)/3.0))
		for j in range(count+1):
			var x := lerpf(span.x,span.y,float(j)/count)
			box(well,"Poste"+str(j),Vector3(x,0.85,TERRACE_VOID_FRONT_Z+0.04),Vector3(0.08,1.7,0.08),metal,false)
		for x in [span.x+0.04,span.y-0.04]:
			box(well,"VidrioLateral"+str(x),Vector3(x,0.85,(b.position.z+TERRACE_VOID_FRONT_Z)*0.5),Vector3(0.08,1.7,TERRACE_VOID_FRONT_Z-b.position.z),glass)
			box(well,"PasamanosLateral"+str(x),Vector3(x,1.73,(b.position.z+TERRACE_VOID_FRONT_Z)*0.5),Vector3(0.1,0.07,TERRACE_VOID_FRONT_Z-b.position.z),metal,false)
		well.set_meta("zona_inaccesible",true)
		well.set_meta("area_no_transitable",Rect2(span.x,b.position.z,span.y-span.x,TERRACE_VOID_FRONT_Z-b.position.z))
	platform.set_meta("ancho_original",b.size.x)
	platform.set_meta("entradas",4)

func abrir_entradas_terraza() -> Dictionary:
	var floor_group := CampusNodes.obtener(CampusNodes.campus(self), "Piso 5")
	var terrace := CampusNodes.obtener(floor_group, "TerrazaPicnic") as Node3D
	for title in ["Delantera_piso 6","Delantera_piso 6a","MeshInstance3D","Delantera_piso 5a3","Delantera_piso 5a4"]:
		var wall := CampusNodes.obtener(floor_group, title) as MeshInstance3D
		wall.visible = false
		for c in wall.find_children("*","CollisionShape3D",true,false): c.disabled = true
	CampusNodes.obtener(terrace, "MobiliarioReferencia/MarcosVidrio").visible = false
	var old := CampusNodes.buscar(terrace, "FachadaConEntradas")
	if old:
		terrace.remove_child(old)
		old.free()
	var facade := Node3D.new()
	facade.name = "FachadaConEntradas"
	owned(terrace,facade)
	var glass: Material = load("res://materials/entrance/MAT_Glass_Entrance.tres")
	var metal: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var paving: Material = CampusNodes.obtener(floor_group, "Building_Floor Piso 5").material_override
	if paving == null: paving = load("res://materials/entrance/MAT_Terrace_Paving.tres")
	var z := -122.24
	var entry_centers: Array[float] = []
	var wall_spans: Array[Vector2] = []
	var start := -85.12619
	for entry in terrace_entries():
		var x := (entry.x+entry.y)*0.5
		entry_centers.append(x)
		wall_spans.append(Vector2(start,x-3.0))
		start = x+3.0
	wall_spans.append(Vector2(start,84.57565))
	for span in wall_spans:
		box(facade,"VidrioFachada"+str(span.x),Vector3((span.x+span.y)*0.5,5.8,z),Vector3(span.y-span.x,11.6,0.18),glass)
		var count := maxi(1,ceili((span.y-span.x)/3.0))
		for i in range(count+1):
			var x := lerpf(span.x,span.y,float(i)/count)
			box(facade,"Montante"+str(x),Vector3(x,5.8,z+0.13),Vector3(0.07,11.6,0.08),metal,false)
		for y in [0.12,3.5,6.0,9.0,11.55]:
			box(facade,"Junta"+str(span.x)+str(y),Vector3((span.x+span.y)*0.5,y,z+0.13),Vector3(span.y-span.x,0.07,0.08),metal,false)
	for x in entry_centers:
		box(facade,"DintelVidrioEntrada"+str(x),Vector3(x,7.55,z),Vector3(6,8.1,0.18),glass)
		box(facade,"MarcoSuperiorEntrada"+str(x),Vector3(x,3.55,z+0.13),Vector3(6.2,0.1,0.12),metal,false)
		box(facade,"UmbralEntrada"+str(x),Vector3(x,-0.075,-122.4),Vector3(6,0.15,6.0),paving)
	terrace.set_meta("entradas_x",entry_centers)
	terrace.set_meta("ancho_entradas",6.0)
	return {"entradas":4,"centros_x":entry_centers,"ancho":6.0,"altura_libre":3.5,"sin_hojas_que_bloqueen":true}

func vista_terraza() -> Dictionary:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(-125,100,-62)
	camera.look_at(Vector3(-25,53,-112),Vector3.UP)
	return {"view":"terrace"}

func vista_aerea() -> Dictionary:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(0,265,-140)
	camera.look_at(Vector3(0,0,-140),Vector3.FORWARD)
	return {"view":"aerial"}

func alinear_acceso() -> Dictionary:
	var root := CampusNodes.campus(self)
	var entrance := CampusNodes.obtener(self, "EntradaPosteriorEstacionamientos") as Node3D
	entrance.position.x = 18.0
	var wall := CampusNodes.obtener(root, "Piso1/Wall_Back2") as MeshInstance3D
	var bounds: AABB = wall.global_transform * wall.get_aabb()
	var left := CampusNodes.obtener(entrance, "MuroIzquierdoAcceso") as CSGBox3D
	left.position.x = (bounds.position.x-18.0-2.5)*0.5
	left.size.x = -2.5-(bounds.position.x-18.0)
	var right := CampusNodes.obtener(entrance, "MuroDerechoAcceso") as CSGBox3D
	right.position.x = (bounds.end.x-18.0+2.5)*0.5
	right.size.x = bounds.end.x-18.0-2.5
	for vehicle in CampusNodes.obtener(root, "PatioPosteriorDuoc/Estacionamientos").get_children():
		if vehicle is Node3D and str(vehicle.name).begins_with("Auto"):
			if absf(vehicle.position.x)<6 and vehicle.position.z < -180:
				vehicle.position.z += 12
			if absf(vehicle.position.x-18.0)<6 and vehicle.position.z > -180:
				vehicle.position.z -= 12
		if vehicle is GeometryInstance3D and str(vehicle.name).begins_with("Demarcacion"):
			if absf(vehicle.position.x)<5:
				vehicle.visible = true
			if absf(vehicle.position.x-18.0)<5:
				vehicle.visible = false
	return {"entrada_x":18,"destino":"pasillo junto a ascensores"}

func vista_acceso() -> Dictionary:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(4,7,-183)
	camera.look_at(Vector3(18,2,-164),Vector3.UP)
	return {"view":"rear entrance"}



func ajustar_posterior_referencia() -> Dictionary:
	var root := CampusNodes.campus(self)
	var stone: Material = load("res://materials/entrance/MAT_Piedra_Posterior.tres")
	var metal: Material = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var concrete: Material = load("res://materials/entrance/MAT_Columns_Concrete.tres")
	for title in ["Estacionamiento","AccesoVehicular"]:
		CampusNodes.obtener(root, "PatioPosteriorDuoc/PavimentosYJardines/"+title).material_override = stone
	var old_entrance := CampusNodes.obtener(self, "EntradaPosteriorEstacionamientos") as Node3D
	old_entrance.visible = false
	for child in old_entrance.find_children("*","CSGShape3D",true,false): child.use_collision = false
	for child in old_entrance.find_children("*","CollisionShape3D",true,false): child.disabled = true
	var old := CampusNodes.buscar(self, "PosteriorReferenciaMarcada")
	if old: old.free()
	var group := Node3D.new()
	group.name = "PosteriorReferenciaMarcada"
	owned(self,group)
	box(group,"AndenPiedra",Vector3(0,0.175,-165.5),Vector3(170,0.08,6),stone)
	# Close the former entrances in the central glass facade.
	var central := CampusNodes.obtener(root, "Piso1/Wall_Back2") as MeshInstance3D
	var central_bounds: AABB = central.global_transform*central.get_aabb()
	box(group,"FachadaCentralRestituida",central_bounds.get_center(),central_bounds.size,central.material_override)
	var left_wall := CampusNodes.obtener(root, "Piso1/SalaAyudaEstudiantil/Wall_Back") as MeshInstance3D
	var right_wall := CampusNodes.obtener(root, "Piso1/Wall_Back") as MeshInstance3D
	var left_bounds: AABB = left_wall.global_transform*left_wall.get_aabb()
	var right_bounds: AABB = right_wall.global_transform*right_wall.get_aabb()
	var stair_span := Vector2(left_bounds.end.x,central_bounds.position.x)
	var ramp_span := Vector2(central_bounds.end.x,right_bounds.position.x)
	var stair_x := (stair_span.x+stair_span.y)*0.5
	var ramp_x := (ramp_span.x+ramp_span.y)*0.5
	for entry in [{"title":"Escalera","span":stair_span,"x":stair_x},{"title":"Rampa","span":ramp_span,"x":ramp_x}]:
		var x: float = entry.x
		var span: Vector2 = entry.span
		var title: String = entry.title
		for interval in [Vector2(span.x,x-2.5),Vector2(x+2.5,span.y)]:
			box(group,title+"Costado"+str(interval.x),Vector3((interval.x+interval.y)*0.5,6,-162.6935),Vector3(interval.y-interval.x,12,0.5),concrete)
		box(group,title+"Dintel",Vector3(x,7.65,-162.6935),Vector3(5,8.7,0.5),concrete)
		box(group,title+"Umbral",Vector3(x,-0.04,-162.6935),Vector3(5,0.08,0.5),stone)
		box(group,title+"DescansoExterior",Vector3(x,0.65,-165.4 if title == "Rampa" else -165.05),Vector3(6 if title == "Rampa" else 8,1.3,1.0 if title == "Rampa" else 0.3),stone)
		# Keep the existing indoor floor flat; put the height transition outside.
		var outside_run := 2.4
		var outside_angle := atan(1.3/outside_run)
		var connection := box(group,title+"ConexionExterior",Vector3(x,0.65-0.04/cos(outside_angle),-163.7),Vector3(5,0.08,sqrt(outside_run*outside_run+1.3*1.3)),stone)
		connection.rotation.x = outside_angle
		var door := CampusNodes.obtener(root, "Piso2/Biblioteca/EntradaVidrio").duplicate() as Node3D
		door.name = "Puerta"+title
		owned(group,door)
		door.position = Vector3(x,0,-162.6935)
		for descendant in door.find_children("*","",true,false): descendant.owner = get_tree().edited_scene_root
		var label := Label3D.new()
		label.name = "Letrero"+title
		label.text = "ACCESO SEDE"
		label.font_size = 48
		label.pixel_size = 0.008
		label.position = Vector3(x,3.65,-163)
		label.rotation.y = PI
		owned(group,label)
	var rise := 1.3-0.215
	for i in range(6):
		var top := 0.215+rise*(i+1)/6.0
		box(group,"Peldano"+str(i),Vector3(stair_x,top*0.5,-167.9+(i+0.5)*0.45),Vector3(8,top,0.45),stone,false)
	var stair_angle := atan(rise/2.7)
	var support := StaticBody3D.new()
	support.name = "ColisionContinuaEscalera"
	support.position = Vector3(stair_x,(0.215+1.3)*0.5-0.04/cos(stair_angle),-166.55)
	support.rotation.x = -stair_angle
	owned(group,support)
	var shape := BoxShape3D.new()
	shape.size = Vector3(8,0.08,sqrt(2.7*2.7+rise*rise))
	var collider := CollisionShape3D.new()
	collider.shape = shape
	owned(support,collider)
	for x in [stair_x-3.95,stair_x+3.95]:
		beam(group,"PasamanosEscalera"+str(x),Vector3(x,1.265,-167.9),Vector3(x,2.35,-165.2),metal)
		beam(group,"PasamanosDescanso"+str(x),Vector3(x,2.35,-165.2),Vector3(x,2.35,-162.8),metal)
		for i in range(7):
			box(group,"PosteEscalera"+str(x)+"_"+str(i),Vector3(x,0.215+rise*i/6.0+0.5,-167.9+i*0.45),Vector3(0.06,1,0.06),metal)
	# The pink arrow points away from the entrance along the glass facade.
	var high_x := ramp_x-3.0
	var low_x := high_x-26.0
	var angle := atan(rise/26.0)
	var ramp := box(group,"RampaAccesible",Vector3((low_x+high_x)*0.5,(0.215+1.3)*0.5-0.075/cos(angle),-165.5),Vector3(sqrt(26.0*26.0+rise*rise),0.15,3),stone)
	ramp.rotation.z = angle
	# Landing must meet the high end without an abrupt step.
	var landing := CampusNodes.obtener(group, "RampaDescansoExterior") as CSGBox3D
	landing.position.z = -165.4
	landing.size.z = 1.0
	for z in [-167.0,-164.0]:
		beam(group,"PasamanosRampa"+str(z),Vector3(low_x,1.265,z),Vector3(high_x,2.35,z),metal)
		for i in range(14):
			var x := low_x+i*2.0
			box(group,"PosteRampa"+str(z)+"_"+str(i),Vector3(x,0.215+rise*i/13.0+0.5,z),Vector3(0.06,1,0.06),metal)
	var bike_x := (low_x+high_x)*0.5
	box(group,"ZonaBicicletas",Vector3(bike_x,0.23,-172),Vector3(18,0.03,3.5),stone)
	for i in range(8):
		var x := bike_x-7.7+i*2.2
		box(group,"BicicleteroIzquierdo"+str(i),Vector3(x,0.7,-172.5),Vector3(0.07,0.94,0.07),metal)
		box(group,"BicicleteroDerecho"+str(i),Vector3(x,0.7,-171.5),Vector3(0.07,0.94,0.07),metal)
		beam(group,"BicicleteroSuperior"+str(i),Vector3(x,1.17,-172.5),Vector3(x,1.17,-171.5),metal)
		if i in [1,3,5]: construir_bicicleta(group,Vector3(x+0.22,0.245,-172),metal,i)
	for vehicle in CampusNodes.obtener(root, "PatioPosteriorDuoc/Estacionamientos").get_children():
		if vehicle is Node3D and str(vehicle.name).begins_with("Auto") and vehicle.position.z > -180:
			if absf(vehicle.position.x-bike_x)<12 or absf(vehicle.position.x-stair_x)<6 or absf(vehicle.position.x-ramp_x)<5: vehicle.position.z -= 12
	group.set_meta("escalera_x",stair_x)
	group.set_meta("rampa_x",ramp_x)
	group.set_meta("rampa_extremo_bajo_x",low_x)
	return {"escalera_x":stair_x,"entrada_rampa_x":ramp_x,"rampa_hacia":low_x,"bicicletero_delante":Vector3(bike_x,0.245,-172),"altura_libre":3.3,"ancho_entradas":5}

func construir_bicicleta(parent: Node3D, origin: Vector3, metal: Material, index: int) -> void:
	var bike := Node3D.new()
	bike.name = "Bicicleta"+str(index)
	bike.position = origin
	owned(parent,bike)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.15,0.35,0.52) if index == 1 else Color(0.55,0.16,0.09)
	for z in [-0.66,0.66]:
		var wheel := CSGTorus3D.new()
		wheel.name = "Rueda"+str(z)
		wheel.inner_radius = 0.30
		wheel.outer_radius = 0.35
		wheel.position = Vector3(0,0.35,z)
		wheel.rotation.z = PI*0.5
		wheel.material = metal
		owned(bike,wheel)
		beam(bike,"Eje"+str(z),Vector3(-0.10,0.35,z),Vector3(0.10,0.35,z),metal)
	var a := Vector3(0,0.4,-0.05)
	var b := Vector3(0,0.9,-0.3)
	var c := Vector3(0,0.88,0.38)
	var d := Vector3(0,0.35,-0.66)
	var e := Vector3(0,0.35,0.66)
	for pair in [[a,b],[b,c],[c,a],[a,d],[b,d],[c,e]]:
		beam(bike,"Cuadro"+str(bike.get_child_count()),pair[0],pair[1],paint)
	box(bike,"Asiento",b+Vector3(0,0.08,0),Vector3(0.3,0.07,0.25),metal,false)
	beam(bike,"Manillar",c+Vector3(-0.3,0.17,0),c+Vector3(0.3,0.17,0),metal)

func ajustar_torniquetes() -> Dictionary:
	var count := 0
	for gate in CampusNodes.campus(self).find_children("Torniquete*","Node3D",true,false):
		if gate.get_script() == null or gate.get_script().resource_path != "res://scripts/exterior/Torniquete.gd": continue
		var p: Vector3 = gate.global_position
		p.y = 0.1
		gate.global_position = p
		gate.regenerar()
		count += 1
	return {"torniquetes_apoyados":count}

func vista_posterior_general() -> Dictionary:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(0,28,-225)
	camera.look_at(Vector3(0,1,-165),Vector3.UP)
	return {"view":"rear parking, ramp, stairs and bicycles"}

func corregir_suelo_visible() -> Dictionary:
	var floor_body := CampusNodes.obtener(CampusNodes.campus(self), "Floor") as StaticBody3D
	var visual := CampusNodes.obtener(floor_body, "MeshInstance3D") as MeshInstance3D
	var collision := CampusNodes.obtener(floor_body, "CollisionShape3D") as CollisionShape3D
	var shape := collision.shape.duplicate() as BoxShape3D
	var mesh := visual.mesh as BoxMesh
	# The collision surface was 1.54 m above the visible ground.
	visual.position.y = collision.position.y+shape.size.y*0.5-mesh.size.y*0.5
	collision.position.x = visual.position.x
	collision.position.z = visual.position.z
	shape.size.x = mesh.size.x
	shape.size.z = mesh.size.z
	collision.shape = shape
	return {"suelo_visible_y":visual.position.y+mesh.size.y*0.5,"colision_y":collision.position.y+shape.size.y*0.5}

func revestir_franjas_amarillas() -> Dictionary:
	var old := CampusNodes.buscar(self, "FranjasAmarillasReferencia")
	if old: old.free()
	var group := Node3D.new()
	group.name = "FranjasAmarillasReferencia"
	owned(self,group)
	var material: Material = load("res://materials/entrance/MAT_Celosia_Posterior.tres")
	# Four solid strips on the rear central facade, preserving the glass bays.
	for x in [-14.0,-4.67,4.67,14.0]:
		box(group,"Franja"+str(x),Vector3(x,53.5,-164.1),Vector3(3.6,83.0,0.12),material,false)
	return {"franjas":4,"vidrios_entre_franjas_conservados":true}

func agregar_npc_papeleria() -> Dictionary:
	var room := CampusNodes.obtener(CampusNodes.campus(self), "Piso2/SalaImpresiones") as Node3D
	var old := CampusNodes.buscar(room, "EncargadoPapeleria")
	if old: old.free()
	var npc := Node3D.new()
	npc.name = "EncargadoPapeleria"
	npc.set_script(load("res://scripts/pisos/piso_1/npc_papeleria.gd"))
	owned(room,npc)
	npc.position = Vector3(-79,0,-121.1)
	return {"npc":"EncargadoPapeleria","articulos":["lapiz","hoja_impresa","cuaderno","goma"],"interaccion":"E"}

func corregir_niveles_sede_y_patio() -> Dictionary:
	var root := CampusNodes.campus(self)
	var floor_body := CampusNodes.obtener(root, "Floor")
	CampusNodes.obtener(floor_body, "MeshInstance3D").visible = false
	CampusNodes.obtener(floor_body, "CollisionShape3D").disabled = true
	var old := CampusNodes.buscar(self, "TerrenoExteriorPorNiveles")
	if old: old.free()
	var terrain := Node3D.new()
	terrain.name = "TerrenoExteriorPorNiveles"
	owned(self,terrain)
	var material: Material = load("res://materials/entrance/MAT_Concrete_Floor.tres")
	for region in [Rect2(-164.13,-261.79,313.407,98.8465),Rect2(-164.13,-162.9435,78.88,186.432),Rect2(84.58,-162.9435,64.697,186.432),Rect2(-85.25,-75.9223,169.83,99.411)]:
		var top := -1.2 if region.position.y < -163 else 0.1
		box(terrain,"Suelo"+str(terrain.get_child_count()),Vector3(region.get_center().x,top-0.1,region.get_center().y),Vector3(region.size.x,0.2,region.size.y),material)
	for child in CampusNodes.obtener(root, "PatioPosteriorDuoc").get_children():
		if child is Node3D and child.name != "CelosiaPosterior": child.position.y = -1.3
	var group := CampusNodes.obtener(self, "PosteriorReferenciaMarcada")
	var adjustment := 0.0 if group.has_meta("patio_y") else -1.3
	for child in group.get_children():
		var title := str(child.name)
		if title.ends_with("ConexionExterior"):
			child.free()
		elif title.ends_with("DescansoExterior"):
			child.position = Vector3(child.position.x,-0.65,-164.3 if title.begins_with("Rampa") else -164.0)
			child.size.y = 1.3
			child.size.z = 3.2 if title.begins_with("Rampa") else 2.4
		elif title.ends_with("Umbral"):
			child.position.y = -0.04
		elif title.begins_with("Anden") or title.begins_with("Peldano") or title.begins_with("Poste") or title.begins_with("Pasamanos") or title.begins_with("Bicicl") or title in ["ColisionContinuaEscalera","RampaAccesible","ZonaBicicletas"]:
			child.position.y += adjustment
	group.set_meta("patio_y",-1.085)
	# Restore the original blue patterned interior floor, without an overlay.
	var interior: Material = load("res://materials/entrance/MAT_Interior_Floor_Dark.tres")
	CampusNodes.obtener(root, "Piso1/Building_Floor").material_override = interior
	return {"sede_y":0,"patio_y":-1.085,"interior_plano":true,"piso_interior_restaurado":true}
