extends Node
## UI-independent adapter; private answers only enter staff forms or after submission.
var auth: Node
var mode := "Sin consultar"
var last_id := ""
var demo: Array = []
var issued: Dictionary = {}
var in_flight := false
const CONTEXTS := ["floor_unlock","teacher_challenge","computer","mission","training"]

func _ready() -> void:
	auth = get_node("/root/AuthManager")
	auth.session_changed.connect(clear_session)
	# Production offline uses an explicit public training bank with no answer keys.
	# The keyed JSON is exclusively a debug fixture.
	if OS.is_debug_build():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://resources/education/demo_questions.json"))
		if parsed is Array: demo = parsed

func get_random_question(subject_id: String, context: String) -> Dictionary:
	if auth.role == "pending": return {"error":"Tu cuenta está pendiente de asignación."}
	if context not in CONTEXTS: return {"error":"Contexto inválido"}
	if not auth.dev_session and auth.session_valid() and auth.client.configured():
		var response: Dictionary = await auth.client.request_json("/rest/v1/rpc/get_random_question",HTTPClient.METHOD_POST,{"p_subject":subject_id,"p_context":context,"p_exclude":last_id if last_id.length() == 36 else null},auth.access_token)
		if response.ok and response.data is Dictionary and response.data.has("id"):
			mode = "Supabase"
			last_id = str(response.data.id)
			issued[last_id] = {"source":"remote","context":context}
			return response.data
		if int(response.status) > 0:
			return {"error":"No hay pregunta disponible o no tienes autorización. Revisa asignaturas y preguntas activas."}
	if not OS.is_debug_build():
		if subject_id != "INF_GENERAL": return {"error":"Práctica offline disponible solo para Informática General en esta etapa"}
		# Answerless training prompt: completion is explicit offline practice, never
		# represented as a backend-verified correct answer. See offline policy docs.
		mode = "Práctica offline"
		var question := {"id":"offline-training","subject_id":subject_id,"floor":3,"question_text":"Sin conexión: identifica almacenamiento no volátil. Un SSD conserva los datos sin energía. Selecciona SSD para completar esta práctica local.","option_a":"RAM","option_b":"SSD","option_c":"CPU","option_d":"Caché","offline_practice":true}
		issued[question.id] = {"source":"practice","context":context}
		return question
	var candidates: Array = demo.filter(func(q): return q.get("subject_id") == subject_id and q.get("active",false) and q.id != last_id)
	if candidates.is_empty(): candidates = demo.filter(func(q): return q.get("subject_id") == subject_id and q.get("active",false))
	if candidates.is_empty(): return {"error":"Sin preguntas de demostración para esta asignatura"}
	var question: Dictionary = candidates.pick_random().duplicate(true)
	last_id = str(question.id)
	issued[last_id] = {"source":"demo","context":context,"key":question.correct_option,"explanation":question.explanation}
	question.erase("correct_option")
	question.erase("explanation")
	mode = "Fallback local DEBUG"
	return question

func submit_answer(question_id: String, option: String, context: String) -> Dictionary:
	if option not in ["A","B","C","D"] or context not in CONTEXTS: return {"error":"Respuesta inválida"}
	if in_flight or not issued.has(question_id): return {"error":"Solicita una pregunta nueva"}
	var ticket: Dictionary = issued[question_id]
	if ticket.context != context: return {"error":"Contexto de pregunta inválido"}
	in_flight = true
	var result: Dictionary
	if ticket.source == "remote":
		var response: Dictionary = await auth.client.request_json("/rest/v1/rpc/submit_answer",HTTPClient.METHOD_POST,{"p_question_id":question_id,"p_selected_option":option,"p_context":context},auth.access_token)
		result = response.data if response.ok and response.data is Dictionary else {"error":"No se pudo validar. Reintenta o solicita otra pregunta."}
	elif ticket.source == "demo" and OS.is_debug_build():
		result = {"question_id":question_id,"selected":option,"correct":option == ticket.key,"explanation":ticket.explanation,"offline":true}
	elif ticket.source == "practice":
		result = {"question_id":question_id,"selected":option,"correct":option == "B","explanation":"Práctica local sin validación del instituto. El SSD es almacenamiento no volátil.","offline":true,"practice":true}
	else: result = {"error":"Sesión de práctica no válida"}
	in_flight = false
	if not result.has("error"): issued.erase(question_id)
	return result

