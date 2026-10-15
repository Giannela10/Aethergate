@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
## Construcción persistente en la escena, ejecutada explícitamente desde el editor.
const LEVELS: Array[float] = [-12.058385849, 0.0, 12.058385849, 23.967668533, 35.674415588, 47.974849701, 60.158504486, 71.942184448, 83.913551331]
const ATRIUM := Rect2(-19.5, -137.8, 36.5, 30.8)
const SHAFT := Rect2(-24.2, -161.0, 7.0, 12.4)
var campus: Node3D
var mats: Dictionary = {}
var cuts: Array = []

func owned(parent: Node, node: Node, title: String) -> void:
	node.name = title
	parent.add_child(node)
	node.owner = campus

func group(parent: Node, title: String) -> Node3D:
	var node := Node3D.new()
	owned(parent, node, title)
	return node

func material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	mat.metallic = metallic
	return mat

func box(parent: Node3D, title: String, pos: Vector3, size_value: Vector3, mat: Material, solid := true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	owned(parent, node, title)
	if solid:
		var body := StaticBody3D.new()
		owned(node, body, "Cuerpo")
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size_value
		collision.shape = shape
		owned(body, collision, "Colision")
	return node

func slab(parent: Node3D, title: String, area: Rect2, top: float, mat: Material, thickness := 0.3) -> MeshInstance3D:
	return box(parent, title, Vector3(area.get_center().x, top - thickness * 0.5, area.get_center().y), Vector3(area.size.x, thickness, area.size.y), mat)

func subtract(area: Rect2, cut: Rect2) -> Array[Rect2]:
	return CampusNodes.obtener(campus, "ContinuidadPisos").subtract(area, cut)

func carve(area: Rect2, top: float, parent: Node3D) -> void:
	# Solo losas horizontales; nunca paredes, escaleras, puertas ni cabinas.
	var nodes := campus.find_children("*", "GeometryInstance3D", true, false)
	for node in nodes:
		if (CampusNodes.contiene(self, node) and not CampusNodes.contiene(CampusNodes.obtener(self, "LosasConAberturas"), node) and node != CampusNodes.buscar(self, "PisoMenos1/Piso")) or not node.is_visible_in_tree():
			continue
		if str(node.name).begins_with("Step"):
			continue
		if node is MeshInstance3D and node.mesh == null:
			continue
		if not (node is MeshInstance3D or node is CSGBox3D):
			continue
		if node.get_path().get_concatenated_names().contains("AscensoresEstudiantiles"):
			continue
		var local_bounds: AABB = AABB(-node.size * 0.5, node.size) if node is CSGBox3D else node.get_aabb()
		var bounds: AABB = node.global_transform * local_bounds
		if bounds.size.y > 0.8 or bounds.size.y < 0.04 or absf(bounds.end.y - top) > 0.6:
			continue
		var footprint := Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z)
		if not footprint.intersects(area):
			continue
		var mat: Material = node.get_active_material(0) if node is MeshInstance3D else node.material
		node.visible = false
		if node is CSGBox3D:
			node.use_collision = false
		for collision in node.find_children("*", "CollisionShape3D", true, false):
			collision.disabled = true
		# El piso exterior original tiene la colisión como hermano del mesh.
		if node.get_parent().name == "Floor":
			for collision in node.get_parent().find_children("*", "CollisionShape3D", true, false):
				collision.disabled = true
		var index := 0
		for piece in subtract(footprint, area):
			if piece.size.x < 0.01 or piece.size.y < 0.01:
				continue
			var replacement := slab(parent, "LosaRecortada_%d_%d" % [cuts.size(), index], piece, bounds.end.y, mat, bounds.size.y)
			replacement.set_meta("suelo_original", str(campus.get_path_to(node)))
			index += 1
		cuts.append(str(campus.get_path_to(node)))

func rail(parent: Node3D, title: String, a: Vector3, b: Vector3, glass := true) -> void:
	var length_value := a.distance_to(b)
	if length_value < 0.1:
		return
	var direction := (b - a).normalized()
	var yaw := atan2(-direction.x, -direction.z)
	var pane := box(parent, title, (a + b) * 0.5 + Vector3.UP * 0.8, Vector3(0.08, 1.6, length_value), mats["glass"] if glass else mats["metal"])
	pane.rotation.y = yaw
	var handrail := box(parent, title + "Pasamanos", (a + b) * 0.5 + Vector3.UP * 1.65, Vector3(0.1, 0.09, length_value), mats["metal"], false)
	handrail.rotation.y = yaw
	for i in range(ceili(length_value / 2.0) + 1):
		var pos := a.lerp(b, float(i) / ceili(length_value / 2.0))
		box(parent, title + "Poste%d" % i, pos + Vector3.UP * 0.82, Vector3(0.08, 1.68, 0.08), mats["metal"], false)

