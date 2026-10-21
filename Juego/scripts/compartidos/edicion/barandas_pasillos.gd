@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
const HEIGHTS: Array[float] = [0.0,12.058385849,23.967668533,35.674415588,47.974849701,60.158504486,71.942184448,83.913551331]
var glass: Material
var metal: Material
var plans: Array = []

func bounds_of(n: Node3D) -> AABB:
	if n is MeshInstance3D:
		return n.global_transform * n.get_aabb()
	if n is CSGBox3D:
		return n.global_transform * AABB(-n.size*0.5,n.size)
	return AABB()

func rect_of(b: AABB) -> Rect2:
	return Rect2(b.position.x,b.position.z,b.size.x,b.size.z)

func inside(p: Vector2, surfaces: Array[Rect2]) -> bool:
	for r in surfaces:
		if r.has_point(p): return true
	return false

func floor_like(title: String) -> bool:
	return title.begins_with("Building_Floor") or title.begins_with("Losa") or title.begins_with("PuenteAcceso") or title.begins_with("UmbralEntrada") or title.begins_with("UmbralPiso") or title.contains("_Cierre") or title in ["PisoCoordinacion","AccesoEscalera","PisoBibliotecaIntegrado","RellenoFrenteEscalera","DesembarcoSuperior"]

func collect(level: int) -> Dictionary:
	var surfaces: Array[Rect2] = []
	var barriers: Array[Rect2] = []
	var accesses: Array[Rect2] = []
	var y := HEIGHTS[level]
	for n in CampusNodes.campus(self).find_children("*","GeometryInstance3D",true,false):
		if (CampusNodes.contiene(self, n) and not str(n.name).begins_with("VidrioPasillo")) or not n.is_visible_in_tree(): continue
		if not (n is MeshInstance3D or n is CSGBox3D): continue
		if n is MeshInstance3D and n.mesh == null: continue
		if n is CSGBox3D and n.get_child_count() > 0: continue
		var b := bounds_of(n)
		if b.size.x < 0.01 or b.size.z < 0.01: continue
		var title := str(n.name)
		if floor_like(title) and not title.contains("Techo") and absf(b.end.y-y) < 0.65:
			surfaces.append(rect_of(b))
		# Keep existing walls, low rails, and solid wooden stair sides.
		if b.position.y < y+0.75 and b.end.y > y+1.25 and minf(b.size.x,b.size.z)<1.0:
			barriers.append(rect_of(b).grow(0.65))
		# Reserve the whole player volume, including stairs below this floor.
		if title.begins_with("Step") or title.begins_with("Escalera Norte") or title.begins_with("Escalera Sur") or title == "DesembarcoSuperior":
			if b.end.y + 2.8 > y and b.position.y < y + 1.8:
				accesses.append(rect_of(b).grow(0.55))
	return {"surfaces":surfaces,"barriers":barriers,"accesses":accesses}

func needed(p: Vector2, normal: Vector2, data: Dictionary) -> bool:
	if inside(p,data.barriers) or inside(p,data.accesses): return false
	var a := inside(p+normal*0.22,data.surfaces)
	var b := inside(p-normal*0.22,data.surfaces)
	return a != b

