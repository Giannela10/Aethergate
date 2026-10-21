extends Node
var campaign: Node
var selected: Node3D
var action := ""
var selected_kind := ""
var refresh_t := 0.0

func _process(delta: float) -> void:
	refresh_t -= delta
	if refresh_t <= 0:
		refresh_t = 0.08
		scan()
	campaign.ui.context.text = action if not campaign.player.busy and not campaign.player.dead else ""

func scan() -> void:
	selected = null
	action = ""
	var player = campaign.player
	if player.dead or player.busy or get_tree().paused:
		return
	var seating: Node = player.get_node_or_null("SeatController")
	if seating and is_instance_valid(seating.seat):
		action = "[E] Levantarse · P celular · I inventario"
		return
	var best := INF
	for group in ["campus_interactable","stationery_vendor","inventory_pickup","weapon_pickup","computer"]:
		for node in get_tree().get_nodes_in_group(group):
			if not node is Node3D or node.is_queued_for_deletion():
				continue
			var delta_pos: Vector3 = node.global_position-player.global_position
			if absf(delta_pos.y) > 2.8: continue
			var priority: float = {"campus_interactable":0,"stationery_vendor":0,"inventory_pickup":1,"weapon_pickup":1,"computer":3}[group]
			if node.has_method("interaction_priority"):
				priority = node.interaction_priority()
			var limit: float = node.interaction_range if node.get("interaction_range") != null else (4.5 if priority == 0 else (2.2 if group == "computer" else 1.8))
			if delta_pos.length_squared() > limit*limit or not player._can_reach(node.interaction_target() if node.has_method("interaction_target") else node):
				continue
			var distance := delta_pos.length()
			var text := ""
			match group:
				"campus_interactable": text = node.interaction_text(player)
				"stationery_vendor": text = "[E] Hablar con Papelería"
				"inventory_pickup": text = "[E] Recoger "+str(node.item_id)
				"weapon_pickup": text = "[E] Recoger "+str(node.weapon_name)
				"computer": text = "[E] Iniciar minijuego" if not node.done else ""
			if text.is_empty():
				continue
			var camera: Camera3D = player.get_viewport().get_camera_3d()
			var alignment := 0.0
			if camera and distance > 0.1:
				alignment = (-camera.global_basis.z).dot(delta_pos.normalized())
			var score: float = priority*10 + distance-alignment*1.2
			if score < best:
				best = score
				selected = node
				selected_kind = group
				action = text

func _context_action(node: Node) -> String:
	if node.has_method("context_action"):
		return str(node.context_action())
	if selected_kind in ["inventory_pickup","weapon_pickup"]:
		return "pickup"
	if selected_kind == "computer":
		return "computer"
	if selected_kind == "stationery_vendor" or node.is_in_group("boss_duel"):
		return "talk"
	var script = node.get_script()
	var file: String = script.resource_path.get_file() if script else ""
	return {"npc.gd":"talk","campus_vendor.gd":"vending","furniture_pickup.gd":"pickup","world_item.gd":"pickup","locked_access.gd":"door","elevator_interaction.gd":"elevator","network_router_interactable.gd":"button"}.get(file,"")

func interact_selected() -> bool:
	scan()
	if not is_instance_valid(selected):
		return false
	var node := selected
	var context := _context_action(node)
	if not context.is_empty() and campaign.player.body.has_method("play_context_action"):
		campaign.player.body.play_context_action(context)
	match selected_kind:
		"campus_interactable","stationery_vendor": node.interact(campaign.player)
		"inventory_pickup": node.collect(campaign.player)
		"weapon_pickup": campaign.player.inventory.collect_weapon(node,false)
		"computer": campaign.player._use_computer(node)
	return true
