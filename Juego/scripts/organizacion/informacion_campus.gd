@tool
extends Node
## Mantiene las fichas de cada piso sin reconstruir ni mover geometría.
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
@export_tool_button("Actualizar fichas de pisos") var actualizar_btn: Callable = actualizar_fichas
@export_tool_button("Verificar orden de pisos") var verificar_btn: Callable = verificar
@export_tool_button("Mostrar campus completo") var mostrar_btn: Callable = mostrar_campus_completo

func marcar_geometria_retirada() -> void:
	# Distinguir piezas eliminadas para abrir huecos de los pisos ocultos
	# durante la edición. La copia anterior conserva la visibilidad individual.
	var campus := CampusNodes.campus(self)
	var snapshot := "res://tests/Main.antes_ordenar.tscn.bak"
	if campus.has_meta("visibilidad_clasificada") or not FileAccess.file_exists(snapshot):
		return
	var names := RegEx.new()
	names.compile('name="([^"]+)"')
	var parents := RegEx.new()
	parents.compile('parent="([^"]+)"')
	var path := ""
	for line in FileAccess.get_file_as_string(snapshot).split("\n"):
		if line.begins_with("[node "):
			var name_match := names.search(line)
			var parent_match := parents.search(line)
			path = ""
			if name_match and parent_match:
				var parent_path := parent_match.get_string(1)
				path = (parent_path + "/" if parent_path != "." else "") + name_match.get_string(1)
		elif line.strip_edges() == "visible = false" and not path.is_empty():
			var node := CampusNodes.buscar(campus, path)
			if not node is GeometryInstance3D:
				continue
			var collisions := node.find_children("*", "CollisionShape3D", true, false)
			if collisions.is_empty() and node.get_parent() is CollisionObject3D:
				collisions = node.get_parent().find_children("*", "CollisionShape3D", true, false)
			var retired: bool = not collisions.is_empty()
			for collision in collisions:
				if not collision.disabled:
					retired = false
			if collisions.is_empty() and node is CSGShape3D:
				retired = not node.use_collision
			if retired:
				node.set_meta("geometria_retirada", true)
	campus.set_meta("visibilidad_clasificada", true)

func mostrar_campus_completo() -> Dictionary:
	var campus := CampusNodes.campus(self)
	marcar_geometria_retirada()
	var activated := 0
	var retired := 0
	var nodes := campus.find_children("*", "Node3D", true, false)
	if campus is Node3D:
		campus.visible = true
	for node: Node3D in nodes:
		if node.get_meta("geometria_retirada", false):
			node.visible = false
			retired += 1
		else:
			if not node.visible:
				activated += 1
			node.visible = true
	var hidden_active: Array[String] = []
	for node: Node3D in nodes:
		var ancestor: Node = node
		var belongs_to_retired := false
		while ancestor != campus:
			if ancestor.get_meta("geometria_retirada", false):
				belongs_to_retired = true
				break
			ancestor = ancestor.get_parent()
		if not belongs_to_retired and not node.is_visible_in_tree():
			hidden_active.append(str(campus.get_path_to(node)))
	return {"elementos_activados": activated, "geometria_retirada": retired, "activos_ocultos": hidden_active}

func actualizar_fichas() -> Dictionary:
	var campus := CampusNodes.campus(self)
	var count := 0
	var routes: Dictionary = campus.get_meta("rutas_ordenadas", {})
	for node in campus.find_children("*", "Node", true, false):
		if node.has_meta("ruta_antes_de_ordenar"):
			routes[str(node.get_meta("ruta_antes_de_ordenar"))] = str(campus.get_path_to(node))
	campus.set_meta("rutas_ordenadas", routes)
	for floor_node in campus.get_children():
		if not floor_node.is_in_group("pisos"):
			continue
		var number: int = floor_node.numero_piso
		var folder := "piso_menos_1" if number == -1 else "piso_%d" % number
		var names: Array[String] = []
		var text := "# %s\n\nNodo de la escena: `Main/%s`. Altura: %.4f.\n\n## Contenido\n\n" % [floor_node.etiqueta, floor_node.name, floor_node.altura]
		for child in floor_node.get_children():
			names.append(str(child.name))
			text += "- `%s` (%s).\n" % [child.name, child.get_class()]
		floor_node.descripcion = "Contenido del nivel: " + ", ".join(names)
		text += "\nLos scripts exclusivos del nivel están en esta carpeta. Los mecanismos que conectan varios pisos están en `scripts/compartidos`. El generador del −1 y la emergencia está en `scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd`.\n\nLa propiedad `altura` informa la cota del piso; las piezas conservan las coordenadas originales del campus.\n"
		var file := FileAccess.open("res://scripts/pisos/%s/INFORMACION.md" % folder, FileAccess.WRITE)
		file.store_string(text)
		count += 1
	return {"fichas_actualizadas": count}

func verificar() -> Dictionary:
	var campus := CampusNodes.campus(self)
	var report: Array = []
	for floor_node in campus.get_children():
		if floor_node.is_in_group("pisos"):
			report.append({"piso": floor_node.numero_piso, "etiqueta": floor_node.etiqueta, "altura": floor_node.altura, "elementos": floor_node.get_child_count()})
	print("PISOS: ", report)
	return {"pisos": report}

func asignar_elemento(path: String, number: int, category: String) -> Dictionary:
	var campus := CampusNodes.campus(self)
	var node := campus.get_node_or_null(path) as Node3D
	var floor_title := "PisoMenos1" if number == -1 else "Piso%d" % number
	if node == null or not campus.has_node(floor_title):
		return {"error": "El elemento o el piso no existe"}
	if node == campus or node.is_ancestor_of(campus.get_node(floor_title)) or node.is_in_group("pisos"):
		return {"error": "Selecciona un elemento del piso, no el contenedor del campus"}
	var old := CampusNodes.ruta_original(node, campus)
	var before := node.global_transform
	var was_visible := node.is_visible_in_tree()
	var parent := CampusNodes.categoria_piso(self, number, category)
	node.reparent(parent, true)
	node.set_meta("ruta_antes_de_ordenar", old)
	var routes: Dictionary = campus.get_meta("rutas_ordenadas", {})
	routes[old] = str(campus.get_path_to(node))
	campus.set_meta("rutas_ordenadas", routes)
	return {"ruta": str(campus.get_path_to(node)), "geometria_conservada": before.is_equal_approx(node.global_transform) and was_visible == node.is_visible_in_tree()}
