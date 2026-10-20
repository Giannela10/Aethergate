extends Node
## REST adapter. Debug logs contain only allowlisted, redacted diagnostics.
var config: Dictionary = {}
var connected := false
var last_status := -1
var last_diagnostic: Dictionary = {}
var last_signup_diagnostic: Dictionary = {}

func publishable_key() -> String:
	# Preferred property takes precedence. Never mask an invalid preferred key
	# by silently using another credential; the old property is only an alias.
	var preferred := str(config.get("supabase_publishable_key", "")).strip_edges()
	return preferred if not preferred.is_empty() else str(config.get("supabase_anon_key", "")).strip_edges()

func project_url() -> String:
	return str(config.get("supabase_url", "")).strip_edges().rstrip("/")

func endpoint_url(path: String) -> String:
	return project_url() + "/" + path.lstrip("/")

func configuration_summary(source: String) -> Dictionary:
	var url := project_url()
	var pattern := RegEx.new()
	pattern.compile("^https://[a-zA-Z0-9-]+\\.supabase\\.co$")
	return {"config_source":source,"supabase_url":"CONFIGURED" if not url.is_empty() else "MISSING","supabase_host_format_valid":pattern.search(url) != null,"publishable_key":"CONFIGURED" if publishable_key().begins_with("sb_publishable_") else "MISSING OR INVALID","key_prefix":"sb_publishable_" if publishable_key().begins_with("sb_publishable_") else "INVALID","configured":configured()}

func configured() -> bool:
	var url := project_url()
	var key := publishable_key()
	var pattern := RegEx.new()
	pattern.compile("^https://[a-zA-Z0-9.-]+(:[0-9]+)?$")
	if pattern.search(url) == null or url.contains("TU_PROYECTO"): return false
	pattern.compile("^sb_publishable_[a-zA-Z0-9_-]+$")
	return pattern.search(key) != null and not key.contains("TU_CLAVE")

func headers_for(token: String = "") -> PackedStringArray:
	var headers := PackedStringArray(["apikey: " + publishable_key(), "Content-Type: application/json"])
	# Publishable keys are not JWTs and must never be Bearer tokens.
	if not token.is_empty(): headers.append("Authorization: Bearer " + token)
	return headers

func connection_state() -> String:
	if not configured(): return "NOT CONFIGURED"
	if last_status < 0: return "NOT CHECKED"
	return "CONNECTED" if connected and last_status >= 200 and last_status < 300 else "ERROR"

func request_json(path: String, method: int = HTTPClient.METHOD_GET, body: Dictionary = {}, token: String = "") -> Dictionary:
	return await _perform_request(path,method,"" if method == HTTPClient.METHOD_GET else JSON.stringify(body),body,token)

func debug_probe_signup_transport() -> Dictionary:
	if not OS.is_debug_build(): return {"ok":false,"status":0,"failure_kind":"debug_only"}
	# Malformed JSON cannot deserialize into signup parameters, including the
	# anonymous-signup flow. This probes POST/TLS/headers without any account data.
	var response := await _perform_request("/auth/v1/signup",HTTPClient.METHOD_POST,"{",{},"")
	return {"ok":response.ok,"status":response.status,"diagnostic":last_diagnostic.duplicate(true),"probe":"malformed_json_no_account_parameters"}

func _perform_request(path: String, method: int, serialized: String, body: Dictionary, token: String) -> Dictionary:
	if not configured():
		last_status = 0
		_record_diagnostic(path,method,0,-1,ERR_UNCONFIGURED,null,body,token,0)
		return {"ok":false,"status":0,"failure_kind":"configuration","error":"Supabase no configurado"}
	var request := HTTPRequest.new()
	request.timeout = 15
	request.body_size_limit = 2097152
	request.max_redirects = 0
	add_child(request)
	var headers := headers_for(token)
	if method == HTTPClient.METHOD_PATCH: headers.append("Prefer: return=representation")
	var started := Time.get_ticks_msec()
	if OS.is_debug_build() and path == "/auth/v1/signup":
		print("[AUTH_SIGNUP_REQUEST] ",JSON.stringify({"url":endpoint_url(path),"apikey_header_configured":publishable_key().begins_with("sb_publishable_"),"content_type":"application/json","body":signup_body_summary(body)}))
	var err := request.request(endpoint_url(path), headers, method, serialized)
	if err != OK:
		request.queue_free()
		connected = false
		last_status = 0
		_record_diagnostic(path,method,0,-1,err,null,body,token,Time.get_ticks_msec()-started)
		return {"ok":false,"status":0,"request_error":err,"transport_result":-1,"failure_kind":"request_start","error":"No se pudo iniciar la solicitud"}
	var result: Array = await request.request_completed
	request.queue_free()
	var status := int(result[1])
	last_status = status
	connected = int(result[0]) == HTTPRequest.RESULT_SUCCESS and status > 0
	var parsed = JSON.parse_string(result[3].get_string_from_utf8())
	var failure := classify_failure(status,int(result[0]),OK)
	_record_diagnostic(path,method,status,int(result[0]),OK,parsed,body,token,Time.get_ticks_msec()-started)
	return {"ok":connected and status >= 200 and status < 300,"status":status,"data":parsed,"transport_result":int(result[0]),"request_error":OK,"failure_kind":failure,"error":"Solicitud rechazada (%d)" % status if status > 0 else "Sin respuesta HTTP"}

