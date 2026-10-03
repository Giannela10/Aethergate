extends CharacterBody3D
## Jugador. Usa humanoid.gd para el cuerpo y las animaciones.
##
## Controles:
##   WASD / flechas = mover (relativo a la cámara)   Shift = correr
##   C / Ctrl = agacharse (los enemigos te ven peor)  Espacio = saltar
##   J / clic izquierdo = golpear
##   E = recoger arma / usar computador    G = soltar arma
##   Ratón = cámara    Esc = liberar el ratón    R = reiniciar

signal health_changed(hp: float, max_hp: float)
signal weapon_changed(text: String)
signal weapon_broke(weapon_name: String)
signal computer_requested(computer)   # pidió usar un computador (main abre el minijuego)
signal hit_received                   # recibió un golpe (interrumpe el minijuego)
signal died

const Humanoid = preload("res://humanoid.gd")

# ---------- Ajustes (cámbialos a tu gusto) ----------
const WALK_SPEED := 2.5
const RUN_SPEED := 5.5
const CROUCH_SPEED := 1.3
const JUMP_VELOCITY := 5.0
const GRAVITY := 14.0

const PUNCH_DAMAGE := 10.0       # daño con las manos
const PUNCH_RANGE := 1.5         # alcance con las manos
const PUNCH_COOLDOWN := 0.32     # tiempo mínimo entre puñetazos
const WEAPON_COOLDOWN := 0.45    # tiempo mínimo entre golpes con arma
const AIM_ASSIST_RANGE := 3.2    # si hay un enemigo cerca, te gira hacia él al golpear
const PICKUP_RANGE := 1.8        # alcance para recoger armas
const COMPUTER_RANGE := 2.2      # alcance para usar computadores

var max_health := 100.0
var health := 100.0
var dead := false
var busy := false                # true mientras usas un computador (no te puedes mover)

var cam_yaw := 0.0               # lo asigna main.gd (la cámara)
var body: Humanoid
var collision: CollisionShape3D
var capsule: CapsuleShape3D

var weapon = null                # arma equipada (weapon.gd) o null
var crouching := false
var running := false
var stun_t := 0.0
var punch_cd := 0.0


func _ready() -> void:
	add_to_group("player")
	_setup_input()

	collision = CollisionShape3D.new()
	capsule = CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.7
	collision.shape = capsule
	collision.position.y = 1.35
	add_child(collision)

	body = Humanoid.new()
	body.scale = Vector3(1.5, 1.5, 1.5)
	body.punch_time = 0.5
	add_child(body)
	body.punch_landed.connect(_on_punch_landed)

	health_changed.emit(health, max_health)


# =====================================================================
#  Controles (se crean por código para no tener que configurarlos)
# =====================================================================
func _setup_input() -> void:
	var actions := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"crouch": [KEY_C, KEY_CTRL],
		"run": [KEY_SHIFT],
		"punch": [KEY_J],
		"interact": [KEY_E],
		"drop": [KEY_G],
	}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in actions[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("punch", mb)


# =====================================================================
#  Física / movimiento
# =====================================================================
func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	stun_t = maxf(stun_t - delta, 0.0)
	punch_cd = maxf(punch_cd - delta, 0.0)

	if not on_floor:
		velocity.y -= GRAVITY * delta

	if dead:
		running = false
		crouching = false
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		move_and_slide()
		return

	# Usando un computador: quieto y sin atender controles
	if busy:
		running = false
		crouching = false
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		move_and_slide()
		return

	crouching = Input.is_action_pressed("crouch") and on_floor

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	running = Input.is_action_pressed("run") and not crouching and input.length() > 0.1

	var speed := WALK_SPEED
	if crouching:
		speed = CROUCH_SPEED
	elif running:
		speed = RUN_SPEED
	if body.is_punching():
		speed *= 0.6

	# Movimiento relativo a la cámara
	var dir := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, cam_yaw)
	var target := Vector2(dir.x, dir.z) * speed
	var accel := 14.0 if on_floor else 4.0
	if stun_t > 0.0:
		target = Vector2.ZERO
		accel = 5.0
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.y, accel * delta)

	if on_floor and stun_t <= 0.0 and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("punch") and punch_cd <= 0.0 and stun_t <= 0.0:
		_try_punch()
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("drop"):
		_drop()

	move_and_slide()

	# Girar el cuerpo hacia donde camina (no mientras golpea, para mantener la guardia)
	if not body.is_punching() and stun_t <= 0.0 \
			and Vector2(velocity.x, velocity.z).length() > 0.2:
		var target_yaw := atan2(-velocity.x, -velocity.z)
		body.rotation.y = lerp_angle(body.rotation.y, target_yaw, 10.0 * delta)


