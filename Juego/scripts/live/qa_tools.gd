extends RefCounted
const Catalog = preload("res://scripts/inventory/item_catalog.gd")
const Registry = preload("res://scripts/live/id_registry.gd")
func run(campaign: Node) -> Dictionary:
	var registry := Registry.new()
	var errors: Array[String] = []
	var review: Array[String] = []
	var targets := {}
	for computer in campaign.get_tree().get_nodes_in_group("computer"):
		targets["computer:"+str(computer.get_meta("campaign_id",""))] = computer
	for duel in campaign.get_tree().get_nodes_in_group("boss_duel"):
		registry.reserve("boss",duel.boss_id,str(duel.get_path()))
		targets["boss:"+duel.boss_id] = duel
	for id in Catalog.all_ids(): registry.reserve("item",Catalog.get_item(id).id,"catalog:"+str(id))
	for node in campaign.get_children():
		if node.get_script() == preload("res://scripts/campaign/npc.gd"):
			registry.reserve("npc",str(node.name),str(node.get_path()))
			if not node.quest_id.is_empty() and not campaign.quests.definitions.has(node.quest_id): errors.append("NPC quest missing: "+str(node.name))
	for id in campaign.quests.definitions:
		var quest = campaign.quests.definitions[id]
		registry.reserve("quest",quest.quest_id,"quest:"+str(id))
		if not quest.prerequisite.is_empty() and not campaign.quests.definitions.has(quest.prerequisite): errors.append("Missing prerequisite: "+id)
		var chain := {}
		var cursor: String = id
		while not cursor.is_empty() and campaign.quests.definitions.has(cursor):
			if chain.has(cursor):
				errors.append("Cyclic prerequisite: "+id); break
			chain[cursor] = true
			cursor = campaign.quests.definitions[cursor].prerequisite
		for requirement in quest.requirements:
			var kind: String = requirement.kind
			var target_id: String = requirement.id
			if kind in ["computer","boss"] and not targets.has(kind+":"+target_id): errors.append("Missing target: "+id+" -> "+kind+":"+target_id)
			if kind == "collect" and target_id != "*" and Catalog.get_item(target_id) == null: errors.append("Missing item: "+id+" -> "+target_id)
			if kind == "deliver":
				var owners := campaign.get_children().filter(func(n): return n.get("quest_id") == target_id and n.has_method("_deliver"))
				if owners.is_empty(): errors.append("Missing delivery NPC: "+id)
			if kind == "boss" and campaign.data.bosses.get(target_id,false) and campaign.quests.progress(requirement) < int(requirement.amount): review.append("Defeated boss without equivalent progress event: "+target_id)
			if kind == "door": review.append("Check credential source and physical route: "+target_id)
		for item_id in quest.reward.get("items",{}):
			if Catalog.get_item(item_id) == null: errors.append("Missing reward item: "+item_id)
	for event in campaign.live.events.catalog: registry.reserve("event",event.event_id,"event:"+str(event.get_instance_id()))
	errors.append_array(registry.duplicates)
	var navigation: Array = []
	for path in ["GameplayManager/Player","SistemasCompartidos/AscensoresEstudiantiles","Piso1","Piso2","Piso3","Piso4","Piso5","Piso6","Piso7","Piso8"]:
		var node = campaign.get_parent().get_node_or_null(NodePath(path))
		navigation.append({"path":path,"exists":node != null})
		if node == null: review.append("Review scene path/alias: "+path)
	for group in ["campus_checkpoint","boss_duel","campus_guard"]:
		for node in campaign.get_tree().get_nodes_in_group(group):
			navigation.append({"path":str(node.get_path()),"position":str(node.global_position),"ground_check":"existing placement validator/manual route"})
	review.append("Stairs, door connectivity and arena exits require an in-game traversal; no automatic geometry repair")
	return {"errors":errors,"manual_review":review,"navigation":navigation,"registered_ids":registry.ids.size(),"geometry_modified":false}
