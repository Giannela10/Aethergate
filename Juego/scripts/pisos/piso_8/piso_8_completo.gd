@tool
extends "res://scripts/pisos/piso_8/pasillo_referencia.gd"
## Distribución completa sobre las losas existentes del piso 8.
## Se construye manualmente y se guarda como escena, nunca en _ready().
const DoorScript = preload("res://scripts/compartidos/puerta_vidrio_salas.gd")
const ROOM_FRONT := -137.8
const ROOM_DEPTH := 23.4
const HALL_CENTER := -130.15
const HALL_WIDTH := 15.3
const CEILING_HEIGHT := 11.16
const WALL_HEIGHT := CEILING_HEIGHT - 0.08
@export_range(6, 8) var numero_piso: int = 8
var mesh_cache: Dictionary = {}
var shape_cache: Dictionary = {}
var element_id := 0
var dark_floor: ShaderMaterial
var rooms: Array[Dictionary] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# La misma escena se instancia en 6, 7 y 8; solo cambia la numeración.
	var floor_rooms: Array = get_meta("salas", []).duplicate(true)
	for room in floor_rooms:
		var suffix: int = int(room.numero) % 100
		var room_node := get_node("Sala%d" % (800 + suffix))
		var number := numero_piso * 100 + suffix
		room.numero = number
		room_node.set_meta("numero_sala", number)
		room_node.get_node("NumeroSala").text = str(number)
		room_node.get_node("TextoPizarra").text = "Duoc UC\nSala %d" % number
	set_meta("salas", floor_rooms)
	set_meta("numero_piso", numero_piso)
	get_node("ZonaEncuentroDuoc/OrientacionAscensores").text = "ASCENSORES ↑     PISO %d     SALAS ← →" % numero_piso

func owned(node: Node, parent: Node) -> void:
	element_id += 1
	if parent.has_node(NodePath(str(node.name))):
		node.name = str(node.name) + "_%04d" % element_id
	parent.add_child(node)
	node.owner = self

