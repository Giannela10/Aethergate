extends SceneTree
var checks := 0
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func _initialize() -> void:
	var service = preload("res://scripts/education/learning_activity_service.gd")
	var data := {"subject_id":"fixture","unit":"SQL","prompt":"Selecciona","explanation":"Explicación","kind":"multiple_choice","difficulty":"easy","content":{"options":["a","b","c","d"]},"answer":0}
	check(service.validate(data).is_empty(),"Four alternatives")
	data.answer = 7
	check(not service.validate(data).is_empty(),"Reject answer outside choices")
	data.answer = 0
	data.content.answer = 0
	check(not service.validate(data).is_empty(),"Reject public answer")
	data.content.erase("answer")
	for kind in ["ordering","sequence","matching","practical"]:
		data.kind = kind
		data.content = {"items":["a","b","c"]}
		data.answer = [2,0,1]
		check(service.validate(data).is_empty(),kind+" contract")
	data.answer = [0,0,1]
	check(not service.validate(data).is_empty(),"Reject duplicate sequence")
	data.kind = "reflection"
	data.access_challenge = true
	check(not service.validate(data).is_empty(),"Reflection cannot deny access")
	data.access_challenge = false
	check(service.validate(data).is_empty(),"Ungraded reflection")
	check(not preload("res://scripts/live/save_migration.gd").supported({"version":{},"save_version":2}),"Malformed version cannot crash campaign recovery")
	check(not preload("res://scripts/live/save_migration.gd").supported({"version":1,"save_version":1.5}),"Fractional save versions rejected")
	data.kind="multiple_choice"; data.content={"options":["a","b","c","d"]}; data.answer=0; data.access_challenge=true; data.max_attempts_per_day=1
	check(not service.validate(data).is_empty(),"Mandatory gates cannot exhaust daily retries")
	data.max_attempts_per_day=0; data.retry_delay_seconds=301
	check(not service.validate(data).is_empty(),"Retry delay bounded")
	data.retry_delay_seconds=0; data.kind="reflection"; data.access_challenge=false
	var view := preload("res://scripts/education/learning_activity_view.gd").new()
	view.activity = data
	root.add_child(view)
	await process_frame
	check(view.get_child_count()>=3,"Activity interface builds")
	view.queue_free()
	print("LEARNING_ACTIVITY_V4_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"server_sql_executed":false}))
	quit(0 if failures.is_empty() else 1)
