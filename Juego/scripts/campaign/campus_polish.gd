extends Node
var campaign: Node
@export var show_damage_numbers := true
var healths: Dictionary = {}
var timer := 0.0
var step := 0
var tutorial_timer := 0.0
func _process(delta: float) -> void:
	if not campaign.ready_for_play:
		return
	if not campaign.data.tutorial and not campaign.ui.modal and not campaign.player.busy and not is_instance_valid(campaign.active_duel) and campaign.ui.toast_t <= 0 and campaign.ui.notice_queue.is_empty():
		tutorial_timer -= delta
		if tutorial_timer <= 0:
			var tips := ["WASD · Muévete por el campus","SHIFT · Corre; la estamina se recupera","E · Usa la acción contextual","I · Abre la mochila","J / clic · Ataca; mantén clic para ataque fuerte"]
			campaign.ui.notify(tips[step])
			step += 1
			tutorial_timer = 5
			if step >= tips.size():
				campaign.data.tutorial = true
				campaign.save_game()
	timer -= delta
	if timer > 0:
		return
	timer = 0.1
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var key := enemy.get_instance_id()
		var hp: float = enemy.get("health")
		if healths.has(key) and hp < healths[key] and show_damage_numbers:
			var label := Label3D.new()
			label.text = "−%d" % ceili(float(healths[key])-hp)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size = 40
			label.pixel_size = 0.005
			campaign.add_child(label)
			label.global_position = enemy.global_position+Vector3.UP*2.8
			if campaign.audio:
				var sound := campaign.audio.get_node_or_null("ImpactSound") as AudioStreamPlayer
				if sound and sound.stream:
					sound.play()
			var tween := label.create_tween().set_parallel(true)
			tween.tween_property(label,"position:y",label.position.y+0.7,0.7)
			tween.tween_property(label,"modulate:a",0.0,0.7)
			tween.chain().tween_callback(label.queue_free)
		healths[key] = hp
