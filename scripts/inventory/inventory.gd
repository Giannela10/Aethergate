extends Node
const Catalog = preload("res://scripts/inventory/item_catalog.gd")
const Item = preload("res://scripts/inventory/inventory_item.gd")
signal changed
signal notice(text: String)
signal item_used(item_id: String)
@export var persist := true
@export var save_path := "user://inventario_estudiante.json"
var entries: Array[Dictionary] = []
var weapon_nodes: Dictionary = {}
var quick_slots: Array[String] = ["","","",""]
var equipped_uid := ""
var serial := 0
var max_entries := 0
var player: CharacterBody3D
var storage: Node3D

func _ready() -> void:
	player = get_parent()
	storage = Node3D.new()
	storage.name = "StoredWeapons"
	storage.visible = false
	add_child(storage)
	if persist:
		load_data()
	# La papelería guardada previamente sigue siendo la fuente de migración.
	for key in player.stationery_inventory:
		var amount: int = player.stationery_inventory[key]
		var existing := count_item(key)
		if amount > existing:
			add_item(key,amount-existing,false)
		elif existing > amount:
			for entry in entries.duplicate():
				if entry.item_id == key:
					_erase_entry(entry.uid)
			if amount > 0:
				add_item(key,amount,false)
	changed.emit()

func entry_for(uid: String) -> Dictionary:
	for entry in entries:
		if entry.uid == uid:
			return entry
	return {}

func toggle_favorite(uid: String) -> bool:
	var entry := entry_for(uid)
	if entry.is_empty(): return false
	entry["favorite"] = not bool(entry.get("favorite",false))
	_commit()
	return true

func discard_protected(uid: String) -> bool:
	var entry := entry_for(uid)
	if entry.is_empty(): return false
	var item = Catalog.get_item(entry.item_id)
	return bool(entry.get("favorite",false)) or item.unique or item.category == Item.Category.CLAVE

func describe_comparison(uid: String) -> String:
	var weapon = weapon_nodes.get(uid)
	if not is_instance_valid(weapon): return ""
	var current = player.weapon
	var text := "\nDAÑO: %.1f · VELOCIDAD: %.2f s/golpe\nDURABILIDAD: %d · PESO: sin dato" % [float(weapon.damage),float(weapon.swing_time),int(weapon.durability)]
	if is_instance_valid(current):
		text += "\nActual: %.1f daño · %.2f s/golpe · %d durabilidad" % [float(current.damage),float(current.swing_time),int(current.durability)]
	return text

func count_item(id: String) -> int:
	var count := 0
	for entry in entries:
		if entry.item_id == id:
			count += int(entry.quantity)
	return count

func has_item(id: String, amount: int = 1) -> bool:
	return amount > 0 and count_item(id) >= amount

func _uid() -> String:
	serial += 1
	return "item_%d" % serial

func add_item(id: String, amount: int = 1, announce: bool = true) -> int:
	var item = Catalog.get_item(id)
	if item == null or amount <= 0:
		return 0
	if item.unique and has_item(id):
		return 0
	if max_entries > 0 and entries.size() >= max_entries and (not item.stackable or not has_item(id)):
		notice.emit("La mochila está llena.")
		return 0
	if item.category == Item.Category.ARMA:
		var added_weapons := 0
		for i in mini(amount,100):
			if max_entries > 0 and entries.size() >= max_entries: break
			var weapon := create_weapon(id)
			storage.add_child(weapon)
			if collect_weapon(weapon,false):
				added_weapons += 1
			else:
				weapon.queue_free()
		return added_weapons
	var previous_count := count_item(id)
	var remaining := amount
	if item.stackable:
		for entry in entries:
			if entry.item_id == id:
				var added := mini(remaining,maxi(0,item.max_stack-int(entry.quantity)))
				entry.quantity += added
				remaining -= added
	# Los objetos clave son únicos y no se consumen.
	if item.category == Item.Category.CLAVE:
		remaining = 0 if has_item(id) else mini(remaining,1)
	if remaining > 0:
		while remaining > 0:
			if max_entries > 0 and entries.size() >= max_entries: break
			var quantity := mini(remaining,item.max_stack if item.stackable else 1)
			var entry := {"uid":_uid(),"item_id":id,"quantity":quantity,"data":{}}
			entries.append(entry)
			_auto_slot(entry.uid)
			remaining -= quantity
	var added_total := count_item(id)-previous_count
	if added_total == 0:
		notice.emit("No hay espacio disponible para este objeto.")
		return 0
	_sync_paper(id)
	_commit()
	if announce:
		notice.emit("Recogiste: %s x%d" % [item.display_name,added_total])
	return added_total

