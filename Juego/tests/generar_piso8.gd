extends SceneTree
## Construcción explícita: godot --headless --path . --script res://tests/generar_piso8.gd
func _initialize() -> void:
	call_deferred("generate")

func generate() -> void:
	var builder := Node3D.new()
	builder.set_script(load("res://scripts/pisos/piso_8/piso_8_completo.gd"))
	builder.name = "PasilloReferencia"
	var result: Dictionary = builder.build()
	var packed := PackedScene.new()
	var error := packed.pack(builder)
	if error == OK:
		error = ResourceSaver.save(packed, "res://scripts/pisos/piso_8/PasilloReferencia.tscn")
	print("PISO8_BUILD_RESULT ", result, " error=", error)
	builder.free()
	quit(0 if error == OK else 1)