func clear_session() -> void:
	issued.clear()
	last_id = ""
	mode = "Sin consultar"
	demo = demo.filter(func(q): return not str(q.get("id","")).begins_with("dev-created-"))

func get_subjects() -> Array:
	if auth.dev_session and OS.is_debug_build():
		return [{"id":"INF_GENERAL","code":"INF_GENERAL","name":"Informática General","floor":3,"active":true}]
	var result: Dictionary = await auth.client.request_json("/rest/v1/subjects?select=*&active=eq.true&order=code",HTTPClient.METHOD_GET,{},auth.access_token)
	return result.data if result.ok and result.data is Array else []

func get_questions_for_teacher() -> Array:
	if auth.role not in ["teacher","admin"]: return []
	if auth.dev_session and OS.is_debug_build(): return demo.duplicate(true)
	var creator := ",creator:profiles!questions_created_by_fkey(display_name,email)" if auth.role == "admin" else ""
	var result: Dictionary = await auth.client.request_json("/rest/v1/questions?select=*,subjects(code,name),question_keys(correct_option,explanation)"+creator+"&order=created_at.desc",HTTPClient.METHOD_GET,{},auth.access_token)
	return result.data if result.ok and result.data is Array else []

static func validate_question(data: Dictionary) -> String:
	for key in ["subject_id","question_text","option_a","option_b","option_c","option_d"]:
		if str(data.get(key,"")).strip_edges().is_empty(): return "Completa la pregunta, asignatura y las cuatro alternativas."
	if data.get("correct_option") not in ["A","B","C","D"]: return "Selecciona una respuesta correcta."
	if data.get("difficulty") not in ["easy","medium","hard"]: return "Dificultad inválida."
	return ""

func create_question(data: Dictionary) -> Dictionary:
	return await update_question("",data)

func update_question(id: String, data: Dictionary) -> Dictionary:
	var error := validate_question(data)
	if not error.is_empty(): return {"error":error}
	if auth.role not in ["teacher","admin"]: return {"error":"Sin autorización"}
	if auth.dev_session and OS.is_debug_build():
		var row := data.duplicate(true)
		row.id = id if not id.is_empty() else "dev-created-" + str(Time.get_ticks_usec())
		row.floor = 3
		if row.subject_id != "INF_GENERAL": return {"error":"Asignatura no asignada"}
		for index in demo.size():
			if demo[index].id == row.id:
				demo[index] = row
				return {"ok":true}
		demo.append(row)
		return {"ok":true}
	var result: Dictionary = await auth.client.request_json("/rest/v1/rpc/save_question",HTTPClient.METHOD_POST,{"p_id":id if not id.is_empty() else null,"p_data":data},auth.access_token)
	return {"ok":true} if result.ok else {"error":"No se pudo guardar. Revisa tu asignación y propiedad de la pregunta."}

func set_question_active(id: String, active: bool) -> Dictionary:
	if auth.role not in ["teacher","admin"]: return {"error":"Sin autorización"}
	if auth.dev_session and OS.is_debug_build():
		for row in demo:
			if row.id == id:
				row.active = active
				return {"ok":true}
		return {"error":"Pregunta no encontrada"}
	var result: Dictionary = await auth.client.request_json("/rest/v1/questions?id=eq."+id.uri_encode(),HTTPClient.METHOD_PATCH,{"active":active},auth.access_token)
	return {"ok":true} if result.ok and result.data is Array and result.data.size() == 1 else {"error":"No se pudo cambiar el estado. Verifica tus permisos sobre esta pregunta."}
