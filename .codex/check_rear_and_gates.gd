extends SceneTree
var actor: CharacterBody3D
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func walk(points: Array) -> bool:
	actor.global_position = points[0]+Vector3.UP*0.08
	actor.velocity = Vector3.ZERO
	for target in points:
		var reached := false
		var stalled := 0
		for frame in range(2400):
			await physics_frame
			var delta: Vector3 = target-actor.global_position
			delta.y = 0
			if delta.length()<0.15:
				reached = true
				break
			var old := actor.global_position
			var direction := delta.normalized()*minf(2.5,delta.length()*60)
			actor.velocity.x = direction.x
			actor.velocity.z = direction.z
			actor.velocity.y = 0 if actor.is_on_floor() else actor.velocity.y-14.0/60
			actor.move_and_slide()
			stalled = stalled+1 if Vector2(actor.global_position.x-old.x,actor.global_position.z-old.z).length()<0.002 else 0
			if stalled>90: break
		if not reached:
			var blockers: Array = []
			for i in actor.get_slide_collision_count(): blockers.append(str(actor.get_slide_collision(i).get_collider().get_path()))
			failures.append({"position":str(actor.global_position),"target":str(target),"blockers":blockers})
			return false
	return true
func run() -> void:
	var save_path := "user://papeleria_inventario.json"
	var saved_exists := FileAccess.file_exists(save_path)
	var saved_backup := FileAccess.get_file_as_string(save_path) if saved_exists else ""
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	actor = CharacterBody3D.new()
	actor.name = "ProbeWithDifferentName"
	actor.add_to_group("player")
	actor.floor_snap_length = 0.5
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 2.7
	capsule.radius = 0.45
	collider.shape = capsule
	collider.position.y = 1.35
	actor.add_child(collider)
	root.add_child(actor)
	await physics_frame
	await physics_frame
	var manager = scene.get_node("GameplayManager")
	manager.player.remove_from_group("player")
	manager.player.set_physics_process(false)
	manager.player.global_position = Vector3(1000,10,1000)
	var clutter: Array = []
	for child in manager.get_children():
		if child.get_script() and child.get_script().resource_path in ["res://scripts/juego/enemy.gd","res://scripts/juego/computer.gd","res://scripts/juego/weapon.gd"]: clutter.append(str(child.name))
	print("ENTRANCE_CLUTTER ",clutter)
	if not clutter.is_empty(): failures.append("entrance clutter remains")
	var visual_floor = scene.get_node("Floor/MeshInstance3D")
	var physical_floor = scene.get_node("Floor/CollisionShape3D")
	var visible_top: float = visual_floor.global_position.y+visual_floor.mesh.size.y*0.5
	var collision_top: float = physical_floor.global_position.y+physical_floor.shape.size.y*0.5
	if absf(visible_top-collision_top)>0.002: failures.append("ground mesh and collider have different heights")
	print("GROUND_ALIGNMENT visible=",visible_top," collision=",collision_top)
	var gates := 0
	for gate in scene.find_children("Torniquete*","Node3D",true,false):
		if gate.get_script() == null or gate.get_script().resource_path != "res://scripts/exterior/Torniquete.gd": continue
		if absf(gate.global_position.y-0.1)>0.001: failures.append("floating gate "+str(gate.name))
		for reverse in [false,true]:
			var center: Vector3 = gate.global_position+gate.global_basis.x*gate.arm_length*0.5
			var route := [center+gate.global_basis.z*(-4 if reverse else 4),center+gate.global_basis.z*(4 if reverse else -4)]
			if await walk(route): gates+=1
			if not gate.is_open: failures.append("gate failed to open "+str(gate.name))
			if gate.opening_direction != (-1.0 if reverse else 1.0): failures.append("incorrect gate direction "+str(gate.name))
			actor.global_position = Vector3(0,3,0)
			for frame in range(100): await physics_frame
			if gate.is_open: failures.append("gate failed to close "+str(gate.name))
	var rear := 0
	var exterior = scene.get_node("EstructuraYAccesoPosterior/PosteriorReferenciaMarcada")
	var stair_x: float = exterior.get_meta("escalera_x")
	var ramp_x: float = exterior.get_meta("rampa_x")
	var low_x: float = exterior.get_meta("rampa_extremo_bajo_x")
	for points in [[Vector3(low_x-2,-1.0,-165.5),Vector3(ramp_x,0,-165.5),Vector3(ramp_x,0,-160.8),Vector3(ramp_x,0,-155)], [Vector3(stair_x,-1.0,-169),Vector3(stair_x,0,-164),Vector3(stair_x,0,-160.8),Vector3(stair_x,0,-155)]]:
		for reverse in [false,true]:
			var route: Array = points.duplicate()
			if reverse: route.reverse()
			if await walk(route): rear+=1
	var front_routes := 0
	for reverse in [false,true]:
		var route := [Vector3(5.5,0.2,-2),Vector3(5.5,0.2,-72)]
		if reverse: route.reverse()
		if await walk(route): front_routes += 1
	print("FRONT_FORECOURT routes=",front_routes)
	var npc = scene.get_node("Piso2/SalaImpresiones/EncargadoPapeleria")
	var player = manager.player
	player.global_position = npc.global_position+Vector3(0,0,-2.8)
	player._try_interact()
	if not npc.window.visible: failures.append("stationery interaction did not open")
	for key in ["lapiz","hoja_impresa","cuaderno","goma"]:
		var previous_count: int = player.stationery_inventory.get(key,0)
		npc.give_item(key)
		if player.stationery_inventory.get(key,0) != previous_count+1: failures.append("stationery item missing: "+key)
	npc.close_shop()
	if player.busy: failures.append("player still busy after closing stationery menu")
	print("STATIONERY_INVENTORY ",player.stationery_inventory)
	print("REAR_AND_GATE_CHECK gates=",gates," rear_routes=",rear," failures=",JSON.stringify(failures))
	if saved_exists:
		var saved_file := FileAccess.open(save_path,FileAccess.WRITE)
		saved_file.store_string(saved_backup)
	else: DirAccess.remove_absolute(save_path)
	quit(0 if failures.is_empty() and gates == 10 and rear == 4 else 1)
