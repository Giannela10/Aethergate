class_name NetworkInterferenceZone
extends Node3D
var boss: Node
var radius := 2.4
var lifetime := 5.0
var pulse_time := 0.0

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.035
	disc.radial_segments = 40
	mesh.mesh = disc
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.65,0.12,0.95,0.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = material
	add_child(mesh)
	var label := Label3D.new()
	label.text = "INTERFERENCIA"
	label.position.y = 0.5
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss) or not boss.combat_active():
		queue_free()
		return
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	pulse_time -= delta
	if pulse_time > 0:
		return
	pulse_time = 0.2
	var player: Node3D = boss.target
	if not is_instance_valid(player) or player.get("dead") == true or not boss.inside_arena(player.global_position):
		return
	var offset := player.global_position-global_position
	if absf(offset.y) < 1.5 and Vector2(offset.x,offset.z).length() <= radius and boss.has_clear_line(global_position+Vector3.UP,player.global_position+Vector3.UP):
		boss.apply_network_slow(player,1.0,0.6)
