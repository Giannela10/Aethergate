extends Node3D
## Safe visual access to the existing personalization menu.
var campaign: Node
var station_kind := "LOCKER"
var interaction_range := 2.2
var label: Label3D

func _ready() -> void:
	add_to_group("campus_interactable")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("405768") if station_kind == "LOCKER" else Color("8ea6b0")
	material.metallic = 0.45
	material.roughness = 0.35
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.65,1.65,0.38 if station_kind == "LOCKER" else 0.08)
	mesh.mesh = box
	mesh.position.y = 0.825
	mesh.material_override = material
	add_child(mesh)
	label = Label3D.new()
	label.text = "ARMARIO PERSONAL" if station_kind == "LOCKER" else "ESPEJO"
	label.position.y = 1.95
	label.font_size = 26
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func interaction_text(_player: Node) -> String:
	return "[E] Personalizar personaje"

func context_action() -> String:
	return "inspect"

func interact(player: Node3D) -> void:
	if player.dead or player.busy or player.body.is_punching() or campaign.active_duel != null:
		return
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node3D and enemy.get("dead") != true and enemy.global_position.distance_squared_to(player.global_position) < 100:
			campaign.ui.notify("Personalización disponible fuera de combate")
			return
	campaign.show_personalization()

func _process(_delta: float) -> void:
	if is_instance_valid(campaign.player):
		label.visible = global_position.distance_squared_to(campaign.player.global_position) < 36

static func setup(owner_campaign: Node3D) -> void:
	for row in [["LOCKER",Vector3(6,0.1,-4)],["MIRROR",Vector3(7,0.1,-4)]]:
		var station = load("res://scripts/campaign/appearance_station.gd").new()
		station.name = "ArmarioPersonal" if row[0] == "LOCKER" else "EspejoPersonal"
		station.campaign = owner_campaign
		station.station_kind = row[0]
		station.position = row[1]
		owner_campaign.add_child(station)
