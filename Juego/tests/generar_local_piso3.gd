extends SceneTree

func _initialize() -> void:
	var builder := Node3D.new()
	builder.set_script(load("res://scripts/pisos/piso_3/local_comida_referencia.gd"))
	builder.name = "LocalComidaReferencia"
	var result: Dictionary = builder.build()
	var scene := PackedScene.new()
	var error := scene.pack(builder)
	if error == OK:
		error = ResourceSaver.save(scene, "res://scripts/pisos/piso_3/LocalComidaReferencia.tscn")
	print("LOCAL_PISO3_BUILD_RESULT ", result, " error=", error)
	builder.free()
	quit(0 if error == OK else 1)
