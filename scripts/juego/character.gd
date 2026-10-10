extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_force: float = 5.0
@export var gravity: float = 15.0
@export var mouse_sensitivity: float = 0.003

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:

	# MOVER CÁMARA CON EL MOUSE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

		# Izquierda / derecha
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Arriba / abajo
		camera.rotation.x -= event.relative.y * mouse_sensitivity

		camera.rotation.x = clamp(
			camera.rotation.x,
			deg_to_rad(-60.0),
			deg_to_rad(45.0)
		)

	# ESC libera el mouse
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Click vuelve a capturar el mouse
	if event is InputEventMouseButton:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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

	var input_direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		input_direction.y -= 1.0

	if Input.is_key_pressed(KEY_S):
		input_direction.y += 1.0

	if Input.is_key_pressed(KEY_A):
		input_direction.x -= 1.0

	if Input.is_key_pressed(KEY_D):
		input_direction.x += 1.0


	if input_direction.length() > 0.0:
		input_direction = input_direction.normalized()


	# =========================
	# MOVIMIENTO SEGÚN DONDE MIRA
	# =========================

	var direction := (
		transform.basis *
		Vector3(input_direction.x, 0.0, input_direction.y)
	).normalized()


	if direction.length() > 0.0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0


	move_and_slide()
