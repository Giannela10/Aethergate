extends Node
var campaign: Node
var ambient: Array[AudioStreamPlayer3D] = []
@export var random_events_enabled := false
var event_timer := 360.0
func _ready() -> void:
	if campaign == null:
		campaign = get_parent()
	for row in [["Casino",Vector3(-50,2,-104)],["Biblioteca",Vector3(-50,14,-111)],["Pasillos",Vector3(25,38,-143)],["Subterraneo",Vector3(25,-10,-143)],["Tecnologia",Vector3(50,86,-131)]]:
		var player := get_node_or_null("Ambiente"+row[0]) as AudioStreamPlayer3D
		if player == null:
			player = AudioStreamPlayer3D.new()
			player.name = "Ambiente"+row[0]
			player.position = row[1]
			player.max_distance = 24
			add_child(player)
		if player.stream:
			player.play()
		ambient.append(player)
func duck(enabled: bool) -> void:
	for player in ambient:
		player.volume_db = -15 if enabled else 0
func _process(delta: float) -> void:
	if not random_events_enabled or not campaign.ready_for_play or is_instance_valid(campaign.active_duel):
		return
	event_timer -= delta
	if event_timer <= 0:
		event_timer = randf_range(300,600)
		campaign.ui.notify("Evento: computador infectado. Consulta el registro.")
func power_cut(lights: Array) -> void:
	var values: Array = []
	for light in lights:
		if light is Light3D:
			values.append([light,light.light_energy])
	for i in 6:
		for value in values:
			if is_instance_valid(value[0]):
				value[0].light_energy = 0.1 if i%2 == 0 else value[1]
		await get_tree().create_timer(0.25).timeout
	for value in values:
		if is_instance_valid(value[0]):
			value[0].light_energy = value[1]
