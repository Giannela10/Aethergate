class_name PhonePreview
extends Node
## F6: campus aislado sin guardados del usuario.
func _ready() -> void:
	call_deferred("open_preview")
func open_preview() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var campaign = scene.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(scene)
	while not campaign.ready_for_play:
		await get_tree().process_frame
	campaign.ui.close_modal()
	campaign.phone.open()
