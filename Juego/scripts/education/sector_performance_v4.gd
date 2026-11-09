extends Node
## Batch repeated opaque boxes in fixed structure only. Physics is untouched.
var platform: Node
var enabled := false # Draw calls fall, but CPU samples varied: opt-in benchmark only.
var batches: Array = []
var batched_meshes := 0
func _ready() -> void:
	for floor_number in [-1,1,2,3,4,5,6,7,8]:
		var root: Node = platform.campaign.get_parent().get_node("PisoMenos1" if floor_number==-1 else "Piso"+str(floor_number))
		for name in ["Losas","LosasYAccesos","BarandasPasillos","BarandasEscalerasPrincipales","Estructura"]:
			var structure := root.get_node_or_null(name) as Node3D
			if structure: _batch_static(structure)
	set_enabled(enabled)

func _batch_static(structure: Node3D) -> void:
	var candidates := {}
	for node in structure.find_children("*","MeshInstance3D",true,false):
		if not node.visible or not node.mesh is BoxMesh or node.mesh.get_surface_count()!=1: continue
		var material = node.get_active_material(0)
		if not material is StandardMaterial3D or material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or material.emission_enabled or material.albedo_texture!=null or material.normal_enabled or material.roughness_texture!=null or material.metallic_texture!=null: continue
		var size: Vector3 = node.mesh.size
		var key := str([size,material.albedo_color,material.roughness,material.metallic,material.cull_mode,material.shading_mode,material.vertex_color_use_as_albedo,node.cast_shadow])
		if not candidates.has(key): candidates[key]=[]
		candidates[key].append(node)
	for nodes in candidates.values():
		if nodes.size()<12: continue
		var multimesh := MultiMesh.new(); multimesh.transform_format=MultiMesh.TRANSFORM_3D
		multimesh.mesh=nodes[0].mesh; multimesh.instance_count=nodes.size()
		for index in nodes.size(): multimesh.set_instance_transform(index,structure.global_transform.affine_inverse()*nodes[index].global_transform)
		var batch := MultiMeshInstance3D.new(); batch.name="StaticBatchV4"; batch.multimesh=multimesh
		batch.material_override=nodes[0].get_active_material(0); batch.cast_shadow=nodes[0].cast_shadow
		structure.add_child(batch)
		batches.append({"batch":batch,"originals":nodes})
		batched_meshes+=nodes.size()
func set_enabled(value: bool) -> void:
	enabled=value
	for row in batches:
		row.batch.visible=enabled
		for mesh in row.originals: mesh.visible=not enabled
