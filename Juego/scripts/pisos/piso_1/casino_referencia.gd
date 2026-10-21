@tool
extends Node3D
## Interior basado en la fotografía del comedor. Eje de vista: acceso este hacia oeste.
var materials: Dictionary = {}
var interior: Node3D

func guardar_interior() -> int:
	_ready()
	var generated := get_node("InteriorFotografico")
	var scene_root := get_tree().edited_scene_root
	generated.owner = scene_root
	for child in generated.find_children("*", "", true, false):
		child.owner = scene_root
	return generated.get_child_count()

func material(key: String, color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.72
	m.metallic = metallic
	materials[key] = m
	return m

func point(p: Vector3) -> Vector3:
	return Vector3(-33.0 - p.z, p.y, -100.0 + p.x)

func box(title: String, p: Vector3, size: Vector3, key: String, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh_box := BoxMesh.new()
	mesh_box.size = Vector3(size.z, size.y, size.x)
	n.mesh = mesh_box
	n.material_override = materials[key]
	n.position = point(p)
	interior.add_child(n)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = mesh_box.size
		shape.shape = bounds
		n.add_child(body)
		body.add_child(shape)
	return n

func bar(p: Vector3, q: Vector3, radius: float, key: String) -> void:
	var a := point(p)
	var b := point(q)
	var n := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = a.distance_to(b)
	cylinder.radial_segments = 8
	n.mesh = cylinder
	n.material_override = materials[key]
	interior.add_child(n)
	n.position = (a + b) * 0.5
	n.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func sign_text(text: String, p: Vector3, scale_value: float = 0.012) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = scale_value
	label.position = point(p)
	label.rotation.y = PI / 2.0
	label.outline_size = 0
	interior.add_child(label)

func chair(u: float, d: float, side: float, green: bool) -> void:
	var key := "green" if green else "chair"
	box("Asiento", Vector3(u,0.68,d),Vector3(0.85,0.12,0.82),key)
	var back := box("Respaldo",Vector3(u,1.13,d+side*0.38),Vector3(0.86,0.85,0.09),key)
	back.rotation.z = side * 0.10
	for x in [-0.33,0.33]:
		for z in [-0.30,0.30]:
			bar(Vector3(u+x*1.4,0.08,d+z*1.5),Vector3(u+x,0.65,d+z),0.025,"steel")

func _ready() -> void:
	if get_node_or_null("InteriorFotografico"):
		return
	for title in ["Comedor", "MesonAtencion", "CubiertaMeson"]:
		var old := get_node_or_null(NodePath(title))
		if old:
			remove_child(old)
			old.queue_free()
	interior = Node3D.new()
	interior.name = "InteriorFotografico"
	add_child(interior)
	material("concrete",Color(0.49,0.47,0.44))
	material("tile",Color(0.32,0.33,0.34))
	material("joint",Color(0.20,0.21,0.22))
	material("wall",Color(0.77,0.75,0.69))
	material("wood",Color(0.76,0.59,0.34))
	material("slat",Color(0.50,0.32,0.15))
	material("steel",Color(0.57,0.60,0.61),0.75)
	material("dark",Color(0.09,0.10,0.11))
	material("chair",Color(0.12,0.14,0.18))
	material("green",Color(0.34,0.49,0.12))
	material("red",Color(0.65,0.09,0.15))
	material("orange",Color(0.94,0.29,0.035))
	var lamp := material("lamp",Color(1.0,0.94,0.77))
	lamp.emission_enabled = true
	lamp.emission = Color(1.0,0.92,0.72)
	lamp.emission_energy_multiplier = 2.5
	box("PisoBaldosas",Vector3(-1,0.035,25),Vector3(43,0.06,51),"tile",true)
	for u in range(-22,22,2):
		box("JuntaLongitudinal",Vector3(u,0.068,25),Vector3(0.018,0.003,51),"joint")
	for d in range(0,51,2):
		box("JuntaTransversal",Vector3(-1,0.068,d),Vector3(43,0.003,0.018),"joint")
	box("CieloHormigon",Vector3(-1,6.5,25),Vector3(43,0.22,51),"concrete")
	box("FondoAtencion",Vector3(-1,3,50.5),Vector3(43,6,0.18),"wall",true)
	box("MuroLateralIzquierdo",Vector3(21,3,25),Vector3(0.16,6,51),"wall")
	for d in range(2,51,4):
		box("VentanaHorizontal",Vector3(20.88,2.1,d),Vector3(0.04,0.65,3.85),"dark")
		box("VentanaAlta",Vector3(20.88,4.8,d),Vector3(0.04,0.65,3.85),"dark")
	for d in [9,23,38]:
		for u in [-19.5,19.5]:
			box("PilarHormigon",Vector3(u,3.2,d),Vector3(0.9,6.4,0.9),"concrete",true)
		box("Viga",Vector3(0,6.1,d),Vector3(41,0.45,0.55),"concrete")
	for u in [-17,-9,0,9,17]:
		bar(Vector3(u,6.15,1),Vector3(u,6.15,49),0.045,"steel")
	for d in [5,14,23,32,41,47]:
		for u in [-14,-4,6,16]:
			box("LuminariaSuspendida",Vector3(u,5.35,d),Vector3(7.5,0.10,0.24),"dark")
			box("Difusor",Vector3(u,5.28,d),Vector3(7.25,0.045,0.21),"lamp")
			for offset in [-2.8,2.8]:
				bar(Vector3(u+offset,5.4,d),Vector3(u+offset,6.35,d),0.014,"dark")
		var light := OmniLight3D.new()
		light.position = point(Vector3(0,4.8,d))
		light.omni_range = 22
		light.light_color = Color(1,0.94,0.84)
		light.light_energy = 2.0
		interior.add_child(light)
	for row in range(5):
		for col in range(5):
			# Pasillo de circulación desde la puerta lateral al servicio.
			var u: float = [-15.5,-8.5,3.5,10.5,17.0][col]
			var d := 8.0 + row * 6.7
			box("CubiertaMesa",Vector3(u,1.18,d),Vector3(4.4,0.12,2.0),"wood",true)
			for x in [-2.0,2.0]:
				for z in [-0.82,0.82]:
					box("PataMesa",Vector3(u+x,0.59,d+z),Vector3(0.10,1.1,0.10),"steel")
			for side in [-1.0,1.0]:
				for x in [-1.1,1.1]:
					chair(u+x,d+side*1.45,side,(row+col+int(x>0))%3==0)
	box("FrenteMeson",Vector3(7,0.9,46.6),Vector3(25,1.7,1.8),"steel",true)
	box("CubiertaServicio",Vector3(7,1.8,46.5),Vector3(25.3,0.12,2),"steel")
	for u in [-3,2,7,12,17]:
		box("BandejaServicio",Vector3(u,1.89,46.5),Vector3(2.8,0.08,1.2),"dark")
		bar(Vector3(u,1.85,47),Vector3(u,2.8,47),0.035,"steel")
	box("Marquesina",Vector3(7,4.1,47),Vector3(26,1.8,0.2),"dark")
	for u in [-3,4,11,18]:
		box("FranjaRoja",Vector3(u,4.1,46.86),Vector3(1.8,1.8,0.05),"red")
	sign_text("CAFÉ     •     MENÚ     •     JIF     •     SÁNDWICH",Vector3(7,4.1,46.73),0.010)
	sign_text("COMIDA CALIENTE",Vector3(7,2.9,49.9),0.009)
	box("PanelMaderaCafeteria",Vector3(-13,1.7,50.2),Vector3(11,3.4,0.1),"wood")
	box("MostradorCafe",Vector3(-13,0.8,46.8),Vector3(9,1.6,1.7),"slat",true)
	box("CubiertaCafe",Vector3(-13,1.66,46.8),Vector3(9.2,0.12,1.9),"dark")
	box("Vitrina",Vector3(-11,2.25,46.8),Vector3(3,1.0,1.3),"steel")
	box("Cafetera",Vector3(-15,2.2,46.9),Vector3(1.3,1,0.8),"dark")
	box("Pantalla",Vector3(-10,3.8,48.9),Vector3(3,1.6,0.16),"dark")
	for d in [10,30]:
		for u in range(-19,-13):
			box("SeparadorListones",Vector3(u*1.0,1.15,d),Vector3(0.14,2.2,0.16),"slat")
		box("Jardinera",Vector3(-16.5,0.55,d),Vector3(6.3,1,1.1),"slat",true)
		for u in [-18,-16,-14]:
			for tilt in [-0.7,0.0,0.7]:
				bar(Vector3(u,0.8,d),Vector3(u+tilt,2.7-abs(tilt),d+tilt),0.09,"green")
	# Escalera naranja de mantenimiento junto al pilar derecho de la foto.
	for u in [-18.5,-17.1]:
		bar(Vector3(u,0.1,16),Vector3(u,4.3,17.3),0.075,"orange")
	for step in range(11):
		var y := 0.3 + step*0.36
		bar(Vector3(-18.5,y,16+y*0.30),Vector3(-17.1,y,16+y*0.30),0.05,"steel")
	box("Extintor",Vector3(-19.0,1.45,17.8),Vector3(0.28,0.9,0.28),"red")