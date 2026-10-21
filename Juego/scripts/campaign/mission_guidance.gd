extends Node
## Un único marcador sigue el objetivo principal pendiente.
var campaign: Node
var target: Node3D
var hint := ""
var marker: Label3D
var refresh_time := 0.0

func _ready() -> void:
	marker = Label3D.new()
	marker.name = "MarcadorMisionPrincipal"
	marker.font_size = 52
	marker.pixel_size = 0.008
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.modulate = Color("ffe075")
	campaign.add_child(marker)
	marker.hide()

func _process(delta: float) -> void:
	refresh_time -= delta
	if refresh_time > 0:
		return
	refresh_time = 0.15
	target = null
	hint = ""
	if not campaign.ready_for_play or not campaign.quests:
		marker.hide()
		return
	for id in campaign.quests.definitions:
		var quest = campaign.quests.definitions[id]
		if not quest.main_quest or campaign.quests.state(id) != 1:
			continue
		for requirement in quest.requirements:
			if requirement.get("optional",false): continue
			if campaign.quests.progress(requirement) >= requirement.amount:
				continue
			target = find_target(requirement)
			if is_instance_valid(target):
				var distance: float = campaign.player.global_position.distance_to(target.global_position)
				var floor_number := nearest_floor(target.global_position.y)
				hint = "SIGUE EL MARCADOR AMARILLO · Piso %s · %d m\nAcércate hasta ver [E] para interactuar. M: lista de tareas." % [floor_number,ceili(distance)]
				if requirement.id == "punto":
					hint += "\nPunto Estudiantil: al fondo del pasillo, lado izquierdo."
				elif requirement.id == "pc_intro":
					hint += "\nComputador inicial: cerca de la entrada principal."
				elif requirement.id == "chef":
					hint += "\nChef: en el casino del primer piso."
				marker.global_position = target.global_position+Vector3.UP*5.2
				marker.text = "! MISIÓN PRINCIPAL\n"+requirement.text+"\n%d m · Piso %s" % [ceili(distance),floor_number]
				marker.visible = not campaign.player.dead and not is_instance_valid(campaign.active_duel)
			else:
				marker.hide()
				hint = "M: consulta los requisitos de esta etapa."
			return
	marker.hide()

func nearest_floor(height: float) -> String:
	var heights = load("res://scripts/campaign/campus_content.gd").HEIGHTS
	var nearest := 0
	for i in heights.size():
		if absf(height-heights[i]) < absf(height-heights[nearest]):
			nearest = i
	return "−1" if nearest == 8 else str(nearest+1)

func find_target(requirement: Dictionary) -> Node3D:
	if requirement.kind == "door" and requirement.id == "nexo_core" and campaign.final_area != null:
		return campaign.final_area.access
	if requirement.kind == "boss" and requirement.id == "director" and campaign.academic_expansion != null:
		for flag in ["director_task_network","director_task_antivirus","director_task_config"]:
			if not campaign.academic_expansion.state.flags.get(flag,false):
				return campaign.get_node_or_null("director_antivirus" if flag == "director_task_antivirus" else ("DirectorConnection" if flag == "director_task_network" else "DirectorPC01"))
	if requirement.kind == "academic_task":
		return campaign.get_node_or_null("director_antivirus" if requirement.id == "director_task_antivirus" else ("DirectorConnection" if requirement.id == "director_task_network" else "DirectorPC01"))
	if requirement.kind == "academic_any":
		for duel in get_tree().get_nodes_in_group("boss_duel"):
			if duel.boss_id in ["profesor_datos","profesor_algoritmos"] and not duel.defeated: return duel.actor
	match requirement.kind:
		"talk", "boss":
			for duel in get_tree().get_nodes_in_group("boss_duel"):
				if duel.boss_id == requirement.id and not duel.defeated:
					return duel.actor
		"computer":
			for computer in get_tree().get_nodes_in_group("computer"):
				if computer.get_meta("campaign_id","") == requirement.id and not computer.done:
					return computer
		"collect":
			var nearest: Node3D
			var best_distance := INF
			for node in campaign.get_children():
				if not node is Node3D or node.get("collected") != false or node.get("item_id") == null:
					continue
				if requirement.id != "*" and node.item_id != requirement.id:
					continue
				var distance: float = campaign.player.global_position.distance_to(node.global_position)
				if distance < best_distance:
					nearest = node
					best_distance = distance
			return nearest
		"secret":
			return campaign.get_node_or_null("Secreto_"+requirement.id)
		"floor":
			for checkpoint in get_tree().get_nodes_in_group("campus_checkpoint"):
				if nearest_floor(checkpoint.global_position.y) == requirement.id:
					return checkpoint
		"door":
			for node in get_tree().get_nodes_in_group("campus_interactable"):
				if node.get("access_id") == requirement.id:
					return node
	return null
