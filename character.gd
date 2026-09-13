extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_force: float = 5.0
@export var gravity: float = 15.0


func _physics_process(delta: float) -> void:

	# =========================
	# GRAVEDAD
	# =========================

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


	# =========================
	# SALTO
	# =========================

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_force


	# =========================
	# WASD
	# =========================

	var direction := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		direction.z -= 1.0

	if Input.is_key_pressed(KEY_S):
		direction.z += 1.0

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0

	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0


	# Evitar que moverse en diagonal sea más rápido
	if direction.length() > 0.0:
		direction = direction.normalized()


	# =========================
	# MOVIMIENTO
	# =========================

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
