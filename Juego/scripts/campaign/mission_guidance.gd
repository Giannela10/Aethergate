extends Node
## Un único marcador sigue el objetivo principal pendiente.
var campaign: Node
var target: Node3D
var hint := ""
var marker: Label3D
var refresh_time := 0.0
var arrows: Array[MeshInstance3D] = []

func _ready() -> void:
	marker = Label3D.new()
	marker.name = "MarcadorMisionPrincipal"
	marker.font_size = 52
	marker.pixel_size = 0.008
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.modulate = Color("ffe075")
	marker.outline_modulate = Color("#182738")
	campaign.add_child(marker)
	marker.hide()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color("#ffe163")
	var shape := SurfaceTool.new()
	shape.begin(Mesh.PRIMITIVE_TRIANGLES)
	shape.set_material(material)
	# Dos alas con un hueco detrás de la punta.
	var points := [
		Vector3(-0.7,0,0.30), Vector3(0,0,-0.46), Vector3(0,0,-0.09),
		Vector3(-0.7,0,0.30), Vector3(0,0,-0.09), Vector3(-0.70,0,0.02),
		Vector3(0.70,0,0.30), Vector3(0,0,-0.46), Vector3(0,0,-0.09),
		Vector3(0.70,0,0.30), Vector3(0,0,-0.09), Vector3(0.70,0,0.02),
	]
	for point in points:
		shape.add_vertex(point)
	var mesh := shape.commit()
	for i in 4:
		var arrow := MeshInstance3D.new()
		arrow.mesh = mesh
		arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		campaign.add_child(arrow)
		arrow.hide()
		arrows.append(arrow)

func _physics_process(delta: float) -> void:
	refresh_time -= delta
	if refresh_time > 0:
		return
	refresh_time = 0.15
	target = null
	hint = ""
	for arrow in arrows:
		arrow.hide()
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
				marker.global_position = target.global_position+Vector3.UP*3.15
				marker.text = "◆\n%d m" % ceili(distance)
				marker.visible = not campaign.player.dead and not is_instance_valid(campaign.active_duel)
				if marker.visible and requirement.id == "punto":
					_show_entrance_arrows()
			else:
				marker.hide()
				hint = "M: consulta los requisitos de esta etapa."
			return
	marker.hide()

func _show_entrance_arrows() -> void:
	var player: CharacterBody3D = campaign.player
	var from := player.global_position
	if from.z < -74.0 or absf(from.y) > 2.0:
		return
	var gate := Vector3(3, from.y, -28)
	var destination := gate if from.z > -26.0 else Vector3(3, from.y, -67)
	var direction := (destination-from).normalized()
	var length := from.distance_to(destination)
	var space := player.get_world_3d().direct_space_state
	var exclude: Array[RID] = [player.get_rid()]
	for i in arrows.size():
		var step := 4.0 + 2.2*i
		if step >= length:
			break
		var at := from + direction*step
		var obstruction := PhysicsRayQueryParameters3D.create(from+Vector3.UP, at+Vector3.UP, 1, exclude)
		if not space.intersect_ray(obstruction).is_empty():
			break
		var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP, at-Vector3.UP*2, 1, exclude))
		if ground.is_empty() or ground.normal.y < 0.7:
			break
		arrows[i].global_position = ground.position+Vector3.UP*0.06
		arrows[i].rotation.y = atan2(-direction.x, -direction.z)
		arrows[i].show()

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
