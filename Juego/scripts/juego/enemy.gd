extends CharacterBody3D
## Enemigo con sigilo. NO sabe dónde estás hasta que te ve (o te oye muy de cerca).
##
## Estados:
##   PATROL = camina sin rumbo y se queda mirando alrededor
##   CHASE  = te persigue y te golpea (aparece un "!" rojo)
##   SEARCH = llegó a donde te vio por última vez y te busca (aparece un "?" naranja)
## Mientras se da cuenta de ti aparece un "?" amarillo que se va llenando.
##
## Visión: cono frontal de ~110°, alcance 14 m, bloqueado por paredes.
## Si te agachas te ve a la mitad de distancia; si corres, a 30% más.

signal died(enemy)

const Humanoid = preload("res://scripts/juego/humanoid.gd")

enum State { PATROL, CHASE, SEARCH }

# ---------- Ajustes (cámbialos para hacerlo más fácil o difícil) ----------
const MAX_HEALTH := 100.0
const PATROL_SPEED := 1.3
const CHASE_SPEED := 2.6
const GRAVITY := 14.0

const VISION_RANGE := 14.0       # metros
const VISION_HALF_ANGLE := 55.0  # grados (55 = cono de 110°)
const HEARING_RANGE := 3.0       # si estás más cerca que esto, te nota aunque no mire
const NOTICE_TIME := 0.8         # segundos para darse cuenta estando cerca

const ATTACK_RANGE := 1.35       # a esta distancia se detiene y ataca
const ATTACK_HIT_RANGE := 1.6    # distancia máxima a la que su golpe conecta
const ATTACK_DAMAGE := 8.0
const ATTACK_COOLDOWN := 1.2
const STUN_TIME := 0.3           # tiempo aturdido al recibir un golpe

const BAR_W := 0.8

var health := MAX_HEALTH
var dead := false
var state := State.PATROL
var suspicion := 0.0             # 0 = no sabe nada, 1 = te descubrió
var stun_t := 0.0
var attack_cd := 1.0

var target: Node3D
var body: Humanoid

var home := Vector3.ZERO
var patrol_target := Vector3.ZERO
var patrol_wait := 1.0
var patrol_walk_t := 0.0
var idle_yaw := 0.0
var last_seen := Vector3.ZERO
var lost_t := 0.0
var search_t := 0.0

var bar_root: Node3D
var bar_fg: MeshInstance3D
var alert_label: Label3D


func _ready() -> void:
	add_to_group("enemy")
	home = global_position
	patrol_target = home
	patrol_wait = randf_range(0.5, 2.5)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)

	body = _create_visual()
	body.shirt_color = Color("a83232")
	body.pants_color = Color("3a3a3a")
	body.hair_color = Color("111111")
	body.skin_color = Color("c48a68")
	body.angry = true
	body.punch_time = 0.7        # golpe lento: se ve venir y se puede esquivar
	add_child(body)
	body.rotation.y = randf() * TAU
	idle_yaw = body.rotation.y
	body.punch_landed.connect(_on_punch_landed)

	_build_bar()
	_build_indicator()

func _create_visual() -> Humanoid:
	return Humanoid.new()


# =====================================================================
#  Barra de vida e indicador de alerta
# =====================================================================
func _build_bar() -> void:
	bar_root = Node3D.new()
	bar_root.position = Vector3(0, 2.15, 0)
	add_child(bar_root)
	_bar_quad(Color(0, 0, 0, 0.75), -1, Vector2(BAR_W + 0.05, 0.13))
	bar_fg = _bar_quad(Color(0.9, 0.15, 0.1), 0, Vector2(BAR_W, 0.09))