func group(title: String, position_value: Vector3 = Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	node.name = title
	node.position = position_value
	owned(node, self)
	return node

func box(title: String, center: Vector3, size_value: Vector3, surface: Material, solid: bool = false, parent: Node = self) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = title
	mesh_node.position = center
	if not mesh_cache.has(size_value):
		var mesh := BoxMesh.new()
		mesh.size = size_value
		mesh_cache[size_value] = mesh
	mesh_node.mesh = mesh_cache[size_value]
	mesh_node.material_override = surface
	owned(mesh_node, parent)
	if solid:
		var body := StaticBody3D.new()
		body.name = "Cuerpo"
		owned(body, mesh_node)
		var collision := CollisionShape3D.new()
		collision.name = "Colision"
		if not shape_cache.has(size_value):
			var shape := BoxShape3D.new()
			shape.size = size_value
			shape_cache[size_value] = shape
		collision.shape = shape_cache[size_value]
		owned(collision, body)
	return mesh_node

func label_on(parent: Node3D, title: String, content: String, center: Vector3, angle: float = 0.0, color: Color = Color.WHITE, pixel: float = 0.003) -> void:
	var label := Label3D.new()
	label.name = title
	label.text = content
	label.position = center
	label.rotation.y = angle
	label.font_size = 48
	label.pixel_size = pixel
	label.modulate = color
	label.outline_size = 0
	owned(label, parent)

func init_materials() -> void:
	material("beige", Color(0.66, 0.58, 0.47), 0.72)
	var cladding := ShaderMaterial.new()
	cladding.shader = load("res://scripts/pisos/piso_8/paneles_beige.gdshader")
	materials.beige = cladding
	material("joint", Color(0.28, 0.25, 0.21), 0.8)
	material("black", Color(0.025, 0.028, 0.033), 0.4, 0.35)
	material("steel", Color(0.53, 0.56, 0.57), 0.25, 0.75)
	material("red", Color(0.72, 0.025, 0.018), 0.35)
	material("white", Color(0.84, 0.83, 0.77), 0.6)
	material("purple", Color(0.31, 0.055, 0.58), 0.9)
	material("green", Color(0.06, 0.38, 0.12), 0.85)
	material("yellow", Color(0.86, 0.68, 0.03))
	material("blue", Color(0.035, 0.11, 0.33))
	material("ceiling", Color(0.30, 0.29, 0.27), 0.95)
	material("wood", Color(0.55, 0.39, 0.22), 0.75)
	material("room_floor", Color(0.42, 0.41, 0.37), 0.85)
	material("tile", Color(0.77, 0.79, 0.75), 0.4)
	material("ceramic", Color(0.92, 0.92, 0.87), 0.2)
	material("carpet", Color(0.28, 0.42, 0.10), 0.95)
	material("partition", Color(0.18, 0.24, 0.27), 0.8)
	var glass := material("glass", Color(0.12, 0.18, 0.22, 0.22), 0.20, 0.08)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var frosted := material("frosted", Color(0.60, 0.65, 0.63, 0.72), 0.75)
	frosted.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frosted.cull_mode = BaseMaterial3D.CULL_DISABLED
	var lamp := material("lamp", Color(1, 0.94, 0.83), 0.4)
	lamp.emission_enabled = true
	lamp.emission = Color(1, 0.93, 0.80)
	lamp.emission_energy_multiplier = 2.0
	dark_floor = ShaderMaterial.new()
	dark_floor.shader = load("res://scripts/pisos/piso_8/baldosas_oscuras.gdshader")

func build() -> Dictionary:
	for child in get_children():
		child.free()
	element_id = 0
	rooms.clear()
	init_materials()
	position = Vector3(0, 60.407787, 0)
	rotation = Vector3.ZERO
	# Un único pasillo exterior ocupa también el espacio del paralelo eliminado.
	# Todas las salas se sitúan detrás del mismo frente interior.
	classroom(807, -50, 16, ROOM_FRONT, ROOM_DEPTH, false, true)
	classroom(808, -34, 16, ROOM_FRONT, ROOM_DEPTH, false, true)
	classroom(805, 39.25, 12.5, ROOM_FRONT, ROOM_DEPTH, false, true)
	classroom(806, 51.75, 12.5, ROOM_FRONT, ROOM_DEPTH, false, true)
	# Salas adicionales en los espacios junto al núcleo; terminan antes de los huecos.
	classroom(809, 26.5, 13, ROOM_FRONT, 10.6, false, true)
	classroom(810, -23, 6, ROOM_FRONT, 8.2, false, true)
	bathroom("BanosMujeres", -64, "BAÑOS · MUJERES")
	bathroom("BanosHombres", 64, "BAÑOS · HOMBRES")
	build_central_lounge()
	build_south_corridor()
	build_south_nook(-77)
	build_south_nook(77)
	build_corridor_entrance()
	fit_to_building_roof()
	complete_corridor_finishes()
	set_meta("referencias", ["WhatsApp Image 2026-10-13 at 09.16.56.jpeg", "WhatsApp Image 2026-10-13 at 09.16.47.jpeg"])
	set_meta("salas", rooms)
	set_meta("banos", [Vector3(-64, 0, ROOM_FRONT), Vector3(64, 0, ROOM_FRONT)])
	set_meta("ancho_pasillo", HALL_WIDTH)
	set_meta("altura_techo", CEILING_HEIGHT)
	return {"salas": rooms.size(), "banos": 2, "elementos": element_id, "referencias": 2}

func build_corridor_entrance() -> void:
	var entrance := group("InicioPasilloJuntoEscalera")
	entrance.set_meta("inicio", Vector3(19, 0, -134.8))
	entrance.set_meta("recorrido_recto", "X=19 a 84, sin giro ni paredes intermedias; integrado al pasillo exterior")

func complete_corridor_finishes() -> void:
	var finish := group("AcabadosPasilloCompleto")
	# Los descansos que enlazan vestíbulo, escalera y entrada reciben el mismo acabado.
	# Se respeta el borde Z=-132.953 del atrio y los huecos de escalera en Z<-148.6.
	var landing_rects: Array[Rect2] = [
		Rect2(-17.2, -148.5, 35.5, 15.547),
		Rect2(18.3, -148.5, 1.7, 10.7),
		Rect2(-20, -148.5, 2.8, 10.7),
	]
	for rect in landing_rects:
		var center := rect.get_center()
		box("SueloDescansoTerminado", Vector3(center.x, -0.02, center.y), Vector3(rect.size.x, 0.04, rect.size.y), dark_floor, true, finish)
		box("CieloDescansoTerminado", Vector3(center.x, CEILING_HEIGHT, center.y), Vector3(rect.size.x, 0.16, rect.size.y), materials.ceiling, false, finish)
		linear_light(finish, Vector3(center.x, CEILING_HEIGHT - 0.41, center.y), 3.8)
		var landing_light := finish.get_children().back() as OmniLight3D
		landing_light.omni_range = CEILING_HEIGHT + 4
		landing_light.light_energy = 1.5
	for side in [-1, 1]:
		box("RemateExtremoPasillo", Vector3(side * 84.0, WALL_HEIGHT * 0.5, HALL_CENTER), Vector3(0.15, WALL_HEIGHT, HALL_WIDTH), materials.beige, true, finish)
		box("ZocaloExtremo", Vector3(side * 83.9, 0.08, HALL_CENTER), Vector3(0.035, 0.16, HALL_WIDTH), materials.black, false, finish)
	# Zócalos de los paños de entrada y remates superiores en toda la altura.
	for wall in find_children("*", "MeshInstance3D", true, false):
		if wall.material_override != materials.beige or not wall.mesh is BoxMesh:
			continue
		var size_value: Vector3 = wall.mesh.size
		if size_value.y < 3.6:
			continue
		var edge_size := Vector3(size_value.x, 0.16, size_value.z)
		if size_value.x < size_value.z:
			edge_size.x += 0.03
		else:
			edge_size.z += 0.03
		box("ZocaloPanelBeige", Vector3(0, 0.08 - wall.position.y, 0), edge_size, materials.black, false, wall)
		box("RemateSuperiorPanel", Vector3(0, WALL_HEIGHT - 0.05 - wall.position.y, 0), Vector3(size_value.x, 0.10, size_value.z), materials.black, false, wall)
	# Travesaños de fachada: el vidrio y sus perfiles completan todo el recorrido.
	for side in [-1, 1]:
		for i in range(11):
			var x: float = side * (21.0 + i * 6.0)
			for height_value in [3.2, 6.4, 9.6, WALL_HEIGHT - 0.05]:
				box("TravesanoVentanalCompleto", Vector3(x, height_value, -122.66), Vector3(5.95, 0.065, 0.10), materials.black, false, finish)

func linear_light(parent: Node3D, center: Vector3, length_value: float = 3.4, angle: float = 0.0) -> void:
	var lamp := box("LuminariaLineal", center, Vector3(0.12, 0.055, length_value), materials.lamp, false, parent)
	lamp.rotation.y = angle
	var light := OmniLight3D.new()
	light.name = "LuzInterior"
	light.position = center + Vector3.DOWN * 0.25
	light.light_color = Color(1.0, 0.93, 0.83)
	light.light_energy = 1.0
	light.omni_range = 8.5
	owned(light, parent)

func build_corridor() -> void:
	var hall := group("PasillosAmbasAlas")
	# Un solo suelo físico evita enganches en las juntas de las losas CSG antiguas.
	var floor_collision := box("SueloContinuoPasillo", Vector3(0, -0.02, -136.8), Vector3(168, 0.04, 4.8), dark_floor, true, hall)
	floor_collision.visible = false
	# Paños cortos comparten malla y reciben las luces próximas en Compatibility.
	for i in range(28):
		var x := -81.0 + i * 6.0
		box("Baldosas", Vector3(x, -0.015, -136.8), Vector3(6, 0.03, 4.8), dark_floor, false, hall)
		box("CieloHormigon", Vector3(x, 4.06, -136.8), Vector3(6, 0.16, 4.95), materials.ceiling, false, hall)
		box("BandejaInstalaciones", Vector3(x, 3.83, -137.6), Vector3(5.9, 0.14, 0.56), materials.black, false, hall)
		box("ConductoVentilacion", Vector3(x, 3.80, -135.5), Vector3(5.9, 0.26, 0.62), materials.ceiling, false, hall)
		for k in range(6):
			box("TravesanoCielo", Vector3(x - 2.5 + k, 3.92, -136.8), Vector3(0.075, 0.1, 4.6), materials.steel, false, hall)
		linear_light(hall, Vector3(x, 3.65, -136.8), 3.4, PI / 2)
	# Zona central acristalada hacia el atrio; se conservan las barandas existentes.
	for x in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		box("VidrioAtrio", Vector3(x, 1.98, -134.35), Vector3(5.95, 3.96, 0.05), materials.glass, true, hall)
		box("PerfilAtrio", Vector3(x + 3, 1.98, -134.30), Vector3(0.08, 3.96, 0.10), materials.black, false, hall)
		box("ZocaloAtrio", Vector3(x, 0.06, -134.28), Vector3(6, 0.12, 0.1), materials.black, false, hall)
	for x in [-74.0, 74.0]:
		box("SalidaEmergencia", Vector3(x, 3.35, -136.8), Vector3(0.06, 0.34, 0.85), materials.green, false, hall)
		label_on(hall, "TextoSalida", "SALIDA →", Vector3(x + 0.04, 3.35, -136.8), PI / 2, Color.WHITE, 0.0018)

func fire_cabinet(parent: Node3D) -> void:
	cylinder("TuberiaRoja", Vector3(-2.04, 1.9, 0), 0.045, 3.8, materials.red, parent)
	box("FondoGabinete", Vector3(-1.96, 1.82, 0), Vector3(0.16, 0.96, 0.72), materials.red, true, parent)
	for z in [-0.38, 0.38]:
		box("LateralGabinete", Vector3(-1.76, 1.82, z), Vector3(0.48, 0.96, 0.055), materials.red, false, parent)
	for y in [1.31, 2.33]:
		box("BordeGabinete", Vector3(-1.76, y, 0), Vector3(0.48, 0.055, 0.8), materials.red, false, parent)
	var hose := MeshInstance3D.new()
	hose.name = "MangueraEnrollada"
	hose.position = Vector3(-1.62, 1.89, 0)
	hose.rotation.z = PI / 2
	var torus := TorusMesh.new()
	torus.inner_radius = 0.13
	torus.outer_radius = 0.28
	hose.mesh = torus
	hose.material_override = materials.white
	owned(hose, parent)
	box("SenalRedHumeda", Vector3(-2.15, 2.92, 0), Vector3(0.03, 0.46, 0.3), materials.red, false, parent)
	label_on(parent, "TextoIncendio", "RED\nHÚMEDA", Vector3(-2.128, 2.92, 0), PI / 2, Color.WHITE, 0.0012)

func door(parent: Node3D, center: Vector3, title: String, angle: float = 0.0, glass_door: bool = true) -> void:
	var entry := Node3D.new()
	entry.name = title
	entry.position = center
	entry.rotation.y = angle
	entry.set_script(DoorScript)
	entry.set("ancho", 2.0)
	owned(entry, parent)
	for side in [-1, 1]:
		var leaf := AnimatableBody3D.new()
		leaf.name = "HojaIzquierda" if side < 0 else "HojaDerecha"
		leaf.position = Vector3(side * 0.5, 1.38, 0)
		owned(leaf, entry)
		box("PanelPuerta", Vector3.ZERO, Vector3(0.98, 2.76, 0.055), materials.glass if glass_door else materials.partition, false, leaf)
		if glass_door:
			box("EsmeriladoPuerta", Vector3(0, -0.3, 0.038), Vector3(0.96, 1.1, 0.01), materials.frosted, false, leaf)
		box("Manilla", Vector3(-side * 0.37, -0.12, 0.10), Vector3(0.035, 0.40, 0.04), materials.steel, false, leaf)
		box("PerfilHoja", Vector3(-side * 0.48, 0, 0.035), Vector3(0.035, 2.76, 0.07), materials.black, false, leaf)
		var collision := CollisionShape3D.new()
		collision.name = "ColisionPuerta"
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.98, 2.76, 0.08)
		collision.shape = shape
		owned(collision, leaf)
	box("DintelPuerta", Vector3(0, 2.82, 0), Vector3(2.15, 0.09, 0.10), materials.black, false, entry)
	var upper_height := WALL_HEIGHT - 2.865
	box("RellenoSobrePuerta", Vector3(0, 2.865 + upper_height * 0.5, 0), Vector3(2.2, upper_height, 0.06), materials.glass if glass_door else materials.beige, true, entry)