func create_weapon(id: String) -> Node3D:
	var item = Catalog.get_item(id)
	var weapon: Node3D
	if item.weapon_kind.begins_with("campus:"):
		weapon = load("res://scripts/campaign/campus_weapon.gd").new()
		weapon.item_id = id
		return weapon
	if not item.weapon_sport.is_empty():
		weapon = load("res://scripts/juego/implemento_deportivo.gd").new()
		weapon.sport = item.weapon_sport
	elif item.weapon_kind == "paleta_ping_pong":
		weapon = load("res://scripts/inventory/paleta_ping_pong.gd").new()
	else:
		weapon = load("res://scripts/juego/weapon.gd").new()
		weapon.kind = item.weapon_kind
	return weapon

func collect_weapon(weapon: Node3D, equip_now: bool = false) -> bool:
	if max_entries > 0 and entries.size() >= max_entries:
		return false
	var id := Catalog.weapon_id(weapon)
	if id.is_empty() or weapon.get("durability") <= 0:
		return false
	if not weapon.has_meta("max_durability"):
		weapon.set_meta("max_durability",weapon.get("max_durability") if weapon.get("max_durability") != null else weapon.durability)
	var uid := _uid()
	var entry := {"uid":uid,"item_id":id,"quantity":1,"data":{}}
	entries.append(entry)
	weapon_nodes[uid] = weapon
	weapon.pick_up()
	if weapon.get_parent() != storage:
		weapon.reparent(storage,false)
	weapon.process_mode = Node.PROCESS_MODE_DISABLED
	weapon.set_meta("inventory_uid",uid)
	_auto_slot(uid)
	_commit()
	notice.emit("Recogiste: %s x1" % Catalog.get_item(id).display_name)
	if equip_now:
		equip_entry(uid)
	return true

func stash_equipped() -> void:
	if player.weapon == null:
		equipped_uid = ""
		return
	var weapon = player.body.unequip()
	player.weapon = null
	player.body.punch_time = 0.5
	if weapon != null:
		if equipped_uid.is_empty() or not weapon_nodes.has(equipped_uid):
			# Compatibilidad con armas equipadas por scripts externos.
			storage.add_child(weapon)
			collect_weapon(weapon,false)
		else:
			storage.add_child(weapon)
			weapon.process_mode = Node.PROCESS_MODE_DISABLED
	equipped_uid = ""
	player._emit_weapon()
	_commit()

func equip_entry(uid: String) -> bool:
	var entry := entry_for(uid)
	if entry.is_empty() or player.dead:
		return false
	var item = Catalog.get_item(entry.item_id)
	if item.category == Item.Category.PAPELERIA:
		stash_equipped()
		return player.equip_stationery(entry.item_id)
	if item.category != Item.Category.ARMA:
		return false
	if uid == equipped_uid:
		return true
	stash_equipped()
	player.equip_stationery("")
	var weapon = weapon_nodes.get(uid)
	if not is_instance_valid(weapon):
		return false
	weapon.process_mode = Node.PROCESS_MODE_INHERIT
	weapon.get_parent().remove_child(weapon)
	player.body.equip(weapon)
	player.weapon = weapon
	player.body.punch_time = weapon.swing_time
	equipped_uid = uid
	player._emit_weapon()
	_commit()
	return true

