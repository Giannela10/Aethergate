extends CharacterBody3D
## Jugador. Usa humanoid.gd para el cuerpo y las animaciones.
##
## Controles:
##   WASD / flechas = mover (relativo a la cÃƒÆ’Ã‚Â¡mara)   Shift = correr
##   C / Ctrl = agacharse (los enemigos te ven peor)  Espacio = saltar
##   J / clic izquierdo = golpear
##   E = recoger arma / usar computador    G = soltar arma
##   RatÃƒÆ’Ã‚Â³n = cÃƒÆ’Ã‚Â¡mara    Esc = liberar el ratÃƒÆ’Ã‚Â³n    R = reiniciar

signal health_changed(hp: float, max_hp: float)
signal weapon_changed(text: String)
signal weapon_broke(weapon_name: String)
signal computer_requested(computer)   # pidiÃƒÆ’Ã‚Â³ usar un computador (main abre el minijuego)
signal hit_received                   # recibiÃƒÆ’Ã‚Â³ un golpe (interrumpe el minijuego)
signal died

const Humanoid = preload("res://scripts/juego/humanoid.gd")
const SportsProjectile = preload("res://scripts/juego/proyectil_deportivo.gd")
const StudentVisual = preload("res://scripts/juego/student_visual.gd")
@export var persist_inventory := true
var inventory: Node
var inventory_ui: CanvasLayer
var speed_multiplier := 1.0
var speed_boost_time := 0.0
var attack_multiplier := 1.0
var progression_damage := 1.0
var progression_speed := 1.0

# ---------- Ajustes (cÃƒÆ’Ã‚Â¡mbialos a tu gusto) ----------
const WALK_SPEED := 2.5
const RUN_SPEED := 5.5
const CROUCH_SPEED := 1.3
const JUMP_VELOCITY := 5.0
const GRAVITY := 14.0

const PUNCH_DAMAGE := 10.0       # daÃƒÆ’Ã‚Â±o con las manos
const PUNCH_RANGE := 1.5         # alcance con las manos
const PUNCH_COOLDOWN := 0.32     # tiempo mÃƒÆ’Ã‚Â­nimo entre puÃƒÆ’Ã‚Â±etazos
const WEAPON_COOLDOWN := 0.45    # tiempo mÃƒÆ’Ã‚Â­nimo entre golpes con arma
const AIM_ASSIST_RANGE := 3.2    # si hay un enemigo cerca, te gira hacia ÃƒÆ’Ã‚Â©l al golpear
const PICKUP_RANGE := 1.8        # alcance para recoger armas
const COMPUTER_RANGE := 2.2      # alcance para usar computadores

var max_health := 100.0
var health := 100.0
var dead := false
var busy := false                # true mientras usas un computador (no te puedes mover)

var cam_yaw := 0.0               # lo asigna main.gd (la cÃƒÆ’Ã‚Â¡mara)
var body: Humanoid
var collision: CollisionShape3D
var capsule: CapsuleShape3D
var standing_capsule: CapsuleShape3D

var stationery_inventory: Dictionary = {}
var equipped_stationery := ""
var stationery_notes := ""
var stationery_model: Node3D
var stationery_ui: CanvasLayer

var weapon = null                # arma equipada (weapon.gd) o null
var crouching := false
var running := false
var stun_t := 0.0
var punch_cd := 0.0


func _ready() -> void:
	name = "Player"
	add_to_group("player")
	_setup_input()
	floor_snap_length = 0.5

	collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	capsule = CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.7
	standing_capsule = capsule.duplicate()
	collision.shape = capsule
	collision.position.y = 1.35
	add_child(collision)

	body = StudentVisual.new()
	body.name = "CharacterVisual"
	body.scale = Vector3(1.5, 1.5, 1.5)
	body.punch_time = 0.5
	add_child(body)
	body.punch_landed.connect(_on_punch_landed)
	load_stationery()
	stationery_ui = CanvasLayer.new()
	stationery_ui.set_script(load("res://scripts/pisos/piso_1/inventario_papeleria.gd"))
	add_child(stationery_ui)
	stationery_ui.name = "LegacyStationeryUI"
	stationery_ui.set_process_input(false)
	stationery_ui.hide()
	var pivot := Marker3D.new()
	pivot.name = "CameraPivot"
	pivot.position.y = 1.4
	add_child(pivot)
	var area := Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 0
	area.collision_mask = 0
	area.monitoring = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = PICKUP_RANGE
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	inventory = load("res://scripts/inventory/inventory.gd").new()
	inventory.name = "Inventory"
	inventory.persist = persist_inventory
	add_child(inventory)
	inventory_ui = load("res://scripts/inventory/inventory_ui.gd").new()
	inventory_ui.name = "InventoryUI"
	add_child(inventory_ui)

	health_changed.emit(health, max_health)


