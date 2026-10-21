extends Node
var checks := 0
var failures: Array[String] = []
var finished := false
const Auth = preload("res://scripts/auth/auth_manager.gd")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	# All credentials here are synthetic fixtures and never leave the process.
	check(not Auth.validate_email_credentials("invalid","test-password",true,"Test User","test-password").is_empty(),"Reject malformed email")
	check(not Auth.validate_email_credentials("a@example.test","short",true,"Test User","short").is_empty(),"Reject short registration password")
	check(not Auth.validate_email_credentials("a@example.test","test-password",true,"A","test-password").is_empty(),"Reject missing display name")
	check(not Auth.validate_email_credentials("a@example.test","test-password",true,"Test User","different").is_empty(),"Reject mismatch")
	check(not Auth.validate_email_credentials("a@example.test","").is_empty(),"Reject empty login password")
	check(Auth.validate_email_credentials(" a@example.test ","test-password",true,"Test User","test-password").is_empty(),"Accept valid registration")
	check(Auth.validate_email_credentials("a@example.test","legacy").is_empty(),"Login defers existing password policy to server")
	var auth := preload("res://tests/email_auth_manager_fixture.gd").new()
	add_child(auth)
	auth.client.enabled = false
	var missing: Dictionary = await auth.register_email("a@example.test","test-password","Test User","test-password")
	check(not missing.ok and auth.client.requests.is_empty(),"Missing configuration creates no account")
	auth.client.enabled = true
	auth.client.replies.append({"ok":true,"status":200,"data":{"id":"fixture-user"}})
	var confirmed: Dictionary = await auth.register_email(" a@example.test ","test-password"," Test User ","test-password")
	check(confirmed.ok and confirmed.get("confirmation_required",false),"Confirmation-required response")
	check(auth.accepted == 0 and not auth.busy,"Unconfirmed signup does not create session")
	var request: Dictionary = auth.client.requests.back()
	check(request.path == "/auth/v1/signup" and request.email == "a@example.test","Signup endpoint and email normalization")
	check(request.metadata == {"display_name":"Test User"} and not request.has_role,"Signup metadata display_name cannot choose role")
	check(request.has_password and not request.has("password"),"Fixture request summary does not retain password")
	auth.client.replies.append({"ok":true,"status":200,"data":{"access_token":"synthetic-test-session"}})
	var immediate: Dictionary = await auth.register_email("a@example.test","test-password","Test User","test-password")
	check(immediate.ok and auth.accepted == 1,"Immediate signup goes through profile/session handler")
	auth.client.replies.append({"ok":true,"status":200,"data":{"access_token":"synthetic-test-session"}})
	var logged_in: Dictionary = await auth.login_email("a@example.test","test-password")
	check(logged_in.ok and auth.accepted == 2,"Email login reuses session handler")
	check(auth.client.requests.back().path == "/auth/v1/token?grant_type=password","Password grant endpoint")
	check(auth.client.requests.back().metadata.is_empty(),"Login does not send profile or role")
	auth.client.replies.append({"ok":false,"status":400,"data":{"code":"email_not_confirmed"}})
	var unconfirmed: Dictionary = await auth.login_email("a@example.test","test-password")
	check(not unconfirmed.ok and unconfirmed.message.contains("confirmar"),"Unconfirmed email message")
	auth.client.replies.append({"ok":false,"status":0})
	var offline: Dictionary = await auth.login_email("a@example.test","test-password")
	check(not offline.ok and not auth.busy and auth.accepted == 2,"Network failure creates no fake session")
	auth.busy = true
	var before: int = auth.client.requests.size()
	var duplicate: Dictionary = await auth.login_email("a@example.test","test-password")
	check(not duplicate.ok and auth.client.requests.size() == before,"Concurrent auth rejected")
	check(Auth._email_error({"status":429}).contains("demasiadas"),"Rate limit message")
	auth.busy = false
	auth.queue_free()
	finished = true
	var report := {"checks":checks,"failures":failures,"remote_registration":"NOT TESTED: requires configured Supabase and SMTP","real_passwords_used":false}
	var file := FileAccess.open("res://reports/email_registration_tests.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report,"\t"))
		file.close()
	print("EMAIL_REGISTRATION_RESULT ",JSON.stringify(report))
