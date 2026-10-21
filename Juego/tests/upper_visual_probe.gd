extends Node3D
var result := {}
func _ready() -> void:
	var failures: Array[String] = []
	var presets = preload("res://scripts/juego/character_visual_presets.gd")
	var roles := ["ESTUDIANTE","PROFESOR","FUNCIONARIO","INGLES","LENGUAJE","ETICA","DIRECTOR","TALLER","ENFERMERIA"]
	for index in roles.size():
		var visual = preload("res://scripts/juego/student_visual.gd").new()
		visual.skin_color = Color("c48a68") # También probar el color base heredado por bosses.
		visual.position = Vector3((index%5)*1.8,0,-floori(index/5.0)*2)
		add_child(visual)
		var preset: Dictionary = presets.create("preview:"+roles[index],roles[index])
		presets.apply(visual,preset)
		var expected_skin := Color(preload("res://scripts/juego/character_appearance.gd").SKIN[preset.skin])
		var has_skin := false
		for part in visual.head_pivot.get_children():
			if part is MeshInstance3D and part.material_override is StandardMaterial3D and part.material_override.albedo_color.is_equal_approx(expected_skin): has_skin = true
		if not has_skin: failures.append(roles[index]+": stored skin not applied")
		visual.rotation.y = PI
		if visual.module_parts.TOP.is_empty(): failures.append(roles[index]+": top missing")
		if visual.animation_tree == null: failures.append("animation contract")
		visual.animate(0.016,Vector3.ZERO,true,false)
		var label := Label3D.new()
		label.text = roles[index]; label.font_size = 24; label.pixel_size = 0.003; label.position.y = 2
		visual.add_child(label)
	var camera := Camera3D.new(); add_child(camera)
	camera.position = Vector3(4,3.2,8); camera.look_at(Vector3(3.5,1,-1)); camera.current = true
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35,-30,0); add_child(sun)
	result = {"roles":roles.size(),"failures":failures}
	print("UPPER_VISUAL_RESULT "+JSON.stringify(result))
