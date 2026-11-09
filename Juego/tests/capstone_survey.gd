extends Node3D
func _ready(): run.call_deferred()
func run():
	var campus=load("res://Main.tscn").instantiate()
	var campaign=campus.get_node("CampusCampaign")
	campaign.persist=false;campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	for frame in 5: await get_tree().process_frame
	var rows=[]
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		if not duel.initialized: continue
		var config=duel.actor.get("config")
		var configured=config.get("questions") if config!=null else null
		var simulation_questions=duel.actor.get("question_bank")
		rows.append({"id":duel.boss_id,"name":duel.boss_name,"floor":campaign.phone._floor_for(duel.actor),"actor":str(duel.actor.get_path()),"mentor":str(duel.interaction_target().get_path()),"interaction":duel.interaction_text(campaign.player),"actor_script":duel.actor.get_script().resource_path,"duel_script":duel.get_script().resource_path,"configured_questions":configured.size() if configured is Array else null,"simulation_bank":simulation_questions.size() if simulation_questions is Array else null,"published_bank_count":null,"published_status":"Not recoverable: current public read-only DNS probe failed; do not infer empty bank","initialized":duel.initialized})
	rows.append({"id":"Profesor","name":"Profesor de misión de documentos","floor":3,"subject":null,"published_bank_count":null,"status":"Mission NPC without assigned subject; no invented academic attribution"})
	var file=FileAccess.open("res://reports/capstone/teachers_before.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"\t"));file.close()
	print("CAPSTONE_SURVEY_DONE ",rows.size())
