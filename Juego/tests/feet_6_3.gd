extends Node3D
const OUT="res://reports/characters_6_3/"
var phase="before"
var player: Node3D
var camera: Camera3D
var campus: Node
func _ready() -> void:
	seed(630)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if FileAccess.file_exists(OUT+"phase.txt"): phase=FileAccess.get_file_as_string(OUT+"phase.txt").strip_edges()
	run.call_deferred()
func run() -> void:
	campus=load("res://Main.tscn").instantiate()
	var campaign=campus.get_node("CampusCampaign")
	campaign.persist=false;campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	campaign.ui.close_modal();campaign.set_process(false);campaign.manager.set_process(false)
	player=campaign.player
	if phase=="before":
		var old=player.body
		var baseline=load("res://tests/baseline_6_3/visual_6_2.gd").new()
		baseline.scale=old.scale;baseline.punch_time=old.punch_time
		player.add_child(baseline);player.body=baseline
		old.get_parent().remove_child(old);old.free()
	for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()
	for actor in campus.find_children("*","CharacterBody3D",true,false):
		actor.set_process(false);actor.set_physics_process(false)
	player.body.apply_appearance(preload("res://scripts/juego/character_appearance.gd").normalize({"top":1,"bottom_style":1,"pants":0,"shoes":6,"hair_color":1,"backpack":1,"backpack_color":5}))
	player.global_position=Vector3(4,0.14,-48)
	player.busy=false
	player.set_physics_process(true)
	await get_tree().create_timer(0.4).timeout
	player.set_physics_process(false)
	camera=Camera3D.new();camera.near=0.02;camera.fov=42;add_child(camera);camera.make_current()
	var methods=[]
	for method in ClassDB.class_get_method_list("MeshInstance3D"):
		if "bake" in method.name: methods.append(method)
	write("mesh_api",methods)
	var nearby=[]
	for node in campus.find_children("*","GeometryInstance3D",true,false):
		var bounds: AABB
		if node is MeshInstance3D and node.mesh: bounds=node.global_transform*node.get_aabb()
		elif node is CSGBox3D: bounds=node.global_transform*AABB(-node.size*0.5,node.size)
		else: continue
		if bounds.grow(0.15).has_point(Vector3(8,0.2,-45)):
			nearby.append({"path":str(node.get_path()),"class":node.get_class(),"bounds":str(bounds),"material":str(node.get("material_override")),"collision":node.get("use_collision")})
	write("overlap_surface",nearby)
	var rows=[]
	for state in ["idle","walk","run","jump","land","crouch","attack"]:
		var motion=Vector3(0,0,-2.5 if state=="walk" else -5.5 if state=="run" else 0)
		if state=="jump": motion.y=3
		if state=="land":
			player.body.animate(0.1,Vector3(0,-4,0),false,false)
		if state=="attack": player.body.start_punch()
		for i in (8 if state=="attack" else 40): player.body.animate(0.016,motion,state!="jump",state=="crouch")
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		rows.append(measure(state))
		for angle in ["front","back","left","right"] if state=="idle" else ["right"]:
			var offsets={"front":Vector3(0,0.30,-1.35),"back":Vector3(0,0.30,1.35),"left":Vector3(-1.35,0.30,0),"right":Vector3(1.35,0.30,0)}
			await shot(state+"_"+angle,offsets[angle])
	write("feet",rows)
	if phase=="after": await live_validation()
	print("FEET63_DONE ",phase)

