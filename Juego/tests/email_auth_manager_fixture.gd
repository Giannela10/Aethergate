extends "res://scripts/auth/auth_manager.gd"
## Keeps the production validation and requests; replaces session persistence.
var accepted := 0

func _delete_saved_session() -> void:
	pass # Never delete a developer's persisted session from fixture tests.

func _ready() -> void:
	client = preload("res://tests/email_auth_client_fixture.gd").new()
	add_child(client)

func _accept_session(_session: Dictionary, _current: int) -> bool:
	accepted += 1
	busy = false
	return true
