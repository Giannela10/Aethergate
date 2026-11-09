extends "res://tests/roles_shell_fixture.gd"
func _resolve_services() -> void:
	auth=preload("res://tests/roles_auth_fixture.gd").new();add_child(auth)
	var old=auth.client
	auth.client=preload("res://tests/capstone_learning_backend_fixture.gd").new();auth.add_child(auth.client);old.free()
	auth.client.assignments[auth.client.OTHER]=[auth.client.SUBJECT]
	auth.sign_as(auth.client.OTHER)
	service=preload("res://scripts/education/question_service.gd").new();add_child(service);service.auth=auth
	administration=preload("res://scripts/education/admin_service.gd").new();administration.auth=auth;add_child(administration)
