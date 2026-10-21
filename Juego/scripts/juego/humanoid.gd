extends Node3D
## Cuerpo humanoide procedural reutilizable (lo usan el jugador y los enemigos).
## - El origen del nodo está en los PIES y el cuerpo mira hacia -Z.
## - Rotar +X una extremidad que cuelga la lleva hacia ADELANTE.
## - Inclinar el torso hacia adelante = rotación X NEGATIVA.

signal punch_landed(side: int)   # se emite en el instante en que el golpe "conecta"

# ---------- Proporciones (metros) ----------
const THIGH := 0.44
const SHIN := 0.43
const FOOT_H := 0.08
const UPPER_ARM := 0.28
const FOREARM := 0.26

# ---------- Poses (radianes) ----------
const CROUCH_THIGH := 1.05              # muslo hacia adelante al agacharse (~60°)
const CROUCH_KNEE := 1.9                # flexión de rodilla al agacharse (~109°)
const GUARD_POSE := Vector2(0.9, 2.0)   # (hombro, codo) en guardia
const HIT_POSE := Vector2(1.5, 0.05)    # brazo estirado al golpear
const HOLD_POSE := Vector2(0.9, 1.6)    # brazo derecho sosteniendo un arma
const SWING_COCK := Vector2(2.7, 1.1)   # arma levantada detrás de la cabeza
const SWING_END := Vector2(0.75, 0.25)  # arma al final del golpe (hacia abajo)

# ---------- Colores fijos ----------
const BELT := Color("1e1a17")
const SHOE_UPPER := Color("2a2d33")
const SHOE_SOLE := Color("e9e6df")

# ---------- Personalización (asignar ANTES de add_child) ----------
var skin_color := Color("e0ac86")
var shirt_color := Color("3b6ea5")
var pants_color := Color("2f4058")
var hair_color := Color("2b1d14")
var angry := false          # cejas fruncidas
var punch_time := 0.45      # duración de cada golpe (segundos)

# ---------- Estado público ----------
var crouch_amt := 0.0       # 0 = de pie, 1 = agachado (el dueño lo usa para la colisión)
var dead := false
var armed := false
var weapon_node: Node3D
var look_controller := preload("res://scripts/juego/look_at_controller.gd").new()
const EXPRESSIONS := ["NEUTRAL","HAPPY","ANGRY","WORRIED","SURPRISED","TIRED","RELIEVED","ALERT"]
var expression: String = "NEUTRAL"
var secondary_animation_enabled := true
var eyes: Array[Dictionary] = []
var blink_wait := randf_range(2.5,6.0)
var blink_time := 0.0
var visual_speed := 0.0
var hit_direction := 0.0
var hit_variant := "HIT_FRONT"
var eyebrows: Array[MeshInstance3D] = []
var mouth: MeshInstance3D
var lod_level: int = 0
var visual_near_distance := 16.0
var visual_far_distance := 35.0
var cast_near_shadows := true
var lod_tick := 0.0
var lod_meshes: Array[Node] = []
var activity_level := 0
var visual_elapsed := 0.0
var animation_delta := 0.0
var face_applied := ""
var eye_openness := -1.0
var blink_timer: Timer
static var shared_meshes: Dictionary = {}

func set_activity_level(level: int) -> void:
	var changed := activity_level != clampi(level,0,3)
	activity_level = clampi(level,0,3)
	if changed:
		lod_tick = 0
		update_visual_lod(0)
	set_meta("visual_activity",["LOD0","LOD1","LOD2","SLEEP"][activity_level])
	secondary_animation_enabled = activity_level == 0 and lod_level == 0
	if is_instance_valid(blink_timer): blink_timer.paused = not secondary_animation_enabled or dead
	if get("imported_visual") != null:
		get("imported_visual").set_activity(activity_level)

