extends "res://scripts/education/education_shell.gd"
## Production form controller with isolated auth; never touches real users/tokens.
func _ready() -> void:
	auth = preload("res://tests/email_auth_manager_fixture.gd").new()
	add_child(auth)
	column = VBoxContainer.new()
	add_child(column)
	_account_form(true)

func fill_valid() -> void:
	account_fields.full_name.text = "Test User"
	account_fields.email.text = "user@example.test"
	account_fields.password.text = "synthetic-password"
	account_fields.confirmation.text = "synthetic-password"