func _bar_quad(color: Color, priority: int, size: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.albedo_color = color
	m.render_priority = priority
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar_root.add_child(mi)
	return mi


func _update_bar() -> void:
	var ratio := clampf(health / MAX_HEALTH, 0.0, 1.0)
	var w := maxf(BAR_W * ratio, 0.001)
	var q := bar_fg.mesh as QuadMesh
	q.size = Vector2(w, 0.09)
	q.center_offset = Vector3(-(BAR_W - w) * 0.5, 0.0, 0.0)   # se vacía hacia la izquierda


func _build_indicator() -> void:
	alert_label = Label3D.new()
	alert_label.text = "!"
	alert_label.font_size = 96
	alert_label.pixel_size = 0.006
	alert_label.outline_size = 16
	alert_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alert_label.no_depth_test = true
	alert_label.position = Vector3(0, 2.6, 0)
	alert_label.visible = false
	add_child(alert_label)


func _update_indicator() -> void:
	match state:
		State.CHASE:
			alert_label.text = "!"
			alert_label.modulate = Color(1.0, 0.2, 0.15)
			alert_label.visible = true
		State.SEARCH:
			alert_label.text = "?"
			alert_label.modulate = Color(1.0, 0.6, 0.1)
			alert_label.visible = true
		_:
			if suspicion > 0.05:
				alert_label.text = "?"
				alert_label.modulate = Color(1.0, 0.92, 0.2, clampf(0.3 + suspicion, 0.0, 1.0))
				alert_label.visible = true
			else:
				alert_label.visible = false


# =====================================================================
#  Percepción
# =====================================================================
func _line_of_sight(from: Vector3, to: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var ex: Array[RID] = [get_rid()]
	for e in get_tree().get_nodes_in_group("enemy"):
		var cb := e as CollisionObject3D
		if cb != null:
			ex.append(cb.get_rid())
	q.exclude = ex
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	return hit.get("collider") == target


## 0 = no te percibe; >0 = te percibe (más cerca = se da cuenta más rápido).
func _vision_amount() -> float:
	if target == null or not is_instance_valid(target) or target.get("dead"):
		return 0.0

	var to := target.global_position - global_position
	if absf(to.y) > 2.0:
		return 0.0
	to.y = 0.0
	var dist := to.length()
	if dist < 0.001:
		return 1.0

	# Sigilo: agachado te ven menos; corriendo te ven más
	var range_mul := 1.0
	var eye_h := 1.1
	if target.get("crouching"):
		range_mul = 0.5
		eye_h = 0.7
	elif target.get("running"):
		range_mul = 1.3

	# Oído: muy cerca te nota aunque no te vea
	if dist < HEARING_RANGE * range_mul:
		return 1.0

	var max_dist := VISION_RANGE * range_mul
	if dist > max_dist:
		return 0.0

	# Cono de visión
	var dir := to / dist
	if body.forward().dot(dir) < cos(deg_to_rad(VISION_HALF_ANGLE)):
		return 0.0

	# Línea de visión (las paredes la bloquean)
	var eye := global_position + Vector3(0, 1.6, 0)
	var tgt := target.global_position + Vector3(0, eye_h, 0)
	if not _line_of_sight(eye, tgt):
		return 0.0

	return 0.4 + 0.6 * (1.0 - dist / max_dist)


# =====================================================================
#  IA + física
# =====================================================================
func _physics_process(delta: float) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if dead:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		move_and_slide()
		return

	attack_cd = maxf(attack_cd - delta, 0.0)
	stun_t = maxf(stun_t - delta, 0.0)

	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node3D
	var player_alive: bool = target != null and not target.get("dead")

	# --- Percepción: la sospecha sube si te ve y baja si no ---
	var vis := 0.0
	if player_alive:
		vis = _vision_amount()
	if vis > 0.0:
		suspicion = minf(suspicion + delta * vis / NOTICE_TIME, 1.0)
		last_seen = target.global_position
	elif state != State.CHASE:
		suspicion = maxf(suspicion - delta * 0.35, 0.0)

	if not player_alive:
		if state != State.PATROL:
			state = State.PATROL
			home = global_position
			_pick_patrol()
		suspicion = 0.0
	elif suspicion >= 1.0 and state != State.CHASE:
		_start_chase()

	# --- Comportamiento según el estado ---
	var desired := Vector3.ZERO
	match state:
		State.PATROL:
			desired = _do_patrol(delta)
		State.CHASE:
			desired = _do_chase(delta, vis)
		State.SEARCH:
			desired = _do_search(delta)

	var accel := 10.0 if stun_t <= 0.0 else 4.0
	velocity.x = move_toward(velocity.x, desired.x, accel * delta)
	velocity.z = move_toward(velocity.z, desired.z, accel * delta)
	move_and_slide()
	_update_indicator()


func _process(delta: float) -> void:
	var duel := get_node_or_null("BossDuelController")
	var neutral: bool = duel != null and duel.state != duel.DuelState.COMBAT
	# Sin física neutral no hay is_on_floor fiable: evitar pose de salto en la intro.
	body.animate(delta,Vector3.ZERO if neutral else velocity,true if neutral else is_on_floor(),false)


func _face(dir: Vector3, speed: float, delta: float) -> void:
	body.rotation.y = lerp_angle(body.rotation.y, atan2(-dir.x, -dir.z), speed * delta)


# ---------- PATRULLA ----------
func _pick_patrol() -> void:
	var a := randf() * TAU
	patrol_target = home + Vector3(sin(a), 0.0, cos(a)) * randf_range(3.0, 8.0)
	patrol_wait = randf_range(2.0, 4.5)
	patrol_walk_t = 0.0
	idle_yaw = randf() * TAU


func _do_patrol(delta: float) -> Vector3:
	# Notó algo: se detiene y mira hacia allá
	if suspicion > 0.2:
		var look := last_seen - global_position
		look.y = 0.0
		if look.length() > 0.01:
			_face(look.normalized(), 6.0, delta)
		return Vector3.ZERO

	# Se queda quieto mirando alrededor
	if patrol_wait > 0.0:
		patrol_wait -= delta
		body.rotation.y = lerp_angle(body.rotation.y, idle_yaw, 1.5 * delta)
		return Vector3.ZERO

	# Camina hacia un punto cercano
	var to := patrol_target - global_position
	to.y = 0.0
	patrol_walk_t += delta
	if to.length() < 0.7 or patrol_walk_t > 7.0:
		_pick_patrol()
		return Vector3.ZERO
	var dir := to.normalized()
	_face(dir, 5.0, delta)
	return dir * PATROL_SPEED


# ---------- PERSECUCIÓN ----------
func _start_chase() -> void:
	state = State.CHASE
	lost_t = 0.0
	suspicion = 1.0
	_alert_nearby()


## Avisa a los enemigos cercanos de dónde te vieron.
func _alert_nearby() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Node3D
		if en == null or en == self:
			continue
		if en.global_position.distance_to(global_position) < 10.0 and en.has_method("alert"):
			en.alert(last_seen)


func alert(pos: Vector3) -> void:
	if dead or state == State.CHASE:
		return
	last_seen = pos
	state = State.CHASE
	lost_t = 0.0
	suspicion = 1.0


func _do_chase(delta: float, vis: float) -> Vector3:
	var seeing := vis > 0.0
	if seeing:
		lost_t = 0.0
		suspicion = 1.0
	else:
		lost_t += delta

	# Va hacia ti si te ve; si no, hacia donde te vio por última vez
	var to := last_seen - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > 0.001:
		var dir := to / dist
		_face(dir, 8.0, delta)
		if stun_t <= 0.0:
			if seeing and dist <= ATTACK_RANGE:
				if attack_cd <= 0.0 and body.start_punch():
					attack_cd = ATTACK_COOLDOWN + randf() * 0.6
				return Vector3.ZERO
			if dist > (ATTACK_RANGE * 0.9 if seeing else 0.8):
				return dir * CHASE_SPEED

	# Te perdió de vista y ya llegó al último lugar donde te vio
	if not seeing and (dist <= 0.8 or lost_t > 8.0):
		state = State.SEARCH
		search_t = 4.0
		suspicion = 0.5
	return Vector3.ZERO


# ---------- BÚSQUEDA ----------
func _do_search(delta: float) -> Vector3:
	search_t -= delta
	body.rotation.y += sin(search_t * 2.0) * 1.6 * delta   # mira a izquierda y derecha
	if search_t <= 0.0:
		state = State.PATROL
		suspicion = 0.0
		home = global_position
		_pick_patrol()
	return Vector3.ZERO


# =====================================================================
#  Combate
# =====================================================================
## Su golpe conecta solo si sigues cerca y delante (si te alejas, lo esquivas).
func _on_punch_landed(_side: int) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	if dead or target == null or not is_instance_valid(target):
		return
	var to := target.global_position - global_position
	if absf(to.y) > 2.0 or not _line_of_sight(global_position + Vector3.UP, target.global_position + Vector3.UP):
		return
	to.y = 0.0
	var dist := to.length()
	if dist > ATTACK_HIT_RANGE:
		return
	if dist > 0.01 and body.forward().dot(to / dist) < 0.3:
		return
	if target.has_method("take_hit"):
		target.take_hit(to.normalized(), ATTACK_DAMAGE)


## Recibir daño (lo llama el jugador). Un golpe por la espalda también lo alerta.
func take_hit(direction: Vector3, damage: float) -> void:
	var duel := get_node_or_null("BossDuelController")
	if duel != null and not duel.allows_damage():
		return
	if dead:
		return
	health = maxf(health - damage, 0.0)
	body.hurt()
	body.react_to_hit(direction,damage)
	stun_t = STUN_TIME
	velocity.x += direction.x * 3.5
	velocity.z += direction.z * 3.5
	_update_bar()
	if health <= 0.0:
		_die()
		return
	if target != null and is_instance_valid(target):
		last_seen = target.global_position
	if state != State.CHASE:
		_start_chase()


func _die() -> void:
	dead = true
	remove_from_group("enemy")     # el jugador ya no lo apunta
	body.die()
	bar_root.visible = false
	alert_label.visible = false
	collision_layer = 0            # se puede atravesar; sigue chocando con el suelo
	died.emit(self)
	# Los bosses de campaña conservan su cuerpo derrotado en el campus.
	if get_node_or_null("BossDuelController") != null:
		return
	await get_tree().create_timer(4.0).timeout
	queue_free()
