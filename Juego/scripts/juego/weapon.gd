extends Node3D
## Arma recogible (palo o silla).
## En el suelo: flota, brilla y muestra "[E] Recoger". En la mano: se usa para golpear.
## El arma se extiende hacia -Y desde el origen (el origen es donde la agarra la mano).

const KINDS := {
	"palo": {"name": "Palo", "damage": 22.0, "reach": 1.9, "durability": 14, "swing_time": 0.6},
	"silla": {"name": "Silla", "damage": 34.0, "reach": 1.7, "durability": 4, "swing_time": 0.75},
}

var kind := "palo"          # asignar ANTES de add_child
var weapon_name := "Palo"
var damage := 22.0
var reach := 1.9
var durability := 14
var swing_time := 0.6
var held := false

var model: Node3D
var ring: MeshInstance3D
var label: Label3D
var t := 0.0
var base_y := 0.0


func _ready() -> void:
	var stats: Dictionary = KINDS[kind]
	weapon_name = stats["name"]
	damage = stats["damage"]
	reach = stats["reach"]
	durability = stats["durability"]
	swing_time = stats["swing_time"]

	model = Node3D.new()
	add_child(model)
	if kind == "palo":
		_build_stick()
	else:
		_build_chair()
	_build_marker()
	put_down()


# =====================================================================
#  Estado: en el suelo / en la mano
# =====================================================================
func put_down() -> void:
	held = false
	add_to_group("weapon_pickup")
	ring.visible = true
	if kind == "palo":
		model.rotation = Vector3(0, 0, PI * 0.5)    # tirado en el suelo
		base_y = 0.05
		model.position = Vector3(-0.375, base_y, 0)
	else:
		model.rotation = Vector3.ZERO               # silla de pie
		base_y = 0.75
		model.position = Vector3(0, base_y, 0)


func pick_up() -> void:
	held = true
	remove_from_group("weapon_pickup")
	ring.visible = false
	label.visible = false
	model.position = Vector3.ZERO
	model.rotation = Vector3.ZERO


func _process(delta: float) -> void:
	if held:
		return
	t += delta
	model.position.y = base_y + 0.04 * sin(t * 2.5)
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	label.visible = pl != null and not pl.has_node("InteractionController") and not pl.get("dead") \
			and pl.global_position.distance_to(global_position) < 2.2


# =====================================================================
#  Modelos
# =====================================================================
func _mat(c: Color, rough: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, pos: Vector3, color: Color) -> void:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bot_r
	c.height = h
	c.radial_segments = 16
	_mesh(parent, c, pos, color)


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var b := BoxMesh.new()
	b.size = size
	_mesh(parent, b, pos, color)


func _build_stick() -> void:
	var wood := Color("8a5a2b")
	var grip := Color("2a2522")
	_cyl(model, 0.024, 0.048, 0.95, Vector3(0, -0.375, 0), wood)   # más grueso en la punta
	_cyl(model, 0.027, 0.027, 0.2, Vector3(0, -0.02, 0), grip)     # empuñadura
	var knob := SphereMesh.new()
	knob.radius = 0.032
	knob.height = 0.064
	_mesh(model, knob, Vector3(0, 0.1, 0), grip)


func _build_chair() -> void:
	# La agarra por el respaldo; las patas apuntan hacia donde golpea (-Y)
	var root := Node3D.new()
	root.position = Vector3(0, -0.75, -0.18)
	model.add_child(root)
	var wood := Color("a06b3a")
	var dark := Color("7a4e28")
	_box(root, Vector3(0.42, 0.04, 0.42), Vector3(0, 0.45, -0.02), wood)       # asiento
	_box(root, Vector3(0.42, 0.22, 0.035), Vector3(0, 0.72, 0.18), wood)       # respaldo
	for sx in [-1.0, 1.0]:
		_box(root, Vector3(0.035, 0.47, 0.035), Vector3(0.19 * sx, 0.68, 0.18), dark)   # postes
		_cyl(root, 0.022, 0.022, 0.45, Vector3(0.18 * sx, 0.225, -0.18), dark)          # patas delanteras
		_cyl(root, 0.022, 0.022, 0.45, Vector3(0.18 * sx, 0.225, 0.17), dark)           # patas traseras


func _build_marker() -> void:
	# Círculo brillante en el suelo
	ring = MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.6
	c.bottom_radius = 0.6
	c.height = 0.01
	ring.mesh = c
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.85, 0.2, 0.35)
	ring.material_override = m
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(0, 0.01, 0)
	add_child(ring)

	# Texto flotante
	label = Label3D.new()
	label.text = "[E] Recoger %s" % weapon_name
	label.font_size = 48
	label.pixel_size = 0.005
	label.outline_size = 12
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 1.3, 0)
	label.visible = false
	add_child(label)