# =====================================================================
#  Controles (se crean por cÃƒÆ’Ã‚Â³digo para no tener que configurarlos)
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
		"throw_sport": [KEY_Q],
	}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in actions[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)

	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	if not InputMap.action_has_event("punch", mb):
		InputMap.action_add_event("punch", mb)


# =====================================================================
#  FÃƒÆ’Ã‚Â­sica / movimiento
# =====================================================================
func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	speed_boost_time = maxf(0.0,speed_boost_time-delta)
	if speed_boost_time <= 0.0:
		speed_multiplier = 1.0
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

	var seating := get_node_or_null("SeatController")
	if seating and seating.update_seated():
		return

	# Usando un computador: quieto y sin atender controles
	if busy:
		running = false
		crouching = false
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		move_and_slide()
		return

	var combat := get_node_or_null("CombatExtensions")
	if combat and combat.dodge_t > 0:
		velocity.x = combat.dodge_direction.x*8.0
		velocity.z = combat.dodge_direction.z*8.0
		move_and_slide()
		return
	var wants_crouch := Input.is_action_pressed("crouch") and on_floor
	crouching = wants_crouch or (crouching and not _has_standing_room())

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	running = Input.is_action_pressed("run") and (combat == null or combat.stamina > 0) and not crouching and input.length() > 0.1

	var speed := WALK_SPEED
	if crouching:
		speed = CROUCH_SPEED
	elif running:
		speed = RUN_SPEED
	speed *= speed_multiplier * progression_speed
	if body.is_punching():
		speed *= 0.6

	# Movimiento relativo a la cÃƒÆ’Ã‚Â¡mara
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
		if combat == null or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_try_punch()
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("drop"):
		_drop()
	if Input.is_action_just_pressed("throw_sport") and punch_cd <= 0.0 and stun_t <= 0.0:
		_throw_sport()

	move_and_slide()

	# Girar el cuerpo hacia donde camina (no mientras golpea, para mantener la guardia)
	if not body.is_punching() and stun_t <= 0.0 \
			and Vector2(velocity.x, velocity.z).length() > 0.2:
		var target_yaw := atan2(-velocity.x, -velocity.z)
		body.rotation.y = lerp_angle(body.rotation.y, target_yaw, 10.0 * delta)


func _process(delta: float) -> void:
	body.animate(delta, velocity, is_on_floor(), crouching)

	# ColisiÃƒÆ’Ã‚Â³n mÃƒÆ’Ã‚Â¡s baja al agacharse
	var h := lerpf(2.7, 1.725, body.crouch_amt)
	capsule.height = h
	collision.position.y = h * 0.5


func _has_standing_room() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = standing_capsule
	query.transform = global_transform
	query.transform.origin = global_transform * Vector3(0, 1.375, 0)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.margin = 0.001
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


# =====================================================================
#  Combate
# =====================================================================
func _try_punch() -> void:
	var seating := get_node_or_null("SeatController")
	if seating and is_instance_valid(seating.seat):
		seating.stand()
		return
	if body.start_punch():
		punch_cd = WEAPON_COOLDOWN if weapon != null else PUNCH_COOLDOWN
		_aim_assist()


