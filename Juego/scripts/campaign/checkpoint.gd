extends Node3D
@export var checkpoint_id := ""
var campaign: Node
func _ready() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	add_to_group("campus_checkpoint")
	var label := Label3D.new()
	label.text = "CHECKPOINT"
	label.position.y = 2.3
	label.pixel_size = 0.004
	label.font_size = 32
	label.modulate = Color("66cdd0")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
func _process(_delta: float) -> void:
	if not campaign.ready_for_play or campaign.player.dead or campaign.player.busy or is_instance_valid(campaign.active_duel):
		return
	if global_position.distance_to(campaign.player.global_position) < 2.2 and campaign.data.checkpoint.get("id","") != checkpoint_id:
		campaign.data.checkpoint = {"id":checkpoint_id,"position":[global_position.x,global_position.y+0.15,global_position.z],"health":campaign.player.health}
		campaign.ui.notify("Checkpoint activado: "+checkpoint_id)
		campaign.event("checkpoint",checkpoint_id)
		campaign.save_game()
