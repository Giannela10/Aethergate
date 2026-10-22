extends SceneTree
## Verifies room closure, PC orientation and usable access through the real doors.
var failures: Array[String] = []
var routes := 0
var floor_samples := 0
var campus: Node3D
var library: Node3D
var probe: Node3D
var floor_y: float
var capsule: CapsuleShape3D

func _initialize() -> void:
	call_deferred("run")

func walk_segment(start: Vector3, finish: Vector3, description: String) -> void:
	routes += 1
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY,start)
	query.motion = finish-start
	query.collision_mask = 1
	var space = root.world_3d.direct_space_state
	var sweep = space.cast_motion(query)
	if sweep[0] < .999:
		failures.append("Blocked: "+description)
		query.transform.origin = start.lerp(finish,minf(sweep[1]+.015,1))
		query.motion = Vector3.ZERO
		for hit in space.intersect_shape(query):
			print("LIBRARY_BLOCKER ",description," ",hit.collider.get_path())
	for i in range(11):
		floor_samples += 1
		var p = start.lerp(finish,i/10.0)
		var ray = PhysicsRayQueryParameters3D.create(p,p-Vector3(0,2.0,0),1)
		if space.intersect_ray(ray).is_empty(): failures.append("Missing floor: "+description+" at "+str(p))

func point(x: float,z: float) -> Vector3:
	return Vector3(x,floor_y+1.3,z)

