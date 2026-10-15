extends Node3D
@export var marker_id := ""
@export var marker_type := "area"
@export var area_name := ""
@export var radius := 2.5
@export var required_door := ""
var entered := false
var campaign: Node
func _ready() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	add_to_group("campus_area")
func _process(_delta: float) -> void:
	if not campaign.ready_for_play or campaign.player.dead:
		return
	var inside: bool = global_position.distance_to(campaign.player.global_position) < radius
	if inside and not entered:
		if not required_door.is_empty() and not campaign.data.unlocks.get("door:"+required_door,false):
			return
		if marker_type == "secret":
			if not campaign.data.secrets.has(marker_id):
				campaign.data.secrets[marker_id] = true
				campaign.event("secret",marker_id)
				campaign.grant_reward({"credits":25,"xp":40},"secret:"+marker_id)
				campaign.ui.notify("Secreto descubierto: "+area_name)
				campaign.save_game()
		else:
			campaign.event(marker_type,marker_id)
			campaign.ui.notify(area_name,2.0)
	entered = inside
