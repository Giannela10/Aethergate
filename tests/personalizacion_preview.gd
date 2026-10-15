class_name AppearancePreview
extends Node
## F6: vista aislada, sin cargar ni sobrescribir la partida real.
func _ready() -> void:
	call_deferred("show_preview")
func show_preview() -> void:
	var campus = load("res://Main.tscn").instantiate()
	var campaign = campus.get_node("CampusCampaign")
	campaign.persist = false
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(campus)
	while not campaign.ready_for_play:
		await get_tree().process_frame
	campaign.show_personalization()
