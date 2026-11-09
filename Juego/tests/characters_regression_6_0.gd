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
	var model = preload("res://scripts/juego/student_visual.gd").new()
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
	var path := "user://characters60_isolated_appearance.json"
	var stream := FileAccess.open(path,FileAccess.WRITE)
	stream.store_string(JSON.stringify(p)); stream.close()
	check(Profile.normalize(JSON.parse_string(FileAccess.get_file_as_string(path)),unlocks)==p,"Isolated disk round trip")
	DirAccess.remove_absolute(path)
	print("CHARACTERS60_RESULT ",JSON.stringify({"failures":failures,"personal_saves_used":false}))
	owner_actor.free()
	quit(0 if failures.is_empty() else 1)