func fit_to_building_roof() -> void:
	# Se modifica cada instancia, manteniendo recursos compartidos por tamaño.
	# Las hojas de las puertas y el mobiliario conservan sus dimensiones normales.
	for node in find_children("*", "MeshInstance3D", true, false):
		if not node.mesh is BoxMesh:
			continue
		var size_value: Vector3 = node.mesh.size
		if size_value.y >= 3.6 and size_value.y <= 4.01 and node.position.y < 2.3:
			size_value.y = WALL_HEIGHT
			node.position.y = WALL_HEIGHT * 0.5
			if not mesh_cache.has(size_value):
				var mesh := BoxMesh.new()
				mesh.size = size_value
				mesh_cache[size_value] = mesh
			node.mesh = mesh_cache[size_value]
			for collision in node.find_children("*", "CollisionShape3D", true, false):
				if not shape_cache.has(size_value):
					var shape := BoxShape3D.new()
					shape.size = size_value
					shape_cache[size_value] = shape
				collision.shape = shape_cache[size_value]
		elif str(node.name).begins_with("Cielo"):
			node.position.y = CEILING_HEIGHT
		elif node.position.y >= 3.4 and node.position.y <= 3.95 and size_value.y < 0.3:
			node.position.y += CEILING_HEIGHT - 4.06
	for light in find_children("*", "OmniLight3D", true, false):
		light.position.y = CEILING_HEIGHT - 0.65
		light.omni_range = CEILING_HEIGHT + 4.0
		light.light_energy = 1.5

