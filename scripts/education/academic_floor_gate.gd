extends Node
## Pilot arrival guard covers any route into floor 3 without editing stair geometry.
var campaign: Node
var last_safe := Vector3(0,2,0)
var pending := false
var cooldown := 0.0
var question: Dictionary = {}
var busy := false
var previous_id := ""
const HEIGHT := 23.967668533

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_node("/root/AuthManager").session_changed.connect(_session_changed)

func _session_changed() -> void:
	if not get_tree().get_meta("education_enabled",false): return
	var auth := get_node("/root/AuthManager")
	if auth.session_valid() and auth.role == "student": return
	campaign.save_game()
	campaign.ui.close_modal()
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file","res://scenes/education/Login.tscn")

func requires_challenge(position: Vector3) -> bool:
	return absf(position.y-HEIGHT) < 2.4 and not campaign.data.academic_floor_unlocks.get("3",false)

func _physics_process(delta: float) -> void:
	if not campaign.ready_for_play or not get_tree().get_meta("education_enabled",false): return
	var auth := get_node("/root/AuthManager")
	if not auth.session_valid() or auth.role != "student": return
	# Esc can close the shared campaign modal. Treat it as cancellation so
	# pending never becomes a bypass on a later attempt.
	if pending and not campaign.ui.modal and not busy:
		pending = false
		cooldown = 1.5
	cooldown = maxf(0,cooldown-delta)
	var pos: Vector3 = campaign.player.global_position
	if requires_challenge(pos):
		if pending: return
		# Restore the last position outside the arrival band before opening the UI.
		campaign.player.global_position = last_safe
		campaign.player.velocity = Vector3.ZERO
		if not get_tree().paused and not campaign.ui.modal and cooldown <= 0:
			pending = true
			_begin()
	elif not pending and not get_tree().paused:
		last_safe = pos

func _begin() -> void:
	campaign.ui.dialog("DESAFÍO DE ACCESO · PISO 3","INFORMÁTICA Y TELECOMUNICACIONES\nResponde correctamente para habilitar el acceso.",["COMENZAR","VOLVER"],[_fetch,_cancel],true)
	_focus()

func _fetch() -> void:
	if busy: return
	busy = true
	campaign.ui.dialog("DESAFÍO DE ACCESO","Buscando pregunta…",[],[],true)
	question = await get_node("/root/QuestionService").get_random_question("INF_GENERAL","floor_unlock")
	busy = false
	if question.has("error"):
		campaign.ui.dialog("SIN PREGUNTA",question.error,["REINTENTAR","VOLVER"],[_fetch,_cancel],true)
		_focus()
		return
	campaign.ui.dialog("DESAFÍO DE ACCESO · PISO 3","",[],[],true)
	var view := preload("res://scripts/education/question_view.gd").new()
	view.question = question
	view.selected.connect(_answer)
	campaign.ui.column.add_child(view)
	var back := Button.new()
	back.text = "VOLVER"
	back.custom_minimum_size.y = 44
	back.pressed.connect(_cancel)
	campaign.ui.column.add_child(back)
	_focus()

func _answer(option: String) -> void:
	if busy: return
	busy = true
	campaign.ui.dialog("VALIDANDO RESPUESTA","Un momento…",[],[],true)
	var result: Dictionary = await get_node("/root/QuestionService").submit_answer(str(question.id),option,"floor_unlock")
	busy = false
	if result.has("error"):
		campaign.ui.dialog("SIN VALIDACIÓN",result.error,["INTENTAR OTRA PREGUNTA","VOLVER"],[_fetch,_cancel],true)
		_focus()
		return
	preload("res://scripts/education/academic_progress.gd").record(campaign.data,question,result,"floor_unlock")
	if result.correct: campaign.data.academic_floor_unlocks["3"] = true
	campaign.save_game()
	campaign.ui.dialog("CORRECTO · PISO 3 DESBLOQUEADO" if result.correct else "INCORRECTO",str(result.get("explanation","")),["CONTINUAR"] if result.correct else ["INTENTAR OTRA PREGUNTA","VOLVER"],[_cancel] if result.correct else [_fetch,_cancel],true)
	_focus()

func _cancel() -> void:
	pending = false
	cooldown = 1.5
	campaign.ui.close_modal()

func _focus() -> void:
	for child in campaign.ui.column.find_children("*","Button",true,false):
		if child is Button:
			child.grab_focus()
			return
