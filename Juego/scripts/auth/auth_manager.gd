extends Node
signal session_changed
signal status_changed(message: String)
var client: Node
var callback: Node
var user_id := ""
var email := ""
var display_name := ""
var avatar_url := ""
var role := "pending"
var access_token := ""
var refresh_token := ""
var expires_at := 0
var dev_session := false
var initialized := false
var busy := false
var verifier := ""
var generation := 0
var refresh_tick := 0.0
var config_source := "NONE"
var profile_ready := false
var profile_cache: Dictionary = {}
var silent_restore := false
var remember_login := false

func can_enter_menu() -> bool:
	return session_valid() and profile_ready

func _auth_log(tag: String, result: String, http_status: int = 0) -> void:
	if OS.is_debug_build(): print("[AUTH_%s] status=%d result=%s" % [tag,http_status,result])
const SESSION_FILE := "user://education.auth-session.json"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	client = preload("res://scripts/auth/supabase_client.gd").new()
	add_child(client)
	load_configuration()
	callback = preload("res://scripts/auth/oauth_loopback.gd").new()
	add_child(callback)
	callback.code_received.connect(_exchange)
	callback.failed.connect(_login_failed)

func load_configuration() -> void:
	client.config = {}
	config_source = "NONE"
	var external := OS.get_environment("DUOCGAMES_AUTH_CONFIG")
	var candidates: Array[String] = []
	if not external.is_empty(): candidates.append(external)
	candidates.append_array(["user://auth_config.json","res://config/auth_config.json"])
	for path in candidates:
		if not FileAccess.file_exists(path): continue
		config_source = path if path.begins_with("res://") or path.begins_with("user://") else "DUOCGAMES_AUTH_CONFIG"
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path).trim_prefix("\ufeff"))
		if parsed is Dictionary: client.config = parsed
		return

func session_valid() -> bool:
	return not user_id.is_empty() and (dev_session and OS.is_debug_build() or not access_token.is_empty() and expires_at > int(Time.get_unix_time_from_system()))

static func menu_for_role(profile_role: String) -> String:
	return {"pending":"PendingAccountScreen","student":"StudentMainMenu","teacher":"TeacherDashboard","admin":"AdminDashboard"}.get(profile_role,"Login")

func route_authenticated_user(requested_view: String = "") -> String:
	if not can_enter_menu(): return "Login"
	if requested_view == "StudentMainMenu" and role in ["student","teacher","admin"]: return requested_view
	if requested_view == "TeacherDashboard" and role in ["teacher","admin"]: return requested_view
	return menu_for_role(role)

func refresh_profile() -> Dictionary:
	if busy: return {"ok":false,"message":"Espera a que termine la solicitud actual."}
	if not session_valid():
		return {"ok":await refresh_session(),"message":"No se pudo actualizar la sesión. Inicia sesión nuevamente."}
	busy = true
	var current := generation
	var result: Dictionary = await client.request_json("/rest/v1/profiles?select=id,email,display_name,avatar_url,role&id=eq."+user_id.uri_encode(),HTTPClient.METHOD_GET,{},access_token)
	if current != generation: return {"ok":false,"message":"Operación cancelada."}
	busy = false
	if not result.get("ok",false) or not result.data is Array or result.data.size()!=1 or not result.data[0] is Dictionary:
		return {"ok":false,"message":"No se pudo consultar el estado de tu cuenta. Intenta nuevamente."}
	var profile: Dictionary = result.data[0]
	if str(profile.get("id",""))!=user_id or profile.get("role") not in ["pending","student","teacher","admin"]:
		profile_ready = false
		role = ""
		session_changed.emit()
		return {"ok":false,"message":"El perfil no es válido. Contacta al administrador."}
	profile_cache = profile.duplicate(true)
	role = str(profile.role)
	display_name = str(profile.get("display_name",email))
	profile_ready = true
	_auth_log("ROUTE",role.to_upper())
	session_changed.emit()
	return {"ok":true,"message":"Tu cuenta sigue pendiente de asignación." if role=="pending" else "Estado actualizado."}

