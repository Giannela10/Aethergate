extends VBoxContainer
## Identical question component in student challenges and teacher previews.
signal selected(option: String)
var question: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation",12)
	var text := Label.new()
	text.text = str(question.get("question_text",""))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size",20)
	text.add_theme_color_override("font_color",Color.WHITE)
	add_child(text)
	var first: Button
	for option in ["A","B","C","D"]:
		var button := Button.new()
		button.text = "[%s] %s" % [option,question.get("option_"+option.to_lower(),"")]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size",18)
		button.add_theme_color_override("font_color",Color.WHITE)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("15324d")
		normal.set_content_margin_all(12)
		normal.set_corner_radius_all(8)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("24567c")
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color(0,0,0,0)
		focus.border_color = Color("ffd344")
		focus.set_border_width_all(2)
		focus.set_corner_radius_all(8)
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_stylebox_override("hover",hover)
		button.add_theme_stylebox_override("pressed",hover)
		button.add_theme_stylebox_override("focus",focus)
		button.pressed.connect(func(): selected.emit(option))
		add_child(button)
		if first == null: first = button
	if first: first.grab_focus()