func animation_due(delta: float) -> bool:
	update_visual_lod(delta)
	visual_elapsed += delta
	var player := get_tree().get_first_node_in_group("player")
	var duel := get_parent().get_node_or_null("BossDuelController")
	var critical: bool = (player != null and player.is_ancestor_of(self)) or (duel != null and duel.state in [duel.DuelState.INTRO,duel.DuelState.COMBAT]) or (dead and death_t < 1) or hurt_t > 0 or is_punching()
	if get("imported_visual") != null: get("imported_visual").set_activity(0 if critical else activity_level)
	if activity_level == 3 and not critical:
		visual_elapsed = 0
		return false
	var interval: float = 0.0 if critical else [0.0,0.12,0.5,1.0][maxi(activity_level,lod_level)]
	if visual_elapsed < interval: return false
	# Explicit restore/death calls may advance a full second in one step.
	# Only ambient catch-up is capped; critical gameplay timing stays intact.
	animation_delta = visual_elapsed if critical else minf(visual_elapsed,0.5)
	visual_elapsed = 0
	return true

func update_visual_lod(delta: float) -> void:
	lod_tick -= delta
	if lod_tick > 0: return
	lod_tick = 0.5
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or player.is_ancestor_of(self): return
	var offset := global_position-player.global_position
	var next_lod := 2 if absf(offset.y) > 4 or offset.length_squared() > visual_far_distance*visual_far_distance else (1 if offset.length_squared() > visual_near_distance*visual_near_distance else 0)
	secondary_animation_enabled = next_lod == 0
	if is_instance_valid(blink_timer): blink_timer.paused = not secondary_animation_enabled or dead
	if lod_meshes.is_empty():
		lod_meshes = find_children("*","MeshInstance3D",true,false)
	if next_lod != lod_level:
		lod_level = next_lod
		for node in lod_meshes:
			if is_instance_valid(node):
				node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if lod_level == 0 and cast_near_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_expression(value: String) -> void:
	if value in EXPRESSIONS and value != expression:
		expression = value
		set_meta("expression",value)

func react_to_hit(direction: Vector3, intensity: float = 0.0) -> void:
	var local := global_transform.basis.inverse()*direction
	hit_direction = clampf(local.x,-1.0,1.0)
	hit_variant = "HIT_HEAVY" if intensity >= 25 else ("HIT_LEFT" if hit_direction > 0.25 else ("HIT_RIGHT" if hit_direction < -0.25 else "HIT_FRONT"))

func _secondary_animation(delta: float) -> void:
	if dead or not secondary_animation_enabled:
		return
	look_controller.apply(head_pivot,delta)
	blink_time = maxf(0.0,blink_time-delta)
	var openness := (1.0-sin(PI*blink_time/0.16)*0.95)*(0.7 if expression == "TIRED" else 1.0)
	if not is_equal_approx(openness,eye_openness):
		eye_openness = openness
		for eye in eyes:
			if is_instance_valid(eye.mesh): eye.mesh.scale.y = float(eye.height)*openness
	if face_applied == expression:
		chest.rotation.z = hit_direction*hurt_t*0.13
		return
	face_applied = expression
	for index in eyebrows.size():
		var sign_value := -1.0 if index == 0 else 1.0
		eyebrows[index].rotation.z = sign_value*(0.25 if expression in ["ANGRY","ALERT"] else (-0.18 if expression == "WORRIED" else 0.0))
		eyebrows[index].position.y = 0.15 if expression == "SURPRISED" else 0.135
	if is_instance_valid(mouth):
		mouth.scale.x = 1.15 if expression in ["HAPPY","RELIEVED"] else 1.0
		mouth.scale.y = 2.5 if expression == "SURPRISED" else 1.0
	chest.rotation.z = hit_direction*hurt_t*0.13

