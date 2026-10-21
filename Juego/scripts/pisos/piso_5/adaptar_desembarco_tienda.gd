@tool
extends Node3D
## Ajuste manual guardado en Main: nicho, ancho de escalera y protecciones bajas.

func _ready() -> void:
	pass

func box(title: String, bounds: AABB, surface: Material, solid: bool = true) -> void:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = bounds.size
	n.mesh = mesh
	n.material_override = surface
	add_child(n)
	n.owner = owner
	n.global_position = bounds.get_center()
	if solid:
		var body := StaticBody3D.new()
		n.add_child(body)
		body.owner = owner
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = bounds.size
		collision.shape = shape
		body.add_child(collision)
		collision.owner = owner

func cut_wall(node: MeshInstance3D, hole: AABB) -> void:
	var bounds := node.global_transform * node.get_aabb()
	var overlap := bounds.intersection(hole)
	if not overlap.has_volume():
		return
	var surface := node.get_active_material(0)
	node.visible = false
	for collision in node.find_children("*", "CollisionShape3D", true, false):
		collision.disabled = true
	var pieces := [
		AABB(bounds.position, Vector3(overlap.position.x - bounds.position.x, bounds.size.y, bounds.size.z)),
		AABB(Vector3(overlap.end.x, bounds.position.y, bounds.position.z), Vector3(bounds.end.x - overlap.end.x, bounds.size.y, bounds.size.z)),
		AABB(Vector3(overlap.position.x, bounds.position.y, bounds.position.z), Vector3(overlap.size.x, overlap.position.y - bounds.position.y, bounds.size.z)),
		AABB(Vector3(overlap.position.x, overlap.end.y, bounds.position.z), Vector3(overlap.size.x, bounds.end.y - overlap.end.y, bounds.size.z)),
		AABB(Vector3(overlap.position.x, overlap.position.y, bounds.position.z), Vector3(overlap.size.x, overlap.size.y, overlap.position.z - bounds.position.z)),
		AABB(Vector3(overlap.position.x, overlap.position.y, overlap.end.z), Vector3(overlap.size.x, overlap.size.y, bounds.end.z - overlap.end.z))]
	for piece in pieces:
		if piece.size.x > 0.01 and piece.size.y > 0.01 and piece.size.z > 0.01:
			box("MuroFueraNicho", piece, surface)

func apply() -> Dictionary:
	if get_child_count() > 0:
		return {"estado": "estructura ya ajustada"}
	var campus := owner
	var floor_node := campus.get_node("Piso5")
	var hole := AABB(Vector3(-35, 47.95, -142.8), Vector3(12.2, 8.2, 3.5))
	cut_wall(floor_node.get_node("Estructura/Delantera_piso 5c"), hole)
	cut_wall(floor_node.get_node("Estructura/Wall_Right piso 5b2"), hole)
	var cream := StandardMaterial3D.new()
	cream.albedo_color = Color(0.70, 0.68, 0.60)
	cream.roughness = 0.88
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color(0.96, 0.68, 0.035)
	yellow.roughness = 0.72
	var railing := StandardMaterial3D.new()
	railing.albedo_color = Color(0.035, 0.035, 0.035)
	railing.roughness = 0.5
	var count := 0
	for step in floor_node.get_node("Escaleras/Escalera ascensor5").get_children():
		if not step is MeshInstance3D or not step.mesh is BoxMesh or not str(step.name).begins_with("Step"):
			continue
		var mesh := step.mesh.duplicate() as BoxMesh
		if mesh.size.z < 9.5 or mesh.size.z > 10.5:
			continue
		mesh.size.z = 5.2
		step.mesh = mesh
		for collision in step.find_children("*", "CollisionShape3D", true, false):
			if collision.shape is BoxShape3D:
				var shape := collision.shape.duplicate() as BoxShape3D
				shape.size.z = 5.2
				collision.shape = shape
		var bounds: AABB = step.global_transform * step.get_aabb()
		box("NarizAmarilla", AABB(Vector3(bounds.position.x + 0.015, bounds.end.y + 0.006, bounds.position.z), Vector3(0.09, 0.024, bounds.size.z)), yellow, false)
		count += 1
	# Los paneles originales sobresalían 3 m sobre cada peldaño.
	for panel in floor_node.get_node("AcabadosEscaleraCentral").get_children():
		if not panel is MeshInstance3D:
			continue
		var collisions := panel.find_children("*", "CollisionShape3D", true, false)
		if collisions.is_empty() or not collisions[0].shape is ConvexPolygonShape3D:
			continue
		var points: PackedVector3Array = collisions[0].shape.points.duplicate()
		for i in range(points.size()):
			if i in [2, 3, 6, 7]:
				points[i].y -= 1.8
			points[i].z += 2.4 if points[i].z < -127.8 else -2.4
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for face in [[0,3,2,1],[4,5,6,7],[0,4,7,3],[1,2,6,5],[3,7,6,2],[0,1,5,4]]:
			for index in [face[0],face[1],face[2],face[0],face[2],face[3]]:
				surface.add_vertex(points[index])
		surface.generate_normals()
		panel.mesh = surface.commit()
		panel.material_override = cream
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		collisions[0].shape = shape
	for rail in floor_node.get_node("BarandasEscalerasPrincipales/TramoSuperior4").get_children():
		if rail is Node3D:
			rail.position.z += 2.4 if rail.position.z < -127.8 else -2.4
		if rail is CSGBox3D:
			rail.material = railing
	box("PlacaTactilDesembarco", AABB(Vector3(-20.3, 47.981, -130.4), Vector3(1.2, 0.035, 5.2)), yellow, false)
	return {"nicho_abierto": true, "ancho_escalera": 5.2, "altura_laterales": 1.2, "peldaños_marcados": count}