## Si hay un enemigo cerca, gira hacia ÃƒÆ’Ã‚Â©l para que el golpe conecte.
func _aim_assist() -> void:
	var best: Node3D = null
	var best_d := AIM_ASSIST_RANGE
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Node3D
		if en == null:
			continue
		if en.get("dead") == true or absf(en.global_position.y - global_position.y) > 2.0 or not _can_reach(en):
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
	if dead or busy:
		return
	var dmg := PUNCH_DAMAGE
	var reach := PUNCH_RANGE
	if weapon != null:
		dmg = weapon.damage
		reach = weapon.reach

	var fwd := body.forward()
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Node3D
		if en == null or en.get("dead") == true or not en.has_method("take_hit"):
			continue
		var to := en.global_position - global_position
		if absf(to.y) > 2.0 or not _can_reach(en):
			continue
		to.y = 0.0
		var dist := to.length()
		if dist > reach:
			continue
		if dist > 0.01 and fwd.dot(to / dist) < 0.35:   # debe estar delante
			continue
		var bonus: float = weapon.bonus_against(en) if weapon != null and weapon.has_method("bonus_against") else 1.0
		en.take_hit(to.normalized(), dmg * attack_multiplier * progression_damage * bonus)
		hit_any = true

	if hit_any and weapon != null:
		_use_weapon()


## Impide golpear o interactuar a través de paredes y losas.
func _can_reach(target: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.2, target.global_position + Vector3.UP * 1.2)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider := hit.get("collider") as Node
	return collider == target or (collider != null and target.is_ancestor_of(collider))


## Gasta durabilidad del arma; si llega a 0 se rompe.
func _use_weapon() -> void:
	weapon.durability -= 1
	if weapon.durability <= 0:
		var broken_name: String = weapon.weapon_name
		if inventory != null:
			inventory.detach_equipped()
		var w = body.unequip()
		if w != null:
			w.queue_free()
		weapon = null
		body.punch_time = 0.5
		_emit_weapon()
		weapon_broke.emit(broken_name)
	else:
		_emit_weapon()
	if inventory != null:
		inventory._commit()


## Recibir daÃƒÆ’Ã‚Â±o (lo llaman los enemigos).
func take_hit(direction: Vector3, damage: float) -> void:
	var combat := get_node_or_null("CombatExtensions")
	if combat and combat.dodge_t > 0:
		return
	if dead:
		return
	hit_received.emit()
	health = maxf(health - damage, 0.0)
	body.hurt()
	body.react_to_hit(direction,damage)
	stun_t = 0.25
	var academic_push := 0.9 if inventory != null and inventory.has_item("ProtectorDental",1) else 1.0
	velocity.x += direction.x * 4.0 * academic_push
	velocity.z += direction.z * 4.0 * academic_push
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
	if not equipped_stationery.is_empty():
		weapon_changed.emit(load("res://scripts/pisos/piso_1/inventario_papeleria.gd").ITEMS[equipped_stationery] + " · F: usar")
	elif weapon == null:
		weapon_changed.emit("Puños")
	else:
		var n: String = weapon.weapon_name
		var d: int = weapon.durability
		if weapon.has_method("can_throw") and weapon.can_throw():
			n += " · Q: lanzar"
		weapon_changed.emit("%s (%d)" % [n, d])

