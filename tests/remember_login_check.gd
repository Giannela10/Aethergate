extends SceneTree
const Fixture = preload("res://tests/supabase_session_fixture.gd")
const Shell = preload("res://tests/remember_login_shell_fixture.gd")
var checks := 0
var failures: Array[String] = []
const ADMIN := "11111111-2222-4333-8444-555555555555"
const TEACHER := "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func queue_login(auth: Node, id: String, selected_role: String) -> void:
	auth.client.replies.append({"ok":true,"status":200,"data":{"access_token":"synthetic-access","refresh_token":"synthetic-refresh","expires_in":3600,"user":{"id":id,"email":id+"@example.test"}}})
	auth.client.replies.append({"ok":true,"status":200,"data":[{"id":id,"email":id+"@example.test","display_name":id,"avatar_url":"avatar-"+id,"role":selected_role}]})

func run() -> void:
	var auth := Fixture.new()
	root.add_child(auth)
	var messages: Array[String] = []
	auth.status_changed.connect(func(value): messages.append(value))
	await auth.initialize()
	check(auth.route_authenticated_user()=="Login" and messages.is_empty(),"Empty startup shows clean Login")
	auth.initialized = false
	auth.stored = {"url":auth.client.project_url(),"refresh_token":"legacy"}
	await auth.initialize()
	check(auth.client.requests.is_empty() and auth.stored.is_empty(),"Legacy token without consent is discarded silently")
	queue_login(auth,ADMIN,"admin")
	await auth.login_email("admin@example.test","synthetic-password",true)
	check(auth.route_authenticated_user()=="AdminDashboard","Manual admin login routes correctly")
	check(auth.remember_login and auth.stored.keys().size()==3 and auth.stored.get("remember_login")==true and not auth.stored.has("password") and not auth.stored.has("access_token"),"Explicit consent persists only refresh token, URL and consent")
	var restarted := Fixture.new()
	root.add_child(restarted)
	restarted.stored = auth.stored.duplicate(true)
	queue_login(restarted,ADMIN,"admin")
	await restarted.initialize()
	check(restarted.route_authenticated_user()=="AdminDashboard" and restarted.client.requests[0].path.ends_with("grant_type=refresh_token"),"Remembered restart refreshes and routes")
	restarted.client.replies.append({"ok":true,"status":204,"data":null})
	set_meta("education_menu_view","StudentMainMenu")
	await restarted.logout()
	check(restarted.route_authenticated_user()=="Login" and restarted.stored.is_empty() and not restarted.remember_login and not has_meta("education_menu_view"),"Logout resets consent and requested dashboard")
	check(restarted.user_id.is_empty() and restarted.display_name.is_empty() and restarted.email.is_empty() and restarted.avatar_url.is_empty() and restarted.profile_cache.is_empty() and restarted.expires_at==0 and restarted.access_token.is_empty() and restarted.refresh_token.is_empty(),"Logout clears identity, cache and tokens")
	check(restarted.client.requests.back().path=="/auth/v1/logout?scope=local","Logout requests remote revocation")
	queue_login(restarted,TEACHER,"teacher")
	await restarted.login_email("teacher@example.test","synthetic-password")
	check(restarted.route_authenticated_user()=="TeacherDashboard" and restarted.user_id==TEACHER and restarted.profile_cache.id==TEACHER and restarted.avatar_url=="avatar-"+TEACHER,"Second account uses only new identity without restarting")
	check(restarted.stored.is_empty(),"Unchecked login persists nothing")
	var unchecked := Fixture.new()
	root.add_child(unchecked)
	unchecked.stored = restarted.stored.duplicate(true)
	await unchecked.initialize()
	check(unchecked.route_authenticated_user()=="Login" and unchecked.client.requests.is_empty(),"Unchecked restart stays at Login")
	unchecked.initialized = false
	unchecked.stored = auth.stored.duplicate(true)
	unchecked.client.replies.append({"ok":false,"status":400,"data":{}})
	await unchecked.initialize()
	check(unchecked.stored.is_empty() and unchecked.route_authenticated_user()=="Login" and not unchecked.remember_login,"Invalid refresh clears remembered state")
	# Exercise the actual login form without resolving production services.
	var form := Shell.new()
	form.auth = restarted
	form.column = VBoxContainer.new()
	form.add_child(form.column)
	root.add_child(form)
	form._account_form(false)
	check(not form.remember_checkbox.button_pressed and form.remember_checkbox.text=="Mantener sesión iniciada","Login checkbox defaults unchecked")
	form.account_fields.email.text = "admin@example.test"
	form.account_fields.password.text = "synthetic-password"
	form.remember_checkbox.button_pressed = true
	queue_login(restarted,ADMIN,"admin")
	await form._submit_account(false)
	check(restarted.remember_login and restarted.stored.get("remember_login")==true,"Actual login form forwards explicit persistence consent")
	form._account_form(false)
	check(not form.remember_checkbox.button_pressed,"Opening another login form resets checkbox")
	form.free()
	for node in [auth,restarted,unchecked]: node.free()
	var result := {"checks":checks,"failures":failures,"real_accounts_modified":0}
	var file := FileAccess.open("res://reports/remember_login_tests.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(result,"\t"))
	print("REMEMBER_LOGIN_RESULT ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
