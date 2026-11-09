extends RefCounted
## Static render-surface samples for decorative floors whose collision is lower.
## Never creates colliders or changes the actor/controller.
static var world_id:=0
static var cells: Dictionary={}
static var large: Array=[]
static func height_at(model: Node3D, point: Vector3, physical_y: float) -> float:
	var id=model.get_world_3d().get_instance_id()
	if world_id!=id:
		world_id=id;cells.clear();large.clear();_build(model.get_tree().root)
	var key=Vector2i(floori(point.x/3),floori(point.z/3))
	var result=physical_y
	var candidates: Array=large.duplicate()
	if cells.has(key): candidates.append_array(cells[key])
	for tri in candidates:
		if tri[0].y>physical_y+0.25 or tri[0].y<physical_y-0.005: continue
		var a=Vector2(tri[0].x,tri[0].z)
		var b=Vector2(tri[1].x,tri[1].z)-a
		var c=Vector2(tri[2].x,tri[2].z)-a
		var p=Vector2(point.x,point.z)-a
		var area=b.cross(c)
		if absf(area)<0.00001: continue
		var u=p.cross(c)/area;var v=b.cross(p)/area
		if u>=-0.0001 and v>=-0.0001 and u+v<=1.0001: result=maxf(result,tri[0].y)
	return result
static func _build(root: Node) -> void:
	for node in root.find_children("*","MeshInstance3D",true,false):
		if node.mesh==null or not node.is_visible_in_tree(): continue
		var ancestor: Node=node
		var skip=false
		while ancestor!=null:
			if ancestor.is_in_group("campus_character_visual") or ancestor is AnimatableBody3D:
				skip=true;break
			ancestor=ancestor.get_parent()
		if skip: continue
		var bounds: AABB=node.global_transform*node.get_aabb()
		if bounds.size.y>0.26 and not str(node.name).begins_with("DetalleCombinado"): continue
		for surface in node.mesh.get_surface_count():
			var arrays=node.mesh.surface_get_arrays(surface)
			if arrays.size()!=Mesh.ARRAY_MAX or arrays[Mesh.ARRAY_VERTEX]==null: continue
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices=PackedInt32Array()
			if arrays[Mesh.ARRAY_INDEX]!=null: indices=arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for i in vertices.size(): indices.append(i)
			for i in range(0,indices.size()-2,3):
				var a: Vector3=node.global_transform*vertices[indices[i]]
				var b: Vector3=node.global_transform*vertices[indices[i+1]]
				var c: Vector3=node.global_transform*vertices[indices[i+2]]
				if maxf(absf(a.y-b.y),absf(a.y-c.y))>0.002: continue
				var box=AABB(a,Vector3.ZERO).expand(b).expand(c)
				if box.size.x*box.size.z<0.005: continue
				var from=Vector2i(floori(box.position.x/3),floori(box.position.z/3))
				var to=Vector2i(floori(box.end.x/3),floori(box.end.z/3))
				var tri=[a,b,c]
				if (to.x-from.x+1)*(to.y-from.y+1)>256: large.append(tri);continue
				for x in range(from.x,to.x+1):
					for z in range(from.y,to.y+1):
						var key=Vector2i(x,z)
						if not cells.has(key): cells[key]=[]
						cells[key].append(tri)
