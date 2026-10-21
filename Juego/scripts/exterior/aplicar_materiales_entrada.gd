@tool
extends Node
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
# Utilidad manual: asigna recursos compartidos a geometría existente.
func apply_materials() -> Dictionary:
	var root := CampusNodes.campus(self)
	var assigned: Dictionary = {}
	var mapping := {
		"MAT_Facade_Dark": ["Piso2/Front_Left piso 2", "Piso2/Front_Right2", "Piso 3/Front_Right3", "Piso 4/Front_Right3"],
		"MAT_Lower_Wall_Light": ["Piso1/Front_Left", "Piso1/Front_Right", "Caseta/Muro/Bloque", "Caseta/Muro2/Bloque", "Caseta/Muro3/Bloque", "Caseta/Muro4/Bloque", "Caseta/Bloque", "Caseta Exterior/Bloque"],
		"MAT_Columns_Concrete": ["Piso1/Pilar1", "Piso1/Pilar2", "Piso1/Pilar5", "Piso1/Pilar6", "Piso1/Pilar9"],
		"MAT_Concrete_Floor": ["Floor/MeshInstance3D"],
	}
	for material_name in mapping:
		var mat := load("res://materials/entrance/" + material_name + ".tres") as StandardMaterial3D
		assigned[material_name] = []
		for path in mapping[material_name]:
			var n := CampusNodes.buscar(root, path)
			if n is MeshInstance3D:
				n.material_override = mat
			elif n is CSGBox3D:
				n.material = mat
			else:
				return {"error": "Geometría no encontrada: " + path}
			assigned[material_name].append(path)
	var metal := load("res://materials/entrance/MAT_Metal_Dark.tres") as StandardMaterial3D
	assigned["MAT_Metal_Dark"] = []
	for child in CampusNodes.hijos(root):
		if str(child.name).begins_with("Reja") or str(child.name) == "Torniquete":
			for n in child.find_children("*", "CSGBox3D", true, false):
				n.material = metal
				assigned["MAT_Metal_Dark"].append(str(root.get_path_to(n)))
	for path in ["Caseta Exterior/Torniquete/Bloque", "Caseta Exterior/Torniquete2/Bloque", "Caseta Exterior/Torniquete3/Bloque", "Caseta Exterior/Torniquete4/Bloque"]:
		var n := CampusNodes.obtener(root, path) as CSGBox3D
		n.material = metal
		assigned["MAT_Metal_Dark"].append(path)
	var report := FileAccess.open("res://materials/entrance/asignaciones.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(assigned, "\t"))
	var summary := {}
	for key in assigned:
		summary[key] = assigned[key].size()
	summary["sin_geometria_en_entrada"] = ["MAT_Window_Dark", "MAT_Glass_Entrance", "MAT_Grass"]
	return summary