func _throw_sport(confirmed: bool = false) -> void:
	if weapon != null and inventory != null and inventory.discard_protected(inventory.equipped_uid):
		var entry: Dictionary = inventory.entry_for(inventory.equipped_uid)
		if entry.get("favorite",false):
			inventory.notice.emit("Desmarca el favorito para lanzarlo.")
			return
		if not confirmed:
			var campaign := get_tree().get_first_node_in_group("campus_campaign")
			if campaign != null and campaign.live != null: campaign.live.qol.confirm_discard(_throw_sport.bind(true),"lanzar")
			return
	if not dead and not busy and weapon == null:
		var campaign := get_tree().get_first_node_in_group("campus_campaign")
		if campaign:
			campaign.throw_distraction()
		return
	if dead or busy or weapon == null or body.is_punching():
		return
	if not weapon.has_method("can_throw") or not weapon.can_throw():
		return
	var direction := Vector3.FORWARD.rotated(Vector3.UP, cam_yaw)
	var origin := global_position + Vector3.UP * 1.6 + direction * 0.7
	var destination := origin + direction * 14.0
	var best_distance := 18.0
	# Asistencia de puntería solo delante del jugador y con línea de visión.
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var en := enemy as Node3D
		if en == null or en.get("dead") == true:
			continue
		var offset := en.global_position - global_position
		if absf(offset.y) > 3 or offset.length() >= best_distance:
			continue
		if offset.normalized().dot(direction) < 0.65:
			continue
		var point := en.global_position + Vector3.UP * 1.3
		var query := PhysicsRayQueryParameters3D.create(origin, point)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		var collider := hit.get("collider") as Node
		if not hit.is_empty() and collider != en and not (collider and en.is_ancestor_of(collider)):
			continue
		best_distance = offset.length()
		destination = point
	if inventory != null:
		inventory.detach_equipped()
	var item = body.unequip()
	weapon = null
	body.punch_time = 0.5
	var projectile := SportsProjectile.new()
	projectile.equipment = item
	projectile.sport = item.sport
	projectile.damage = item.damage + 8.0
	projectile.targets_enemies = true
	projectile.shooter = self
	get_parent().add_child(projectile)
	projectile.launch(origin, destination, 16.0)
	body.start_punch()
	body.request_visual_state("THROW",0.45)
	punch_cd = 0.6
	_emit_weapon()


## E: usa lo mÃƒÆ’Ã‚Â¡s cercano entre un arma del suelo y un computador pendiente.
func _try_interact() -> void:
	var centralized := get_node_or_null("InteractionController")
	if centralized:
		centralized.interact_selected()
		return
	for vendor in get_tree().get_nodes_in_group("stationery_vendor"):
		if global_position.distance_to(vendor.global_position) < 4.5 and _can_reach(vendor):
			vendor.interact(self)
			return
	var best_weapon: Node3D = null
	var best_wd := PICKUP_RANGE
	for w in get_tree().get_nodes_in_group("weapon_pickup"):
		var wn := w as Node3D
		if wn == null:
			continue
		var d := wn.global_position.distance_to(global_position)
		if d < best_wd and _can_reach(wn):
			best_wd = d
			best_weapon = wn

	var best_pc: Node3D = null
	var best_cd := COMPUTER_RANGE
	for c in get_tree().get_nodes_in_group("computer"):
		var cn := c as Node3D
		if cn == null or cn.get("done"):
			continue
		var d := cn.global_position.distance_to(global_position)
		if d < best_cd and _can_reach(cn):
			best_cd = d
			best_pc = cn

	var best_item: Node3D
	var best_id := PICKUP_RANGE
	for item in get_tree().get_nodes_in_group("inventory_pickup"):
		if item is Node3D and not item.is_queued_for_deletion():
			var d := global_position.distance_to(item.global_position)
			if d < best_id and _can_reach(item):
				best_item = item
				best_id = d
	if best_item != null and (best_weapon == null or best_id <= best_wd) and (best_pc == null or best_id <= best_cd):
		best_item.collect(self)
	elif best_pc != null and (best_weapon == null or best_cd < best_wd):
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
	if inventory != null:
		inventory.collect_weapon(w,true)
		return
	equip_stationery("")
	if weapon != null:
		_drop()                          # cambia el arma actual por la nueva
	w.pick_up()
	w.get_parent().remove_child(w)
	body.equip(w)
	weapon = w
	body.punch_time = w.swing_time
	_emit_weapon()


func _drop(confirmed: bool = false) -> void:
	if not equipped_stationery.is_empty():
		equip_stationery("")
		return
	if weapon == null:
		return
	if inventory != null and inventory.discard_protected(inventory.equipped_uid):
		var entry: Dictionary = inventory.entry_for(inventory.equipped_uid)
		if entry.get("favorite",false):
			inventory.notice.emit("Desmarca el favorito para soltarlo.")
			return
		if not confirmed:
			var campaign := get_tree().get_first_node_in_group("campus_campaign")
			if campaign != null and campaign.live != null: campaign.live.qol.confirm_discard(_drop.bind(true))
			return
	if inventory != null:
		inventory.detach_equipped()
	var w = body.unequip()
	weapon = null
	body.punch_time = 0.5
	if w != null:
		get_parent().add_child(w)
		var p := global_position + body.forward() * 1.0
		var query := PhysicsRayQueryParameters3D.create(p + Vector3.UP, p + Vector3.DOWN * 4.0)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.normal.y > 0.55:
			p = hit.position + Vector3.UP * 0.025
		w.global_position = p
		w.rotation = Vector3.ZERO
		w.put_down()
	_emit_weapon()

