extends Node3D
## Explicit isolated rendered fixture; not a player save or a campaign playthrough.
var campaign: Node
var actor: CharacterBody3D
var ready_for_capture := false
func _ready() -> void:
	var main = load("res://Main.tscn").instantiate()
	campaign = main.get_node("CampusCampaign"); campaign.persist = false
	main.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(main)
	while not campaign.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	campaign.ui.close_modal(); campaign.live.director.enabled = false
	for q in campaign.quests.definitions.values():
		if q.main_quest and q.quest_id != "nexo_final": campaign.data.quests[q.quest_id].state = 2
	campaign.data.bosses["director"] = true
	campaign.data.unlocks["nexo_archive_read"] = true
	campaign.give_reward_item("CredencialDirector",1); campaign.quests.refresh()
	campaign.final_area.enter_core()
	actor = campaign.final_area.actor
	campaign.player.global_position = actor.global_position+Vector3(0,0,7.5)
	campaign.manager.cam_yaw = 0
	campaign.manager.cam_pivot = campaign.player.global_position+Vector3.UP*1.4
	campaign.player.receive_item("Palo",1)
	campaign.live.moments.queue.clear()
	campaign.ui.notice_queue.clear(); campaign.ui.toast_t = 0
	campaign.data.tutorial = true
	ready_for_capture = true
	print("NEXO_VISUAL_FIXTURE_READY — no user saves")