func classroom(number: int, x: float, width: float, entry_z: float, depth: float, front: bool, south: bool = false) -> void:
	var room := group("Sala%d" % number, Vector3(x, 0, entry_z))
	if front:
		room.rotation.y = PI
	room.set_meta("numero_sala", number)
	room.set_meta("lado", "sur" if south else "norte")
	var center := Vector3(0, 0, -depth * 0.5)
	box("SueloSala", center + Vector3(0, -0.015, 0), Vector3(width - 0.2, 0.03, depth), materials.room_floor, false, room)
	box("CieloSala", center + Vector3(0, 4.02, 0), Vector3(width, 0.14, depth), materials.white, false, room)
	for side in [-1, 1]:
		box("TabiqueLateral", center + Vector3(side * width * 0.5, 1.98, 0), Vector3(0.15, 3.96, depth), materials.beige, true, room)
	box("MuroFondo", Vector3(0, 1.98, -depth), Vector3(width, 3.96, 0.15), materials.beige, true, room)
	# Dos mamparas a ambos lados del acceso real, nunca una colisión sobre la puerta.
	var panel_width := (width - 2.2) * 0.5
	var front_glass_width := minf(6.2, width - 1.2)
	for side in [-1, 1]:
		var panel_x: float = side * (1.10 + panel_width * 0.5)
		if south:
			var opaque_width: float = (width - front_glass_width) * 0.5
			var opaque_x: float = side * (front_glass_width * 0.5 + opaque_width * 0.5)
			var side_glass_width := (front_glass_width - 2.2) * 0.5
			var side_glass_x: float = side * (1.1 + side_glass_width * 0.5)
			box("RevestimientoBeige", Vector3(opaque_x, 1.98, 0), Vector3(opaque_width, 3.96, 0.15), materials.beige, true, room)
			box("MamparaJuntoPuerta", Vector3(side_glass_x, 1.98, 0), Vector3(side_glass_width, 3.96, 0.06), materials.glass, true, room)
			box("EsmeriladoJuntoPuerta", Vector3(side_glass_x, 1.1, 0.042), Vector3(side_glass_width, 1.15, 0.01), materials.frosted, false, room)
			for k in range(1, 10):
				box("JuntaHorizontalPanel", Vector3(opaque_x, k * 0.39, 0.081), Vector3(opaque_width, 0.008, 0.008), materials.joint, false, room)
			for k in range(1, 4) if opaque_width > 2.5 else range(2, 3):
				box("JuntaVerticalPanel", Vector3(opaque_x + (k - 2) * 1.25, 1.98, 0.081), Vector3(0.008, 3.96, 0.008), materials.joint, false, room)
		else:
			box("MamparaSala", Vector3(panel_x, 1.98, 0), Vector3(panel_width, 3.96, 0.06), materials.glass, true, room)
			box("FranjaEsmerilada", Vector3(panel_x, 1.1, 0.042), Vector3(panel_width, 1.15, 0.01), materials.frosted, false, room)
		box("PilarBeige", Vector3(side * (width * 0.5 - 0.34), 1.98, 0.04), Vector3(0.65, 3.96, 0.24), materials.beige, true, room)
		box("Zocalo", Vector3(panel_x, 0.06, 0.05), Vector3(panel_width, 0.12, 0.08), materials.black, false, room)
		for k in range(1, 10):
			box("JuntaRevestimiento", Vector3(side * (width * 0.5 - 0.34), k * 0.39, 0.17), Vector3(0.65, 0.008, 0.01), materials.joint, false, room)
		for k in range(1, 4):
			box("PerfilMampara", Vector3(side * (1.1 + panel_width * k / 4.0), 1.98, 0.035), Vector3(0.05, 3.96, 0.08), materials.black, false, room)
	door(room, Vector3.ZERO, "PuertaSala")
	box("PlacaSala", Vector3(1.45, 2.55, 0.08), Vector3(0.68, 0.38, 0.035), materials.white, false, room)
	box("FranjaDuoc", Vector3(1.14, 2.55, 0.105), Vector3(0.10, 0.38, 0.01), materials.blue, false, room)
	label_on(room, "NumeroSala", str(number), Vector3(1.48, 2.55, 0.106), 0, Color(0.06, 0.06, 0.06), 0.0025)
	box("Pizarra", Vector3(0, 1.95, -depth + 0.10), Vector3(5.0, 1.6, 0.08), materials.ceramic, false, room)
	box("MarcoPizarra", Vector3(0, 1.09, -depth + 0.15), Vector3(5.1, 0.05, 0.10), materials.steel, false, room)
	label_on(room, "TextoPizarra", "Duoc UC\nSala %d" % number, Vector3(0, 1.95, -depth + 0.155), 0, Color(0.08, 0.12, 0.16), 0.004)
	box("PantallaProyeccion", Vector3(width * 0.5 - 2.0, 2.45, -depth + 0.12), Vector3(2.3, 1.3, 0.08), materials.black, false, room)
	box("ImagenProyector", Vector3(width * 0.5 - 2.0, 2.45, -depth + 0.17), Vector3(2.15, 1.15, 0.015), materials.blue, false, room)
	desk(room, Vector3(0, 0, -depth + 2.1), true)
	chair(room, Vector3(0, 0, -depth + 1.25), PI)
	var rows_count := mini(6, maxi(1, int((depth - 5.0) / 2.0)))
	var columns_count := mini(5, maxi(2, int((width - 2.0) / 1.8)))
	for row in range(rows_count):
		for column in range(columns_count):
			var px := (column - (columns_count - 1) * 0.5) * 1.8
			var pz := (-3.2 if depth < 8 else -3.4) - row * 2.0
			desk(room, Vector3(px, 0, pz))
			chair(room, Vector3(px, 0, pz + 0.78), 0)
	for px in [-width * 0.25, width * 0.25]:
		for pz in [-depth * 0.25, -depth * 0.70]:
			linear_light(room, Vector3(px, 3.65, pz), 2.8)
	box("ArmarioMateriales", Vector3(width * 0.5 - 0.7, 1.0, -depth + 1.0), Vector3(1.0, 2.0, 0.55), materials.wood, true, room)
	rooms.append({"numero": number, "entrada": Vector3(x, 0, entry_z), "ancho": width, "profundidad": depth, "frontal": front, "lado": "sur" if south else "norte"})

