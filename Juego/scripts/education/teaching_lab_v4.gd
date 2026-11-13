extends Node3D
@export var room_number := "301"
@export var topic := "Programación"
var material := StandardMaterial3D.new()
static var shared_boxes: Dictionary = {}
static var shared_materials: Dictionary = {}
static var shared_collisions: Dictionary = {}
func box(label: String, center: Vector3, size: Vector3, color: Color, solid: bool = false) -> void:
	var mesh := MeshInstance3D.new(); mesh.name = label; mesh.position = center
	var key := str(size)
	if not shared_boxes.has(key):
		var box_mesh := BoxMesh.new(); box_mesh.size=size; shared_boxes[key]=box_mesh
	mesh.mesh=shared_boxes[key]
	if not shared_materials.has(str(color)):
		var mat := material.duplicate(); mat.albedo_color=color; shared_materials[str(color)]=mat
	mesh.material_override=shared_materials[str(color)]
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new(); body.position = center
		var collision := CollisionShape3D.new()
		if not shared_collisions.has(key):
			var cube := BoxShape3D.new(); cube.size=size; shared_collisions[key]=cube
		collision.shape=shared_collisions[key]
		body.add_child(collision); add_child(body)
func _ready() -> void:
	material.roughness = 0.8
	# 10 x 8 m. Door faces the corridor; no new slab or external circulation changes.
	box("MuroFondo",Vector3(0,1.65,3.9),Vector3(10,3.3,0.12),Color("dadad3"),true)
	for x in [-4.94,4.94]: box("MuroLateral",Vector3(x,1.65,0),Vector3(0.12,3.3,8),Color("dadad3"),true)
	for x in [-3.0,3.0]: box("Frente",Vector3(x,1.65,-3.94),Vector3(4,3.3,0.12),Color("dadad3"),true)
	box("Pizarra",Vector3(0,1.8,3.78),Vector3(3.5,1.25,0.06),Color("eff7ef"))
	for x in [-2.7,2.7]:
		for z in [-1.5,1.0]:
			box("Mesa",Vector3(x,0.75,z),Vector3(2.2,0.1,0.85),Color("a5916b"),true)
			box("Monitor",Vector3(x,1.25,z+0.2),Vector3(0.7,0.45,0.07),Color("142c3f"))
			# The screen bottom is 1.025 and the desktop is 0.8: give the
			# display a real stand rather than leaving a 22.5 cm air gap.
			box("BaseMonitor",Vector3(x,0.815,z+0.2),Vector3(0.36,0.03,0.24),Color("24252b"))
			box("SoporteMonitor",Vector3(x,0.92,z+0.2),Vector3(0.055,0.21,0.055),Color("24252b"))
			box("Teclado",Vector3(x,0.85,z-0.15),Vector3(0.6,0.04,0.2),Color("24252b"))
			box("Gabinete",Vector3(x+0.85,0.4,z),Vector3(0.3,0.65,0.5),Color("24252b"))
			box("Silla",Vector3(x,0.42,z-0.85),Vector3(0.6,0.1,0.6),Color("e49a30"))
			box("Respaldo",Vector3(x,0.8,z-1.1),Vector3(0.6,0.65,0.08),Color("e49a30"))
	box("Proyector",Vector3(0,2.8,0),Vector3(0.6,0.2,0.4),Color.WHITE)
	if topic in ["Servidores","Ciberseguridad","Laboratorio General"]:
		for x in [-3.8,3.8]:
			box("Rack",Vector3(x,1.1,2.8),Vector3(0.75,2.2,0.65),Color("1c252d"),true)
			for y in [0.5,0.9,1.3,1.7]: box("Servidor",Vector3(x,y,2.42),Vector3(0.6,0.22,0.08),Color("4193a4"))
	if topic in ["Hardware y Soporte","Laboratorio General"]:
		box("PlacaDePractica",Vector3(-2.7,0.84,1),Vector3(0.65,0.05,0.45),Color("237a48"))
		box("Memoria",Vector3(-2.7,0.89,1),Vector3(0.45,0.05,0.08),Color("d7c858"))
	if topic in ["Servidores","Ciberseguridad","Laboratorio General"]:
		box("Switch",Vector3(2.7,0.87,1.2),Vector3(0.7,0.1,0.25),Color("60748a"))
		for x in [2.45,2.6,2.75,2.9]: box("CableDeRed",Vector3(x,0.88,0.8),Vector3(0.025,0.025,0.6),Color("347fd3"))
	var label := Label3D.new(); label.text = room_number+" · "+topic; label.position = Vector3(0,2.7,-4.05); label.font_size = 40; add_child(label)
