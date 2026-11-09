extends Node
signal session_changed
var client: Node
var user_id := "user-a"
var role := "student"
var dev_session := false
var access_token := "user-a"
var expired := false

func _ready() -> void:
	client = preload("res://tests/cloud_backend_fixture.gd").new()
	add_child(client)

func can_enter_menu() -> bool: return not user_id.is_empty() and not expired
func session_valid() -> bool: return can_enter_menu()
func refresh_session() -> bool:
	expired = false
	session_changed.emit()
	return can_enter_menu()

func sign_as(id: String) -> void:
	user_id = id
	access_token = id
	session_changed.emit()
