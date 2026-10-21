extends "res://scripts/education/education_shell.gd"
var routed_to := "Login"

func _resolve_services() -> void:
	auth = preload("res://tests/roles_auth_fixture.gd").new()
	add_child(auth)
	service = preload("res://scripts/education/question_service.gd").new()
	add_child(service)
	service.auth = auth
	administration = preload("res://scripts/education/admin_service.gd").new()
	administration.auth = auth
	add_child(administration)

func _route() -> void:
	routed_to = auth.route_authenticated_user(str(get_tree().get_meta("education_menu_view","")))
	match routed_to:
		"PendingAccountScreen": _pending()
		"StudentMainMenu": _student()
		"TeacherDashboard": _teacher()
		"AdminDashboard": _admin()
		_: _show_login()