# ---------- Articulaciones ----------
var fall_pivot: Node3D
var hips: Node3D
var spine: Node3D
var chest: Node3D
var head_pivot: Node3D
var hip_l: Node3D
var hip_r: Node3D
var knee_l: Node3D
var knee_r: Node3D
var ankle_l: Node3D
var ankle_r: Node3D
var shoulder_l: Node3D
var shoulder_r: Node3D
var elbow_l: Node3D
var elbow_r: Node3D
var hand_l: Node3D
var hand_r: Node3D

# ---------- Estado interno ----------
var _mats := {}
var phase := 0.0
var time := 0.0
var air_t := 0.0
var crouch_t := 0.0
var land_t := 0.0
var run_t := 0.0
var hurt_t := 0.0
var death_t := 0.0
var armed_t := 0.0
var was_on_floor := true
var last_air_vy := 0.0
var flash_on := false

# Golpes: índice 0 = brazo izquierdo, 1 = brazo derecho
var punch_p: Array[float] = [-1.0, -1.0]
var punch_hit: Array[bool] = [false, false]
var next_right := true


func _ready() -> void:
	add_to_group("campus_character_visual")
	_build()
	blink_timer = Timer.new()
	blink_timer.name = "BlinkTimer"
	blink_timer.one_shot = true
	blink_timer.timeout.connect(_blink)
	add_child(blink_timer)
	blink_timer.start(blink_wait)

func _blink() -> void:
	if secondary_animation_enabled and not dead: blink_time = 0.16
	blink_timer.start(randf_range(2.8,6.5))


# =====================================================================
#  Helpers de construcción
# =====================================================================
func _mat(color: Color, rough: float = 0.85) -> StandardMaterial3D:
	var key := "%s_%s" % [color.to_html(), rough]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	_mats[key] = m
	return m


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _node(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color,
		scl: Vector3, rough: float) -> MeshInstance3D:
	# Primitive geometry is immutable after construction; materials stay per actor
	# because damage flashes and customization mutate them.
	var geometry_key := ""
	if mesh is SphereMesh: geometry_key = str(["sphere",mesh.radius,mesh.height,mesh.radial_segments,mesh.rings])
	elif mesh is CylinderMesh: geometry_key = str(["cylinder",mesh.top_radius,mesh.bottom_radius,mesh.height,mesh.radial_segments,mesh.rings])
	elif mesh is BoxMesh: geometry_key = str(["box",mesh.size])
	if not geometry_key.is_empty():
		if shared_meshes.has(geometry_key): mesh = shared_meshes[geometry_key]
		else: shared_meshes[geometry_key] = mesh
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(color, rough)
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
	if parent == head_pivot and color in [Color("f4f4f4"),Color("15151a"),Color("f4f3ec"),Color("303b32")]:
		eyes.append({"mesh":mi,"height":scl.y})
	if parent == head_pivot and mesh is BoxMesh:
		if color.is_equal_approx(hair_color):
			eyebrows.append(mi)
		elif color in [Color("8a3b3b"),Color("986958")]:
			mouth = mi
	return mi


func _ball(parent: Node3D, r: float, pos: Vector3, color: Color,
		scl: Vector3 = Vector3.ONE, rough: float = 0.85) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 24
	s.rings = 12
	return _node(parent, s, pos, color, scl, rough)


func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, pos: Vector3,
		color: Color, scl: Vector3 = Vector3.ONE, rough: float = 0.85) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bot_r
	c.height = h
	c.radial_segments = 24
	c.rings = 1
	return _node(parent, c, pos, color, scl, rough)


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color,
		rough: float = 0.85) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _node(parent, b, pos, color, Vector3.ONE, rough)


## Segmento cónico que cuelga hacia abajo desde su pivote (más grueso arriba).
func _limb(parent: Node3D, top_r: float, bot_r: float, length: float,
		color: Color, rough: float = 0.85) -> void:
	_cyl(parent, top_r, bot_r, length, Vector3(0, -length * 0.5, 0), color, Vector3.ONE, rough)


