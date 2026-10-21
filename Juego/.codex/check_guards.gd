extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var player = scene.get_node("GameplayManager").player
	player.set_physics_process(false)
	player.global_position = Vector3(1000,5,1000)
	var guards := get_nodes_in_group("campus_guard")
	var failures: Array = []
	var initial: Array[Vector3] = []
	var maximum: Array[float] = []
	for guard in guards:
		initial.append(guard.global_position)
		maximum.append(0.0)
	for frame in range(1500):
		await physics_frame
		for i in range(guards.size()):
			var p: Vector3 = guards[i].global_position
			maximum[i] = maxf(maximum[i],p.distance_to(initial[i]))
			if not guards[i].desk_mode and (p.x < -7.5 or p.x>13.5 or p.z < -36 or p.z>-24): failures.append("guard left turnstile area")
	for i in range(guards.size()):
		if not guards[i].desk_mode and maximum[i]<3: failures.append("guard patrol blocked "+str(i))
		if guards[i].desk_mode and maximum[i]>0.05: failures.append("registration guard left desk")
		player.global_position = guards[i].global_position+Vector3(0,0,2)
		for frame in range(5): await physics_frame
		if not guards[i].greeting.visible or guards[i].greeting.text != "Buenos días": failures.append("greeting missing "+str(i))
		player.global_position = Vector3(1000,5,1000)
	var pavilion: Vector3 = scene.get_node("EntradaReferenciaDuoc/ExplanadaFrontalReferenciaAerea/PabellonCentral").global_position
	if pavilion.z > -38: failures.append("pavilion still overlaps fence")
	print("GUARD_PATROL_AND_GREETING count=",guards.size()," distance=",maximum," pavilion=",pavilion," failures=",JSON.stringify(failures))
	quit(0 if guards.size()==3 and failures.is_empty() else 1)