func build_south_corridor() -> void:
	var south := group("LadoSurSalasYVentanales")
	south.set_meta("disposicion", "Pasillo único amplio y recto desde la escalera: 15.3 m entre salas en Z=-137.8 y vidrio exterior en Z=-122.58")
	box("FrenteSuperiorSobreCielo", Vector3(0, 11.4, -122.5), Vector3(169, 0.64, 0.16), materials.beige, false, south)
	box("VentanalCentralSinLosa", Vector3(0, 1.98, -122.58), Vector3(36, 3.96, 0.06), materials.glass, true, south)
	for side in [-1, 1]:
		var center_x: float = side * 51.0
		var floor_collision := box("SueloContinuoSur", Vector3(center_x, -0.02, HALL_CENTER), Vector3(66, 0.04, HALL_WIDTH), dark_floor, true, south)
		floor_collision.visible = false
		for i in range(11):
			var x: float = side * (21.0 + i * 6.0)
			box("BaldosasSur", Vector3(x, -0.015, HALL_CENTER), Vector3(6, 0.03, HALL_WIDTH), dark_floor, false, south)
			box("CieloHormigonSur", Vector3(x, 4.06, HALL_CENTER), Vector3(6, 0.16, HALL_WIDTH), materials.ceiling, false, south)
			box("VentanalSur", Vector3(x, 1.98, -122.58), Vector3(5.95, 3.96, 0.06), materials.glass, true, south)
			box("ZocaloNegroVentanal", Vector3(x, 0.06, -122.65), Vector3(6, 0.12, 0.12), materials.black, false, south)
			for k in range(4):
				box("MontanteNegroVentanal", Vector3(x - 3 + k * 1.5, 1.98, -122.66), Vector3(0.065, 3.96, 0.1), materials.black, false, south)
			if i % 2 == 0:
				box("PilarBeigeSur", Vector3(x - 3, 1.98, -122.83), Vector3(0.44, 3.96, 0.44), materials.beige, true, south)
			box("ConductoCieloSur", Vector3(x, 3.80, -124.3), Vector3(5.95, 0.25, 0.6), materials.ceiling, false, south)
			box("BandejaCablesSur", Vector3(x, 3.82, ROOM_FRONT + 1.3), Vector3(5.95, 0.14, 0.52), materials.black, false, south)
			for k in range(6):
				box("TravesanoSur", Vector3(x - 2.5 + k, 3.92, HALL_CENTER), Vector3(0.07, 0.1, HALL_WIDTH - 0.2), materials.steel, false, south)
			for light_z in [ROOM_FRONT + 3.0, HALL_CENTER, -125.8]:
				linear_light(south, Vector3(x, 3.65, light_z), 3.8, PI / 2)
		# Enlace a la circulación transversal por el borde del atrio existente.
		box("SueloConexionSur", Vector3(side * 19.0, -0.015, -131.0), Vector3(1.7, 0.03, 11.6), dark_floor, false, south)
		linear_light(south, Vector3(side * 19.0, 3.65, -131.0), 3.5)
	for x in [-67.0, -43.0, -23.0, 23.0, 46.0, 68.0]:
		var furniture := group("MesaJuntoVentanalSur", Vector3(x, 0, -125.35))
		furniture.rotation.y = -PI / 2
		box("MesaAltaBlanca", Vector3(2.28, 1.08, 0), Vector3(0.75, 0.055, 1.1), materials.white, true, furniture)
		box("SoporteMesa", Vector3(2.58, 0.53, 0), Vector3(0.07, 1.03, 0.7), materials.steel, false, furniture)
		chair(furniture, Vector3(1.98, 0, 0.85), 0)
	for x in [-55.0, 35.0]:
		var fixtures := group("RedHumedaSur", Vector3(x, 0, ROOM_FRONT + 2.17))
		fixtures.rotation.y = -PI / 2
		fire_cabinet(fixtures)
		for i in range(2):
			cylinder("BasureroSur", Vector3(-1.92, 0.45, -1.7 - i * 0.5), 0.2, 0.9, materials.steel, fixtures)
			cylinder("TapaReciclajeSur", Vector3(-1.92, 0.91, -1.7 - i * 0.5), 0.205, 0.065, materials.yellow if i == 0 else materials.green, fixtures)
	for x in [-25.1, 25.1]:
		var chair_group := group("SillonMoradoSur", Vector3(x, 0, -123.5))
		box("BaseSillon", Vector3(0, 0.35, 0), Vector3(1.05, 0.3, 0.96), materials.purple, true, chair_group)
		box("Cojin", Vector3(0, 0.55, 0), Vector3(0.80, 0.16, 0.76), materials.purple, false, chair_group)
		box("Respaldo", Vector3(0, 0.87, 0.4), Vector3(1.05, 0.85, 0.18), materials.purple, true, chair_group)
		for px in [-0.44, 0.44]:
			box("Apoyabrazos", Vector3(px, 0.65, 0), Vector3(0.16, 0.38, 0.9), materials.purple, true, chair_group)
			for z in [-0.35, 0.35]:
				cylinder("PataSillon", Vector3(px, 0.12, z), 0.035, 0.24, materials.steel, chair_group)

