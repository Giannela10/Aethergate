extends SceneTree
var failures: Array[String] = []
const Pickup = preload("res://scripts/inventory/inventory_pickup.gd")
const Effects = preload("res://scripts/inventory/item_effect_receiver.gd")
const Catalog = preload("res://scripts/inventory/item_catalog.gd")
const Director = preload("res://scripts/pisos/piso_8/director_informatica_boss.gd")
const KeyAccess = preload("res://scripts/inventory/key_access.gd")
class TestPlayer extends "res://scripts/juego/player.gd":
	func _ready() -> void:
		persist_inventory = false
		super._ready()
	func load_stationery() -> void:
		stationery_inventory = {"cuaderno":2}
	func save_stationery() -> void:
		pass

func check(ok: bool, text: String) -> void:
	if not ok:
		failures.append(text)
		push_error(text)

func uid(inventory: Node, id: String) -> String:
	for entry in inventory.entries:
		if entry.item_id == id:
			return entry.uid
	return ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(80,0.2,30)
	floor_col.shape = floor_shape
	floor_body.position = Vector3(50,83.8,-131)
	floor_body.add_child(floor_col)
	world.add_child(floor_body)
	var player := TestPlayer.new()
	player.position = Vector3(59,84,-131)
	world.add_child(player)
	player.set_physics_process(false)
	var inv = player.inventory
	check(inv.count_item("cuaderno") == 2,"Migración de papelería")
	check(player.body.get_node("Model") != null,"Modelo organizado")
	check(player.body.weapon_socket.name == "WeaponSocket","Socket de arma")
	check(player.body.backpack_socket.get_node("Mochila") != null,"Mochila visible")
	check(player.body.animation_player.has_animation("Death"),"Clips preparados para rig futuro")
	inv.add_item("Botiquin",2)
	inv.add_item("Botiquin",1)
	check(inv.count_item("Botiquin") == 3,"Consumibles apilables")
	check(not inv.use_entry(uid(inv,"Botiquin")) and inv.count_item("Botiquin") == 3,"Vida completa no gasta botiquín")
	player.health = 20
	check(inv.use_entry(uid(inv,"Botiquin")) and player.health == 70,"Botiquín cura 50")
	check(inv.count_item("Botiquin") == 2,"Uso descuenta cantidad")
	inv.add_item("Comida")
	inv.use_entry(uid(inv,"Comida"))
	check(player.health == 100 and not inv.has_item("Comida"),"Comida cura 30 y elimina pila vacía")
	inv.add_item("ColacionEspecial")
	player.health = 1
	inv.use_entry(uid(inv,"ColacionEspecial"))
	check(player.health == 100,"Colación recupera toda la vida")
	inv.add_item("BebidaEnergetica",2)
	inv.use_entry(uid(inv,"BebidaEnergetica"))
	check(player.speed_multiplier == 1.35 and player.speed_boost_time == 12,"Energética temporal")
	inv.use_entry(uid(inv,"BebidaEnergetica"))
	check(player.speed_multiplier == 1.35,"No acumula velocidad")
	player.speed_boost_time = 0.001
	player.busy = true
	player._physics_process(0.01)
	player.busy = false
	check(player.speed_multiplier == 1,"Velocidad normal al expirar")
	inv.add_item("LlaveCasino")
	var key_uid := uid(inv,"LlaveCasino")
	check(not inv.use_entry(key_uid) and inv.count_item("LlaveCasino") == 1,"Llaves no se consumen")
	var door := Node3D.new()
	door.position = player.position
	world.add_child(door)
	var access := KeyAccess.new()
	access.required_item = "LlaveCasino"
	door.add_child(access)
	check(access.try_unlock(player) and inv.count_item("LlaveCasino") == 1,"Acceso comprueba llave sin consumirla")
	var pickup := Pickup.new()
	pickup.item_id = "Bebida"
	pickup.position = player.position + Vector3.LEFT
	world.add_child(pickup)
	await physics_frame
	await physics_frame
	check(pickup.collect(player) and inv.has_item("Bebida"),"Recoger objeto del mundo")
	check(not pickup.collect(player),"No recoger dos veces")
	await process_frame
	check(not is_instance_valid(pickup),"Objeto recogido desaparece")
	var w1 = load("res://scripts/juego/weapon.gd").new()
	world.add_child(w1)
	w1.durability = 7
	player._equip(w1)
	var w1uid: String = inv.equipped_uid
	check(w1.get_parent() == player.body.weapon_socket and inv.count_item("Palo") == 1,"Arma equipada en socket y registrada")
	var w2 = load("res://scripts/juego/weapon.gd").new()
	w2.kind = "silla"
	world.add_child(w2)
	player._equip(w2)
	check(w1.get_parent() == inv.storage and w1.durability == 7,"Cambiar arma guarda la anterior")
	inv.equip_entry(w1uid)
	check(player.weapon == w1 and w1.durability == 7,"Reequipar conserva durabilidad")
	inv.assign_quick(0,w1uid)
	check(inv.use_quick(0) and player.weapon == w1,"Barra rápida equipa")
	player._use_weapon()
	check(w1.durability == 6,"Combate gasta durabilidad")
	player._drop()
	check(w1.is_in_group("weapon_pickup") and not inv.has_item("Palo"),"Soltar retira del inventario")
	check(absf(w1.global_position.y-83.925) < 0.2,"Soltar conserva el piso")
	player._equip(w1)
	w1.durability = 1
	player._use_weapon()
	check(player.weapon == null and not inv.has_item("Palo"),"Arma rota se retira de mochila")
	inv.add_item("PaletaPingPong")
	check(inv.equip_entry(uid(inv,"PaletaPingPong")) and player.weapon.damage == 20,"Paleta usa API de weapon")
	inv.add_item("Disco")
	inv.equip_entry(uid(inv,"Disco"))
	player._throw_sport()
	check(player.weapon == null and not inv.has_item("Disco"),"Lanzar saca el arma del inventario")
	inv.add_item("USBInfectado",2)
	var boss := Director.new()
	boss.position = Vector3(64,84,-131)
	var effects := Effects.new()
	effects.name = "ItemEffects"
	effects.weaknesses = {"USBInfectado":2.0}
	effects.cancel_methods = ["_cancel_blue_screen"]
	boss.add_child(effects)
	world.add_child(boss)
	boss.set_physics_process(false)
	boss.target = player
	await physics_frame
	boss._start_blue_screen()
	check(inv.use_entry(uid(inv,"USBInfectado")),"USB se aplica a boss compatible")
	check(boss.health == 620 and effects.remaining > 0,"Debilidad duplica daño y paraliza")
	check(boss.blue_charge == 0 and not boss.blue_marker.visible,"USB cancela Pantallazo")
	check(inv.count_item("USBInfectado") == 1,"USB solo gasta al acertar")
	var wall := StaticBody3D.new()
	wall.position = Vector3(61.5,85.0,-131)
	var wall_collision := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(0.2,4,3)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	world.add_child(wall)
	await physics_frame
	await physics_frame
	check(not inv.use_entry(uid(inv,"USBInfectado")) and boss.health == 620,"Pared bloquea objeto especial")
	wall.queue_free()
	await physics_frame
	await physics_frame
	player.position.y = 72
	check(not inv.use_entry(uid(inv,"USBInfectado")),"USB no alcanza otro piso")
	player.position.y = 84
	effects.immunities = ["USBInfectado"]
	check(not inv.use_entry(uid(inv,"USBInfectado")) and inv.count_item("USBInfectado") == 1,"Inmunidad no gasta objeto")
	effects.immunities = []
	effects.remaining = 0.001
	effects.was_processing = true
	effects._process(0.01)
	check(boss.is_physics_processing(),"Efecto restaura IA al expirar")
	boss.set_physics_process(false)
	player.inventory_ui.open_inventory()
	await process_frame
	await process_frame
	check(player.busy and player.inventory_ui.panel.visible,"I abre inventario y bloquea movimiento")
	check(player.inventory_ui.panel.size.y <= 560,"Panel de inventario cabe en pantalla")
	player.take_hit(Vector3.ZERO,1)
	check(not player.busy and not player.inventory_ui.panel.visible,"Daño cierra inventario sin bloquear controles")
	player.busy = true
	check(not inv.use_entry(uid(inv,"USBInfectado")),"No usar barra mientras hay minijuego")
	player.busy = false
	player.receive_stationery("lapiz")
	check(inv.has_item("lapiz") and player.stationery_inventory.lapiz == 1,"Papelería y mochila sincronizadas")
	player.equip_stationery("lapiz")
	check(player.stationery_model.get_parent() == player.body.item_socket,"Objeto equipado en ItemSocket")
	# Guardado aislado, nunca sobre los archivos de la partida.
	inv.save_path = "res://tests/inventario_temporal.json"
	inv.save_data()
	var other := TestPlayer.new()
	world.add_child(other)
	other.set_physics_process(false)
	other.inventory.save_path = inv.save_path
	other.inventory.load_data()
	check(other.inventory.count_item("Botiquin") == inv.count_item("Botiquin"),"Carga cantidades persistentes")
	check(other.inventory.has_item("LlaveCasino"),"Carga objetos clave")
	var saved_silla_uid := uid(other.inventory,"Silla")
	check(other.inventory.weapon_nodes[saved_silla_uid].durability == w2.durability,"Carga durabilidad por arma")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(inv.save_path))
	world.queue_free()
	await process_frame
	print("INVENTORY_REGRESSION_RESULT " + JSON.stringify({"passed":failures.is_empty(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
