extends SceneTree
const Profile = preload("res://scripts/juego/character_appearance.gd")
const Presets = preload("res://scripts/juego/character_visual_presets.gd")
var failures: Array = []
func check(ok: bool, detail: String) -> void:
	if not ok: failures.append(detail)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var owner_actor := Node3D.new()
	owner_actor.add_to_group("player")
	root.add_child(owner_actor)
	var model = preload("res://scripts/juego/main_character_visual_6.gd").new()
	owner_actor.add_child(model)
	var socket = model.weapon_socket
	var hand = model.hand_r
	var unlocks := {}
	for key in Profile.LOCKS.values(): unlocks[key]=true
	for face in 4:
		var p: Dictionary = Profile.normalize({"face":face,"hair":face,"top":face,"backpack":face%2},unlocks)
		model.apply_appearance(p)
		var encoded := JSON.stringify(p)
		var decoded: Dictionary = Profile.normalize(JSON.parse_string(encoded),unlocks)
		check(decoded==p,"Round trip appearance "+str(face))
		check(model.weapon_socket==socket and socket.get_parent()==hand,"Socket identity preserved")
		check(model.find_children("*","CollisionShape3D",true,false).is_empty(),"No cosmetic collisions")
	var p: Dictionary = Profile.normalize({"hair":5,"top":4,"accessory":1,"backpack":1},unlocks)
	model.apply_appearance(p)
	var count: int = model.find_children("*","MeshInstance3D",true,false).size()
	for i in 8: model.apply_appearance(p)
	await process_frame
	check(count==model.find_children("*","MeshInstance3D",true,false).size(),"Repeated changes do not accumulate meshes")
	var hits := [0]
	model.punch_landed.connect(func(_side): hits[0]+=1)
	model.start_punch()
	for i in 60: model.animate(0.016,Vector3.ZERO,true,false)
	check(hits[0]==1,"Single functional hit event")
	for expression in ["NEUTRAL","HAPPY","SURPRISED","FOCUSED","WORRIED","PAIN","VICTORY"]:
		model.set_expression(expression)
		model.animate(0.016,Vector3.ZERO,true,false)
		check(model.expression==expression,"Expression "+expression)
	for role in Presets.ROLES:
		check(Presets.create("stable_"+role,role)==Presets.create("stable_"+role,role),"Stable profile "+role)
	model.set_activity_level(3)
	check(not model.secondary_animation_enabled,"SLEEP disables secondary animation")
	model.set_activity_level(0)
	check(model.secondary_animation_enabled,"Wake restores secondary animation")
	var path := "user://main_character60_regression_isolated.json"
	var stream := FileAccess.open(path,FileAccess.WRITE)
	stream.store_string(JSON.stringify(p)); stream.close()
	check(Profile.normalize(JSON.parse_string(FileAccess.get_file_as_string(path)),unlocks)==p,"Isolated disk round trip")
	DirAccess.remove_absolute(path)
	check_imported_student(unlocks)
	print("MAIN_CHARACTER60_RESULT ",JSON.stringify({"failures":failures,"personal_saves_used":false}))
	owner_actor.free()
	quit(0 if failures.is_empty() else 1)

