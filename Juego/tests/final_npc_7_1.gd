extends Node
var f: Node
func install(parent: Node) -> String:
	f=parent;name="NPCInspect71";parent.add_child(self);return "NPC_INSPECTION_READY"
func inspect(number: int) -> void:
	f.active_floor=number;f.phase="npc_motion"
	var height: float=preload("res://scripts/campaign/campus_content.gd").HEIGHTS[number-1]
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		if absf(duel.actor.global_position.y-height)>1 or duel.simulation==null: continue
		var visual=duel.simulation.mentor_visual
		f.player.global_position=visual.global_position+Vector3(0,0,3)
		visual.set_meta("important_scene",true);visual.activity_level=0;visual.update_visual_lod(1.0)
		for i in 60:
			visual.animate(1.0/60.0,Vector3.ZERO,true,false)
			await get_tree().process_frame
		var adapter=visual.get("human_visual63")
		var imported=adapter.model if adapter!=null else null
		f.record("human_imported_"+duel.boss_id,"PASS" if imported!=null and imported.rig.get_bone_count()==53 else "FAIL",{"scale":str(visual.global_basis.get_scale()),"policy_height":visual.get_meta("standard_human_height",null),"scope":"Actual imported mentor, one second of idle animation; not all movement states"})
		await f.shot("npc_"+duel.boss_id+"_front",visual.global_position+visual.global_basis.orthonormalized()*Vector3(0,1.6,-4),visual.global_position+Vector3.UP*1.35)
		await f.shot("npc_"+duel.boss_id+"_side",visual.global_position+visual.global_basis.orthonormalized()*Vector3(4,1.6,0),visual.global_position+Vector3.UP*1.35)
	f.write("floor_"+str(number)+"/npc_done",{"floor":number})
