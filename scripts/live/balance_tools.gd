extends Node
const Catalog = preload("res://scripts/inventory/item_catalog.gd")
var hub: Node
var telemetry: Array[Dictionary] = []
var previous_health := 0.0
var last_quest_states := {}
var quest_started := {}
var deaths_by_boss := {}
var mission_durations := {}
var qa: RefCounted

func attack_formulas(actor: Node) -> Array[String]:
	var result: Array[String] = []
	var script = actor.get_script()
	if not script is GDScript: return result
	for line in script.source_code.split("\n"):
		if (line.contains("take_hit") and not line.strip_edges().begins_with("func ")) or line.contains(".damage ="):
			result.append(line.strip_edges())
	return result
func _ready() -> void:
	previous_health = hub.campaign.player.health
	hub.campaign.player.health_changed.connect(health_changed)
	hub.campaign.player.died.connect(player_died)
	hub.campaign.player.inventory.item_used.connect(func(id): record("item_used",{"id":id}))
func enabled() -> bool:
	return OS.is_debug_build() and hub.config.telemetry_enabled
func record(kind: String, values: Dictionary = {}) -> void:
	if not enabled(): return
	var row := values.duplicate(true)
	row["kind"] = kind
	row["time"] = float(hub.campaign.data.stats.get("time_played",0))
	telemetry.append(row)
	while telemetry.size() > 1000: telemetry.pop_front()
	# No networking. Opt-in development log, bounded by rotating one file.
	if hub.campaign.persist:
		var path := "user://campus_telemetry.json"
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(telemetry))
func health_changed(health: float, _max_health: float) -> void:
	if health < previous_health:
		record("damage",{"amount":previous_health-health,"weapon":str(hub.campaign.player.weapon.weapon_name) if hub.campaign.player.weapon != null else "Puños"})
	previous_health = health
func player_died() -> void:
	var duel = hub.campaign.active_duel
	var id := str(duel.boss_id) if is_instance_valid(duel) else str(hub.campaign.live.retry.duel.boss_id) if is_instance_valid(hub.campaign.live.retry.duel) and hub.campaign.live.retry.failed else "world"
	var position: Vector3 = hub.campaign.player.global_position
	if enabled(): deaths_by_boss[id] = int(deaths_by_boss.get(id,0))+1
	record("death",{"boss":id,"position":[position.x,position.y,position.z]})
func on_event(kind: String, id: String) -> void:
	record(kind,{"id":id})
	if not enabled(): return
	for quest_id in hub.campaign.quests.definitions:
		var status: int = hub.campaign.quests.state(quest_id)
		if status == 1 and not quest_started.has(quest_id): quest_started[quest_id] = float(hub.campaign.data.stats.get("time_played",0))
		if status == 2 and last_quest_states.get(quest_id,0) != 2 and quest_started.has(quest_id):
			mission_durations[quest_id] = float(hub.campaign.data.stats.get("time_played",0))-float(quest_started[quest_id])
		last_quest_states[quest_id] = status
func balance_report() -> Dictionary:
	var bosses: Array = []
	for duel in get_tree().get_nodes_in_group("boss_duel"):
		var actor = duel.actor
		var damage = actor.get("attack_damage")
		if damage == null: damage = actor.get("melee_damage")
		if damage == null: damage = actor.get("mistake_damage")
		if damage == null: damage = attack_formulas(actor)
		var cooldowns := {}
		for key in ["attack_cooldown","attack_cd","tray_cd","digital_cd","blue_cd","packet_cd","pulse_cd","zone_cd","connection_cd","throw_cooldown"]:
			if actor.get(key) != null: cooldowns[key] = actor.get(key)
		bosses.append({"id":duel.boss_id,"health":duel.max_health,"damage":damage,"damage_note":"Numeric export or exact formulas from the existing script","current_phase":actor.get("phase"),"thresholds": [0.6,0.3] if duel.boss_id in ["chef","director"] else [],"cooldowns_current":cooldowns,"telegraph":"Existing windup/zone plus pending-special label","range_adaptation":"Existing distance conditions retained"})
		if duel.boss_id == "nexo":
			bosses.back().thresholds = [actor.config.phase_two,actor.config.phase_three]
			bosses.back()["human_balance"] = "PENDIENTE DE BALANCE HUMANO"
	var weapons: Array = []
	var consumables: Array = []
	for id in Catalog.all_ids():
		var item = Catalog.get_item(id)
		if item.category == 0: consumables.append({"id":id,"heal":item.heal_amount,"full_heal":item.full_heal,"speed":item.speed_multiplier,"duration":item.duration})
		if item.category != 1: continue
		var stats: Dictionary = item.weapon_data.duplicate(true)
		if stats.is_empty():
			stats = preload("res://scripts/juego/weapon.gd").KINDS.get(item.weapon_kind,{}).duplicate(true)
			if stats.is_empty(): stats = preload("res://scripts/juego/implemento_deportivo.gd").SPORTS.get(item.weapon_sport,{}).duplicate(true)
		else:
			var factor: float = [1.0,1.1,1.25,1.4][item.rarity]
			stats.damage = float(stats.get("damage",0))*factor
			stats.durability = ceili(float(stats.get("durability",0))*factor)
		weapons.append({"id":id,"stats":stats,"weight":stats.get("weight","not_defined")})
		if stats.is_empty() and item.weapon_kind == "paleta_ping_pong":
			weapons.back().stats = {"source":"res://scripts/inventory/paleta_ping_pong.gd","damage":20.0,"durability":22,"swing_time":0.48}
	var enemies: Array = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_node("BossDuelController"): continue
		enemies.append({"name":str(enemy.name),"health":enemy.get("health"),"damage":enemy.get("melee_damage")})
	return {"bosses":bosses,"weapons":weapons,"consumables":consumables,"enemies":enemies,"economy":economy_report(),"telemetry_enabled":enabled(),"deaths":deaths_by_boss,"mission_durations":mission_durations}
func economy_report() -> Dictionary:
	var quest_credits := 0
	var upgrade_total := 0
	for quest in hub.campaign.quests.definitions.values(): quest_credits += int(quest.reward.get("credits",0))
	for level in 5: upgrade_total += (60+level*40)*5
	var vendors: Array = []
	for node in hub.campaign.get_children():
		if node.get("prices") is Dictionary: vendors.append({"name":str(node.name),"prices":node.prices})
	return {"quest_credits":quest_credits,"boss_credits":get_tree().get_nodes_in_group("boss_duel").size()*75,"all_upgrades_cost":upgrade_total,"live_reward_cap":hub.config.reward_budget,"vendors":vendors,"review":["Free repeatable healing is intentional","No resale system observed: no sell-price arbitrage evaluated","Furniture is plentiful; count sources, not unique item definitions","Rewards must use campaign.grant_reward source IDs"],"automatic_changes":false}
func save_report(path: String = "user://campus_balance_report.json") -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"balance":balance_report(),"qa":qa.run(hub.campaign) if qa != null else {}},"  "))
	return file.get_error()
func show_report() -> void:
	var text := JSON.stringify(balance_report(),"  ")
	if qa != null: text += "\nQA\n"+JSON.stringify(qa.run(hub.campaign),"  ")
	hub.campaign.ui.dialog("DESARROLLO · BALANCE Y QA",text,["Guardar reporte local","Volver"],[func(): hub.campaign.ui.notify("Reporte: "+error_string(save_report())),hub.campaign.show_options],true)
