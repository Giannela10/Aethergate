extends Node
var report: Dictionary = {}
func _ready() -> void:
	var packed := load("res://assets/characters/human_pilot/human_pilot.glb") as PackedScene
	var model := packed.instantiate() as Node3D
	add_child(model)
	var bounds := AABB()
	var first := true
	var meshes: Array = []
	var skeletons: Array = []
	var animations: Array = []
	var materials: Dictionary = {}
	for node in model.find_children("*","Node",true,false):
		if node is MeshInstance3D:
			var box: AABB = (model.global_transform.affine_inverse()*node.global_transform)*node.get_aabb()
			bounds = box if first else bounds.merge(box); first = false
			var surfaces: Array = []
			for i in node.mesh.get_surface_count():
				var arrays: Array = node.mesh.surface_get_arrays(i)
				surfaces.append({"vertices":arrays[Mesh.ARRAY_VERTEX].size(),"indices":arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null else 0,"bones":arrays[Mesh.ARRAY_BONES].size() if arrays[Mesh.ARRAY_BONES] != null else 0})
				var mat: Material = node.get_active_material(i)
				if mat is StandardMaterial3D:
					materials[mat.resource_name] = {"albedo":str(mat.albedo_color),"albedo_map":mat.albedo_texture != null,"normal_map":mat.normal_texture != null,"roughness_map":mat.roughness_texture != null,"metallic_map":mat.metallic_texture != null,"roughness":mat.roughness,"metallic":mat.metallic,"cull_mode":mat.cull_mode}
			meshes.append({"path":str(model.get_path_to(node)),"skin":node.skin != null,"skeleton_path":str(node.skeleton),"surfaces":surfaces})
		elif node is Skeleton3D:
			var bones: Array = []
			for i in node.get_bone_count(): bones.append(node.get_bone_name(i))
			skeletons.append({"path":str(model.get_path_to(node)),"bones":bones})
		elif node is AnimationPlayer:
			animations.append({"path":str(model.get_path_to(node)),"clips":Array(node.get_animation_list())})
	report = {"asset":"res://assets/characters/human_pilot/human_pilot.glb","root_transform":str(model.transform),"bounds_position":str(bounds.position),"bounds_size":str(bounds.size),"bounds_min":[bounds.position.x,bounds.position.y,bounds.position.z],"bounds_dimensions":[bounds.size.x,bounds.size.y,bounds.size.z],"meshes":meshes,"skeletons":skeletons,"animation_players":animations,"materials":materials}
	var file := FileAccess.open("res://reports/human_pilot_inspection.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("HUMAN_PILOT_INSPECTION ",JSON.stringify(report))
