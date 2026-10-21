extends Node
const Client = preload("res://scripts/auth/supabase_client.gd")
const Auth = preload("res://scripts/auth/auth_manager.gd")
var finished := false
var failures: Array[String] = []
var checks := 0

func _ready() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func run() -> void:
	for status in [400,401,403,422,429,500,503]:
		check(Client.classify_failure(status,HTTPRequest.RESULT_SUCCESS) == "http_error","HTTP status remains an HTTP error %d" % status)
		check(Auth._email_error({"status":status}) != "No se pudo conectar con el servidor.","HTTP status not mislabeled network %d" % status)
	for pair in [[HTTPRequest.RESULT_TIMEOUT,"timeout"],[HTTPRequest.RESULT_CANT_RESOLVE,"dns"],[HTTPRequest.RESULT_CANT_CONNECT,"connection"],[HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR,"tls"]]:
		check(Client.classify_failure(0,pair[0]) == pair[1],"Transport reason "+pair[1])
		check(Auth._email_error({"status":0,"failure_kind":pair[1]}) == "No se pudo conectar con el servidor.","Transport message "+pair[1])
	check(Auth._email_error({"status":0,"failure_kind":"configuration"}).contains("configuración"),"Configuration is not a network error")
	check(Auth._email_error({"status":422,"data":{"code":"email_address_invalid"}}) == "El correo electrónico no es válido.","Invalid email mapped")
	check(Auth._email_error({"status":422,"data":{"code":"weak_password"}}) == "La contraseña no cumple los requisitos.","Weak password mapped")
	check(Auth._email_error({"status":403,"data":{"code":"signup_disabled"}}).contains("deshabilitado"),"Signup disabled mapped")
	check(Auth._email_error({"status":422,"data":{"code":422.0,"error_code":"weak_password"}}) == "La contraseña no cumple los requisitos.","Numeric HTTP code does not hide machine error")
	check(Client.supabase_error_code({"code":400.0,"error_code":"bad_json"}) == "bad_json","GoTrue error_code has precedence")
	check(Auth._email_error({"status":429,"data":{"code":"over_email_send_rate_limit"}}).contains("demasiadas solicitudes"),"Email rate limit mapped")
	check(Auth._email_error({"status":500,"data":{"code":"unexpected_failure","msg":"Database error saving new user"}}).contains("trigger de profiles"),"Database/trigger distinct from network")
	check(Auth._email_error({"status":500,"data":{"msg":"Error sending confirmation email"}}).contains("SMTP"),"SMTP distinct from database/network")
	var body := {"email":"user@example.test","password":"synthetic-password","data":{"display_name":"Test User"}}
	var summary := Client.signup_body_summary(body)
	check(summary.email_present and summary.password_present and summary.display_name_present and summary.password_length == 18,"Safe body shape summary")
	check(not JSON.stringify(summary).contains("synthetic-password") and not JSON.stringify(summary).contains("user@example.test"),"Summary contains no credentials")
	var clean := Client.sanitize_message("synthetic-password opaque-refresh sb_publishable_fixturekey user@example.test \"access_token\":\"opaque-other\"",["synthetic-password","opaque-refresh"])
	for secret in ["synthetic-password","opaque-refresh","sb_publishable_fixturekey","user@example.test","opaque-other"]:
		check(not clean.contains(secret),"Diagnostic secret redaction")
	var client := Client.new()
	client.config = {"supabase_url":"https://fixture.supabase.co///","supabase_publishable_key":"sb_publishable_fixture"}
	check(client.endpoint_url("//auth/v1/signup") == "https://fixture.supabase.co/auth/v1/signup","Single endpoint slash")
	client.free()
	var form := preload("res://tests/registration_shell_fixture.gd").new()
	add_child(form)
	for invalid_field in ["full_name","email","password","confirmation"]:
		form.fill_valid()
		form.account_fields[invalid_field].text = "x"
		var before: int = form.auth.client.requests.size()
		await form._submit_account(true)
		check(form.auth.client.requests.size() == before,"Invalid field prevents request "+invalid_field)
	form.fill_valid()
	form.auth.client.enabled = false
	await form._submit_account(true)
	check(form.account_fields.password.text == "synthetic-password" and form.account_fields.confirmation.text == "synthetic-password","Configuration failure preserves password fields")
	form.auth.client.enabled = true
	form.auth.client.replies.append({"ok":false,"status":0,"failure_kind":"timeout"})
	await form._submit_account(true)
	check(form.account_fields.password.text == "synthetic-password" and form.account_fields.password.editable,"Transport failure preserves fields and retry")
	form.auth.client.replies.append({"ok":false,"status":429,"data":{"code":"over_email_send_rate_limit"}})
	await form._submit_account(true)
	check(form.account_fields.password.text == "synthetic-password" and form.status.text.contains("demasiadas"),"HTTP failure preserves password and shows correct message")
	form.auth.client.replies.append({"ok":true,"status":200,"data":{"id":"fixture-user"}})
	await form._submit_account(true)
	check(not form.account_fields.has("confirmation") and form.account_fields.password.text.is_empty(),"Successful signup clears passwords and returns to login")
	form.queue_free()
	finished = true
	var report := {"checks":checks,"failures":failures,"real_accounts_created":0}
	var file := FileAccess.open("res://reports/signup_diagnostics_unit.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report,"\t"))
		file.close()
	print("SIGNUP_DIAGNOSTICS_UNIT ",JSON.stringify(report))
