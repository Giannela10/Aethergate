extends "res://tests/supabase_session_fixture.gd"

func _ready() -> void:
	client = preload("res://tests/roles_backend_fixture.gd").new()
	add_child(client)
	callback = preload("res://scripts/auth/oauth_loopback.gd").new()
	add_child(callback)

func sign_as(id: String) -> void:
	client.caller = id
	var profile: Dictionary = client.profiles[id]
	user_id = id
	email = str(profile.email)
	display_name = str(profile.display_name)
	role = str(profile.role)
	access_token = "fixture-access"
	refresh_token = "fixture-refresh"
	expires_at = int(Time.get_unix_time_from_system())+3600
	set("profile_ready",true)
	set("profile_cache",profile.duplicate(true))
