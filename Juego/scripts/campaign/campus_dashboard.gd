extends Control

const Look = preload("res://scripts/campaign/campus_menu_style.gd")
const Stage = preload("res://scripts/campaign/campus_avatar_stage.gd")
const Profile = preload("res://scripts/juego/character_appearance.gd")
const Quest = preload("res://scripts/campaign/quest.gd")
const MAIN_QUESTS := ["inicio","biblioteca","academico3","academico4","academico5","seguridad6","acceso7","direccion","postgame","nexo_final"]
const NEWS := [
	["Primer día", "Encuentra Punto Estudiantil y completa las primeras misiones de la campaña.", "◎"],
	["Explora el campus", "Encuentra los desafíos académicos de cada piso y continúa tu aventura.", "↗"],
	["Tarjetas del campus", "Busca los coleccionables repartidos por las salas y espacios comunes.", "◇"]
]

var canvas: Control
var status: Label
var news_title: Label
var news_body: Label
var news_icon: Label
var news_tabs: Array[Button] = []
var actions := {}
var payload := {}
var student_name := "Estudiante"
var extra_actions: Array = []

func setup(name_value: String, data: Dictionary, callbacks: Dictionary, extra: Array = []) -> void:
	student_name = name_value if not name_value.is_empty() else "Estudiante"
	payload = data
	actions = callbacks
	extra_actions = extra
	if is_node_ready():
		_refresh_progress()