# =====================================================================
#  Construcción del cuerpo
# =====================================================================
func _build() -> void:
	fall_pivot = Node3D.new()
	add_child(fall_pivot)

	# Pelvis (pantalón)
	hips = _pivot(fall_pivot, Vector3(0, FOOT_H + THIGH + SHIN, 0))
	_ball(hips, 0.15, Vector3(0, -0.01, 0), pants_color, Vector3(1.1, 0.75, 0.85))

	# Abdomen + cinturón
	spine = _pivot(hips, Vector3(0, 0.05, 0))
	_cyl(spine, 0.145, 0.145, 0.035, Vector3.ZERO, BELT, Vector3(1.05, 1.0, 0.78), 0.5)
	_cyl(spine, 0.13, 0.14, 0.24, Vector3(0, 0.14, 0), shirt_color, Vector3(1.05, 1.0, 0.76))

	# Pecho (más ancho arriba) y hombros redondeados
	chest = _pivot(spine, Vector3(0, 0.22, 0))
	_cyl(chest, 0.165, 0.135, 0.30, Vector3(0, 0.12, 0), shirt_color, Vector3(1.1, 1.0, 0.74))
	_ball(chest, 0.16, Vector3(0, 0.26, 0), shirt_color, Vector3(1.1, 0.35, 0.74))

	# Cuello y cabeza
	var neck := _pivot(chest, Vector3(0, 0.27, 0))
	_cyl(neck, 0.046, 0.05, 0.11, Vector3(0, 0.04, 0), skin_color, Vector3.ONE, 0.6)
	head_pivot = _pivot(neck, Vector3(0, 0.09, 0))
	_build_head()

	# Brazos
	var al := _build_arm(-1.0)
	shoulder_l = al[0]
	elbow_l = al[1]
	hand_l = al[2]
	var ar := _build_arm(1.0)
	shoulder_r = ar[0]
	elbow_r = ar[1]
	hand_r = ar[2]

	# Piernas
	var ll := _build_leg(-1.0)
	hip_l = ll[0]
	knee_l = ll[1]
	ankle_l = ll[2]
	var lr := _build_leg(1.0)
	hip_r = lr[0]
	knee_r = lr[1]
	ankle_r = lr[2]


func _build_head() -> void:
	# Cráneo ovalado y pelo
	_ball(head_pivot, 0.105, Vector3(0, 0.1, 0), skin_color, Vector3(0.92, 1.1, 1.0), 0.6)
	_ball(head_pivot, 0.112, Vector3(0, 0.122, 0.016), hair_color, Vector3(0.96, 1.0, 1.0), 0.9)

	# Orejas y nariz
	for sx in [-1.0, 1.0]:
		_ball(head_pivot, 0.02, Vector3(0.095 * sx, 0.095, 0.0), skin_color, Vector3(0.6, 1.0, 0.8), 0.6)
	_ball(head_pivot, 0.017, Vector3(0, 0.085, -0.102), skin_color.darkened(0.08),
			Vector3(0.8, 1.0, 1.3), 0.6)

	# Ojos y cejas
	for sx in [-1.0, 1.0]:
		_ball(head_pivot, 0.017, Vector3(0.038 * sx, 0.105, -0.09), Color("f4f4f4"), Vector3.ONE, 0.3)
		_ball(head_pivot, 0.009, Vector3(0.038 * sx, 0.105, -0.103), Color("15151a"), Vector3.ONE, 0.2)
		var brow := _box(head_pivot, Vector3(0.045, 0.009, 0.012),
				Vector3(0.038 * sx, 0.132, -0.094), hair_color)
		if angry:
			brow.rotation.z = 0.35 * sx

	# Boca
	_box(head_pivot, Vector3(0.05, 0.007, 0.006), Vector3(0, 0.056, -0.096), Color("8a3b3b"), 0.5)


