@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
func raised(y: float) -> float:
	return 12.0+(y-12.0)*0.65 if y < 12.0 else y

func block(parent: Node3D, title: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var n := MeshInstance3D.new()
	n.name = title
	n.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mat
	parent.add_child(n)
	n.owner = get_tree().edited_scene_root
	var body := StaticBody3D.new()
	n.add_child(body)
	body.owner = n.owner
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	collision.owner = n.owner

func close_to_building_ceiling() -> String:
	var aud := CampusNodes.obtener(CampusNodes.campus(self), "Piso2/AuditorioPiso2e")
	if aud.has_meta("techo_hasta_losa"):
		return "Techo ya unido a la losa superior."
	var slab := CampusNodes.obtener(CampusNodes.campus(self), "Piso 3/Building_Floor Piso 3c") as MeshInstance3D
	var bounds: AABB = slab.global_transform * slab.get_aabb()
	var target_top := bounds.position.y
	var ceiling := CampusNodes.obtener(aud, "TechoAcustico") as Node3D
	var roof := CampusNodes.obtener(ceiling, "BaseTecho") as MeshInstance3D
	var old_bounds: AABB = roof.global_transform * roof.get_aabb()
	var delta := target_top-old_bounds.end.y
	ceiling.position.y += delta
	var wall_top := target_top-0.1
	for wall in CampusNodes.obtener(aud, "CierresHastaTecho").get_children():
		var mesh := wall.mesh.duplicate() as BoxMesh
		var bottom: float = wall.position.y-mesh.size.y/2
		mesh.size.y = wall_top-bottom
		wall.position.y = (wall_top+bottom)/2
		wall.mesh = mesh
		var collision := wall.get_child(0).get_child(0) as CollisionShape3D
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		collision.shape = shape
	for collision in CampusNodes.obtener(aud, "ColisionesAuditorio").find_children("*","CollisionShape3D",true,false):
		if not collision.shape is ConvexPolygonShape3D: continue
		var points: PackedVector3Array = collision.shape.points
		var is_roof := true
		for p in points:
			var world: Vector3 = collision.global_transform*p
			if world.y < old_bounds.position.y-0.02 or world.y > old_bounds.end.y+0.02:
				is_roof = false
				break
		if not is_roof: continue
		var shape := collision.shape.duplicate() as ConvexPolygonShape3D
		for i in points.size():
			var world: Vector3 = collision.global_transform*points[i]
			world.y += delta
			points[i] = collision.global_transform.affine_inverse()*world
		shape.points = points
		collision.shape = shape
	aud.set_meta("techo_hasta_losa",target_top)
	return "Techo unido a losa superior a %.3f m; paredes extendidas sin hueco." % target_top

func apply() -> String:
	var root := CampusNodes.campus(self)
	var aud := CampusNodes.obtener(root, "Piso2/AuditorioPiso2e")
	if aud.has_meta("base_elevada"):
		return "Base ya elevada."
	var tiers := CampusNodes.obtener(aud, "Graderias") as Node3D
	var tiers_transform := tiers.global_transform
	tiers_transform.origin.y = 4.2
	tiers_transform.basis.y *= 0.65
	tiers.global_transform = tiers_transform
	for seat in CampusNodes.obtener(aud, "Butacas").get_children():
		var p: Vector3 = seat.global_position
		p.y = raised(p.y)
		seat.global_position = p
	var stage := CampusNodes.obtener(aud, "Escenario")
	for n in stage.get_children():
		if not n is Node3D: continue
		var p: Vector3 = n.global_position
		if str(n.name) == "TarimaAmpliada":
			var mesh := n.mesh.duplicate() as BoxMesh
			mesh.size.y *= 0.65
			n.mesh = mesh
			p.y = raised(p.y)
		elif p.y < 12.0:
			p.y += raised(7.4)-7.4
		n.global_position = p
	# Independent world-space convex colliders keep the ramps connected.
	for collision in CampusNodes.obtener(aud, "ColisionesAuditorio").find_children("*","CollisionShape3D",true,false):
		if not collision.shape is ConvexPolygonShape3D: continue
		var shape := collision.shape.duplicate() as ConvexPolygonShape3D
		var points := shape.points
		for i in points.size():
			var world: Vector3 = collision.global_transform * points[i]
			world.y = raised(world.y)
			points[i] = collision.global_transform.affine_inverse() * world
		shape.points = points
		collision.shape = shape
	# Replace the thick floor block with the actual raised structural slab.
	var floor_node := CampusNodes.obtener(root, "Piso2/Building_Floor Piso 2e") as MeshInstance3D
	var floor_mesh := floor_node.mesh.duplicate() as BoxMesh
	floor_mesh.size = Vector3(25.562,0.3,35.452)
	floor_node.mesh = floor_mesh
	floor_node.position.y = raised(6.238)-0.15
	var floor_collision := CampusNodes.obtener(floor_node, "StaticBody3D/CollisionShape3D") as CollisionShape3D
	var floor_shape := BoxShape3D.new()
	floor_shape.size = floor_mesh.size
	floor_collision.shape = floor_shape
	floor_collision.get_parent().position = Vector3.ZERO
	floor_collision.position = Vector3.ZERO
	# Full-height continuous wood walls, preserving both entrance openings.
	var finish := Node3D.new()
	finish.name = "CierresHastaTecho"
	aud.add_child(finish)
	finish.owner = get_tree().edited_scene_root
	var wood: Material = load("res://materials/entrance/MAT_Auditorium_Plywood.tres")
	var bottom := raised(6.238)
	var top := 17.7
	for z in [-122.0,-86.85]:
		block(finish,"MuroLateral",Vector3(55.42,(bottom+top)/2,z),Vector3(25.5,top-bottom,0.12),wood)
	block(finish,"MuroEscenario",Vector3(42.72,(bottom+top)/2,-104.44),Vector3(0.12,top-bottom,35.15),wood)
	for segment in [[-122.0,-120.0],[-117.0,-92.0],[-89.0,-86.85]]:
		block(finish,"MuroEntradas",Vector3(68.05,(bottom+top)/2,(segment[0]+segment[1])/2),Vector3(0.12,top-bottom,segment[1]-segment[0]),wood)
	block(finish,"DintelHastaTecho",Vector3(68.05,(15.4+top)/2,-104.44),Vector3(0.12,top-15.4,35.15),wood)
	aud.set_meta("base_elevada",true)
	aud.set_meta("altura_nueva_base",bottom)
	return "Base elevada a %.2f m; entradas conservadas a 12 m y paredes hasta el techo." % bottom
