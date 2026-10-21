extends Node3D
## Escena principal: mundo, cámara en tercera persona (ratón), HUD, enemigos, armas
## y 3 escritorios con computador (cada uno con un minijuego distinto).

const MOUSE_SENS := 0.003
const START_ENEMIES := 3
const ENEMY_RESPAWN_TIME := 6.0
const WEAPON_RESPAWN_TIME := 8.0
const TASKS_TOTAL := 3
const TASK_HEAL := 25.0          # vida que recuperas al completar una tarea

# Keep the entrance clear for exploring the campus.
@export var populate_entrance := false

# Puntos donde aparecen/reaparecen los enemigos (lejos del jugador, para que haya sigilo)
const ENEMY_SPAWNS := [
	Vector3(14, 0.05, -8), Vector3(-15, 0.05, -4), Vector3(0, 0.05, -20),
	Vector3(10, 0.05, 15), Vector3(-12, 0.05, 13), Vector3(22, 0.05, 4),
]
# Lugares donde aparecen las armas
const WEAPON_SPOTS := [
	Vector3(3, 0, -3), Vector3(-3, 0, -2), Vector3(6, 0, 5), Vector3(-6, 0, 6),
	Vector3(9, 0, -2), Vector3(-9, 0, -8), Vector3(2, 0, 9), Vector3(-2, 0, -12),
]

var player                      # jugador (CharacterBody3D con player.gd)
var minigame                    # ventana de minijuegos (CanvasLayer con minigame_ui.gd)
var current_computer = null     # computador que se está usando
var cam: Camera3D
var cam_yaw := 0.0
var cam_pitch := 0.35
var cam_dist := 5.0
var cam_pivot := Vector3.ZERO
var kills := 0
var tasks_done := 0
var message_id := 0
var task_count := 0

var hp_bar: ProgressBar
var kills_label: Label
var tasks_label: Label
var weapon_label: Label
var msg_label: Label


func _ready() -> void:
	#_build_environment()
	#_build_floor()
	#_build_obstacles()

	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/juego/player.gd"))
	var campaign := get_parent().get_node_or_null("CampusCampaign")
	if campaign and (not campaign.persist or campaign.has_meta("test_mode")):
		player.persist_inventory = false
	add_child(player)
	player.global_position = Vector3(0, 2, 0)

	cam = Camera3D.new()
	cam.fov = 60.0
	add_child(cam)
	cam.make_current()
	cam_pivot = player.global_position + Vector3(0, 1.4, 0)

	minigame = CanvasLayer.new()
	minigame.set_script(load("res://scripts/juego/minigame_ui.gd"))
	add_child(minigame)
	minigame.finished.connect(_on_minigame_finished)

	_build_hud()
	player.health_changed.connect(_on_player_health)
	player.weapon_changed.connect(_on_weapon_changed)
	player.weapon_broke.connect(_on_weapon_broke)
	player.computer_requested.connect(_on_computer_requested)
	player.hit_received.connect(_on_player_hit)
	player.died.connect(_on_player_died)
	_on_player_health(player.health, player.max_health)
	player._emit_weapon()

	# Computadores: (posición, giro en grados, minijuego)
	if populate_entrance:
		_spawn_computer(Vector3(-6, 0, -5), 0.0, 0)
		_spawn_computer(Vector3(8, 0, 8), 225.0, 1)
		_spawn_computer(Vector3(-13, 0, 6), 90.0, 2)
		var kinds := ["palo", "silla", "palo", "silla", "palo"]
		for i in kinds.size():
			_spawn_weapon(kinds[i], WEAPON_SPOTS[i])
		for i in START_ENEMIES:
			_spawn_enemy(ENEMY_SPAWNS[i])

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	task_count = get_tree().get_nodes_in_group("computer").size()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)
	_update_counters()


# =====================================================================
#  Ambiente, suelo y obstáculos
# =====================================================================
func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("4f86c6")
	sky_mat.sky_horizon_color = Color("bcd6ea")
	sky_mat.ground_horizon_color = Color("bcd6ea")
	sky_mat.ground_bottom_color = Color("6f8f6a")
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("bcd6ea")
	env.fog_density = 0.008
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _build_floor() -> void:
	var size := Vector3(300, 1, 300)
	var body := StaticBody3D.new()
	body.position = Vector3(0, -0.5, 0)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	# Suelo a cuadros (así se nota el movimiento)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 g = floor(wpos.xz);
	float c = mod(g.x + g.y, 2.0);
	ALBEDO = mix(vec3(0.46, 0.58, 0.40), vec3(0.38, 0.50, 0.33), c);
	ROUGHNESS = 0.95;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh

	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)

	add_child(body)


