extends Node
var rows: Dictionary = {}
var fail_next := false
var lose_response := false
var requests: Array = []
var hold := false
var release := false

func project_url() -> String: return "https://fixture.supabase.co"

func request_json(path: String, _method: int = 0, body: Dictionary = {}, token: String = "") -> Dictionary:
	body = body.duplicate(true) # HTTP serializes the body before waiting for a response.
	requests.append({"path":path,"body":body.duplicate(true),"token":token})
	while hold and not release: await get_tree().process_frame
	if fail_next:
		fail_next = false
		return {"ok":false,"status":0}
	var row: Dictionary = rows.get(token,{"payload":{},"revision":0})
	if path.ends_with("load_campaign"): return {"ok":true,"data":row.duplicate(true)}
	if not path.ends_with("save_campaign"): return {"ok":false,"status":404,"data":null}
	if row.get("request_id","") == body.p_request_id:
		return {"ok":true,"data":{"revision":row.revision,"request_id":row.request_id}}
	if int(row.revision) != int(body.p_revision): return {"ok":true,"data":{"conflict":true}}
	rows[token] = {"payload":body.p_payload.duplicate(true),"revision":int(row.revision)+1,"request_id":body.p_request_id,"previous_payload":row.payload.duplicate(true) if body.get("p_backup",false) else row.get("previous_payload",{})}
	if lose_response:
		lose_response = false
		return {"ok":false,"status":0}
	return {"ok":true,"data":{"revision":rows[token].revision,"request_id":body.p_request_id}}