func make_plan(level: int) -> Array:
	var data := collect(level)
	var xs: Array[float] = []
	var zs: Array[float] = []
	for r in data.surfaces:
		for x in [r.position.x,r.end.x]:
			var v: float = snappedf(x,0.01)
			if not xs.has(v): xs.append(v)
		for z in [r.position.y,r.end.y]:
			var v: float = snappedf(z,0.01)
			if not zs.has(v): zs.append(v)
	xs.sort()
	zs.sort()
	var lines: Dictionary = {}
	for r in data.surfaces:
		for axis in [0,1]:
			var coords: Array[float] = (zs if axis==0 else xs).duplicate()
			var lo: float = r.position.y if axis==0 else r.position.x
			var hi: float = r.end.y if axis==0 else r.end.x
			var constants: Array = [r.position.x,r.end.x] if axis==0 else [r.position.y,r.end.y]
			for c in constants:
				var cuts: Array[float] = coords.duplicate()
				for barrier in data.barriers + data.accesses:
					var cross_lo: float = barrier.position.x if axis==0 else barrier.position.y
					var cross_hi: float = barrier.end.x if axis==0 else barrier.end.y
					if c < cross_lo or c > cross_hi: continue
					for cut in ([barrier.position.y,barrier.end.y] if axis==0 else [barrier.position.x,barrier.end.x]):
						if cut>lo and cut<hi and not cuts.has(cut): cuts.append(cut)
				cuts.sort()
				var key := str(axis)+":"+str(snappedf(c,0.01))
				if not lines.has(key): lines[key] = {"axis":axis,"c":float(c),"intervals":[]}
				for i in range(cuts.size()-1):
					var a := maxf(lo,cuts[i])
					var b := minf(hi,cuts[i+1])
					if b-a<0.035: continue
					var p := Vector2(c,(a+b)*0.5) if axis==0 else Vector2((a+b)*0.5,c)
					if needed(p,Vector2.RIGHT if axis==0 else Vector2.DOWN,data):
						lines[key].intervals.append(Vector2(a,b))
	var result: Array = []
	for line in lines.values():
		var intervals: Array = line.intervals
		intervals.sort_custom(func(a,b): return a.x<b.x)
		var start := INF
		var finish := -INF
		for interval in intervals:
			if interval.x <= finish+0.025:
				finish = maxf(finish,interval.y)
			else:
				if finish-start>0.15: result.append({"axis":line.axis,"c":line.c,"start":start,"end":finish})
				start = interval.x
				finish = interval.y
		if finish-start>0.15: result.append({"axis":line.axis,"c":line.c,"start":start,"end":finish})
	return result

func own(parent: Node, n: Node) -> void:
	parent.add_child(n)
	n.owner = owner

# Apply before rebuilding rails. Keep slabs and their physics shapes together.
func repair_stair_access() -> Dictionary:
	var campus := CampusNodes.campus(self)
	var changed: Array[String] = []
	var edge_z := -132.9532
	for n in campus.find_children("*", "GeometryInstance3D", true, false):
		if not (n is MeshInstance3D or n is CSGBox3D): continue
		var title := str(n.name)
		if not floor_like(title) or title.contains("Techo"): continue
		var b := bounds_of(n)
		# These slabs extend 0.8 m into the principal staircase opening.
		if b.position.x < -18.0 and b.end.x > 15.0 and b.position.z < -140.0 and b.end.z > edge_z and b.end.z < -131.0 and b.end.y > 10.0:
			var depth := edge_z - b.position.z
			if n is CSGBox3D:
				n.size.z = depth
			else:
				if not n.mesh is BoxMesh: continue
				n.mesh = n.mesh.duplicate()
				n.mesh.size.z = depth
				for c in n.find_children("*", "CollisionShape3D", true, false):
					if c.shape is BoxShape3D:
						c.shape = c.shape.duplicate()
						c.shape.size.z = depth
			var p: Vector3 = n.global_position
			p.z = b.position.z + depth * 0.5
			n.global_position = p
			changed.append(str(campus.get_path_to(n)))
	var front := CampusNodes.obtener(campus, "Piso2/AcabadosZonaAscensores/BarandasAtrio")
	for n in front.get_children():
		if str(n.name).contains("Frente"):
			var p: Vector3 = n.global_position
			p.z = -133.0532
			n.global_position = p
	return {"losas_recortadas": changed, "baranda_frontal_z": -133.0532}