func initialize() -> void:
	if initialized or busy: return
	initialized = true
	if client.configured():
		var stored := _read_saved_session()
		# Legacy sessions did not record consent. Never restore them implicitly.
		if stored.get("remember_login",false) != true:
			_delete_saved_session()
			return
		if str(stored.get("url","")).strip_edges().trim_suffix("/") == client.project_url():
			remember_login = true
			refresh_token = str(stored.get("refresh_token", ""))
			if not refresh_token.is_empty():
				silent_restore = true
				var restore_generation := generation
				if not await refresh_session() and generation == restore_generation:
					clear_session()
					session_changed.emit()
				silent_restore = false
			else: clear_session()
		elif not stored.is_empty(): _delete_saved_session()

func _read_saved_session() -> Dictionary:
	if not FileAccess.file_exists(SESSION_FILE): return {}
	var stored = JSON.parse_string(FileAccess.get_file_as_string(SESSION_FILE))
	return stored if stored is Dictionary else {}

func _persist_session() -> void:
	if not remember_login or refresh_token.is_empty():
		_delete_saved_session()
		return
	_write_saved_session({"url":client.project_url(),"refresh_token":refresh_token,"remember_login":true})

func _write_saved_session(stored: Dictionary) -> void:
	var file := FileAccess.open(SESSION_FILE,FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(stored))

func _delete_saved_session() -> void:
	if FileAccess.file_exists(SESSION_FILE): DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_FILE))

func _process(delta: float) -> void:
	refresh_tick += delta
	if refresh_tick < 20: return
	refresh_tick = 0
	if not dev_session and not busy and not refresh_token.is_empty() and expires_at < int(Time.get_unix_time_from_system()) + 120:
		await refresh_session()

func dev_login(selected_role: String) -> void:
	if not OS.is_debug_build() or selected_role not in ["pending","student","teacher","admin"]: return
	clear_session()
	dev_session = true
	user_id = "dev-" + selected_role
	display_name = "Desarrollo " + selected_role.capitalize()
	role = selected_role
	profile_ready = true
	session_changed.emit()

static func validate_email_credentials(address: String, password: String, registering: bool = false, full_name: String = "", confirmation: String = "") -> String:
	var pattern := RegEx.new()
	pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")
	if address.length() > 254 or pattern.search(address.strip_edges()) == null:
		return "Escribe un correo válido."
	if password.is_empty(): return "Escribe tu contraseña."
	if registering:
		if full_name.strip_edges().length() < 2 or full_name.strip_edges().length() > 80:
			return "Escribe tu nombre (entre 2 y 80 caracteres)."
		if password.length() < 8: return "Usa una contraseña de al menos 8 caracteres."
		if password != confirmation: return "Las contraseñas no coinciden."
	return ""

func register_email(address: String, password: String, full_name: String, confirmation: String) -> Dictionary:
	var error := validate_email_credentials(address,password,true,full_name,confirmation)
	if not error.is_empty(): return {"ok":false,"message":error}
	return await _email_auth(address.strip_edges(),password,full_name.strip_edges(),true)

func login_email(address: String, password: String, keep_signed_in: bool = false) -> Dictionary:
	var error := validate_email_credentials(address,password)
	if not error.is_empty(): return {"ok":false,"message":error}
	return await _email_auth(address.strip_edges(),password,"",false,keep_signed_in)

