extends SceneTree
## Comprueba recorridos reales, puertas automáticas y suelo del piso completo.
var failures: Array[String] = []
var tested := 0
var floor_number := 8
var probe: CharacterBody3D
var campus: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func walk(points: Array[Vector3], title: String) -> void:
	probe.global_position = points[0] + Vector3.UP * 0.20
	probe.velocity = Vector3.ZERO
	for i in range(12):
		await physics_frame
		probe.velocity.y -= 14.0 / 60.0
		probe.move_and_slide()
	for target in points.slice(1):
		var reached := false
		for frame in range(3000):
			await physics_frame
			var offset: Vector3 = target - probe.global_position
			offset.y = 0
			if offset.length() < 0.18:
				reached = true
				break
			var step: Vector3 = offset.normalized() * minf(6.0, offset.length() * 60.0)
			probe.velocity.x = step.x
			probe.velocity.z = step.z
			probe.velocity.y = 0 if probe.is_on_floor() else probe.velocity.y - 14.0 / 60.0
			probe.move_and_slide()
			if probe.global_position.y < points[0].y - 2.0:
				break
		var blockers: Array[String] = []
		if not reached:
			for i in probe.get_slide_collision_count():
				blockers.append(str(probe.get_slide_collision(i).get_collider().get_path()))
		check(reached, "%s bloqueado hacia %s desde %s: %s" % [title, target, probe.global_position, blockers])
		if not reached:
			break
	tested += 1

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--floor="):
			floor_number = argument.trim_prefix("--floor=").to_int()
	if floor_number not in [6, 7, 8]:
		push_error("Seleccionar --floor=6, --floor=7 o --floor=8")
		quit(1)
		return
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
	campus = load("res://Main.tscn").instantiate()
	campus.get_node("GameplayManager").free()
	root.add_child(campus)
	probe = CharacterBody3D.new()
	probe.set_script(load("res://tests/access_probe.gd"))
	probe.name = "PruebaPiso8"
	probe.floor_snap_length = 0.5
	probe.add_to_group("player")
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.7
	collision.shape = capsule
	collision.position.y = 1.35
	probe.add_child(collision)
	campus.add_child(probe)
	var floor_design := campus.get_node("Piso%d/PasilloReferencia" % floor_number)
	var floor_y: float = floor_design.global_position.y
	var original_floor := campus.get_node("Piso%d" % floor_number)
	check(absf(floor_y - original_floor.altura - 0.026448669) < 0.002, "La distribución debe quedar sobre la losa del piso %d" % floor_number)
	check(floor_design.get_meta("salas").size() == 6, "Deben existir seis salas ocupando el espacio detrás del pasillo amplio")
	check(not floor_design.has_node("PasillosAmbasAlas"), "No debe existir el pasillo interior paralelo")
	check(not floor_design.has_node("CierreInicioPasilloEste") and not floor_design.has_node("CierreInicioPasilloOeste"), "No debe haber una pared bloqueando el punto de inicio")
	check(floor_design.has_node("InicioPasilloJuntoEscalera"), "El pasillo debe comenzar junto a la escalera")
	check(floor_design.has_node("AcabadosPasilloCompleto"), "Los acabados deben completar todo el recorrido")
	check(floor_design.get_node("AcabadosPasilloCompleto").find_children("TravesanoVentanalCompleto*", "MeshInstance3D", true, false).size() == 88, "Los perfiles de fachada deben cubrir las dos alas completas")
	check(is_equal_approx(floor_design.get_meta("ancho_pasillo"), 15.3), "El pasillo amplio debe medir 15,3 m")
	check(not floor_design.get_node("InicioPasilloJuntoEscalera").has_node("ParedLateralGiro"), "No debe quedar el tramo corto en L bloqueando el pasillo largo")
	check(floor_design.get_meta("altura_techo") > 11, "El cielo debe alcanzar la altura de la cubierta")
	var ceiling := floor_design.get_node("LadoSurSalasYVentanales/CieloHormigonSur")
	var wall := floor_design.get_node("Sala805/RevestimientoBeige")
	check(absf(ceiling.position.y - (wall.position.y + wall.mesh.size.y * 0.5) - 0.08) < 0.01, "La pared debe rellenar hasta el cielo, sin huecos superiores")
	check(floor_design.has_node("BanosMujeres") and floor_design.has_node("BanosHombres"), "Faltan los baños")
	await walk([Vector3(-40, floor_y, -135.9), Vector3(-40, floor_y, -124.6)], "Paso transversal del ala oeste")
	await walk([Vector3(40, floor_y, -135.9), Vector3(40, floor_y, -124.6)], "Paso transversal del ala este")
	for room in floor_design.get_meta("salas"):
		check(int(room.numero / 100) == floor_number, "La numeración de las salas debe corresponder al piso %d" % floor_number)
		if room.lado == "sur":
			check(room.entrada.z < -125.35, "El lado exterior de vidrio debe quedar sin salas")
		var entry: Vector3 = room.entrada
		var direction: float = 1.0 if room.frontal else -1.0
		var x: float = entry.x
		var inner_z: float = entry.z + direction * 1.6
		var far_z: float = entry.z + direction * (room.profundidad - 3.0)
		var hall_z: float = -134.8
		var aisle_x: float = x + minf(4.7, room.ancho * 0.5 - 0.95)
		await walk([Vector3(x, floor_y, hall_z), Vector3(x, floor_y, inner_z), Vector3(aisle_x, floor_y, inner_z), Vector3(aisle_x, floor_y, far_z), Vector3(aisle_x, floor_y, inner_z), Vector3(x, floor_y, inner_z), Vector3(x, floor_y, hall_z)], "Entrada, interior y salida sala %d" % room.numero)
	for x in [-64.0, 64.0]:
		await walk([Vector3(x, floor_y, -134.8), Vector3(x, floor_y, -140.8), Vector3(x, floor_y, -159), Vector3(x, floor_y, -144.8), Vector3(x - 3.25, floor_y, -144.8), Vector3(x, floor_y, -144.8), Vector3(x, floor_y, -134.8)], "Baño y cabina accesible %s" % x)
	for side in [-1.0, 1.0]:
		probe.global_position = Vector3(side * 19, floor_y, -134.8)
		for frame in range(2):
			await physics_frame
		check(not probe.test_move(probe.global_transform, Vector3(side * 3, 0, 0)), "El inicio debe estar abierto y permitir avanzar desde el punto indicado")
		for lane_z in [-124.6, -130.15, -134.8, -135.9]:
			await walk([Vector3(side * 20, floor_y, lane_z), Vector3(side * 81, floor_y, lane_z), Vector3(side * 20, floor_y, lane_z)], "Pasillo exterior, ala %s, ancho en %s" % [side, lane_z])
		if side > 0:
			await walk([Vector3(19, floor_y, -125.35), Vector3(26.5, floor_y, -125.35), Vector3(26.5, floor_y, -134.8), Vector3(19, floor_y, -134.8), Vector3(19, floor_y, -136.8)], "Conexión exterior a escalera por el inicio abierto")
		else:
			await walk([Vector3(-19, floor_y, -125.35), Vector3(-21, floor_y, -125.35), Vector3(-21, floor_y, -136.8), Vector3(-19, floor_y, -136.8)], "Conexión oeste a ascensores")
		await walk([Vector3(side * 77, floor_y, -134.8), Vector3(side * 77, floor_y, -139.4)], "Estudio extremo sur %s" % side)
	await walk([Vector3(0, floor_y, -136.8), Vector3(0, floor_y, -147.0)], "Acceso central a ascensores")
	await walk([Vector3(19, floor_y, -134.8), Vector3(26.5, floor_y, -134.8), Vector3(26.5, floor_y, -125.5), Vector3(40, floor_y, -125.5)], "Inicio del pasillo desde el punto del personaje y conexión al exterior")
	await walk([Vector3(19, floor_y, -134.8), Vector3(26.5, floor_y, -134.8), Vector3(26.5, floor_y, -125.5), Vector3(81, floor_y, -125.5), Vector3(26.5, floor_y, -125.5), Vector3(26.5, floor_y, -134.8), Vector3(19, floor_y, -134.8)], "Recorrido completo de principio a fin y regreso")
	await walk([Vector3(19, floor_y, -134.8), Vector3(81, floor_y, -134.8), Vector3(19, floor_y, -134.8)], "Pasillo recto completo desde la escalera, sin giro")
	await walk([Vector3(-20.7, floor_y, -149.8), Vector3(-20.7, floor_y, -146.8), Vector3(-19, floor_y, -146.8), Vector3(-19, floor_y, -134.8)], "Salida de emergencia del piso 8 hacia el pasillo")
	print("PISO8_ROUTES_RESULT ", JSON.stringify({"floor": floor_number, "tested": tested, "failures": failures}))
	campus.free()
	quit(0 if failures.is_empty() else 1)
