@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")

func prism(parent: Node3D, title: String, x0: float, x1: float, y0: float, y1: float, z: float, material: Material) -> void:
	var points := PackedVector3Array([
		Vector3(x0,y0-0.24,z-0.12),Vector3(x1,y1-0.24,z-0.12),
		Vector3(x1,y1+3.0,z-0.12),Vector3(x0,y0+3.0,z-0.12),
		Vector3(x0,y0-0.24,z+0.12),Vector3(x1,y1-0.24,z+0.12),
		Vector3(x1,y1+3.0,z+0.12),Vector3(x0,y0+3.0,z+0.12)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0,3,2,1],[4,5,6,7],[0,4,7,3],[1,2,6,5],[3,7,6,2],[0,1,5,4]]:
		for index in [face[0],face[1],face[2],face[0],face[2],face[3]]:
			surface.add_vertex(points[index])
	surface.generate_normals()
	var n := MeshInstance3D.new()
	n.name = title
	n.mesh = surface.commit()
	n.material_override = material
	parent.add_child(n)
	n.owner = get_tree().edited_scene_root
	var body := StaticBody3D.new()
	n.add_child(body)
	body.owner = n.owner
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	collision.shape = shape
	body.add_child(collision)
	collision.owner = n.owner

func apply() -> void:
	CampusNodes.limpiar(self)
	var wood := ShaderMaterial.new()
	wood.resource_name = "MAT_Madera_Escalera_Principal"
	wood.shader = load("res://materials/entrance/madera_escalera.gdshader")
	ResourceSaver.save(wood,"res://materials/entrance/MAT_Madera_Escalera_Principal.tres")
	var floor_mat := StandardMaterial3D.new()
	floor_mat.resource_name = "MAT_Peldanos_Oscuros"
	floor_mat.albedo_color = Color(0.035,0.039,0.04)
	floor_mat.roughness = 0.62
	ResourceSaver.save(floor_mat,"res://materials/entrance/MAT_Peldanos_Oscuros.tres")
	var root := CampusNodes.campus(self)
	var glazing := CampusNodes.buscar(root, "VidriosLateralesEscaleraPisos2a8")
	if glazing:
		root.remove_child(glazing)
		glazing.free()
	var count := 0
	for stair in root.find_children("Escalera ascensor*","Node3D",true,false):
		var decoration := CampusNodes.grupo_de_piso(self, "LateralesPiso" + str(count+1), count+1, "AcabadosEscaleraCentral")
		for child in stair.get_children():
			if child is MeshInstance3D and str(child.name).begins_with("Step"):
				child.material_override = floor_mat
		for flight in [0,1]:
			var steps: Array[MeshInstance3D] = []
			for child in stair.get_children():
				if not child is MeshInstance3D: continue
				var number := int(str(child.name).trim_prefix("Step"))
				if (flight == 0 and number >= 2 and number <= 16) or (flight == 1 and number >= 17 and number <= 34):
					steps.append(child)
			steps.sort_custom(func(a,b): return a.global_position.x < b.global_position.x)
			if steps.is_empty(): continue
			var first: AABB = steps.front().global_transform * steps.front().get_aabb()
			var last: AABB = steps.back().global_transform * steps.back().get_aabb()
			var x0 := first.position.x
			var x1 := last.end.x
			var y0 := first.end.y
			var y1 := last.end.y
			for z in [first.position.z-0.14,first.end.z+0.14]:
				prism(decoration,"PanelMaderaTramo"+str(flight+1),x0,x1,y0,y1,z,wood)
		var landing := CampusNodes.buscar(stair, "Step35")
		if landing:
			var bounds: AABB = landing.global_transform * landing.get_aabb()
			for z in [bounds.position.z-0.14,bounds.end.z+0.14]:
				prism(decoration,"PanelDescanso",bounds.position.x,bounds.end.x,bounds.end.y,bounds.end.y,z,wood)
		count += 1
	set_meta("tramos_entre_pisos",count)
	set_meta("vidrio_interior_retirado",true)

func verificar() -> Dictionary:
	var counts: Array = []
	for group in CampusNodes.hijos(self):
		counts.append({"piso":group.get_parent().etiqueta,"paneles":group.get_child_count()})
	return {"tramos":counts,"vidrio_interior_presente":CampusNodes.campus(self).has_node("VidriosLateralesEscaleraPisos2a8")}

func vista_escalera() -> void:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(-24,17,-112)
	camera.look_at(Vector3(-2,18,-127.8),Vector3.UP)

