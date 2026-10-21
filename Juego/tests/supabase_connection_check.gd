extends Node
## Public-key GET probes only. Never signs up, signs in or prints response bodies.
var finished := false
var result: Dictionary = {}

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var auth := get_node("/root/AuthManager")
	result = {"config_source":auth.config_source,"configured":auth.client.configured(),"publishable_detected":auth.client.publishable_key().begins_with("sb_publishable_"),"new_property_supported":true,"legacy_property_supported":true,"users_created":0,"administrative_connection":false,"tables":{}}
	if result.configured:
		var settings: Dictionary = await auth.client.request_json("/auth/v1/settings")
		result.auth_http_status = int(settings.status)
		result.auth_reachable = settings.ok
		if settings.ok and settings.data is Dictionary:
			var providers = settings.data.get("external",{})
			result.email_provider_enabled = providers.get("email",false) == true if providers is Dictionary else false
			result.signup_disabled = settings.data.get("disable_signup",false) == true
		for table in ["profiles","subjects","teacher_subjects","questions","question_keys","question_attempts","academic_progress"]:
			var response: Dictionary = await auth.client.request_json("/rest/v1/"+table+"?select=*&limit=0")
			var code := ""
			if response.get("data") is Dictionary: code = str(response.data.get("code",""))
			var missing := code in ["PGRST205","42P01"]
			result.tables[table] = {"http_status":int(response.status),"missing_or_not_in_schema_cache":missing,"requires_auth_or_permissions":int(response.status) in [401,403]}
		result.migration_verified = false
		result.rls_verified_with_real_roles = false
	else:
		result.auth_reachable = false
	result["no_remote_writes"] = true
	var file := FileAccess.open("res://reports/supabase_connection_check.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result,"\t"))
		file.close()
	finished = true
	print("SUPABASE_CONNECTION_CHECK ",JSON.stringify(result))
