extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var casino := Node3D.new()
	casino.set_script(load("res://scripts/pisos/piso_1/casino_referencia.gd"))
	root.add_child(casino)
	var interior := casino.get_node("InteriorFotografico")
	assert(interior.get_node("PisoBaldosas") is MeshInstance3D)
	assert(interior.get_node("FondoAtencion").get_child(0) is StaticBody3D)
	var count_before := interior.get_child_count()
	casino._ready()
	assert(interior.get_child_count() == count_before)
	assert(count_before > 500)
	print("Casino: geometría, colisiones e inicialización única OK (%d elementos)." % count_before)
	quit()
