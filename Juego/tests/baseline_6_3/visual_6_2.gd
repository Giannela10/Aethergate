extends "res://scripts/juego/main_character_visual_6.gd"
var human62: Node3D
func _ready() -> void:
	super._ready()
	human62=preload("res://tests/baseline_6_3/human_6_2.gd").new()
	add_child(human62)
	if not human62.initialize(self):
		human62.queue_free()
		human62=null
		set_meta("human62_active",false)
		return
	set_meta("main_character_remodel","6.2 skinned CC0")
func apply_appearance(profile: Dictionary) -> void:
	super.apply_appearance(profile)
	if human62==null: return
	var supported=int(profile.top) in [0,1] and int(profile.outfit)==0 and int(profile.accessory)==0 and int(profile.get("head_accessory",0))==0 and int(profile.get("shoe_style",0))==0 and int(profile.get("bottom_style",0)) in [0,1,4]
	human62.set_active(supported)
	set_meta("human62_active",supported)
	if not supported: return
	human62.apply_profile(profile)
	for mesh in fall_pivot.find_children("*","MeshInstance3D",true,false):
		mesh.visible=mesh.get_meta("visual_module","")=="BACKPACK" and int(profile.backpack)>0
		if mesh.visible and mesh.get_parent()==chest: mesh.position.y+=0.06
		if mesh.visible and int(profile.get("backpack_color",0))==5 and mesh.material_override is StandardMaterial3D and mesh.material_override.albedo_color.r<0.4:
			mesh.material_override=mesh.material_override.duplicate()
			mesh.material_override.albedo_color=Color("14191f")
			mesh.material_override.roughness=0.95
	for part in hair6: part.hide()
func animate(delta: float, velocity: Vector3, on_floor: bool, crouching: bool) -> void:
	super.animate(delta,velocity,on_floor,crouching)
	if human62!=null: human62.update_pose(delta)

