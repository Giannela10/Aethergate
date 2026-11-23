extends "res://scripts/juego/main_character_visual_6.gd"
var human62: Node3D
var campus_wordmark: Node3D
func _ready() -> void:
	super._ready()
	human62=preload("res://scripts/juego/human_student_6_2.gd").new()
	add_child(human62)
	if not human62.initialize(self):
		human62.queue_free()
		human62=null
		set_meta("human62_active",false)
		return
	set_meta("main_character_remodel","6.2 skinned CC0")
	campus_wordmark = Node3D.new()
	campus_wordmark.name = "CampusWordmark"
	campus_wordmark.position = Vector3(-0.087,0.194,-0.154)
	campus_wordmark.basis = Basis(Vector3.LEFT,Vector3(0,0.89,0.46),Vector3(0,0.46,-0.89)).orthonormalized()
	campus_wordmark.hide()
	chest.add_child(campus_wordmark)
	for part in [["Duoc",Color("f4bd42"),-0.007],["UC",Color("f4f2ed"),-0.007]]:
		var label := Label3D.new()
		label.text = part[0]
		label.modulate = part[1]
		label.position.x = part[2]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if part[0] == "Duoc" else HORIZONTAL_ALIGNMENT_LEFT
		label.font_size = 32
		label.pixel_size = 0.00047
		label.outline_size = 0
		label.shaded = true
		campus_wordmark.add_child(label)
func apply_appearance(profile: Dictionary) -> void:
	super.apply_appearance(profile)
	if human62==null: return
	set_meta("human62_active",true)
	human62.apply_profile(profile)
	campus_wordmark.visible = int(profile.top) == 1 and int(profile.outfit) == 0 and int(profile.clothes) == 0 and int(profile.get("body_type",0)) == 0
	for mesh in fall_pivot.find_children("*","MeshInstance3D",true,false):
		mesh.visible=mesh.get_meta("visual_module","")=="BACKPACK" and int(profile.backpack)>0
		if mesh.visible and mesh.get_parent()==chest: mesh.position.y+=0.06
		if mesh.visible and int(profile.get("backpack_color",0))==5 and mesh.material_override is StandardMaterial3D and mesh.material_override.albedo_color.r<0.4:
			mesh.material_override=mesh.material_override.duplicate()
			mesh.material_override.albedo_color=Color("14191f")
			mesh.material_override.roughness=0.95
	for mesh in appearance_adapter.extras:
		match mesh.get_meta("visual_module","ACCESSORY"):
			"ACCESSORY", "HEAD_ACCESSORY", "OUTFIT":
				mesh.show()
			"BOTTOM":
				mesh.visible = int(profile.bottom_style) >= 2
			"SHOES":
				mesh.visible = int(profile.shoe_style) > 0
func animate(delta: float, velocity: Vector3, on_floor: bool, crouching: bool) -> void:
	super.animate(delta,velocity,on_floor,crouching)
	if human62!=null: human62.update_pose(delta)
