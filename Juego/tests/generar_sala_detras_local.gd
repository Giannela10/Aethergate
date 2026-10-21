extends SceneTree

func _initialize() -> void:
	var builder := Node3D.new()
	builder.set_script(load("res://scripts/pisos/piso_3/sala_detras_local.gd"))
	builder.name = "SalaDetrasLocal"
	var result: Dictionary = builder.build()
	var scene := PackedScene.new()
	var error := scene.pack(builder)
	if error == OK:
		error = ResourceSaver.save(scene, "res://scripts/pisos/piso_3/SalaDetrasLocal.tscn")
	print("SALA_DETRAS_LOCAL_BUILD ", result, " error=", error)
	builder.free()
	quit(0 if error == OK else 1)
