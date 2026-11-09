extends Node3D
var results: Array = []
var probe: CharacterBody3D
var route := 0
var elapsed := 0.0
var settled := 0.0
var floors_checked := false
func check_repaired_floors() -> void:
	var failures: Array = []
	var patches: Array[Node] = []
	for floor_node in get_node("Campus").get_children():
		if floor_node.is_in_group("pisos"):
			patches.append_array(floor_node.find_children("Piso*_Cierre*", "MeshInstance3D", true, false))
	var tested := 0
	for patch in patches:
		# Los parches retirados para huecos y pasillos no son superficies transitables.
		if not patch.is_visible_in_tree():
			continue
		tested += 1
		var start: Vector3 = patch.global_position + Vector3(0,1.5,0)
		var query := PhysicsRayQueryParameters3D.create(start,start-Vector3(0,3,0))
		query.exclude = [probe.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or absf(hit.position.y-(patch.global_position.y+0.15))>(0.15 if str(patch.name).begins_with("Piso1_") else 0.05):
			failures.append({"patch":str(patch.name),"expected":patch.global_position.y+0.15,"hit":str(hit)})
	print("FLOOR_REPAIR_RESULT "+JSON.stringify({"tested":tested,"failures":failures}))
func _ready() -> void:
	var manager := get_node_or_null("Campus/GameplayManager")
	if manager:
		manager.process_mode = Node.PROCESS_MODE_DISABLED
		manager.queue_free()
	for p in get_tree().get_nodes_in_group("player"):
		p.remove_from_group("player")
	probe = CharacterBody3D.new()
	probe.set_script(load("res://tests/access_probe.gd"))
	probe.name = "Probe"
	probe.floor_snap_length = 0.5
	probe.add_to_group("player")
	add_child(probe)
	var c := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	c.shape = capsule
	c.position.y = 0.9
	probe.add_child(c)
	start_route()
func start_route() -> void:
	elapsed = 0
	settled = 0
	probe.position = Vector3(-53.5,12.15,-125) if route == 6 else Vector3(-53.5,12.15,-118.76+route*7.68)
	probe.velocity = Vector3.ZERO
func _physics_process(delta: float) -> void:
	if route >= 7: return
	elapsed += delta
	settled += delta
	if not floors_checked and settled > 0.4:
		floors_checked = true
		check_repaired_floors()
	probe.velocity = Vector3.ZERO
	if settled > 0.7:
		if route < 6: probe.velocity.x = 2.8
		else: probe.velocity.z = 2.8
	if not probe.is_on_floor(): probe.velocity.y = -5
	probe.move_and_slide()
	var reached := probe.position.z > -115.5 if route == 6 else probe.position.x > -48.1
	if reached or elapsed > 10:
		var passed := reached
		var blockers: Array = []
		for i in probe.get_slide_collision_count():
			blockers.append(str(probe.get_slide_collision(i).get_collider().get_path()))
		results.append({"box":route+1,"passed":passed,"position":str(probe.position),"blockers":blockers if not passed else []})
		route += 1
		if route < 7: start_route()
		else: print("LIBRARY_ACCESS_RESULT "+JSON.stringify(results))
