extends RefCounted
## Local learning progress is a game metric, never an official grade.
static func migrate(raw: Dictionary) -> Dictionary:
	var data := raw.duplicate(true)
	if not data.get("academic_floor_unlocks") is Dictionary: data["academic_floor_unlocks"] = {}
	var progress = data.get("academic_progress",{})
	if not progress is Dictionary: progress = {}
	for key in ["answered","correct","incorrect"]:
		var value = progress.get(key,0)
		progress[key] = maxi(0,int(value)) if value is int or value is float else 0
	if not progress.get("subjects") is Dictionary: progress["subjects"] = {}
	if not progress.get("offline_attempts") is Array: progress["offline_attempts"] = []
	progress.offline_attempts = progress.offline_attempts.slice(-200)
	data["academic_progress"] = progress
	return data

static func record(data: Dictionary, question: Dictionary, result: Dictionary, context: String) -> void:
	var progress: Dictionary = data.academic_progress
	var source_key := "practice_answers" if result.get("offline",false) or result.get("practice",false) else "verified_answers"
	progress[source_key]=int(progress.get(source_key,0))+1
	if not progress.get("completed_activities") is Dictionary: progress["completed_activities"]={}
	if question.has("kind") and (result.get("correct",false)==true or result.get("reflection",false)):
		progress.completed_activities[str(question.id)]=true
	if result.get("reflection",false):
		progress["reflections"] = int(progress.get("reflections",0))+1
		progress.subjects[str(question.subject_id)] = true
		return
	progress.answered += 1
	progress["correct" if result.get("correct",false) else "incorrect"] += 1
	progress.subjects[str(question.subject_id)] = true
	if result.get("offline",false):
		progress.offline_attempts.append({"question_id":question.id,"selected":result.selected,"correct":result.correct,"context":context,"kind":"offline_attempt","created_at":Time.get_datetime_string_from_system(true)})
		progress.offline_attempts = progress.offline_attempts.slice(-200)
