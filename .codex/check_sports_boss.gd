extends SceneTree
var failures: Array[String] = []
func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await frames(2)
	var player = scene.get_node("GameplayManager").player
	var boss = scene.get_node("Piso1/SalaAyudaEstudiantil/BossAyudaEstudiantil")
	var initial_count := get_nodes_in_group("sports_equipment").size()
	check(initial_count == 4, "initial balls missing")
	for item in scene.get_node("Piso1/SalaAyudaEstudiantil/ObjetosParaCombate").get_children():
		check(item.get("sport") != null, "old stick or chair still in room")
	player.set_physics_process(false)
	player.global_position = boss.global_position + Vector3(4.5, 0.05, 0)
	for i in range(150):
		await physics_frame
		if not get_nodes_in_group("sports_projectile").is_empty(): break
	check(not get_nodes_in_group("sports_projectile").is_empty(), "boss AI did not throw")
	boss.set_physics_process(false)
	await frames(180)
	check(player.health == 88.0, "projectile did not damage player exactly once")
	check(get_nodes_in_group("sports_projectile").is_empty(), "projectile did not land")
	var pickups := get_nodes_in_group("sports_equipment")
	check(pickups.size() == initial_count + 1, "throw did not leave one sports item")
	pickups = pickups.filter(func(item): return item.get("sport") == "bate")
	if not pickups.is_empty():
		var item = pickups[0]
		check(item.is_in_group("weapon_pickup") and not item.held, "landed item cannot be collected")
		player.global_position = item.global_position + Vector3(0.6, 0, 0)
		player._try_interact()
		check(player.weapon == item and item.held, "E interaction did not equip item")
		check(not item.is_in_group("weapon_pickup"), "held item still collectible")
		player.global_position = boss.global_position + Vector3(1.4, 0, 0)
		player.body.rotation.y = PI / 2
		player._on_punch_landed(1)
		check(boss.health == 170.0 and item.durability == 11, "sports weapon cannot damage boss")
		player._drop()
		check(item.is_in_group("weapon_pickup") and not item.held, "sports item cannot be dropped")
	# Each of the three models follows the same flight and pickup lifecycle.
	for sport in ["raqueta", "pelota"]:
		player.global_position = boss.global_position + Vector3(4.5, 0.05, 0)
		boss._throw_equipment()
		await frames(180)
		var found := false
		for item in get_nodes_in_group("weapon_pickup"):
			if item.get("sport") == sport: found = true
		check(found, "missing landed " + sport)
	check(player.health == 64.0, "three throws damage not correct")
	# Throw the player's actual baseball, preserving its identity and durability.
	var baseball = scene.get_node("Piso1/SalaAyudaEstudiantil/ObjetosParaCombate/PelotaBaseball1")
	player._equip(baseball)
	player.global_position = boss.global_position + Vector3(4.5, 0.05, 0)
	player.cam_yaw = PI / 2
	var before_boss: float = boss.health
	var equipment_count := get_nodes_in_group("sports_equipment").size()
	player._throw_sport()
	check(player.weapon == null and not baseball.is_in_group("weapon_pickup"), "baseball did not leave player's hand")
	await frames(180)
	check(boss.health == before_boss - 28.0, "player baseball did not damage boss once")
	check(player.health == 64.0, "player's own baseball damaged player")
	check(baseball.is_in_group("weapon_pickup"), "player baseball did not become collectible again")
	check(get_nodes_in_group("sports_equipment").size() == equipment_count, "throw duplicated baseball")
	player._equip(baseball)
	check(player.weapon == baseball, "cannot retrieve thrown baseball")
	player._drop()
	# All five extra sports must have a model and complete the flight lifecycle.
	boss.max_sports_equipment = 20
	for sport in ["baseball", "tenis", "futbol", "rugby", "disco"]:
		boss._throw_equipment()
		await frames(180)
		var found := false
		for item in get_nodes_in_group("weapon_pickup"):
			if item.get("sport") == sport and item.model.get_child_count() > 0: found = true
		check(found, "extra sports model or landing missing: " + sport)
	check(player.health == 4.0, "eight boss throws did not each deal 12 damage")
	# A wall must stop detection, throwing, and an already-flying projectile.
	var barrier := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 4, 3)
	col.shape = shape
	barrier.add_child(col)
	scene.add_child(barrier)
	barrier.global_position = boss.global_position + Vector3(2, 2, 0)
	await frames(2)
	check(not boss._can_detect_target(), "boss detects player through wall")
	var before: float = player.health
	var projectile = load("res://scripts/juego/proyectil_deportivo.gd").new()
	projectile.shooter = boss._mover
	scene.add_child(projectile)
	projectile.launch(boss.global_position + Vector3(0.7, 1.8, 0), player.global_position + Vector3.UP * 1.2, 12)
	await frames(180)
	check(player.health == before, "projectile passed through wall")
	boss.max_sports_equipment = get_nodes_in_group("sports_equipment").size()
	check(not boss._can_spawn_equipment(), "equipment limit not enforced")
	boss.take_hit(Vector3.ZERO, 999)
	barrier.queue_free()
	await frames(2)
	boss._throw_equipment()
	check(get_nodes_in_group("sports_projectile").is_empty(), "dead boss threw equipment")
	print("SPORTS_BOSS_RESULT ", JSON.stringify({"failures":failures,"player_health":player.health,"equipment":get_nodes_in_group("sports_equipment").size()}))
	quit(0 if failures.is_empty() else 1)