func _build_arm(side: float) -> Array:
	var shoulder := _pivot(chest, Vector3(0.19 * side, 0.24, 0))
	shoulder.rotation.z = 0.07 * side   # separado un poco del cuerpo
	_ball(shoulder, 0.058, Vector3.ZERO, shirt_color)
	_limb(shoulder, 0.048, 0.04, UPPER_ARM, skin_color, 0.6)
	_cyl(shoulder, 0.056, 0.05, 0.13, Vector3(0, -0.065, 0), shirt_color)   # manga corta

	var elbow := _pivot(shoulder, Vector3(0, -UPPER_ARM, 0))
	_ball(elbow, 0.04, Vector3.ZERO, skin_color, Vector3.ONE, 0.6)
	_limb(elbow, 0.038, 0.03, FOREARM, skin_color, 0.6)

	# Mano / puño con pulgar (aquí se engancha el arma)
	var hand := _pivot(elbow, Vector3(0, -FOREARM - 0.03, 0))
	_ball(hand, 0.043, Vector3.ZERO, skin_color, Vector3(0.85, 1.15, 1.0), 0.6)
	_ball(hand, 0.018, Vector3(-0.028 * side, 0.012, -0.02), skin_color, Vector3.ONE, 0.6)
	return [shoulder, elbow, hand]


func _build_leg(side: float) -> Array:
	var hip := _pivot(hips, Vector3(0.09 * side, 0, 0))
	_ball(hip, 0.085, Vector3.ZERO, pants_color)
	_limb(hip, 0.085, 0.06, THIGH, pants_color)

	var knee := _pivot(hip, Vector3(0, -THIGH, 0))
	_ball(knee, 0.06, Vector3.ZERO, pants_color)
	_limb(knee, 0.058, 0.043, SHIN, pants_color)

	# Zapatilla: parte de arriba + puntera + suela
	var ankle := _pivot(knee, Vector3(0, -SHIN, 0))
	_box(ankle, Vector3(0.1, 0.055, 0.2), Vector3(0, -0.0475, -0.04), SHOE_UPPER, 0.6)
	_ball(ankle, 0.05, Vector3(0, -0.05, -0.14), SHOE_UPPER, Vector3(0.95, 0.65, 1.0), 0.6)
	_box(ankle, Vector3(0.105, 0.02, 0.29), Vector3(0, -0.07, -0.07), SHOE_SOLE, 0.9)
	return [hip, knee, ankle]


# =====================================================================
#  API pública
# =====================================================================
func forward() -> Vector3:
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized()


func is_punching() -> bool:
	return punch_p[0] >= 0.0 or punch_p[1] >= 0.0


## Inicia un golpe. Con las manos vacías alterna brazo; con arma usa el derecho.
## Devuelve false si el/los brazos están ocupados.
func start_punch() -> bool:
	if dead:
		return false
	if armed:
		if punch_p[1] >= 0.0:
			return false
		punch_p[1] = 0.0
		punch_hit[1] = false
		return true
	var side := 1 if next_right else 0
	if punch_p[side] >= 0.0:
		side = 1 - side
		if punch_p[side] >= 0.0:
			return false
	punch_p[side] = 0.0
	punch_hit[side] = false
	next_right = (side == 0)
	return true


## Reacción al recibir un golpe (retroceso del torso + destello rojo).
func hurt() -> void:
	hurt_t = 1.0


func die() -> void:
	if dead:
		return
	dead = true
	punch_p[0] = -1.0
	punch_p[1] = -1.0


## Engancha un arma a la mano derecha.
func equip(w: Node3D) -> void:
	hand_r.add_child(w)
	w.position = Vector3.ZERO
	w.rotation = Vector3.ZERO
	weapon_node = w
	armed = true
	punch_p[0] = -1.0
	punch_p[1] = -1.0


## Suelta el arma de la mano y la devuelve (el dueño decide qué hacer con ella).
func unequip() -> Node3D:
	var w := weapon_node
	if w != null and w.get_parent() == hand_r:
		hand_r.remove_child(w)
	weapon_node = null
	armed = false
	punch_p[1] = -1.0
	return w


