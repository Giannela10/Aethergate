extends Node
const Migration = preload("res://scripts/live/save_migration.gd")
var campaign: Node
var state: Dictionary
var config: Resource
var director: Node
var campus_state: Node
var events: Node
var moments: Node
var reactive: Node
var retry: Node
var qol: Node
var diagnostics: Node
var settings: Node
var localization: Node
var floor_activity: Node
var rng := RandomNumberGenerator.new()
var restoring_inventory := false
func _ready() -> void:
	rng.randomize()
	config = preload("res://resources/live/campus_live.tres").duplicate(true)
	state = campaign.data.campus_live
	director = preload("res://scripts/live/gameplay_director.gd").new()
	director.name = "GameplayDirector"
	director.hub = self
	director.process_mode = Node.PROCESS_MODE_ALWAYS
	director.remaining = maxf(30,float(state.get("cooldown",90)))
	add_child(director)
	campaign.player.hit_received.connect(director.damage_received)
	campaign.gameplay_event.connect(on_event)
	campus_state = preload("res://scripts/live/campus_state.gd").new()
	campus_state.name = "CampusState"
	campus_state.hub = self
	add_child(campus_state)
	campus_state.refresh()
	events = preload("res://scripts/live/ambient_events.gd").new()
	events.name = "EventosAmbientales"
	events.hub = self
	add_child(events)
	moments = preload("res://scripts/live/story_moments.gd").new()
	moments.name = "StoryMoments"
	moments.hub = self
	add_child(moments)
	reactive = preload("res://scripts/live/reactive_world.gd").new()
	reactive.name = "MundoReactivo"
	reactive.hub = self
	add_child(reactive)
	retry = preload("res://scripts/live/boss_retry.gd").new()
	retry.name = "BossRetry"
	retry.hub = self
	add_child(retry)
	qol = preload("res://scripts/live/campus_qol.gd").new()
	qol.name = "CampusQoL"
	qol.hub = self
	add_child(qol)
	diagnostics = preload("res://scripts/live/balance_tools.gd").new()
	diagnostics.name = "BalanceTools"
	diagnostics.hub = self
	add_child(diagnostics)
	diagnostics.qa = preload("res://scripts/live/qa_tools.gd").new()
	localization = preload("res://scripts/live/campus_localization.gd").new()
	localization.name = "CampusLocalization"
	add_child(localization)
	settings = preload("res://scripts/live/campus_settings.gd").new()
	settings.name = "CampusSettings"
	settings.hub = self
	add_child(settings)
	floor_activity = preload("res://scripts/live/floor_activity_manager.gd").new()
	floor_activity.name = "FloorActivityManager"
	floor_activity.hub = self
	add_child(floor_activity)
func floor_id() -> String:
	return campaign.phone._floor_for(campaign.player)
func completed() -> bool:
	return campaign.data.bosses.get("nexo",false) == true or campaign.data.get("campaign_completed",false) == true
func event_active() -> bool:
	return events != null and events.active != null
func on_event(kind: String, id: String, _amount: int = 1) -> void:
	if campus_state != null: campus_state.refresh()
	if moments != null: moments.on_event(kind,id)
	if reactive != null and kind in ["boss","computer","story","secret"]: reactive.refresh()
	if retry != null and kind == "boss": retry.victory(id)
	if qol != null: qol.on_event(kind,id)
	if diagnostics != null: diagnostics.on_event(kind,id)
	if kind in ["boss","story","computer","deliver","secret"]:
		director.activity()