func detach_equipped() -> void:
	if not equipped_uid.is_empty():
		var uid := equipped_uid
		equipped_uid = ""
		weapon_nodes.erase(uid)
		_erase_entry(uid)
		_commit()

func _erase_entry(uid: String) -> void:
	var entry := entry_for(uid)
	if not entry.is_empty():
		entries.erase(entry)
	for i in 4:
		if quick_slots[i] == uid:
			quick_slots[i] = ""

func remove_items(id: String, amount: int, allow_keys: bool = false) -> bool:
	if amount <= 0 or not has_item(id,amount):
		return false
	var definition = Catalog.get_item(id)
	if definition.category == Item.Category.CLAVE and not allow_keys:
		return false
	var remaining := amount
	for entry in entries.duplicate():
		if entry.item_id != id or remaining <= 0:
			continue
		var taken := mini(remaining,entry.quantity)
		entry.quantity -= taken
		remaining -= taken
		if entry.quantity <= 0:
			if entry.uid == equipped_uid:
				stash_equipped()
			if weapon_nodes.has(entry.uid):
				var weapon = weapon_nodes[entry.uid]
				weapon_nodes.erase(entry.uid)
				if is_instance_valid(weapon):
					weapon.queue_free()
			_erase_entry(entry.uid)
	_sync_paper(id)
	_commit()
	return true

func assign_quick(slot: int, uid: String) -> bool:
	if slot < 0 or slot >= 4 or (not uid.is_empty() and entry_for(uid).is_empty()):
		return false
	quick_slots[slot] = uid
	_commit()
	return true

func _auto_slot(uid: String) -> void:
	var item = Catalog.get_item(entry_for(uid).item_id)
	if item.category in [Item.Category.CLAVE,Item.Category.PAPELERIA]:
		return
	for i in 4:
		if quick_slots[i].is_empty():
			quick_slots[i] = uid
			return

func use_quick(slot: int) -> bool:
	if slot < 0 or slot >= 4:
		return false
	return use_entry(quick_slots[slot])

func use_entry(uid: String) -> bool:
	var entry := entry_for(uid)
	if entry.is_empty() or player.dead:
		return false
	var ui = player.get("inventory_ui")
	if player.busy and (ui == null or not ui.panel.visible):
		return false
	var item = Catalog.get_item(entry.item_id)
	match item.category:
		Item.Category.ARMA, Item.Category.PAPELERIA:
			return equip_entry(uid)
		Item.Category.CLAVE:
			notice.emit("Objeto clave: %s. Se conserva para los accesos." % item.display_name)
			return false
		Item.Category.CONSUMIBLE:
			if item.full_heal or item.heal_amount > 0:
				if player.health >= player.max_health:
					notice.emit("Ya tienes la vida completa.")
					return false
				var academic_bonus := 5.0 if entry.item_id == "Botiquin" and has_item("KitClinicoMejorado",1) else 0.0
				player.heal(player.max_health if item.full_heal else item.heal_amount+academic_bonus)
			elif item.speed_multiplier > 1:
				player.apply_speed_boost(item.speed_multiplier,item.duration)
			else:
				return false
		Item.Category.ESPECIAL:
			if not _use_special(item):
				notice.emit("No hay un objetivo compatible a la vista.")
				return false
	entry.quantity -= 1
	if entry.quantity <= 0:
		_erase_entry(uid)
	_commit()
	notice.emit("Usaste: " + item.display_name)
	item_used.emit(item.id)
	return true