func _email_auth(address: String, password: String, full_name: String, registering: bool, keep_signed_in: bool = false) -> Dictionary:
	if busy and silent_restore:
		generation += 1
		busy = false
		silent_restore = false
	if busy: return {"ok":false,"message":"Hay una autenticación en curso. Espera a que termine."}
	if not client.configured():
		return {"ok":false,"message":"Primero configura Supabase para crear cuentas e iniciar sesión con correo. Las cuentas no se guardan dentro del juego."}
	clear_session()
	remember_login = keep_signed_in and not registering
	busy = true
	var current := generation
	var payload := {"email":address,"password":password}
	if registering: payload["data"] = {"display_name":full_name}
	var path := "/auth/v1/signup" if registering else "/auth/v1/token?grant_type=password"
	if OS.is_debug_build() and client.has_method("configuration_summary"):
		print("[AUTH_CONFIG] ",JSON.stringify(client.configuration_summary(config_source)))
	var response: Dictionary = await client.request_json(path,HTTPClient.METHOD_POST,payload)
	_auth_log("LOGIN",("SIGNUP_" if registering else "PASSWORD_") + ("AUTH_OK" if response.get("ok",false) else "AUTH_ERROR"),int(response.get("status",0)))
	payload.clear()
	password = ""
	if current != generation: return {"ok":false,"message":"Operación cancelada."}
	if not response.ok or not response.get("data") is Dictionary:
		busy = false
		return {"ok":false,"message":_email_error(response)}
	var session: Dictionary = response.data
	if not str(session.get("access_token","")).is_empty():
		var accepted := await _accept_session(session,current)
		return {"ok":accepted,"message":("Cuenta creada correctamente. Tu cuenta está pendiente de asignación. Un administrador debe indicar si eres estudiante o profesor." if registering else "Sesión iniciada.") if accepted else ("La sesión inició, pero no se pudo cargar tu perfil. Contacta al administrador." if session_valid() else "No se recibió una sesión válida. Intenta nuevamente.")}
	busy = false
	if registering:
		# With confirmation enabled, Supabase may mask an existing account.
		# Never infer account existence from a successful signup response.
		return {"ok":true,"confirmation_required":true,"message":"Cuenta creada correctamente. Tu cuenta está pendiente de asignación. Un administrador debe indicar si eres estudiante o profesor. Revisa tu correo para confirmar tu cuenta."}
	return {"ok":false,"message":"No se recibió una sesión válida. Intenta nuevamente."}

static func _email_error(response: Dictionary) -> String:
	var status := int(response.get("status",0))
	var kind := str(response.get("failure_kind",""))
	if kind == "configuration": return "La configuración de Supabase no es válida. Revisa la URL y la clave pública."
	if status == 0 or kind in ["timeout","dns","connection","tls","transport","no_http_response","request_start"]:
		return "No se pudo conectar con el servidor."
	var data = response.get("data",{})
	var code := preload("res://scripts/auth/supabase_client.gd").supabase_error_code(data).to_lower()
	var message := str(data.get("msg",data.get("message",data.get("error_description","")))).to_lower() if data is Dictionary else ""
	if status == 429 or code in ["over_email_send_rate_limit","over_request_rate_limit"]:
		return "Se enviaron demasiadas solicitudes. Intenta nuevamente más tarde."
	match code:
		"email_not_confirmed": return "Debes confirmar tu correo antes de iniciar sesión."
		"invalid_credentials", "invalid_grant": return "Correo o contraseña incorrectos."
		"user_already_exists", "email_exists", "email_address_already_exists": return "Ya existe una cuenta asociada a este correo."
		"email_address_invalid": return "El correo electrónico no es válido."
		"weak_password": return "La contraseña no cumple los requisitos."
		"signup_disabled": return "El registro de nuevas cuentas está deshabilitado."
		"email_provider_disabled": return "El acceso con correo está deshabilitado. Contacta al administrador."
	if message.contains("already registered") or message.contains("already been registered"):
		return "Ya existe una cuenta asociada a este correo."
	if message.contains("invalid email") or message.contains("email address") and message.contains("invalid"):
		return "El correo electrónico no es válido."
	if message.contains("password") and (message.contains("weak") or message.contains("at least")):
		return "La contraseña no cumple los requisitos."
	if status >= 500:
		if message.contains("database error"):
			return "Supabase no pudo guardar la cuenta en la base de datos. Revisa el trigger de profiles y los registros de Auth/Postgres."
		if message.contains("sending") and message.contains("email"):
			return "Supabase no pudo enviar el correo de confirmación. Revisa la configuración SMTP."
		return "Supabase encontró un error interno. Revisa los registros de Auth."
	if status == 401: return "Supabase rechazó la autenticación de la aplicación. Revisa la clave pública configurada."
	if status == 403: return "Supabase rechazó la operación. Revisa los permisos y la configuración de Auth."
	if status in [400,422]: return "Supabase rechazó los datos enviados. Revisa el correo y los requisitos de contraseña."
	if status >= 300 and status < 400: return "La solicitud fue redirigida. Revisa la URL de Supabase."
	return "El servidor devolvió una respuesta no válida. Intenta nuevamente."

