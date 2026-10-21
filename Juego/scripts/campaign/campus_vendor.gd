extends Node3D
var interaction_range := 2.5
@export var vendor_name := "Máquina expendedora"
@export var prices: Dictionary = {"Bebida":5,"BebidaEnergetica":12,"Comida":10}
var campaign: Node
var quoted_prices := {}

func effective_price(id: String) -> int:
	return maxi(1,ceili(float(prices[id])*float(get_meta("live_discount",1.0))))
func _ready() -> void:
	campaign = get_tree().get_first_node_in_group("campus_campaign")
	add_to_group("campus_interactable")
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0,2.0,0.7)
	mesh.mesh = box
	mesh.position.y = 1
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("24547b")
	mesh.material_override = material
	add_child(mesh)
	var label := Label3D.new()
	label.text = vendor_name
	label.position.y = 2.4
	label.font_size = 32
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
func interaction_text(_player: Node) -> String:
	return "[E] Usar "+vendor_name
func interact(_player: CharacterBody3D) -> void:
	var choices: Array = []
	var callbacks: Array = []
	for id in prices:
		quoted_prices[id] = effective_price(id)
		choices.append("%s · %d créditos" % [id,quoted_prices[id]])
		callbacks.append(_buy.bind(id))
	choices.append("Cerrar")
	callbacks.append(campaign.ui.close_modal)
	campaign.ui.dialog(vendor_name,"Créditos Duoc: %d" % campaign.data.credits,choices,callbacks)
func _buy(id: String) -> void:
	var price := int(quoted_prices.get(id,effective_price(id)))
	if campaign.data.credits < price:
		campaign.ui.notify("Créditos insuficientes.")
		return
	var item = load("res://scripts/inventory/item_catalog.gd").get_item(id)
	if item == null or item.unique:
		return
	if campaign.player.receive_item(id,1) <= 0:
		return
	campaign.data.credits -= price
	campaign.save_game()
	campaign.ui.notify("Compraste: "+item.display_name)
	interact(campaign.player)

func interaction_priority() -> int:
	return 4