func label(parent: Node3D, title: String, text_value: String, pos: Vector3, size_value := 58) -> Label3D:
	var node := Label3D.new()
	node.text = text_value
	node.position = pos
	node.font_size = size_value
	node.pixel_size = 0.007
	node.outline_size = 4
	owned(parent, node, title)
	return node

func build_basement() -> void:
	var basement := group(self, "PisoMenos1")
	slab(basement, "Piso", Rect2(-84.8, -162.45, 169.1, 86.05), LEVELS[0], mats["floor"], 0.5)
	for x in [-84.8, 84.3]:
		box(basement, "MuroLateral", Vector3(x, LEVELS[0] * 0.5, -119.425), Vector3(0.35, -LEVELS[0], 86.05), mats["wall"])
	for z in [-162.45, -76.4]:
		box(basement, "MuroFondo", Vector3(-0.25, LEVELS[0] * 0.5, z), Vector3(169.1, -LEVELS[0], 0.35), mats["wall"])
	for x in [-60.0, -36.0, 36.0, 60.0]:
		for z in [-149.0, -120.0, -90.0]:
			box(basement, "Pilar", Vector3(x, LEVELS[0] * 0.5, z), Vector3(1.2, -LEVELS[0], 1.2), mats["concrete"])
	for x in [-56.0, -28.0, 0.0, 28.0, 56.0]:
		for z in [-149.0, -124.0, -95.0]:
			box(basement, "Luminaria", Vector3(x, -1.2, z), Vector3(2.5, 0.1, 0.3), mats["lamp"], false)
			var light := OmniLight3D.new()
			light.position = Vector3(x, -3.0, z)
			light.omni_range = 24.0
			light.light_energy = 1.4
			owned(basement, light, "Luz")
	label(basement, "Identificacion", "PISO −1\nAcceso por escalera central y emergencia", Vector3(0, -8.5, -147.0), 100)
	# Replica exacta de los peldaños, descanso y colisiones centrales existentes.
	var original := CampusNodes.obtener(campus, "Piso1/Escalera ascensor") as Node3D
	var copy := original.duplicate() as Node3D
	owned(basement, copy, "EscaleraCentralMenos1")
	copy.global_transform = original.global_transform
	copy.position.y += LEVELS[0]
	for child in copy.find_children("*", "Node", true, false):
		child.owner = campus
	var decoration := CampusNodes.obtener(campus, "AcabadosEscaleraPrincipal/LateralesPiso1").duplicate() as Node3D
	owned(basement, decoration, "LateralesEscaleraCentral")
	decoration.position.y += LEVELS[0]
	for child in decoration.find_children("*", "Node", true, false):
		child.owner = campus
	slab(basement, "DescansoInferiorCentral", Rect2(-24.0, -132.8332, 5.0, 10.0), LEVELS[0], mats["floor"])
	slab(basement, "LlegadaCentralPiso1", Rect2(16.108, -132.8332, 3.092, 10.0), 0.0, mats["steps"])
	rail(basement, "ProteccionLlegadaNorte", Vector3(15.2, 0, -132.8332), Vector3(19.2, 0, -132.8332))
	rail(basement, "ProteccionLlegadaSur", Vector3(15.2, 0, -122.8332), Vector3(19.2, 0, -122.8332))

func build_atrium() -> void:
	var floor_parts := group(self, "LosasConAberturas")
	carve(ATRIUM, 0.0, floor_parts)
	var edges := group(self, "BarandasAberturaPiso1")
	# Lado izquierdo cerrado; lado derecho permite salir de la escalera central.
	rail(edges, "OesteNorte", Vector3(ATRIUM.position.x, 0.1, ATRIUM.position.y), Vector3(ATRIUM.position.x, 0.1, -132.95))
	rail(edges, "OesteSur", Vector3(ATRIUM.position.x, 0.1, -122.7), Vector3(ATRIUM.position.x, 0.1, ATRIUM.end.y))
	rail(edges, "Norte", Vector3(ATRIUM.position.x, 0.1, ATRIUM.position.y), Vector3(ATRIUM.end.x, 0.1, ATRIUM.position.y))
	rail(edges, "Sur", Vector3(ATRIUM.position.x, 0.1, ATRIUM.end.y), Vector3(ATRIUM.end.x, 0.1, ATRIUM.end.y))
	rail(edges, "EsteNorte", Vector3(ATRIUM.end.x, 0.1, ATRIUM.position.y), Vector3(ATRIUM.end.x, 0.1, -132.95))
	rail(edges, "EsteSur", Vector3(ATRIUM.end.x, 0.1, -122.7), Vector3(ATRIUM.end.x, 0.1, ATRIUM.end.y))
	label(edges, "SenalBajada", "PISO −1\n↓ Escalera central", Vector3(19.4, 2.2, -120.3))

