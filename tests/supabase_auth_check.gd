extends Node
const Client = preload("res://scripts/auth/supabase_client.gd")
const Auth = preload("res://scripts/auth/auth_manager.gd")
const UID := "11111111-2222-4333-8444-555555555555"
var checks := 0
var failures: Array[String] = []
var finished := false

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _ready() -> void:
	call_deferred("run")

func session() -> Dictionary:
	return {"access_token":"synthetic-access","refresh_token":"synthetic-refresh","expires_at":int(Time.get_unix_time_from_system())+3600,"user":{"id":UID,"email":"user@example.test"}}

func queue_login(auth: Node, selected_role: String = "student", profile_id: String = UID) -> void:
	auth.client.replies.append({"ok":true,"status":200,"data":session()})
	auth.client.replies.append({"ok":true,"status":200,"data":[{"id":profile_id,"display_name":"Test User","email":"user@example.test","avatar_url":"","role":selected_role}]})

func run() -> void:
	for pair in [["student","StudentMainMenu"],["teacher","TeacherDashboard"],["admin","AdminDashboard"],["unknown","Login"]]:
		check(Auth.menu_for_role(pair[0]) == pair[1],"Menu routing "+pair[0])
	var client := Client.new()
	var primary := "sb_publishable_fixture_primary"
	var legacy := "sb_publishable_fixture_legacy"
	client.config = {"supabase_url":"https://fixture.supabase.co/","supabase_publishable_key":primary,"supabase_anon_key":legacy}
	check(client.configured(),"Publishable property accepted")
	check(client.publishable_key() == primary,"Preferred property wins")
	check(client.project_url() == "https://fixture.supabase.co","URL normalization")
	client.config.erase("supabase_publishable_key")
	check(client.configured() and client.publishable_key() == legacy,"Legacy property accepts publishable value")
	client.config.supabase_publishable_key = ""
	check(client.configured() and client.publishable_key() == legacy,"Empty preferred property uses legacy")
	client.config.supabase_publishable_key = "sb_" + "secret_" + "synthetic_rejected"
	check(not client.configured(),"Secret keys rejected; no fallback masks invalid preferred key")
	client.config.supabase_publishable_key = "eyJ.synthetic.rejected"
	check(not client.configured(),"JWT API keys rejected")
	client.config.supabase_publishable_key = primary
	client.config.supabase_url = "https://user:password@fixture.supabase.co"
	check(not client.configured(),"Credentials in URL rejected")
	client.config.supabase_url = "http://fixture.supabase.co"
	check(not client.configured(),"HTTP rejected")
	client.config.supabase_url = "https://fixture.supabase.co"
	check(client.headers_for().has("apikey: "+primary) and client.headers_for().size() == 2,"Anonymous header sends only apikey and content type")
	check(client.headers_for("synthetic-access").has("Authorization: Bearer synthetic-access"),"User token is bearer")
	check(not client.headers_for().has("Authorization: Bearer "+primary),"Publishable never sent as bearer")
	client.config = {}
	check(not client.configured() and client.connection_state() == "NOT CONFIGURED","Missing config safe")
	client.free()
	var auth := preload("res://tests/supabase_session_fixture.gd").new()
	add_child(auth)
	for selected_role in ["pending","student","teacher","admin"]:
		queue_login(auth,selected_role)
		var result: Dictionary = await auth.login_email("user@example.test","synthetic-password")
		check(result.ok and auth.session_valid() and auth.role == selected_role,"Profile routes role "+selected_role)
		check(auth.user_id == UID and auth.display_name == "Test User","Identity from profile "+selected_role)
		check(auth.stored.is_empty() and not auth.remember_login,"Manual login defaults to memory only "+selected_role)
		check(auth.client.requests.back().path.contains("/profiles?select=") and auth.client.requests.back().path.contains(UID),"Profile queried by authenticated ID "+selected_role)
		auth.clear_session()
	queue_login(auth,"unknown")
	check(not (await auth.login_email("user@example.test","synthetic-password")).ok and auth.session_valid() and not auth.can_enter_menu(),"Unknown role blocks routing but preserves Auth")
	queue_login(auth,"admin","different-id")
	check(not (await auth.login_email("user@example.test","synthetic-password")).ok and auth.session_valid() and not auth.can_enter_menu(),"Profile identity mismatch blocked")
	auth.client.replies.append({"ok":true,"status":200,"data":session()})
	auth.client.replies.append({"ok":true,"status":200,"data":[]})
	check(not (await auth.login_email("user@example.test","synthetic-password")).ok and auth.session_valid() and not auth.can_enter_menu(),"Missing profile blocks routing without deleting Auth")
	auth.stored = {"url":auth.client.project_url(),"refresh_token":"synthetic-old-refresh","remember_login":true}
	queue_login(auth)
	await auth.initialize()
	check(auth.session_valid() and auth.client.requests[-2].path == "/auth/v1/token?grant_type=refresh_token","Startup restores through refresh endpoint")
	check(auth.stored.refresh_token == "synthetic-refresh","Refresh token rotation persisted")
	auth.client.replies.append({"ok":false,"status":400,"data":{"code":"refresh_token_not_found"}})
	check(not (await auth.refresh_session()) and not auth.session_valid() and auth.stored.is_empty(),"Refresh failure clears session and storage")
	queue_login(auth)
	await auth.login_email("user@example.test","synthetic-password")
	auth.client.replies.append({"ok":true,"status":204,"data":null})
	await auth.logout()
	check(not auth.session_valid() and auth.access_token.is_empty() and auth.refresh_token.is_empty() and auth.stored.is_empty(),"Logout clears all local session state")
	check(auth.client.requests.back().path == "/auth/v1/logout?scope=local","Logout endpoint called")
	check(Auth._email_error({"status":400,"data":{"code":"invalid_credentials"}}) == "Correo o contraseña incorrectos.","Invalid credentials friendly message")
	check(Auth._email_error({"status":400,"data":{"error":"invalid_grant"}}) == "Correo o contraseña incorrectos.","Legacy auth error field supported")
	check(Auth._email_error({"status":400,"data":{"code":"email_not_confirmed"}}) == "Debes confirmar tu correo antes de iniciar sesión.","Unconfirmed email friendly message")
	check(Auth._email_error({"status":400,"data":{"code":"user_already_exists"}}) == "Ya existe una cuenta asociada a este correo.","Explicit duplicate account friendly message")
	check(Auth._email_error({"status":0}) == "No se pudo conectar con el servidor.","Transport error friendly message")
	check(not auth.diagnostics().contains("synthetic-refresh") and not auth.diagnostics().contains("synthetic-access"),"Diagnostics contain no tokens")
	auth.queue_free()
	var isolated := preload("res://tests/supabase_session_fixture.gd").new()
	add_child(isolated)
	var messages: Array[String] = []
	isolated.status_changed.connect(func(value): messages.append(value))
	await isolated.initialize()
	check(isolated.client.requests.is_empty() and messages.is_empty(),"No-session startup is silent and makes no request")
	isolated.initialized = false
	isolated.stored = {"url":isolated.client.project_url(),"refresh_token":"expired-synthetic","remember_login":true}
	isolated.client.replies.append({"ok":false,"status":400,"data":{"error_code":"refresh_token_not_found"}})
	await isolated.initialize()
	check(messages.is_empty() and isolated.stored.is_empty() and isolated.user_id.is_empty(),"Invalid startup refresh cleans silently")
	for absolute in [null,0,1]:
		var sample := session()
		sample.expires_at = absolute
		sample.expires_in = 3600
		isolated.client.replies.append({"ok":true,"status":200,"data":sample})
		isolated.client.replies.append({"ok":true,"status":200,"data":[{"id":UID,"role":"student"}]})
		var outcome: Dictionary = await isolated.login_email("user@example.test","synthetic-password")
		check(outcome.ok and isolated.expires_at > int(Time.get_unix_time_from_system())+3500,"Relative expiry handles invalid absolute: "+str(absolute))
	var millis := session()
	millis.expires_at = int(millis.expires_at)*1000
	isolated.client.replies.append({"ok":true,"status":200,"data":millis})
	isolated.client.replies.append({"ok":true,"status":200,"data":[{"id":UID,"role":"student"}]})
	check((await isolated.login_email("user@example.test","synthetic-password")).ok and isolated.expires_at < int(Time.get_unix_time_from_system())+3700,"Milliseconds normalized to Unix seconds")
	check(isolated.client.requests[-2].path == "/auth/v1/token?grant_type=password","Manual login uses entered credentials endpoint directly")
	isolated.clear_session()
	isolated.initialized = false
	messages.clear()
	isolated.stored = {"url":isolated.client.project_url(),"refresh_token":"synthetic-old","remember_login":true}
	var expired := session()
	expired.expires_at = 1
	isolated.client.replies.append({"ok":true,"status":200,"data":expired})
	await isolated.initialize()
	check(messages.is_empty() and isolated.stored.is_empty() and not isolated.session_valid(),"Expired startup response is cleared without UI error")
	isolated.initialized = false
	isolated.stored = {"url":isolated.client.project_url(),"refresh_token":"synthetic-old","remember_login":true}
	isolated.client.replies.append({"ok":true,"status":200,"data":session()})
	isolated.client.replies.append({"ok":false,"status":403,"data":{}})
	await isolated.initialize()
	check(not isolated.session_valid() and not isolated.can_enter_menu() and isolated.stored.is_empty(),"Startup profile error clears session and blocks routing")
	check(messages.is_empty(),"Startup profile failure stays silent")
	isolated.clear_session()
	isolated.initialized = false
	isolated.stored = {"url":isolated.client.project_url(),"refresh_token":"synthetic-old","remember_login":true}
	queue_login(isolated)
	await isolated.initialize()
	check(isolated.can_enter_menu() and messages.is_empty(),"Valid simulated startup refresh routes silently")
	isolated.busy = true
	isolated.silent_restore = true
	queue_login(isolated)
	check((await isolated.login_email("user@example.test","synthetic-password")).ok and isolated.can_enter_menu(),"Explicit manual login supersedes pending startup restore")
	isolated.queue_free()
	finished = true
	var report := {"checks":checks,"failures":failures,"real_accounts_created":0,"session_storage":"isolated in-memory fixture"}
	var file := FileAccess.open("res://reports/supabase_auth_tests.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report,"\t"))
		file.close()
	print("SUPABASE_AUTH_RESULT ",JSON.stringify(report))
