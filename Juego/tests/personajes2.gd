extends SceneTree
## Integration checks: visual replacement, sockets, dialogue and save-compatible data.
const Profile = preload("res://scripts/juego/character_appearance.gd")
const Presets = preload("res://scripts/juego/character_visual_presets.gd")
var failures: Array[String] = []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("run")

func fixture() -> PackedScene:
	# Synthetic rig for adapter validation only; never added to game assets.
	var root_node := Node3D.new()
	root_node.name = "Fixture"
	var test_mesh := MeshInstance3D.new()
	test_mesh.mesh = SphereMesh.new()
	root_node.add_child(test_mesh)
	test_mesh.owner = root_node
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	skeleton.add_bone("root")
	root_node.add_child(skeleton)
	skeleton.owner = root_node
	for key in ["RightHand","LeftHand","Back"]:
		var marker := Marker3D.new()
		marker.name = key
		root_node.add_child(marker)
		marker.owner = root_node
	var animator := AnimationPlayer.new()
	animator.name = "AnimationPlayer"
	root_node.add_child(animator)
	animator.owner = root_node
	var library := AnimationLibrary.new()
	for key in ["idle","walk","run"]:
		var clip := Animation.new()
		clip.length = 1
		clip.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(key,clip)
	animator.add_animation_library("",library)
	var packed := PackedScene.new()
	packed.pack(root_node)
	root_node.free()
	return packed