func ramp(parent: Node3D, title: String, x: float, z0: float, z1: float, y0: float, y1: float) -> void:
	var run := absf(z1 - z0)
	var count := ceili((y1 - y0) / 0.19)
	for i in count:
		var t := float(i + 1) / count
		var top := lerpf(y0, y1, t)
		var z := lerpf(z0, z1, (float(i) + 0.5) / count)
		box(parent, title + "Peldano%02d" % i, Vector3(x, top - 0.09, z), Vector3(2.6, 0.18, run / count + 0.005), mats["steps"], false)
	# Superficie continua bajo los peldaños: subir y bajar sin tener que saltar.
	var points := PackedVector3Array()
	for side in [-1.0, 1.0]:
		for endpoint in [0, 1]:
			var z := z0 if endpoint == 0 else z1
			var top := y0 if endpoint == 0 else y1
			points.append(Vector3(x + side * 1.3, top, z))
			points.append(Vector3(x + side * 1.3, top - 0.22, z))
	var body := StaticBody3D.new()
	owned(parent, body, title + "RampaFisica")
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	collision.shape = shape
	owned(body, collision, "Colision")
	for edge in [-1.3, 1.3]:
		var a := Vector3(x + edge, y0 + 1.3, z0)
		var b := Vector3(x + edge, y1 + 1.3, z1)
		var beam := box(parent, title + "Pasamanos", (a + b) * 0.5, Vector3(0.08, 0.08, a.distance_to(b)), mats["metal"], false)
		beam.look_at(b)
		for i in range(5):
			var p := Vector3(x + edge, lerpf(y0, y1, i / 4.0), lerpf(z0, z1, i / 4.0))
			box(parent, title + "Poste", p + Vector3.UP * 0.65, Vector3(0.07, 1.3, 0.07), mats["metal"], false)

func build_door(parent: Node3D, y: float, title: String) -> void:
	var door := Node3D.new()
	door.set_script(load("res://scripts/compartidos/puerta_emergencia.gd"))
	door.set("floor_label", title)
	door.position = Vector3(-20.7, y, -148.6)
	# Crear hijos antes de introducir el script en el árbol (_ready usa Bisagra).
	var hinge := AnimatableBody3D.new()
	hinge.name = "Bisagra"
	hinge.position.x = -1.5
	var leaf := MeshInstance3D.new()
	leaf.name = "Hoja"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.0, 3.3, 0.12)
	leaf.mesh = mesh
	leaf.material_override = mats["door"]
	leaf.position = Vector3(1.5, 1.65, 0)
	hinge.add_child(leaf)
	var collision := CollisionShape3D.new()
	collision.name = "Colision"
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	collision.position = leaf.position
	hinge.add_child(collision)
	door.add_child(hinge)
	owned(parent, door, "PuertaPiso" + title.replace("−", "Menos"))
	for child in door.find_children("*", "Node", true, false):
		child.owner = campus
	box(hinge, "BarraAntipanico", Vector3(1.5, 1.3, 0.13), Vector3(2.1, 0.1, 0.09), mats["metal"], false)
	box(parent, "MarcoIzquierdo", Vector3(-22.3, y + 1.75, -148.6), Vector3(0.14, 3.5, 0.25), mats["metal"])
	box(parent, "MarcoDerecho", Vector3(-19.1, y + 1.75, -148.6), Vector3(0.14, 3.5, 0.25), mats["metal"])
	box(parent, "Dintel", Vector3(-20.7, y + 3.5, -148.6), Vector3(3.3, 0.14, 0.25), mats["metal"])
	box(parent, "CartelSalida", Vector3(-20.7, y + 3.85, -148.43), Vector3(3.2, 0.45, 0.08), mats["exit"], false)
	label(parent, "TextoSalida", "ESCALERA · PISO %s" % title, Vector3(-20.7, y + 3.85, -148.37), 42)
	label(parent, "NumeroPiso", "PISO %s\n↕ EMERGENCIA" % title, Vector3(-20.7, y + 2.0, -160.7), 52)

