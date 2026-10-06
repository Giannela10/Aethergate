extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	var volume := AABB(Vector3(32.5,8.3,-121.8),Vector3(10,8,41))
	for n in scene.find_children("*","MeshInstance3D",true,false):
		if str(n.get_path()).contains("AuditorioPiso2e"): continue
		var bounds: AABB = n.global_transform*n.get_aabb()
		if bounds.intersects(volume): print(str(scene.get_path_to(n))," ",bounds)
	for n in scene.find_children("*","CSGBox3D",true,false):
		if str(n.get_path()).contains("AuditorioPiso2e"): continue
		var bounds: AABB = n.global_transform*AABB(-n.size*0.5,n.size)
		if bounds.intersects(volume): print(str(scene.get_path_to(n))," ",bounds)
	quit()