# =====================================================================
#  Animación de golpes
# =====================================================================
## Puñetazo: Vector2(peso de guardia, peso de golpe) según el progreso p (0..1).
func _punch_weights(p: float) -> Vector2:
	if p < 0.0:
		return Vector2.ZERO
	var wg := 1.0
	var wh := 0.0
	if p < 0.25:            # 1) preparar: brazo a guardia
		wg = p / 0.25
	elif p < 0.5:           # 2) lanzar el golpe (rápido)
		wh = (p - 0.25) / 0.25
	elif p < 0.65:          # 3) brazo extendido
		wh = 1.0
	else:                   # 4) recoger el brazo y volver a la pose normal
		wh = 1.0 - (p - 0.65) / 0.35
		if p > 0.8:
			wg = 1.0 - (p - 0.8) / 0.2
	return Vector2(smoothstep(0.0, 1.0, wg), smoothstep(0.0, 1.0, wh))


func _punch_arm(base: Vector2, w: Vector2) -> Vector2:
	var v := base.lerp(GUARD_POSE, w.x)
	return v.lerp(HIT_POSE, w.y)


## Golpe con arma (tajo desde arriba): pose (hombro, codo) según el progreso p.
func _swing_pose(p: float) -> Vector2:
	if p < 0.35:            # levantar el arma detrás de la cabeza
		return HOLD_POSE.lerp(SWING_COCK, smoothstep(0.0, 1.0, p / 0.35))
	elif p < 0.55:          # bajar de golpe
		return SWING_COCK.lerp(SWING_END, smoothstep(0.0, 1.0, (p - 0.35) / 0.2))
	elif p < 0.7:           # mantener
		return SWING_END
	return SWING_END.lerp(HOLD_POSE, smoothstep(0.0, 1.0, (p - 0.7) / 0.3))


## Giro del torso durante el golpe con arma (-0.6 = hacia atrás, 1 = hacia adelante).
func _swing_twist(p: float) -> float:
	if p < 0.0:
		return 0.0
	if p < 0.35:
		return -smoothstep(0.0, 1.0, p / 0.35) * 0.6
	if p < 0.55:
		return lerpf(-0.6, 1.0, smoothstep(0.0, 1.0, (p - 0.35) / 0.2))
	if p < 0.7:
		return 1.0
	return lerpf(1.0, 0.0, smoothstep(0.0, 1.0, (p - 0.7) / 0.3))


# =====================================================================
#  Piernas
# =====================================================================
## Devuelve Vector2(ángulo del muslo, flexión de la rodilla).
func _leg_pose(s: float, c: float, swing: float, air_thigh: float, air_knee: float) -> Vector2:
	# Caminar: el muslo oscila y la rodilla se flexiona al llevar la pierna adelante
	var thigh := s * swing
	var knee := maxf(0.0, c) * swing * 1.9
	# Correr: zancada más larga, rodilla muy flexionada al recuperar (talón hacia el glúteo)
	var run_thigh := 0.2 + 0.55 * s
	var run_knee := 0.3 + maxf(0.0, c) * 1.7
	thigh = lerpf(thigh, run_thigh, run_t)
	knee = lerpf(knee, run_knee, run_t)
	# Agacharse
	thigh = lerpf(thigh, CROUCH_THIGH, crouch_amt)
	knee = lerpf(knee, CROUCH_KNEE, crouch_amt)
	# En el aire
	thigh = lerpf(thigh, air_thigh, air_t)
	knee = lerpf(knee, air_knee, air_t)
	return Vector2(thigh, knee)


## Altura vertical entre cadera y suelo con esa pose de pierna.
func _reach(p: Vector2) -> float:
	return THIGH * cos(p.x) + SHIN * cos(p.x - p.y)