func _ready() -> void:
	canvas = Look.screen(self)
	Look.stripe(canvas, Rect2(29, 33, 5, 102))
	Look.label(canvas, "DuocUC", Rect2(45, 27, 276, 64), 52)
	Look.label(canvas, "Aventura", Rect2(48, 89, 266, 37), 31)
	Look.label(canvas, "Universitaria", Rect2(48, 125, 280, 36), 28)

	var model := Stage.new()
	model.profile = _saved_appearance()
	Look.place(canvas, model, Rect2(303, 131, 497, 535))
	var slot := 0
	var play_button: Button
	for entry in [["play","▶    Jugar"],["missions","◎    Misiones"],["inventory","▣    Inventario"],["appearance","◇    Personalización"],["settings","⚙    Ajustes"],["credits","ⓘ    Créditos"],["exit","↪    Salir"]]:
		var action: Callable = actions.get(entry[0], Callable())
		if not action.is_valid():
			continue
		var button := Look.button(canvas, entry[1], Rect2(32, 175 + slot * 56, 272 - slot * 3, 48), action, slot == 0, 21)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if slot == 0:
			play_button = button
		slot += 1
	for i in extra_actions.size():
		var extra: Array = extra_actions[i]
		Look.button(canvas, str(extra[0]), Rect2(33 + i * 165, 578, 158, 32), extra[1], false, 13)

	Look.panel(canvas, Rect2(826, 23, 305, 82))
	Look.panel(canvas, Rect2(834, 28, 65, 69), Look.GOLD)
	var portrait := Stage.new()
	portrait.portrait = true
	portrait.profile = model.profile
	Look.place(canvas, portrait, Rect2(834, 29, 65, 65))
	Look.label(canvas, "", Rect2(910, 31, 143, 27), 20).name = "Student"
	Look.label(canvas, "", Rect2(1052, 34, 71, 23), 14, Look.GOLD).name = "Level"
	Look.panel(canvas, Rect2(911, 66, 202, 13))
	var xp := ColorRect.new()
	xp.name = "XPFill"
	xp.color = Look.GOLD
	xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Look.place(canvas, xp, Rect2(913, 68, 0, 9))
	Look.label(canvas, "", Rect2(912, 81, 202, 17), 11, Look.MUTED).name = "XPText"

	Look.panel(canvas, Rect2(826, 140, 305, 204), Look.GOLD)
	Look.label(canvas, "Novedades", Rect2(845, 150, 252, 35), 22)
	Look.stripe(canvas, Rect2(844, 191, 269, 1), Look.GOLD)
	Look.panel(canvas, Rect2(847, 205, 72, 87))
	news_icon = Look.label(canvas, "", Rect2(850, 218, 66, 59), 31, Look.GOLD)
	news_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	news_title = Look.label(canvas, "", Rect2(931, 203, 181, 25), 17)
	news_body = Look.label(canvas, "", Rect2(931, 230, 180, 71), 13, Look.MUTED)
	news_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	news_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	for i in NEWS.size():
		var tab := Look.button(canvas, "●", Rect2(943 + i * 27, 305, 25, 28), _news.bind(i), false, 11)
		tab.tooltip_text = NEWS[i][0]
		news_tabs.append(tab)
	_news(0)

	Look.panel(canvas, Rect2(814, 399, 317, 179))
	Look.label(canvas, "Tu progreso", Rect2(831, 408, 279, 28), 22)
	var titles := ["Misiones principales", "Tarjetas coleccionadas", "Créditos"]
	for i in titles.size():
		var y := 446 + i * 40
		Look.stripe(canvas, Rect2(831, y-3, 280, 1), Color("#2e526e"))
		Look.label(canvas, titles[i], Rect2(833, y, 209, 32), 15)
		var metric := Look.label(canvas, "", Rect2(1031, y, 80, 32), 17, Look.GOLD)
		metric.name = "Metric%d" % i
		metric.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	status = Look.label(canvas, "", Rect2(810, 584, 320, 52), 13, Look.MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	model.name = "StudentModel"
	portrait.name = "StudentPortrait"
	_refresh_progress()
	if play_button != null:
		play_button.grab_focus()

func set_progress(data: Dictionary) -> void:
	payload = data
	if is_instance_valid(canvas):
		_refresh_progress()

func _refresh_progress() -> void:
	var appearance := _saved_appearance()
	canvas.get_node("StudentModel").set_profile(appearance)
	canvas.get_node("StudentPortrait").set_profile(appearance)
	var xp: int = maxi(0, int(payload.get("xp", 0)))
	canvas.get_node("Student").text = student_name
	canvas.get_node("Level").text = "Nivel %d" % (1 + floori(float(xp) / 150.0))
	canvas.get_node("XPText").text = "%d / 150 XP" % (xp % 150)
	canvas.get_node("XPFill").size.x = 198.0 * float(xp % 150) / 150.0
	var count := 0
	var quest_state: Dictionary = payload.get("quests", {})
	for key in MAIN_QUESTS:
		var state: Variant = quest_state.get(key, {})
		if state is Dictionary and int(state.get("state", 0)) == Quest.State.COMPLETED:
			count += 1
	canvas.get_node("Metric0").text = "%d / %d" % [count, MAIN_QUESTS.size()]
	var cards: Dictionary = payload.get("cards", {})
	canvas.get_node("Metric1").text = "%d / 20" % cards.size()
	canvas.get_node("Metric2").text = str(payload.get("credits", 0))

func _saved_appearance() -> Dictionary:
	var saved: Variant = payload.get("appearance")
	var equipped: Dictionary = Profile.CAMPUS_REFERENCE.duplicate()
	if saved is Dictionary:
		equipped.merge(saved, true)
	var cosmetics: Variant = payload.get("cosmetics")
	var unlocked: Dictionary = cosmetics.duplicate() if cosmetics is Dictionary else {}
	var bosses: Variant = payload.get("bosses")
	if bosses is Dictionary:
		Profile.unlock_from_progress(bosses, unlocked)
	if payload.get("campaign_completed", false) == true:
		unlocked["nexo_jacket"] = true
	return Profile.normalize(equipped, unlocked)

func _news(index: int) -> void:
	news_title.text = NEWS[index][0]
	news_body.text = NEWS[index][1]
	news_icon.text = NEWS[index][2]
	for i in news_tabs.size():
		Look.tone(news_tabs[i], i == index)
