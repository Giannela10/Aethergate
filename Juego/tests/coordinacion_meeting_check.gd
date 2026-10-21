extends SceneTree
var failures: Array[String]=[]
var routes:=0
var samples:=0
var capsule: CapsuleShape3D

func _initialize() -> void:
	call_deferred("run")

func walk(a: Vector3,b: Vector3,title: String) -> void:
	routes+=1
	var space=root.world_3d.direct_space_state
	var query=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	query.transform=Transform3D(Basis.IDENTITY,a)
	query.motion=b-a
	query.collision_mask=1
	var motion=space.cast_motion(query)
	if motion[0]<.999:
		failures.append("Blocked: "+title)
		query.transform.origin=a.lerp(b,minf(motion[1]+.015,1))
		query.motion=Vector3.ZERO
		for hit in space.intersect_shape(query): print("MEETING_BLOCKER ",title," ",hit.collider.get_path())
	for i in range(11):
		samples+=1
		var p=a.lerp(b,i/10.0)
		if space.intersect_ray(PhysicsRayQueryParameters3D.create(p,p-Vector3.UP*2,1)).is_empty(): failures.append("No floor: "+title)

func run() -> void:
	var campus=load("res://Main.tscn").instantiate()
	var retained_door=campus.get_node("Piso1/InteriorCoordinacion/SalaReuniones/PuertaVidrio")
	for n in campus.find_children("*","",true,false):
		if n.get_script()!=null and n!=retained_door:
			n.set_script(null)
	campus.set_script(null)
	root.add_child(campus)
	var office=campus.get_node("Piso1/InteriorCoordinacion")
	var meeting=office.get_node("SalaReuniones")
	var probe=Node3D.new()
	probe.add_to_group("player")
	root.add_child(probe)
	probe.position=Vector3(70.2,.15,-106.2)
	capsule=CapsuleShape3D.new()
	capsule.radius=.45
	capsule.height=1.8
	for i in range(60): await physics_frame
	var paths: Array=[
		[Vector3(71,1.3,-124),Vector3(71,1.3,-111),"reception entrance"],
		[Vector3(71,1.3,-111),Vector3(70.2,1.3,-107),"existing office door"],
		[Vector3(70.2,1.3,-107),Vector3(70.2,1.3,-94.4),"main open-office aisle"],
		[Vector3(36.2,1.3,-101.5),Vector3(70.2,1.3,-101.5),"open office across old glass partitions"],
		[Vector3(36.2,1.3,-110.7),Vector3(36.2,1.3,-94.4),"copier and lounge"],
		[Vector3(38,1.3,-94.4),Vector3(70.2,1.3,-94.4),"back office circulation"],
		[Vector3(80.4,1.3,-119.3),Vector3(80.4,1.3,-112),"behind reception counter"],
		[Vector3(70.2,1.3,-106.2),Vector3(74.5,1.3,-106.2),"meeting-room automatic door"],
		[Vector3(74.5,1.3,-106.2),Vector3(73.4,1.3,-106.2),"inside meeting-room entrance"],
		[Vector3(73.4,1.3,-106.2),Vector3(73.4,1.3,-95.3),"meeting west aisle"],
		[Vector3(73.4,1.3,-95.3),Vector3(81.7,1.3,-95.3),"meeting back aisle"],
		[Vector3(81.7,1.3,-95.3),Vector3(81.7,1.3,-106.2),"meeting east aisle"],
		[Vector3(74.5,1.3,-106.2),Vector3(70.2,1.3,-106.2),"meeting exit"]]
	for path in paths: walk(path[0],path[1],path[2])
	var desks:=0
	for child in office.get_children():
		if child.has_node("TableroMadera"):
			desks+=1
			var p=child.global_position
			if p.x<34.7 or p.x>81.2 or p.z<-107 or p.z>-95:
				failures.append("Desk outside usable office bounds: "+str(child.name))
	if desks!=8: failures.append("Eight existing desks must remain")
	var ceiling=office.get_node("TechoCoordinacion")
	var underside=ceiling.global_position.y-ceiling.mesh.get_aabb().size.y/2
	var corridor=root.world_3d.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(71,1.3,-128),Vector3(71,15,-128),1))
	var report=JSON.parse_string(FileAccess.get_file_as_string("res://reports/coordinacion_meeting_layout.json"))
	if corridor.is_empty(): failures.append("Cannot measure the corridor ceiling")
	elif absf(corridor.position.y-underside)>.01:
		if report.get("ceiling_adjustment_applied",true): failures.append("Coordination ceiling does not match corridor")
		else: print("CEILING_ADJUSTMENT_PENDING current=",underside," corridor=",corridor.position.y," auditorium_structure_preserved=true")
	for n in meeting.get_children():
		if n is MeshInstance3D and str(n.name).begins_with("Vidrio"):
			var upper=n.global_position.y+n.mesh.get_aabb().size.y/2
			if absf(upper-underside)>.01: failures.append("Meeting glass does not reach ceiling: "+str(n.name))
	# Detect the external auditorium constraint explicitly instead of treating the
	# raised ceiling mesh as evidence that the entire physical volume is clear.
	for p in [Vector3(71,2,-115),Vector3(76,2,-104),Vector3(58,2,-105)]:
		var hit=root.world_3d.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p,Vector3(p.x,13,p.z),1))
		if not hit.is_empty() and hit.position.y<underside-.2:
			print("CEILING_EXTERNAL_CONSTRAINT actual_underside=",hit.position.y," intended_underside=",underside," object=",hit.collider.get_path())
	for failure in failures: push_error(failure)
	print("COORD_MEETING_CHECK desks=",desks," routes=",routes," floor_samples=",samples," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