func build_emergency() -> void:
	var tower := group(self, "EscaleraEmergencia")
	var floor_parts := CampusNodes.obtener(self, "LosasConAberturas")
	for y in LEVELS:
		if y >= 0.0:
			carve(SHAFT, y, floor_parts)
	var height_value: float = LEVELS.back() - LEVELS.front() + 5.0
	var middle_y: float = (LEVELS.back() + LEVELS.front() + 5.0) * 0.5
	for x in [SHAFT.position.x - 0.12, SHAFT.end.x + 0.12]:
		box(tower, "MuroCajaLateral", Vector3(x, middle_y, SHAFT.get_center().y), Vector3(0.24, height_value, SHAFT.size.y), mats["wall"])
	box(tower, "MuroCajaPosterior", Vector3(SHAFT.get_center().x, middle_y, -161.0), Vector3(SHAFT.size.x, height_value, 0.24), mats["wall"])
	for i in LEVELS.size():
		var y := LEVELS[i]
		var title := "−1" if i == 0 else str(i)
		var level := group(tower, "Nivel" + title.replace("−", "Menos"))
		slab(level, "DescansoPiso", Rect2(-24.2, -151.1, 7.0, 4.4), y, mats["floor"])
		build_door(level, y, title)
		var wall_height := 5.0 if i == LEVELS.size() - 1 else LEVELS[i + 1] - y
		box(level, "FrenteIzquierdo", Vector3(-23.25, y + wall_height * 0.5, -148.6), Vector3(1.9, wall_height, 0.24), mats["wall"])
		box(level, "FrenteDerecho", Vector3(-18.1, y + wall_height * 0.5, -148.6), Vector3(2.0, wall_height, 0.24), mats["wall"])
		box(level, "FrenteSobrePuerta", Vector3(-20.7, y + (wall_height + 3.6) * 0.5, -148.6), Vector3(3.2, wall_height - 3.6, 0.24), mats["wall"])
		var light := OmniLight3D.new()
		light.position = Vector3(-20.7, y + 4.5, -154.3)
		light.omni_range = 12.0
		light.light_energy = 1.2
		owned(level, light, "LuzEmergencia")
		if i == LEVELS.size() - 1:
			continue
		var rise := (LEVELS[i + 1] - y) * 0.25
		for flight in range(4):
			var start_y := y + rise * flight
			var end_y := start_y + rise
			var outward := flight % 2 == 0
			ramp(level, "Tramo%d" % (flight + 1), -22.65 if outward else -18.75, -151.1 if outward else -158.5, -158.5 if outward else -151.1, start_y, end_y)
			if flight < 3:
				var landing_area := Rect2(-24.2, -160.9 if outward else -151.1, 7.0, 2.4)
				slab(level, "DescansoGiro%d" % (flight + 1), landing_area, end_y, mats["floor"])
				if not outward:
					rail(level, "ProteccionDescansoIntermedio", Vector3(-24.2, end_y, -148.7), Vector3(-17.2, end_y, -148.7), false)
	slab(tower, "CubiertaEscalera", SHAFT, LEVELS.back() + 5.0, mats["wall"])
	tower.set_meta("niveles", ["−1", "1", "2", "3", "4", "5", "6", "7", "8"])

func build() -> Dictionary:
	campus = CampusNodes.campus(self)
	if get_child_count() > 0:
		return {"status": "already_built"}
	mats["floor"] = load("res://materials/entrance/MAT_Interior_Floor_Dark.tres")
	mats["steps"] = load("res://materials/entrance/MAT_Peldanos_Oscuros.tres")
	mats["concrete"] = load("res://materials/entrance/MAT_Columns_Concrete.tres")
	mats["wall"] = material(Color("c7cdce"))
	mats["metal"] = material(Color("45535a"), 0.65)
	mats["door"] = material(Color("275958"), 0.15)
	mats["glass"] = material(Color(0.65, 0.85, 0.9, 0.22))
	mats["glass"].transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mats["glass"].cull_mode = BaseMaterial3D.CULL_DISABLED
	mats["exit"] = material(Color("167344"))
	mats["lamp"] = material(Color("dce6df"))
	mats["lamp"].emission_enabled = true
	mats["lamp"].emission = Color("dce6df")
	build_atrium()
	build_basement()
	build_emergency()
	finish_guards()
	finish_accesses()
	preserve_central_entrance()
	extend_elevators_to_basement()
	set_meta("abertura_piso1", ATRIUM)
	set_meta("caja_emergencia", SHAFT)
	set_meta("losas_recortadas", cuts)
	return {"basement_y": LEVELS[0], "doors": 9, "flights": 32, "cut_slabs": cuts.size(), "atrium": ATRIUM, "shaft": SHAFT}

