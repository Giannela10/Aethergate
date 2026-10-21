@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
const LEVELS: Array[float] = [0.0,12.058385849,23.967668533,35.674415588,47.974849701,60.158504486,71.942184448,83.913551331]
func subtract(rect: Rect2, cut: Rect2) -> Array[Rect2]:
	var overlap := rect.intersection(cut)
	if not overlap.has_area(): return [rect]
	var pieces: Array[Rect2] = []
	if overlap.position.y > rect.position.y:
		pieces.append(Rect2(rect.position,Vector2(rect.size.x,overlap.position.y-rect.position.y)))
	if overlap.end.y < rect.end.y:
		pieces.append(Rect2(Vector2(rect.position.x,overlap.end.y),Vector2(rect.size.x,rect.end.y-overlap.end.y)))
	if overlap.position.x > rect.position.x:
		pieces.append(Rect2(Vector2(rect.position.x,overlap.position.y),Vector2(overlap.position.x-rect.position.x,overlap.size.y)))
	if overlap.end.x < rect.end.x:
		pieces.append(Rect2(Vector2(overlap.end.x,overlap.position.y),Vector2(rect.end.x-overlap.end.x,overlap.size.y)))
	return pieces
func remove_area(regions: Array[Rect2], cut: Rect2) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in regions: result.append_array(subtract(rect,cut))
	return result
func holes(level: int) -> Array[Rect2]:
	var regions: Array[Rect2] = [Rect2(-84.8,-162.45,169.1,86.05 if level<5 else 40.5)]
	for cut in [
		Rect2(-85,-163,14.3,23.3),Rect2(70.6,-163,14.4,23.3),
		Rect2(-19.4,-133.3,35.8,10.85),
		Rect2(-18.5,-122.5,44.1,46.1),
		Rect2(-12.7,-162.6,5.4,13.3),Rect2(-2.7,-162.6,5.4,13.3),Rect2(7.3,-162.6,5.4,13.3)]:
		regions = remove_area(regions,cut)
	if level == 1:
		regions = remove_area(regions,Rect2(32.3,-122.3,52,35.8))
		regions = remove_area(regions,Rect2(-32.5,-122.5,14.0,46.1))
	if level <= 1:
		regions = remove_area(regions,Rect2(36.8,-86.7,39.2,10.3))
	var campus := CampusNodes.campus(self)
	# Mantener las nuevas aberturas si se vuelve a ejecutar la reparación de losas.
	var basement := CampusNodes.buscar(campus, "PisoMenosUnoYEmergencia")
	if basement:
		if basement.has_meta("caja_emergencia"):
			regions = remove_area(regions, basement.get_meta("caja_emergencia"))
		if level == 0 and basement.has_meta("abertura_piso1"):
			regions = remove_area(regions, basement.get_meta("abertura_piso1"))
	# Preserve the three protected terrace wells when repairing floor continuity.
	for well in campus.find_children("Vacio*","Node3D",true,false):
		if absf(well.global_position.y-LEVELS[level])<0.65 and well.has_meta("area_no_transitable"):
			regions = remove_area(regions,well.get_meta("area_no_transitable"))
	for n in campus.find_children("*","GeometryInstance3D",true,false):
		if CampusNodes.contiene(self, n) or not n.is_visible_in_tree(): continue
		var title := str(n.name)
		var floor_like := title.begins_with("Building_Floor") or title.begins_with("Losa") or title.begins_with("PuenteAcceso") or title.begins_with("UmbralEntrada") or title.begins_with("UmbralPiso") or title in ["PisoCoordinacion","AccesoEscalera","PisoBibliotecaIntegrado"]
		if not floor_like: continue
		if n is MeshInstance3D and n.mesh == null: continue
		if not (n is MeshInstance3D or n is CSGBox3D): continue
		var bounds: AABB = n.global_transform * n.get_aabb()
		if absf(bounds.end.y-LEVELS[level]) > 0.65: continue
		regions = remove_area(regions,Rect2(bounds.position.x,bounds.position.z,bounds.size.x,bounds.size.z))
	return regions
func audit() -> Array:
	var report: Array = []
	for i in range(8):
		var patches := holes(i)
		var areas: Array = []
		var total := 0.0
		for rect in patches:
			if rect.size.x < 0.06 or rect.size.y < 0.06: continue
			total += rect.get_area()
			areas.append({"min":rect.position,"size":rect.size})
		report.append({"piso":i+1,"area_faltante":total,"huecos":areas})
	return report
func unify_elevator_floors() -> Dictionary:
	var mat: Material = load("res://materials/entrance/MAT_Interior_Floor_Dark.tres")
	var changed := 0
	var aligned := 0
	for redundant in CampusNodes.descendientes(CampusNodes.obtener(CampusNodes.campus(self), "AccesosAscensores"), "PasilloPiso*","CSGBox3D",true,false):
		redundant.visible = false
		redundant.use_collision = false
	for n in CampusNodes.campus(self).find_children("*","CSGBox3D",true,false):
		if not (str(n.name).begins_with("Losa") or str(n.name).begins_with("UmbralPiso")): continue
		n.material = mat
		changed += 1
		if str(n.name).begins_with("UmbralPiso"):
			var bounds: AABB = n.global_transform * n.get_aabb()
			for y in LEVELS:
				if absf(bounds.end.y-y) < 0.4:
					n.global_position.y += y-bounds.end.y
					aligned += 1
					break
	return {"materiales_unificados":changed,"umbrales_nivelados":aligned}

func apply() -> Array:
	CampusNodes.limpiar(self)
	var mat: Material = load("res://materials/entrance/MAT_Interior_Floor_Dark.tres")
	var report: Array = []
	for i in range(8):
		var patches := holes(i)
		var count := 0
		for rect in patches:
			if rect.size.x < 0.06 or rect.size.y < 0.06: continue
			var n := MeshInstance3D.new()
			n.name = "Piso"+str(i+1)+"_Cierre"+str(count+1)
			n.position = Vector3(rect.get_center().x,LEVELS[i]-0.15,rect.get_center().y)
			var mesh := BoxMesh.new()
			mesh.size = Vector3(rect.size.x,0.3,rect.size.y)
			n.mesh = mesh
			n.material_override = mat
			CampusNodes.guardar(self, n, str(n.name), CampusNodes.categoria_piso(self, i+1, "LosasYAccesos"))
			n.owner = get_tree().edited_scene_root
			var body := StaticBody3D.new()
			n.add_child(body)
			body.owner = n.owner
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = mesh.size
			collision.shape = shape
			body.add_child(collision)
			collision.owner = n.owner
			count += 1
		report.append({"piso":i+1,"cierres":count})
	set_meta("reparaciones",report)
	return report
