extends Node
## UI adapter. PostgreSQL independently checks every administrative operation.
var auth: Node
const ROLES := ["pending","student","teacher","admin"]
var last_role_diagnostic: Dictionary = {}
var last_role_probe: Dictionary = {}
var last_role_request: Dictionary = {}

func _safe_error(value: Variant) -> String:
	var sensitive: Array = [auth.access_token,auth.refresh_token]
	if auth.client.has_method("publishable_key"): sensitive.append(auth.client.publishable_key())
	return preload("res://scripts/auth/supabase_client.gd").sanitize_message(str(value) if value!=null else "",sensitive)

func _record_role_response(response: Dictionary, target_id: String, selected_role: String) -> void:
	var data = response.get("data",{})
	if not data is Dictionary: data = {}
	last_role_diagnostic = {
		"endpoint":"/rest/v1/rpc/admin_set_user_role", "http_status":int(response.get("status",0)),
		"code":_safe_error(data.get("code",data.get("error_code",""))),
		"message":_safe_error(data.get("message","")),"details":_safe_error(data.get("details","")),"hint":_safe_error(data.get("hint","")),
		"authenticated":auth.session_valid(),"user_id_exists":not auth.user_id.is_empty(),
		"runtime_role":auth.role,"email_exists":not auth.email.is_empty(),"jwt_exists":not auth.access_token.is_empty(),
		"target_user_id":target_id,"new_role":selected_role
	}
	if OS.is_debug_build(): print("[ADMIN_ROLE_RPC] ",JSON.stringify(last_role_diagnostic))

func diagnose_role_connection() -> void:
	# Read-only. Never invokes a write RPC or changes any real account.
	last_role_probe = {"authenticated":auth.session_valid(),"runtime_role":auth.role,"user_id_exists":not auth.user_id.is_empty(),"email_exists":not auth.email.is_empty(),"jwt_exists":not auth.access_token.is_empty()}
	if auth.dev_session or not auth.session_valid(): return
	var actor: String = auth.user_id
	var user: Dictionary = await auth.client.request_json("/auth/v1/user",HTTPClient.METHOD_GET,{},auth.access_token)
	if auth.user_id!=actor: return
	last_role_probe.auth_http_status = int(user.get("status",0))
	last_role_probe.auth_id_matches = user.get("ok",false) and user.get("data") is Dictionary and str(user.data.get("id",""))==actor
	var profile: Dictionary = await auth.client.request_json("/rest/v1/profiles?select=id,role,email&id=eq."+actor.uri_encode(),HTTPClient.METHOD_GET,{},auth.access_token)
	if auth.user_id!=actor: return
	last_role_probe.profile_http_status = int(profile.get("status",0))
	if profile.get("ok",false) and profile.get("data") is Array and profile.data.size()==1:
		last_role_probe.profile_id_matches = str(profile.data[0].get("id",""))==actor
		last_role_probe.database_role = str(profile.data[0].get("role",""))
		last_role_probe.role_consistent = last_role_probe.database_role==auth.role
		last_role_probe.email_matches = str(profile.data[0].get("email",""))==auth.email
	var schema: Dictionary = await auth.client.request_json("/rest/v1/",HTTPClient.METHOD_GET,{},auth.access_token)
	if auth.user_id!=actor: return
	last_role_probe.schema_http_status = int(schema.get("status",0))
	if schema.get("ok",false) and schema.get("data") is Dictionary:
		last_role_probe.rpc_visible = schema.data.get("paths",{}).has("/rpc/admin_set_user_role")
	if OS.is_debug_build(): print("[ADMIN_ROLE_RPC] READ_ONLY_PROBE ",JSON.stringify(last_role_probe))

func _ready() -> void:
	if auth == null: auth = get_node("/root/AuthManager")

func authorized() -> bool:
	return auth != null and auth.can_enter_menu() and auth.role == "admin" and not auth.dev_session

