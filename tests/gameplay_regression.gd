extends SceneTree
## Ejecutar: godot --headless --path . --script res://tests/gameplay_regression.gd
var failures: Array[String] = []

class TestPlayer extends "res://scripts/juego/player.gd":
	func _ready() -> void:
		persist_inventory = false
		super._ready()
	func load_stationery() -> void:
		pass
	func save_stationery() -> void:
		pass

class Target extends Node3D:
	var health := 100.0
	var dead := false
	func take_hit(_direction: Vector3, damage: float) -> void:
		health -= damage

func block(parent: Node3D, position_value: Vector3, size_value: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position_value
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size_value
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func check_scripts(path: String) -> void:
	var directory := DirAccess.open(path)
	for filename in directory.get_files():
		if filename.ends_with(".gd"):
			var script = load(path.path_join(filename))
			check(script != null and script.can_instantiate(), "Script inválido: " + path.path_join(filename))
	for folder in directory.get_directories():
		check_scripts(path.path_join(folder))

func run() -> void:
	# Cargar todos los scripts de juego detecta dependencias y errores de análisis.
	check_scripts("res://scripts")
	check(load("res://Main.tscn") != null, "La escena principal debe cargar")
	check(load("res://Character.tscn") != null, "La escena Character debe cargar")
	check(load("res://materials/entrance/MAT_Piedra_Posterior.tres") != null, "El material de piedra debe cargar")
	var files = load("res://scripts/juego/game_files.gd").new()
	root.add_child(files)
	files.start()
	var completions := [0]
	files.completed.connect(func(): completions[0] += 1)
	for index in files.TOTAL:
		files._on_folder(files.queue[files.index][1])
	files._on_folder(0)
	check(files.done and completions[0] == 1, "Archivos: los clics posteriores no repiten el éxito")
	files.queue_free()
	var ui = load("res://scripts/juego/minigame_ui.gd").new()
	root.add_child(ui)
	ui.open(-1)
	check(not ui.active, "Minijuego: rechazar identificadores inválidos")
	ui.open(0)
	ui._on_completed()
	ui.close()
	ui.open(1)
	await create_timer(1.3).timeout
	check(ui.active and ui.current.get_script() == load("res://scripts/juego/game_virus.gd"), "El temporizador anterior no cierra una sesión nueva")
	ui.close()
	ui.queue_free()
	var password = load("res://scripts/juego/game_password.gd").new()
	root.add_child(password)
	password.start()
	password._set_phase(password.Phase.ENTER, 0.0)
	password.code = "0123"
	for digit in [0, 1, 2, 3]:
		var key := InputEventKey.new()
		key.keycode = KEY_0 + digit
		key.pressed = true
		password._unhandled_key_input(key)
	password._on_key("Enviar")
	check(password.done, "Contraseña: aceptar teclado físico y ceros iniciales")
	password.queue_free()
	var player = load("res://scripts/juego/player.gd").new()
	# No agregar al árbol: comprobar el registro de controles sin tocar el guardado.
	player._setup_input()
	var events := InputMap.action_get_events("punch").size()
	player._setup_input()
	check(InputMap.action_get_events("punch").size() == events, "Reiniciar no duplica controles")
	player.free()
	var world := Node3D.new()
	root.add_child(world)
	block(world, Vector3(0, 11.85, 0), Vector3(10, 0.3, 10))
	var fighter := TestPlayer.new()
	fighter.position = Vector3(0, 12.05, 0)
	world.add_child(fighter)
	fighter.set_physics_process(false)
	var victim := Target.new()
	victim.position = Vector3(0, 12.05, -1)
	world.add_child(victim)
	victim.add_to_group("enemy")
	await physics_frame
	await physics_frame
	check(fighter._has_standing_room(), "El jugador puede levantarse con espacio libre")
	var ceiling := block(world, Vector3(0, 14.1, 0), Vector3(3, 0.2, 3))
	await physics_frame
	await physics_frame
	check(not fighter._has_standing_room(), "El jugador no se levanta bajo un techo bajo")
	ceiling.queue_free()
	await physics_frame
	await physics_frame
	fighter._on_punch_landed(0)
	check(victim.health == 90.0, "El golpe alcanza al enemigo delante")
	var wall := block(world, Vector3(0, 13.0, -0.5), Vector3(3, 3, 0.1))
	await physics_frame
	await physics_frame
	fighter._on_punch_landed(0)
	check(victim.health == 90.0, "La pared bloquea el golpe")
	wall.queue_free()
	await physics_frame
	await physics_frame
	victim.position.y = 24.0
	fighter._on_punch_landed(0)
	check(victim.health == 90.0, "El golpe no alcanza otro piso")
	var weapon = load("res://scripts/juego/weapon.gd").new()
	world.add_child(weapon)
	fighter._equip(weapon)
	fighter._drop()
	check(absf(weapon.global_position.y - 12.025) < 0.1, "Soltar un arma conserva el piso actual")
	check(weapon.is_in_group("weapon_pickup"), "El arma soltada se puede recoger")
	world.queue_free()
	await process_frame
	print("GAMEPLAY_REGRESSION_RESULT " + JSON.stringify({"passed": failures.is_empty(), "failures": failures}))
	quit(0 if failures.is_empty() else 1)
