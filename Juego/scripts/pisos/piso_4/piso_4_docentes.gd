@tool
extends "res://scripts/pisos/piso_4/piso_4_referencia.gd"
## Segunda mitad de la fila posterior. Conserva los accesos y el sector 411–416.
const HOLE := Rect2(36.6,-119.3,30.5,17.2)

func apply() -> Dictionary:
	restore_cut_floors()
	for child in get_children():
		remove_child(child)
		child.free()
	palette()
	entries.clear()
	global_position = Vector3(0,HEIGHT,0)
	trim_lower_wall_collision("Piso 3/Delantera_piso 3a")
	var front := CampusNodes.obtener(get_parent(), "Delantera_piso 4a")
	front.set_meta("piso4_sector_docentes_front",true)
	front.hide()
	for col in front.find_children("*","CollisionShape3D",true,false): col.disabled = true
	room("BanosDocentes",Rect2(32.25,-162.44,9.6,22.44),true,"bath")
	var teachers := room("ProfesoresCoordDocente",Rect2(41.85,-162.44,20,22.44),true,"teachers")
	for row in range(2):
		for col in range(3):
			desk(teachers,Vector3((col-1)*5,0,-6+row*6))
	var meeting := group(teachers,"MesaCompartida",Vector3(0,0,6))
	box(meeting,"Tablero",Vector3(0,1.0,0),Vector3(6,0.12,1.4),"wood",true)
	for x in [-2.5,2.5]: box(meeting,"Pie",Vector3(x,0.45,0),Vector3(0.1,0.9,1.1),"metal")
	for x in [-2.0,0.0,2.0]:
		chair(meeting,Vector3(x,0,1.4))
		var c := group(meeting,"SillaOpuesta",Vector3(x,0,-1.4))
		c.rotation.y = PI
		chair(c,Vector3.ZERO)
	var lounge := room("ED",Rect2(61.85,-162.44,8.52,22.44),true,"lounge")
	for z in [-6.0,2.0]:
		var table := group(lounge,"MesaEstar",Vector3(0,0,z))
		box(table,"Tablero",Vector3(0,0.95,0),Vector3(2.6,0.12,1.4),"wood",true)
		box(table,"Pie",Vector3(0,0.45,0),Vector3(0.15,0.9,1),"metal")
		chair(table,Vector3(-0.8,0,1.4))
		chair(table,Vector3(0.8,0,1.4))
	box(self,"CostadoOriginal",Vector3(32.25,5.975,-151.22),Vector3(0.2,11.95,22.44),"wall",true)
	var well := group(self,"VacioProfesoresPiso4")
	well.set_meta("area_no_transitable",HOLE)
	well.set_meta("vista_piso_inferior",3)
	var cut_count := cut_floor_hole(well)
	var panels := build_glass_fence(well)
	set_meta("alcance","Baños · Sala profesores / coordinación docente · ED · vacío con vidrio")
	set_meta("hueco",HOLE)
	return {"banos":1,"profesores_ancho":20,"ed_ancho":8.52,"profundidad":22.44,"hueco":HOLE,"losas_recortadas":cut_count,"paneles_vidrio":panels}

func restore_cut_floors() -> void:
	var campus := get_parent().get_parent()
	for n in campus.find_children("*","GeometryInstance3D",true,false):
		if not n.has_meta("piso4_vacio_original"): continue
		var before: Dictionary = n.get_meta("piso4_vacio_original")
		n.visible = before.visible
		if n is CSGBox3D: n.use_collision = before.use_collision
		for record in before.collisions:
			var col := CampusNodes.buscar(campus, record.path)
			if col: col.disabled = record.disabled
		n.remove_meta("piso4_vacio_original")

func subtract_rect(rect: Rect2,cut: Rect2) -> Array[Rect2]:
	var overlap := rect.intersection(cut)
	if not overlap.has_area(): return [rect]
	var pieces: Array[Rect2] = []
	if overlap.position.y>rect.position.y: pieces.append(Rect2(rect.position,Vector2(rect.size.x,overlap.position.y-rect.position.y)))
	if overlap.end.y<rect.end.y: pieces.append(Rect2(Vector2(rect.position.x,overlap.end.y),Vector2(rect.size.x,rect.end.y-overlap.end.y)))
	if overlap.position.x>rect.position.x: pieces.append(Rect2(Vector2(rect.position.x,overlap.position.y),Vector2(overlap.position.x-rect.position.x,overlap.size.y)))
	if overlap.end.x<rect.end.x: pieces.append(Rect2(Vector2(overlap.end.x,overlap.position.y),Vector2(rect.end.x-overlap.end.x,overlap.size.y)))
	return pieces

