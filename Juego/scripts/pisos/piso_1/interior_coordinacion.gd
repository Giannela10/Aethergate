@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
# Construcción manual del interior; los nodos quedan guardados en Main.tscn.
var colors := {
	"pared": Color(0.84, 0.85, 0.81), "madera": Color(0.54, 0.32, 0.16),
	"azul": Color(0.06, 0.22, 0.39), "gris": Color(0.22, 0.25, 0.28),
	"piso": Color(0.66, 0.67, 0.63), "dorado": Color(0.95, 0.67, 0.16),
	"pantalla": Color(0.12, 0.39, 0.52), "blanco": Color(0.95, 0.94, 0.90)
}
var mats: Dictionary = {}

func box(title: String, p: Vector3, s: Vector3, color: String, solid: bool = true) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = s
	n.mesh = mesh
	n.material_override = mats[color]
	n.position = p
	add_child(n)
	n.owner = owner
	if solid:
		var body := StaticBody3D.new()
		n.add_child(body)
		body.owner = owner
		var shape := CollisionShape3D.new()
		var resource := BoxShape3D.new()
		resource.size = s
		shape.shape = resource
		body.add_child(shape)
		shape.owner = owner
	return n

func label(title: String, p: Vector3, text_value: String) -> void:
	var n := Label3D.new()
	n.name = title
	n.text = text_value
	n.font_size = 72
	n.pixel_size = 0.006
	n.position = p
	n.modulate = colors["azul"]
	add_child(n)
	n.owner = owner

func chair(title: String, x: float, y: float, z: float, audience: bool = false) -> void:
	var c := "azul" if audience else "gris"
	box(title + "Base", Vector3(x, y + 0.35, z), Vector3(0.75, 0.7, 0.75), "gris")
	box(title + "Cojin", Vector3(x, y + 0.8, z), Vector3(1.05, 0.25, 1.05), c)
	box(title + "Respaldo", Vector3(x, y + 1.25, z + 0.48), Vector3(1.05, 1.1, 0.22), c)
	if audience:
		for side in [-1, 1]:
			box(title + "Brazo" + str(side), Vector3(x + side * 0.62, y + 0.95, z), Vector3(0.18, 0.25, 1.1), "madera")

func desk(title: String, x: float, z: float) -> void:
	box(title + "Tablero", Vector3(x, 1.45, z), Vector3(2.8, 0.18, 1.5), "madera")
	for side in [-1, 1]:
		box(title + "Soporte" + str(side), Vector3(x + side, 0.72, z), Vector3(0.18, 1.44, 1.15), "gris")
	box(title + "Monitor", Vector3(x, 1.95, z - 0.35), Vector3(0.95, 0.6, 0.12), "gris", false)
	box(title + "Display", Vector3(x, 1.95, z - 0.275), Vector3(0.8, 0.45, 0.02), "pantalla", false)
	box(title + "Teclado", Vector3(x, 1.58, z + 0.2), Vector3(0.8, 0.06, 0.3), "gris", false)
	chair(title + "Silla", x, 0.1, z + 1.5)

func light_at(title: String, p: Vector3) -> void:
	box(title + "Panel", p, Vector3(2.4, 0.08, 0.6), "blanco", false)
	var n := OmniLight3D.new()
	n.name = title
	n.position = p - Vector3(0, 0.3, 0)
	n.light_color = Color(1.0, 0.91, 0.78)
	n.light_energy = 1.2
	n.omni_range = 13.0
	add_child(n)
	n.owner = owner