func _process(delta: float) -> void:
	body.animate(delta, velocity, is_on_floor(), crouching)

	# Colisión más baja al agacharse
	var h := lerpf(1.8, 1.15, body.crouch_amt)
	capsule.height = h
	collision.position.y = h * 0.5


# =====================================================================
#  Combate
# =====================================================================
func _try_punch() -> void:
	if body.start_punch():
		punch_cd = WEAPON_COOLDOWN if weapon != null else PUNCH_COOLDOWN
		_aim_assist()


## Si hay un enemigo cerca, gira hacia él para que el golpe conecte.
func _aim_assist() -> void:
	var best: Node3D = null
	var best_d := AIM_ASSIST_RANGE
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Node3D
		if en == null:
			continue
		var d := en.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = en
	if best != null:
		var to := best.global_position - global_position
		body.rotation.y = atan2(-to.x, -to.z)


## Se llama en el instante en que el golpe conecta.
func _on_punch_landed(_side: int) -> void:
	var dmg := PUNCH_DAMAGE
	var reach := PUNCH_RANGE
	if weapon != null:
		dmg = weapon.damage
		reach = weapon.reach

	var fwd := body.forward()
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Node3D
		if en == null or not en.has_method("take_hit"):
			continue
		var to := en.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if dist > reach:
			continue
		if dist > 0.01 and fwd.dot(to / dist) < 0.35:   # debe estar delante
			continue
		en.take_hit(to.normalized(), dmg)
		hit_any = true

	if hit_any and weapon != null:
		_use_weapon()


## Gasta durabilidad del arma; si llega a 0 se rompe.
func _use_weapon() -> void:
	weapon.durability -= 1
	if weapon.durability <= 0:
		var broken_name: String = weapon.weapon_name
		var w = body.unequip()
		if w != null:
			w.queue_free()
		weapon = null
		body.punch_time = 0.5
		_emit_weapon()
		weapon_broke.emit(broken_name)
	else:
		_emit_weapon()


## Recibir daño (lo llaman los enemigos).
func take_hit(direction: Vector3, damage: float) -> void:
	if dead:
		return
	hit_received.emit()
	health = maxf(health - damage, 0.0)
	body.hurt()
	stun_t = 0.25
	velocity.x += direction.x * 4.0
	velocity.z += direction.z * 4.0
	health_changed.emit(health, max_health)
	if health <= 0.0:
		dead = true
		crouching = false
		body.die()
		died.emit()


## Recuperar vida (por ejemplo al completar una tarea).
func heal(amount: float) -> void:
	if dead:
		return
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)


# =====================================================================
#  Interactuar: armas y computadores
# =====================================================================
func _emit_weapon() -> void:
	if weapon == null:
		weapon_changed.emit("Puños")
	else:
		var n: String = weapon.weapon_name
		var d: int = weapon.durability
		weapon_changed.emit("%s (%d)" % [n, d])


## E: usa lo más cercano entre un arma del suelo y un computador pendiente.
func _try_interact() -> void:
	var best_weapon: Node3D = null
	var best_wd := PICKUP_RANGE
	for w in get_tree().get_nodes_in_group("weapon_pickup"):
		var wn := w as Node3D
		if wn == null:
			continue
		var d := wn.global_position.distance_to(global_position)
		if d < best_wd:
			best_wd = d
			best_weapon = wn

	var best_pc: Node3D = null
	var best_cd := COMPUTER_RANGE
	for c in get_tree().get_nodes_in_group("computer"):
		var cn := c as Node3D
		if cn == null or cn.get("done"):
			continue
		var d := cn.global_position.distance_to(global_position)
		if d < best_cd:
			best_cd = d
			best_pc = cn

	if best_pc != null and (best_weapon == null or best_cd < best_wd):
		_use_computer(best_pc)
	elif best_weapon != null:
		_equip(best_weapon)


func _use_computer(c: Node3D) -> void:
	var to := c.global_position - global_position
	body.rotation.y = atan2(-to.x, -to.z)      # mira hacia el computador
	velocity.x = 0.0
	velocity.z = 0.0
	computer_requested.emit(c)


func _equip(w) -> void:
	if weapon != null:
		_drop()                          # cambia el arma actual por la nueva
	w.pick_up()
	w.get_parent().remove_child(w)
	body.equip(w)
	weapon = w
	body.punch_time = w.swing_time
	_emit_weapon()


func _drop() -> void:
	if weapon == null:
		return
	var w = body.unequip()
	weapon = null
	body.punch_time = 0.5
	if w != null:
		get_parent().add_child(w)
		var p := global_position + body.forward() * 1.0
		p.y = 0.0
		w.global_position = p
		w.rotation = Vector3.ZERO
		w.put_down()
	_emit_weapon()
