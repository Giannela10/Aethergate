extends SceneTree
const Chef = preload("res://scripts/pisos/piso_1/chef_supremo_casino.gd")
const Enemy = preload("res://scripts/juego/enemy.gd")
var death_count := 0

class TestPlayer extends CharacterBody3D:
	var dead := false
	var crouching := false
	var running := false
	var health := 200.0
	var max_health := 200.0
	func take_hit(_direction: Vector3, damage: float) -> void:
		health -= damage
	func heal(amount: float) -> void:
		health = minf(health + amount,max_health)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var player := TestPlayer.new()
	player.position = Vector3(-70,0.2,-102.5)
	player.add_to_group("player")
	world.add_child(player)
	var normal := Enemy.new()
	world.add_child(normal)
	normal.set_physics_process(false)
	var boss := Chef.new()
	boss.position = Vector3(-73,0.2,-102.5)
	world.add_child(boss)
	boss.set_physics_process(false)
	boss.target = player
	boss.died.connect(func(_enemy): death_count += 1)
	await physics_frame
	assert(boss.health == 350.0 and boss.phase == 1)
	assert(is_equal_approx(boss.body.scale.x,1.4))
	assert(normal.health == 100.0)
	boss.take_hit(Vector3.ZERO,-50)
	assert(boss.health == 350.0)
	boss.take_hit(Vector3.ZERO,boss.boss_max_health * 0.40 - 1)
	assert(boss.phase == 1 and boss.health == boss.boss_max_health * 0.60 + 1)
	boss.take_hit(Vector3.ZERO,1)
	assert(boss.phase == 2 and boss.health == boss.boss_max_health * 0.60)
	assert(boss.body.punch_time == 0.58)
	boss.body.rotation.y = -PI/2
	player.position.x = -71.2
	boss._on_punch_landed(0)
	assert(player.health == 178.0, "Melee fase 2: 22 daño")
	player.position.x = -30.0
	assert(boss._do_chase(0.016,1.0) == Vector3.ZERO)
	assert(boss.state == boss.State.PATROL, "No persigue fuera del casino")
	player.position.x = -65.0
	boss.tray_pending = true
	boss._on_punch_landed(0)
	var tray := world.get_node("BandejaChef")
	assert(tray.damage == 14.0 and tray.shooter == boss)
	boss.take_hit(Vector3.ZERO,boss.boss_max_health * 0.30)
	assert(boss.phase == 3 and boss.health == boss.boss_max_health * 0.30)
	assert(boss.body.punch_time == 0.46)
	boss.take_hit(Vector3.ZERO,1000)
	assert(boss.dead and not boss.is_in_group("enemy"))
	boss._on_punch_landed(0)
	assert(player.health == 178.0, "No ataca después de morir")
	boss.take_hit(Vector3.ZERO,1000)
	assert(death_count == 1, "Una sola muerte y recompensa")
	await process_frame
	await process_frame
	assert(player.health == player.max_health, "Curación completa")
	assert(not is_instance_valid(tray), "Las bandejas desaparecen al morir")
	assert(normal.health == 100.0 and not normal.dead)
	print("CHEF CASINO OK: 350 HP, fases 60/30%, melee, bandeja, límites, muerte única, curación y enemigo normal intacto.")
	quit(0)
