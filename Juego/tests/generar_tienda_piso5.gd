extends SceneTree

func _initialize() -> void:
	var builder := Node3D.new()
	builder.name = "TiendaEsquinaPiso5"
	builder.set_script(load("res://scripts/pisos/piso_5/tienda_esquina_piso5.gd"))
	var result: Dictionary = builder.build()
	var scene := PackedScene.new()
	var error := scene.pack(builder)
	if error == OK:
		error = ResourceSaver.save(scene, "res://scripts/pisos/piso_5/TiendaEsquinaPiso5.tscn")
	print("TIENDA_PISO5_BUILD ", result, " error=", error)
	builder.free()
	quit(0 if error == OK else 1)
