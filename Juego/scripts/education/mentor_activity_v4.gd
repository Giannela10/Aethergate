extends RefCounted
var campaign: Node
var floor_number := 3
var mentor_id := ""
var service := preload("res://scripts/education/learning_activity_service.gd").new()
var activity: Dictionary
var practice_mode=false
var local_service=preload("res://scripts/education/local_practice_service.gd").new()
var page_generation=0
func open() -> void:
	campaign.ui.dialog("ACTIVIDAD DEL DOCENTE","Elige la fuente. La práctica local es material original no validado por Duoc UC y no otorga desbloqueos oficiales.",["PRÁCTICA LOCAL","BANCO PUBLICADO","VOLVER"],[open_local,open_published,campaign.ui.close_modal],true)
func open_local() -> void:
	practice_mode=true
	_open_activity()
func open_published() -> void:
	practice_mode=false
	_open_activity()
func _open_activity() -> void:
	service.auth = campaign.get_node("/root/AuthManager")
	campaign.ui.dialog("ACTIVIDAD DEL DOCENTE","Consultando banco publicado…",[],[],true)
	page_generation+=1
	var generation=page_generation
	activity = local_service.fetch(floor_number,"teacher_challenge",mentor_id) if practice_mode else await service.fetch(floor_number,"teacher_challenge",mentor_id)
	if generation!=page_generation: return
	if not is_instance_valid(campaign): return
	if activity.has("error"):
		campaign.ui.dialog("ACTIVIDAD NO DISPONIBLE",activity.error+" Un fallo de recuperación no demuestra un banco vacío.",["PRÁCTICA LOCAL","VOLVER"],[open_local,campaign.ui.close_modal],true)
		return
	campaign.ui.dialog("APRENDER Y PRACTICAR","PRÁCTICA LOCAL · sin validación institucional ni recompensas oficiales." if practice_mode else "El resultado educativo se valida por separado de la simulación de combate.",[],[],true)
	var view := preload("res://scripts/education/learning_activity_view.gd").new()
	view.activity = activity
	view.answered.connect(answer)
	campaign.ui.column.add_child(view)

func answer(value: Variant) -> void:
	campaign.ui.dialog("VALIDANDO","Un momento…",[],[],true)
	var result: Dictionary = local_service.submit(str(activity.id),value,"teacher_challenge") if practice_mode else await service.submit(str(activity.id),value,"teacher_challenge")
	if not is_instance_valid(campaign): return
	if result.has("error"):
		campaign.ui.dialog("SIN VALIDACIÓN",result.error,["VOLVER"],[campaign.ui.close_modal],true)
		return
	preload("res://scripts/education/academic_progress.gd").record(campaign.data,activity,result,"teacher_challenge")
	if result.get("verified",false) and (result.get("correct",false)==true or result.get("reflection",false)) and not mentor_id.is_empty():
		if not campaign.data.education_v4.get("mentor_passes") is Dictionary: campaign.data.education_v4["mentor_passes"]={}
		campaign.data.education_v4.mentor_passes[mentor_id]=true
	campaign.save_game()
	campaign.ui.dialog("REFLEXIÓN" if result.get("reflection",false) else ("CORRECTO" if result.get("correct",false) else "SIGUE APRENDIENDO"),str(result.get("explanation","")),["OTRA ACTIVIDAD","CONTINUAR"],[open_local if practice_mode else open_published,campaign.ui.close_modal],true)
