extends Node3D
## Curación gratuita reutilizable y checkpoint al usar E fuera de los duelos.
var interaction_range := 2.5
var campaign: Node

func _ready() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	add_to_group("campus_interactable")
	add_to_group("health_station")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("35d48b")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for size in [Vector3(0.7,0.2,0.16),Vector3(0.2,0.7,0.16)]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		mesh.mesh = box
		mesh.position.y = 1.5
		mesh.material_override = material
		add_child(mesh)
	var label := Label3D.new()
	label.text = "+ CENTRO DE VIDA\n[E] Curarte gratis"
	label.position.y = 2.5
	label.font_size = 36
	label.pixel_size = 0.005
	label.modulate = Color("76ffb5")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func interaction_priority() -> int:
	return 2

func interaction_text(_player: Node) -> String:
	return "[E] Centro de vida · recuperar toda la vida"

func interact(player: CharacterBody3D) -> void:
	if player.dead or player.busy or player.global_position.distance_to(global_position) > interaction_range or not player._can_reach(self):
		return
	if is_instance_valid(campaign.active_duel):
		campaign.ui.notify("Termina el duelo para usar el centro de vida.")
		return
	player.heal(player.max_health)
	var position_value := player.global_position
	campaign.data.checkpoint = {"id":str(name),"position":[position_value.x,position_value.y,position_value.z],"health":player.max_health}
	campaign.ui.notify("VIDA COMPLETA · Punto de reaparición guardado")
	campaign.save_game()
