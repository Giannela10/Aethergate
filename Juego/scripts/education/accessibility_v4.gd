extends RefCounted
var platform: Node
const ACTIONS := ["move_forward","move_back","move_left","move_right","run","jump","crouch","interact","punch","drop","throw_sport"]
func state() -> Dictionary:
	var data: Dictionary = platform.campaign.data.education_v4
	if not data.get("accessibility") is Dictionary: data["accessibility"] = {}
	var settings: Dictionary = data.accessibility
	var defaults := {"text_scale":1.0,"high_contrast":false,"subtitles":true,"extra_time":false,"assist":false,"music":0.6,"ambient":0.45,"effects":0.8,"bindings":{}}
	for key in defaults:
		if not settings.has(key) or typeof(settings[key]) != typeof(defaults[key]): settings[key] = defaults[key]
	return settings
func apply() -> void:
	var settings := state()
	platform.campaign.player.learning_assist = settings.assist
	for row in [["Music","music"],["Ambient","ambient"],["Effects","effects"]]:
		var index := AudioServer.get_bus_index(row[0])
		if index<0: AudioServer.add_bus(); index=AudioServer.bus_count-1; AudioServer.set_bus_name(index,row[0])
		AudioServer.set_bus_volume_db(index,linear_to_db(clampf(float(settings[row[1]]),0.0,1.0)))
		AudioServer.set_bus_mute(index,float(settings[row[1]])<=0)
	for action in settings.bindings:
		if action not in ACTIONS or not InputMap.has_action(action): continue
		var code := OS.find_keycode_from_string(str(settings.bindings[action]))
		if code == KEY_NONE or code == KEY_ESCAPE: continue
		InputMap.action_erase_events(action)
		var event := InputEventKey.new(); event.physical_keycode = code
		InputMap.action_add_event(action,event)
	apply_text(platform.campaign.ui.panel)
func apply_text(node: Node) -> void:
	if not is_instance_valid(node): return
	var settings := state()
	if node is Control:
		if not node.has_meta("v4_font_size"): node.set_meta("v4_font_size",node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size",int(float(node.get_meta("v4_font_size"))*clampf(float(settings.text_scale),0.85,1.6)))
		if settings.high_contrast and (node is Label or node is Button): node.add_theme_color_override("font_color",Color.WHITE)
		elif node is Label or node is Button: node.remove_theme_color_override("font_color")
	for child in node.get_children(): apply_text(child)
func show_options() -> void:
	var c: Node = platform.campaign
	var settings := state()
	c.ui.dialog("ACCESIBILIDAD Y AUDIO","Las ayudas de combate no alteran las notas ni validan respuestas. Esc conserva siempre la pausa. Los indicadores de ataques permanecen visibles.",["VOLVER"],[c.phone.open],true)
	for row in [["high_contrast","Texto de alto contraste"],["subtitles","Subtítulos narrativos"],["extra_time","Tiempo adicional en práctica física"],["assist","Modo aprendizaje: combate sin muerte"]]:
		var button := CheckButton.new(); button.text = row[1]; button.button_pressed = settings[row[0]]
		button.toggled.connect(func(value): settings[row[0]]=value; apply(); c.save_game())
		c.ui.column.add_child(button)
	for row in [["text_scale","Tamaño de texto",0.85,1.6,0.05],["music","Música",0.0,1.0,0.05],["ambient","Ambiente",0.0,1.0,0.05],["effects","Efectos",0.0,1.0,0.05]]:
		var label := Label.new(); label.text=row[1]; c.ui.column.add_child(label)
		var slider := HSlider.new(); slider.min_value=row[2]; slider.max_value=row[3]; slider.step=row[4]; slider.value=float(settings[row[0]])
		slider.value_changed.connect(func(value): settings[row[0]]=value; apply(); c.save_game())
		c.ui.column.add_child(slider)
	for action in ACTIONS:
		var input := LineEdit.new(); input.placeholder_text=action+": nombre de tecla, por ejemplo W o Space"; input.text=str(settings.bindings.get(action,""))
		input.text_submitted.connect(func(value):
			var code := OS.find_keycode_from_string(value)
			if code!=KEY_NONE and code!=KEY_ESCAPE: settings.bindings[action]=value; apply(); c.save_game())
		c.ui.column.add_child(input)
	apply_text(c.ui.panel)
