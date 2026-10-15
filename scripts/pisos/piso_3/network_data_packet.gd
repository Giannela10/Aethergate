class_name NetworkDataPacket
extends "res://scripts/pisos/piso_8/proyectil_error_sistema.gd"
## Reutiliza el barrido de colisiones, alcance y daño de proyectiles existentes.
func _ready() -> void:
	super._ready()
	for node in get_children():
		if node is Label3D:
			node.text = "DATOS"
	var material := model.material_override as StandardMaterial3D
	material.albedo_color = Color("62ffc7")
	material.emission = Color("08b59d")
