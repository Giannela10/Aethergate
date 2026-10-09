@tool
extends RefCounted
## Las herramientas antiguas conservan sus referencias tras ordenar la escena.
## El juego usa las rutas actuales; este adaptador solo sirve al editor.
static func campus(node: Node) -> Node:
	var current := node
	while current != null:
		if current.is_in_group("campus"):
			return current
		current = current.get_parent()
	return node.get_tree().edited_scene_root

static func ruta_original(node: Node, root: Node) -> String:
	if node == root:
		return ""
	if node.has_meta("ruta_antes_de_ordenar"):
		return str(node.get_meta("ruta_antes_de_ordenar"))
	var parent := node.get_parent()
	var prefix := ruta_original(parent, root)
	return (prefix + "/" if not prefix.is_empty() else "") + str(node.name)

static func buscar(base: Node, path: NodePath) -> Node:
	var root := campus(base)
	if root == null:
		return base.get_node_or_null(path)
	var original := ruta_original(base, root)
	var requested := str(path)
	var full := original + "/" + requested if not original.is_empty() else requested
	var routes: Dictionary = root.get_meta("rutas_ordenadas", {})
	var best := ""
	for old: String in routes:
		if (full == old or full.begins_with(old + "/")) and old.length() > best.length():
			best = old
	if not best.is_empty():
		var result := root.get_node_or_null(str(routes[best]) + full.substr(best.length()))
		if result:
			return result
	return base.get_node_or_null(path)

static func obtener(base: Node, path: NodePath) -> Node:
	var result := buscar(base, path)
	if result == null:
		push_error("Referencia de edición inexistente: %s desde %s" % [path, base.get_path()])
	return result

static func hijos(base: Node) -> Array[Node]:
	var result: Array[Node] = []
	var root := campus(base)
	var prefix := ruta_original(base, root)
	if not prefix.is_empty():
		prefix += "/"
	for node in root.find_children("*", "Node", true, false):
		var path := ruta_original(node, root)
		if path.begins_with(prefix) and not path.substr(prefix.length()).contains("/"):
			result.append(node)
	return result

static func contiene(base: Node, node: Node) -> bool:
	var root := campus(base)
	var prefix := ruta_original(base, root)
	return prefix.is_empty() or ruta_original(node, root).begins_with(prefix + "/")

static func limpiar(base: Node) -> void:
	var root := campus(base)
	var prefix := ruta_original(base, root) + "/"
	var routes: Dictionary = root.get_meta("rutas_ordenadas", {})
	for node in hijos(base):
		node.free()
	for old: String in routes.keys():
		if old.begins_with(prefix):
			routes.erase(old)
	root.set_meta("rutas_ordenadas", routes)

static func categoria_piso(base: Node, number: int, title: String) -> Node3D:
	var root := campus(base)
	var floor_node := root.get_node("PisoMenos1" if number == -1 else "Piso%d" % number)
	var result := floor_node.get_node_or_null(title) as Node3D
	if result == null:
		result = Node3D.new()
		result.name = title
		floor_node.add_child(result)
		result.owner = root
	return result

static func guardar(base: Node, node: Node, old_relative: String, parent: Node) -> void:
	var root := campus(base)
	var prefix := ruta_original(base, root)
	var old := (prefix + "/" if not prefix.is_empty() else "") + old_relative
	var existing := buscar(base, old_relative)
	var routes: Dictionary = root.get_meta("rutas_ordenadas", {})
	if existing != null and existing != node:
		existing.free()
		for child_path: String in routes.keys():
			if child_path.begins_with(old + "/"):
				routes.erase(child_path)
	parent.add_child(node)
	node.owner = root
	node.set_meta("ruta_antes_de_ordenar", old)
	routes[old] = str(root.get_path_to(node))
	root.set_meta("rutas_ordenadas", routes)

static func grupo_de_piso(base: Node, old_relative: String, number: int, title: String) -> Node3D:
	var root := campus(base)
	var parent := root.get_node("PisoMenos1" if number == -1 else "Piso%d" % number)
	var result := Node3D.new()
	result.name = title
	guardar(base, result, old_relative, parent)
	return result

static func descendientes(base: Node, pattern: String, type: String, _recursive := true, _owned := false) -> Array[Node]:
	var root := campus(base)
	var prefix := ruta_original(base, root)
	var result: Array[Node] = []
	for node in root.find_children(pattern, type, true, false):
		if prefix.is_empty() or ruta_original(node, root).begins_with(prefix + "/"):
			result.append(node)
	return result
