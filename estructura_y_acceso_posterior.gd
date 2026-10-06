@tool
extends Node3D

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
	var root := get_parent()
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
	var roof := root.get_node("Piso 8/Building_Floor Piso 8 Techo") as MeshInstance3D
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
	var terrace_floor := root.get_node("Piso 5/Building_Floor Piso 5") as MeshInstance3D
	var mesh := terrace_floor.mesh.duplicate() as BoxMesh
	var terrace_ratio := 138.0/mesh.size.x
	mesh.size.x = 138.0
	terrace_floor.mesh = mesh
	for collision in terrace_floor.find_children("*","CollisionShape3D",true,false):
		var shape := collision.shape.duplicate() as BoxShape3D
		shape.size.x = 138.0
		collision.shape = shape
	var terrace := root.get_node("Piso 5/TerrazaPicnic")
	terrace.get_node("CercaVidrio").scale.x *= terrace_ratio
	for furniture in terrace.get_node("MobiliarioReferencia").get_children():
		if furniture is Node3D and str(furniture.name) != "MarcosVidrio":
			furniture.position.x *= terrace_ratio
	terrace.set_meta("ancho_referencia_aerea",138.0)
	# Small pedestrian access beside the parked cars.
	var entrance := Node3D.new()
	entrance.name = "EntradaPosteriorEstacionamientos"
	entrance.position.x = 18.0
	owned(self,entrance)
	var wall := root.get_node("Piso1/Wall_Back2") as MeshInstance3D
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
	var door := root.get_node("Piso2/Biblioteca/EntradaVidrio").duplicate() as Node3D
	door.name = "PuertaPosterior"
	owned(entrance,door)
	door.position = Vector3(0,1.3,z)
	for descendant in door.find_children("*","",true,false):
		descendant.owner = get_tree().edited_scene_root
	var sign := root.get_node("Piso2/Biblioteca/Letrero").duplicate() as Label3D
	sign.name = "LetreroAccesoPosterior"
	sign.text = "ACCESO SEDE"
	owned(entrance,sign)
	sign.position = Vector3(0,4.9,z-0.3)
	for vehicle in root.get_node("PatioPosteriorDuoc/Estacionamientos").get_children():
		if vehicle is Node3D and str(vehicle.name).begins_with("Auto") and absf(vehicle.position.x-18.0) < 6:
			vehicle.position.z -= 12.0
	box(entrance,"PasoPeatonal",Vector3(0,0.24,-172),Vector3(6,0.06,8.2),concrete)
	for marking in root.get_node("PatioPosteriorDuoc/Estacionamientos").get_children():
		if marking is GeometryInstance3D and str(marking.name).begins_with("Demarcacion") and absf(marking.position.x-18.0)<5:
			marking.visible = false
	set_meta("referencia","Vista aerea: entrantes en extremos, terraza retraida y acceso junto a los autos")
	alinear_terraza()
	return {"entrantes_cubierta":2,"terraza_ancho":138,"acceso_posterior":true,"peldanos":6}

func alinear_terraza() -> Dictionary:
	var root := get_parent()
	var roof := root.get_node("Piso 8/Building_Floor Piso 8 Techo") as MeshInstance3D
	var west := root.get_node("Piso 4/Front_Left piso 4 sur3") as MeshInstance3D
	var east := root.get_node("Piso 4/Wall_Right3") as MeshInstance3D
	var center_x := (west.global_position.x + east.global_position.x) * 0.5
	var full_width := east.global_position.x - west.global_position.x + 0.5
	var floor_node := root.get_node("Piso 5/Building_Floor Piso 5") as MeshInstance3D
	var terrace_mesh := floor_node.mesh.duplicate() as BoxMesh
	terrace_mesh.size.x = full_width
	floor_node.mesh = terrace_mesh
	floor_node.global_position.x = center_x
	for collision in floor_node.find_children("*","CollisionShape3D",true,false):
		var shape := BoxShape3D.new()
		shape.size = terrace_mesh.size
		collision.shape = shape
		collision.global_position = floor_node.global_position
	var terrace := root.get_node("Piso 5/TerrazaPicnic")
	var fence := terrace.get_node("CercaVidrio") as Node3D
	fence.scale.x = 1.0
	var left := fence.get_node("Izquierda/Panel01") as CSGBox3D
	var right := fence.get_node("Derecha/Panel01") as CSGBox3D
	var fence_center := (left.global_position.x+right.global_position.x)*0.5
	fence.global_position.x += center_x-fence_center
	var furniture := terrace.get_node("MobiliarioReferencia") as Node3D
	furniture.global_position.x = center_x
	for i in range(10):
		furniture.get_node("SombrillaMesa%02d" % (i+1)).position.x = -72.0 + i * 16.0
	for i in range(7):
		furniture.get_node("ZonaCafe%02d" % (i+1)).position.x = -66.0 + i * 22.0
	terrace.set_meta("ancho_referencia_aerea", full_width)
	return {"centro_x":center_x,"ancho_losa":terrace_mesh.size.x,"barandas_y_colision":"alineadas"}

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
	var root := get_parent()
	var entrance := get_node("EntradaPosteriorEstacionamientos") as Node3D
	entrance.position.x = 18.0
	var wall := root.get_node("Piso1/Wall_Back2") as MeshInstance3D
	var bounds: AABB = wall.global_transform * wall.get_aabb()
	var left := entrance.get_node("MuroIzquierdoAcceso") as CSGBox3D
	left.position.x = (bounds.position.x-18.0-2.5)*0.5
	left.size.x = -2.5-(bounds.position.x-18.0)
	var right := entrance.get_node("MuroDerechoAcceso") as CSGBox3D
	right.position.x = (bounds.end.x-18.0+2.5)*0.5
	right.size.x = bounds.end.x-18.0-2.5
	for vehicle in root.get_node("PatioPosteriorDuoc/Estacionamientos").get_children():
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


