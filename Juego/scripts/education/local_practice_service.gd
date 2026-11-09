extends RefCounted
## Public, unverified practice. Never used for server grades, access gates or mission validation.
const BANK="res://resources/education/capstone_practice_bank.json"
var catalog: Dictionary={}
var remaining: Dictionary={}
var issued: Dictionary={}
var last_id=""
var load_error=""
func _init() -> void:
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(BANK))
	if not parsed is Dictionary or not parsed.get("questions") is Array or not parsed.get("mentors") is Dictionary:
		load_error="El banco local no es válido.";return
	catalog=parsed
func question_ids(floor_number: int, mentor: String) -> Array:
	if catalog.is_empty(): return []
	if not mentor.is_empty():
		var profile: Dictionary=catalog.mentors.get(mentor,{})
		return profile.get("question_ids",[]).duplicate() if int(profile.get("floor",0))==floor_number else []
	var ids=[]
	for subject in catalog.subjects:
		if subject.code=="INF_GENERAL" and int(subject.floor)==floor_number:
			for question in catalog.questions:
				if question is Dictionary and question.get("subject_id","")==subject.id and question.get("id") is String: ids.append(question.id)
	return ids
func fetch(floor_number: int, context: String, mentor: String="") -> Dictionary:
	if context not in ["teacher_challenge","training"]: return {"error":"La práctica local no valida misiones ni accesos."}
	if not load_error.is_empty(): return {"error":load_error}
	var allowed=question_ids(floor_number,mentor)
	var valid={}
	for question in catalog.get("questions",[]):
		if question is Dictionary and question.get("active",false) and question.get("id","") in allowed and _valid(question): valid[question.id]=question
	if valid.is_empty(): return {"error":"No hay preguntas locales activas y válidas para este docente y piso."}
	var scope=mentor+":"+str(floor_number)
	var deck: Array=remaining.get(scope,[])
	deck=deck.filter(func(id): return valid.has(id))
	if deck.is_empty():
		for id in allowed:
			if valid.has(id) and not deck.has(id): deck.append(id)
		if deck.size()>1 and deck[0]==last_id: deck.append(deck.pop_front())
	var id: String=deck.pop_front();remaining[scope]=deck;last_id=id
	var question: Dictionary=valid[id].duplicate(true)
	issued.clear() # Only the currently displayed question can be submitted.
	issued[id]={"context":context,"answer":int(question.answer),"explanation":question.explanation,"mentor":mentor}
	question.erase("answer");question.erase("explanation")
	question.floor=floor_number;question.offline_practice=true;question.source="local_practice"
	return question
static func _valid(question: Dictionary) -> bool:
	if not question.get("id") is String or question.id.is_empty(): return false
	if not preload("res://scripts/education/learning_activity_service.gd").validate(question).is_empty(): return false
	if question.kind!="multiple_choice": return false
	var seen={}
	for option in question.content.options:
		if not option is String or option.strip_edges().is_empty() or seen.has(option.strip_edges().to_lower()): return false
		seen[option.strip_edges().to_lower()]=true
	return true
func submit(id: String, answer: Variant, context: String) -> Dictionary:
	if not issued.has(id): return {"error":"Solicita una pregunta nueva; esta pregunta ya no está activa."}
	if not (answer is int or answer is float) or float(answer)!=floorf(float(answer)) or answer<0 or answer>3: return {"error":"Selecciona una de las cuatro alternativas."}
	var ticket: Dictionary=issued[id]
	if ticket.context!=context: return {"error":"Contexto de práctica inválido."}
	issued.erase(id)
	return {"question_id":id,"selected":int(answer),"correct":int(answer)==ticket.answer,"explanation":ticket.explanation,"offline":true,"practice":true,"verified":false,"mentor_id":ticket.mentor,"educational_xp":0}
