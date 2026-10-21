extends Node3D
var boss: Node3D
var caption := "AVISO"
var radius := 2.0
var length := 0.0
var warning := 1.2
var lifetime := 1.5
var damage := 16.0
var kind := "damage"
var choice := ""
var direction := Vector3.FORWARD
var resolved := false
var color := Color(0.95,0.6,0.12,0.4)
var mesh: MeshInstance3D
var label: Label3D
func _ready() -> void:
	mesh = MeshInstance3D.new()
	if length > 0:
		var box := BoxMesh.new(); box.size = Vector3(radius*2,0.04,length); mesh.mesh = box
		mesh.position = direction*length*0.5
		mesh.rotation.y = atan2(-direction.x,-direction.z)
	else:
		var disc := CylinderMesh.new(); disc.top_radius = radius; disc.bottom_radius = radius; disc.height = 0.04; disc.radial_segments = 32; mesh.mesh = disc
	var material := StandardMaterial3D.new()
	material.albedo_color = color; material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = material; mesh.position.y = 0.05; add_child(mesh)
	label = Label3D.new(); label.text = caption; label.position = mesh.position+Vector3.UP*0.6; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.pixel_size = 0.004; label.font_size = 28; add_child(label)
func contains(point: Vector3) -> bool:
	if absf(point.y-global_position.y) > 2.5: return false
	var offset := point-global_position; offset.y = 0
	if length <= 0: return offset.length() <= radius
	var forward := offset.dot(direction)
	return forward >= 0 and forward <= length and absf(offset.dot(direction.cross(Vector3.UP))) <= radius
func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss) or not boss.combat_active(): retire(); return
	var player = boss.target
	if warning > 0:
		warning -= delta
		return
	var valid_player: bool = is_instance_valid(player) and not player.dead
	if valid_player and kind == "choice":
		if contains(player.global_position): boss.choose_stance(choice)
	elif valid_player and not resolved and kind == "damage":
		resolved = true; label.text = caption+" · IMPACTO"
		if contains(player.global_position) and boss.has_clear_line(global_position+Vector3.UP,player.global_position+Vector3.UP): boss.hit_player(damage)
	elif valid_player and kind == "slow" and contains(player.global_position):
		boss.apply_ink(player)
	lifetime -= delta
	if lifetime <= 0: retire()

func retire() -> void:
	set_physics_process(false)
	hide()
	queue_free()