func cut_floor_hole(well: Node3D) -> int:
	var campus := get_parent().get_parent()
	var count := 0
	for n in campus.find_children("*","GeometryInstance3D",true,false):
		if is_ancestor_of(n): continue
		var title := str(n.name)
		if not (title.begins_with("Building_Floor") or title.begins_with("Losa") or title.contains("_Cierre") or title.begins_with("Pasillo")): continue
		var b: AABB
		if n is MeshInstance3D and n.mesh is BoxMesh: b = n.global_transform*n.get_aabb()
		elif n is CSGBox3D: b = n.global_transform*AABB(-n.size*0.5,n.size)
		else: continue
		if absf(b.end.y-HEIGHT)>0.6: continue
		var rect := Rect2(b.position.x,b.position.z,b.size.x,b.size.z)
		if not rect.intersection(HOLE).has_area(): continue
		var records: Array = []
		for col in n.find_children("*","CollisionShape3D",true,false):
			records.append({"path":campus.get_path_to(col),"disabled":col.disabled})
			col.disabled = true
		var had_collision: bool = n.use_collision if n is CSGBox3D else false
		n.set_meta("piso4_vacio_original",{"visible":n.visible,"collisions":records,"use_collision":had_collision})
		n.hide()
		if n is CSGBox3D: n.use_collision = false
		var original_material: Material = n.material if n is CSGBox3D else n.get_active_material(0)
		for piece in subtract_rect(rect,HOLE):
			var slab := box(well,"LosaBordeProfesores",Vector3(piece.get_center().x,b.get_center().y-HEIGHT,piece.get_center().y),Vector3(piece.size.x,b.size.y,piece.size.y),"floor",true)
			if original_material: slab.material_override = original_material
		count += 1
	return count

func build_glass_fence(well: Node3D) -> int:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.45,0.7,0.78,0.22)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.roughness = 0.12
	mats["well_glass"] = glass
	var fence := group(well,"CercaVidrioCompleta")
	var count := 0
	for axis in range(2):
		var length := HOLE.size.x if axis==0 else HOLE.size.y
		var start := HOLE.position.x if axis==0 else HOLE.position.y
		var pieces := ceili(length/2.5)
		var step := length/pieces
		var sides := [HOLE.position.y,HOLE.end.y] if axis==0 else [HOLE.position.x,HOLE.end.x]
		for side in sides:
			for i in range(pieces):
				var middle := start+(i+0.5)*step
				var p := Vector3(middle,0.9,side) if axis==0 else Vector3(side,0.9,middle)
				var size := Vector3(step,1.8,0.12) if axis==0 else Vector3(0.12,1.8,step)
				box(fence,"VidrioBorde%02d"%count,p,size,"well_glass",true)
				p.y = 1.85
				size.y = 0.1
				box(fence,"Pasamanos%02d"%count,p,size,"metal")
				var post := Vector3(start+i*step,0.94,side) if axis==0 else Vector3(side,0.94,start+i*step)
				box(fence,"Poste%02d"%count,post,Vector3(0.09,1.88,0.09),"metal")
				count += 1
			var end := Vector3(start+length,0.94,side) if axis==0 else Vector3(side,0.94,start+length)
			box(fence,"PosteFinal",end,Vector3(0.09,1.88,0.09),"metal")
	return count