func _add_block(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	body.add_child(mi)

	add_child(body)


## Paredes, cajas y pilares: bloquean la vista de los enemigos (para esconderte).
func _build_obstacles() -> void:
	var concrete := Color("8d9199")
	var wood := Color("a47b4c")
	_add_block(Vector3(0, 1.25, -9), Vector3(8, 2.5, 0.5), concrete)       # pared grande
	_add_block(Vector3(-8, 1.25, 4), Vector3(0.5, 2.5, 8), concrete)       # pared lateral
	_add_block(Vector3(12, 1.25, -14), Vector3(0.5, 2.5, 8), concrete)     # pared lejana
	_add_block(Vector3(5, 0.35, -6), Vector3(1.4, 0.7, 1.4), wood)         # cajas (se pueden saltar)
	_add_block(Vector3(6.6, 0.35, -6.2), Vector3(1.4, 0.7, 1.4), wood)
	_add_block(Vector3(10, 1.5, 2), Vector3(0.8, 3, 0.8), concrete)        # pilares
	_add_block(Vector3(-12, 1.5, -10), Vector3(0.8, 3, 0.8), concrete)
	_add_block(Vector3(-3, 1.5, 12), Vector3(0.8, 3, 0.8), concrete)


# =====================================================================
#  Aparición de computadores, enemigos y armas
# =====================================================================
func _spawn_computer(pos: Vector3, yaw_deg: float, game_id: int) -> void:
	var c := Node3D.new()
	c.set_script(load("res://scripts/juego/computer.gd"))
	c.set("game_id", game_id)   # hay que asignarlo antes de add_child
	c.position = pos
	c.rotation_degrees.y = yaw_deg
	add_child(c)


func _spawn_enemy(pos: Vector3) -> void:
	var e := CharacterBody3D.new()
	e.set_script(load("res://scripts/juego/enemy.gd"))
	e.position = pos
	add_child(e)
	e.died.connect(_on_enemy_died)


func _spawn_weapon(kind: String, pos: Vector3) -> void:
	var w := Node3D.new()
	w.set_script(load("res://scripts/juego/weapon.gd"))
	w.set("kind", kind)          # hay que asignarlo antes de add_child
	w.position = pos
	add_child(w)


## Elige un punto de aparición lejos del jugador.
func _pick_enemy_spawn() -> Vector3:
	var far: Array = []
	for p in ENEMY_SPAWNS:
		var d: float = p.distance_to(player.global_position)
		if d > 14.0:
			far.append(p)
	if far.is_empty():
		return ENEMY_SPAWNS[randi() % ENEMY_SPAWNS.size()]
	return far[randi() % far.size()]


# =====================================================================
#  HUD
# =====================================================================
func _style_label(l: Label, font_size: int) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var box := VBoxContainer.new()
	box.position = Vector2(20, 16)
	layer.add_child(box)

	var hp_title := Label.new()
	hp_title.text = "Vida"
	_style_label(hp_title, 20)
	box.add_child(hp_title)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(280, 22)
	hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hp_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.2, 0.2)
	hp_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(hp_bar)

	weapon_label = Label.new()
	_style_label(weapon_label, 20)
	box.add_child(weapon_label)

	tasks_label = Label.new()
	_style_label(tasks_label, 20)
	box.add_child(tasks_label)

	kills_label = Label.new()
	_style_label(kills_label, 20)
	box.add_child(kills_label)
	_update_counters()

	var help := Label.new()
	help.text = "WASD mover · Shift correr · C agacharse (sigilo) · Espacio saltar\n" \
			+ "J / clic izq. golpear · E usar computador o recoger arma · G soltar\n" \
			+ "Ratón: cámara · Rueda: zoom · Esc: liberar ratón · R: reiniciar"
	help.text += "\nQ: lanzar pelota o disco equipado"
	_style_label(help, 15)
	box.add_child(help)

	msg_label = Label.new()
	layer.add_child(msg_label)
	msg_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	msg_label.offset_top = 100
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(msg_label, 40)
	msg_label.visible = false


func _update_counters() -> void:
	kills_label.text = "Enemigos derrotados: %d" % kills
	tasks_label.text = "Tareas en computadores: %d / %d" % [tasks_done, task_count] if task_count > 0 else "Explora el campus · Biblioteca y Punto Estudiantil"


func _show_message(text: String, seconds: float) -> void:
	message_id += 1
	var shown_message := message_id
	msg_label.text = text
	msg_label.visible = true
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
		if not player.dead and message_id == shown_message:
			msg_label.visible = false


