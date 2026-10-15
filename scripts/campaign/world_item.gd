extends "res://scripts/inventory/inventory_pickup.gd"
var interaction_range := 1.8
@export var world_id := ""
@export var respawn := false
@export var pickup_message := ""
@export var important := false
@export var collectible_kind := ""
@export var note_text := ""
var campaign: Node
var weapon_display: Node3D

func _ready() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	if campaign and campaign.data.collected.get(world_id,false) and not respawn:
		collected = true
		hide()
		return
	super._ready()
	remove_from_group("inventory_pickup")
	add_to_group("campus_interactable")
	if prompt:
		prompt.hide()
	var item = Catalog.get_item(item_id)
	if item and item.category == 1:
		# Modelo físico del arma, sin duplicar su lógica de combate.
		for child in get_children():
			if child is MeshInstance3D:
				child.hide()
		weapon_display = campaign.player.inventory.create_weapon(item_id)
		add_child(weapon_display)
		weapon_display.pick_up()
		weapon_display.remove_from_group("weapon_pickup")
		weapon_display.rotation.z = PI/2
		weapon_display.position.y = 0.28
		weapon_display.set_process(false)

func interaction_text(_player: Node) -> String:
	var item = Catalog.get_item(item_id)
	return "" if collected or item == null else "[E] Recoger "+item.display_name

func interact(player: CharacterBody3D) -> void:
	if player.dead or player.busy or player.global_position.distance_to(global_position) > interaction_range or not player._can_reach(self):
		return
	if collected:
		return
	if player.receive_item(item_id,quantity) <= 0:
		return
	collected = true
	remove_from_group("campus_interactable")
	hide()
	if campaign:
		campaign.data.collected[world_id] = true
		if not collectible_kind.is_empty():
			campaign.event(collectible_kind,world_id)
		if not note_text.is_empty():
			campaign.data.notes[world_id] = note_text
			player.stationery_notes += "\n"+note_text
			if not player.inventory.has_item("cuaderno"):
				player.receive_stationery("cuaderno")
			player.save_stationery()
		campaign.ui.notify(pickup_message if not pickup_message.is_empty() else "Recogiste: "+Catalog.get_item(item_id).display_name)
		campaign.save_game()
	# Conservar nodo e ID para restauración de partidas y pruebas.
	if is_instance_valid(weapon_display):
		weapon_display.hide()

func _process(delta: float) -> void:
	if important and not collected and is_instance_valid(weapon_display):
		weapon_display.rotate_y(delta*0.2)

func interaction_priority() -> int:
	return 1