func build_south_nook(x: float) -> void:
	var nook := group("SalaEstudioExtremoSur", Vector3(x, 0, ROOM_FRONT))
	box("SueloEstudio", Vector3(0, -0.015, -3.1), Vector3(12.0, 0.03, 6.2), materials.room_floor, false, nook)
	box("CieloEstudio", Vector3(0, 4.02, -3.1), Vector3(12.0, 0.14, 6.2), materials.white, false, nook)
	for side in [-1, 1]:
		box("MamparaEstudio", Vector3(side * 3.55, 1.98, 0), Vector3(4.9, 3.96, 0.06), materials.glass, true, nook)
		box("EsmeriladoEstudio", Vector3(side * 3.55, 1.1, 0.042), Vector3(4.9, 1.15, 0.01), materials.frosted, false, nook)
		box("MuroLateral", Vector3(side * 6, 1.98, -3.1), Vector3(0.15, 3.96, 6.2), materials.beige, true, nook)
	box("MuroFondoEstudio", Vector3(0, 1.98, -6.2), Vector3(12, 3.96, 0.15), materials.beige, true, nook)
	door(nook, Vector3.ZERO, "PuertaEstudio")
	for px in [-2.5, 2.5]:
		desk(nook, Vector3(px, 0, -3), true)
		chair(nook, Vector3(px, 0, -2.2), 0)
	linear_light(nook, Vector3(0, 3.65, -3), 3.5)

func desk(parent: Node3D, center: Vector3, teacher: bool = false) -> void:
	var width := 1.5 if teacher else 1.05
	box("MesaDocente" if teacher else "MesaAlumno", center + Vector3(0, 0.76, 0), Vector3(width, 0.055, 0.62), materials.wood if teacher else materials.white, true, parent)
	for x in [-width * 0.40, width * 0.40]:
		for z in [-0.24, 0.24]:
			box("PataMesa", center + Vector3(x, 0.37, z), Vector3(0.045, 0.74, 0.045), materials.black, false, parent)
	if teacher:
		box("NotebookDocente", center + Vector3(0.25, 0.81, 0), Vector3(0.34, 0.03, 0.25), materials.black, false, parent)
		box("PantallaNotebook", center + Vector3(0.25, 0.95, -0.12), Vector3(0.34, 0.26, 0.025), materials.black, false, parent)

func chair(parent: Node3D, center: Vector3, angle: float) -> void:
	var node := Node3D.new()
	node.name = "Silla"
	node.position = center
	node.rotation.y = angle
	owned(node, parent)
	box("Asiento", Vector3(0, 0.47, 0), Vector3(0.46, 0.055, 0.46), materials.white, true, node)
	box("Respaldo", Vector3(0, 0.72, 0.21), Vector3(0.46, 0.46, 0.05), materials.white, false, node)
	for x in [-0.18, 0.18]:
		for z in [-0.18, 0.18]:
			box("PataSilla", Vector3(x, 0.23, z), Vector3(0.035, 0.46, 0.035), materials.steel, false, node)

