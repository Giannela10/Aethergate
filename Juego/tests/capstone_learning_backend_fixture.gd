extends "res://tests/roles_backend_fixture.gd"
## In-memory RPC contract model. Does not establish remote RLS or deployment state.
var activities={}
var tickets={}
var serial=0
var fail_next=false
func request_json(path: String, method: int, body: Dictionary, token: String="") -> Dictionary:
	if not path.contains("learning_"): return super.request_json(path,method,body,token)
	requests.append({"path":path,"method":method})
	if fail_next: fail_next=false;return {"ok":false,"status":0,"failure_kind":"connection"}
	var role: String=profiles[caller].role
	if path.ends_with("learning_staff_bank"):
		if role not in ["teacher","admin"]: return denied()
		return reply(activities.values().filter(func(q): return role=="admin" or q.subject_id in assignments.get(caller,[])).duplicate(true))
	if path.ends_with("save_learning_activity"):
		if role not in ["teacher","admin"]: return denied()
		var data: Dictionary=body.p_data
		if role=="teacher" and data.subject_id not in assignments.get(caller,[]): return denied()
		if not preload("res://scripts/education/learning_activity_service.gd").validate(data).is_empty(): return denied("Invalid content")
		var id=str(body.get("p_id", "")) if body.get("p_id")!=null else ""
		if not id.is_empty() and (not activities.has(id) or role!="admin" and activities[id].created_by!=caller): return denied()
		if id.is_empty(): serial+=1;id="aaaaaaaa-aaaa-4aaa-8aaa-%012d"%serial
		var row=data.duplicate(true);row.id=id;row.created_by=activities[id].created_by if activities.has(id) else caller
		activities[id]=row;return reply(id)
	if path.ends_with("get_learning_activity"):
		if role not in ["student","teacher","admin"]: return denied()
		for row in activities.values():
			if row.active and (str(body.get("p_mentor",""))=="" or row.mentor_id==body.p_mentor):
				tickets[caller]={"id":row.id,"context":body.p_context}
				var public_row=row.duplicate(true);public_row.erase("answer");public_row.erase("explanation");public_row.floor=body.p_floor
				return reply(public_row)
		return reply({"error":"No hay una actividad publicada disponible."})
	if path.ends_with("submit_learning_activity"):
		if not tickets.has(caller) or tickets[caller].id!=body.p_id or tickets[caller].context!=body.p_context: return denied("Missing ticket")
		var row: Dictionary=activities[body.p_id]
		if not row.active: return denied("Inactive")
		tickets.erase(caller)
		return reply({"question_id":row.id,"selected":body.p_answer,"correct":body.p_answer==row.answer,"explanation":row.explanation,"verified":true,"educational_xp":0,"fixture_only":true})
	return denied()