func run() -> void:
	var world: Node = load("res://Main.tscn").instantiate()
	var campaign = world.get_node("CampusCampaign")
	campaign.persist = false
	world.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(world)
	current_scene = world
	while not campaign.ready_for_play:
		await process_frame
	while get_nodes_in_group("boss_duel").any(func(d): return not d.initialized):
		await process_frame
	campaign.ui.close_modal()
	var player = campaign.player
	player.set_physics_process(false)
	var visual = player.body
	var capsule = player.capsule
	var health: float = player.health
	var snapshot: Dictionary = player.inventory.snapshot_data()
	check(visual.name == "CharacterVisual","Single modular CharacterVisual")
	check(visual.module_parts.TOP.size() > 0 and visual.module_parts.SHOES.size() > 0,"Articulated clothing modules")
	for state in visual.STATES:
		check(visual.animation_tree.tree_root.has_node(state),"Prepared state "+state)
	var preset: Dictionary = Presets.create("npc_rival")
	check(preset == Presets.create("npc_rival"),"Stable ID generation")
	check(campaign.data.npc_visuals.size() >= 8,"Existing NPC presets persisted")
	check(JSON.parse_string(JSON.stringify(campaign.data.npc_visuals)) is Dictionary,"Preset data JSON round trip")
	var stored: Dictionary = campaign.data.npc_visuals.duplicate(true)
	var npc = campaign.get_node("Profesor")
	check(npc.model.get_meta("visual_preset") == stored.Profesor,"Important NPC keeps stored identity")
	var socket = visual.weapon_socket
	var socket_parent = socket.get_parent()
	var clips := {"IDLE":"idle","WALK":"walk","RUN":"run"}
	check(not visual.install_imported_visual(fixture(),clips),"Reject missing attachment bindings safely")
	check(visual.fall_pivot.visible,"Rejected asset keeps fallback")
	check(visual.install_imported_visual(fixture(),clips,{"weapon_socket":"RightHand","item_socket":"LeftHand","backpack_socket":"Back"}),"Accept valid skeleton and bindings")
	visual.animate(0.016,Vector3.ZERO,true,false)
	check(not visual.fall_pivot.visible and visual.imported_visual.model.visible,"Imported model active")
	check(socket == visual.weapon_socket and socket.get_parent() == visual,"Equipped socket retains identity and visibility")
	visual.animate(0.016,Vector3(0,0,5.5),true,false)
	check(visual.imported_visual.locomotion_speed > 0 and visual.imported_visual.locomotion_speed < 5.5,"AnimationTree smooths run blend without slowing gameplay")
	visual.animate(0.016,Vector3(0,4,0),false,false)
	check(visual.fall_pivot.visible and not visual.imported_visual.model.visible,"Missing jump clip uses real procedural fallback")
	check(socket.get_parent() == socket_parent,"Fallback restores original socket")
	visual.imported_visual.clear()
	check(socket.get_parent() == socket_parent and socket.is_inside_tree(),"Clear imported model preserves equipment")
	var look = visual.look_controller
	look.target = npc
	npc.position = player.position+Vector3(10,0,-10)
	look.apply(visual.head_pivot,0.5)
	check(absf(look.yaw) <= look.max_yaw and absf(look.pitch) <= look.max_pitch,"Natural gaze limits")
	look.target = null
	visual.set_expression("WORRIED")
	check(visual.expression == "WORRIED","Expression state available without blend shapes")
	visual.set_expression("UNKNOWN")
	check(visual.expression == "WORRIED","Unknown expression ignored")
	visual.set_expression("NEUTRAL")
	visual.show_phone(true)
	check(visual.activity_visual.prop_kind == "PHONE" and visual.phone_visible,"Phone visual uses existing phone lifecycle")
	visual.show_phone(false)
	check(not visual.phone_visible and visual.activity_visual.prop_kind == "NONE","Phone prop removed on close")
	for action in ["TYPE","WRITE","READ","PHONE","EAT","REPAIR","INSPECT"]:
		visual.set_visual_activity(action,"TABLET")
		visual.animate(0.1,Vector3.ZERO,true,false)
	check(visual.activity_visual.action == "INSPECT","All procedural work actions supported")
	visual.set_visual_activity("","NONE")
	visual.hurt_t = 0
	visual.react_to_hit(Vector3.RIGHT,30)
	check(visual.hit_variant == "HIT_HEAVY","Directional heavy impact")
	visual.hurt()
	visual.animate(0.05,Vector3.ZERO,true,false)
	check(visual.visual_state == "HIT","Damage fallback preserves HIT state")
	visual.hurt_t = 0
	# Current player can have equipment from the fixture's campaign state.
	var landed := [0]
	visual.punch_landed.connect(func(_side): landed[0] += 1)
	visual.start_punch()
	for index in 60:
		visual.animate(0.016,Vector3.ZERO,true,false)
	check(landed[0] == 1,"Visual adapter does not duplicate attack timing")
	var unlocked := {}
	Profile.unlock_from_progress({"nexo":true},unlocked)
	check(unlocked.get("nexo_jacket",false),"NEXO cosmetic reward")
	check(Profile.normalize({"outfit":5}).outfit == 0,"NEXO locked before progress")
	check(Profile.normalize({"outfit":5},unlocked).outfit == 5,"NEXO equip after unlock")
	campaign.data["campaign_completed"] = true
	var chosen: Dictionary = campaign.data.appearance.duplicate()
	campaign.refresh_visual_rewards()
	check(campaign.data.cosmetics.get("nexo_jacket",false) and campaign.data.appearance == chosen,"Campaign endpoint unlock never auto-equips")
	var station = campaign.get_node("ArmarioPersonal")
	check(station.has_method("interact") and campaign.has_node("EspejoPersonal"),"Safe existing-menu access points")
	campaign.show_personalization()
	campaign.appearance_menu._cancel()
	campaign.ui.close_modal()
	var camera_before := get_viewport_camera()
	# Isolated open air above the fixture campus: test a real cinematic shot.
	player.global_position = Vector3(0,300,0)
	npc.global_position = player.global_position+Vector3(2,0,0)
	camera_before.global_position = player.global_position+Vector3(0,2,5)
	camera_before.look_at(player.global_position+Vector3.UP*1.7)
	var position_before: Vector3 = player.global_position
	campaign.ui.begin_character_dialogue(npc)
	check(campaign.ui.dialogue_camera.mode == 2,"Clear space enables TWO_SHOT")
	check(visual.look_controller.target == npc,"Dialogue gaze target")
	campaign.ui.close_modal()
	check(get_viewport_camera() == camera_before and visual.look_controller.target == null,"Dialogue restores camera and gaze")
	check(player.global_position == position_before,"Dialogue never relocates player")
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(20,20,20)
	collision.shape = shape
	blocker.add_child(collision)
	world.add_child(blocker)
	blocker.global_position = player.global_position
	await physics_frame
	camera_before.global_position = player.global_position+Vector3(0,2,5)
	campaign.ui.begin_character_dialogue(npc)
	check(campaign.ui.dialogue_camera.mode == 0 and get_viewport_camera() == camera_before,"Blocked shot keeps normal camera")
	campaign.ui.close_modal()
	blocker.queue_free()
	check(player.capsule == capsule and player.health == health,"Visual changes preserve collision and health")
	check(player.inventory.snapshot_data() == snapshot,"Visual changes preserve inventory")
	print("PERSONAJES2_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func get_viewport_camera() -> Camera3D:
	return root.get_camera_3d()
