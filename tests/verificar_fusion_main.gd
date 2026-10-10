extends SceneTree
func _initialize() -> void:
	var packed := load("res://Main.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	var campus := packed.instantiate()
	for path in ["PisoMenos1","Piso1/PasilloDerechoYCapilla/Capilla","Piso1/InteriorCoordinacion/Recepcion","Piso2/Biblioteca/MobiliarioReferenciaFoto/MesonOvaladoAbierto","Piso2/Biblioteca/SalasEstudio","SistemasCompartidos","Exterior"]:
		if not campus.has_node(path):
			push_error("Falta elemento de una rama: "+path)
			quit(1)
			return
	# Las rutas del orden remoto deben reflejar también los muebles reemplazados.
	var routes: Dictionary = campus.get_meta("rutas_ordenadas")
	var removed := 0
	for previous in routes.keys():
		if not campus.has_node(routes[previous]):
			routes.erase(previous)
			removed += 1
	campus.set_meta("rutas_ordenadas",routes)
	var result := PackedScene.new()
	var error := result.pack(campus)
	if error == OK:
		error = ResourceSaver.save(result,"res://Main.tscn")
	print("FUSION_MAIN_OK=",error == OK," RUTAS_MOBILIARIO_REEMPLAZADO=",removed)
	campus.free()
	quit(error)
