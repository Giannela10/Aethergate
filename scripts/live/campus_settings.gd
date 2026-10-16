extends Node
var hub: Node
var data := {"window":"WINDOWED","quality":"ALTO","fps":0,"language":"es","telemetry":false}
var tick := 0.0
var known: Dictionary = {}
var applied_window := ""
var windowed_size := Vector2i(1152,648)
var windowed_position := Vector2i.ZERO
const QUALITIES := {"BAJO":{"near":9.0,"far":22.0,"shadows":false,"effects":false},"MEDIO":{"near":13.0,"far":30.0,"shadows":true,"effects":true},"ALTO":{"near":16.0,"far":35.0,"shadows":true,"effects":true}}
const CHARACTER_QUALITY := {"ALTO":"CHARACTER_HIGH","MEDIO":"CHARACTER_MEDIUM","BAJO":"CHARACTER_LOW"}
const SHADOW_DISTANCE := {"ALTO":40.0,"MEDIO":30.0,"BAJO":20.0}
func _ready() -> void:
	data.telemetry = hub.config.telemetry_enabled
	if hub.campaign.persist and not hub.campaign.has_meta("test_mode"):
		var file := ConfigFile.new()
		if file.load("user://campus_settings.cfg") == OK:
			for key in data: data[key] = file.get_value("settings",key,data[key])
	normalize()
	apply()
func normalize() -> void:
	if not QUALITIES.has(data.quality): data.quality = "ALTO"
	if data.window not in ["WINDOWED","BORDERLESS","FULLSCREEN"]: data.window = "WINDOWED"
	if data.fps not in [0,30,60,120]: data.fps = 0
	if data.language not in ["es","en"]: data.language = "es"
	data.telemetry = data.telemetry == true
func set_option(key: String, value: Variant) -> void:
	if not data.has(key): return
	data[key] = value
	normalize(); apply(); save()
func save() -> void:
	if not hub.campaign.persist or hub.campaign.has_meta("test_mode"): return
	var file := ConfigFile.new()
	for key in data: file.set_value("settings",key,data[key])
	var result := file.save("user://campus_settings.cfg")
	if result != OK: hub.campaign.ui.notify("No se pudieron guardar los ajustes: "+error_string(result))
func apply() -> void:
	Engine.max_fps = int(data.fps)
	# Keep nearby sunlight shadows; the previous 100 m range rendered most floors
	# into shadow maps. Controlled fixture ablation recorded in PERFORMANCE_PROFILE.
	var sun := hub.campaign.get_parent().get_node_or_null("SistemasCompartidos/LuzExterior") as DirectionalLight3D
	if sun != null: sun.directional_shadow_max_distance = SHADOW_DISTANCE[data.quality]
	hub.localization.set_language(data.language)
	hub.config.telemetry_enabled = data.telemetry
	hub.reactive.effects_enabled = QUALITIES[data.quality].effects
	if not hub.reactive.effects_enabled:
		hub.reactive.pulse_remaining = 0
		hub.reactive.restore_lights()
		hub.reactive.refresh()
	if DisplayServer.get_name() != "headless" and hub.campaign.persist and not hub.campaign.has_meta("test_mode") and applied_window != data.window:
		if applied_window in ["","WINDOWED"]:
			windowed_size = DisplayServer.window_get_size()
			windowed_position = DisplayServer.window_get_position()
		match data.window:
			"WINDOWED":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
				DisplayServer.window_set_size(windowed_size)
				DisplayServer.window_set_position(windowed_position)
			"BORDERLESS":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
				var screen := DisplayServer.window_get_current_screen()
				DisplayServer.window_set_size(DisplayServer.screen_get_size(screen))
				DisplayServer.window_set_position(DisplayServer.screen_get_position(screen))
			"FULLSCREEN": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		applied_window = data.window
	refresh_actors()
func refresh_actors() -> void:
	var c = hub.campaign
	var actors: Array = [c.player]
	actors.append_array(c.get_tree().get_nodes_in_group("campus_guard"))
	actors.append_array(c.get_tree().get_nodes_in_group("enemy"))
	actors.append_array(c.get_children())
	for duel in c.get_tree().get_nodes_in_group("boss_duel"): actors.append(duel.actor)
	var quality: Dictionary = QUALITIES[data.quality]
	for actor in actors:
		for property in ["body","model","_visual","visual"]:
			var body = actor.get(property)
			if not body is Node3D or body.get("visual_near_distance") == null: continue
			body.visual_near_distance = quality.near
			body.visual_far_distance = quality.far
			body.cast_near_shadows = quality.shadows
			body.set_meta("character_quality",CHARACTER_QUALITY[data.quality])
			if body.get("imported_visual") != null: body.imported_visual.set_quality(CHARACTER_QUALITY[data.quality])
			var key := str(body.get_instance_id())
			if known.get(key) == data.quality: continue
			known[key] = data.quality
			for mesh in body.find_children("*","MeshInstance3D",true,false):
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if quality.shadows and body.lod_level == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func show_options() -> void:
	var c = hub.campaign
	c.ui.dialog("AJUSTES DE CAMPUS","Los avisos de ataques importantes siguen visibles en todos los niveles.",["Volver"],[c.show_options],true)
	var rows := [
		["window","Ventana",["WINDOWED","BORDERLESS","FULLSCREEN"]],
		["quality","Gráficos",["BAJO","MEDIO","ALTO"]],
		["fps","Límite FPS",[30,60,120,0]],
		["language","Idioma",["es","en"]],
		["telemetry","Telemetría local de desarrollo",[false,true]]]
	for row in rows:
		var label := Label.new(); label.text = row[1]; c.ui.column.add_child(label)
		var option := OptionButton.new()
		for value in row[2]: option.add_item("SIN LÍMITE" if row[0] == "fps" and value == 0 else str(value))
		option.select(maxi(0,row[2].find(data[row[0]])))
		option.item_selected.connect(func(index: int): set_option(row[0],row[2][index]))
		c.ui.column.add_child(option)
	if OS.is_debug_build():
		var report := Button.new(); report.text = "Herramientas de balance y QA"
		report.pressed.connect(c.live.diagnostics.show_report); c.ui.column.add_child(report)
func _process(delta: float) -> void:
	tick += delta
	if tick > 10: tick = 0; refresh_actors()
