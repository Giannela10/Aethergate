extends Node3D
## Escritorio con computador. Acércate y presiona E para abrir su minijuego.
## La pantalla es azul mientras la tarea está pendiente y verde cuando la completas.
## El computador mira hacia +Z (la silla y el jugador quedan en ese lado).

const NAMES := ["Ordenar archivos", "Antivirus", "Contraseña"]

var game_id := 0        # 0 = archivos, 1 = antivirus, 2 = contraseña (asignar ANTES de add_child)
var done := false
var activity_profile := ""

func activity_title() -> String:
	return preload("res://scripts/juego/campus_activity.gd").title_for(activity_profile) if not activity_profile.is_empty() else NAMES[game_id]

func interaction_text(_player: Node) -> String:
	return "" if done else "[E] " + activity_title()

var screen_mat: StandardMaterial3D
var screen_light: OmniLight3D
var screen_text: Label3D
var prompt: Label3D


func _ready() -> void:
	add_to_group("computer")
	_build_desk()
	_build_chair()
	_build_computer()
	_build_prompt()
	_refresh()


# =====================================================================
#  Helpers
# =====================================================================
func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rough: float = 0.8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	mi.mesh = c
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.7
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)


# =====================================================================
#  Modelo: escritorio, silla y computador
# =====================================================================
func _build_desk() -> void:
	var wood := Color("9b7248")
	var dark := Color("5e4529")
	_box(self, Vector3(1.6, 0.06, 0.8), Vector3(0, 0.77, 0), wood)            # tablero
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(self, Vector3(0.06, 0.74, 0.06), Vector3(0.74 * sx, 0.37, 0.34 * sz), dark)   # patas
	_box(self, Vector3(1.5, 0.45, 0.03), Vector3(0, 0.5, -0.37), dark)        # panel trasero

	# Colisión: un bloque para que no se pueda atravesar
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 0.8, 0.8)
	col.shape = shape
	col.position = Vector3(0, 0.4, 0)
	body.add_child(col)
	add_child(body)


func _build_chair() -> void:
	# Silla de oficina decorativa (sin colisión), un poco girada
	var chair := Node3D.new()
	chair.position = Vector3(0.2, 0, 1.55)
	chair.rotation_degrees.y = 18.0
	add_child(chair)
	var fabric := Color("2f3b52")
	_box(chair, Vector3(0.5, 0.07, 0.5), Vector3(0, 0.5, 0), fabric)           # asiento
	_box(chair, Vector3(0.5, 0.5, 0.07), Vector3(0, 0.8, 0.25), fabric)        # respaldo
	_cyl(chair, 0.04, 0.45, Vector3(0, 0.25, 0), Color("222222"))              # columna
	_cyl(chair, 0.26, 0.04, Vector3(0, 0.03, 0), Color("222222"))              # base


func _build_computer() -> void:
	var black := Color("1a1a1f")
	# Monitor
	_cyl(self, 0.12, 0.02, Vector3(0, 0.81, -0.1), black)                      # base
	_box(self, Vector3(0.05, 0.15, 0.03), Vector3(0, 0.89, -0.12), black)      # cuello
	_box(self, Vector3(0.72, 0.44, 0.04), Vector3(0, 1.12, -0.12), black)      # marco

	# Pantalla que brilla
	var screen := _box(self, Vector3(0.66, 0.38, 0.01), Vector3(0, 1.12, -0.095), Color.WHITE)
	screen_mat = StandardMaterial3D.new()
	screen_mat.emission_enabled = true
	screen_mat.emission_energy_multiplier = 1.4
	screen.material_override = screen_mat

	screen_text = Label3D.new()
	screen_text.font_size = 36
	screen_text.pixel_size = 0.0016
	screen_text.outline_size = 6
	screen_text.position = Vector3(0, 1.12, -0.088)
	add_child(screen_text)

	# Teclado, ratón y torre
	_box(self, Vector3(0.42, 0.02, 0.14), Vector3(0, 0.81, 0.2), Color("2b2b30"))
	_box(self, Vector3(0.06, 0.03, 0.1), Vector3(0.32, 0.815, 0.22), Color("2b2b30"))
	_box(self, Vector3(0.2, 0.42, 0.4), Vector3(0.62, 1.01, -0.1), Color("24242a"))

	# Luz suave de la pantalla
	screen_light = OmniLight3D.new()
	screen_light.position = Vector3(0, 1.15, 0.35)
	screen_light.omni_range = 3.5
	screen_light.light_energy = 0.8
	add_child(screen_light)


func _build_prompt() -> void:
	prompt = Label3D.new()
	prompt.text = "[E] Usar computador\n%s" % activity_title()
	prompt.font_size = 40
	prompt.pixel_size = 0.005
	prompt.outline_size = 12
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.no_depth_test = true
	prompt.position = Vector3(0, 1.8, 0.3)
	prompt.visible = false
	add_child(prompt)


# =====================================================================
#  Estado
# =====================================================================
func set_done() -> void:
	done = true
	_refresh()


func _refresh() -> void:
	var color := Color("3b82f6")
	screen_text.text = "PC %d\n%s" % [game_id + 1, activity_title()]
	if done:
		color = Color("22c55e")
		screen_text.text = "COMPLETADO"
	screen_mat.albedo_color = color.darkened(0.3)
	screen_mat.emission = color
	screen_light.light_color = color
	prompt.visible = false


func _process(_delta: float) -> void:
	if done:
		return
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	prompt.visible = pl != null and not pl.has_node("InteractionController") and not pl.get("dead") and not pl.get("busy") \
			and pl.global_position.distance_to(global_position) < 2.2
