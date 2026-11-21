extends CanvasLayer
const MenuStyle = preload("res://scripts/campaign/campus_menu_style.gd")
var campaign: Node
var panel: PanelContainer
var column: VBoxContainer
var objective: Label
var context: Label
var toast: Label
var toast_t := 0.0
enum NoticePriority { CRITICAL, MISSION, REWARD, INFO }
var notice_queue: Array[Dictionary] = []
var toast_priority := NoticePriority.INFO
var boss_box: VBoxContainer
var boss_title: Label
var boss_bar: ProgressBar
var boss_value: Label
var intro: ColorRect
var intro_name: Label
var modal := false
var paused_before := false
var mouse_before := 0
var page := ""
var dialogue_camera: Node
var campus_hud: Control
var fullscreen_menu: Control
var world_rendering_disabled := false
var fullscreen_cancel: Callable
var teacher_panel := false
var default_panel_style: StyleBoxFlat

func begin_character_dialogue(actor: Node3D, boss: bool = false) -> void:
	if dialogue_camera == null:
		dialogue_camera = preload("res://scripts/campaign/dialogue_camera_controller.gd").new()
		dialogue_camera.name = "DialogueCameraController"
		add_child(dialogue_camera)
	dialogue_camera.begin(campaign.player,actor,3 if boss else 2)

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_fit)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	objective = Label.new()
	objective.position = Vector2(20,150)
	objective.add_theme_font_size_override("font_size",15)
	objective.add_theme_color_override("font_outline_color",Color.BLACK)
	objective.add_theme_constant_override("outline_size",4)
	root.add_child(objective)
	context = Label.new()
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(context)
	context.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	context.offset_left = -400
	context.offset_right = 400
	context.offset_top = -183
	context.offset_bottom = -150
	toast = Label.new()
	toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color",Color("a8edca"))
	root.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.offset_left = -420
	toast.offset_right = 420
	toast.offset_top = 110
	toast.offset_bottom = 155
	boss_box = VBoxContainer.new()
	root.add_child(boss_box)
	boss_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	boss_box.offset_left = -480
	boss_box.offset_right = -24
	boss_box.offset_top = 22
	boss_box.offset_bottom = 105
	boss_title = Label.new()
	boss_box.add_child(boss_title)
	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size.y = 18
	boss_bar.show_percentage = false
	boss_box.add_child(boss_bar)
	boss_value = Label.new()
	boss_box.add_child(boss_value)
	boss_box.hide()
	campus_hud = preload("res://scripts/campaign/campus_hud.gd").new()
	campus_hud.campaign = campaign
	campus_hud.ui = self
	root.add_child(campus_hud)
	campus_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	objective.hide()
	context.hide()
	panel = PanelContainer.new()
	root.add_child(panel)
	var style := MenuStyle.surface(20)
	default_panel_style = style
	panel.add_theme_stylebox_override("panel",style)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
	column.minimum_size_changed.connect(func():
		if panel.visible:
			_fit.call_deferred())
	scroll.add_child(column)
	panel.hide()
	intro = ColorRect.new()
	intro.color = Color(0,0,0,0.78)
	intro.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(intro)
	intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_name = Label.new()
	intro_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_name.add_theme_font_size_override("font_size",36)
	intro.add_child(intro_name)
	intro_name.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro.hide()

func open_fullscreen(on_cancel: Callable = Callable()) -> Control:
	if not modal:
		paused_before = get_tree().paused
		mouse_before = Input.mouse_mode
	_clear_fullscreen()
	modal = true
	campaign.player.busy = true
	campaign.player.velocity = Vector3.ZERO
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.hide()
	world_rendering_disabled = get_viewport().disable_3d
	get_viewport().disable_3d = true
	fullscreen_cancel = on_cancel if on_cancel.is_valid() else close_modal
	fullscreen_menu = Control.new()
	panel.get_parent().add_child(fullscreen_menu)
	fullscreen_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return fullscreen_menu

func _input(event: InputEvent) -> void:
	if is_instance_valid(fullscreen_menu) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fullscreen_cancel.call()

func _clear_fullscreen() -> void:
	if not is_instance_valid(fullscreen_menu):
		return
	fullscreen_menu.hide()
	fullscreen_menu.queue_free()
	fullscreen_menu = null
	fullscreen_cancel = Callable()
	get_viewport().disable_3d = world_rendering_disabled

func dialog(title: String, text: String, choices: Array, callbacks: Array, pause_world: bool = false) -> void:
	_clear_fullscreen()
	teacher_panel = false
	panel.add_theme_stylebox_override("panel", default_panel_style)
	if campaign.live != null and campaign.live.event_active():
		campaign.live.events.finish()
	if campaign.live != null and campaign.live.qol != null:
		campaign.live.qol.record_dialogue(title,text)
	if is_instance_valid(campaign.phone) and is_instance_valid(campaign.phone.view):
		campaign.phone.view.restore()
	if not modal:
		paused_before = get_tree().paused
		mouse_before = Input.mouse_mode
	modal = true
	campaign.player.busy = true
	campaign.player.velocity = Vector3.ZERO
	if pause_world:
		get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for child in column.get_children():
		# Un botón puede estar emitiendo pressed al cambiar de página.
		column.remove_child(child)
		child.queue_free()
	var scroll := column.get_parent() as ScrollContainer
	scroll.scroll_vertical = 0
	scroll.follow_focus = false
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size",25)
	heading.add_theme_color_override("font_color", MenuStyle.GOLD)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(heading)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", MenuStyle.MUTED)
	body.visible = not text.is_empty()
	column.add_child(body)
	for i in choices.size():
		var button := Button.new()
		button.text = str(choices[i])
		button.custom_minimum_size.y = 42
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		MenuStyle.tone(button, i == 0)
		button.pressed.connect(callbacks[i])
		column.add_child(button)
	panel.show()
	var platform := campaign.get_node_or_null("DuocGames4")
	if platform != null: platform.accessibility.apply_text.call_deferred(column)
	call_deferred("_fit")

