extends RefCounted
var campaign: Node
var floor_number := 3
var mentor_id := ""
var mentor_name := ""
var service := preload("res://scripts/education/learning_activity_service.gd").new()
var activity: Dictionary
var practice_mode=false
var local_service=preload("res://scripts/education/local_practice_service.gd").new()
var page_generation=0
func _dialog(title: String, text: String, choices: Array, callbacks: Array) -> void:
	campaign.ui.teacher_dialog(title, text, choices, callbacks, true, mentor_name)

func open() -> void:
	_dialog("ACTIVIDAD DEL DOCENTE","Elige la fuente. La práctica local es material original no validado por Duoc UC y no otorga desbloqueos oficiales.",["PRÁCTICA LOCAL","BANCO PUBLICADO","PREGUNTAS DEL BOSS","VOLVER"],[open_local,open_published,open_assigned_questions,campaign.ui.close_modal])
func open_assigned_questions() -> void:
	practice_mode = false
	_dialog("PREGUNTAS DEL BOSS","Buscando preguntas asignadas a " + mentor_name + "...",[],[])
	var question_service: Node = campaign.get_node("/root/QuestionService")
	activity = await question_service.get_boss_question(mentor_id)
	if not is_instance_valid(campaign): return
	if activity.has("error"):
		_dialog("SIN PREGUNTAS ASIGNADAS",str(activity.error),["VOLVER A ACTIVIDADES","CERRAR"],[open,campaign.ui.close_modal])
		return
	_dialog("PREGUNTA DE " + mentor_name.to_upper(),"Responde para registrar tu resultado.",[],[])
	var view := preload("res://scripts/education/question_view.gd").new()
	view.question = activity
	view.selected.connect(_answer_assigned_question)
	campaign.ui.column.add_child(view)

func _answer_assigned_question(option: String) -> void:
	_dialog("VALIDANDO RESPUESTA","Un momento...",[],[])
	var question_service: Node = campaign.get_node("/root/QuestionService")
	var result: Dictionary = await question_service.submit_answer(str(activity.id),option,"teacher_challenge")
	if not is_instance_valid(campaign): return
	if result.has("error"):
		_dialog("SIN VALIDACION",str(result.error),["OTRA PREGUNTA","CERRAR"],[open_assigned_questions,campaign.ui.close_modal])
		return
	preload("res://scripts/education/academic_progress.gd").record(campaign.data,activity,result,"teacher_challenge")
	campaign.save_game()
	_dialog("CORRECTO" if result.get("correct",false) else "SIGUE APRENDIENDO",str(result.get("explanation","")),["OTRA PREGUNTA","CONTINUAR"],[open_assigned_questions,campaign.ui.close_modal])

func open_local() -> void:
	practice_mode=true
	_open_activity()
func open_published() -> void:
	practice_mode=false
	_open_activity()
func _open_activity() -> void:
	service.auth = campaign.get_node("/root/AuthManager")
	if not practice_mode:
		_dialog("ACTIVIDAD DEL DOCENTE","Consultando banco publicado…",[],[])
	page_generation+=1
	var generation=page_generation
	activity = local_service.fetch(floor_number,"teacher_challenge",mentor_id) if practice_mode else await service.fetch(floor_number,"teacher_challenge",mentor_id)
	if generation!=page_generation: return
	if not is_instance_valid(campaign): return
	if activity.has("error"):
		_dialog("ACTIVIDAD NO DISPONIBLE",activity.error,["PRÁCTICA LOCAL","VOLVER"],[open_local,campaign.ui.close_modal])
		return
	_dialog("APRENDER Y PRACTICAR","PRÁCTICA LOCAL · sin validación institucional ni recompensas oficiales." if practice_mode else "BANCO PUBLICADO · El resultado educativo se valida por separado de la simulación de combate.",[],[])
	var view := preload("res://scripts/education/learning_activity_view.gd").new()
	view.activity = activity
	view.teacher_style = true
	view.answered.connect(answer)
	campaign.ui.column.add_child(view)

func answer(value: Variant) -> void:
	_dialog("VALIDANDO","Un momento…",[],[])
	var result: Dictionary = local_service.submit(str(activity.id),value,"teacher_challenge") if practice_mode else await service.submit(str(activity.id),value,"teacher_challenge")
	if not is_instance_valid(campaign): return
	if result.has("error"):
		_dialog("SIN VALIDACIÓN",result.error,["VOLVER"],[campaign.ui.close_modal])
		return
	preload("res://scripts/education/academic_progress.gd").record(campaign.data,activity,result,"teacher_challenge")
	if result.get("verified",false) and (result.get("correct",false)==true or result.get("reflection",false)) and not mentor_id.is_empty():
		if not campaign.data.education_v4.get("mentor_passes") is Dictionary: campaign.data.education_v4["mentor_passes"]={}
		campaign.data.education_v4.mentor_passes[mentor_id]=true
	campaign.save_game()
	_dialog("REFLEXIÓN" if result.get("reflection",false) else ("CORRECTO" if result.get("correct",false) else "SIGUE APRENDIENDO"),str(result.get("explanation","")),["OTRA ACTIVIDAD","CONTINUAR"],[open_local if practice_mode else open_published,campaign.ui.close_modal])
