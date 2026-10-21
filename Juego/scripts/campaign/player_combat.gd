extends Node
var player: CharacterBody3D
var stamina := 100.0
var max_stamina := 100.0
var dodge_t := 0.0
var dodge_cd := 0.0
var dodge_direction := Vector3.ZERO
var charging := false
var charge_t := 0.0
var heavy := false
var normal_swing := 0.5
var bar: ProgressBar

func _ready() -> void:
	player = get_parent()
	var layer := CanvasLayer.new()
	add_child(layer)
	bar = ProgressBar.new()
	bar.position = Vector2(20,420)
	bar.custom_minimum_size = Vector2(150,12)
	bar.show_percentage = false
	layer.add_child(bar)

func _process(delta: float) -> void:
	dodge_t = maxf(0,dodge_t-delta)
	dodge_cd = maxf(0,dodge_cd-delta)
	if charging and not player.busy and not player.dead:
		charge_t += delta
	if player.running and Vector2(player.velocity.x,player.velocity.z).length() > 2.7 and not player.busy:
		stamina = maxf(0,stamina-14*delta)
	else:
		stamina = minf(max_stamina,stamina+22*delta)
	bar.max_value = max_stamina
	bar.value = stamina
	if heavy and not player.body.is_punching():
		heavy = false
		player.attack_multiplier = 1.0
		player.body.punch_time = player.weapon.swing_time if player.weapon != null else 0.5
	if player.dead or player.busy:
		charging = false

func _input(event: InputEvent) -> void:
	if player.dead or player.busy or get_tree().paused:
		return
	var seating := player.get_node_or_null("SeatController")
	if seating and is_instance_valid(seating.seat):
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventKey and event.physical_keycode == KEY_ALT):
			if event.pressed:
				seating.stand()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ALT:
		dodge()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		if event.pressed:
			charging = true
			charge_t = 0
		elif charging:
			charging = false
			if player.punch_cd > 0 or player.stun_t > 0 or player.body.is_punching():
				return
			heavy = charge_t >= 0.45 and stamina >= 30
			if heavy:
				stamina -= 30
				player.attack_multiplier = 1.8
				normal_swing = player.body.punch_time
				player.body.punch_time = normal_swing*1.4
			else:
				player.attack_multiplier = 1.0
			player._try_punch()

func dodge() -> bool:
	var seating := player.get_node_or_null("SeatController")
	if seating and is_instance_valid(seating.seat):
		seating.stand()
		return false
	if dodge_cd > 0 or stamina < 25 or player.stun_t > 0:
		return false
	var input := Input.get_vector("move_left","move_right","move_forward","move_back")
	dodge_direction = Vector3(input.x,0,input.y).rotated(Vector3.UP,player.cam_yaw)
	if dodge_direction.length() < 0.1:
		dodge_direction = -player.body.forward()
	dodge_direction = dodge_direction.normalized()
	dodge_t = 0.22
	dodge_cd = 0.7
	stamina -= 25
	return true