func build() -> String:
	for child in get_children():
		remove_child(child)
		child.free()
	position = Vector3.ZERO
	for key in colors:
		var m := StandardMaterial3D.new()
		m.albedo_color = colors[key]
		m.roughness = 0.8
		mats[key] = m
	mats["piso"] = load("res://materials/entrance/MAT_Interior_Floor_Dark.tres")
	# Interior del primer piso entre coodinacion, MeshInstance3D6 y Wall_Right.
	# Se conserva la apertura existente x69..73 frente a la escalera.
	box("PilarAcceso",Vector3(78.54,6.03,-122.05),Vector3(11.08,11.95,0.505),"pared")
	box("DintelEntrada",Vector3(71,7.45,-122.05),Vector3(4,9.1,0.505),"pared")
	label("LetreroEntrada",Vector3(71,2.55,-122.42),"COORDINACIÓN")
	CampusNodes.obtener(self, "LetreroEntrada").rotation.y = PI
	box("PisoCoordinacion",Vector3(58,0.02,-107.55),Vector3(50,0.2,28.1),"piso")
	# Altura libre ajustada a la losa existente debajo del auditorio.
	box("TechoCoordinacion",Vector3(58,4.99,-107.55),Vector3(50,0.1,28.1),"pared")
	box("MostradorSecretaria",Vector3(65.5,0.85,-118.1),Vector3(7,1.7,1.5),"madera")
	box("FrenteRecepcion",Vector3(65.5,0.85,-118.87),Vector3(6.5,1.2,0.06),"azul",false)
	label("Secretaria",Vector3(65.5,2.3,-118.88),"SECRETARÍA")
	CampusNodes.obtener(self, "Secretaria").rotation.y = PI
	desk("Secretaria1",63.5,-115.5)
	desk("Secretaria2",67,-115.5)
	for i in range(4):
		chair("Espera"+str(i),47+i*2.0,0.12,-119.5)
	box("MesaEspera",Vector3(50,0.65,-117.2),Vector3(3,1,1.1),"madera")
	label("Espera",Vector3(50,2.35,-120.9),"SALA DE ESPERA")
	for i in range(3):
		var z := -112.0+i*7
		box("TabiqueOficina"+str(i),Vector3(38,2.52,z+3),Vector3(9.5,4.8,0.18),"pared")
		box("FrenteOficina"+str(i),Vector3(42.8,2.52,z+0.7),Vector3(0.18,4.8,3.7),"pared")
		box("DintelOficina"+str(i),Vector3(42.8,4.68,z-2.25),Vector3(0.18,0.5,2.2),"pared")
		desk("Oficina"+str(i+1),37.5,z)
		label("RotuloOficina"+str(i),Vector3(38,2.35,z+2.85),"OFICINA "+str(i+1))
	for x in [49.0,55.0,61.0]:
		for z in [-109.0,-101.5]:
			desk("Coordinador"+str(x)+str(z),x,z)
	box("SeparadorCentral",Vector3(55,1.4,-105.5),Vector3(15,0.7,0.12),"azul",false)
	box("TabiqueReuniones",Vector3(68,2.52,-99.15),Vector3(0.18,4.8,10.5),"pared")
	box("FrenteReunionesIzquierdo",Vector3(70.5,2.52,-104.4),Vector3(5,4.8,0.18),"pared")
	box("FrenteReunionesDerecho",Vector3(79.5,2.52,-104.4),Vector3(7,4.8,0.18),"pared")
	box("DintelReuniones",Vector3(74.5,4.68,-104.4),Vector3(3,0.5,0.18),"pared")
	label("Reuniones",Vector3(72,2.3,-104.55),"REUNIONES")
	CampusNodes.obtener(self, "Reuniones").rotation.y = PI
	box("MesaReuniones",Vector3(75,1.35,-98.8),Vector3(3.5,0.2,5.5),"madera")
	for i in range(3):
		for x in [72.5,77.5]:
			chair("Reunion"+str(x)+str(i),x,0.12,-96.6-i*1.8)
	for x in [39.0,54.0,74.0]:
		for z in [-116.0,-98.0]:
			light_at("LuzCoordinacion"+str(x)+str(z),Vector3(x,4.87,z))
	set_meta("ubicacion","Primer piso: x33..83, z-121.6..-93.5, dentro de los muros indicados")
	return "Coordinación reubicada dentro de los muros. Auditorio conservado."
