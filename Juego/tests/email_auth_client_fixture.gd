extends Node
## No network or disk. Only records a redacted request summary.
var enabled := true
var replies: Array = []
var requests: Array = []

func configured() -> bool:
	return enabled

func project_url() -> String:
	return "https://fixture.supabase.co"

func connection_state() -> String:
	return "NOT CHECKED"

func request_json(path: String, method: int, body: Dictionary, _token: String = "") -> Dictionary:
	requests.append({"path":path,"method":method,"email":body.get("email",""),"metadata":body.get("data",{}).duplicate(true),"has_password":body.has("password"),"has_role":body.has("role")})
	return replies.pop_front() if not replies.is_empty() else {"ok":false,"status":0}
