extends Node3D
## The interaction marker and the combat actor share a single visible model.
var duel: Node
var original_visual: Node3D
var mentor: Node3D
var caption: Label3D
var active := false
var mentor_visual: Node3D

static func digital_model() -> Node3D:
	var model := Node3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("164d68")
	material.emission_enabled = true
	material.emission = Color("16bddc")
	material.emission_energy_multiplier = 0.5
	for row in [[Vector3(0,1.1,0),Vector3(0.65,0.75,0.45)],[Vector3(0,1.8,0),Vector3(0.45,0.35,0.4)],[Vector3(-0.46,1.1,0),Vector3(0.18,0.65,0.22)],[Vector3(0.46,1.1,0),Vector3(0.18,0.65,0.22)],[Vector3(-0.2,0.4,0),Vector3(0.2,0.65,0.25)],[Vector3(0.2,0.4,0),Vector3(0.2,0.65,0.25)]]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new(); box.size = row[1]
		mesh.mesh = box; mesh.material_override = material; mesh.position = row[0]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		model.add_child(mesh)
	var visor := Label3D.new()
	visor.text = "[ SIM ]"
	visor.position = Vector3(0,2.2,0)
	visor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visor.font_size = 35
	model.add_child(visor)
	return model

func setup(controller: Node) -> void:
	duel = controller
	for key in ["body","_visual","visual"]:
		var candidate = duel.actor.get(key)
		if candidate is Node3D: original_visual = candidate; break
	mentor = Node3D.new()
	mentor.name = "Mentor_"+duel.boss_id
	mentor.add_to_group("educational_mentor")
	var anchor: Node3D = original_visual.get_parent() if original_visual else duel.actor
	anchor.add_child(mentor)
	mentor_visual = original_visual
	if original_visual:
		mentor.set_meta("dialogue_visual",original_visual)
		original_visual.show()
		_configure_actor_appearance()
	caption = Label3D.new()
	caption.text = duel.boss_name+"\nMENTOR · SIMULACIÓN EDUCATIVA"
	caption.position.y = 2.8
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mentor.add_child(caption)

func _configure_actor_appearance() -> void:
	var presets = preload("res://scripts/juego/character_visual_presets.gd")
	if not original_visual.has_meta("visual_preset"):
		var role: String = {"punto":"FUNCIONARIO","chef":"VENDEDOR"}.get(duel.boss_id,presets.role_for(duel.boss_id))
		var preset: Dictionary = presets.create(duel.boss_id,role)
		if original_visual.has_method("apply_appearance"):
			presets.apply(original_visual,preset)
		else:
			original_visual.set_meta("visual_preset",preset)
	original_visual.set_meta("educational_duel_visual",true)
	if original_visual.has_method("_finish_human63"):
		original_visual._finish_human63()

func begin() -> void:
	active = true
	mentor.hide()

func finish() -> void:
	active = false
	mentor.show()
	caption.text = duel.boss_name+"\nSIMULACIÓN COMPLETADA"
	if is_instance_valid(original_visual) and original_visual.get("dead") == true:
		get_tree().create_timer(1.6,false).timeout.connect(_restore_mentor_pose)

func reset() -> void:
	active = false
	mentor.show()

func _restore_mentor_pose() -> void:
	if not is_instance_valid(original_visual): return
	original_visual.dead = false
	original_visual.death_t = 0.0
	original_visual.hurt_t = 0.0
	original_visual.fall_pivot.transform = Transform3D.IDENTITY
