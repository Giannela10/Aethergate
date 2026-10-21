extends Node
## Registro exclusivo del Piso 8. Las puertas futuras consultan has_credential().
signal credential_granted(credential: String)
const CREDENTIAL := "CredencialDirector"
@export var persist := true
@export var save_path := "user://credencial_director.cfg"
var acquired := false
var badge: Label

func _ready() -> void:
	if persist:
		var data := ConfigFile.new()
		if data.load(save_path) == OK:
			acquired = bool(data.get_value("recompensas",CREDENTIAL,false))
	var layer := CanvasLayer.new()
	layer.name = "EstadoCredencial"
	add_child(layer)
	badge = Label.new()
	badge.text = "CredencialDirector obtenida"
	badge.position = Vector2(20,410)
	badge.add_theme_color_override("font_outline_color",Color.BLACK)
	badge.add_theme_constant_override("outline_size",4)
	layer.add_child(badge)

func _process(_delta: float) -> void:
	var campaign := get_tree().get_first_node_in_group("campus_campaign")
	if campaign and not campaign.ready_for_play:
		return
	if campaign and campaign.ready_for_play:
		acquired = bool(campaign.data.bosses.get("director",false))
	var player := get_tree().get_first_node_in_group("player") as Node3D
	badge.visible = acquired and is_instance_valid(player) and absf(player.global_position.y - 83.94) < 4.0
	if acquired and is_instance_valid(player):
		_sync_inventory(player)
	elif is_instance_valid(player) and player.has_method("has_key_item") and player.call("has_key_item",CREDENTIAL):
		grant_credential(player)

func has_credential(credential: String = CREDENTIAL) -> bool:
	return credential == CREDENTIAL and acquired

func grant_credential(player: Node = null) -> bool:
	if is_instance_valid(player):
		_sync_inventory(player)
	if acquired:
		return false
	acquired = true
	if persist:
		var data := ConfigFile.new()
		data.set_value("recompensas",CREDENTIAL,true)
		var error := data.save(save_path)
		if error != OK:
			push_warning("CredencialDirector obtenida en esta sesión; no se pudo guardar: %s" % error_string(error))
	credential_granted.emit(CREDENTIAL)
	return true

func _sync_inventory(player: Node) -> void:
	player.set_meta(CREDENTIAL,true)
	var inventory = player.get("inventory")
	if inventory != null and not inventory.has_item(CREDENTIAL) and player.has_method("receive_item"):
		player.call("receive_item",CREDENTIAL,1)
