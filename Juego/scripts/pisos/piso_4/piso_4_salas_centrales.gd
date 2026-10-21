@tool
extends "res://scripts/pisos/piso_4/piso_4_referencia.gd"
## Salas centrales 418, 417 y 415 sobre las divisiones originales.
const BACK := -122.234558105469
const FRONT := -97.308090209961
const LIMITS := [-70.213, -57.561, -45.271, -32.331]

func apply() -> Dictionary:
	for child in get_children():
		remove_child(child)
		child.free()
	palette()
	entries.clear()
	global_position = Vector3(0,HEIGHT,0)
	trim_lower_wall_collision("Piso 3/Delantera_piso 3d")
	var original_front := CampusNodes.obtener(get_parent(), "Delantera_piso 4d")
	original_front.set_meta("piso4_salas_centrales",true)
	original_front.hide()
	for col in original_front.find_children("*","CollisionShape3D",true,false):
		col.disabled = true
	var names := ["418","417","415"]
	var layout: Array = []
	for i in range(3):
		var rect := Rect2(LIMITS[i],BACK,LIMITS[i+1]-LIMITS[i],FRONT-BACK)
		var r := room(names[i],rect,true,"class")
		# Conservar los tabiques y el perímetro que ya tenía este bloque.
		var duplicate_partition := CampusNodes.obtener(r, "DivisionSala")
		r.remove_child(duplicate_partition)
		duplicate_partition.free()
		layout.append({"sala":names[i],"planta":rect,"mesas":9,"sillas":9})
	set_meta("distribucion_central",layout)
	return {"salas":layout,"frente_original":FRONT,"paredes_originales_conservadas":true}

func preview_middle() -> void:
	var campus := get_parent().get_parent()
	for level in range(5,9):
		var n := CampusNodes.buscar(campus, "Piso "+str(level))
		if n: n.hide()
	for n in campus.find_children("*","GeometryInstance3D",true,false):
		if n is MeshInstance3D and n.mesh:
			var b: AABB = n.global_transform*n.get_aabb()
			if b.position.y>HEIGHT+10.5: n.hide()
		elif n is CSGBox3D:
			var b: AABB = n.global_transform*AABB(-n.size*0.5,n.size)
			if b.position.y>HEIGHT+10.5: n.hide()
	for n in campus.find_children("*","CanvasLayer",true,false): n.hide()
	var camera := Camera3D.new()
	campus.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 40
	camera.global_position = Vector3(-51.27,120,-78)
	camera.look_at(Vector3(-51.27,HEIGHT,-110))
	camera.make_current()
	var sun := DirectionalLight3D.new()
	campus.add_child(sun)
	sun.rotation_degrees = Vector3(-65,-20,0)
	sun.light_energy = 0.8