static func valid_id(value: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
	return pattern.search(value) != null

static func error_message(response: Dictionary) -> String:
	var data = response.get("data",{})
	var message := str(data.get("message","")) if data is Dictionary else ""
	if message.contains("LAST_ADMIN"): return "No puedes quitar el último administrador."
	if int(response.get("status",0)) == 0: return "No se pudo conectar con el servidor."
	if message.contains("Admin required") or int(response.get("status",0)) in [401,403]: return "No tienes permisos de administrador."
	if message.contains("Target must be teacher"): return "La cuenta debe tener el rol profesor antes de asignar materias."
	if message.contains("Profile not found"): return "La cuenta ya no está disponible. Actualiza la lista."
	if message.contains("Invalid role"): return "El rol seleccionado no es válido."
	return "No se pudo guardar. Revisa los permisos y que la migración 004 esté aplicada."

func _read_all(path: String) -> Dictionary:
	if not authorized(): return {"ok":false,"message":"Se requiere una sesión de administrador real."}
	var rows: Array = []
	var offset := 0
	var actor_id: String = auth.user_id
	while true:
		if not authorized() or auth.user_id!=actor_id: return {"ok":false,"message":"La sesión cambió. Vuelve a abrir Usuarios."}
		var result: Dictionary = await auth.client.request_json(path+"&limit=200&offset="+str(offset),HTTPClient.METHOD_GET,{},auth.access_token)
		if not result.get("ok",false) or not result.get("data") is Array: return {"ok":false,"message":error_message(result)}
		rows.append_array(result.data)
		if result.data.is_empty(): break
		offset += result.data.size()
	return {"ok":true,"data":rows}

func list_profiles() -> Dictionary:
	return await _read_all("/rest/v1/profiles?select=id,email,display_name,role,created_at&order=created_at.desc,id")

func list_subjects() -> Dictionary:
	return await _read_all("/rest/v1/subjects?select=id,code,name,floor,active&order=code")

func get_teacher_subjects(target_id: String) -> Dictionary:
	if not valid_id(target_id): return {"ok":false,"message":"Identificador de cuenta inválido."}
	return await _read_all("/rest/v1/teacher_subjects?select=subject_id&teacher_id=eq."+target_id+"&order=subject_id")

func set_user_role(target_id: String, selected_role: String) -> Dictionary:
	if not authorized(): return {"ok":false,"message":"No tienes permisos de administrador."}
	if not valid_id(target_id) or selected_role not in ROLES: return {"ok":false,"message":"Cuenta o rol inválido."}
	last_role_request = {"endpoint":"/rest/v1/rpc/admin_set_user_role","authenticated":auth.session_valid(),"user_id_exists":not auth.user_id.is_empty(),"runtime_role":auth.role,"email_exists":not auth.email.is_empty(),"jwt_exists":not auth.access_token.is_empty(),"target_user_id":target_id,"new_role":selected_role}
	if OS.is_debug_build(): print("[ADMIN_ROLE_RPC] REQUEST ",JSON.stringify(last_role_request))
	var response: Dictionary = await auth.client.request_json("/rest/v1/rpc/admin_set_user_role",HTTPClient.METHOD_POST,{"target_user_id":target_id,"new_role":selected_role},auth.access_token)
	_record_role_response(response,target_id,selected_role)
	return {"ok":true,"data":response.data} if response.get("ok",false) and response.get("data") is Dictionary else {"ok":false,"message":error_message(response)}

func set_teacher_subjects(target_id: String, subject_ids: Array) -> Dictionary:
	if not authorized(): return {"ok":false,"message":"No tienes permisos de administrador."}
	if not valid_id(target_id): return {"ok":false,"message":"Identificador de cuenta inválido."}
	for subject in subject_ids:
		if not valid_id(str(subject)): return {"ok":false,"message":"Asignatura inválida."}
	var response: Dictionary = await auth.client.request_json("/rest/v1/rpc/admin_set_teacher_subjects",HTTPClient.METHOD_POST,{"target_user_id":target_id,"subject_ids":subject_ids},auth.access_token)
	return {"ok":true} if response.get("ok",false) else {"ok":false,"message":error_message(response)}

static func filter_profiles(rows: Array, query: String, selected_role: String) -> Array:
	var search := query.strip_edges().to_lower()
	return rows.filter(func(row): return (selected_role.is_empty() or row.get("role")==selected_role) and (search.is_empty() or str(row.get("display_name","")).to_lower().contains(search) or str(row.get("email","")).to_lower().contains(search)))