func finish_guards() -> Dictionary:
	campus = CampusNodes.campus(self)
	var tower := CampusNodes.obtener(self, "EscaleraEmergencia")
	var count := 0
	for body in CampusNodes.descendientes(tower, "*RampaFisica", "StaticBody3D", true, false):
		if body.has_node("ProteccionLaterales"):
			continue
		var guards := group(body, "ProteccionLaterales")
		var points: PackedVector3Array = CampusNodes.obtener(body, "Colision").shape.points
		for side in [0, 4]:
			var fence_points := PackedVector3Array()
			for point_index in [side, side + 2]:
				var point := points[point_index]
				for dx in [-0.035, 0.035]:
					fence_points.append(point + Vector3(dx, 0.0, 0))
					fence_points.append(point + Vector3(dx, 1.3, 0))
			var barrier := StaticBody3D.new()
			owned(guards, barrier, "Barrera")
			var collision := CollisionShape3D.new()
			var shape := ConvexPolygonShape3D.new()
			shape.points = fence_points
			collision.shape = shape
			owned(barrier, collision, "Colision")
			count += 1
	return {"protecciones_laterales": count}

func finish_accesses() -> Dictionary:
	campus = CampusNodes.campus(self)
	var landing := CampusNodes.obtener(self, "PisoMenos1/LlegadaCentralPiso1") as MeshInstance3D
	var landing_mesh := landing.mesh.duplicate() as BoxMesh
	landing_mesh.size.x = 3.092
	landing.mesh = landing_mesh
	landing.position.x = (16.108 + 19.2) * 0.5
	var landing_shape := BoxShape3D.new()
	landing_shape.size = landing_mesh.size
	CampusNodes.obtener(landing, "Cuerpo/Colision").shape = landing_shape
	var wall_parts := CampusNodes.buscar(self, "MurosConAccesoEmergencia") as Node3D
	if wall_parts == null:
		wall_parts = group(self, "MurosConAccesoEmergencia")
	var count := 0
	for node in campus.find_children("*", "GeometryInstance3D", true, false):
		if CampusNodes.contiene(self, node):
			continue
		if not (node is MeshInstance3D or node is CSGBox3D):
			continue
		if node is MeshInstance3D and node.mesh == null:
			continue
		if str(node.get_path()).contains("AscensoresEstudiantiles"):
			continue
		var local_bounds: AABB = AABB(-node.size * 0.5, node.size) if node is CSGBox3D else node.get_aabb()
		var bounds: AABB = node.global_transform * local_bounds
		if bounds.size.y < 2.0 or bounds.size.z > 0.8:
			continue
		if not Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z).intersects(SHAFT):
			continue
		if not node.is_visible_in_tree() and node is CSGBox3D and not node.use_collision:
			continue
		var was_visible: bool = node.is_visible_in_tree()
		var mat: Material = node.get_active_material(0) if node is MeshInstance3D else node.material
		node.visible = false
		if node is CSGBox3D:
			node.use_collision = false
		for collision in node.find_children("*", "CollisionShape3D", true, false):
			collision.disabled = true
		for interval in [Vector2(bounds.position.x, minf(bounds.end.x, SHAFT.position.x)), Vector2(maxf(bounds.position.x, SHAFT.end.x), bounds.end.x)]:
			if interval.y - interval.x > 0.02:
				var replacement := box(wall_parts, "MuroConPaso%d" % count, Vector3((interval.x + interval.y) * 0.5, bounds.get_center().y, bounds.get_center().z), Vector3(interval.y - interval.x, bounds.size.y, bounds.size.z), mat)
				replacement.visible = was_visible
		count += 1
	return {"muros_abiertos": count}