func bathroom(title: String, x: float, signage: String) -> void:
	var bath := group(title, Vector3(x, 0, ROOM_FRONT))
	box("SueloBano", Vector3(0, -0.015, -ROOM_DEPTH * 0.5), Vector3(11.8, 0.03, ROOM_DEPTH), materials.tile, false, bath)
	box("CieloBano", Vector3(0, 3.7, -ROOM_DEPTH * 0.5), Vector3(12, 0.12, ROOM_DEPTH), materials.white, false, bath)
	for side in [-1, 1]:
		box("MuroBano", Vector3(side * 6, 1.8, -ROOM_DEPTH * 0.5), Vector3(0.15, 3.6, ROOM_DEPTH), materials.tile, true, bath)
		box("FrenteBano", Vector3(side * 3.55, 1.8, 0), Vector3(4.9, 3.6, 0.15), materials.beige, true, bath)
	box("FondoBano", Vector3(0, 1.8, -ROOM_DEPTH), Vector3(12, 3.6, 0.15), materials.tile, true, bath)
	door(bath, Vector3.ZERO, "PuertaBano", 0, false)
	box("CartelBano", Vector3(0, 3.16, 0.10), Vector3(3.0, 0.48, 0.05), materials.blue, false, bath)
	label_on(bath, "TextoBano", signage, Vector3(0, 3.16, 0.135), 0, Color.WHITE, 0.0023)
	# Entrada y pasillo central de 3 m: todos los sanitarios son accesibles.
	for i in range(4):
		var z := -7.0 - i * 3.3
		stall(bath, Vector3(-3.55, 0, z), i == 0)
		washbasin(bath, Vector3(4.9, 0, z))
	for z in [-4.0, -10.0, -16.0]:
		linear_light(bath, Vector3(0, 3.43, z), 2.8)
	box("DispensadorJabon", Vector3(5.52, 1.22, -6.0), Vector3(0.17, 0.25, 0.19), materials.white, false, bath)
	box("SecadorManos", Vector3(5.52, 1.3, -4.0), Vector3(0.28, 0.43, 0.45), materials.steel, false, bath)
	box("Papelera", Vector3(4.8, 0.45, -3.3), Vector3(0.45, 0.9, 0.45), materials.steel, true, bath)
	label_on(bath, "SenalAccesible", "CABINA ACCESIBLE", Vector3(-2.10, 2.15, -5.35), 0, Color(0.06, 0.12, 0.2), 0.002)
	if title == "BanosHombres":
		for z in [-18.5, -20.0]:
			box("Urinario", Vector3(5.3, 0.85, z), Vector3(0.40, 0.65, 0.46), materials.ceramic, true, bath)
			box("SeparadorUrinario", Vector3(5.1, 1.15, z - 0.60), Vector3(0.65, 1.45, 0.08), materials.partition, false, bath)

func stall(parent: Node3D, center: Vector3, accessible: bool) -> void:
	var width := 3.7
	var depth := 3.15
	for side in [-1, 1]:
		box("SeparadorCabina", center + Vector3(0, 1.35, side * depth * 0.5), Vector3(width, 2.7, 0.07), materials.partition, true, parent)
	# Acceso lateral abierto de 1,3 m con privacidad tras la hoja lateral.
	box("FrenteCabina", center + Vector3(width * 0.5, 1.35, -1.02), Vector3(0.08, 2.7, 1.08), materials.partition, true, parent)
	box("HojaAbiertaCabina", center + Vector3(1.22, 1.35, 0.48), Vector3(1.2, 2.7, 0.07), materials.partition, true, parent)
	cylinder("BaseInodoro", center + Vector3(-0.7, 0.24, 0), 0.22, 0.48, materials.ceramic, parent)
	box("TazaInodoro", center + Vector3(-0.60, 0.43, 0), Vector3(0.64, 0.13, 0.45), materials.ceramic, true, parent)
	box("InteriorTaza", center + Vector3(-0.52, 0.50, 0), Vector3(0.32, 0.01, 0.26), materials.partition, false, parent)
	box("EstanqueInodoro", center + Vector3(-0.92, 0.68, 0), Vector3(0.23, 0.55, 0.47), materials.ceramic, false, parent)
	cylinder("RolloPapel", center + Vector3(-1.4, 0.75, 0.8), 0.09, 0.15, materials.white, parent)
	if accessible:
		box("BarraApoyo", center + Vector3(-0.5, 0.90, -0.55), Vector3(0.9, 0.04, 0.04), materials.steel, false, parent)
		box("BarraApoyoLateral", center + Vector3(-1.10, 0.90, 0), Vector3(0.04, 0.04, 1.15), materials.steel, false, parent)

func washbasin(parent: Node3D, center: Vector3) -> void:
	box("MesonLavamanos", center + Vector3(0, 0.85, 0), Vector3(1.0, 0.09, 1.5), materials.ceramic, true, parent)
	box("Cubeta", center + Vector3(-0.12, 0.901, 0), Vector3(0.56, 0.016, 0.55), materials.tile, false, parent)
	cylinder("Grifo", center + Vector3(0.28, 1.02, 0), 0.025, 0.24, materials.steel, parent)
	box("SalidaGrifo", center + Vector3(0.16, 1.13, 0), Vector3(0.25, 0.04, 0.04), materials.steel, false, parent)
	box("Espejo", center + Vector3(0.60, 1.72, 0), Vector3(0.02, 1.1, 1.35), materials.steel, false, parent)

