extends SceneTree
## Comprueba las etiquetas, la pertenencia a cada piso y las rutas de edición.
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var packed := load("res://Main.tscn") as PackedScene
	check(packed != null, "La escena principal debe cargar")
	if packed == null:
		quit(1)
		return
	var campus := packed.instantiate()
	campus.get_node("GameplayManager").free()
	root.add_child(campus)
	var levels := [-1, 1, 2, 3, 4, 5, 6, 7, 8]
	var labels: Array[String] = []
	for number in levels:
		var title := "PisoMenos1" if number == -1 else "Piso%d" % number
		var floor_node := campus.get_node_or_null(title)
		check(floor_node != null, "Falta " + title)
		if floor_node == null:
			continue
		check(floor_node.numero_piso == number and floor_node.is_in_group("pisos"), "Etiqueta incorrecta: " + title)
		check(not floor_node.descripcion.is_empty(), "Falta información: " + title)
		labels.append(floor_node.etiqueta)
		check(floor_node.has_node("EscaleraEmergencia"), "Falta la emergencia en " + title)
		check(floor_node.has_node("VestibuloAscensores"), "Falta el vestíbulo en " + title)
		check(floor_node.get_node("PuertasAscensores").get_child_count() == 3, "Deben existir tres puertas de ascensor en " + title)
		check(FileAccess.file_exists("res://scripts/pisos/%s/INFORMACION.md" % ("piso_menos_1" if number == -1 else "piso_%d" % number)), "Falta la ficha de " + title)
	var routes: Dictionary = campus.get_meta("rutas_ordenadas")
	for old: String in routes:
		check(campus.has_node(routes[old]), "Ruta ordenada inexistente: " + str(routes[old]))
		check(CampusNodes.buscar(campus, old) == campus.get_node_or_null(routes[old]), "Referencia de edición rota: " + old)
	for floor_node in campus.get_children():
		if not floor_node.is_in_group("pisos"):
			continue
		for old: String in routes:
			var prefix := CampusNodes.ruta_original(floor_node, campus) + "/"
			if old.begins_with(prefix):
				check(CampusNodes.buscar(floor_node, old.substr(prefix.length())) == campus.get_node(routes[old]), "Referencia relativa rota: " + old)
	for lift in campus.get_node("SistemasCompartidos/AscensoresEstudiantiles").get_children():
		check(lift.gate_paths.size() == 9, "Faltan referencias de puertas: " + str(lift.name))
		for i in lift.gate_paths.size():
			var floor_number: int = -1 if i == 8 else i + 1
			var title := "PisoMenos1" if floor_number == -1 else "Piso%d" % floor_number
			check(campus.get_node(title).is_ancestor_of(lift.get_node(lift.gate_paths[i])), "Puerta guardada en otro piso: " + str(lift.name))
	print("FLOOR_ORGANIZATION_RESULT " + JSON.stringify({"pisos": labels, "rutas": routes.size(), "failures": failures}))
	campus.free()
	quit(0 if failures.is_empty() else 1)
