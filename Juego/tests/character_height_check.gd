extends Node3D
## Isolated height/clearance fixture. Never saves the user's campaign.
const OUT = "res://reports/character_height/"
var campus: Node3D
var campaign: Node
var camera: Camera3D
var rows: Array = []
var checks: Array = []
var ready_for_checks := false
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	campus = load("res://Main.tscn").instantiate()
	campaign = campus.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized):
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	campaign.ui.close_modal()
	campaign.live.director.set_process(false)
	campaign.get_node("AcademicFloorGate").set_physics_process(false)
	for actor in campus.find_children("*","CharacterBody3D",true,false):
		actor.set_process(false)
		actor.set_physics_process(false)
	for visual in get_tree().get_nodes_in_group("campus_character_visual"):
		visual.get_parent().set_process(false)
		visual.get_parent().set_physics_process(false)
	campaign.manager.set_process(false)
	camera = Camera3D.new()
	camera.fov = 58
	add_child(camera)
	camera.make_current()
	await snapshot("baseline" if not campaign.player.body.has_method("normalize_visual_height") else "after")
	campaign.player.global_position = Vector3(4,0.14,-48)
	campaign.player.velocity = Vector3.ZERO
	campaign.player.busy = false
	campaign.player.set_process(true)
	campaign.player.set_physics_process(true)
	camera.global_position = Vector3(4,2.0,-54)
	camera.look_at(Vector3(4,1.4,-48))
	ready_for_checks = true
	print("HEIGHT_FIXTURE_READY")
	run_checks.call_deferred()
func model_for(v: Node3D) -> Node3D:
	var model = v.get("human62")
	if model != null and model.active: return model
	var adapter = v.get("human_visual63")
	return adapter.model if adapter != null else null
func bound(mesh: MeshInstance3D) -> AABB:
	var baked: ArrayMesh = mesh.bake_mesh_from_current_skeleton_pose() if mesh.skin != null else mesh.mesh
	var transforms: Array[Transform3D] = []
	if mesh.skin != null and mesh.get_blend_shape_count() > 0:
		# Godot's skeleton bake omits live morphs. Measure the actual mixed vertices.
		baked = mesh.bake_mesh_from_current_blend_shape_mix()
		var skeleton = mesh.get_node(mesh.skeleton)
		for i in mesh.skin.get_bind_count():
			var bone = mesh.skin.get_bind_bone(i)
			if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(i))
			transforms.append(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(i))
	var result := AABB()
	var first := true
	for surface in baked.get_surface_count():
		var vertices = baked.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		var original = mesh.mesh.surface_get_arrays(surface)
		var bones = original[Mesh.ARRAY_BONES]
		var weights = original[Mesh.ARRAY_WEIGHTS]
		var stride = int(weights.size()/vertices.size()) if weights != null else 0
		for index in vertices.size():
			var vertex: Vector3 = vertices[index]
			if not transforms.is_empty():
				var skinned := Vector3.ZERO
				for j in stride:
					skinned += (transforms[bones[index*stride+j]]*vertex)*weights[index*stride+j]
				vertex = skinned
			var point: Vector3 = mesh.global_transform * vertex
			if first: result = AABB(point,Vector3.ZERO); first = false
			else: result = result.expand(point)
	return result
func measure(v: Node3D) -> Dictionary:
	var model = model_for(v)
	var actor = v.get_parent()
	var preset: Dictionary = v.get_meta("visual_preset",{})
	var row = {"path":str(v.get_path()),"actor_script":actor.get_script().resource_path if actor.get_script() else "",
		"id":preset.get("visual_id",str(actor.name)),"role":preset.get("role",""),"root_scale":str(actor.global_basis.get_scale()),
		"visual_scale":str(v.global_basis.get_scale()),"origin":str(v.global_position),"imported":model != null,"colliders":[]}
	for child in actor.get_children():
		if child is CollisionShape3D and child.shape is CapsuleShape3D:
			row.colliders.append({"height":child.shape.height,"radius":child.shape.radius,"offset":child.position.y,"disabled":child.disabled})
	if model != null:
		model.rig.force_update_all_bone_transforms()
		var body_mesh = model.human.find_child("Body",true,false)
		var shoes = model.footwear63.mesh
		var bb = bound(body_mesh)
		var sb = bound(shoes)
		row["crown_y"] = bb.end.y
		row["sole_y"] = sb.position.y
		row["height"] = bb.end.y-sb.position.y
		row["feet_to_origin"] = sb.position.y-v.global_position.y
		row["rig_bones"] = model.rig.get_bone_count()
		var ray = PhysicsRayQueryParameters3D.create(sb.get_center()+Vector3.UP*0.5,sb.get_center()-Vector3.UP*0.8,1)
		if actor is CollisionObject3D: ray.exclude = [actor.get_rid()]
		var hit = v.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			var surface_y = preload("res://scripts/juego/character_ground_6_3.gd").height_at(model,sb.get_center(),hit.position.y)
			row["floor_y"] = hit.position.y
			row["render_clearance"] = sb.position.y-surface_y
		row["model_scale"] = str(model.global_basis.get_scale())
		row["wardrobe"] = model.get("wardrobe")
		row["sockets_finite"] = true
		for socket in model.socket_defaults:
			row.sockets_finite = row.sockets_finite and socket.global_transform.is_finite()
	return row