static func classify_failure(status: int, transport: int, request_error: int = OK) -> String:
	if request_error != OK: return "request_start"
	if status >= 400: return "http_error"
	match transport:
		HTTPRequest.RESULT_TIMEOUT: return "timeout"
		HTTPRequest.RESULT_CANT_RESOLVE: return "dns"
		HTTPRequest.RESULT_CANT_CONNECT: return "connection"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR: return "tls"
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED: return "redirect"
	if transport != HTTPRequest.RESULT_SUCCESS: return "transport"
	if status == 0: return "no_http_response"
	return "http_error" if status >= 300 else ""

static func sanitize_message(value: String, sensitive: Array) -> String:
	var message := value
	for secret in sensitive:
		if secret is String and not secret.is_empty(): message = message.replace(secret,"[REDACTED]")
	var pattern := RegEx.new()
	for expression in ["sb_(publishable|secret)_[a-zA-Z0-9_-]+","eyJ[a-zA-Z0-9_-]+\\.[a-zA-Z0-9_-]+\\.[a-zA-Z0-9_-]+","[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}","(?i)[\"']?(password|access_token|refresh_token|apikey|authorization)[\"']?\\s*[=:]\\s*[\"']?[^\\s,;}\"']+"]:
		pattern.compile(expression)
		message = pattern.sub(message,"[REDACTED]",true)
	return message.replace("\n"," ").replace("\r"," ").left(300)

static func signup_body_summary(body: Dictionary) -> Dictionary:
	var metadata = body.get("data",{})
	return {"email_present":not str(body.get("email","")).is_empty(),"password_present":not str(body.get("password","")).is_empty(),"password_length":str(body.get("password","")).length(),"display_name_present":metadata is Dictionary and not str(metadata.get("display_name","")).is_empty()}

static func supabase_error_code(data: Variant) -> String:
	if not data is Dictionary: return ""
	# GoTrue versions can send a numeric HTTP `code` alongside a machine-readable
	# `error_code`. Prefer the latter rather than hiding it behind "400.0".
	for key in ["error_code","code","error"]:
		if data.get(key) is String and not data[key].is_empty(): return data[key]
	var code = data.get("code")
	return str(int(code)) if code is int or code is float else ""

func _record_diagnostic(path: String, method: int, status: int, transport: int, request_error: int, data: Variant, body: Dictionary, token: String, elapsed_ms: int) -> void:
	if not OS.is_debug_build(): return
	var sensitive: Array = [publishable_key(),token]
	for key in ["password","access_token","refresh_token","auth_code","code_verifier"]:
		if body.get(key) is String: sensitive.append(body[key])
	var code := ""
	var message := ""
	if status >= 400 and data is Dictionary:
		for key in ["access_token","refresh_token"]:
			if data.get(key) is String: sensitive.append(data[key])
		code = sanitize_message(supabase_error_code(data),sensitive)
		message = sanitize_message(str(data.get("msg",data.get("message",data.get("error_description","")))),sensitive)
	last_diagnostic = {"method":"GET" if method == HTTPClient.METHOD_GET else ("POST" if method == HTTPClient.METHOD_POST else str(method)),"url":endpoint_url(path) if configured() else "INVALID CONFIGURATION","http_status":status,"transport_result":transport,"request_error":request_error,"failure_kind":"configuration" if not configured() else classify_failure(status,transport,request_error),"elapsed_ms":elapsed_ms,"timeout_seconds":15,"supabase_error_code":code.left(80),"supabase_message":message,"apikey_header_configured":publishable_key().begins_with("sb_publishable_"),"content_type":"application/json","bearer_present":not token.is_empty()}
	if path == "/auth/v1/signup":
		last_diagnostic["body"] = signup_body_summary(body)
		last_signup_diagnostic = last_diagnostic.duplicate(true)
	print("[AUTH_HTTP] ",JSON.stringify(last_diagnostic))
