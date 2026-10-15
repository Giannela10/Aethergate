extends Node3D
var interaction_range := 4.5
@export var npc_name := "Estudiante"
@export_multiline var dialogue := "Bienvenido al Duoc."
@export var quest_id := ""
@export var requested_items: Dictionary = {}
@export var starting_items: Dictionary = {}
var campaign: Node
func _ready() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	add_to_group("campus_interactable")
	var model = load("res://scripts/juego/humanoid.gd").new()
	model.shirt_color = Color("419182")
	model.scale = Vector3.ONE*1.4
	add_child(model)
	var label := Label3D.new()
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
	campaign.event("talk",name)
	if quest_id.is_empty():
		campaign.ui.dialog(npc_name,dialogue,["Gracias"],[campaign.ui.close_modal])
		return
	var state: int = campaign.quests.state(quest_id)
	if state == 1 and not starting_items.is_empty() and not campaign.data.unlocks.get("provided:"+quest_id,false):
		campaign.data.unlocks["provided:"+quest_id] = true
		for id in starting_items:
			player.receive_item(id,starting_items[id])
		campaign.save_game()
	if state == 2:
		campaign.ui.dialog(npc_name,"¡Gracias por tu ayuda! Ya recibiste la recompensa.",["Hasta luego"],[campaign.ui.close_modal])
		return
	if state == 0:
		campaign.ui.dialog(npc_name,dialogue,["Aceptar misión","Ahora no"],[_accept,campaign.ui.close_modal])
		return
	var complete := not requested_items.is_empty()
	for id in requested_items:
		complete = complete and player.inventory.has_item(id,requested_items[id])
	var text := "Todavía necesito: "+str(requested_items) if not complete else "¡Encontraste lo que buscaba!"
	campaign.ui.dialog(npc_name,text,["Entregar objetos","Volver después"] if complete else ["Volver después"],[_deliver,campaign.ui.close_modal] if complete else [campaign.ui.close_modal])

func _accept() -> void:
	campaign.ui.close_modal()
	campaign.quests.start_quest(quest_id)
	if not starting_items.is_empty() and not campaign.data.unlocks.get("provided:"+quest_id,false):
		campaign.data.unlocks["provided:"+quest_id] = true
		for id in starting_items:
			campaign.player.receive_item(id,starting_items[id])
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