func snapshot(label: String) -> void:
	rows.clear()
	for v in get_tree().get_nodes_in_group("campus_character_visual"):
		if not v.is_visible_in_tree(): continue
		campaign.player.global_position = v.global_position+Vector3(3,0,2)
		v.lod_tick = 0
		v.activity_level = 0
		v.update_visual_lod(1)
		for frame in 12: v.animate(0.1,Vector3.ZERO,true,false)
		v.head_pivot.rotation = Vector3.ZERO
		v.spine.rotation = Vector3.ZERO
		v.hips.rotation = Vector3.ZERO
		v.spine.position.y = 0.05
		var imported = model_for(v)
		if imported != null: imported.update_pose(0.0)
		await get_tree().process_frame
		rows.append(measure(v))
	write(label+"_inventory",rows)
	print("HEIGHT_SNAPSHOT ",label," ",JSON.stringify(rows))
func write(label: String, data: Variant) -> void:
	var file = FileAccess.open(OUT+label+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"))
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+label+".png")

func record(label: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"test":label,"passed":passed,"detail":detail})
	print("HEIGHT_CHECK ",label," ",passed)
func run_checks() -> void:
	checks.clear()
	await lineup()
	var player = campaign.player
	player.global_position = Vector3(4,0.14,-48)
	player.velocity = Vector3.ZERO
	player.busy = false
	player.set_process(true)
	player.set_physics_process(true)
	campaign.manager.set_process(true)
	campaign.manager.cam.make_current()
	await get_tree().create_timer(0.4).timeout
	var start = player.global_position
	Input.action_press("move_forward")
	await get_tree().create_timer(0.7).timeout
	Input.action_release("move_forward")
	record("actual_walk",player.global_position.distance_to(start)>0.7,player.global_position.distance_to(start))
	var idle_position = player.global_position
	await get_tree().create_timer(0.3).timeout
	record("idle_stable",absf(player.global_position.y-idle_position.y)<0.08,player.is_on_floor())
	Input.action_press("punch")
	await get_tree().create_timer(0.15).timeout
	record("actual_attack_animation",player.body.is_punching(),player.body.visual_state)
	Input.action_release("punch")
	await get_tree().create_timer(0.65).timeout
	record("third_person_camera",campaign.manager.cam.current and campaign.manager.cam.global_position.distance_to(player.global_position)>1.5,campaign.manager.cam.global_position.distance_to(player.global_position))
	record("player_capsule_unchanged",is_equal_approx(player.standing_capsule.height,2.7) and is_equal_approx(player.standing_capsule.radius,0.45))
	var support = campus.get_node("CampusCampaign/Auxiliar")
	player.global_position = support.global_position+Vector3(0,0,3)
	player.velocity = Vector3.ZERO
	var scanner = player.get_node("InteractionController")
	scanner.scan()
	record("interaction_scanner",scanner.selected==support)
	if scanner.selected==support: scanner.interact_selected()
	else: support.interact(player)
	await get_tree().process_frame
	record("support_dialogue",campaign.ui.modal and player.busy)
	await shot("support_dialogue")
	campaign.ui.close_modal()
	var duel: Node
	for d in get_tree().get_nodes_in_group("boss_duel"):
		if d.boss_id=="profesor_datos": duel=d
	player.global_position = duel.interaction_target().global_position+Vector3(0,0,3)
	player.velocity = Vector3.ZERO
	duel.interact(player)
	await get_tree().process_frame
	record("academic_dialogue",campaign.ui.modal)
	await duel.accept()
	await get_tree().create_timer(0.25).timeout
	record("educational_simulation",duel.state==duel.DuelState.COMBAT and duel.simulation.hologram.visible and duel.simulation.mentor.visible)
	record("mentor_height_in_simulation",absf(measure(duel.simulation.mentor_visual).height-2.7)<0.04)
	await shot("academic_simulation")
	duel.reset_duel()
	campaign.ui.close_modal()
	player.busy=false
	player.dead=false
	player.health=100
	var stair = player.get_node("SeatController").safe_position(Vector3(-22.65,0.15,-150))
	if stair != null:
		player.global_position = stair
		player.velocity = Vector3.ZERO
		player.cam_yaw=0
		campaign.manager.cam_yaw=0
		Input.action_press("move_forward")
		await get_tree().create_timer(1.8).timeout
		Input.action_release("move_forward")
		record("actual_stairs",player.global_position.y-stair.y>0.3,player.global_position.y-stair.y)
	else: record("actual_stairs",false,"No safe starting point")
	var lift = campus.get_node("SistemasCompartidos/AscensoresEstudiantiles").get_child(0)
	player.global_position = lift.cabin.global_position+Vector3(0,0.15,0)
	player.velocity=Vector3.ZERO
	campaign.data.unlocks["2"]=true # Isolated fixture only, no user's campaign saved.
	await get_tree().create_timer(0.6).timeout
	var floor_start = player.global_position.y
	lift.request_floor(1)
	var requested = lift.moving
	var elapsed = 0.0
	while lift.moving and elapsed<8:
		await get_tree().create_timer(0.25).timeout
		elapsed+=0.25
	record("actual_elevator_trip",requested and lift.current_floor==1 and not lift.moving,{"floor":lift.current_floor,"rise":player.global_position.y-floor_start})
	record("riding_platform",absf(player.global_position.y-12.058385849)<0.4,player.global_position.y)
	record("floor_change",campaign.floor_current=="2",campaign.floor_current)
	player.global_position=Vector3(-53.5,12.1,-125)
	player.velocity=Vector3.ZERO
	player.cam_yaw=0
	campaign.manager.cam_yaw=0
	await get_tree().create_timer(0.4).timeout
	Input.action_press("move_back")
	await get_tree().create_timer(4.0).timeout
	Input.action_release("move_back")
	record("actual_library_door_walk",player.global_position.z>-121.0,str(player.global_position))
	for sample in [["corridor3",Vector3(0,24.1,-138)],["library_door",Vector3(-58.7,12.1,-119.7)],["upper_hall",Vector3(19,84.1,-134.8)]]:
		var safe = player.get_node("SeatController").safe_position(sample[1])
		record("capsule_clearance_"+sample[0],safe!=null,str(safe))
	var original_profile: Dictionary = player.body.get_meta("appearance_profile").duplicate(true)
	var variant = original_profile.duplicate(true)
	variant["top"] = 4
	player.body.apply_appearance(variant)
	record("procedural_fallback",not player.body.human62.active and player.body.global_basis.get_scale().is_equal_approx(Vector3.ONE*1.5))
	player.body.apply_appearance(original_profile)
	record("imported_profile_restored",player.body.human62.active)
	var source_scale = player.scale
	player.scale=Vector3.ONE*1.1
	player.body.normalize_visual_height()
	record("inherited_scale_compensated",player.body.global_basis.get_scale().is_equal_approx(Vector3.ONE*player.body.normalized_human_scale))
	player.scale=source_scale
	player.body.normalize_visual_height()
	record("persist_disabled",not campaign.persist and not player.inventory.persist)
	for row in rows:
		if row.get("imported",false):
			record("human_height_"+row.id,absf(row.height-2.7)<0.04,row.height)
			record("finite_sockets_"+row.id,row.sockets_finite)
	finish_ground_checks()
	write("checks",checks)
	write("summary",{"checks":checks.size(),"failures":checks.filter(func(row):return not row.passed),"isolated":true,"remote_writes":false})
	print("HEIGHT_CHECKS_DONE ",checks.size())