static func base64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")

static func pkce_challenge(value: String) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(value.to_ascii_buffer())
	return base64url(hash.finish())

func google_login() -> void:
	if busy: return
	if not client.configured() or not client.config.get("google_enabled",false):
		status_changed.emit("Configura Supabase y Google para iniciar sesión.")
		return
	clear_session()
	busy = true
	verifier = base64url(Crypto.new().generate_random_bytes(64))
	var nonce := base64url(Crypto.new().generate_random_bytes(32))
	var port := clampi(int(client.config.get("oauth_callback_port",8765)),1024,65535)
	if callback.start(port,nonce) != OK:
		_login_failed("No se pudo abrir el callback local. Comprueba el puerto.")
		return
	var redirect := "http://127.0.0.1:%d/auth/callback?nonce=%s" % [port,nonce]
	var url: String = client.project_url() + "/auth/v1/authorize?provider=google&redirect_to=" + redirect.uri_encode() + "&code_challenge=" + pkce_challenge(verifier) + "&code_challenge_method=s256"
	status_changed.emit("Abriendo navegador…")
	if OS.shell_open(url) != OK:
		_login_failed("No se pudo abrir el navegador.")
		return
	status_changed.emit("Esperando autenticación…")

func _exchange(code: String) -> void:
	var current := generation
	var temporary := verifier
	verifier = ""
	var result: Dictionary = await client.request_json("/auth/v1/token?grant_type=pkce",HTTPClient.METHOD_POST,{"auth_code":code,"code_verifier":temporary})
	temporary = ""
	if current != generation: return
	if not result.ok or not result.data is Dictionary:
		_login_failed("No se pudo completar la autenticación. Inicia de nuevo.")
		return
	await _accept_session(result.data,current)

func refresh_session() -> bool:
	if busy or refresh_token.is_empty(): return false
	busy = true
	var current := generation
	if not silent_restore: status_changed.emit("Conectando…")
	var result: Dictionary = await client.request_json("/auth/v1/token?grant_type=refresh_token",HTTPClient.METHOD_POST,{"refresh_token":refresh_token})
	if current != generation: return false
	_auth_log("REFRESH","OK" if result.ok else "FAILED",int(result.get("status",0)))
	if not result.ok or not result.data is Dictionary:
		clear_session()
		session_changed.emit()
		if not silent_restore: status_changed.emit("Tu sesión expiró. Inicia sesión nuevamente.")
		return false
	return await _accept_session(result.data,current)

