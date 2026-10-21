extends Node
## In-memory policy model, NOT a PostgreSQL/RLS integration test. No network.
const ADMIN := "11111111-1111-4111-8111-111111111111"
const TARGET := "22222222-2222-4222-8222-222222222222"
const OTHER := "33333333-3333-4333-8333-333333333333"
const SUBJECT := "44444444-4444-4444-8444-444444444444"
const UNASSIGNED := "55555555-5555-4555-8555-555555555555"
var caller := ADMIN
var config: Dictionary = {}
var requests: Array = []
var audit: Array = []
var assignments: Dictionary = {}
var profiles := {
	ADMIN:{"id":ADMIN,"display_name":"Nombre repetido","email":"admin@example.test","role":"admin","created_at":"2026-01-01"},
	TARGET:{"id":TARGET,"display_name":"Nombre repetido","email":"target@example.test","role":"pending","created_at":"2026-01-02"},
	OTHER:{"id":OTHER,"display_name":"Docente","email":"teacher@example.test","role":"teacher","created_at":"2026-01-03"}
}
var subjects := [{"id":SUBJECT,"name":"Programación","code":"ALGORITMOS","floor":3,"active":true},{"id":UNASSIGNED,"name":"Enfermería","code":"ENFERMERIA","floor":4,"active":true}]

func configured() -> bool: return true
func project_url() -> String: return "https://fixture.supabase.co"
func connection_state() -> String: return "SIMULATED"
func reply(data: Variant) -> Dictionary: return {"ok":true,"status":200,"data":data}
func denied(message: String = "Admin required") -> Dictionary: return {"ok":false,"status":403,"data":{"message":message}}

func request_json(path: String, method: int, body: Dictionary, _token: String = "") -> Dictionary:
	requests.append({"path":path,"method":method,"body":body.duplicate(true)})
	if path.contains("&offset=") and int(path.split("&offset=")[1])>0: return reply([])
	var database_role: String = profiles[caller].role
	if path=="/auth/v1/signup":
		return reply({"access_token":"fixture-access","refresh_token":"fixture-refresh","expires_in":3600,"user":{"id":TARGET,"email":"target@example.test"}})
	if path.begins_with("/rest/v1/profiles?"):
		if path.contains("id=eq."): return reply([profiles[caller].duplicate(true)])
		return reply(profiles.values().duplicate(true)) if database_role=="admin" else reply([profiles[caller].duplicate(true)])
	if path=="/rest/v1/rpc/admin_set_user_role":
		if database_role!="admin": return denied()
		if body.new_role not in ["pending","student","teacher","admin"]: return denied("Invalid role")
		var previous: String = profiles[body.target_user_id].role
		if previous=="admin" and body.new_role!="admin" and profiles.values().filter(func(p): return p.role=="admin").size()==1: return denied("LAST_ADMIN")
		profiles[body.target_user_id].role = body.new_role
		audit.append({"actor":caller,"target":body.target_user_id,"old":previous,"new":body.new_role})
		return reply(profiles[body.target_user_id].duplicate(true))
	if path=="/rest/v1/rpc/admin_set_teacher_subjects":
		if database_role!="admin": return denied()
		if profiles[body.target_user_id].role!="teacher": return denied("Target must be teacher")
		assignments[body.target_user_id] = body.subject_ids.duplicate()
		return reply({"ok":true})
	if path.begins_with("/rest/v1/teacher_subjects?"):
		var id: String = path.split("teacher_id=eq.")[1].split("&")[0]
		if database_role!="admin" and not (database_role=="teacher" and id==caller): return reply([])
		var rows: Array = []
		for subject in assignments.get(id,[]): rows.append({"subject_id":subject})
		return reply(rows)
	if path.begins_with("/rest/v1/subjects?"):
		return reply(subjects.filter(func(s): return database_role=="admin" or database_role=="student" or database_role=="teacher" and s.id in assignments.get(caller,[])))
	if path=="/rest/v1/rpc/save_question":
		return reply("fixture-question") if database_role=="admin" or database_role=="teacher" and body.p_data.subject_id in assignments.get(caller,[]) else denied()
	return denied()