func audit_void() -> Dictionary:
	var floors_left: Array = []
	var below: Array = []
	for ix in range(7):
		for iz in range(5):
			var p := Vector3(lerpf(HOLE.position.x+0.4,HOLE.end.x-0.4,ix/6.0),HEIGHT+0.35,lerpf(HOLE.position.y+0.4,HOLE.end.y-0.4,iz/4.0))
			var query := PhysicsRayQueryParameters3D.create(p,p-Vector3(0,1.2,0))
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty(): floors_left.append({"p":p,"collider":str(hit.collider.get_path())})
			query = PhysicsRayQueryParameters3D.create(p-Vector3(0,1.2,0),p-Vector3(0,14,0))
			hit = get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.position.y<23.0 or hit.position.y>25.0: below.append({"p":p,"hit":str(hit)})
	var gaps: Array = []
	var checks := 0
	var fence := CampusNodes.obtener(self, "VacioProfesoresPiso4/CercaVidrioCompleta")
	for panel in fence.get_children():
		if not str(panel.name).begins_with("VidrioBorde"): continue
		var size: Vector3 = panel.mesh.size
		var axis := Vector3.RIGHT if size.x>size.z else Vector3.BACK
		var normal := Vector3.BACK if size.x>size.z else Vector3.RIGHT
		var length := maxf(size.x,size.z)
		for offset in [-length*0.48,0.0,length*0.48]:
			var p: Vector3 = panel.global_position+axis*offset
			var query := PhysicsRayQueryParameters3D.create(p-normal*0.4,p+normal*0.4)
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			checks += 1
			if hit.is_empty(): gaps.append(str(panel.name))
	return {"puntos_vacio":35,"suelo_piso4_restante":floors_left,"vista_piso3_fallos":below,"pruebas_vidrio":checks,"huecos_baranda":gaps}

func check_fence_walking() -> void:
	var player = get_tree().get_first_node_in_group("player")
	player.set_physics_process(false)
	var actor := CharacterBody3D.new()
	actor.floor_snap_length = 0.5
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 2.7
	collision.shape = shape
	collision.position.y = 1.35
	actor.add_child(collision)
	get_parent().get_parent().add_child(actor)
	actor.add_collision_exception_with(player)
	var failures: Array = []
	var checked := 0
	for side in range(4):
		var normal := [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK][side] as Vector3
		for t in [0.05,0.5,0.95]:
			var p := Vector3(lerpf(HOLE.position.x,HOLE.end.x,t),HEIGHT,lerpf(HOLE.position.y,HOLE.end.y,t))
			if side==0: p.x = HOLE.position.x
			elif side==1: p.x = HOLE.end.x
			elif side==2: p.z = HOLE.position.y
			else: p.z = HOLE.end.y
			actor.global_position = p+normal*1.6+Vector3(0,0.12,0)
			actor.velocity = Vector3.ZERO
			for i in range(5): await get_tree().physics_frame
			for i in range(50):
				await get_tree().physics_frame
				actor.velocity = -normal*4
				actor.velocity.y = -1 if actor.is_on_floor() else -8
				actor.move_and_slide()
			checked += 1
			if HOLE.has_point(Vector2(actor.global_position.x,actor.global_position.z)) or actor.global_position.y<HEIGHT-0.5:
				failures.append({"lado":side,"muestra":t,"posicion":actor.global_position})
	actor.queue_free()
	player.set_physics_process(true)
	set_meta("prueba_cerca",{"casos":checked,"caidas":failures})
	print("PISO4_FENCE_WALK ",JSON.stringify(get_meta("prueba_cerca")))

func preview_docentes() -> void:
	var campus := get_parent().get_parent()
	for n in campus.find_children("*","GeometryInstance3D",true,false):
		if n is MeshInstance3D and n.mesh:
			var b: AABB = n.global_transform*n.get_aabb()
			if b.position.y>HEIGHT+10.5 and not is_ancestor_of(n): n.hide()
		elif n is CSGBox3D:
			var b: AABB = n.global_transform*AABB(-n.size*0.5,n.size)
			if b.position.y>HEIGHT+11.95: n.hide()
	for level in range(5,9):
		var floor_node := CampusNodes.buscar(campus, "Piso "+str(level))
		if floor_node: floor_node.hide()
	for n in campus.find_children("*","CanvasLayer",true,false): n.hide()
	var camera := Camera3D.new()
	campus.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 60
	camera.global_position = Vector3(92,104,-78)
	camera.look_at(Vector3(50,HEIGHT,-130))
	camera.make_current()
	var sun := DirectionalLight3D.new()
	campus.add_child(sun)
	sun.rotation_degrees = Vector3(-70,-35,0)
	sun.light_energy = 0.75