# =====================================================================
#  Eventos
# =====================================================================
func _on_player_health(hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp


func _on_weapon_changed(text: String) -> void:
	weapon_label.text = "Arma: " + text


func _on_weapon_broke(weapon_name: String) -> void:
	_show_message("¡Se rompió: %s!" % weapon_name, 2.0)
	if not populate_entrance:
		return
	await get_tree().create_timer(WEAPON_RESPAWN_TIME).timeout
	_spawn_weapon(["palo", "silla"][randi() % 2], WEAPON_SPOTS[randi() % WEAPON_SPOTS.size()])


func _on_player_died() -> void:
	if player.stationery_ui.panel.visible:
		player.stationery_ui.close_inventory()
	for vendor in get_tree().get_nodes_in_group("stationery_vendor"):
		if vendor.window.visible:
			vendor.close_shop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_message("Has muerto\nPresiona R para reiniciar", 0.0)


func _on_enemy_died(_enemy) -> void:
	kills += 1
	_update_counters()
	_show_message("¡Enemigo derrotado!", 2.0)
	if not populate_entrance:
		return
	await get_tree().create_timer(ENEMY_RESPAWN_TIME).timeout
	if not player.dead:
		_spawn_enemy(_pick_enemy_spawn())


# ---------- Computadores y minijuegos ----------
func _on_computer_requested(c) -> void:
	if minigame.active or player.dead or c.done:
		return
	current_computer = c
	player.busy = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	minigame.open(c.game_id,str(c.get("activity_profile")) if c.get("activity_profile") != null else "")
	if c.get_meta("campaign_id","") == "director_antivirus" and minigame.current != null:
		minigame.current.GOAL = 4
		minigame.current.bar.max_value = 4
		minigame.current._update_info()
		minigame.title_label.text = "Prueba del Director · identifica archivos sospechosos"


func _on_minigame_finished(success: bool) -> void:
	player.busy = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if success and current_computer != null:
		current_computer.set_done()
		tasks_done += 1
		_update_counters()
		player.heal(TASK_HEAL)
		if tasks_done >= task_count:
			_show_message("¡Completaste las %d tareas!" % task_count, 5.0)
		else:
			_show_message("¡Tarea completada! (%d/%d)  +%d de vida" % [tasks_done, task_count, int(TASK_HEAL)], 2.5)
	current_computer = null


## Si un enemigo te golpea mientras usas el computador, la tarea se interrumpe.
func _on_player_hit() -> void:
	if minigame.active:
		minigame.close(false)
		_show_message("¡Te atacaron! Tarea interrumpida", 2.0)


# =====================================================================
#  Entrada: cámara con ratón, reinicio
# =====================================================================
func _unhandled_input(event: InputEvent) -> void:
	if player.busy or player.dead:
		return
	var mm := event as InputEventMouseMotion
	if mm != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_yaw -= mm.relative.x * MOUSE_SENS
		cam_pitch = clampf(cam_pitch + mm.relative.y * MOUSE_SENS, -0.1, 1.2)
		return

	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED    # clic = volver a capturar el ratón
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = clampf(cam_dist - 0.4, 2.5, 9.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = clampf(cam_dist + 0.4, 2.5, 9.0)


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if player.busy and not minigame.active:
		return
	if minigame.active and k.keycode != KEY_ESCAPE:
		return
	if k.keycode == KEY_R:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().reload_current_scene()
	elif k.keycode == KEY_ESCAPE:
		if minigame.active:
			minigame.close(false)                           # salir del computador
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# =====================================================================
#  Cámara en tercera persona: sigue al personaje y orbita con el ratón
# =====================================================================
func _process(delta: float) -> void:
	if player.global_position.y < -25.0 and not player.dead:
		player.take_hit(Vector3.ZERO, player.max_health)
	player.cam_yaw = cam_yaw

	var focus: Vector3 = player.global_position + Vector3(0, 1.4, 0)
	cam_pivot = cam_pivot.lerp(focus, 1.0 - exp(-14.0 * delta))   # seguimiento suave

	var offset := Vector3(0, sin(cam_pitch), cos(cam_pitch)) * cam_dist
	offset = offset.rotated(Vector3.UP, cam_yaw)
	var desired_position := cam_pivot + offset
	var query := PhysicsRayQueryParameters3D.create(cam_pivot, desired_position)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	cam.global_position = hit.position + hit.normal * 0.25 if not hit.is_empty() else desired_position
	cam.look_at(cam_pivot)
