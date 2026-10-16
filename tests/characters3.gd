extends SceneTree
var failures: Array = []
var checks := 0
class Hub extends Node:
	var campaign: Node
	var player: Node3D
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); push_error(label)
func _initialize() -> void: run.call_deferred()
func rig(with_geometry: bool = true) -> PackedScene:
	var model := Node3D.new()
	if with_geometry:
		var mesh := MeshInstance3D.new(); mesh.mesh = SphereMesh.new()
		model.add_child(mesh); mesh.owner = model
	var skeleton := Skeleton3D.new(); skeleton.name = "Rig"
	model.add_child(skeleton); skeleton.owner = model
	for bone in ["Hips","Hand_R","Chest","Head"]: skeleton.add_bone(bone)
	var animator := AnimationPlayer.new(); animator.name = "AnimationPlayer"
	model.add_child(animator); animator.owner = model
	var library := AnimationLibrary.new()
	for clip in ["idle","walk","run"]:
		var animation := Animation.new(); animation.length = 1; animation.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(clip,animation)
	animator.add_animation_library("",library)
	var packed := PackedScene.new(); packed.pack(model); model.free(); return packed
func run() -> void:
	var world := Node3D.new(); root.add_child(world)
	var player := Node3D.new(); player.add_to_group("player"); world.add_child(player)
	var visual = preload("res://scripts/juego/student_visual.gd").new(); world.add_child(visual)
	var second = preload("res://scripts/juego/student_visual.gd").new(); world.add_child(second)
	await process_frame
	check(visual.head_pivot.name == "Head" and visual.fall_pivot.name == "Model","Visual hierarchy unchanged")
	check(visual._mats.values()[0] != second._mats.values()[0],"Damage materials remain actor-local")
	var first_mesh = visual.find_children("*","MeshInstance3D",true,false)[0]
	var second_mesh = second.find_children("*","MeshInstance3D",true,false)[0]
	check(first_mesh.mesh == second_mesh.mesh,"Identical primitive geometry shared")
	var hub := Hub.new(); hub.campaign = Hub.new(); hub.campaign.player = player
	world.add_child(hub); world.add_child(hub.campaign)
	var manager = preload("res://scripts/live/floor_activity_manager.gd").new(); manager.hub = hub; hub.add_child(manager)
	visual.position.y = 36; manager.refresh()
	check(visual.activity_level == 3,"Off-floor character sleeps")
	var clock: float = visual.time; var blink: float = visual.blink_wait
	for i in 120: visual.animate(0.016,Vector3.ZERO,true,false)
	check(visual.time == clock and visual.blink_wait == blink,"Sleep stops rig, gaze and blink work")
	check(manager.counts.SLEEP >= 1,"Manager reports sleeping characters")
	visual.position = Vector3.ZERO; manager.refresh(); visual.animate(0.016,Vector3.ZERO,true,false)
	check(visual.activity_level == 0 and visual.time > clock,"Floor return restores animation")
	visual.position.x = 22; manager.refresh()
	check(visual.activity_level == 1,"Mid-distance LOD1")
	visual.position.x = 40; manager.refresh()
	check(visual.activity_level == 2,"Far LOD2")
	visual.position = Vector3.ZERO; manager.refresh()
	check(not visual.install_imported_visual(null,{}),"Null asset preserves procedural fallback")
	var clips := {"idle":"idle","walk":"walk","run":"run"}
	var bindings := {"weapon_socket":{"bone":"Hand_R"},"item_socket":{"bone":"Hand_R"},"backpack_socket":{"bone":"Chest"},"hair_socket":{"bone":"Head"},"head_accessory_socket":{"bone":"Head"}}
	check(not visual.install_imported_visual(rig(false),clips,bindings),"Empty imported rig cannot hide visible fallback")
	check(visual.install_imported_visual(rig(),clips,bindings),"Bone binding and lowercase clip aliases accepted")
	visual.animate(0.016,Vector3.ZERO,true,false)
	check(visual.imported_visual.skeleton.find_children("*","BoneAttachment3D",true,false).size() == 5,"Sockets attached to rig bones")
	var installed = visual.imported_visual.model
	check(not visual.install_imported_visual(rig(),clips,{"weapon_socket":{"bone":"missing"}}),"Invalid binding rejected")
	check(visual.imported_visual.model == installed,"Failed replacement preserves installed model")
	visual.set_activity_level(2)
	visual.animate(0.6,Vector3.ZERO,true,false)
	check(not visual.imported_visual.tree.active,"LOD2 does not auto-process imported blends")
	visual.set_activity_level(3)
	check(not visual.imported_visual.tree.active,"Sleeping imported AnimationTree disabled")
	visual.set_activity_level(0); visual.animate(0.016,Vector3.ZERO,true,false)
	check(visual.imported_visual.tree.active,"AnimationTree restores on wake")
	visual.animate(0.016,Vector3(0,4,0),false,false)
	check(visual.fall_pivot.visible,"Missing human jump keeps visible fallback")
	visual.imported_visual.clear()
	check(visual.weapon_socket.is_inside_tree(),"Clear retains gameplay sockets")
	var zone = preload("res://scripts/campaign/academic_boss_zone.gd").new()
	# Real hazard lifecycle with a missing target: no immortal ticking ground zone.
	var boss := HazardBoss.new(); world.add_child(boss)
	zone.boss = boss; zone.warning = 0; zone.lifetime = 0.01; world.add_child(zone)
	zone._physics_process(0.02)
	check(zone.is_queued_for_deletion() and not zone.is_physics_processing(),"Expired targetless zone stops immediately")
	var aliases = preload("res://scripts/juego/character_visual_presets.gd")
	check(aliases.create("stable-student","student_female") == aliases.create("stable-student","student_male"),"Profile aliases do not impose gender restrictions")
	visual.die(); visual.animate(1.0,Vector3.ZERO,true,false)
	check(visual.death_t == 1.0,"Restored defeated pose completes in one explicit step")
	print("CHARACTERS3_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

class HazardBoss extends Node3D:
	var target: Node3D
	func combat_active() -> bool: return true
