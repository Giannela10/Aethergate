extends Node3D
var interaction_range := 4.5
@export var npc_name := "Estudiante"
@export_multiline var dialogue := "Bienvenido al Duoc."
@export var quest_id := ""
@export var portrait: Texture2D
@export var requested_items: Dictionary = {}
@export var starting_items: Dictionary = {}
var campaign: Node
var model: Node3D
var name_label: Label3D
var visual_tick := 0.0
var animation_elapsed := 0.0
func _ready() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	add_to_group("campus_interactable")
	model = load("res://scripts/juego/student_visual.gd").new()
	model.name = "CharacterVisual"
	model.set_meta("role",preload("res://scripts/juego/character_visual_presets.gd").role_for(str(name)))
	model.scale = Vector3.ONE*1.4
	add_child(model)
	var presets = preload("res://scripts/juego/character_visual_presets.gd")
	var id := str(name)
	if not campaign.data.npc_visuals.get(id) is Dictionary:
		campaign.data.npc_visuals[id] = presets.create(id,presets.role_for(id))
	campaign.data.npc_visuals[id] = presets.upgrade(id,campaign.data.npc_visuals[id])
	presets.apply(model,campaign.data.npc_visuals[id])
	var role := presets.role_for(id)
	if role in ["PROFESOR","FUNCIONARIO"]:
		model.set_visual_activity("READ","FOLDER")
	elif role == "TECNICO":
		model.set_visual_activity("INSPECT","TABLET")
	var label := Label3D.new()
	name_label = label
	label.text = npc_name
	label.position.y = 2.8
	label.font_size = 32
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func interaction_text(_player: Node) -> String:
	return "[E] Hablar con "+npc_name

func interact(player: CharacterBody3D) -> void:
	if player.busy or player.dead:
		return
	if not quest_id.is_empty():
		model.set_expression("WORRIED" if campaign.quests.state(quest_id) == 1 else ("HAPPY" if campaign.quests.state(quest_id) == 2 else "NEUTRAL"))
		campaign.ui.begin_character_dialogue(self)
	campaign.event("talk",name)
	if quest_id.is_empty():
		var ambient: String = dialogue
		if campaign.live != null: ambient += "\n\n"+campaign.live.campus_state.ambient_line()
		campaign.ui.dialog(npc_name,ambient,["Gracias"],[campaign.ui.close_modal])
		return
	var state: int = campaign.quests.state(quest_id)
	var postgame_line := "\n\nLos sistemas volvieron a la normalidad." if str(name) == "Tecnico" and campaign.data.get("campaign_completed",false) else ""
	if state == 1:
		_provide_starting_items()
	if state == 2:
		campaign.ui.dialog(npc_name,"¡Gracias por tu ayuda! Ya recibiste la recompensa."+postgame_line,["Hasta luego"],[campaign.ui.close_modal])
		return
	if state == 0:
		campaign.ui.dialog(npc_name,dialogue+postgame_line,["Aceptar misión","Ahora no"],[_accept,campaign.ui.close_modal])
		return
	var complete := not requested_items.is_empty()
	for id in requested_items:
		complete = complete and player.inventory.has_item(id,requested_items[id])
	var text := "Todavía necesito: "+str(requested_items) if not complete else "¡Encontraste lo que buscaba!"
	text += postgame_line
	campaign.ui.dialog(npc_name,text,["Entregar objetos","Volver después"] if complete else ["Volver después"],[_deliver,campaign.ui.close_modal] if complete else [campaign.ui.close_modal])

func _accept() -> void:
	campaign.ui.close_modal()
	campaign.quests.start_quest(quest_id)
	_provide_starting_items()
	campaign.save_game()

func _provide_starting_items() -> void:
	if starting_items.is_empty() or campaign.quests.state(quest_id) != 1:
		return
	var provided: bool = campaign.data.unlocks.get("provided:"+quest_id,false)
	for id in starting_items:
		var item = preload("res://scripts/inventory/item_catalog.gd").get_item(id)
		# Repair old failed deliveries only for unconsumed quest keys, not consumables.
		var recover_key: bool = provided and item != null and item.category == 2 and int(campaign.events.get("deliver:"+quest_id,0)) == 0
		if not provided or recover_key:
			var missing := maxi(0,int(starting_items[id])-campaign.player.inventory.count_item(id))
			if missing > 0: campaign.give_reward_item(id,missing)
	campaign.data.unlocks["provided:"+quest_id] = true
	campaign.save_game()

func _deliver() -> void:
	for id in requested_items:
		if not campaign.player.inventory.has_item(id,requested_items[id]):
			return
	for id in requested_items:
		campaign.player.inventory.remove_items(id,requested_items[id],true)
	campaign.ui.close_modal()
	campaign.event("deliver",quest_id)
	campaign.save_game()

func interaction_priority() -> int:
	return 0

func _process(delta: float) -> void:
	if not is_instance_valid(campaign) or not is_instance_valid(campaign.player):
		return
	animation_elapsed += delta
	visual_tick -= delta
	if visual_tick > 0:
		return
	var offset: Vector3 = campaign.player.global_position-global_position
	var same_floor := absf(offset.y) < 4.0
	var distance := offset.length()
	var near: bool = same_floor and distance < model.visual_near_distance
	model.update_visual_lod(animation_elapsed)
	visual_tick = 0.0 if near else (0.15 if same_floor and distance < model.visual_far_distance else 0.8)
	model.secondary_animation_enabled = near
	name_label.visible = same_floor and distance < 6
	var mark := ""
	if not quest_id.is_empty() and campaign.quests != null:
		var state: int = campaign.quests.state(quest_id)
		if state == 0:
			var definition = campaign.quests.definitions.get(quest_id)
			if definition != null and (definition.prerequisite.is_empty() or campaign.quests.state(definition.prerequisite) == 2):
				mark = " !"
		elif state == 1 and not requested_items.is_empty():
			var ready := true
			for id in requested_items:
				ready = ready and campaign.player.inventory.has_item(id,requested_items[id])
			if ready: mark = " ?"
	name_label.text = npc_name+mark
	if same_floor and distance < model.visual_far_distance:
		model.animate(minf(animation_elapsed,0.2),Vector3(0,0,1.3) if get_meta("duel_retreating",false) else Vector3.ZERO,true,false)
	animation_elapsed = 0
