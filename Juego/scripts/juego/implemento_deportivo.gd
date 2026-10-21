extends "res://scripts/juego/weapon.gd"
## Implementos compatibles con recoger, equipar, golpear y soltar del jugador.
const SPORTS := {
	"bate": {"name": "Bate de béisbol", "damage": 30.0, "reach": 2.2, "durability": 12, "swing_time": 0.65},
	"raqueta": {"name": "Raqueta de tenis", "damage": 24.0, "reach": 2.1, "durability": 10, "swing_time": 0.55},
	"pelota": {"name": "Pelota de básquetbol", "damage": 18.0, "reach": 1.8, "durability": 16, "swing_time": 0.5},
	"baseball": {"name": "Pelota de béisbol", "damage": 20.0, "reach": 1.7, "durability": 16, "swing_time": 0.45},
	"tenis": {"name": "Pelota de tenis", "damage": 14.0, "reach": 1.7, "durability": 16, "swing_time": 0.4},
	"futbol": {"name": "Pelota de fútbol", "damage": 20.0, "reach": 1.8, "durability": 16, "swing_time": 0.5},
	"rugby": {"name": "Pelota de rugby", "damage": 22.0, "reach": 1.8, "durability": 14, "swing_time": 0.55},
	"disco": {"name": "Disco volador", "damage": 18.0, "reach": 1.8, "durability": 14, "swing_time": 0.45}
}
const THROWABLE := ["pelota", "baseball", "tenis", "futbol", "rugby", "disco"]
@export_enum("bate", "raqueta", "pelota", "baseball", "tenis", "futbol", "rugby", "disco") var sport := "bate"

func _ready() -> void:
	var stats: Dictionary = SPORTS.get(sport, SPORTS["bate"])
	weapon_name = stats["name"]
	damage = stats["damage"]
	reach = stats["reach"]
	durability = stats["durability"]
	swing_time = stats["swing_time"]
	add_to_group("sports_equipment")
	model = Node3D.new()
	add_child(model)
	match sport:
		"raqueta": _build_racket()
		"pelota": _build_ball()
		"baseball": _build_baseball()
		"tenis": _build_tennis()
		"futbol": _build_football()
		"rugby": _build_rugby()
		"disco": _build_disc()
		_: _build_bat()
	_build_marker()
	put_down()

func put_down() -> void:
	held = false
	add_to_group("weapon_pickup")
	ring.show()
	if can_throw():
		base_y = 0.2 if sport in ["pelota", "futbol", "rugby"] else 0.1
		if sport == "disco": base_y = 0.04
		model.position = Vector3(0, base_y, 0)
		model.rotation = Vector3.ZERO
	else:
		base_y = 0.1
		model.position = Vector3(-0.35, base_y, 0)
		model.rotation = Vector3(0, 0, PI / 2)

func can_throw() -> bool:
	return sport in THROWABLE

func _sphere(radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	return _mesh(model, mesh, Vector3.ZERO, color)

func _seam(radius: float, color: Color, rotation_value: Vector3) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.003
	mesh.outer_radius = radius + 0.003
	var line := _mesh(model, mesh, Vector3.ZERO, color)
	line.rotation = rotation_value

func _build_baseball() -> void:
	_sphere(0.095, Color("f4eee1"))
	for side in [-1.0, 1.0]:
		for i in range(14):
			var angle := float(i) / 14 * TAU
			var stitch := _box_stitch(Vector3(side * 0.05, sin(angle) * 0.079, cos(angle) * 0.079))
			stitch.rotation.x = -angle

func _box_stitch(pos: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.022, 0.004, 0.004)
	return _mesh(model, mesh, pos, Color("c83939"))

func _build_tennis() -> void:
	_sphere(0.085, Color("c9e744"))
	_seam(0.085, Color("fff4df"), Vector3(PI / 3, 0, PI / 4))
	_seam(0.085, Color("fff4df"), Vector3(-PI / 3, 0, -PI / 4))

func _build_football() -> void:
	_sphere(0.18, Color("f1eee7"))
	for direction in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var patch := SphereMesh.new()
		patch.radius = 0.061
		patch.height = 0.122
		_mesh(model, patch, direction * 0.13, Color("242830"))
	for axis in [Vector3.ZERO, Vector3(PI / 2, 0, 0), Vector3(0, 0, PI / 2)]:
		_seam(0.18, Color("343842"), axis)

func _build_rugby() -> void:
	var ball := _sphere(0.14, Color("a86332"))
	ball.scale.y = 1.65
	for y in [-0.1, -0.06, -0.02, 0.02, 0.06, 0.1]:
		_box(model, Vector3(0.07, 0.008, 0.01), Vector3(0, y, -0.136), Color("eee7d1"))

func _build_disc() -> void:
	_cyl(model, 0.2, 0.18, 0.035, Vector3.ZERO, Color("e94d75"))
	_seam(0.17, Color("f8d862"), Vector3.ZERO)

func _build_bat() -> void:
	_cyl(model, 0.025, 0.06, 0.95, Vector3(0, -0.4, 0), Color("cb925a"))
	_cyl(model, 0.028, 0.028, 0.23, Vector3(0, -0.045, 0), Color("243346"))
	_cyl(model, 0.04, 0.04, 0.025, Vector3(0, 0.08, 0), Color("243346"))
	_cyl(model, 0.06, 0.06, 0.025, Vector3(0, -0.88, 0), Color("cb925a"))

func _build_racket() -> void:
	_cyl(model, 0.025, 0.025, 0.25, Vector3(0, -0.05, 0), Color("243346"))
	_cyl(model, 0.015, 0.022, 0.25, Vector3(0, -0.28, 0), Color("56c6bf"))
	var hoop := TorusMesh.new()
	hoop.inner_radius = 0.17
	hoop.outer_radius = 0.195
	var frame := _mesh(model, hoop, Vector3(0, -0.62, 0), Color("56c6bf"))
	frame.rotation.x = PI / 2
	frame.scale.z = 1.3
	for i in range(-3, 4):
		var offset := float(i) * 0.04
		var half_width := sqrt(maxf(0, 0.17 * 0.17 - offset * offset))
		_box(model, Vector3(half_width * 2, 0.004, 0.004), Vector3(0, -0.62 + offset * 1.3, 0), Color("eee9dc"))
		_box(model, Vector3(0.004, half_width * 2.6, 0.004), Vector3(offset, -0.62, 0), Color("eee9dc"))

func _build_ball() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	_mesh(model, sphere, Vector3.ZERO, Color("e88929"))
	for axis in range(3):
		var seam := TorusMesh.new()
		seam.inner_radius = 0.177
		seam.outer_radius = 0.184
		var line := _mesh(model, seam, Vector3.ZERO, Color("342a25"))
		if axis == 1: line.rotation.x = PI / 2
		if axis == 2: line.rotation.z = PI / 2
