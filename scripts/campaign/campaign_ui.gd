extends CanvasLayer
var campaign: Node
var panel: PanelContainer
var column: VBoxContainer
var objective: Label
var context: Label
var toast: Label
var toast_t := 0.0
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

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	objective = Label.new()
	objective.position = Vector2(20,310)
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
	panel = PanelContainer.new()
	root.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.07,0.11,0.98)
	style.set_content_margin_all(18)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel",style)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
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

func dialog(title: String, text: String, choices: Array, callbacks: Array, pause_world: bool = false) -> void:
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
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size",25)
	column.add_child(heading)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 520
	column.add_child(body)
	for i in choices.size():
		var button := Button.new()
		button.text = str(choices[i])
		button.custom_minimum_size.y = 34
		button.pressed.connect(callbacks[i])
		column.add_child(button)
	panel.show()
	call_deferred("_fit")

func _fit() -> void:
	if not is_inside_tree():
		return
	var size := get_viewport().get_visible_rect().size
	var scale_value := minf(1,size.x/650.0)
	panel.scale = Vector2.ONE*scale_value
	panel.size = Vector2(600,minf(500,(size.y-40)/scale_value))
	panel.position = (size-panel.size*scale_value)*0.5

func close_modal() -> void:
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

func notify(text: String, duration: float = 4.0) -> void:
	toast.text = text
	toast_t = duration

func _process(delta: float) -> void:
	toast_t = maxf(0,toast_t-delta)
	toast.visible = toast_t > 0
	var duel = campaign.active_duel
	boss_box.visible = is_instance_valid(duel) and duel.state == duel.DuelState.COMBAT
	if boss_box.visible:
		var hp: float = duel.actor.get("health")
		boss_title.text = duel.boss_name
		boss_bar.max_value = duel.max_health
		boss_bar.value = hp
		var phase_value = duel.actor.get("phase")
		boss_value.text = "%d / %d%s" % [ceili(hp),ceili(duel.max_health)," · Fase %s" % phase_value if phase_value != null else ""]
