extends Node
var campaign: Node
func show_quests() -> void:
	campaign.ui.page = "quests"
	campaign.ui.dialog("MISIONES",campaign.quests.describe(),["Cerrar"],[campaign.ui.close_modal],true)
