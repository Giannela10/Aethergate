@tool
extends "res://scripts/pisos/piso_4/piso_4_referencia.gd"
const AREA := Rect2(-18.5,-122.0,37.65,24.152)
func apply() -> Dictionary:
	for c in get_children():
		remove_child(c)
		c.free()
	palette()
	global_position = Vector3(0,HEIGHT,0)
	var campus := get_parent().get_parent()
	var removed := 0
	for path in ["Piso2/AuditorioPiso2e/AuditorioAmpliado/PasillosUniformesPisos1a4/Piso4","BarandasPasillosTodosLosPisos/Piso4"]:
		var old := CampusNodes.buscar(campus, path)
		if not old: continue
		for n in old.get_children():
			if not n is MeshInstance3D: continue
			var title := str(n.name)
			if not (title.begins_with("Cristal") or title.begins_with("Vidrio") or title.begins_with("Poste") or title.begins_with("Pasamanos")): continue
			var b: AABB = n.global_transform*n.get_aabb()
			if b.position.x < -20 or b.end.x > 26 or b.position.z < -122.2 or b.end.z > -97.6: continue
			old.remove_child(n)
			n.free()
			removed += 1
	var slab := box(self,"SueloContinuoSectorCentral",Vector3(AREA.get_center().x,-0.25,AREA.get_center().y),Vector3(AREA.size.x,0.5,AREA.size.y),"floor",true)
	slab.material_override = CampusNodes.obtener(get_parent(), "Building_Floor Piso 4b").material_override
	set_meta("barandas_retiradas",removed)
	set_meta("piso_repuesto",AREA)
	return {"barandas_retiradas":removed,"piso_repuesto":AREA}

func audit_floor() -> Dictionary:
	var failures: Array = []
	var count := 0
	for ix in range(7):
		for iz in range(5):
			var p := Vector3(AREA.position.x+1+ix*(AREA.size.x-2)/6,HEIGHT,AREA.position.y+1+iz*(AREA.size.y-2)/4)
			var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.2,p-Vector3.UP*0.5))
			count += 1
			if hit.is_empty(): failures.append(p)
	return {"puntos":count,"piso_ausente":failures}
