class_name AcademicPhysicalObjective
extends CharacterBody3D
var boss: Node3D
var token := ""
var caption := ""
var mode := "walk"
var age := 0.0
var enabled := true
var label: Label3D
var interaction_range := 2.4
func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	add_to_group("campus_interactable")
	if mode == "destroy":
		collision_layer = 4
		add_to_group("enemy")
		var shape := CollisionShape3D.new()
		shape.shape = SphereShape3D.new()
		shape.shape.radius = 0.6
		shape.position.y = 0.6
		add_child(shape)
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.8
	cylinder.bottom_radius = 0.8
	cylinder.height = 0.08 if mode != "destroy" else 0.9
	mesh.mesh = cylinder
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("4eade6") if mode != "destroy" else Color("ecb94a")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = material
	mesh.position.y = 0.05 if mode != "destroy" else 0.45
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	label = Label3D.new()
	label.text = caption+(" · GOLPEA" if mode == "destroy" else (" · [E]" if mode == "use" else ""))
	label.position.y = 1.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 52
	label.pixel_size = 0.009
	add_child(label)
func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss) or not boss.combat_active():
		queue_free()
		return
	age += delta
	if mode == "walk" and age > 0.6 and enabled and boss.target != null:
		var p: Vector3 = boss.target.global_position
		if absf(p.y-global_position.y) < 1.8 and Vector2(p.x-global_position.x,p.z-global_position.z).length() < 1.05:
			activate()
func interaction_text(_player: Node) -> String:
	return "[E] "+caption if enabled and mode == "use" else ""
func interaction_priority() -> int: return 1
func interaction_target() -> Node3D: return self
func interact(player: CharacterBody3D) -> void:
	if mode == "use" and player == boss.target and global_position.distance_to(player.global_position) < interaction_range:
		activate()
func take_hit(_direction: Vector3, _damage: float) -> void:
	if mode == "destroy": activate()
func activate() -> void:
	if not enabled or not is_instance_valid(boss) or not boss.combat_active(): return
	if not boss.has_clear_line(global_position+Vector3.UP,boss.target.global_position+Vector3.UP): return
	boss.objective_selected(token,self)
func retire() -> void:
	enabled = false
	remove_from_group("campus_interactable")
	remove_from_group("enemy")
	hide()
	queue_free()