func preserve_central_entrance() -> void:
	campus = CampusNodes.campus(self)
	var edges := CampusNodes.obtener(self, "BarandasAberturaPiso1")
	if edges.has_node("UmbralEscaleraExistente"):
		return
	for node in edges.get_children():
		if str(node.name).begins_with("Oeste"):
			edges.remove_child(node)
			node.free()
	mats["metal"] = material(Color("45535a"), 0.65)
	mats["glass"] = material(Color(0.65, 0.85, 0.9, 0.22))
	mats["glass"].transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mats["glass"].cull_mode = BaseMaterial3D.CULL_DISABLED
	rail(edges, "OesteNorte", Vector3(-19.5, 0.1, -137.8), Vector3(-19.5, 0.1, -132.95))
	rail(edges, "OesteSur", Vector3(-19.5, 0.1, -122.7), Vector3(-19.5, 0.1, -107.0))
	slab(edges, "UmbralEscaleraExistente", Rect2(-20.6, -132.8332, 2.0, 10.0), 0.1, load("res://materials/entrance/MAT_Interior_Floor_Dark.tres"), 0.15)

func extend_elevators_to_basement() -> Dictionary:
	campus = CampusNodes.campus(self)
	var extension := CampusNodes.buscar(self, "AccesoAscensoresMenos1") as Node3D
	if extension:
		return {"status": "already_built"}
	extension = group(self, "AccesoAscensoresMenos1")
	var floor_parts := CampusNodes.obtener(self, "LosasConAberturas") as Node3D
	var depth := -LEVELS[0]
	var openings: Array[Rect2] = []
	var count := 0
	for lift in CampusNodes.obtener(campus, "AscensoresEstudiantiles").get_children():
		var area := Rect2(lift.position.x - 2.6, lift.position.z - 5.45, 5.2, 12.75)
		carve(area, 0.0, floor_parts)
		carve(area, LEVELS[0], floor_parts)
		openings.append(area)
		for title in ["VidrioLateralIzquierdo", "VidrioLateralDerecho", "VidrioPosterior", "GuiaIzquierda", "GuiaDerecha"]:
			var wall := CampusNodes.obtener(lift, title) as CSGBox3D
			wall.size.y += depth
			wall.position.y -= depth * 0.5
		CampusNodes.obtener(lift, "BasePozo").position.y -= depth
		var gate := CampusNodes.obtener(lift, "PuertaPiso1").duplicate() as AnimatableBody3D
		gate.position.x = 0.0
		gate.position.y = LEVELS[0]
		owned(lift, gate, "PuertaPisoMenos1")
		for child in gate.find_children("*", "Node", true, false):
			child.owner = campus
		var sign_label := label(extension, "SenalAscensorMenos1", "ASCENSOR · PISO −1\n[E] Llamar", Vector3(lift.position.x, LEVELS[0] + 4.0, -149.45), 48)
		sign_label.modulate = Color("e8eee9")
		count += 1
	var wall_material := material(Color("c7cdce"))
	for interval in [Vector2(-15.2, -12.6), Vector2(-7.4, -2.6), Vector2(2.6, 7.4), Vector2(12.6, 15.2)]:
		box(extension, "MuroEntreAscensores", Vector3((interval.x + interval.y) * 0.5, (LEVELS[0] - 0.15) * 0.5, -149.65), Vector3(interval.y - interval.x, depth - 0.15, 0.16), wall_material)
	for x in [-10.0, 0.0, 10.0]:
		var bottom := LEVELS[0] + 3.4
		box(extension, "DintelAscensor", Vector3(x, (bottom - 0.15) * 0.5, -149.65), Vector3(5.2, -0.15 - bottom, 0.16), wall_material)
	set_meta("huecos_ascensores_menos1", openings)
	return {"ascensores_extendidos": count, "piso_menos1_y": LEVELS[0], "tecla_menos1": "0"}

func view_atrium() -> void:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(30, 17, -96)
	camera.look_at(Vector3(-1, -4, -125))

func view_emergency() -> void:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(-33, 10, -136)
	camera.look_at(Vector3(-20.7, 4, -153))

func preview_atrium() -> void:
	var manager := CampusNodes.obtener(CampusNodes.campus(self), "GameplayManager")
	manager.set_process(false)
	manager.player.busy = true
	manager.player.global_position = Vector3(24, 0.2, -120)
	manager.cam.global_position = Vector3(25, 12, -107)
	manager.cam.look_at(Vector3(-1, -5, -125))

func preview_emergency() -> void:
	var manager := CampusNodes.obtener(CampusNodes.campus(self), "GameplayManager")
	manager.set_process(false)
	manager.player.busy = true
	manager.player.global_position = Vector3(-20.7, 0.1, -149.6)
	manager.cam.global_position = Vector3(-20.7, 3.8, -149.4)
	manager.cam.look_at(Vector3(-21.6, 3.2, -157.7))
