extends SceneTree
const Boss = preload("res://scripts/pisos/piso_8/director_informatica_boss.gd")
const Registry = preload("res://scripts/pisos/piso_8/credencial_director.gd")
const Enemy = preload("res://scripts/juego/enemy.gd")
var failures: Array[String] = []
var deaths := 0
var rewards := 0

class TestPlayer extends CharacterBody3D:
	var dead := false
	var crouching := false
	var running := false
	var health := 1000.0
	var max_health := 1000.0
	func take_hit(_direction: Vector3, damage: float) -> void:
		health -= damage

func check(condition: bool, text: String) -> void:
	if not condition:
		failures.append(text)
		push_error(text)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var registry := Registry.new()
	registry.name = "CredencialDirector"
	registry.persist = false
	world.add_child(registry)
	registry.credential_granted.connect(func(_credential): rewards += 1)
	var player := TestPlayer.new()
	player.position = Vector3(62,84.06,-131)
	player.add_to_group("player")
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.3
	capsule.shape = shape
	capsule.position.y = 0.9
	player.add_child(capsule)
	world.add_child(player)
	var boss := Boss.new()
	boss.position = Vector3(64,84.06,-131)
	world.add_child(boss)
	boss.set_physics_process(false)
	boss.target = player
	boss.died.connect(func(_enemy): deaths += 1)
	var normal := Enemy.new()
	normal.position = Vector3(100,84.06,-131)
	world.add_child(normal)
	normal.set_physics_process(false)
	await physics_frame
	check(boss.health == 700 and boss.phase == 1,"700 HP y fase inicial")
	check(is_equal_approx(boss.body.scale.x,1.2),"Escala visual 1.2; cápsula anterior intacta")
	check(not registry.has_credential(),"Credencial bloqueada antes de vencer")
	boss.body.rotation.y = PI/2
	boss._on_punch_landed(0)
	check(player.health == 980,"Melee inicial 20 daño")
	player.position.x = 56
	await physics_frame
	boss.digital_pending = true
	boss._on_punch_landed(0)
	check(boss.projectiles.size() == 1,"Proyectil digital desde fase 1")
	var shot = boss.projectiles[0]
	shot.set_physics_process(false)
	check(shot.damage == 16,"Daño inicial del proyectil")
	boss.take_hit(Vector3.ZERO,-30)
	check(boss.health == 700,"Daño negativo no cura")
	boss.take_hit(Vector3.ZERO,279)
	check(boss.phase == 1,"Fase 1 hasta 421 HP")
	boss.take_hit(Vector3.ZERO,1)
	check(boss.phase == 2 and boss.health == 420,"Fase 2 al 60%")
	check(boss.minions.size() == 2,"Invoca exactamente dos virus")
	for virus in boss.minions:
		virus.set_physics_process(false)
		check(virus.health == 50 and virus.is_in_group("enemy"),"Virus reutiliza enemigo con 50 HP")
	boss.take_hit(Vector3.ZERO,1)
	check(boss.minions.size() == 2,"No duplica invocaciones")
	boss.take_hit(Vector3.ZERO,209)
	check(boss.phase == 3 and boss.health == 210,"Modo Administrador al 30%")
	check(boss.name_label.text.contains("Modo Administrador"),"Nombre visible del modo")
	player.position = Vector3(60,84.06,-131)
	await physics_frame
	boss._start_blue_screen()
	check(boss.blue_charge == 1.2 and boss.blue_marker.visible,"Área anunciada 1.2 segundos")
	boss.blue_charge = 0
	boss._resolve_blue_screen()
	check(player.health == 944,"Pantallazo Azul causa 36 de daño en área")
	player.position.x = 54
	await physics_frame
	boss._resolve_blue_screen()
	check(player.health == 944,"Pantallazo esquivable fuera de radio 6")
	player.position = Vector3(60,72,-131)
	check(boss._vision_amount() == 0,"No detecta en otros pisos")
	check(boss._do_chase(0.016,1) == Vector3.ZERO,"No persigue fuera del Piso 8")
	player.position = Vector3(60,84.06,-131)
	boss._start_blue_screen()
	boss.digital_pending = true
	boss.take_hit(Vector3.ZERO,1000)
	check(boss.dead and not boss.is_in_group("enemy"),"Muerte desactiva ataques y selección")
	check(boss.blue_charge == 0 and not boss.blue_marker.visible,"Cancela Pantallazo pendiente")
	boss._on_punch_landed(0)
	check(player.health == 944,"No golpea después de morir")
	boss.take_hit(Vector3.ZERO,1000)
	await process_frame
	await process_frame
	check(deaths == 1 and rewards == 1,"Una sola muerte y entrega")
	check(registry.has_credential("CredencialDirector"),"Credencial disponible para puertas futuras")
	check(player.get_meta("CredencialDirector",false),"Credencial asociada al jugador")
	check(not registry.grant_credential(player) and rewards == 1,"Recompensa no duplicable")
	check(not is_instance_valid(shot),"Proyectiles eliminados al morir")
	for virus in boss.minions:
		check(not is_instance_valid(virus),"Virus eliminados al morir")
	check(normal.health == 100 and not normal.dead,"Enemigo normal intacto")
	# Prueba persistencia sin alterar la partida del usuario.
	var saved := Registry.new()
	saved.persist = true
	saved.save_path = "res://tests/director_credencial_temporal.cfg"
	world.add_child(saved)
	saved.grant_credential()
	var reloaded := Registry.new()
	reloaded.persist = true
	reloaded.save_path = saved.save_path
	world.add_child(reloaded)
	check(reloaded.has_credential(),"Credencial persiste al recargar registro")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saved.save_path))
	print("DIRECTOR INFORMATICA: %s (%d fallos)" % ["OK" if failures.is_empty() else "ERROR", failures.size()])
	quit(0 if failures.is_empty() else 1)