func _use_special(item: Resource) -> bool:
	var best: Node3D
	var receiver: Node
	var distance: float = item.effect_range
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy is Node3D or enemy.get("dead") == true or absf(enemy.global_position.y-player.global_position.y) > 2.5:
			continue
		var component := enemy.get_node_or_null("ItemEffects")
		var d: float = enemy.global_position.distance_to(player.global_position)
		if component and component.can_apply(item.id) and d < distance and player._can_reach(enemy):
			best = enemy
			receiver = component
			distance = d
	return receiver != null and is_instance_valid(best) and receiver.apply_item(item,player)

func _sync_paper(id: String) -> void:
	var item = Catalog.get_item(id)
	if item and item.category == Item.Category.PAPELERIA:
		player.stationery_inventory[id] = count_item(id)
		player.save_stationery()

func _commit() -> void:
	changed.emit()
	if persist:
		save_data()

func snapshot_data() -> Dictionary:
	var stored: Array = []
	for entry in entries:
		var snapshot: Dictionary = entry.duplicate(true)
		if weapon_nodes.has(entry.uid) and is_instance_valid(weapon_nodes[entry.uid]):
			snapshot.data = {"durability":weapon_nodes[entry.uid].durability,"max_durability":weapon_nodes[entry.uid].get_meta("max_durability",weapon_nodes[entry.uid].durability)}
		stored.append(snapshot)
	return {"version":1,"serial":serial,"entries":stored,"quick":quick_slots,"equipped":equipped_uid}

func save_data() -> void:
	var file := FileAccess.open(save_path,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(snapshot_data()))

func load_data() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var data = preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(save_path)
	_load_snapshot(data)

func restore_snapshot(data: Dictionary) -> void:
	var old_persist := persist
	persist = false
	if player.weapon != null:
		var equipped = player.body.unequip()
		player.weapon = null
		if is_instance_valid(equipped):
			equipped.queue_free()
	for weapon in weapon_nodes.values():
		if is_instance_valid(weapon) and not weapon.is_queued_for_deletion():
			weapon.queue_free()
	weapon_nodes.clear()
	entries.clear()
	equipped_uid = ""
	quick_slots = ["","","",""]
	_load_snapshot(data)
	persist = old_persist
	changed.emit()

func _load_snapshot(data: Variant) -> void:
	if not data is Dictionary or data.get("version") != 1 or not data.get("entries") is Array:
		return
	serial = maxi(0,int(data.get("serial",0)))
	for value in data.entries:
		if not value is Dictionary:
			continue
		var item = Catalog.get_item(str(value.get("item_id","")))
		var uid := str(value.get("uid",""))
		if item == null or uid.is_empty() or not entry_for(uid).is_empty():
			continue
		var quantity := clampi(int(value.get("quantity",0)),0,item.max_stack)
		if quantity == 0:
			continue
		var entry := {"uid":uid,"item_id":item.id,"quantity":quantity,"data":{}}
		if value.has("favorite"): entry["favorite"] = value.get("favorite",false) == true
		entries.append(entry)
		serial = maxi(serial,int(uid.trim_prefix("item_")))
		if item.category == Item.Category.ARMA:
			var weapon := create_weapon(item.id)
			storage.add_child(weapon)
			var stats = value.get("data",{})
			if stats is Dictionary:
				weapon.set_meta("max_durability",maxi(weapon.durability,int(stats.get("max_durability",weapon.durability))))
				weapon.durability = clampi(int(stats.get("durability",weapon.durability)),1,weapon.durability)
			weapon.pick_up()
			weapon.process_mode = Node.PROCESS_MODE_DISABLED
			weapon_nodes[uid] = weapon
			weapon.set_meta("inventory_uid",uid)
	var slots = data.get("quick",[])
	if slots is Array:
		for i in mini(4,slots.size()):
			var uid := str(slots[i])
			quick_slots[i] = uid if not entry_for(uid).is_empty() else ""
	var equipped := str(data.get("equipped",""))
	if not equipped.is_empty() and weapon_nodes.has(equipped):
		call_deferred("equip_entry",equipped)

func _exit_tree() -> void:
	if persist and is_instance_valid(player):
		save_data()

