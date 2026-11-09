extends Node3D
func _ready(): run.call_deferred()
func run():
 var campus=load("res://Main.tscn").instantiate()
 var campaign=campus.get_node("CampusCampaign")
 campaign.persist=false;campaign.set_meta("test_mode",true)
 campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
 add_child(campus)
 while not campaign.ready_for_play: await get_tree().process_frame
 await get_tree().create_timer(2).timeout
 var rows=[]
 for visual in get_tree().get_nodes_in_group("campus_character_visual"):
  var actor=visual.get_parent()
  var row={"path":str(visual.get_path()),"actor_path":str(actor.get_path()),"script":actor.get_script().resource_path if actor.get_script() else "","visual_script":visual.get_script().resource_path,"position":str(visual.global_position),"floor":roundi(visual.global_position.y/12)+1,"profile":visual.get_meta("visual_preset",{}),"appearance":visual.get_meta("appearance_profile",{}),"visible":visual.is_visible_in_tree(),"groups":actor.get_groups(),"interaction":actor.interaction_text(campaign.player) if actor.has_method("interaction_text") else ""}
  for key in ["npc_id","id","boss_id","student_id"]:
   if actor.get(key)!=null: row[key]=actor.get(key)
  rows.append(row)
 var file=FileAccess.open("res://reports/characters_6_3/inventory_runtime.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(rows,"\t"));file.close()
 print("INVENTORY63_DONE ",rows.size())
