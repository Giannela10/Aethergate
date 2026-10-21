extends "res://scripts/juego/enemy.gd"
@export_enum("NORMAL","RAPIDO","PESADO","DISTANCIA","TECNOLOGICO") var variant := "NORMAL"
@export var floor_number := 1
var hp_max := 100.0
var speed_factor := 1.0
var melee_damage := 8.0
var shot_cd := 2.0
var minions: Array = []

func _ready() -> void:
	super._ready()
	hp_max = 60+floor_number*8
	speed_factor = 0.8+floor_number*0.04
	melee_damage = 5+floor_number
	if variant == "RAPIDO":
		hp_max *= 0.65
		speed_factor *= 1.35
	elif variant == "PESADO":
		hp_max *= 1.7
		speed_factor *= 0.7
		melee_damage *= 1.4
	if variant == "TECNOLOGICO":
		add_to_group("technological")
	health = hp_max
	_update_bar()

func inside_arena(pos: Vector3) -> bool:
	return absf(pos.y-home.y) < 2.5 and Vector2(pos.x-home.x,pos.z-home.z).length() < 12

func _vision_amount() -> float:
	if not is_instance_valid(target) or not inside_arena(target.global_position):
		return 0
	return super._vision_amount()

func _do_patrol(delta: float) -> Vector3:
	var desired := super._do_patrol(delta)*speed_factor
	return desired if inside_arena(global_position+desired*delta) else Vector3.ZERO

func _do_chase(delta: float, vis: float) -> Vector3:
	if not is_instance_valid(target) or not inside_arena(target.global_position):
		state = State.SEARCH
		search_t = 2
		return Vector3.ZERO
	return super._do_chase(delta,vis)*speed_factor

func _on_punch_landed(_side: int) -> void:
	if dead or not is_instance_valid(target) or target.get("dead") == true or not inside_arena(target.global_position):
		return
	var direction := target.global_position-global_position
	if direction.length() <= ATTACK_HIT_RANGE and _line_of_sight(global_position+Vector3.UP,target.global_position+Vector3.UP):
		if direction.length() < 0.01 or body.forward().dot(direction.normalized()) > 0.3:
			target.take_hit(direction.normalized(),melee_damage)

func _physics_process(delta: float) -> void:
	if get_meta("perception_sleep",false): return
	shot_cd = maxf(0,shot_cd-delta)
	if not dead and variant in ["DISTANCIA","TECNOLOGICO"] and state == State.CHASE and shot_cd <= 0 and is_instance_valid(target) and inside_arena(target.global_position):
		var distance := global_position.distance_to(target.global_position)
		if distance > 4 and distance < 12 and _vision_amount() > 0:
			var shot = load("res://scripts/pisos/piso_8/proyectil_error_sistema.gd").new()
			shot.shooter = self
			shot.damage = melee_damage
			get_parent().add_child(shot)
			shot.launch(global_position+Vector3.UP*1.6,target.global_position+Vector3.UP)
			shot_cd = 3.2
	super._physics_process(delta)

func _update_bar() -> void:
	if not is_instance_valid(bar_fg):
		return
	var width := maxf(BAR_W*health/maxf(hp_max,1),0.001)
	var quad := bar_fg.mesh as QuadMesh
	quad.size.x = width
	quad.center_offset.x = -(BAR_W-width)*0.5