func run() -> void:
	campus=load("res://Main.tscn").instantiate()
	for n in campus.find_children("*","",true,false):
		# Keep the existing automatic doors and the actual bibliotecaria collider.
		var script=n.get_script()
		if script!=null and script.resource_path not in ["res://scripts/compartidos/puerta_vidrio_salas.gd","res://scripts/pisos/piso_2/boss_bibliotecaria.gd"]:
			n.set_script(null)
	campus.set_script(null)
	root.add_child(campus)
	library=campus.get_node("Piso2/Biblioteca")
	# Retain its real collider but stop animation in this test fixture: its duel
	# controller was deliberately stripped along with the rest of the campaign.
	library.get_node("BossBibliotecaria").set_process(false)
	floor_y=library.global_position.y
	probe=Node3D.new()
	probe.add_to_group("player")
	root.add_child(probe)
	probe.position=Vector3(-53.5,floor_y,-123.5)
	capsule=CapsuleShape3D.new()
	capsule.radius=.45
	capsule.height=1.8
	for i in range(45): await physics_frame
	walk_segment(point(-53.5,-125),point(-53.5,-109),"main entrance")
	var pcs=library.get_node("PuestosComputadores").get_children()
	# Current scene has west-wall stations 01–03 and south-wall stations 10–19.
	# Six removed west stations must not shift orientation checks by array index.
	var expected_stations: Array[String] = ["Puesto01","Puesto02","Puesto03"]
	for number in range(10,20): expected_stations.append("Puesto%d" % number)
	if pcs.size()!=expected_stations.size(): failures.append("Current layout must retain 13 PC stations")
	for station_name in expected_stations:
		if not library.get_node("PuestosComputadores").has_node(NodePath(station_name)):
			failures.append("Missing station: "+station_name)
	for i in range(pcs.size()):
		var pc=pcs[i]
		var direction=(pc.get_node("Monitor").global_position-pc.get_node("Silla").global_position)
		direction.y=0
		var wall=Vector3.LEFT if str(pc.name) in ["Puesto01","Puesto02","Puesto03"] else Vector3.BACK
		if direction.normalized().dot(wall)<.98: failures.append("PC faces away from wall: "+str(pc.name))
		if not pc.has_node("Mouse"): failures.append("PC missing mouse: "+str(pc.name))
	var ceiling=library.get_node("AcabadosReferencia/FondoCieloMadera")
	var ceiling_bottom=ceiling.global_position.y-ceiling.mesh.get_aabb().size.y/2
	for index in range(6):
		var room=library.get_node("SalasEstudio/SalaEstudio"+str(index+1))
		var chairs=0
		for n in room.get_children():
			if str(n.name).begins_with("Silla"): chairs+=1
			if n.name==&"TechoBox" and n.visible: failures.append("False ceiling remains: "+str(room.name))
			if n is MeshInstance3D and (str(n.name).begins_with("Pared") or n.name==&"FrenteVidriado" or n.name==&"Dintel" or (n.mesh is BoxMesh and is_equal_approx(n.mesh.size.x,2.3) and is_equal_approx(n.mesh.size.z,.09))):
				var top=n.global_position.y+n.mesh.get_aabb().size.y/2
				if absf(top-ceiling_bottom)>.02: failures.append("Incomplete closure: "+str(n.get_path()))
		if chairs!=8: failures.append("Study room must retain 8 chairs")
		var door=room.get_node("PuertaVidrio")
		probe.global_position=door.global_position+Vector3(-1,0,0)
		for i in range(45): await physics_frame
		var z=door.global_position.z
		walk_segment(point(-53.5,z),point(-48.1,z),"study room "+str(index+1))
		var high_ray=PhysicsRayQueryParameters3D.create(Vector3(-53,floor_y+9,z+2.5),Vector3(-48,floor_y+9,z+2.5),1)
		if root.world_3d.direct_space_state.intersect_ray(high_ray).is_empty(): failures.append("No upper glass collision: "+str(room.name))
	walk_segment(point(-53.5,-119),point(-53.5,-81.15),"study-room corridor")
	# Capsule probes place the current aisle east of both PC chairs and Estante3.
	walk_segment(point(-78.5,-109.5),point(-78.5,-85),"PC and shelf corridor")
	for x in [-75.5,-71.5,-67.5]:
		walk_segment(point(x,-110),point(x,-104.5),"between shelves "+str(x))
	walk_segment(point(-70.5,-121),point(-70.5,-111),"shelves to reception")
	if library.has_node("PasillosEstanterias"):
		for z in [-101.75,-96.25,-90.75]:
			walk_segment(point(-68.5,z),point(-54.5,z),"horizontal shelf aisle "+str(z))
		walk_segment(point(-68.5,-110),point(-68.5,-81.15),"west shelf circulation")
		walk_segment(point(-54.5,-110),point(-54.5,-81.15),"east shelf circulation")
		walk_segment(point(-61.5,-87),point(-61.5,-81.15),"front passage with shelves on both sides")
		var active_tables=0
		for n in library.get_node("MobiliarioReferenciaFoto").get_children():
			if n.has_node("TableroMadera") and n.is_visible_in_tree(): active_tables+=1
		if active_tables!=3: failures.append("Expected exactly three remaining study tables")
		var shelf_group=library.get_node("PasillosEstanterias")
		if shelf_group.get_child_count()!=6: failures.append("Expected four central and two flanking shelves")
		var books=0
		for shelf in shelf_group.get_children():
			var count=0
			for n in shelf.find_children("*","CSGBox3D",true,false):
				if str(n.name).begins_with("Libros"): count+=1
			if count==0: failures.append("Empty new bookshelf: "+str(shelf.name))
			books+=count
		print("LIBRARY_SHELF_CHECK central=4 flanking=2 active_tables=",active_tables," new_books=",books)
	else:
		walk_segment(point(-66.5,-110),point(-66.5,-81.15),"reading tables corridor")
	walk_segment(point(-82,-81.15),point(-53.5,-81.15),"south computer corridor")
	walk_segment(point(-64.5,-115.5),point(-69.5,-115.5),"staff counter exit")
	var wall=library.get_node("ParedIzquierdaVidrio")
	if wall.material is StandardMaterial3D and wall.material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
		failures.append("Giant wall still transparent")
	for failure in failures: push_error(failure)
	print("LIBRARY_LAYOUT_CHECK PCs=",pcs.size()," rooms=6 routes=",routes," floor_samples=",floor_samples," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
