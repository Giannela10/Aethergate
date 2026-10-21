extends Node3D
var interaction_range := 2.5
enum Requirement { KEY_ITEM, BOSS_REWARD, MISSION, ACCESS_LEVEL }
@export var requirement_type: Requirement = Requirement.KEY_ITEM
@export var required_id := "TarjetaAcceso"
@export var access_id := ""
var campaign: Node
var unlocked := false
func _ready() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	add_to_group("campus_interactable")
	unlocked = bool(campaign.data.unlocks.get("door:"+access_id,false))
	get_parent().set_meta("campaign_locked",not unlocked)

func interaction_target() -> Node3D:
	return get_parent()

func can_access(player: Node) -> bool:
	if unlocked:
		return true
	match requirement_type:
		Requirement.KEY_ITEM: return player.has_key_item(required_id)
		Requirement.BOSS_REWARD: return campaign.data.bosses.get(required_id,false)
		Requirement.MISSION: return campaign.quests.state(required_id) == 2
		Requirement.ACCESS_LEVEL: return campaign.data.unlocks.get(required_id,false)
	return false

func interaction_text(player: Node) -> String:
	if unlocked:
		return ""
	return "[E] Abrir acceso" if can_access(player) else "[E] Acceso cerrado · Necesitas "+required_id

func interact(player: CharacterBody3D) -> void:
	if not can_access(player):
		campaign.ui.notify("Necesitas "+required_id)
		return
	unlocked = true
	get_parent().set_meta("campaign_locked",false)
	campaign.data.unlocks["door:"+access_id] = true
	campaign.event("door",access_id)
	campaign.ui.notify("Puerta desbloqueada")
	campaign.save_game()

func interaction_priority() -> int:
	return 2
