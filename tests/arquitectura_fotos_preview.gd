extends "res://tests/costados_preview.gd"
var checks:Dictionary={}
func check_shop5() -> Dictionary:
	var shop:Node3D=campus.get_node("Piso5/TiendaEsquinaPiso5")
	var space:PhysicsDirectSpaceState3D=get_world_3d().direct_space_state
	var result:Dictionary={"failures":[],"checks":0,"front_world":str(shop.global_basis.z.normalized()),"position":str(shop.global_position)}
	for x in [-3.5,-1.5,0.5,2.5]:
		var ray:=PhysicsRayQueryParameters3D.create(shop.to_global(Vector3(x,1.5,1.8)),shop.to_global(Vector3(x,1.5,1.0)))
		var hit:Dictionary=space.intersect_ray(ray)
		result.checks+=1
		if not hit.is_empty(): result.failures.append("front_blocked_"+str(x)+": "+str(hit.collider.get_path()))
	for x in [-4.2,-3.5,-1.5,0.5,2.5,3.7]:
		var ray:=PhysicsRayQueryParameters3D.create(shop.to_global(Vector3(x,0.5,2)),shop.to_global(Vector3(x,-1,2)))
		result.checks+=1
		if space.intersect_ray(ray).is_empty(): result.failures.append("floor_missing_"+str(x))
	for x in [-1.5,0.5]:
		var ray:=PhysicsRayQueryParameters3D.create(shop.to_global(Vector3(x,1,1)),shop.to_global(Vector3(x,1,-1.5)))
		var hit:Dictionary=space.intersect_ray(ray)
		result.checks+=1
		if hit.is_empty() or not str(hit.collider.get_path()).contains("TiendaEsquinaPiso5/MostradorFrontal"): result.failures.append("counter_collision_"+str(x))
	# Espacio transitable entre el negocio y la escalera, con cÃ¡psula de tamaÃ±o humano.
	for x in [-32.0,-28.0,-24.0,-20.0]:
		var shape:=CapsuleShape3D.new()
		shape.radius=0.40; shape.height=2.4
		var q:=PhysicsShapeQueryParameters3D.new()
		q.shape=shape; q.transform=Transform3D(Basis.IDENTITY,Vector3(x,49.25,-142.2)); q.collision_mask=1
		q.exclude=[campaign.player.get_rid()]
		var hit:Array[Dictionary]=space.intersect_shape(q)
		result.checks+=1
		if not hit.is_empty(): result.failures.append("corridor_blocked_"+str(x)+": "+str(hit[0].collider.get_path()))
	result.passed=result.failures.is_empty()
	var f:=FileAccess.open("res://reports/tienda_piso5_acceso_foto.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	return result

func probe_library() -> void:
	var quiz:Node=campus.get_node("Piso2/Biblioteca/BossBibliotecaria/BossDuelController")
	var p:CharacterBody3D=campaign.player
	p.global_position=quiz.actor.global_position+Vector3(0,0,2)
	quiz.actor.set("player",p)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var q:=PhysicsRayQueryParameters3D.create(p.global_position+Vector3.UP*1.6,quiz.actor.global_position+Vector3.UP*1.6)
	q.exclude=[p.get_rid()]
	var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
	var result:Dictionary={"busy_before":p.busy,"dead":p.dead,"state_before":quiz.state,"can_interact":quiz.actor.call("_can_interact"),"hit":str(hit.get("collider")),"hit_path":str(hit.collider.get_path()) if hit.has("collider") else ""}
	quiz.interact(p)
	result.state_dialogue=quiz.state
	quiz.intro_duration=0.1
	quiz.accept()
	await get_tree().create_timer(2.0,true,false,true).timeout
	result.state_after=quiz.state; result.active=quiz.actor.active; result.busy_after=p.busy; result.paused=get_tree().paused
	var f:=FileAccess.open("res://reports/fotos_library_probe.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	print("LIBRARY_PROBE ",JSON.stringify(result))

var regressions:Dictionary={}
var tests_finished:=false
func show_photo(view:String) -> void:
	var camera:Camera3D=campaign.manager.cam
	match view:
		"tienda5":
			camera.global_position=Vector3(-21,51.2,-138.2)
			camera.look_at(Vector3(-25.2,50.8,-147.4))
		"cafe":
			camera.global_position=Vector3(57,28,-110)
			camera.look_at(Vector3(39,28,-110))
		"sala":
			camera.global_position=Vector3(27,27,-130)
			camera.look_at(Vector3(28,26.4,-121))
		"interior":
			camera.global_position=Vector3(28,27,-120)
			camera.look_at(Vector3(28,27,-104))
		"entrada":
			camera.global_position=Vector3(0,9,-21)
			camera.look_at(Vector3(8,9,-73))
		"estatua":
			camera.global_position=Vector3(57,4,-50)
			camera.look_at(Vector3(62,2.6,-60))
		"escalera":
			camera.global_position=Vector3(-30,28,-127.8)
			camera.look_at(Vector3(-12,29,-127.8))
		"superior":
			camera.global_position=Vector3(37,63,-128)
			camera.look_at(Vector3(37,63,-138))
func ground_probe() -> Array:
	var result:Array=[]
	for xz in [Vector2(62,-60),Vector2(62,-53),Vector2(8,-50)]:
		var q:=PhysicsRayQueryParameters3D.create(Vector3(xz.x,8,xz.y),Vector3(xz.x,-8,xz.y),1)
		var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
		result.append({"position":str(hit.get("position")),"collider":str(hit.get("collider"))})
	return result
func test_doors() -> void:
	checks={"doors":[],"campaign_ready":campaign.ready_for_play,"floors":{}}
	var player:Node3D=campaign.player
	var old_pos:Vector3=player.global_position
	for door in campus.find_children("*","Node3D",true,false):
		if door.has_meta("photo_floor"):
			var fi:String=str(campus.get_path_to(door)).get_slice("/",0)
			checks.floors[fi]=int(checks.floors.get(fi,0))+1
		if not door.has_meta("photo_hinged"): continue
		var leaf:AnimatableBody3D=door.get_node("HojaIzquierda")
		var original_lock:bool=bool(door.get_meta("campaign_locked",false))
		var original_rotation:Vector3=leaf.rotation
		door.set_physics_process(false)
		player.global_position=door.global_position+Vector3(0,1.3,1.0)
		door.set_meta("campaign_locked",true)
		door.call("_physics_process",1.0)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var closed:bool=absf(leaf.rotation.y)<0.01
		var shape:=CapsuleShape3D.new()
		shape.radius=0.32; shape.height=2.0
		var q:=PhysicsShapeQueryParameters3D.new()
		q.shape=shape; q.transform=Transform3D(Basis.IDENTITY,door.global_position+Vector3(0,1.4,0))
		q.collision_mask=1
		q.exclude=[campaign.player.get_rid()]
		var closed_hit:=false
		for hit in get_world_3d().direct_space_state.intersect_shape(q):
			if hit.collider==leaf: closed_hit=true
		door.set_meta("campaign_locked",false)
		door.call("_physics_process",1.0)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var open_hit:=false
		for hit in get_world_3d().direct_space_state.intersect_shape(q):
			if hit.collider==leaf: open_hit=true
		checks.doors.append({"path":str(campus.get_path_to(door)),"locks_closed":closed,"closed_collision":closed_hit,"opens":leaf.rotation.y>1.5,"open_clear":not open_hit})
		leaf.rotation=original_rotation
		door.set_meta("campaign_locked",original_lock)
		door.set_physics_process(true)
	player.global_position=old_pos
	checks.ground=ground_probe()
	checks.all_doors_pass=true
	for d in checks.doors:
		if not(d.locks_closed and d.closed_collision and d.opens and d.open_clear): checks.all_doors_pass=false
	var f:=FileAccess.open("res://reports/arquitectura_validacion.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(checks,"  "))
	print("PHOTOS_DOORS ",checks.doors.size()," pass=",checks.all_doors_pass)
	tests_finished=true
func run_regressions() -> void:
	for suite in ["campaign_regression","inventory_regression","organizacion_pisos","performance_startup"]:
		var relative:String="res://reports/fotos_"+suite+".log"
		var pid:int=OS.create_process(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/"+suite+".gd","--log-file",ProjectSettings.globalize_path(relative)],false)
		var start:int=Time.get_ticks_msec()
		while pid>0 and OS.is_process_running(pid) and Time.get_ticks_msec()-start<180000:
			await get_tree().create_timer(0.5,true,false,true).timeout
		var timeout:bool=pid>0 and OS.is_process_running(pid)
		if timeout: OS.kill(pid)
		var log_text:String=FileAccess.get_file_as_string(relative)
		regressions[suite]={"timeout":timeout,"script_errors":log_text.contains("SCRIPT ERROR"),"tail":log_text.right(2000)}
		print("PHOTOS_REGRESSION ",suite," ",JSON.stringify(regressions[suite]))
		var f:=FileAccess.open("res://reports/arquitectura_regresiones.json",FileAccess.WRITE)
		f.store_string(JSON.stringify(regressions,"  "))


func check_emergency_shop() -> void:
	var result:Dictionary=check_shop5()
	var door:Node3D=campus.get_node("Piso5/EscaleraEmergencia/PuertaPiso5")
	var player:CharacterBody3D=campaign.player
	var old:Vector3=player.global_position
	player.global_position=door.global_position+Vector3(0,0,1.2)
	door.call("_physics_process",1.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	result.checks+=1
	if not door.opened: result.failures.append("emergency_door_does_not_open")
	for z in [-144.5,-146.5,-148.6,-150.0]:
		var shape:=CapsuleShape3D.new()
		shape.radius=0.40; shape.height=2.4
		var q:=PhysicsShapeQueryParameters3D.new()
		q.shape=shape; q.transform=Transform3D(Basis.IDENTITY,Vector3(-20.7,49.25,z))
		q.collision_mask=1; q.exclude=[player.get_rid()]
		var hits:Array[Dictionary]=get_world_3d().direct_space_state.intersect_shape(q)
		result.checks+=1
		if not hits.is_empty(): result.failures.append("emergency_route_blocked_"+str(z)+": "+str(hits[0].collider.get_path()))
	var shop:Node3D=campus.get_node("Piso5/TiendaEsquinaPiso5")
	result.checks+=1
	if shop.global_position.distance_to(Vector3(-28.751,47.975,-144.517))>0.1: result.failures.append("wrong_emergency_location")
	result.passed=result.failures.is_empty()
	for segment in [
		[Vector3(-28,56,-142),Vector3(-28,56,-145)],
		[Vector3(-32.5,50,-148.5),Vector3(-32.5,50,-150.4)],
		[Vector3(-24,55,-146),Vector3(-22.8,55,-146)],
		[Vector3(-33,50,-146),Vector3(-35,50,-146)]
	]:
		var ray:=PhysicsRayQueryParameters3D.create(segment[0],segment[1])
		result.checks+=1
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): result.failures.append("wall_not_closed_"+str(segment[0]))
	result.passed=result.failures.is_empty()
	result.emergency_door_path=str(campus.get_path_to(door))
	var f:=FileAccess.open("res://reports/tienda_piso5_emergencia_pruebas.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	player.global_position=old
	print("EMERGENCY_SHOP ",JSON.stringify(result))

func show_basement(view: String) -> void:
	var camera: Camera3D = campaign.manager.cam
	var position_value: Vector3
	var target: Vector3
	match view:
		"elevators_center":
			position_value = Vector3(0.0, BASEMENT_Y + 4.8, -148.0)
			target = Vector3(0.0, BASEMENT_Y + 1.5, -112.0)
		"elevators_left":
			position_value = Vector3(0.0, BASEMENT_Y + 4.8, -148.0)
			target = Vector3(34.0, BASEMENT_Y + 2.0, -128.0)
		"automotive":
			position_value = Vector3(20.0, BASEMENT_Y + 5.4, -145.0)
			target = Vector3(52.0, BASEMENT_Y + 2.5, -127.0)
		"pingpong_lockers":
			position_value = Vector3(0.0, BASEMENT_Y + 6.5, -116.0)
			target = Vector3(0.0, BASEMENT_Y + 1.5, -82.0)
		"business":
			position_value = Vector3(-20.0, BASEMENT_Y + 5.0, -142.0)
			target = Vector3(-31.0, BASEMENT_Y + 2.2, -128.0)
		"corridor":
			position_value = Vector3(-48.0, BASEMENT_Y + 5.0, -125.0)
			target = Vector3(-67.0, BASEMENT_Y + 2.0, -98.0)
		"welding":
			position_value = Vector3(58.0, BASEMENT_Y + 5.0, -136.0)
			target = Vector3(72.0, BASEMENT_Y + 2.0, -149.0)
		"machinery":
			position_value = Vector3(21.0, BASEMENT_Y + 4.8, -118.0)
			target = Vector3(54.0, BASEMENT_Y + 2.5, -118.0)
		"ramp_base":
			position_value = Vector3(32.0, BASEMENT_Y + 4.5, -109.0)
			target = Vector3(24.37, BASEMENT_Y + 5.0, -151.0)
		"ramp_middle":
			position_value = Vector3(31.0, -1.0, -139.0)
			target = Vector3(24.37, -6.0, -139.0)
		"ramp_exit":
			position_value = Vector3(24.37, 5.0, -169.0)
			target = Vector3(24.37, -6.0, -144.0)
		_:
			position_value = Vector3(0.0, BASEMENT_Y + 4.8, -148.0)
			target = Vector3(0.0, BASEMENT_Y + 1.5, -112.0)
	camera.global_position = position_value
	camera.look_at(target)
	campaign.player.busy = true
	campaign.player.visible = false
	campaign.player.global_position = Vector3(300.0, 100.0, 300.0)

func check_basement_route() -> Dictionary:
	var points: Array[Vector3] = [
		Vector3(0, BASEMENT_Y + 1.5, -147),
		Vector3(0, BASEMENT_Y + 1.5, -121),
		Vector3(45, BASEMENT_Y + 1.5, -124),
		Vector3(-7, BASEMENT_Y + 1.5, -103),
		Vector3(0, BASEMENT_Y + 1.5, -84),
		Vector3(-31, BASEMENT_Y + 1.5, -126),
		Vector3(-49, BASEMENT_Y + 1.5, -115),
		Vector3(-49, BASEMENT_Y + 1.5, -91),
		Vector3(58, BASEMENT_Y + 1.5, -152),
		Vector3(24.37, BASEMENT_Y + 1.5, -116),
		Vector3(24.37, -4.0, -139.5),
		Vector3(24.37, 1.5, -162.94)
	]
	var names: Array[String] = ["ascensor", "centro", "mecanica", "ping_pong", "lockers", "negocio", "pasillo", "salas", "soldadura", "base_rampa_interior", "mitad_rampa", "vano_rampa_exterior"]
	var report: Dictionary = {"route": [], "failures": []}
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for i in points.size():
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.38
		capsule.height = 2.2
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY, points[i])
		query.collision_mask = 1
		query.exclude = [campaign.player.get_rid()]
		var hits: Array[Dictionary] = space.intersect_shape(query)
		var paths: Array[String] = []
		for hit in hits:
			paths.append(str(hit.collider.get_path()))
		var item: Dictionary = {"name": names[i], "position": points[i], "clear": paths.is_empty(), "hits": paths}
		report.route.append(item)
		if not paths.is_empty():
			report.failures.append(item)
	report.passed = report.failures.is_empty()
	var f := FileAccess.open("res://reports/piso_menos1_ruta_visual.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	print("BASEMENT_ROUTE ", JSON.stringify(report))
	return report

func audit_basement_gameplay() -> Dictionary:
	var lifts: Node3D = campus.get_node("SistemasCompartidos/AscensoresEstudiantiles")
	var final_area: Node3D = campaign.final_area as Node3D
	var basement: Node3D = campus.get_node("PisoMenos1")
	var ambient: Node3D = basement.get_node("AmbientacionIndustrial2026")
	return {
		"campaign_ready": campaign.ready_for_play,
		"persistence_disabled_for_preview": not campaign.persist,
		"elevators": lifts.get_child_count(),
		"central_stair_preserved": basement.has_node("EscaleraCentralMenos1"),
		"emergency_stair_preserved": basement.has_node("EscaleraEmergencia"),
		"elevator_lobby_preserved": basement.has_node("VestibuloAscensores"),
		"nexo_exists": final_area != null,
		"nexo_position": str(final_area.global_position) if final_area != null else "",
		"nexo_placement_valid": bool(final_area.get("placement_valid")) if final_area != null else false,
		"nexo_terminals": final_area.terminals.size() if final_area != null else 0,
		"nexo_boss": final_area.actor != null and final_area.actor.name == "NEXO" if final_area != null else false,
		"visual_groups": ambient.get_child_count(),
		"multimesh_instances": ambient.find_children("*", "MultiMeshInstance3D", true, false).size(),
		"fps_sample": Engine.get_frames_per_second()
	}

const BASEMENT_Y: float = -12.058385849
