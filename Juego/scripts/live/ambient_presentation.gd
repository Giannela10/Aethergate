extends RefCounted
## Temporary CharacterVisual instances only: no new NPC AI, quests or saved actors.
var hub: Node
var bodies: Array[Dictionary] = []
var clock := 0.0
func _init(owner_hub: Node) -> void:
	hub = owner_hub
func populate(root: Node3D, event: Resource) -> void:
	var role := "PROFESOR" if event.anchor == "teachers" or event.event_id == "profesor_salida" else ("TALLER" if event.anchor == "workshop" else "ESTUDIANTE")
	var count := 0
	var minute := int(hub.campaign.academics.current_time().minute)
	var limit := 2 if event.anchor == "biblioteca" and (minute < 540 or minute > 1020) else 3
	if event.event_id in ["biblioteca_estudio","casino_almuerzo","evaluacion","trabajo_grupo","docentes_reunion","discusion_docente"]:
		for pickup in hub.get_tree().get_nodes_in_group("campus_chair"):
			if count >= limit: break
			if pickup.collected or not pickup.furniture.is_visible_in_tree() or pickup.global_position.distance_to(root.global_position) > 12: continue
			if hub.campaign.phone._floor_for(pickup) != hub.floor_id(): continue
			var floor_position = hub.campaign.player.get_node("SeatController").safe_position(pickup.furniture.global_position,pickup.furniture)
			if floor_position == null: continue
			var body := _body(root,event,role,count)
			body.global_position = floor_position
			body.global_rotation.y = pickup.furniture.global_rotation.y
			var seat_height: float = pickup.furniture.global_position.y+0.6
			for mesh in pickup.furniture.find_children("*","MeshInstance3D",true,false):
				if "asiento" in str(mesh.name).to_lower() or "cojin" in str(mesh.name).to_lower():
					seat_height = mesh.to_global(Vector3(0,mesh.mesh.get_aabb().end.y,0)).y
					break
			body.contextual_pose.seated = true
			body.contextual_pose.seat_height = clampf((seat_height-floor_position.y)/body.scale.y,0.3,0.9)
			bodies.append({"body":body,"seat":pickup.furniture,"start":body.global_position,"end":body.global_position})
			count += 1
	if count >= 2: return
	for offset in [Vector3(1.8,0,0),Vector3(-1.8,0,0),Vector3(0,0,1.8)]:
		if count >= limit: break
		var position = hub.campaign.player.get_node("SeatController").safe_position(root.global_position+offset)
		if position == null or position.distance_to(hub.campaign.player.global_position) < 1.2: continue
		var body := _body(root,event,role,count)
		body.global_position = position
		var end: Vector3 = position
		if event.event_id in ["entrada","ascensor_espera","taller_inspeccion","profesor_salida"]:
			var candidate = hub.campaign.player.get_node("SeatController").safe_position(position+Vector3(0,0,1))
			if candidate != null:
				var ray := PhysicsRayQueryParameters3D.create(position+Vector3.UP*1.2,candidate+Vector3.UP*1.2)
				ray.exclude = [hub.campaign.player.get_rid()]
				if root.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): end = candidate
		bodies.append({"body":body,"seat":null,"start":position,"end":end})
		var facing: Vector3 = root.global_position-position
		body.rotation.y = atan2(-facing.x,-facing.z)
		count += 1
func _body(root: Node3D, event: Resource, role: String, index: int) -> Node3D:
	var body := preload("res://scripts/juego/student_visual.gd").new()
	body.name = "FiguranteAmbiental"+str(index)
	body.scale = Vector3.ONE*1.4
	root.add_child(body)
	var presets = preload("res://scripts/juego/character_visual_presets.gd")
	presets.apply(body,presets.create("ambient:"+event.event_id+":"+str(index),role))
	body.set_visual_activity(event.action,event.prop)
	if hub.settings != null:
		var quality: Dictionary = hub.settings.QUALITIES[hub.settings.data.quality]
		body.visual_near_distance = quality.near
		body.visual_far_distance = quality.far
		body.cast_near_shadows = quality.shadows
		if not quality.shadows:
			for mesh in body.find_children("*","MeshInstance3D",true,false): mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return body
func update(delta: float) -> void:
	clock += delta
	for record in bodies:
		var body = record.body
		if not is_instance_valid(body): continue
		if is_instance_valid(record.seat) and not record.seat.is_visible_in_tree():
			body.hide()
			continue
		var before: Vector3 = body.global_position
		body.global_position = Vector3(record.start).lerp(Vector3(record.end),0.5-0.5*cos(clock*0.6))
		var velocity: Vector3 = (body.global_position-before)/maxf(delta,0.001)
		if Vector2(velocity.x,velocity.z).length() > 0.05:
			body.rotation.y = lerp_angle(body.rotation.y,atan2(-velocity.x,-velocity.z),minf(1,delta*6))
		body.animate(delta,velocity,true,false)
func clear() -> void:
	for record in bodies:
		if is_instance_valid(record.body): record.body.queue_free()
	bodies.clear()