func box(parent: Node3D, title: String, pos: Vector3, dimensions: Vector3, mat: Material, solid: bool) -> void:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	own(parent,n)
	if solid:
		var body := StaticBody3D.new()
		body.name = "Cuerpo"
		own(n,body)
		var collision := CollisionShape3D.new()
		collision.name = "Colision"
		var shape := BoxShape3D.new()
		shape.size = dimensions + Vector3(0.04,0,0.04)
		collision.shape = shape
		own(body,collision)

func build() -> Array:
	repair_stair_access()
	CampusNodes.limpiar(self)
	glass = CampusNodes.obtener(CampusNodes.campus(self), "Piso2/AcabadosZonaAscensores/BarandasAtrio/VidrioPasillo0").material_override
	metal = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var report: Array = []
	plans.clear()
	for level in range(1,8):
		var plan := make_plan(level)
		plans.append(plan)
		var group := CampusNodes.grupo_de_piso(self, "Piso" + str(level+1), level+1, "BarandasPasillos")
		var count := 0
		var total := 0.0
		for edge in plan:
			var length: float = edge.end-edge.start
			var pieces := maxi(1,ceili(length/3.6))
			var step: float = length/pieces
			total += length
			for i in range(pieces):
				var midpoint: float = edge.start+(i+0.5)*step
				var position_value := Vector3(edge.c,HEIGHTS[level]+0.8,midpoint) if edge.axis==0 else Vector3(midpoint,HEIGHTS[level]+0.8,edge.c)
				var dimensions := Vector3(0.06,1.6,step) if edge.axis==0 else Vector3(step,1.6,0.06)
				box(group,"VidrioPasillo%03d"%count,position_value,dimensions,glass,true)
				position_value.y = HEIGHTS[level]+1.64
				dimensions.y = 0.08
				box(group,"Pasamanos%03d"%count,position_value,dimensions,metal,false)
				var post := Vector3(edge.c,HEIGHTS[level]+0.82,edge.start+i*step) if edge.axis==0 else Vector3(edge.start+i*step,HEIGHTS[level]+0.82,edge.c)
				box(group,"Poste%03d"%count,post,Vector3(0.07,1.68,0.07),metal,false)
				count += 1
			var post_end := Vector3(edge.c,HEIGHTS[level]+0.82,edge.end) if edge.axis==0 else Vector3(edge.end,HEIGHTS[level]+0.82,edge.c)
			box(group,"PosteFinal"+str(count),post_end,Vector3(0.07,1.68,0.07),metal,false)
		report.append({"piso":level+1,"paneles":count,"metros":snappedf(total,0.01)})
	set_meta("barandas_instaladas",report)
	return report

func verificar() -> Dictionary:
	var panels := CampusNodes.descendientes(self, "VidrioPasillo*","MeshInstance3D",true,false)
	var missing_collision: Array = []
	for n in panels:
		if not n.has_node("Cuerpo/Colision"): missing_collision.append(str(n.get_path()))
	var remaining: Array = []
	for level in range(1,8):
		var open := make_plan(level)
		var length := 0.0
		for edge in open: length += edge.end-edge.start
		remaining.append({"piso":level+1,"metros_sin_baranda":snappedf(length,0.01)})
	return {"paneles":panels.size(),"sin_colision":missing_collision,"bordes_pendientes":remaining}

func vista() -> void:
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	camera.global_position = Vector3(-13,30,-116)
	camera.look_at(Vector3(-24,24,-122),Vector3.UP)

func probar_colisiones() -> Dictionary:
	var checked := 0
	var failures: Array = []
	for panel in CampusNodes.descendientes(self, "VidrioPasillo*","MeshInstance3D",true,false):
		var center: Vector3 = panel.global_position
		var size: Vector3 = panel.mesh.size
		var normal := Vector3.RIGHT if size.x < size.z else Vector3.BACK
		var query := PhysicsRayQueryParameters3D.create(center-normal*0.45,center+normal*0.45)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			failures.append(str(panel.name))
		else:
			checked += 1
	return {"colisiones_comprobadas":checked,"fallos":failures}