func finish_ground_checks() -> void:
	for row in rows:
		if row.get("imported",false):
			record("ground_clearance_"+row.id,row.has("render_clearance") and absf(float(row.get("render_clearance",1.0)))<0.02,row.get("render_clearance"))
	write("checks",checks)
	write("summary",{"checks":checks.size(),"failures":checks.filter(func(row):return not row.passed),"isolated":true,"remote_writes":false})
func lineup() -> void:
	var hidden_ui: Array = []
	for control in campus.find_children("*","CanvasLayer",true,false)+campus.find_children("*","Label3D",true,false):
		if control.visible:
			hidden_ui.append(control)
			control.hide()
	var ids = ["Player","Estudiante","Profesor","profesor_algoritmos","director","Auxiliar"]
	var saved: Dictionary = {}
	var labels: Array = []
	var selected: Array = []
	for v in get_tree().get_nodes_in_group("campus_character_visual"):
		var preset = v.get_meta("visual_preset",{})
		var id = str(preset.get("visual_id",str(v.get_parent().name)))
		if id not in ids or not v.is_visible_in_tree(): continue
		var actor = v.get_parent()
		saved[actor]=actor.global_transform
		actor.global_position=Vector3(ids.find(id)*2.2,0.14,-48)
		actor.rotation.y=0
		v.lod_tick=0
		v.activity_level=0
		if v.get("human_visual63")!=null: v.human_visual63.tick=1
		v.update_visual_lod(1)
		for i in 12: v.animate(0.1,Vector3.ZERO,true,false)
		var label=Label3D.new()
		label.text={"Player":"Jugador","Estudiante":"Estudiante","Profesor":"Profesor","profesor_algoritmos":"Boss acad?mico","director":"Director","Auxiliar":"Auxiliar"}[id]
		label.position=Vector3(ids.find(id)*2.2,3.1,-48)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size=25
		add_child(label)
		labels.append(label)
		selected.append(v)
	camera.global_position=Vector3(5.5,3.2,-60)
	camera.look_at(Vector3(5.5,1.5,-48))
	camera.make_current()
	await get_tree().create_timer(0.4).timeout
	await shot("six_humans_after")
	for actor in saved: actor.global_transform=saved[actor]
	for label in labels: label.queue_free()
	for control in hidden_ui: control.show()