func check_imported_student(unlocks: Dictionary) -> void:
	var stage := preload("res://scripts/campaign/campus_avatar_stage.gd").new()
	stage.size = Vector2(427,494)
	stage.can_rotate = true
	root.add_child(stage)
	var profile := Profile.normalize({"body_type":1,"hair":7,"top":1,"skin":3,"accessory":9},unlocks)
	stage.set_profile(profile)
	var human = stage.model.human62
	if human == null:
		check(false,"Imported student initialized")
		stage.queue_free()
		return
	var rig: Skeleton3D = human.rig
	check_knees(human)
	for mesh_name in ["Body","Cloth_hoodie","Cloth_jeans"]:
		var mesh := human.human.find_child(mesh_name,true,false) as MeshInstance3D
		var morph := mesh.find_blend_shape_by_name("gender_female") if mesh else -1
		check(morph >= 0 and is_equal_approx(mesh.get_blend_shape_value(morph),0.65),"Female morph on "+mesh_name)
	check(human.pieces["hair_braid01"][0].is_visible_in_tree(),"Braided hair rendered by preview")
	check(Profile.normalize(JSON.parse_string(JSON.stringify(profile)),unlocks)==profile,"Student body and accessories persist")
	check(Profile.normalize({},unlocks).body_type==0,"Legacy appearance defaults")
	stage.zoom_by(0.3)
	stage.rotate_by(TAU+0.5)
	check(stage.camera.size < stage.fitting_size and is_equal_approx(stage.yaw,wrapf(PI+0.5,-PI,PI)),"Preview zoom and full rotation")
	var head := rig.find_bone("head")
	var initial_rotation := rig.get_bone_pose_rotation(head)
	for frame in 24:
		stage.model.animate(0.016,Vector3.ZERO,true,false)
	check(not rig.get_bone_pose_rotation(head).is_equal_approx(initial_rotation),"Imported idle clip writes animated bone tracks")
	for sample in [[Vector3(2.5,0,0),true,"Locomotion"],[Vector3(6.6,0,0),true,"Locomotion"],[Vector3(0,5,0),false,"Jump"],[Vector3(0,-6,0),false,"Fall"],[Vector3.ZERO,true,"Land"]]:
		stage.model.animate(0.016,sample[0],sample[1],false)
		check(human.motion_state==sample[2] and human.motion_tree.active,"Imported motion "+sample[2])
	check(stage.model.human62.rig==rig,"Appearance and animation reuse the skeleton")
	var hits := [0]
	stage.model.punch_landed.connect(func(_side): hits[0] += 1)
	stage.model.start_punch()
	for frame in 45:
		stage.model.animate(0.016,Vector3.ZERO,true,false)
	check(hits[0]==1,"Imported female character preserves impact timing")
	var reference := Profile.normalize(Profile.CAMPUS_REFERENCE,unlocks)
	stage.set_profile(reference)
	var face_mesh := human.human.find_child("Body",true,false) as MeshInstance3D
	var nose := face_mesh.find_blend_shape_by_name("face_nose_width_decr")
	var eyes := face_mesh.find_blend_shape_by_name("face_eye_tilt_incr")
	check(nose >= 0 and eyes >= 0 and face_mesh.get_blend_shape_value(nose) > 0.0 and face_mesh.get_blend_shape_value(eyes) > 0.0,"Reference changes facial geometry")
	var full_size: float = stage.camera.size
	stage.toggle_face_focus()
	check(stage.camera.size < full_size * 0.5,"Preview frames face details")
	stage.toggle_face_focus()
	check(stage.model.campus_wordmark.is_visible_in_tree(),"DuocUC wordmark displayed on reference hoodie")
	check(human.pieces["clothing_hoodie"][0].is_visible_in_tree() and human.pieces["hair_short04"][0].is_visible_in_tree(),"Reference outfit uses the rigged clothing and hair")
	reference.top = 0
	reference.face = 0
	stage.set_profile(reference)
	check(nose >= 0 and is_zero_approx(face_mesh.get_blend_shape_value(nose)),"Switching face resets reference morphs")
	check(not stage.model.campus_wordmark.visible,"DuocUC wordmark stays with the hoodie")
	stage.queue_free()

func check_knees(human: Node3D) -> void:
	for side in ["l","r"]:
		var thigh: int = human.rig.find_bone("thigh_"+side)
		var calf: int = human.rig.find_bone("calf_"+side)
		var foot: int = human.rig.find_bone("foot_"+side)
		var ball: int = human.rig.find_bone("ball_"+side)
		var upper: float = human.rests[thigh].origin.distance_to(human.rests[calf].origin)
		var lower: float = human.rests[calf].origin.distance_to(human.rests[foot].origin)
		for offset in [Vector3(0.18,0.12,0.12),Vector3(-0.18,0.12,-0.12),Vector3(0,0.02,0)]:
			var poses: Array[Transform3D] = human.rests.duplicate()
			var hip := poses[thigh].origin
			poses[calf].origin += Vector3(0.12 if side == "l" else -0.12,0,-0.035)
			var target: Vector3 = poses[foot].origin + offset
			human.footwear63._solve_leg(poses,thigh,calf,foot,ball,target,upper,lower)
			var leg := (poses[foot].origin-hip).normalized()
			var pole := poses[calf].origin-hip-leg*(poses[calf].origin-hip).dot(leg)
			var forward := (Vector3.BACK-leg*Vector3.BACK.dot(leg)).normalized()
			check(pole.normalized().dot(forward) >= 0.97,"Knee bends forward "+side)
			check(is_equal_approx(hip.distance_to(poses[calf].origin),upper) and is_equal_approx(poses[calf].origin.distance_to(poses[foot].origin),lower),"Leg lengths preserved "+side)

