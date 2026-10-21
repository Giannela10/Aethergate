extends "res://scripts/auth/auth_manager.gd"
## Exercises production session logic without reading or writing personal saves.
var stored: Dictionary = {}
var writes := 0
var deletes := 0

func _ready() -> void:
	client = preload("res://tests/email_auth_client_fixture.gd").new()
	add_child(client)
	callback = preload("res://scripts/auth/oauth_loopback.gd").new()
	add_child(callback)

func _read_saved_session() -> Dictionary:
	return stored.duplicate(true)

func _write_saved_session(value: Dictionary) -> void:
	writes += 1
	stored = value.duplicate(true)

func _delete_saved_session() -> void:
	deletes += 1
	stored = {}