func live_validation() -> void:
	var rows=[]
	player.body.punch_p[0]=-1;player.body.punch_p[1]=-1
	for test in ["walk","run","jump","land","crouch","attack"]:
		player.global_position=Vector3(4,0.15,-48);player.velocity=Vector3.ZERO
		player.set_physics_process(true);player.set_process(true)
		await get_tree().create_timer(0.3).timeout
		if test in ["walk","run"]: Input.action_press("move_forward")
		if test=="run": Input.action_press("run")
		if test in ["jump","land"]: Input.action_press("jump")
		if test=="crouch": Input.action_press("crouch")
		if test=="attack": Input.action_press("punch")
		await get_tree().create_timer(1.1 if test=="land" else 0.22).timeout
		player.set_physics_process(false);player.set_process(false)
		for action in ["move_forward","run","jump","crouch","punch"]: Input.action_release(action)
		await get_tree().process_frame
		rows.append(measure("live_"+test))
		await shot("live_"+test,Vector3(1.35,0.30,0))
	for zone in [["raised_marking",Vector3(8,0.15,-45)],["interior",Vector3(-20,0.05,-100)],["library",Vector3(-58.7,12.1,-119.7)],["stairs_landing",Vector3(-20.7,0.15,-149.8)]]:
		var safe=player.get_node("SeatController").safe_position(zone[1])
		if safe==null: rows.append({"state":zone[0],"skipped":"No safe position"});continue
		player.global_position=safe;player.velocity=Vector3.ZERO
		player.set_physics_process(true);player.set_process(true)
		await get_tree().create_timer(0.5).timeout
		player.set_physics_process(false);player.set_process(false)
		rows.append(measure(zone[0]));await shot(zone[0],Vector3(1.35,0.30,0))
	var lift=campus.get_node("SistemasCompartidos/AscensoresEstudiantiles").get_child(0)
	var stair_start=player.get_node("SeatController").safe_position(Vector3(-22.65,0.15,-150))
	if stair_start!=null:
		player.global_position=stair_start;player.velocity=Vector3.ZERO;player.cam_yaw=0
		player.set_physics_process(true);player.set_process(true)
		Input.action_press("move_forward")
		await get_tree().create_timer(1.8).timeout
		Input.action_release("move_forward")
		player.set_physics_process(false);player.set_process(false)
		var stair_row=measure("stairs_ascending")
		stair_row["rise"]=player.global_position.y-stair_start.y
		rows.append(stair_row);await shot("stairs_ascending",Vector3(1.35,0.30,0))
	var target=lift.cabin.global_position+Vector3(0,0.15,0)
	player.global_position=target;player.velocity=Vector3.ZERO
	player.set_physics_process(true);player.set_process(true)
	await get_tree().create_timer(0.6).timeout
	player.set_physics_process(false);player.set_process(false)
	rows.append(measure("inside_elevator"));await shot("inside_elevator",Vector3(1.35,0.30,0))
	player.set_physics_process(true);player.set_process(true)
	lift.request_floor(1)
	if not lift.moving:
		rows.append({"state":"elevator_request","blocked_by_campaign":true,"note":"Expected with fresh campaign. Motion below is a visual test fixture; unlock data unchanged."})
		lift.destination=1;lift.close_timer=1.0;lift.moving=true
	await get_tree().create_timer(1.5).timeout
	player.set_physics_process(false);player.set_process(false)
	rows.append(measure("elevator_moving"));await shot("elevator_moving",Vector3(1.35,0.30,0))
	write("live_feet",rows)
func measure(state: String) -> Dictionary:
	var model=player.body.human62
	var rig: Skeleton3D=model.rig
	var row={"state":state,"origin":str(player.global_position),"bones":[],"shoes":[]}
	for name in ["calf_l","foot_l","ball_l","calf_r","foot_r","ball_r"]:
		var index=rig.find_bone(name)
		row.bones.append({"name":name,"rest":str(rig.get_bone_global_rest(index)),"pose":str(rig.get_bone_global_pose(index))})
	for mesh in model.human.find_children("*","MeshInstance3D",true,false):
		if not mesh.visible or (not "shoe" in str(mesh.name).to_lower() and not "sneaker" in str(mesh.name).to_lower()): continue
		var baked: ArrayMesh=mesh.bake_mesh_from_current_skeleton_pose()
		var bounds=AABB()
		var first=true
		for surface in baked.get_surface_count():
			for vertex in baked.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var world: Vector3=mesh.global_transform*vertex
				if first: bounds=AABB(world,Vector3.ZERO);first=false
				else: bounds=bounds.expand(world)
		var ray=PhysicsRayQueryParameters3D.create(Vector3(bounds.get_center().x,player.global_position.y+0.5,bounds.get_center().z),Vector3(bounds.get_center().x,player.global_position.y-0.8,bounds.get_center().z))
		ray.exclude=[player.get_rid()]
		var hit=player.get_world_3d().direct_space_state.intersect_ray(ray)
		var visible_y=preload("res://scripts/juego/character_ground_6_3.gd").height_at(model,bounds.get_center(),hit.position.y) if not hit.is_empty() else 0.0
		row.shoes.append({"name":str(mesh.name),"bounds":str(bounds),"minimum_y":bounds.position.y,"maximum_y":bounds.end.y,"floor_y":hit.position.y if not hit.is_empty() else null,"clearance":bounds.position.y-hit.position.y if not hit.is_empty() else null,"visible_floor_y":visible_y,"render_clearance":bounds.position.y-visible_y,"skin_binds":mesh.skin.get_bind_count() if mesh.skin else 0})
	return row
func shot(label: String, offset: Vector3) -> void:
	camera.global_position=player.global_position+offset
	camera.look_at(player.global_position+Vector3(0,0.15,0))
	await get_tree().create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+phase+"_feet_"+label+".png")
func write(label: String, value: Variant) -> void:
	var f=FileAccess.open(OUT+phase+"_"+label+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(value,"\t"));f.close()
