@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
func add_box(parent: Node3D, title: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var n := MeshInstance3D.new()
	n.name = title
	n.position = pos
	var b := BoxMesh.new()
	b.size = size
	n.mesh = b
	n.material_override = mat
	parent.add_child(n)
	n.owner = get_tree().edited_scene_root

func apply() -> void:
	var steel := StandardMaterial3D.new()
	steel.resource_name = "MAT_Acero_Inoxidable_Ascensor"
	steel.albedo_color = Color(0.58,0.61,0.63)
	steel.metallic = 0.82
	steel.roughness = 0.3
	steel.anisotropy_enabled = true
	steel.anisotropy = 0.65
	var glass := StandardMaterial3D.new()
	glass.resource_name = "MAT_Vidrio_Panoramico_Ascensor"
	glass.albedo_color = Color(0.75,0.88,0.91,0.065)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.roughness = 0.14
	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = Color(0.85,0.9,0.93)
	lamp.emission_enabled = true
	lamp.emission = Color(0.85,0.9,0.93)
	lamp.emission_energy_multiplier = 1.5
	ResourceSaver.save(steel,"res://materials/entrance/MAT_Acero_Inoxidable_Ascensor.tres")
	ResourceSaver.save(glass,"res://materials/entrance/MAT_Vidrio_Panoramico_Ascensor.tres")
	ResourceSaver.save(lamp,"res://materials/entrance/MAT_Luz_Cabina.tres")
	var root := CampusNodes.campus(self)
	for n in root.find_children("VentanalAscensores","CSGBox3D",true,false):
		n.material = glass
	CampusNodes.obtener(root, "Piso1/Wall_Back2").material_override = glass
	var elevators := CampusNodes.obtener(root, "AscensoresEstudiantiles")
	for lift in elevators.get_children():
		for n in lift.find_children("*","CSGBox3D",true,false):
			if str(n.name).begins_with("Vidrio"): n.material = glass
			elif str(n.name).begins_with("Guia"): n.material = steel
		var cabin := CampusNodes.obtener(lift, "Cabina")
		for title in ["CristalIzquierdo","CristalDerecho","Techo"]:
			CampusNodes.obtener(cabin, title).material_override = steel
		CampusNodes.obtener(cabin, "CristalPosterior").material_override = glass
		for n in lift.find_children("Panel","MeshInstance3D",true,false):
			n.material_override = steel
		var old := CampusNodes.buscar(cabin, "AcabadosInoxidable")
		if old:
			cabin.remove_child(old)
			old.free()
		var details := Node3D.new()
		details.name = "AcabadosInoxidable"
		cabin.add_child(details)
		details.owner = get_tree().edited_scene_root
		for x in [-2.27,2.27]:
			add_box(details,"PasamanosLateral",Vector3(x,1.05,0.8),Vector3(0.065,0.065,11.4),steel)
			for z in [-4,0,4,6]:
				add_box(details,"SoportePasamanos",Vector3(x,1.05,z),Vector3(0.18,0.045,0.045),steel)
			for z in [-4,-2,0,2,4,6]:
				add_box(details,"JuntaPanel",Vector3(x*1.027,1.65,z),Vector3(0.015,3.1,0.018),steel)
			add_box(details,"Zocalo",Vector3(x,0.12,0.85),Vector3(0.08,0.2,12.1),steel)
		add_box(details,"PasamanosPosterior",Vector3(0,1.05,-5.1),Vector3(4.4,0.065,0.065),steel)
		for z in [-3,1,5]:
			add_box(details,"LuminariaTecho",Vector3(0,3.19,z),Vector3(2.8,0.025,0.22),lamp)
		var light := OmniLight3D.new()
		light.name = "LuzInterior"
		light.position = Vector3(0,2.7,0.8)
		light.omni_range = 10
		light.light_energy = 0.65
		details.add_child(light)
		light.owner = details.owner
