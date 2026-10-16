extends RefCounted
const Registry = preload("res://scripts/live/id_registry.gd")
static func theme_allowed(floor_name: String, role: String, sector: String = "") -> bool:
	if role == "PROFESOR" and floor_name == "4": return sector == "teachers"
	if role in ["ENFERMERIA","ODONTOLOGIA","health"]: return floor_name == "4" and sector == "health"
	if role in ["teachers"]: return floor_name == "4" and sector == "teachers"
	if role in ["TECNICO","technology"]: return floor_name == "3"
	if role in ["TALLER","workshop"]: return floor_name == "-1"
	if role == "library": return floor_name == "2"
	if role == "casino": return floor_name == "1"
	if role == "general": return floor_name in ["5","6","7","8"]
	if role == "director": return floor_name == "8"
	return floor_name in ["1","2","3","4","5","6","7","8","-1"]

static func floor_at(position: Vector3) -> String:
	var heights = preload("res://scripts/campaign/campus_content.gd").HEIGHTS
	var index := 0
	for i in heights.size():
		if absf(position.y-heights[i]) < absf(position.y-heights[index]): index = i
	return "-1" if index == 8 else str(index+1)
static func create_npc(campaign: Node3D, data: Resource, position: Vector3) -> Node3D:
	if not Registry.valid_id(data.npc_id) or campaign.has_node(NodePath(data.npc_id)): return null
	if not theme_allowed(data.floor,data.role,data.sector): return null
	if floor_at(position) != data.floor: return null
	if not data.quest_id.is_empty() and not campaign.quests.definitions.has(data.quest_id): return null
	var npc := preload("res://scripts/campaign/npc.gd").new()
	npc.name = data.npc_id; npc.npc_name = data.display_name; npc.dialogue = data.dialogue; npc.quest_id = data.quest_id
	npc.position = position
	if not data.appearance.is_empty(): campaign.data.npc_visuals[data.npc_id] = data.appearance.duplicate(true)
	campaign.add_child(npc)
	return npc
static func create_boss(parent: Node3D, data: Resource, position: Vector3) -> Node3D:
	if data.actor_scene == null or not Registry.valid_id(data.boss_id) or not theme_allowed(data.floor,data.theme,data.sector): return null
	if floor_at(position) != data.floor: return null
	for duel in parent.get_tree().get_nodes_in_group("boss_duel"):
		if duel.boss_id == data.boss_id: return null
	var actor := data.actor_scene.instantiate() as Node3D
	if actor == null: return null
	var duel := actor.get_node_or_null("BossDuelController")
	if duel == null: actor.free(); return null
	duel.boss_id = data.boss_id; duel.boss_name = data.display_name
	actor.position = position; parent.add_child(actor)
	return actor
static func create_pickup(campaign: Node3D, world_id: String, item_id: String, position: Vector3) -> Node3D:
	if not Registry.valid_id(world_id) or campaign.has_node(NodePath(world_id)): return null
	var item = preload("res://scripts/inventory/item_catalog.gd").get_item(item_id)
	if item == null: return null
	return preload("res://scripts/campaign/campus_content.gd").add_item(campaign,world_id,item_id,position,item.category == 1)
static func create_quest(campaign: Node, data: Resource) -> bool:
	if data.get_script() != preload("res://scripts/campaign/quest.gd") or not Registry.valid_id(data.quest_id) or campaign.quests.definitions.has(data.quest_id): return false
	if not data.prerequisite.is_empty() and not campaign.quests.definitions.has(data.prerequisite): return false
	campaign.quests.definitions[data.quest_id] = data
	campaign.data.quests[data.quest_id] = {"state":0}
	campaign.quests.refresh()
	return true
static func create_event(campaign: Node, data: Resource) -> bool:
	if data.get_script() != preload("res://scripts/live/event_data.gd") or not Registry.valid_id(data.event_id): return false
	for event in campaign.live.events.catalog:
		if event.event_id == data.event_id: return false
	for floor_name in data.floors:
		if not theme_allowed(floor_name,data.sector if not data.sector.is_empty() else "campus",data.sector): return false
	campaign.live.events.catalog.append(data)
	return true
