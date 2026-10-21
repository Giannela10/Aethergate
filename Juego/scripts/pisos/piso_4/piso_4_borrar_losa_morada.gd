@tool
extends "res://scripts/pisos/piso_4/piso_4_docentes.gd"
const CUT := Rect2(-32.16,-122.0,13.66,24.152)
func apply() -> Dictionary:
	palette()
	global_position = Vector3(0,HEIGHT,0)
	set_meta("area_no_transitable",CUT)
	var campus := get_parent().get_parent()
	var changed: Array = []
	for n in campus.find_children("*","GeometryInstance3D",true,false):
		if is_ancestor_of(n) or not n.is_visible_in_tree(): continue
		var title := str(n.name)
		if not (title.begins_with("Building_Floor") or title.begins_with("Losa") or title.contains("_Cierre") or title.begins_with("Pasillo")): continue
		var b: AABB
		if n is MeshInstance3D and n.mesh is BoxMesh: b=n.global_transform*n.get_aabb()
		elif n is CSGBox3D: b=n.global_transform*AABB(-n.size*0.5,n.size)
		else: continue
		if absf(b.end.y-HEIGHT)>0.6: continue
		var rect := Rect2(b.position.x,b.position.z,b.size.x,b.size.z)
		if not rect.intersection(CUT).has_area(): continue
		var material: Material = n.get_active_material(0) if n is MeshInstance3D else n.material
		n.hide()
		for col in n.find_children("*","CollisionShape3D",true,false): col.disabled=true
		if n is CSGBox3D: n.use_collision=false
		for piece in subtract_rect(rect,CUT):
			var slab := box(self,"LosaFueraMarca",Vector3(piece.get_center().x,b.get_center().y-HEIGHT,piece.get_center().y),Vector3(piece.size.x,b.size.y,piece.size.y),"floor",true)
			slab.material_override=material
		changed.append(str(campus.get_path_to(n)))
	return {"solo_franja_morada":CUT,"losas_recortadas":changed}
func audit_cut() -> Dictionary:
	var failures: Array = []
	for ix in range(3):
		for iz in range(5):
			var p := Vector3(CUT.position.x+1+ix*(CUT.size.x-2)/2,HEIGHT,CUT.position.y+1+iz*(CUT.size.y-2)/4)
			var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.3,p-Vector3.UP*0.6))
			if not hit.is_empty(): failures.append(p)
	return {"puntos":15,"piso_restante_en_morado":failures}
