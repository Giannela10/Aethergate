extends Node
const Backend = preload("res://tests/roles_backend_fixture.gd")
const Admin = preload("res://scripts/education/admin_service.gd")
var checks := 0
var failures: Array[String] = []
var finished := false

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func run() -> void:
	var auth := preload("res://tests/roles_auth_fixture.gd").new()
	add_child(auth)
	var admin := Admin.new()
	admin.auth = auth
	add_child(admin)
	auth.client.caller = Backend.TARGET
	var registered: Dictionary = await auth.register_email("target@example.test","fixture-password","Nombre repetido","fixture-password")
	check(registered.ok and auth.role=="pending","New signup receives pending profile")
	check(auth.client.requests[0].body.data.keys()==["display_name"] and not auth.client.requests[0].body.has("role"),"Only one signup form; no role metadata")
	check(auth.route_authenticated_user()=="PendingAccountScreen","Pending routes to waiting screen")
	check(auth.route_authenticated_user("StudentMainMenu")=="PendingAccountScreen","Pending cannot request game menu")
	check(auth.route_authenticated_user("TeacherDashboard")=="PendingAccountScreen","Pending cannot request staff menu")
	auth.sign_as(Backend.ADMIN)
	var listing: Dictionary = await admin.list_profiles()
	check(listing.ok and listing.data.size()==3,"Admin lists every profile")
	check(Admin.filter_profiles(listing.data,"TARGET@","").size()==1,"Case-insensitive email search")
	check(Admin.filter_profiles(listing.data,"nombre repetido","").size()==2,"Duplicate names retained separately")
	check(Admin.filter_profiles(listing.data,"","pending").size()==1,"Role filter")
	check((await admin.set_user_role(Backend.TARGET,"student")).ok,"Admin changes pending to student")
	check(auth.client.profiles[Backend.ADMIN].role=="admin","Duplicate display name never changes wrong identity")
	check(auth.client.audit.back().target==Backend.TARGET and auth.client.audit.back().old=="pending","Role action audited against UUID")
	auth.sign_as(Backend.TARGET)
	check(auth.route_authenticated_user()=="StudentMainMenu","Student opens game menu")
	check(auth.route_authenticated_user("TeacherDashboard")=="StudentMainMenu","Student cannot request teacher dashboard")
	check(not (await admin.list_profiles()).ok,"Student client admin list denied")
	# Forge the client role. The simulated server still uses independently signed caller.
	auth.role = "admin"
	check(not (await admin.set_user_role(Backend.TARGET,"admin")).ok,"Forged student role rejected server-side model")
	auth.sign_as(Backend.OTHER)
	auth.role = "admin"
	check(not (await admin.set_user_role(Backend.OTHER,"admin")).ok,"Forged teacher role rejected server-side model")
	auth.sign_as(Backend.ADMIN)
	check((await admin.set_user_role(Backend.TARGET,"teacher")).ok,"Admin changes student to teacher")
	check((await admin.set_teacher_subjects(Backend.TARGET,[Backend.SUBJECT])).ok,"Admin assigns subjects atomically")
	check((await admin.get_teacher_subjects(Backend.TARGET)).data==[{"subject_id":Backend.SUBJECT}],"Assignment lookup by UUID")
	var before: int = auth.client.requests.size()
	check(not (await admin.set_user_role(Backend.TARGET,"owner")).ok and auth.client.requests.size()==before,"Invalid role rejected before request")
	check(not (await admin.set_user_role("Nombre repetido","admin")).ok,"Names rejected as user identity")
	var last: Dictionary = await admin.set_user_role(Backend.ADMIN,"pending")
	check(not last.ok and last.message=="No puedes quitar el último administrador.","Last admin cannot be demoted")
	check((await admin.set_user_role(Backend.OTHER,"admin")).ok,"Admin can promote another admin")
	check((await admin.set_user_role(Backend.ADMIN,"teacher")).ok,"Demotion allowed when another admin remains")
	await auth.refresh_profile()
	check(auth.role=="teacher" and auth.route_authenticated_user()=="TeacherDashboard","Own profile refresh updates routing after demotion")
	auth.sign_as(Backend.OTHER)
	check(auth.route_authenticated_user()=="AdminDashboard","Admin default route")
	check(auth.route_authenticated_user("TeacherDashboard")=="TeacherDashboard" and auth.role=="admin","Admin can open teacher panel without role change")
	check(auth.route_authenticated_user("StudentMainMenu")=="StudentMainMenu" and auth.role=="admin","Admin can play without role change")
	check((await admin.list_subjects()).data.size()==2,"Admin sees full subject catalog")
	auth.sign_as(Backend.TARGET)
	check(auth.route_authenticated_user("StudentMainMenu")=="StudentMainMenu" and auth.role=="teacher","Teacher can play without role change")
	check(not (await admin.set_teacher_subjects(Backend.TARGET,[Backend.UNASSIGNED])).ok,"Teacher cannot self-assign")
	var question_service := preload("res://scripts/education/question_service.gd").new()
	add_child(question_service)
	question_service.auth = auth
	var allowed: Array = await question_service.get_subjects()
	check(allowed.size()==1 and allowed[0].id==Backend.SUBJECT,"Teacher only sees assigned subject in form")
	check((await auth.client.request_json("/rest/v1/teacher_subjects?select=subject_id&teacher_id=eq."+Backend.TARGET+"&order=subject_id",HTTPClient.METHOD_GET,{},auth.access_token)).data.size()==1,"Teacher reads own assignments in policy model")
	check((await auth.client.request_json("/rest/v1/teacher_subjects?select=subject_id&teacher_id=eq."+Backend.OTHER+"&order=subject_id",HTTPClient.METHOD_GET,{},auth.access_token)).data.is_empty(),"Teacher cannot read others assignments in policy model")
	var question := {"subject_id":Backend.SUBJECT,"question_text":"Prueba","option_a":"A","option_b":"B","option_c":"C","option_d":"D","difficulty":"easy","correct_option":"B","active":true}
	check((await question_service.create_question(question)).get("ok",false),"Teacher creates assigned-subject question")
	question.subject_id = Backend.UNASSIGNED
	check((await question_service.create_question(question)).has("error"),"Backend model rejects unassigned subject even with forged form")
	auth.sign_as(Backend.OTHER)
	check((await question_service.create_question(question)).get("ok",false),"Admin creates questions across subjects")
	auth.client.profiles[Backend.TARGET].role = "student"
	auth.sign_as(Backend.TARGET)
	check((await question_service.create_question(question)).has("error"),"Student cannot create questions")
	before = auth.client.requests.size()
	check((await question_service.get_questions_for_teacher()).is_empty() and auth.client.requests.size()==before,"Student cannot fetch staff keys")
	auth.client.profiles[Backend.TARGET].role = "pending"
	auth.sign_as(Backend.TARGET)
	check((await question_service.get_random_question("INF_GENERAL","floor_unlock")).has("error"),"Pending cannot request gameplay questions")
	auth.client.profiles[Backend.TARGET].role = "student"
	await auth.refresh_profile()
	check(auth.route_authenticated_user()=="StudentMainMenu","Pending refresh recognizes assigned student")
	auth.client.profiles[Backend.TARGET].role = "teacher"
	await auth.refresh_profile()
	check(auth.route_authenticated_user()=="TeacherDashboard","Pending refresh recognizes assigned teacher")
	auth.client.profiles[Backend.TARGET].role = "admin"
	await auth.refresh_profile()
	check(auth.route_authenticated_user()=="AdminDashboard","Profile refresh recognizes assigned admin")
	# Exercise actual UI callbacks with isolated services, no real network or session files.
	var shell := preload("res://tests/roles_shell_fixture.gd").new()
	shell.name = "Login"
	add_child(shell)
	await get_tree().process_frame
	shell.auth.sign_as(Backend.ADMIN)
	await shell._users_page("")
	check(shell.users_list.get_child_count()==3,"Admin UI lists all accounts")
	shell.user_search.text = "target@"
	shell.user_search.text_changed.emit("target@")
	check(shell.users_list.get_child_count()==1,"Admin UI search filters by email")
	shell.user_search.clear()
	shell.user_filter.select(1)
	shell._render_users()
	check(shell.users_list.get_child_count()==1,"Admin UI pending filter")
	shell._user_detail(shell.auth.client.profiles[Backend.TARGET])
	var selector: OptionButton
	for child in shell.column.get_children():
		if child is OptionButton: selector = child
	selector.select(2)
	await shell._save_user_role(shell.auth.client.profiles[Backend.TARGET],selector)
	var boxes: Array = shell.column.get_children().filter(func(child): return child is CheckBox)
	check(boxes.size()==2,"Saving teacher role immediately opens subject assignment")
	boxes[0].button_pressed = true
	await shell._save_assignments(Backend.TARGET,boxes)
	check(shell.auth.client.assignments[Backend.TARGET]==[Backend.SUBJECT],"Subject checkbox form saves through RPC adapter")
	shell.auth.client.profiles[Backend.TARGET].role = "pending"
	shell.auth.sign_as(Backend.TARGET)
	shell._route()
	check(shell.routed_to=="PendingAccountScreen","Pending UI route")
	shell.auth.client.profiles[Backend.TARGET].role = "student"
	await shell._refresh_account()
	check(shell.routed_to=="StudentMainMenu","Pending update button opens assigned menu")
	var sql := FileAccess.get_file_as_string("res://supabase/migrations/004_user_roles_admin.sql")
	check(sql.contains("set default 'pending'") and sql.contains("'pending')"),"Migration defaults and trigger use pending")
	check(sql.contains("pg_advisory_xact_lock(804004)") and sql.contains("LAST_ADMIN"),"Migration includes serialized last-admin guard (static review)")
	check(sql.contains("actor uuid:=auth.uid()") and sql.contains("actor_role is distinct from 'admin'"),"RPC checks authenticated database actor (static review)")
	check(sql.contains("revoke insert,update,delete on public.profiles"),"Direct profile writes revoked (static review)")
	check(sql.contains("insert into public.admin_audit_log") and sql.contains("enable row level security"),"Audit/RLS declarations present (static review)")
	check(not sql.contains("update public.profiles set role='pending'"),"No bulk conversion of existing accounts")
	var sensitive := "sb_publishable_fixture_redaction"
	admin._record_role_response({"status":404,"data":{"code":"PGRST202","message":"Missing RPC "+auth.access_token,"details":sensitive,"hint":"Reload schema"}},Backend.TARGET,"teacher")
	check(admin.last_role_diagnostic.http_status==404 and admin.last_role_diagnostic.code=="PGRST202","Role diagnostic preserves HTTP and Supabase code")
	check(admin.last_role_diagnostic.target_user_id==Backend.TARGET and admin.last_role_diagnostic.new_role=="teacher","Role diagnostic records exact UUID and internal role")
	check(not JSON.stringify(admin.last_role_diagnostic).contains(auth.access_token) and not JSON.stringify(admin.last_role_diagnostic).contains(sensitive),"Role diagnostic redacts tokens and API keys")
	check(admin.last_role_diagnostic.hint=="Reload schema" and admin.last_role_diagnostic.has("details"),"Role diagnostic includes details and hint")
	var corrective := FileAccess.get_file_as_string("res://supabase/migrations/005_fix_admin_roles.sql")
	check(corrective.contains("security definer set search_path = ''") and corrective.contains("grant execute on function public.admin_set_user_role(uuid,text) to authenticated"),"Corrective migration secures definer and EXECUTE")
	check(corrective.contains("notify pgrst, 'reload schema'") and not corrective.contains("disable row level security"),"Corrective migration reloads schema without disabling RLS")
	shell.queue_free()
	auth.queue_free()
	admin.queue_free()
	question_service.queue_free()
	get_tree().remove_meta("education_menu_view")
	finished = true
	var report := {"checks":checks,"failures":failures,"real_users_created":0,"real_users_modified":0,"backend":"in-memory policy model plus SQL static checks; remote RLS NOT TESTED"}
	var file := FileAccess.open("res://reports/user_roles_tests.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report,"\t"))
	print("USER_ROLES_RESULT ",JSON.stringify(report))

func _ready() -> void: call_deferred("run")
