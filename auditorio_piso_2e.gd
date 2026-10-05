@tool
extends Node3D
# Construcción manual del auditorio de referencia en el desnivel Piso 2e.
# Toda la geometría y sus colisiones se guardan en Main.tscn.
var mats: Dictionary = {}

func group_node(title: String) -> Node3D:
	var n := Node3D.new()
	n.name = title
	add_child(n)
	n.owner = owner
	return n

func box(parent: Node3D, title: String, p: Vector3, size_value: Vector3, material: String, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = size_value
	n.mesh = mesh
	n.position = p
	n.material_override = mats[material]
	parent.add_child(n)
	n.owner = owner
	if solid:
		var body := StaticBody3D.new()
		body.name = "Cuerpo"
		n.add_child(body)
		body.owner = owner
		var collision := CollisionShape3D.new()
		collision.name = "Colision"
		var shape := BoxShape3D.new()
		shape.size = size_value
		collision.shape = shape
		body.add_child(collision)
		collision.owner = owner
	return n

func make_material(title: String, color: Color, roughness: float = 0.9) -> void:
	var m := StandardMaterial3D.new()
	m.resource_name = title
	m.albedo_color = color
	m.roughness = roughness
	mats[title] = m

func seat(parent: Node3D, row: int, col: int, x: float, y: float, z: float) -> void:
	var n := Node3D.new()
	n.name = "Butaca%02d_%02d" % [row + 1, col + 1]
	parent.add_child(n)
	n.owner = owner
	box(n, "Base", Vector3(x, y + 0.4, z), Vector3(0.6, 0.8, 0.6), "metal")
	box(n, "Cojin", Vector3(x, y + 0.86, z), Vector3(1.1, 0.25, 1.05), "azul", true)
	var back := box(n, "Respaldo", Vector3(x, y + 1.3, z + 0.45), Vector3(1.12, 1.1, 0.25), "azul", true)
	back.rotation.x = -0.08
	var rounded := CapsuleMesh.new()
	rounded.radius = 0.56
	rounded.height = 1.3
	rounded.radial_segments = 16
	rounded.rings = 4
	back.mesh = rounded
	back.scale.z = 0.24
	for side in [-1, 1]:
		box(n, "Apoyabrazos" + str(side), Vector3(x + side * 0.61, y + 1.05, z), Vector3(0.16, 0.14, 1.0), "metal")

func remove_old_auditorium(root: Node) -> int:
	var old := root.get_node_or_null("Piso1/InteriorCoordinacion")
	if not old:
		return 0
	var removed := 0
	for n in old.get_children():
		var title := str(n.name)
		if title == "LosaAuditorio":
			n.name = "TechoCoordinacion"
			continue
		if title in ["ParedAuditorioDerecha", "FondoAuditorio", "Tarima", "PantallaProyeccion", "Atril", "DescansoAuditorio", "Auditorio"] or title.begins_with("Butaca") or title.begins_with("EscalonAuditorio") or title.begins_with("LuzAuditorio") or title.begins_with("PosteEscalera") or title.begins_with("PasamanosAuditorio") or title.begins_with("EscalonTarima"):
			old.remove_child(n)
			n.queue_free()
			removed += 1
	return removed

func build() -> Dictionary:
	if get_child_count() > 0:
		return {"status": "Auditorio ya construido"}
	var root := get_parent().get_parent()
	var removed := remove_old_auditorium(root)
	mats["madera"] = load("res://materials/entrance/MAT_Auditorium_Plywood.tres")
	make_material("azul", Color(0.025, 0.07, 0.16), 0.98)
	make_material("metal", Color(0.025, 0.027, 0.03), 0.7)
	make_material("piso", Color(0.025, 0.025, 0.028), 1.0)
	make_material("pared_negra", Color(0.02, 0.02, 0.023), 1.0)
	make_material("luz", Color(1, 0.85, 0.6), 0.5)
	var lum: StandardMaterial3D = mats["luz"]
	lum.emission_enabled = true
	lum.emission = Color(1, 0.77, 0.43)
	lum.emission_energy_multiplier = 2.5
	# Sustituye el bloque macizo por una losa fina, duplicando recursos compartidos.
	var floor_node := get_parent().get_node("Building_Floor Piso 2e") as MeshInstance3D
	var mesh := floor_node.mesh.duplicate() as BoxMesh
	mesh.size = Vector3(25.562, 0.3, 35.452)
	floor_node.mesh = mesh
	floor_node.position.y = 6.088
	floor_node.material_override = mats["piso"]
	var collision := floor_node.get_node("StaticBody3D/CollisionShape3D") as CollisionShape3D
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	collision.position = Vector3.ZERO
	var tiers := group_node("Graderias")
	var seats := group_node("Butacas")
	for row in range(10):
		var y := 6.85 + row * 0.55
		var z := -114.8 + row * 2.4
		var h := y - 6.238
		for x in [49.7, 60.7]:
			box(tiers, "Grada" + str(row + 1) + str(x), Vector3(x, 6.238 + h * 0.5, z), Vector3(9, h, 2.4), "piso", true)
		for col in range(12):
			var x := 46.2 + (col % 6) * 1.4
			if col >= 6:
				x += 11
			seat(seats, row, col, x, y, z)
		# Tres peldaños por fila para mantener contrahuellas de unos 18 cm.
		for j in range(3):
			var top := 6.3 + row * 0.55 + (j + 1) * 0.55 / 3.0
			var step_z := z - 0.8 + j * 0.8
			for x in [44.0, 55.2, 66.6]:
				var step_h := top - 6.238
				box(tiers, "Escalon" + str(row) + "_" + str(j) + "_" + str(x), Vector3(x, 6.238 + step_h * 0.5, step_z), Vector3(2.0, step_h, 0.8), "piso", true)
	box(tiers, "DescansoSuperior", Vector3(55.4, 11.65, -89.5), Vector3(25.3, 0.3, 5), "piso", true)
	var stage := group_node("Escenario")
	box(stage, "TarimaOscura", Vector3(55.4, 6.38, -118.7), Vector3(24.8, 0.28, 6), "piso", true)
	box(stage, "MesaPresentacion", Vector3(55.4, 7.5, -118.8), Vector3(3.5, 0.15, 1.5), "madera", true)
	for x in [53.9, 56.9]:
		box(stage, "PataMesa" + str(x), Vector3(x, 6.95, -118.8), Vector3(0.12, 1.05, 1.3), "metal")
	for x in [47.0, 63.7]:
		box(stage, "MesaLateral" + str(x), Vector3(x, 7.5, -121), Vector3(6, 0.15, 1), "madera")
		box(stage, "SoporteLateral" + str(x), Vector3(x, 7.0, -121), Vector3(0.12, 1, 0.8), "metal")
	seat(stage, 10, 0, 62.7, 6.52, -119.2)
	var walls := group_node("PanelesMadera")
	# Las juntas negras separan el revestimiento en paneles, como en la foto.
	box(walls, "FondoNegro", Vector3(55.4, 12, -122.0), Vector3(25.4, 11.5, 0.18), "pared_negra", true)
	box(walls, "LateralIzquierdoNegro", Vector3(42.78, 12, -104.45), Vector3(0.18, 11.5, 35.3), "pared_negra", true)
	box(walls, "LateralDerechoTramo", Vector3(68.05, 12, -106.75), Vector3(0.18, 11.5, 30.7), "pared_negra", true)
	# Entrada lateral junto al descanso: hueco entre z=-91.4 y -87.6.
	box(walls, "DintelEntrada", Vector3(68.05, 16.75, -89.5), Vector3(0.18, 2, 3.8), "madera", true)
	box(walls, "BajoEntrada", Vector3(68.05, 9, -89.5), Vector3(0.18, 5.6, 3.8), "madera", true)
	box(walls, "CierrePosterior", Vector3(55.4, 14.7, -86.9), Vector3(25.4, 5.8, 0.18), "madera", true)
	for col in range(8):
		for row in range(4):
			box(walls, "PanelFrontal" + str(col) + "_" + str(row), Vector3(44.4 + col * 3.15, 7.65 + row * 2.85, -121.60), Vector3(3.12, 2.82, 0.05), "madera")
	for col in range(11):
		for row in range(4):
			var z := -120.35 + col * 3.08
			box(walls, "PanelIzquierdo" + str(col) + "_" + str(row), Vector3(42.9, 7.65 + row * 2.85, z), Vector3(0.05, 2.82, 3.05), "madera")
			if col < 10:
				box(walls, "PanelDerecho" + str(col) + "_" + str(row), Vector3(67.93, 7.65 + row * 2.85, z), Vector3(0.05, 2.82, 3.05), "madera")
	box(walls, "PuertaFrontal", Vector3(55.4, 8.1, -121.50), Vector3(1.8, 3.4, 0.08), "metal")
	for x in [48.0, 60.5]:
		box(walls, "RejillaVentilacion" + str(x), Vector3(x, 10, -121.8), Vector3(2.8, 0.65, 0.08), "metal")
		for j in range(12):
			box(walls, "LamaRejilla" + str(x) + str(j), Vector3(x - 1.3 + j * 0.23, 10, -121.74), Vector3(0.025, 0.62, 0.03), "madera")
	var ceiling := group_node("TechoAcustico")
	box(ceiling, "BaseTecho", Vector3(55.4, 17.8, -104.45), Vector3(25.4, 0.2, 35.3), "pared_negra", true)
	for col in range(6):
		for row in range(9):
			var x := 44.9 + col * 4.2
			var z := -120.1 + row * 3.9
			var panel := box(ceiling, "PanelTecho" + str(col) + "_" + str(row), Vector3(x, 17.6, z), Vector3(4.05, 0.12, 3.72), "madera")
			panel.rotation.z = 0.015 if row % 2 == 0 else -0.015
			if col % 2 == 1 and row % 2 == 0:
				box(ceiling, "RanuraLuz" + str(col) + str(row), Vector3(x + 1.98, 17.49, z), Vector3(0.12, 0.03, 2), "luz")
	var lighting := group_node("IluminacionCalida")
	for x in [46.0, 55.4, 64.8]:
		for z in [-118.0, -109.0, -100.0, -91.0]:
			var n := OmniLight3D.new()
			n.name = "Luz" + str(x) + str(z)
			n.position = Vector3(x, 16.8, z)
			n.light_color = Color(1, 0.84, 0.62)
			n.light_energy = 1.8
			n.omni_range = 11
			lighting.add_child(n)
			n.owner = owner
	for x in [47.0, 63.0]:
		box(lighting, "LuzFrontal" + str(x), Vector3(x, 14.3, -121.75), Vector3(1.3, 0.07, 0.1), "luz")
	var sign := Label3D.new()
	sign.name = "LetreroAuditorio"
	sign.text = "AUDITORIO"
	sign.position = Vector3(68.23, 15.3, -89.5)
	sign.rotation.y = PI / 2
	sign.font_size = 64
	sign.pixel_size = 0.012
	lighting.add_child(sign)
	sign.owner = owner
	resolve_overlaps()
	add_passage_ramps()
	orient_to_library()
	enlarge_stage_and_fix_access()
	finish_passage_connection()
	bridge_landing_edges()
	bevel_landing_connections()
	return {"ubicacion": "Piso2/Building_Floor Piso 2e", "butacas": 120, "filas": 10, "retirados_del_auditorio_anterior": removed}

func resolve_overlaps() -> String:
	var stage_floor := StandardMaterial3D.new()
	stage_floor.albedo_color = Color(0.025, 0.025, 0.028)
	stage_floor.roughness = 1
	mats["piso"] = stage_floor
	var old_slab := get_parent().get_node("RellenoFrenteEscalera") as CSGBox3D
	var old_material := old_slab.material
	old_slab.size = Vector3(10.337, 0.5, 10.81)
	old_slab.position.x = 37.4685
	if not get_node_or_null("AjustesAcceso"):
		var adjustments := group_node("AjustesAcceso")
		mats["existente"] = old_material
		box(adjustments, "LosaDerechaConservada", Vector3(70.22, 11.80838585, -91.905), Vector3(4.11, 0.5, 10.81), "existente", true)
		box(adjustments, "LosaEntradaAuditorio", Vector3(55.418, 11.65, -89.25), Vector3(25.562, 0.3, 5.5), "piso", true)
	for n in get_node("PanelesMadera").get_children():
		if str(n.name).begins_with("PanelFrontal"):
			n.position.z = -121.6
		elif str(n.name) == "PuertaFrontal":
			n.position.z = -121.5
		elif str(n.name).begins_with("RejillaVentilacion"):
			n.position.z = -121.5
		elif str(n.name).begins_with("LamaRejilla"):
			n.position.z = -121.44
	for n in get_node("Butacas").find_children("Respaldo", "MeshInstance3D", true, false):
		var rounded := CapsuleMesh.new()
		rounded.radius = 0.56
		rounded.height = 1.3
		rounded.radial_segments = 16
		rounded.rings = 4
		n.mesh = rounded
		n.scale.z = 0.24
	return "Losa que cruzaba las graderías recortada; paredes y butacas ajustadas."

func add_passage_ramps() -> String:
	if get_node_or_null("RampasPasillos"):
		return "Rampas existentes."
	make_material("piso", Color(0.025, 0.025, 0.028), 1)
	make_material("metal", Color(0.025, 0.027, 0.03), 0.7)
	var ramps := group_node("RampasPasillos")
	for x in [44.0, 55.2, 66.6]:
		var ramp := box(ramps, "Rampa" + str(x), Vector3(x, 9.195, -104), Vector3(1.9, 0.15, 24.623), "piso", true)
		ramp.rotation.x = -atan(5.5 / 24)
		ramp.visible = false
	for x in [43.05, 67.8]:
		for z in [-119.5, -107.0, -95.0]:
			box(get_node("PanelesMadera"), "PerfilEstructural" + str(x) + str(z), Vector3(x, 12, z), Vector3(0.18, 11.5, 0.28), "metal")
	return "Pasillos con rampas de colisión para subir sin saltar."

func orient_to_library() -> Dictionary:
	if get_node_or_null("EntradasAuditorio"):
		return {"status": "Orientación y dos entradas ya aplicadas."}
	mats["madera"] = load("res://materials/entrance/MAT_Auditorium_Plywood.tres")
	make_material("metal", Color(0.025, 0.027, 0.03), 0.7)
	make_material("piso", Color(0.025, 0.025, 0.028), 1)
	var walls := get_node("PanelesMadera")
	# Cerrar el acceso anterior antes de girar el recinto.
	for title in ["CierrePosterior", "DintelEntrada", "BajoEntrada"]:
		var n := walls.get_node_or_null(title)
		if n:
			walls.remove_child(n)
			n.queue_free()
	box(walls, "CierreAccesoAnterior", Vector3(68.05, 12, -89.5), Vector3(0.18, 11.5, 3.8), "madera", true)
	var old_landing := get_node_or_null("AjustesAcceso/LosaEntradaAuditorio")
	if old_landing:
		old_landing.get_parent().remove_child(old_landing)
		old_landing.queue_free()
	var old_sign := get_node_or_null("IluminacionCalida/LetreroAuditorio")
	if old_sign:
		old_sign.get_parent().remove_child(old_sign)
		old_sign.queue_free()
	# Giro de 90 grados dentro de la misma huella del Piso 2e.
	var center := Vector3(55.418, 0, -104.438)
	var sx := 25.562 / 35.452
	var sz := 35.452 / 25.562
	var basis := Basis(Vector3(0, 0, -sz), Vector3(0, 1, 0), Vector3(sx, 0, 0))
	var transform_value := Transform3D(basis, center - basis * center)
	for title in ["Graderias", "Butacas", "Escenario", "PanelesMadera", "TechoAcustico", "IluminacionCalida", "RampasPasillos"]:
		get_node(title).transform = transform_value
	# Mantener las proporciones de cada butaca tras adaptar la huella.
	for seat_node in get_node("Butacas").get_children():
		var pivot: Vector3 = seat_node.get_node("Cojin").position - Vector3(0, 0.86, 0)
		for part in seat_node.get_children():
			part.position -= pivot
		seat_node.position = pivot
		seat_node.scale = Vector3(1.0 / sz, 1, 1.0 / sx)
		seat_node.set_meta("pivot_corrected", true)
	var entrances := group_node("EntradasAuditorio")
	# Dos huecos libres de tres metros, en el borde este y al nivel del pasillo.
	box(entrances, "MuroExtremoSur", Vector3(68.02, 14.75, -121.0), Vector3(0.18, 5.9, 1.9), "madera", true)
	box(entrances, "MuroEntreEntradas", Vector3(68.02, 14.75, -104.5), Vector3(0.18, 5.9, 25), "madera", true)
	box(entrances, "MuroExtremoNorte", Vector3(68.02, 14.75, -87.9), Vector3(0.18, 5.9, 1.8), "madera", true)
	box(entrances, "DintelAmbasEntradas", Vector3(68.02, 16.55, -104.438), Vector3(0.18, 2.3, 35.3), "madera", true)
	for z in [-118.5, -90.5]:
		box(entrances, "Umbral" + str(z), Vector3(68.08, 11.92, z), Vector3(1.0, 0.28, 2.9), "piso", true)
		var label := Label3D.new()
		label.name = "LetreroEntrada" + str(z)
		label.text = "AUDITORIO — ENTRADA " + ("1" if z < -100 else "2")
		label.font_size = 56
		label.pixel_size = 0.01
		label.position = Vector3(68.18, 15.2, z)
		label.rotation.y = PI / 2
		entrances.add_child(label)
		label.owner = owner
	return {"escenario": "oeste, hacia Biblioteca", "entradas": 2, "lado_entradas": "pasillo este", "ubicacion": "Building_Floor Piso 2e"}

func enlarge_stage_and_fix_access() -> Dictionary:
	if get_node_or_null("ColisionesAuditorio"):
		return {"status": "Escenario y acceso ya corregidos."}
	make_material("piso", Color(0.025, 0.025, 0.028), 1)
	make_material("metal", Color(0.025, 0.027, 0.03), 0.7)
	make_material("pantalla", Color(0.86, 0.9, 0.88), 0.8)
	make_material("proyeccion", Color(0.09, 0.32, 0.3), 0.8)
	mats["madera"] = load("res://materials/entrance/MAT_Auditorium_Plywood.tres")
	var seats := get_node("Butacas")
	for n in seats.get_children():
		if str(n.name).begins_with("Butaca01_") or str(n.name).begins_with("Butaca02_"):
			seats.remove_child(n)
			n.queue_free()
	var tiers := get_node("Graderias")
	for n in tiers.get_children():
		var name_value := str(n.name)
		if name_value.begins_with("Grada1") and not name_value.begins_with("Grada10") or name_value.begins_with("Grada2") or name_value.begins_with("Escalon0_") or name_value.begins_with("Escalon1_"):
			tiers.remove_child(n)
			n.queue_free()
	# Retirar la tarima y muebles anteriores, construidos en coordenadas previas al giro.
	var old_stage := get_node("Escenario")
	remove_child(old_stage)
	old_stage.queue_free()
	var old_ramps := get_node("RampasPasillos")
	remove_child(old_ramps)
	old_ramps.queue_free()
	var stage := group_node("Escenario")
	box(stage, "TarimaAmpliada", Vector3(46.725, 6.819, -104.438), Vector3(7.65, 1.162, 34.1), "piso", true)
	box(stage, "MarcoPantalla", Vector3(43.25, 12.45, -104.438), Vector3(0.16, 6.9, 16.6), "metal")
	box(stage, "PantallaGrande", Vector3(43.36, 12.45, -104.438), Vector3(0.04, 6.5, 16.2), "pantalla")
	box(stage, "AreaProyeccion", Vector3(43.40, 12.45, -104.438), Vector3(0.025, 5.8, 15.1), "proyeccion")
	box(stage, "Atril", Vector3(46.8, 8.05, -117), Vector3(1.1, 1.3, 1.4), "metal", true)
	box(stage, "TableroAtril", Vector3(46.8, 8.78, -117), Vector3(1.2, 0.15, 1.6), "madera")
	var screen_text := Label3D.new()
	screen_text.name = "DuocUCPantalla"
	screen_text.text = "DuocUC\nAUDITORIO SAN JOAQUÍN"
	screen_text.font_size = 120
	screen_text.pixel_size = 0.007
	screen_text.position = Vector3(43.45, 12.45, -104.438)
	screen_text.rotation.y = PI / 2
	screen_text.outline_size = 0
	stage.add_child(screen_text)
	screen_text.owner = owner
	var ramps := group_node("RampasPasillos")
	var length_value := 15.8
	var rise := 4.4
	for z in [-88.60, -104.136, -119.95]:
		var ramp := box(ramps, "RampaAcceso" + str(z), Vector3(57.6, 9.51, z), Vector3(sqrt(length_value * length_value + rise * rise), 0.16, 2.4), "piso", true)
		ramp.rotation.z = atan(rise / length_value)
		ramp.visible = false
	# Las colisiones de cajas bajo padres con escalado no uniforme pueden deformarse.
	# Hornear sus ocho vértices en cuerpos independientes sin escala ni rotación heredada.
	var physics := group_node("ColisionesAuditorio")
	var collisions := find_children("*", "CollisionShape3D", true, false)
	var count := 0
	for old in collisions:
		if old.get_parent().get_parent().name.begins_with("Escalon"):
			old.disabled = true
			continue
		if not old.shape is BoxShape3D:
			continue
		var half: Vector3 = old.shape.size * 0.5
		var points := PackedVector3Array()
		for x in [-1, 1]:
			for y in [-1, 1]:
				for z in [-1, 1]:
					points.append(physics.global_transform.affine_inverse() * (old.global_transform * (half * Vector3(x, y, z))))
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		var body := StaticBody3D.new()
		body.name = "Cuerpo%03d" % count
		physics.add_child(body)
		body.owner = owner
		var collider := CollisionShape3D.new()
		collider.name = "Colision"
		collider.shape = shape
		body.add_child(collider)
		collider.owner = owner
		old.disabled = true
		count += 1
	physics.set_meta("baked_count", count)
	return {"butacas": seats.get_child_count(), "profundidad_escenario": 7.65, "ancho_escenario": 34.1, "colisiones_reconstruidas": count}

func finish_passage_connection() -> String:
	var physics := get_node("ColisionesAuditorio")
	var count: int = physics.get_meta("baked_count")
	var i := 0
	for ramp in get_node("RampasPasillos").get_children():
		var mesh := ramp.mesh.duplicate() as BoxMesh
		var length_value := 15.9
		var rise := 5.25
		mesh.size = Vector3(sqrt(length_value * length_value + rise * rise), 0.16, 2.4)
		ramp.mesh = mesh
		ramp.position.x = 56.45
		ramp.position.y = 9.495
		ramp.rotation.z = atan(rise / length_value)
		var points := PackedVector3Array()
		var half := mesh.size * 0.5
		for x in [-1, 1]:
			for y in [-1, 1]:
				for z in [-1, 1]:
					points.append(physics.global_transform.affine_inverse() * (ramp.global_transform * (half * Vector3(x, y, z))))
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		physics.get_node("Cuerpo%03d/Colision" % (count - 3 + i)).shape = shape
		i += 1
	return "Rampas conectadas sin borde al descanso y a la tarima."

func bridge_landing_edges() -> String:
	var physics := get_node("ColisionesAuditorio")
	if physics.get_node_or_null("EnlaceDescanso0_0"):
		return "Enlaces existentes."
	var segments := [[63.2, 11.7, 64.5, 12.4], [64.5, 12.4, 66.6, 11.78]]
	var lane := 0
	for z in [-88.60, -104.136, -119.95]:
		for i in range(2):
			var segment: Array = segments[i]
			var points := PackedVector3Array()
			for endpoint in range(2):
				var x: float = segment[endpoint * 2]
				var y: float = segment[endpoint * 2 + 1]
				for depth in [-1.2, 1.2]:
					points.append(Vector3(x, y, z + depth))
					points.append(Vector3(x, y - 0.12, z + depth))
			var body := StaticBody3D.new()
			body.name = "EnlaceDescanso" + str(lane) + "_" + str(i)
			physics.add_child(body)
			body.owner = owner
			var collider := CollisionShape3D.new()
			var shape := ConvexPolygonShape3D.new()
			shape.points = points
			collider.shape = shape
			body.add_child(collider)
			collider.owner = owner
		lane += 1
	return "Transición entre descanso y rampas conectada."

func bevel_landing_connections() -> String:
	var segments := [[63.2, 11.7, 64.5, 12.4], [64.5, 12.4, 66.6, 11.78]]
	var lane := 0
	for z in [-88.60, -104.136, -119.95]:
		for i in range(2):
			var segment: Array = segments[i]
			var points := PackedVector3Array()
			for endpoint in range(2):
				var x: float = segment[endpoint * 2]
				var y: float = segment[endpoint * 2 + 1]
				for depth in [-1.2, -0.6, 0.6, 1.2]:
					var top := minf(y, 11.78) if absf(depth) > 1 else y
					points.append(Vector3(x, top, z + depth))
					points.append(Vector3(x, minf(y, 11.65), z + depth))
			var shape := ConvexPolygonShape3D.new()
			shape.points = points
			get_node("ColisionesAuditorio/EnlaceDescanso" + str(lane) + "_" + str(i)).get_child(0).shape = shape
		lane += 1
	return "Transiciones con bordes laterales inclinados."

func correct_seat_pivots() -> int:
	var count := 0
	for seat_node in get_node("Butacas").get_children():
		if seat_node.has_meta("pivot_corrected"):
			continue
		var pivot: Vector3 = seat_node.get_node("Cojin").position - Vector3(0, 0.86, 0)
		for part in seat_node.get_children():
			part.position -= pivot
		seat_node.position = pivot
		seat_node.set_meta("pivot_corrected", true)
		count += 1
	return count




