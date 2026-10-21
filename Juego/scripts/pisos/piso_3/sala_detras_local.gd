@tool
extends "res://scripts/pisos/piso_8/piso_8_completo.gd"
## Sala existente al oeste del negocio y cierre del paso contiguo.

func _ready() -> void:
	pass

func build() -> Dictionary:
	for child in get_children():
		child.free()
	rooms.clear()
	position = Vector3(0, 23.985, 0)
	init_materials()
	# Mantiene los límites de la sala original entre los muros X=32.5 y X=46.3.
	classroom(303, 39.4, 13.4, -122.05, 23.9, true, true)
	box("MuroSobreMampara", Vector3(39.4, 7.78, -122.05), Vector3(13.4, 7.64, 0.15), materials.beige, true)
	# Continuidad hasta la pared del negocio: aquí no existe un pasillo.
	box("CierrePasoContiguo", Vector3(51.7, 5.8, -122.05), Vector3(11.2, 11.6, 0.30), materials.beige, true)
	set_meta("salas", rooms)
	set_meta("numero_piso", 3)
	return {"salas": 1, "paso_contiguo_cerrado": true}

func desk(parent: Node3D, center: Vector3, teacher: bool = false) -> void:
	var width := 2.0 if teacher else 1.45
	var depth := 0.85
	box("MesaDocente" if teacher else "MesaAlumno", center + Vector3(0, 0.76, 0), Vector3(width, 0.075, depth), materials.wood if teacher else materials.white, true, parent)
	for x in [-width * 0.40, width * 0.40]:
		for z in [-depth * 0.38, depth * 0.38]:
			box("PataMesa", center + Vector3(x, 0.37, z), Vector3(0.055, 0.74, 0.055), materials.black, false, parent)
	if teacher:
		box("NotebookDocente", center + Vector3(0.25, 0.81, 0), Vector3(0.34, 0.03, 0.25), materials.black, false, parent)
		box("PantallaNotebook", center + Vector3(0.25, 0.95, -0.12), Vector3(0.34, 0.26, 0.025), materials.black, false, parent)
