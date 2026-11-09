extends Node
## Pilot arrival guard covers any route into floor 3 without editing stair geometry.
var campaign: Node
var last_safe := Vector3(0,2,0)
var pending := false
var cooldown := 0.0
var question: Dictionary = {}
var busy := false
const HEIGHT := 23.967668533
const FLOOR_TOPICS := {3:"Informática",4:"Salud y organización docente",5:"Formación general",6:"Inglés y Ética",7:"Comunicación y Matemáticas",8:"Evaluación integradora de Informática",-1:"Mecánica, Soldadura y Estructuras Metálicas"}
var challenge_floor := 3
var activity_service := preload("res://scripts/education/learning_activity_service.gd").new()
var configured_floors: Dictionary = {3:true}
var published_floors: Dictionary = {}
var verified_access: Dictionary = {}

func refresh_configuration() -> void:
	var auth := get_node("/root/AuthManager")
	if auth.dev_session or not auth.session_valid(): return
	var owner_id: String = auth.user_id
	var response: Dictionary = await auth.client.request_json("/rest/v1/learning_activities?select=subjects(floor)&active=eq.true&access_challenge=eq.true",HTTPClient.METHOD_GET,{},auth.access_token)
	if owner_id!=auth.user_id or not auth.session_valid(): return
	if not response.get("ok",false) or not response.get("data") is Array: return
	for row in response.data:
		if row.get("subjects") is Dictionary:
			var number := int(row.subjects.get("floor",0))
			if FLOOR_TOPICS.has(number): configured_floors[number] = true; published_floors[number]=true
	var grants: Dictionary = await auth.client.request_json("/rest/v1/learning_access?select=floor",HTTPClient.METHOD_GET,{},auth.access_token)
	if owner_id!=auth.user_id or not auth.session_valid(): return
	if grants.get("ok",false) and grants.get("data") is Array:
		for row in grants.data: verified_access[str(int(row.floor))]=true

func locked_floor(position: Vector3) -> int:
	var heights: Array = preload("res://scripts/campaign/campus_content.gd").HEIGHTS
	for number in FLOOR_TOPICS:
		if not configured_floors.has(number): continue
		var index: int = 8 if number == -1 else number-1
		var unlocked: bool = verified_access.get(str(number),false) if published_floors.has(number) else campaign.data.academic_floor_unlocks.get(str(number),false)
		if absf(position.y-float(heights[index])) < 2.4 and not unlocked: return number
	return 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_node("/root/AuthManager").session_changed.connect(_session_changed)
	refresh_configuration.call_deferred()

func _session_changed() -> void:
	if not get_tree().get_meta("education_enabled",false): return
	var auth := get_node("/root/AuthManager")
	if auth.session_valid() and auth.role == "student": return
	campaign.save_game()
	campaign.ui.close_modal()
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file","res://scenes/education/Login.tscn")

func requires_challenge(position: Vector3) -> bool:
	return locked_floor(position) != 0

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
		challenge_floor = locked_floor(pos)
		# Restore the last position outside the arrival band before opening the UI.
		campaign.player.global_position = last_safe
		campaign.player.velocity = Vector3.ZERO
		if not get_tree().paused and not campaign.ui.modal and cooldown <= 0:
			pending = true
			_begin()
	elif not pending and not get_tree().paused:
		last_safe = pos

func _begin() -> void:
	campaign.ui.dialog("DESAFÍO DE ACCESO · PISO "+str(challenge_floor),str(FLOOR_TOPICS[challenge_floor])+"\nResponde correctamente para habilitar el acceso. Puedes volver y reintentar sin perder progreso.",["COMENZAR","VOLVER"],[_fetch,_cancel],true)
	_focus()

func _fetch() -> void:
	if busy: return
	busy = true
	campaign.ui.dialog("DESAFÍO DE ACCESO","Buscando pregunta…",[],[],true)
	activity_service.auth = get_node("/root/AuthManager")
	question = await activity_service.fetch(challenge_floor,"floor_unlock")
	if not question.has("error"):
		busy = false
		campaign.ui.dialog("ACTIVIDAD DE ACCESO · PISO "+str(challenge_floor),"",[],[],true)
		var activity_view := preload("res://scripts/education/learning_activity_view.gd").new()
		activity_view.activity = question
		activity_view.answered.connect(_activity_answer)
		campaign.ui.column.add_child(activity_view)
		var cancel_button := Button.new()
		cancel_button.text = "VOLVER"
		cancel_button.pressed.connect(_cancel)
		campaign.ui.column.add_child(cancel_button)
		_focus()
		return
	if challenge_floor != 3 or published_floors.has(3):
		busy = false
		campaign.ui.dialog("ACTIVIDAD NO DISPONIBLE",str(question.error)+"\nEl docente debe publicar una actividad de acceso para la temática de este piso.",["REINTENTAR","VOLVER"],[_fetch,_cancel],true)
		_focus()
		return
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

func _activity_answer(answer: Variant) -> void:
	if busy: return
	busy = true
	campaign.ui.dialog("VALIDANDO ACTIVIDAD","Validación del servidor…",[],[],true)
	var result := await activity_service.submit(str(question.id),answer,"floor_unlock")
	busy = false
	if result.has("error"):
		campaign.ui.dialog("SIN VALIDACIÓN",result.error,["REINTENTAR","VOLVER"],[_fetch,_cancel],true)
		return
	var correct: bool = result.get("correct",false) == true and result.get("verified",false) == true and int(result.get("floor",0)) == challenge_floor
	if correct:
		verified_access[str(challenge_floor)] = true
		campaign.data.academic_floor_unlocks[str(challenge_floor)] = true
		campaign.data.academic_progress["educational_xp"] = int(campaign.data.academic_progress.get("educational_xp",0))+int(result.get("educational_xp",0))
	preload("res://scripts/education/academic_progress.gd").record(campaign.data,question,result,"floor_unlock")
	campaign.save_game()
	campaign.ui.dialog("ACCESO DESBLOQUEADO" if correct else "SIGUE APRENDIENDO",str(result.get("explanation","")),["CONTINUAR"] if correct else ["OTRA ACTIVIDAD","VOLVER"],[_cancel] if correct else [_fetch,_cancel],true)
	_focus()

func _focus() -> void:
	for child in campaign.ui.column.find_children("*","Button",true,false):
		if child is Button:
			child.grab_focus()
			return
