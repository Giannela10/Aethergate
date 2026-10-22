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
	if campaign and not respawn:
		if campaign.data.collected.get(world_id,false):
			quantity = 0
		else:
			var remaining = campaign.data.get("remaining_quantity",{}).get(world_id,quantity)
			if remaining is int or remaining is float:
				quantity = clampi(int(remaining),0,quantity)
		if quantity <= 0:
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
		# Chairs stand on their legs; elongated weapons rest on their side.
		weapon_display.rotation.z = 0.0 if item.weapon_kind == "silla" else PI/2
		weapon_display.position.y = 0.28
		weapon_display.set_process(false)

func visual_bounds() -> AABB:
	var bounds := AABB()
	var found := false
	for mesh in find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree(): continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = bounds.merge(box) if found else box
		found = true
	return bounds

func placement_clear(space: PhysicsDirectSpaceState3D, surface: Vector3, excluded: Array[RID]) -> bool:
	var bounds := visual_bounds()
	if bounds.size.is_zero_approx(): return true
	var center := bounds.get_center()-global_position
	# Check the actual footprint, including long weapons and chair legs. A clear
	# capsule at the item's origin alone does not prevent overhangs at stairs.
	var half := Vector2(bounds.size.x,bounds.size.z)*0.5
	for offset in [Vector2.ZERO,Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(-half.x,half.y),Vector2(half.x,half.y)]:
		var sample: Vector3 = surface+Vector3(center.x+offset.x,0,center.z+offset.y)
		var ray := PhysicsRayQueryParameters3D.create(sample+Vector3.UP*0.15,sample-Vector3.UP*0.15,1,excluded)
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or hit.normal.y < 0.95 or absf(hit.position.y-surface.y) > 0.06: return false
	var shape := BoxShape3D.new()
	shape.size = Vector3(maxf(bounds.size.x,0.025),maxf(bounds.size.y,0.025),maxf(bounds.size.z,0.025))
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = excluded
	query.margin = 0.001
	query.transform.origin = surface+Vector3(center.x,shape.size.y*0.5+0.015,center.z)
	return space.intersect_shape(query,1).is_empty()

func ground_visuals(surface_y: float) -> void:
	var bounds := visual_bounds()
	if bounds.size.is_zero_approx(): return
	var adjustment := surface_y+0.015-bounds.position.y
	if is_instance_valid(weapon_display):
		weapon_display.global_position.y += adjustment
	else:
		for child in get_children():
			if child is MeshInstance3D and child.visible:
				child.global_position.y += adjustment

func interaction_text(_player: Node) -> String:
	var item = Catalog.get_item(item_id)
	return "" if collected or item == null else "[E] Recoger %s x%d" % [item.display_name,quantity]

func interact(player: CharacterBody3D) -> void:
	if player.dead or player.busy or player.global_position.distance_to(global_position) > interaction_range or not player._can_reach(self):
		return
	if collected:
		return
	var accepted: int = player.receive_item(item_id,quantity)
	if accepted <= 0:
		return
	quantity = maxi(0,quantity-accepted)
	collected = quantity <= 0
	if collected:
		remove_from_group("campus_interactable")
		hide()
	elif is_instance_valid(prompt):
		prompt.text = interaction_text(player)
	if campaign:
		if not campaign.data.get("remaining_quantity") is Dictionary:
			campaign.data.remaining_quantity = {}
		campaign.data.remaining_quantity[world_id] = quantity
		campaign.data.collected[world_id] = collected
		if collected and not collectible_kind.is_empty():
			campaign.event(collectible_kind,world_id)
		if collected and not note_text.is_empty():
			campaign.data.notes[world_id] = note_text
			player.stationery_notes += "\n"+note_text
			if not player.inventory.has_item("cuaderno"):
				player.receive_stationery("cuaderno")
			player.save_stationery()
		campaign.ui.notify(pickup_message if not pickup_message.is_empty() else "Recogiste: "+Catalog.get_item(item_id).display_name)
		campaign.save_game()
	# Conservar nodo e ID para restauración de partidas y pruebas.
	if collected and is_instance_valid(weapon_display):
		weapon_display.hide()

func _process(delta: float) -> void:
	if important and not collected and is_instance_valid(weapon_display):
		weapon_display.rotate_y(delta*0.2)

func interaction_priority() -> int:
	return 1