func _accept_session(session: Dictionary, current: int) -> bool:
	access_token = session.get("access_token","") if session.get("access_token") is String else ""
	refresh_token = session.get("refresh_token","") if session.get("refresh_token") is String else ""
	var now := int(Time.get_unix_time_from_system())
	var lifetime := int(session.get("expires_in",0)) if session.get("expires_in") != null else 0
	var absolute := int(session.get("expires_at",0)) if session.get("expires_at") != null else 0
	if absolute > 100000000000: absolute = int(absolute / 1000.0)
	expires_at = now + lifetime if lifetime > 0 else absolute
	_auth_log("LOGIN","EXPIRY_RELATIVE_SECONDS" if lifetime > 0 else "EXPIRY_ABSOLUTE_SECONDS")
	profile_ready = false
	profile_cache.clear()
	role = ""
	display_name = ""
	avatar_url = ""
	var user = session.get("user",{})
	if not user is Dictionary or access_token.is_empty() or refresh_token.is_empty():
		_auth_log("LOGIN","SESSION_FIELDS_INVALID")
		_login_failed("La sesión recibida no es válida.")
		return false
	user_id = user.get("id","") if user.get("id") is String else ""
	email = user.get("email","") if user.get("email") is String else ""
	if user_id.is_empty() or email.is_empty() or expires_at <= int(Time.get_unix_time_from_system()):
		_auth_log("LOGIN","SESSION_ID_OR_EXPIRY_INVALID")
		_login_failed("La sesión recibida no es válida o ya expiró.")
		return false
	# Persist rotated refresh token even if the independent profile request fails.
	_persist_session()
	if not silent_restore: status_changed.emit("Cargando perfil…")
	var result: Dictionary = await client.request_json("/rest/v1/profiles?select=id,email,display_name,avatar_url,role&id=eq." + user_id.uri_encode(),HTTPClient.METHOD_GET,{},access_token)
	if current != generation: return false
	_auth_log("PROFILE","OK" if result.ok else "PROFILE_ERROR",int(result.get("status",0)))
	if not result.ok or not result.data is Array or result.data.size() != 1 or not result.data[0] is Dictionary:
		_profile_failed("Auth correcto, profile ausente o inaccesible.")
		return false
	var profile: Dictionary = result.data[0]
	if str(profile.get("id","")) != user_id:
		_profile_failed("El perfil no corresponde a la cuenta autenticada.")
		return false
	role = str(profile.get("role",""))
	if role not in ["pending","student","teacher","admin"]:
		role = ""
		_profile_failed("Rol de perfil inválido.")
		return false
	display_name = str(profile.get("display_name",email))
	email = str(profile.get("email",email))
	avatar_url = str(profile.get("avatar_url",""))
	dev_session = false
	profile_ready = true
	profile_cache = profile.duplicate(true)
	busy = false
	# Only the rotating refresh token is persisted; never part of the campaign save.
	_persist_session()
	if not silent_restore: status_changed.emit("Sesión iniciada.")
	_auth_log("ROUTE",role.to_upper())
	session_changed.emit()
	return true

func _profile_failed(detail: String) -> void:
	busy = false
	profile_ready = false
	role = ""
	_auth_log("PROFILE",detail)
	if not silent_restore: status_changed.emit("La sesión inició, pero no se pudo cargar tu perfil. Contacta al administrador.")

func _login_failed(message: String) -> void:
	clear_session()
	session_changed.emit()
	if not silent_restore: status_changed.emit(message)

func clear_session() -> void:
	generation += 1
	if is_instance_valid(callback): callback.stop()
	verifier = ""
	busy = false
	user_id = ""
	email = ""
	display_name = ""
	avatar_url = ""
	role = "pending"
	access_token = ""
	refresh_token = ""
	expires_at = 0
	dev_session = false
	profile_ready = false
	profile_cache.clear()
	remember_login = false
	if is_inside_tree() and get_tree().has_meta("education_menu_view"):
		get_tree().remove_meta("education_menu_view")
	_delete_saved_session()

func logout() -> void:
	var token := access_token
	clear_session()
	session_changed.emit()
	if not token.is_empty(): await client.request_json("/auth/v1/logout?scope=local",HTTPClient.METHOD_POST,{},token)

func diagnostics() -> String:
	return "Supabase: %s\nAuth: %s\nRole: %s\nUser ID: %s\nConfig: %s\nDEV: %s" % [client.connection_state(),"LOGGED IN" if session_valid() else "LOGGED OUT",role.to_upper() if session_valid() else "—",user_id.left(8) if session_valid() else "—",config_source,dev_session]

func session_storage_summary() -> Dictionary:
	var stored := _read_saved_session()
	return {"path":SESSION_FILE,"exists":FileAccess.file_exists(SESSION_FILE),"refresh_present":not str(stored.get("refresh_token","")).is_empty(),"stores_password":stored.has("password"),"stores_expiry":stored.has("expires_at"),"profile_ready":profile_ready}