func _apply_leg(hip: Node3D, knee: Node3D, ankle: Node3D, p: Vector2) -> void:
	hip.rotation.x = p.x                             # muslo hacia adelante (+)
	knee.rotation.x = -p.y                           # la pantorrilla se dobla hacia atrás
	ankle.rotation.x = -(p.x - p.y) - 0.35 * air_t   # pie plano; punta abajo en el aire


# =====================================================================
#  Animación principal (llamar cada frame desde el dueño)
# =====================================================================
func animate(delta: float, velocity: Vector3, on_floor: bool, crouching: bool) -> void:
	if not animation_due(delta): return
	_animate_pose(animation_delta,velocity,on_floor,crouching)

func _animate_pose(delta: float, velocity: Vector3, on_floor: bool, crouching: bool) -> void:
	if dead:
		velocity = Vector3.ZERO
		on_floor = true
		crouching = false
		death_t = move_toward(death_t, 1.0, delta / 0.9)
	time += delta

	visual_speed = move_toward(visual_speed,Vector2(velocity.x, velocity.z).length(),delta*16.0)
	var hspeed := visual_speed

	# Aterrizaje: flexión de amortiguación
	if not on_floor:
		last_air_vy = velocity.y
	elif not was_on_floor and last_air_vy < -2.0:
		land_t = clampf(-last_air_vy / 7.0, 0.3, 1.0)
		last_air_vy = 0.0
	was_on_floor = on_floor

	# Mezclas suaves entre estados
	air_t = move_toward(air_t, 0.0 if on_floor else 1.0, delta * 8.0)
	crouch_t = move_toward(crouch_t, 1.0 if crouching else 0.0, delta * 6.0)
	land_t = move_toward(land_t, 0.0, delta * 3.5)
	hurt_t = move_toward(hurt_t, 0.0, delta * 3.0)
	armed_t = move_toward(armed_t, 1.0 if armed else 0.0, delta * 6.0)
	var run_target := clampf((hspeed - 3.2) / 1.5, 0.0, 1.0) * (1.0 - crouch_t)
	run_t = move_toward(run_t, run_target, delta * 4.0)
	crouch_amt = clampf(maxf(crouch_t, land_t * 0.7), 0.0, 1.0)
	if dead:
		crouch_amt = maxf(crouch_amt, smoothstep(0.0, 0.5, death_t) * 0.35)

	# Fase del ciclo de paso: caminar depende de la velocidad; correr tiene cadencia fija
	var walk_k := minf(hspeed / 2.5, 1.0)
	var rate := lerpf(hspeed * 3.5, 10.0, run_t)
	phase = fmod(phase + rate * delta, TAU)
	var s := sin(phase)
	var c := cos(phase)
	var swing := 0.35 * walk_k * (1.0 - 0.5 * crouch_amt)

	# --- Piernas ---
	var fall := clampf(-velocity.y / 6.0, 0.0, 1.0)   # 0 subiendo, 1 cayendo
	var pl := _leg_pose(s, c, swing, 0.75 - 0.45 * fall, 1.2 - 0.6 * fall)
	var pr := _leg_pose(-s, -c, swing, 0.25 - 0.15 * fall, 0.7 - 0.4 * fall)
	_apply_leg(hip_l, knee_l, ankle_l, pl)
	_apply_leg(hip_r, knee_r, ankle_r, pr)

	# --- Altura de la cadera: la pierna más extendida toca el suelo ---
	var planted := FOOT_H + maxf(_reach(pl), _reach(pr))
	var standing := FOOT_H + THIGH + SHIN
	hips.position.y = lerpf(planted, standing, air_t)

	# --- Avance de los golpes ---
	var hit_at := 0.5 if armed else 0.42
	for i in 2:
		if punch_p[i] >= 0.0:
			punch_p[i] += delta / punch_time
			if not punch_hit[i] and punch_p[i] > hit_at:
				punch_hit[i] = true
				punch_landed.emit(i)
			if punch_p[i] >= 1.0:
				punch_p[i] = -1.0
	var w_l := _punch_weights(punch_p[0])
	var w_r := _punch_weights(punch_p[1])
	var sw_twist := 0.0
	if armed:
		w_l = Vector2.ZERO
		sw_twist = _swing_twist(punch_p[1])
		w_r = Vector2(0.0, clampf(sw_twist, 0.0, 1.0))

	# --- Brazos: opuestos a la pierna del mismo lado ---
	var arm_amp := 0.55 * walk_k
	var arm_l := lerpf(-s * arm_amp, 0.1 - s * 0.85, run_t) + crouch_amt * 0.5
	var arm_r := lerpf(s * arm_amp, 0.1 + s * 0.85, run_t) + crouch_amt * 0.5
	arm_l = lerpf(arm_l, 1.7 - 0.8 * fall, air_t)
	arm_r = lerpf(arm_r, 1.3 - 0.6 * fall, air_t)
	arm_l -= 0.6 * hurt_t
	arm_r -= 0.6 * hurt_t
	# Al correr los codos van muy doblados (~80°)
	var el_l := lerpf(0.15 + maxf(0.0, arm_l) * 0.8, 1.45, run_t) + crouch_amt * 0.4
	var el_r := lerpf(0.15 + maxf(0.0, arm_r) * 0.8, 1.45, run_t) + crouch_amt * 0.4
	var pose_l := _punch_arm(Vector2(arm_l, el_l), w_l)
	var pose_r := _punch_arm(Vector2(arm_r, el_r), w_r)
	if armed_t > 0.0:   # con arma: brazo derecho en posición de sostenerla o golpeando
		var armed_pose := HOLD_POSE
		if punch_p[1] >= 0.0:
			armed_pose = _swing_pose(punch_p[1])
		pose_r = pose_r.lerp(armed_pose, armed_t)
	shoulder_l.rotation.x = pose_l.x
	elbow_l.rotation.x = pose_l.y
	shoulder_r.rotation.x = pose_r.x
	elbow_r.rotation.x = pose_r.y

	# --- Torso y cabeza ---
	var twist := w_r.y - w_l.y                    # al golpear, el torso gira hacia ese lado
	if armed:
		twist = sw_twist
	var lean := 0.05 * walk_k + 0.28 * run_t + 0.5 * crouch_amt \
			+ 0.12 * maxf(w_l.y, w_r.y) - 0.35 * hurt_t
	spine.rotation.x = -lean * 0.5
	chest.rotation.x = -lean * 0.5
	head_pivot.rotation.x = lean * 0.8            # la cabeza compensa para mirar al frente
	var tw := lerpf(0.12, 0.2, run_t) * walk_k    # contra-giro de cadera y hombros al andar
	hips.rotation.y = -s * tw + twist * 0.25
	chest.rotation.y = s * tw * 1.5 + twist * 0.5
	spine.position.y = 0.05 + 0.003 * sin(time * 2.4) * (1.0 - walk_k)   # respiración

	# --- Muerte: cae hacia atrás con los brazos abiertos ---
	shoulder_l.rotation.z = -0.07
	shoulder_r.rotation.z = 0.07
	if dead:
		var f := death_t * death_t
		fall_pivot.rotation.x = f * (PI * 0.5)
		fall_pivot.position.y = 0.17 * f
		shoulder_l.rotation.z = -0.07 - 0.8 * f
		shoulder_r.rotation.z = 0.07 + 0.8 * f

	_update_flash()
	_secondary_animation(delta)


## Destello rojo al recibir daño.
func _update_flash() -> void:
	var on := hurt_t > 0.0
	if not on and not flash_on:
		return
	flash_on = on
	for m in _mats.values():
		var mat := m as StandardMaterial3D
		mat.emission_enabled = on
		if on:
			mat.emission = Color(1.0, 0.2, 0.15) * (hurt_t * 0.7)
