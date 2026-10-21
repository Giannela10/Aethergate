class_name ContextualPreview
extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var campaign = scene.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(scene)
	while not campaign.ready_for_play:
		await get_tree().process_frame
	campaign.ui.close_modal()
	var player = campaign.player
	var seating = player.get_node("SeatController")
	var point = get_tree().get_first_node_in_group("campus_seat")
	if point == null:
		push_error("No hay butacas con suelo seguro")
		return
	for offset in [Vector3(0,0,-1.2),Vector3(0,0,1.2),Vector3(-1.2,0,0),Vector3(1.2,0,0)]:
		var safe = seating.safe_position(point.global_position+offset)
		if safe != null:
			player.global_position = safe
			if seating.begin(point):
				break
	campaign.manager.cam_dist = 6.0
	campaign.manager.cam_yaw = player.body.rotation.y+0.7
	print("CONTEXT_PREVIEW ",point.furniture.name)
