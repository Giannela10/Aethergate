extends Node3D
## Convierte una silla del escenario en un arma sin dejar colisiones invisibles.
var interaction_range := 2.2
var campaign: Node
var furniture: Node3D
var world_id := ""
var collected := false

func _ready() -> void:
	furniture = get_parent()
	world_id = "silla:"+str(campaign.get_parent().get_path_to(furniture))
	add_to_group("campus_chair")
	if campaign.data.collected.get(world_id,false):
		_remove_furniture()
	else:
		add_to_group("campus_interactable")

func interaction_target() -> Node3D:
	return furniture

func interaction_priority() -> int:
	return 1

func interaction_text(_player: Node) -> String:
	return "" if collected else "[E] Tomar silla y equipar"

func interact(player: CharacterBody3D) -> void:
	if collected or player.dead or player.busy or player.global_position.distance_to(global_position) > interaction_range or not player._can_reach(furniture):
		return
	if player.receive_item("Silla",1) <= 0:
		return
	var entry: Dictionary = player.inventory.entries.back()
	player.inventory.equip_entry(entry.uid)
	_remove_furniture()
	campaign.data.collected[world_id] = true
	campaign.ui.notify("Silla equipada · J o clic para atacar · G para soltar")
	campaign.save_game()

func _remove_furniture() -> void:
	collected = true
	remove_from_group("campus_interactable")
	furniture.hide()
	for node in furniture.find_children("*","Node",true,false):
		if node is CSGShape3D:
			node.set_deferred("use_collision",false)
		elif node is CollisionObject3D:
			node.collision_layer = 0
			node.collision_mask = 0
		elif node is CollisionShape3D:
			node.set_deferred("disabled",true)

static func setup(campaign_node: Node3D) -> void:
	_group_casino_chairs(campaign_node)
	for node in campaign_node.get_parent().find_children("*","Node3D",true,false):
		var title := str(node.name).to_lower()
		if node.get_class() != "Node3D" or not (title.begins_with("silla") or title.begins_with("chair")):
			continue
		if not node.has_node("Asiento") and not node.has_node("Respaldo"):
			continue
		if node.has_node("RecogerSilla"):
			continue
		var pickup = load("res://scripts/campaign/furniture_pickup.gd").new()
		pickup.name = "RecogerSilla"
		pickup.campaign = campaign_node
		node.add_child(pickup)

static func _group_casino_chairs(campaign_node: Node) -> void:
	var interior := campaign_node.get_parent().get_node_or_null("Piso1/Casino/InteriorFotografico")
	if interior == null:
		return
	var children := interior.get_children()
	var number := 0
	for i in children.size():
		var seat = children[i]
		if not str(seat.name).begins_with("Asiento") or i+5 >= children.size():
			continue
		if not str(children[i+1].name).begins_with("Respaldo"):
			continue
		var chair := Node3D.new()
		chair.name = "SillaCasino_%03d" % number
		number += 1
		interior.add_child(chair)
		chair.global_position = Vector3(seat.global_position.x,interior.global_position.y,seat.global_position.z)
		for part in range(i,i+6):
			children[part].reparent(chair,true)
		seat.name = "Asiento"
		children[i+1].name = "Respaldo"