func receive_stationery(key: String) -> int:
	if inventory != null:
		return inventory.add_item(key,1)
	if not load("res://scripts/pisos/piso_1/inventario_papeleria.gd").ITEMS.has(key):
		return 0
	stationery_inventory[key] = int(stationery_inventory.get(key,0))+1
	save_stationery()
	return stationery_inventory[key]
func equip_stationery(key: String) -> bool:
	if not key.is_empty() and (not load("res://scripts/pisos/piso_1/inventario_papeleria.gd").ITEMS.has(key) or stationery_inventory.get(key,0)<=0): return false
	if is_instance_valid(stationery_model): stationery_model.free()
	stationery_model = null
	equipped_stationery = ""
	if not key.is_empty() and weapon != null:
		if inventory != null:
			inventory.stash_equipped()
		else:
			_drop()
	equipped_stationery = key
	if not key.is_empty():
		stationery_model = Node3D.new()
		stationery_model.name = "ArticuloEquipado"
		var socket = body.get("item_socket")
		if is_instance_valid(socket):
			socket.add_child(stationery_model)
		else:
			body.hand_r.add_child(stationery_model)
		if key == "lapiz":
			var pencil := CylinderMesh.new()
			pencil.top_radius = 0.009
			pencil.bottom_radius = 0.009
			pencil.height = 0.24
			stationery_part(pencil,Vector3(0,-0.06,0),Color(0.95,0.7,0.08))
		else:
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.22,0.045 if key == "cuaderno" else 0.008,0.3) if key != "goma" else Vector3(0.12,0.07,0.06)
			stationery_part(mesh,Vector3(0,-0.015,-0.1),Color(0.15,0.35,0.7) if key == "cuaderno" else Color(0.92,0.93,0.91) if key == "hoja_impresa" else Color(0.92,0.45,0.55))
			if key in ["cuaderno","hoja_impresa"]:
				for i in range(5):
					var line := BoxMesh.new()
					line.size = Vector3(0.15,0.002,0.004)
					stationery_part(line,Vector3(0,0.01 if key == "cuaderno" else -0.009,-0.19+i*0.035),Color(0.2,0.22,0.27))
	save_stationery()
	_emit_weapon()
	return true
func receive_item(id: String, amount: int = 1) -> int:
	return inventory.add_item(id,amount) if inventory != null else 0

func has_key_item(id: String) -> bool:
	if inventory != null and inventory.has_item(id):
		return true
	return id == "CredencialDirector" and bool(get_meta("CredencialDirector",false))

func apply_speed_boost(multiplier: float, duration: float) -> void:
	speed_multiplier = clampf(multiplier,1.0,2.0)
	speed_boost_time = maxf(duration,0.0)

func stationery_part(mesh: Mesh, position_value: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = position_value
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	part.material_override = material
	stationery_model.add_child(part)
func save_stationery() -> void:
	if not persist_inventory:
		return
	var file := FileAccess.open("user://papeleria_inventario.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"items":stationery_inventory,"notes":stationery_notes,"equipped":equipped_stationery}))
func load_stationery() -> void:
	if not persist_inventory:
		return
	if not FileAccess.file_exists("user://papeleria_inventario.json"): return
	var data = preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary("user://papeleria_inventario.json")
	if not data is Dictionary: return
	var saved_items = data.get("items",{})
	if saved_items is Dictionary:
		for key in load("res://scripts/pisos/piso_1/inventario_papeleria.gd").ITEMS:
			var count = saved_items.get(key, 0)
			stationery_inventory[key] = clampi(int(count), 0, 9999) if count is int or count is float else 0
	stationery_notes = str(data.get("notes",""))
	equip_stationery(str(data.get("equipped","")))