func teacher_dialog(title: String, text: String, choices: Array, callbacks: Array, pause_world: bool = true, teacher: String = "") -> void:
	dialog(title, text, choices, callbacks, pause_world)
	teacher_panel = true
	var style := MenuStyle.surface(20)
	style.border_color = MenuStyle.GOLD
	panel.add_theme_stylebox_override("panel", style)
	if not teacher.is_empty() and teacher != title:
		var byline := Label.new()
		byline.text = teacher
		byline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		byline.add_theme_color_override("font_color", MenuStyle.PALE)
		column.add_child(byline)
		column.move_child(byline, 1)
	var scroll := column.get_parent() as ScrollContainer
	scroll.follow_focus = true

func _fit() -> void:
	if not is_inside_tree():
		return
	var size := get_viewport().get_visible_rect().size
	var width := 710.0
	var scale_value := minf(1, size.x / (width + 50.0))
	panel.scale = Vector2.ONE*scale_value
	var height := clampf(column.get_combined_minimum_size().y + 40, 160, 560)
	panel.size = Vector2(width, minf(height, (size.y-40)/scale_value))
	panel.position = (size-panel.size*scale_value)*0.5

func close_modal() -> void:
	_clear_fullscreen()
	if is_instance_valid(campaign.player) and campaign.player.body.has_method("show_phone"):
		campaign.player.body.show_phone(false)
		campaign.player.set_meta("important_scene",false)
		campaign.player.body.set_expression("NEUTRAL")
	if is_instance_valid(dialogue_camera):
		dialogue_camera.finish()
	if is_instance_valid(campaign.phone) and is_instance_valid(campaign.phone.view):
		campaign.phone.view.restore()
	if not modal:
		return
	modal = false
	page = ""
	panel.hide()
	get_tree().paused = paused_before
	if is_instance_valid(campaign.player):
		campaign.player.busy = false
		campaign.player.punch_cd = maxf(campaign.player.punch_cd,0.2)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if campaign.player.dead else mouse_before as Input.MouseMode

func show_intro(title: String, subtitle: String, duration: float) -> void:
	intro_name.text = title+"\n"+subtitle
	intro.modulate.a = 0
	intro.show()
	var tween := create_tween()
	tween.tween_property(intro,"modulate:a",1.0,0.25)
	tween.tween_interval(maxf(0.1,duration-0.5))
	tween.tween_property(intro,"modulate:a",0.0,0.25)
	await tween.finished
	intro.hide()

func notify(text: String, duration: float = 4.0, priority: int = -1) -> void:
	if text.is_empty(): return
	if priority < 0:
		var upper := text.to_upper()
		priority = NoticePriority.INFO
		if upper.contains("MISIÓN") or upper.contains("OBJETIVO"):
			priority = NoticePriority.MISSION
		elif upper.contains("RECOMPENSA") or upper.contains("DESBLOQUEADO") or upper.contains("BOSS DERROTADO"):
			priority = NoticePriority.REWARD
	priority = clampi(priority,NoticePriority.CRITICAL,NoticePriority.INFO)
	duration = clampf(duration,1.0,12.0)
	if toast_t > 0 and toast.text == text: return
	for row in notice_queue:
		if row.text == text:
			row.priority = mini(row.priority,priority)
			notice_queue.sort_custom(func(a,b): return a.priority < b.priority)
			return
	if toast_t <= 0:
		toast.text = text; toast_t = duration; toast_priority = priority
		return
	if priority == NoticePriority.CRITICAL and toast_priority != NoticePriority.CRITICAL:
		notice_queue.append({"text":toast.text,"duration":toast_t,"priority":toast_priority})
		toast.text = text; toast_t = duration; toast_priority = priority
	else:
		notice_queue.append({"text":text,"duration":duration,"priority":priority})
	notice_queue.sort_custom(func(a,b): return a.priority < b.priority)
	while notice_queue.size() > 16: notice_queue.pop_back()

func _process(delta: float) -> void:
	var notice_hidden := modal or intro.visible
	if not notice_hidden:
		toast_t = maxf(0,toast_t-delta)
		if toast_t <= 0 and not notice_queue.is_empty():
			var row: Dictionary = notice_queue.pop_front()
			toast.text = row.text; toast_t = row.duration; toast_priority = row.priority
	toast.visible = toast_t > 0 and not notice_hidden
	var duel = campaign.active_duel
	boss_box.visible = is_instance_valid(duel) and duel.state == duel.DuelState.COMBAT
	if boss_box.visible:
		var hp: float = duel.actor.get("health")
		boss_title.text = ("SIMULACIÓN · " if duel.is_educational_simulation() else "")+duel.boss_name
		boss_bar.max_value = duel.max_health
		boss_bar.value = hp
		var phase_value = duel.actor.get("phase")
		boss_value.text = "%d / %d%s" % [ceili(hp),ceili(duel.max_health)," · Fase %s" % phase_value if phase_value != null else ""]