func build_central_lounge() -> void:
	var lounge := group("ZonaEncuentroDuoc", Vector3(0, 0, -142.0))
	box("BaldosasVestibulo", Vector3(0, -0.015, 0), Vector3(38, 0.03, 10), dark_floor, false, lounge)
	box("CieloVestibulo", Vector3(0, 4.06, 0), Vector3(38, 0.16, 10), materials.ceiling, false, lounge)
	# Se conserva el eje de paso desde el pasillo hasta los tres ascensores.
	for x in [-13.0, 13.0]:
		box("AlfombraVerde", Vector3(x, 0.015, 0), Vector3(6.5, 0.018, 6.0), materials.carpet, false, lounge)
		for z in [-1.4, 1.4]:
			desk(lounge, Vector3(x, 0, z), true)
			chair(lounge, Vector3(x - 0.45, 0, z + 0.8), 0)
			chair(lounge, Vector3(x + 0.45, 0, z - 0.8), PI)
		for i in range(8):
			box("CelosiaVertical", Vector3(x + 3.5, 2, -2.7 + i * 0.65), Vector3(0.08, 4, 0.08), materials.wood, false, lounge)
		box("PanelInstitucional", Vector3(x, 1.9, -4.3), Vector3(5.8, 3.4, 0.08), materials.blue, false, lounge)
		label_on(lounge, "MarcaDuoc", "Duoc UC\nESPACIO DE ENCUENTRO", Vector3(x, 2.1, -4.245), 0, Color.WHITE, 0.006)
	for x in [-12.0, 0.0, 12.0]:
		linear_light(lounge, Vector3(x, 3.65, 0), 4.0)
	label_on(lounge, "OrientacionAscensores", "ASCENSORES ↑     PISO 8     SALAS ← →", Vector3(0, 3.1, -4.0), 0, Color(0.1, 0.16, 0.21), 0.003)

func build_end_lounge(x: float) -> void:
	var lounge := group("ZonaEstudioYMaquinas", Vector3(x, 0, -128.9))
	box("BaldosasZonaEstudio", Vector3(0, -0.015, -2.0), Vector3(11.5, 0.03, 10.8), dark_floor, false, lounge)
	box("CieloZonaEstudio", Vector3(0, 4.06, -2.0), Vector3(11.5, 0.16, 10.8), materials.ceiling, false, lounge)
	for z in [-4.8, 0.0]:
		linear_light(lounge, Vector3(0, 3.65, z), 3.4)
	for px in [-2.6, 2.6]:
		vending_machine(lounge, Vector3(px, 0, 3.3), px < 0)
	box("AlfombraEncuentro", Vector3(0, 0.015, -1.0), Vector3(6.8, 0.018, 4.2), materials.carpet, false, lounge)
	for px in [-1.5, 1.5]:
		desk(lounge, Vector3(px, 0, -1.0), true)
		chair(lounge, Vector3(px, 0, 0), 0)
		chair(lounge, Vector3(px, 0, -2), PI)
	var armchair := Node3D.new()
	armchair.name = "SillonMorado"
	armchair.position = Vector3(4.4, 0, -2.8)
	owned(armchair, lounge)
	box("Base", Vector3(0, 0.35, 0), Vector3(0.96, 0.3, 0.92), materials.purple, true, armchair)
	box("Cojin", Vector3(0, 0.55, 0), Vector3(0.72, 0.16, 0.75), materials.purple, false, armchair)
	box("Respaldo", Vector3(0, 0.86, 0.4), Vector3(0.96, 0.84, 0.18), materials.purple, true, armchair)
	for px in [-0.40, 0.40]:
		box("Apoyabrazos", Vector3(px, 0.65, 0), Vector3(0.16, 0.38, 0.9), materials.purple, true, armchair)
	label_on(lounge, "TextoZonaEstudio", "ZONA DE ESTUDIO · PISO 8", Vector3(0, 2.9, 4.45), PI, Color(0.1, 0.12, 0.16), 0.004)

func vending_machine(parent: Node3D, center: Vector3, drinks: bool) -> void:
	box("MaquinaBebidas" if drinks else "MaquinaSnacks", center + Vector3(0, 1.08, 0), Vector3(1.1, 2.16, 0.8), materials.blue if drinks else materials.black, true, parent)
	box("VentanaMaquina", center + Vector3(-0.1, 1.17, -0.415), Vector3(0.64, 1.30, 0.025), materials.glass, false, parent)
	box("FondoProductos", center + Vector3(-0.1, 1.17, -0.425), Vector3(0.64, 1.30, 0.01), materials.black, false, parent)
	for row in range(4):
		for column in range(3):
			var p := center + Vector3(-0.31 + column * 0.22, 0.76 + row * 0.27, -0.45)
			box("Producto", p, Vector3(0.13, 0.18, 0.045), materials.red if (row + column) % 2 == 0 else materials.yellow, false, parent)
		box("BandejaProductos", center + Vector3(-0.1, 0.43, -0.46), Vector3(0.60, 0.19, 0.03), materials.black, false, parent)
	box("PanelPago", center + Vector3(0.37, 1.34, -0.44), Vector3(0.19, 0.46, 0.03), materials.steel, false, parent)
	box("PantallaPago", center + Vector3(0.37, 1.45, -0.46), Vector3(0.13, 0.10, 0.015), materials.lamp, false, parent)
	label_on(parent, "RotuloMaquina", "BEBIDAS" if drinks else "SNACKS", center + Vector3(0, 1.94, -0.45), PI, Color.WHITE, 0.0024)
