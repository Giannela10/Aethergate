extends Node
var hub: Node
var screens: Array[RefCounted] = []
var boards: Array[Dictionary] = []
var pulse_remaining := 0.0
var light_values: Array[Dictionary] = []
var tick := 0.0
var room_tick := 0.0
var effects_enabled := true
var pulse_sound: AudioStreamPlayer
var area_sound: AudioStreamPlayer
var face_values: Array[Dictionary] = []
func _ready() -> void:
	pulse_sound = AudioStreamPlayer.new()
	pulse_sound.volume_db = -18
	var sound := AudioStreamWAV.new()
	sound.mix_rate = 22050
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	var samples := PackedByteArray()
	samples.resize(5512*2)
	for index in 5512:
		var t := float(index)/22050.0
		var envelope := sin(PI*float(index)/5512.0)
		samples.encode_s16(index*2,int(sin(TAU*330*t)*envelope*3500))
	sound.data = samples
	pulse_sound.stream = sound
	add_child(pulse_sound)
	area_sound = AudioStreamPlayer.new()
	area_sound.stream = sound
	area_sound.pitch_scale = 1.6
	area_sound.volume_db = -23
	add_child(area_sound)
	for pc in get_tree().get_nodes_in_group("computer"):
		screens.append(preload("res://scripts/live/campus_display.gd").new(pc))
		if pc.get("screen_light") is Light3D:
			light_values.append({"light":pc.screen_light,"energy":pc.screen_light.light_energy})
	for point in get_tree().get_nodes_in_group("campus_checkpoint"):
		var label := Label3D.new()
		label.font_size = 22; label.pixel_size = 0.003
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0,1.6,0)
		point.add_child(label)
		boards.append({"anchor":point,"label":label})
	refresh()
func pulse(duration: float) -> void:
	if hub.campus_state.phase == 4 or not effects_enabled or hub.director.locked(): return
	pulse_remaining = clampf(duration,0,4)
	pulse_sound.play()
	for record in light_values:
		if is_instance_valid(record.light) and record.light.global_position.distance_to(hub.campaign.player.global_position) < 20:
			record.light.light_energy = float(record.energy)*0.55
	for actor in hub.campaign.get_children():
		if actor is Node3D and actor.get("model") != null and actor.global_position.distance_to(hub.campaign.player.global_position) < 16:
			if not face_values.any(func(record): return record.body == actor.model): face_values.append({"body":actor.model,"expression":actor.model.expression})
			actor.model.set_expression("SURPRISED")
	refresh()
func restore_lights() -> void:
	for record in light_values:
		if is_instance_valid(record.light): record.light.light_energy = record.energy
	for record in face_values:
		if is_instance_valid(record.body) and record.body.expression == "SURPRISED": record.body.set_expression(record.expression)
	face_values.clear()

func discovery_sound() -> void:
	if effects_enabled: area_sound.play()
func refresh() -> void:
	if hub.campus_state.phase == 4:
		pulse_remaining = 0
		restore_lights()
	for screen in screens:
		var state := 0 if hub.campus_state.phase == 0 else 1
		if hub.campus_state.phase == 4: state = 4
		elif pulse_remaining > 0 and hub.campaign.phone._floor_for(screen.pc) == hub.floor_id(): state = 2
		screen.show_state(state)
	for record in boards:
		var same: bool = hub.campaign.phone._floor_for(record.anchor) == hub.floor_id()
		record.label.visible = same and record.anchor.global_position.distance_to(hub.campaign.player.global_position) < 8
		record.label.text = "CAMPUS · "+hub.campaign.academics.clock_text()+"\n"+hub.campus_state.ambient_line()
	for key in hub.campaign.academics.points:
		var point = hub.campaign.academics.points[key]
		var value := "EMPTY"
		var now: Dictionary = hub.campaign.academics.current_time()
		for course in hub.campaign.academics.CLASSES:
			if course.site == key and int(now.minute) >= int(course.minute) and int(now.minute) < int(course.minute+course.duration): value = "CLASS"
		if hub.event_active() and hub.events.current.anchor == "academic":
			if hub.events.active.global_position.distance_to(point.global_position) < 4:
				value = "EXAM" if hub.events.current.event_id == "evaluacion" else "GROUP_WORK"
		if hub.event_active() and hub.events.current.event_id == "fallo_breve" and hub.campaign.phone._floor_for(point) == hub.floor_id():
			value = "TECH_PROBLEM"
		hub.state.classrooms[key] = value
		point.set_meta("classroom_state",value)
func _process(delta: float) -> void:
	if pulse_remaining > 0:
		pulse_remaining = maxf(0,pulse_remaining-delta)
		if hub.director.locked() or pulse_remaining == 0:
			pulse_remaining = 0
			restore_lights()
			refresh()
	tick += delta
	if tick >= 5:
		tick = 0
		refresh()
func _exit_tree() -> void:
	restore_lights()
	for record in boards:
		if is_instance_valid(record.label): record.label.queue_free()
